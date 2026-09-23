# peeblestoolbox

Reusable helpers for Peebles-built data projects. Classify counties into MSAs, clean up your maps, clean very dirty data sets before loading them into your cloud data repository, and many other things!

## Installation

Install the released package directly from GitHub with `pak`:

```r
install.packages("pak")
pak::pak("jenniferpeebles/peeblestoolbox@v0.3.0")
```

To install from a local checkout instead:

```r
install.packages(
  "peeblestoolbox",
  repos = NULL,
  type = "source"
)
```

During development, install directly from the package directory:

```r
install.packages(
  "C:/path/to/peeblestoolbox",
  repos = NULL,
  type = "source"
)
```

Then every project can start with:

```r
library(peeblestoolbox)
```

## Setup: Choose your state

Georgia is the default (because I live here!), so existing users do not need to change anything. To
use the state-aware functions somewhere else, set your working state once per
R session:

```r
peebles_state()
#> [1] "GA"

set_peebles_state("North Carolina")
peebles_state()
#> [1] "NC"
```

The setting accepts a postal abbreviation, full state name, or state FIPS
code. To make another state the default in every R session, add this line to
your user-level `.Renviron`:

```text
PEEBLESTOOLBOX_STATE=NC
```

You can still override the default for an individual function call with its
`state` argument.

## Highlighting some useful features

### Metropolitan statistical areas

Quickly classify counties and county equivalents using the official July 2023
OMB metropolitan-area definitions. The bundled national lookup covers all 50
states, the District of Columbia, and Puerto Rico. It includes CBSA,
metropolitan-division, combined-statistical-area, state, county GEOID,
central/outlying, and delineation-date fields.

With no state configuration, Georgia remains the default:

```r
msa_counties()
```

Supply `state = NULL` when looking up an entire cross-state MSA:

```r
charlotte_msa <- msa_counties(state = NULL, cbsa_code = "16740")
unique(charlotte_msa$state_abbr)
#> [1] "NC" "SC"
```

Add MSA information to data containing one or several states. County names are
matched without regard to capitalization or whether they include `"County"`:

```r
counties <- data.frame(
  county = c("Mecklenburg", "York", "Wake"),
  state = c("NC", "SC", "NC")
)

add_msa(counties, county = "county", state_column = "state")
```

The result retains every row and adds the MSA and CSA classifications. For the
most reliable match, especially in multistate data, use a column containing
five-digit county GEOIDs with the `county_fips` argument.

The original Georgia conveniences remain available and backward compatible:

```r
is_atlanta_msa(c("Fulton", "Lumpkin County", "Lamar"))
#> [1]  TRUE  TRUE FALSE

ga_msa_counties("12060")
add_ga_msa(data.frame(county = c("Fulton", "Lamar")), county = "county")
```

The lookup comes from the July 2023 OMB delineations (OMB Bulletin 23-01),
distributed by the U.S. Census Bureau.

Source: <https://www.census.gov/geographies/reference-files/time-series/demo/metro-micro/delineation-files.html>

### Atlanta Regional Commission footprint

