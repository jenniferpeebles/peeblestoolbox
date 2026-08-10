\name{msa_counties}
\alias{msa_counties}
\alias{add_msa}
\alias{is_msa_county}
\title{Classify U.S. Counties by Metropolitan Statistical Area}
\usage{
msa_counties(state = peebles_state(), cbsa_code = NULL)

add_msa(data, county = NULL, county_fips = NULL,
  state = peebles_state(), state_column = NULL)

is_msa_county(county, cbsa_code, state = peebles_state())
}
\arguments{
\item{state}{A state abbreviation, full name, or FIPS code. Use \code{NULL}
with \code{msa_counties()} to return all states and territories in the lookup.}
\item{cbsa_code}{Optional five-character CBSA code used to filter the lookup.}
\item{data}{A data frame containing counties or county equivalents.}
\item{county}{Name of the column containing county or county-equivalent names.}
\item{county_fips}{Optional name of a column containing three- or five-digit
county FIPS codes. Five-digit GEOIDs are the most reliable match.}
\item{state_column}{Optional name of a column containing state abbreviations,
names, or FIPS codes. This supports data containing multiple states.}
}
\value{
\code{msa_counties()} returns the official county-to-MSA lookup, including
CBSA, metropolitan-division, combined-statistical-area, state, county GEOID,
central/outlying, and delineation-date fields. \code{add_msa()} adds the
corresponding classification columns to \code{data}. \code{is_msa_county()}
returns a logical vector.
}
\description{
Classify counties and county equivalents using the July 2023 OMB metropolitan
area delineations. The lookup covers the 50 states, District of Columbia, and
Puerto Rico and preserves all state portions of cross-state MSAs.
}
\examples{
msa_counties()
msa_counties(state = NULL, cbsa_code = "16740")

counties <- data.frame(
  county = c("Mecklenburg", "York"),
  state = c("NC", "SC")
)
add_msa(counties, county = "county", state_column = "state")
}
