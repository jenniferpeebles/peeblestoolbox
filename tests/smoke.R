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

original_state_option <- getOption("peeblestoolbox.state")
original_state_env <- Sys.getenv("PEEBLESTOOLBOX_STATE", unset = NA_character_)
options(peeblestoolbox.state = NULL)
Sys.unsetenv("PEEBLESTOOLBOX_STATE")
stopifnot(identical(peebles_state(), "GA"))
set_peebles_state("North Carolina")
stopifnot(identical(peebles_state(), "NC"))
set_peebles_state("13")
stopifnot(identical(peebles_state(), "GA"))

national_lookup <- msa_counties(state = NULL)
charlotte_lookup <- msa_counties(state = NULL, cbsa_code = "16740")
stopifnot(
  nrow(national_lookup) == 1252L,
  length(unique(national_lookup$state_abbr)) == 52L,
  identical(sort(unique(charlotte_lookup$state_abbr)), c("NC", "SC")),
  all(c(
    "metro_division_code", "csa_code", "county_geoid", "state_abbr",
    "state_name", "county_type", "delineation_date"
  ) %in% names(national_lookup)),
  isTRUE(is_msa_county("Mecklenburg", "16740", state = "NC")),
  !isTRUE(is_msa_county("Wake", "16740", state = "NC"))
)

multi_state <- add_msa(
  data.frame(
    county = c("Mecklenburg", "York", "Wake", "Unknown"),
    state = c("NC", "SC", "NC", NA_character_)
  ),
  county = "county",
  state_column = "state"
)
stopifnot(
  identical(multi_state$msa_code, c("16740", "16740", "39580", NA_character_)),
  identical(multi_state$in_msa, c(TRUE, TRUE, TRUE, FALSE))
)

multi_state_fips <- add_msa(
  data.frame(fips = c("119", "45091", "999"), state = c("NC", "SC", "NC")),
  county_fips = "fips",
  state_column = "state"
)
stopifnot(
  identical(multi_state_fips$msa_code, c("16740", "16740", NA_character_))
)

if (is.null(original_state_option)) {
  options(peeblestoolbox.state = NULL)
} else {
  options(peeblestoolbox.state = original_state_option)
}
if (is.na(original_state_env)) {
  Sys.unsetenv("PEEBLESTOOLBOX_STATE")
} else {
  Sys.setenv(PEEBLESTOOLBOX_STATE = original_state_env)
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

dirty_text <- data.frame(
  name = c("  Jane\tDoe  ", "Acme\u00a0LLC", "Line\nBreak", NA_character_),
  value = 1:4,
  stringsAsFactors = FALSE
)
text_profile <- warehouse_profile_text(dirty_text)
stopifnot(
  identical(text_profile$column, "name"),
  text_profile$control_character_n == 2L,
  text_profile$nonbreaking_space_n == 1L
)

clean_text <- warehouse_clean_text(dirty_text)
clean_audit <- attr(clean_text, "warehouse_cleaning_audit")
stopifnot(
  identical(clean_text$name, c("Jane Doe", "Acme LLC", "Line Break", NA_character_)),
  clean_audit$changed_n == 3L,
  identical(clean_text$value, dirty_text$value)
)

valid_schema <- warehouse_validate_schema(
  data.frame(id = "001", amount = 10),
  c(id = "VARCHAR(3)", amount = "DECIMAL(12,2)")
)
invalid_schema <- warehouse_validate_schema(
  data.frame(id = "001", surprise = "x"),
  c(id = "VARCHAR(3)", amount = "DECIMAL(12,2)")
)
stopifnot(
  isTRUE(valid_schema$ok),
  !isTRUE(invalid_schema$ok),
  identical(invalid_schema$missing_columns, "amount"),
  identical(invalid_schema$extra_columns, "surprise")
)

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
