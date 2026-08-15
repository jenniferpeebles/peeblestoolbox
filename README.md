# peeblestoolbox

Reusable helpers for Peebles data projects.

## License

PeeblesToolbox is available under the [MIT License](LICENSE.md). You may use,
copy, modify, publish, and distribute it subject to the license's notice and
disclaimer requirements.

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

## Choose your state

Georgia is the default, so existing users do not need to change anything. To
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

## Metropolitan statistical areas

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

## Census and boundaries

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

## Warehouse

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

## Charts and maps

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

## GeoJSON export

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