`arc_counties()` returns the 11 counties in ARC's regional commission footprint:
Cherokee, Clayton, Cobb, DeKalb, Douglas, Fayette, Forsyth, Fulton, Gwinnett,
Henry, and Rockdale. The lookup includes county names, three-digit county FIPS,
five-digit county GEOIDs, and state identifiers, all stored as character values.
It works offline and uses the definition verified on September 23, 2026 against
[ARC's official county list](https://atlantaregional.org/about-arc/about-the-atlanta-region/).
This is distinct from the Atlanta MSA and ARC's larger transportation planning
area. The City of Atlanta is within the county footprint, not a twelfth county.
These helpers are new in the development version after v0.3.0; install the
updated package from a checkout containing this change to use them.

```r
arc_counties()

# Georgia-only data: names may include "County" and use any capitalization.
georgia <- data.frame(county = c("Fulton", "Forsyth County", "Lumpkin"),
                      population = c(100, 200, 300))
arc_data <- georgia[is_arc_county(georgia$county), ]

# National data: full county GEOIDs include the state, so NC won't match GA.
national <- data.frame(GEOID = c("13121", "37067", "13117", "13187"))
arc_data <- national[is_arc_county(county_fips = national$GEOID), , drop = FALSE]

# If using names in national data, supply the state for each row.
national_names <- data.frame(county = c("Forsyth", "Forsyth", "Fulton"),
                             state = c("NC", "GA", "GA"))
arc_data <- national_names[
  is_arc_county(national_names$county, state = national_names$state),
]
```

`is_arc_county()` takes vectors of values, not quoted column names. Supply
exactly one of `county` or `county_fips`. Names and county-only FIPS codes assume
Georgia unless you supply `state`; this default is independent of
`set_peebles_state()`. Five-digit GEOIDs identify their own state. Missing or
unmatched counties return `FALSE`. Keep FIPS/GEOIDs as character values to
preserve leading zeros. The logical result also works in `dplyr::filter()`;
filtering retains matching rows in their original order, including duplicates.

### Census and boundaries

The state-aware Census and boundary helpers use Georgia unless you select
another default with `set_peebles_state()`. You can also pass `state` directly
for a one-time request:

```r
population <- get_state_acs(
  geography = "county",
  variables = c(population = "B01003_001"),
  state = "NC",
  year = 2024
)

counties <- get_state_counties()
tracts <- get_state_tracts()
```

The existing `get_ga_acs()` and `get_ga_*()` boundary functions always select
Georgia and remain available for older projects.

### Connecting to your cloud repository

Do you frequently have to log in to a data warehouse or another cloud database
to retrieve data? These helpers read your login information from a private
`.Renviron` file on your local machine, so you can share your R code without
also sharing your username, password, or other credentials.

Save the credentials in your user-level `.Renviron`, never in a project file:

```text
WAREHOUSE_HOST=your-host
WAREHOUSE_USER=your-user
WAREHOUSE_PASSWORD=your-password
WAREHOUSE_DATABASE=your-database
WAREHOUSE_PORT=3306
```

Restart R, then:

```r
con <- warehouse_connect()
# Do work...
warehouse_disconnect(con)
```

For difficult government exports, profile the text before loading it:

```r
text_qa <- warehouse_profile_text(teamworks_data)
clean_data <- warehouse_clean_text(
  teamworks_data,
  from = "latin1",
  repair_mojibake = TRUE
)
attr(clean_data, "warehouse_cleaning_audit")
attr(clean_data, "warehouse_column_name_audit")
```

Invalid encodings stop cleaning by default instead of being silently deleted.
Leading UTF byte-order marks are reported by `warehouse_profile_text()` and
removed from column names and character values by `warehouse_clean_text()`.
Before any insert, validate the project-owned schema and inspect a dry-run plan:

```r
warehouse_validate_schema(clean_data, personnel_schema)
warehouse_plan_load(con, clean_data, "personnel_actions_jan2026")
```

The shared chunk writer is intentionally narrow and safe. It only appends to an
existing table, defaults to a dry run, requires exact destination column order,
and reconciles row counts. It never creates, drops, truncates, or replaces tables:

```r
warehouse_write_chunks(
  con,
  clean_data,
  "personnel_actions_jan2026",
  chunk_size = 100000L,
  execute = TRUE
)
```

### Charts and maps

These helpers give `ggplot2` charts and maps a clean, consistent appearance
without repeating the same formatting code in every project.
`theme_peebles_chart()` formats a standard chart, while
`theme_peebles_map()` removes axes and other clutter from a map. You can also
mark a graphic as a draft with `add_peebles_watermark()` and export it at a
consistent size and print-ready resolution with `save_peebles_plot()`.

```r
chart <- ggplot2::ggplot(mtcars, ggplot2::aes(factor(cyl))) +
  ggplot2::geom_bar() +
  theme_peebles_chart() +
  add_peebles_watermark("DRAFT")

save_peebles_plot(chart, "cars.png")
```

### GeoJSON exports

Pass an `sf` object:

```r
export_geojson(
  ga_counties,
  "georgia_counties.geojson"
)
```

Or pass the path to a GIS layer that `sf` can read:

```r
export_geojson(
  "data/map_layers/service_areas.shp",
  "service_areas"
)
```

The helper transforms the layer to WGS84 (EPSG:4326) and saves it in
`output/geojson/`. It will not overwrite an existing file unless
`overwrite = TRUE`.


## License

PeeblesToolbox is available under the [MIT License](LICENSE.md). You may use,
copy, modify, publish, and distribute it subject to the license's notice and disclaimer requirements.

## Function reference you can paste into an AI chat window

Copy the entire block below into a chat when the AI cannot read this repository.
It describes all 33 exported functions in the current package (development
version 0.3.0.9000), including the Georgia shortcuts. The examples and setup
instructions elsewhere in this README provide additional context.

```text
Use the R package peeblestoolbox (PeeblesToolbox) in this project wherever its
functions fit the task, instead of recreating those helpers. Load it with
library(peeblestoolbox), or call peeblestoolbox::function_name(). This reference
describes version 0.3.0.9000. Do not invent additional toolbox functions or
arguments. If the installed version differs, inspect its help or args() in R.
The signatures below are reference notation, not a script to execute as a whole.

SETUP AND CONVENTIONS
- R >= 4.2.0 is required; ggplot2 is an imported dependency. Optional packages
  must be installed for the helpers that use them: tidycensus for ACS, tigris
  for boundaries, sf for GeoJSON, and DBI/RMariaDB for warehouse connections.
- State-aware functions default to peebles_state(). Its precedence is the
  peeblestoolbox.state R option, then PEEBLESTOOLBOX_STATE in the environment,
  then "GA". State inputs accept postal abbreviations, full names, or state
  FIPS codes for the 50 states, DC, and Puerto Rico.
- The Georgia-specific functions always use Georgia, regardless of that setting.
- Data-frame column arguments are quoted column names, such as county = "county"
  or county_fips = "GEOID". Vector functions take the actual values instead.
- Keep credentials in the user's private .Renviron, not in scripts or this chat.
  ACS helpers require CENSUS_API_KEY in the environment. Warehouse credentials
  use WAREHOUSE_HOST, WAREHOUSE_USER, WAREHOUSE_PASSWORD, WAREHOUSE_DATABASE,
  and optionally WAREHOUSE_PORT (default 3306). Restart R after editing .Renviron.

DEFAULT STATE (2 functions)
1. peebles_state()
   Return the current default state as a two-letter abbreviation.
2. set_peebles_state(state)
   Set one default state for this R session; return its abbreviation invisibly.
   Example: set_peebles_state("NC"). Use PEEBLESTOOLBOX_STATE in .Renviron for
   a persistent default across sessions.

METROPOLITAN STATISTICAL AREAS (7 functions)
These use a bundled, offline July 2023 OMB county-to-MSA lookup covering all
50 states, DC, and Puerto Rico. It is a fixed vintage, not a live lookup of the
latest definitions. County-name matching ignores case, punctuation, and a
trailing "County" suffix. Prefer five-digit county GEOIDs for reliable matches; preserve
leading zeros. Unmatched or missing counties get FALSE membership, so FALSE
alone does not prove that a valid county is outside an MSA.

3. msa_counties(state = peebles_state(), cbsa_code = NULL)
   Return the lookup, optionally filtered by state and/or CBSA code. Use
   state = NULL for the national lookup or all portions of a cross-state MSA.
   Columns: cbsa_code, cbsa_title, metro_division_code, metro_division_name,
   csa_code, csa_name, county_geoid, state_fips, state_abbr, state_name,
   county_fips, county, county_type, delineation_date.
   Example: msa_counties(state = NULL, cbsa_code = "16740") for Charlotte.
4. add_msa(data, county = NULL, county_fips = NULL,
           state = peebles_state(), state_column = NULL)
   Return all input rows with msa_code, msa_name, metro_division_code,
   metro_division_name, csa_code, csa_name, msa_county_type, and in_msa added.
   Supply a county-name column or a FIPS column; county_fips takes precedence.
   Three-digit county FIPS need the correct state. Five-digit GEOIDs identify
   the state themselves. Use state_column for multistate county-name data.
   Unmatched rows have NA classification fields and in_msa = FALSE.
   Example: add_msa(df, county = "county", state_column = "state").
5. is_msa_county(county, cbsa_code, state = peebles_state())
   Return a logical vector indicating whether county names belong to the
   selected MSA in the selected state. county is a vector, not a column name.
   Example: is_msa_county(c("Mecklenburg", "Wake"), "16740", state = "NC").
6. ga_msa_counties(cbsa_code = NULL)
   Return the lookup for Georgia only, optionally filtered by CBSA code.
7. add_ga_msa(data, county, county_fips = NULL)
   Return the input with ga_msa_code, ga_msa_name, ga_msa_county_type, and
   in_ga_msa added. Uses Georgia; county and county_fips are column names.
8. is_atlanta_msa(county)
   Return a logical vector for county names in the Atlanta MSA (CBSA 12060).
   Under the bundled vintage, Lumpkin is included and Lamar is excluded.
9. add_atlanta_msa(data, county)
   Return the input with the logical column in_atlanta_msa added; county is
   the quoted name of the county-name column.

CENSUS ACS DATA AND BOUNDARIES (10 functions)
These retrieve data through tidycensus or tigris and require network access.
The year default is 2024, not an automatically selected latest year. Set year
explicitly for the project's desired vintage. Extra arguments (...) are passed
to the underlying tidycensus::get_acs() or corresponding tigris function.

10. get_state_acs(geography, variables, state = peebles_state(), year = 2024,
                  survey = "acs5", geometry = FALSE, output = "wide",
                  cache_table = TRUE, ...)
    Retrieve ACS estimates and margins of error using tidycensus. geography is
    a supported Census geography; variables contains Census variable IDs,
    optionally named. Returns a tibble, or an sf object with geometry = TRUE.
    Example: get_state_acs("county", c(population = "B01003_001"),
                           state = "GA", year = 2024).
11. get_state_counties(state = peebles_state(), year = 2024, cb = TRUE, ...)
    Retrieve county boundaries through tigris::counties().
12. get_state_tracts(state = peebles_state(), year = 2024, cb = TRUE, ...)
    Retrieve census-tract boundaries through tigris::tracts().
13. get_state_block_groups(state = peebles_state(), year = 2024, cb = TRUE, ...)
    Retrieve block-group boundaries through tigris::block_groups().
14. get_state_places(state = peebles_state(), year = 2024, cb = TRUE, ...)
    Retrieve Census place boundaries through tigris::places().
    All four boundary helpers return the underlying tigris result (normally
    sf); cb = TRUE requests cartographic boundaries. Pass county via ... to
    tract/block-group requests when needed.
15. get_ga_acs(geography, variables, year = 2024, survey = "acs5",
               geometry = FALSE, output = "wide", cache_table = TRUE, ...)
    Georgia-only version of get_state_acs(); same output and key requirement.
16. get_ga_counties(year = 2024, cb = TRUE, ...)
    Georgia-only county boundaries.
17. get_ga_tracts(year = 2024, cb = TRUE, ...)
    Georgia-only census-tract boundaries.
18. get_ga_block_groups(year = 2024, cb = TRUE, ...)
    Georgia-only block-group boundaries.
19. get_ga_places(year = 2024, cb = TRUE, ...)
    Georgia-only Census place boundaries.
    The five get_ga_* helpers have no state argument; use get_state_* for
    other states.

WAREHOUSE CONNECTIONS, TEXT CLEANING, AND LOADS (7 functions)
20. warehouse_connect(host = Sys.getenv("WAREHOUSE_HOST"),
                       user = Sys.getenv("WAREHOUSE_USER"),
                       password = Sys.getenv("WAREHOUSE_PASSWORD"),
                       dbname = Sys.getenv("WAREHOUSE_DATABASE"),
                       port = Sys.getenv("WAREHOUSE_PORT", unset = "3306"), ...)
    Open and return a MariaDB/MySQL DBI connection using RMariaDB. Required
    settings must be nonempty; ... is forwarded to DBI::dbConnect().
21. warehouse_disconnect(connection)
    Disconnect a valid DBI connection; safely do nothing if already invalid.
22. warehouse_profile_text(data, columns = NULL)
    Return one diagnostic row per selected character column (all by default):
    rows, missing_n, invalid_encoding_n, leading_bom_n, column_name_has_bom,
    control_character_n, nonbreaking_space_n, and max_characters, plus column.
    Does not change the input or access a database.
23. warehouse_clean_text(data, columns = NULL, from = "",
                          invalid = c("error", "substitute"),
                          replacement = "\ufffd", repair_mojibake = FALSE,
                          squish_whitespace = TRUE)
    Return cleaned data, converting selected character columns (all by default)
    to UTF-8, stripping leading Unicode byte-order marks from values and all
    column names, and replacing nonbreaking spaces. By default also trim and
    collapse whitespace, tabs, and newlines. Invalid encoding stops cleaning
    by default; invalid = "substitute" opts into visible replacements.
    from names a known source encoding, such as "latin1"; the default uses
    marked/native encoding. repair_mojibake opts into a limited set of repairs
    for garbled punctuation, not general encoding detection.
    Inspect attr(result, "warehouse_cleaning_audit") and
    attr(result, "warehouse_column_name_audit") for changes. Duplicate column
    names after BOM removal cause an error. Does not write to a database.
24. warehouse_validate_schema(data, schema, allow_extra = FALSE)
    Compare column names with a named character vector of SQL definitions,
    e.g. c(id = "VARCHAR(3)", amount = "DECIMAL(12,2)"). Return a list with
    ok, issues, missing_columns, extra_columns, and schema_columns. Checks
    missing/extra column names ONLY, not SQL types, lengths, values, or order.
    It neither queries nor creates a database table. Inspect the result's ok.
25. warehouse_plan_load(connection, data, table, chunk_size = 100000L)
    Query the destination without changing it and return a one-row plan:
    table, table_exists, existing_rows, proposed_rows, columns, chunk_size,
    chunks. A missing table is reported with table_exists = FALSE.
26. warehouse_write_chunks(connection, data, table, chunk_size = 100000L,
                            execute = FALSE)
    Require an existing table. Default returns a dry-run load plan. With
    execute = TRUE, require exact destination column names AND order, append
    chunks, and check that the row count increased by the requested amount.
    Return an audit: table, rows_before, rows_requested, rows_after,
    row_count_matches. Never creates, drops, truncates, or replaces a table.
    Does not deduplicate or wrap the whole load in a transaction; a failed
    load can leave earlier chunks inserted. Inspect before retrying an append.

CHARTS, MAPS, AND FILE EXPORTS (5 functions)
27. theme_peebles_chart(base_size = 11, legend_position = "right",
                         angle_x_labels = 25)
    Return a ggplot2 theme based on theme_minimal(), with consistent titles,
    captions, legend placement, and angled x-axis labels. Add with +.
28. theme_peebles_map(base_size = 11, legend_position = "right")
    Return a ggplot2 theme based on theme_void(), with consistent titles,
    captions, and legend placement and no axes or grid. Add with +.
29. add_peebles_watermark(label = "NOT FOR PUBLICATION", color = "gray40",
                          alpha = 0.22, angle = 35, size = 34)
    Return a centered, rotated text annotation to add to a ggplot with +.
    Example: plot + theme_peebles_chart() + add_peebles_watermark("DRAFT").
30. save_peebles_plot(plot, filename, folder = file.path("output", "graphics"),
                       width = 9, height = 6, dpi = 300, ...)
    Save a ggplot using ggplot2::ggsave(), creating the folder if needed.
    Default size is 9 by 6 inches at 300 dpi; ... passes extra ggsave arguments.
    Invisibly return the original plot. Existing files can be overwritten.
31. export_geojson(layer, filename, folder = file.path("output", "geojson"),
                    overwrite = FALSE, quiet = TRUE)
    Accept an sf object, an sfc geometry vector, or a local GIS file path that
    sf can read. Transform to WGS84 (EPSG:4326), create the output folder, add
    .geojson if needed, and write the file. Invisibly return its normalized
    path. Require a known source CRS and refuse to guess a missing CRS.
    Refuse to replace an existing file unless overwrite = TRUE.

ATLANTA REGIONAL COMMISSION FOOTPRINT (2 functions)
New after the v0.3.0 release; require an updated development installation.
The bundled 11-county definition was verified on September 23, 2026 at
https://atlantaregional.org/about-arc/about-the-atlanta-region/ and works offline.
It covers Cherokee, Clayton, Cobb, DeKalb, Douglas, Fayette, Forsyth, Fulton,
Gwinnett, Henry, and Rockdale in Georgia. It is distinct from the Atlanta MSA
and ARC's transportation planning area. Atlanta is not an additional county.

32. arc_counties()
    Return an alphabetical 11-row lookup with character columns county,
    county_fips (three digits), county_geoid (five digits), state_abbr, and
    state_fips. This is a fixed footprint, not a historical membership series.
33. is_arc_county(county = NULL, county_fips = NULL, state = "GA")
    Return a logical vector for filtering. Supply exactly one vector of county
    names or FIPS codes, not a quoted data-frame column name. Name matching
    ignores case, punctuation, and a trailing "County". County-only codes
    accept one to three digits and are padded internally. Names and county-only
    codes require Georgia: state defaults to "GA" independently of the toolbox
    state setting. Supply a scalar state or one state per row in national data.
    States accept abbreviations, full names, or state FIPS. Full five-digit
    GEOIDs carry their own state and determine membership without state matching.
    Missing, blank, malformed, or unmatched county values return FALSE, not NA.
    Missing states do not match names/county-only codes; invalid state labels
    and mismatched vector lengths cause errors. Preserve GEOIDs as character.
    Example: df[is_arc_county(county_fips = df$GEOID), , drop = FALSE].
    Or: df[is_arc_county(df$county, state = df$state), , drop = FALSE].
    Filtering preserves row order and duplicates; FALSE is not a validity check.

When proposing code, choose the relevant helpers from this reference and use
their actual argument names. Keep data-vintage choices explicit. Use ordinary
R or other packages for work the toolbox does not cover.
```

## Authorship

[Jennifer Peebles](https://www.ajc.com/staff/jennifer-peebles/) / [Atlanta Journal-Constitution](https://www.ajc.com/)

A note from JP: I built this project with help from ChatGPT/Codex, which drafted this README from the project's code, outputs and my instructions (and to which I have made edits). I want to be transparent about the help I received. 
