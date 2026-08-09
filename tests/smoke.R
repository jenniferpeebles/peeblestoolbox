library(peeblestoolbox)

original_census_key <- Sys.getenv("CENSUS_API_KEY", unset = NA_character_)
Sys.unsetenv("CENSUS_API_KEY")
census_key_error <- tryCatch(
  peeblestoolbox:::.check_census_key(),
  error = identity
)
stopifnot(
  inherits(census_key_error, "error"),
  grepl("require a key", conditionMessage(census_key_error), fixed = TRUE)
)
Sys.setenv(CENSUS_API_KEY = "test-key-not-used-for-a-request")
stopifnot(isTRUE(peeblestoolbox:::.check_census_key()))
if (is.na(original_census_key)) {
  Sys.unsetenv("CENSUS_API_KEY")
} else {
  Sys.setenv(CENSUS_API_KEY = original_census_key)
}

lookup <- ga_msa_counties()
stopifnot(
  nrow(lookup) == 74L,
  length(unique(lookup$cbsa_code)) == 15L,
  isTRUE(is_atlanta_msa("Lumpkin County")),
  !isTRUE(is_atlanta_msa("Lamar County")),
  isTRUE(is_atlanta_msa("DEKALB")),
  !isTRUE(is_atlanta_msa(NA_character_))
)

classified <- add_ga_msa(
  data.frame(county = c("Fulton", "Chatham County", "Hall", "Lamar")),
  county = "county"
)
stopifnot(
  identical(classified$ga_msa_code, c("12060", "42340", "23580", NA_character_)),
  identical(classified$in_ga_msa, c(TRUE, TRUE, TRUE, FALSE))
)

classified_fips <- add_ga_msa(
  data.frame(county = c("anything", "anything"), fips = c("13187", "13171")),
  county = "county",
  county_fips = "fips"
)
stopifnot(
  identical(classified_fips$ga_msa_code, c("12060", NA_character_))
)

plot <- ggplot2::ggplot(mtcars, ggplot2::aes(factor(cyl))) +
  ggplot2::geom_bar() +
  theme_peebles_chart() +
  add_peebles_watermark("TEST")
stopifnot(inherits(plot, "ggplot"))

if (requireNamespace("sf", quietly = TRUE)) {
  geojson_input <- sf::st_sf(
    name = "test",
    geometry = sf::st_sfc(sf::st_point(c(0, 0)), crs = 3857)
  )
  geojson_folder <- file.path(tempdir(), "peeblestoolbox-geojson-test")
  geojson_path <- export_geojson(
    geojson_input,
    "test_layer",
    folder = geojson_folder,
    overwrite = TRUE
  )
  geojson_output <- sf::st_read(geojson_path, quiet = TRUE)
  stopifnot(
    file.exists(geojson_path),
    sf::st_crs(geojson_output)$epsg == 4326
  )
}
