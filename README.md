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
pak::pak("jenniferpeebles/peeblestoolbox@v0.1.0")
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

## Georgia MSAs

```r
is_atlanta_msa(c("Fulton", "Lumpkin County", "Lamar"))

counties <- data.frame(county = c("Fulton", "Chatham", "Hall", "Lamar"))
add_ga_msa(counties, county = "county")

ga_msa_counties()
ga_msa_counties("12060")
```

The bundled lookup uses the July 2023 OMB delineations (OMB Bulletin 23-01),
distributed by the U.S. Census Bureau. It contains all Georgia counties that
belong to a metropolitan statistical area, including Georgia counties in
cross-state MSAs.

Source: <https://www.census.gov/geographies/reference-files/time-series/demo/metro-micro/delineation-files.html>

## Census and boundaries

```r
population <- get_ga_acs(
  geography = "county",
  variables = c(population = "B01003_001"),
  year = 2024
)

ga_counties <- get_ga_counties(year = 2024)
ga_tracts <- get_ga_tracts(year = 2024)
```

## Warehouse

Save credentials in your user `.Renviron`, never in a project:

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

## Charts and maps

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
