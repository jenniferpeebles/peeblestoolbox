.check_census_key <- function() {
  if (!nzchar(Sys.getenv("CENSUS_API_KEY"))) {
    stop(
      "No CENSUS_API_KEY environment variable was found. ",
      "Current Census API requests require a key. Store CENSUS_API_KEY in ",
      "your user-level .Renviron file, restart R, and try again.",
      call. = FALSE
    )
  }

  invisible(TRUE)
}

get_ga_acs <- function(
    geography,
    variables,
    year = 2024,
    survey = "acs5",
    geometry = FALSE,
    output = "wide",
    cache_table = TRUE,
    ...
) {
  .require_toolbox_package("tidycensus", "retrieve Georgia ACS data")
  .check_census_key()

  tidycensus::get_acs(
    geography = geography,
    variables = variables,
    state = "GA",
    year = year,
    survey = survey,
    geometry = geometry,
    output = output,
    cache_table = cache_table,
    ...
  )
}

get_ga_counties <- function(year = 2024, cb = TRUE, ...) {
  .require_toolbox_package("tigris", "retrieve Georgia county boundaries")
  tigris::counties(state = "GA", year = year, cb = cb, ...)
}

get_ga_tracts <- function(year = 2024, cb = TRUE, ...) {
  .require_toolbox_package("tigris", "retrieve Georgia census-tract boundaries")
  tigris::tracts(state = "GA", year = year, cb = cb, ...)
}

get_ga_block_groups <- function(year = 2024, cb = TRUE, ...) {
  .require_toolbox_package("tigris", "retrieve Georgia block-group boundaries")
  tigris::block_groups(state = "GA", year = year, cb = cb, ...)
}

get_ga_places <- function(year = 2024, cb = TRUE, ...) {
  .require_toolbox_package("tigris", "retrieve Georgia place boundaries")
  tigris::places(state = "GA", year = year, cb = cb, ...)
}
