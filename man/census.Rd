\name{get_ga_acs}
\alias{get_ga_acs}
\alias{get_ga_counties}
\alias{get_ga_tracts}
\alias{get_ga_block_groups}
\alias{get_ga_places}
\alias{get_state_acs}
\alias{get_state_counties}
\alias{get_state_tracts}
\alias{get_state_block_groups}
\alias{get_state_places}
\title{Retrieve State Census Data and Boundaries}
\usage{
get_state_acs(geography, variables, state = peebles_state(), year = 2024,
  survey = "acs5", geometry = FALSE, output = "wide",
  cache_table = TRUE, ...)

get_state_counties(state = peebles_state(), year = 2024, cb = TRUE, ...)

get_state_tracts(state = peebles_state(), year = 2024, cb = TRUE, ...)

get_state_block_groups(state = peebles_state(), year = 2024, cb = TRUE, ...)

get_state_places(state = peebles_state(), year = 2024, cb = TRUE, ...)

get_ga_acs(geography, variables, year = 2024, survey = "acs5",
  geometry = FALSE, output = "wide", cache_table = TRUE, ...)

get_ga_counties(year = 2024, cb = TRUE, ...)

get_ga_tracts(year = 2024, cb = TRUE, ...)

get_ga_block_groups(year = 2024, cb = TRUE, ...)

get_ga_places(year = 2024, cb = TRUE, ...)
}
\arguments{
\item{state}{A state abbreviation, full name, or FIPS code. Defaults to the
value returned by \code{peebles_state()}.}
\item{geography}{A geography accepted by \code{tidycensus::get_acs()}.}
\item{variables}{One or more Census variable IDs, optionally named.}
\item{year}{Data or boundary vintage.}
\item{survey}{ACS survey; usually \code{"acs5"} or \code{"acs1"}.}
\item{geometry}{Whether to return geometry with ACS results.}
\item{output}{Tidycensus output shape, normally \code{"wide"} or \code{"tidy"}.}
\item{cache_table}{Whether tidycensus should cache variable metadata.}
\item{cb}{Whether to request cartographic boundary files.}
\item{...}{Additional arguments passed to tidycensus or tigris.}
}
\value{A tibble or simple-features object returned by tidycensus or tigris.}
\description{
Thin wrappers around tidycensus and tigris that consistently select the
configured state. The \code{get_ga_*()} functions remain Georgia-specific
shortcuts for backward compatibility.
}
