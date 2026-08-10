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

get_state_acs <- function(
    geography,
    variables,
    state = peebles_state(),
    year = 2024,
    survey = "acs5",
    geometry = FALSE,
    output = "wide",
    cache_table = TRUE,
    ...
) {
  .require_toolbox_package("tidycensus", "retrieve state ACS data")
  .check_census_key()

  tidycensus::get_acs(
    geography = geography,
    variables = variables,
    state = .normalize_states(state),
    year = year,
    survey = survey,
    geometry = geometry,
    output = output,
    cache_table = cache_table,
    ...
  )
}

get_state_counties <- function(state = peebles_state(), year = 2024, cb = TRUE, ...) {
  .require_toolbox_package("tigris", "retrieve state county boundaries")
  tigris::counties(state = .normalize_states(state), year = year, cb = cb, ...)
}

get_state_tracts <- function(state = peebles_state(), year = 2024, cb = TRUE, ...) {
  .require_toolbox_package("tigris", "retrieve state census-tract boundaries")
  tigris::tracts(state = .normalize_states(state), year = year, cb = cb, ...)
}

get_state_block_groups <- function(state = peebles_state(), year = 2024, cb = TRUE, ...) {
  .require_toolbox_package("tigris", "retrieve state block-group boundaries")
  tigris::block_groups(state = .normalize_states(state), year = year, cb = cb, ...)
}

get_state_places <- function(state = peebles_state(), year = 2024, cb = TRUE, ...) {
  .require_toolbox_package("tigris", "retrieve state place boundaries")
  tigris::places(state = .normalize_states(state), year = year, cb = cb, ...)
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
  get_state_acs(
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
  get_state_counties(state = "GA", year = year, cb = cb, ...)
}

get_ga_tracts <- function(year = 2024, cb = TRUE, ...) {
  get_state_tracts(state = "GA", year = year, cb = cb, ...)
}

get_ga_block_groups <- function(year = 2024, cb = TRUE, ...) {
  get_state_block_groups(state = "GA", year = year, cb = cb, ...)
}

get_ga_places <- function(year = 2024, cb = TRUE, ...) {
  get_state_places(state = "GA", year = year, cb = cb, ...)
}
