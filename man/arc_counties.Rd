\name{arc_counties}
\alias{arc_counties}
\alias{is_arc_county}
\title{Identify the 11-County Atlanta Regional Commission Footprint}
\usage{
arc_counties()

is_arc_county(county = NULL, county_fips = NULL, state = "GA")
}
\arguments{
\item{county}{A vector of county names, with or without a trailing
\code{"County"}. Matching ignores case and punctuation.}
\item{county_fips}{A vector of five-digit county GEOIDs or county-only FIPS
codes (one to three digits, padded to three internally). Supply exactly one
of \code{county} or \code{county_fips}. Malformed codes do not match.}
\item{state}{A state abbreviation, full name, or state FIPS code, either one
value for all counties or a vector of the same length. Defaults to Georgia,
independently of \code{peebles_state()}. Names and county-only FIPS codes
match only when the corresponding state is Georgia. Five-digit GEOIDs carry
their own state and do not use this argument for matching.}
}
\value{
\code{arc_counties()} returns an 11-row data frame with character columns
\code{county}, \code{county_fips}, \code{county_geoid}, \code{state_abbr},
and \code{state_fips}, ordered alphabetically by county name.
\code{is_arc_county()} returns a logical vector in input order, suitable for
subsetting a data frame. Missing, blank, or unmatched counties return
\code{FALSE}, never \code{NA}. Missing states do not match names or county-only
codes; unrecognized nonmissing state values cause an error.
}
\description{
Look up or select Cherokee, Clayton, Cobb, DeKalb, Douglas, Fayette, Forsyth,
Fulton, Gwinnett, Henry, and Rockdale counties in Georgia. The definition is
bundled with the package and requires no network request.
}
\details{
This is ARC's 11-county regional commission footprint, verified September 23,
2026, rather than the Atlanta MSA or ARC's larger transportation planning area.
The City of Atlanta is within the county footprint, not an additional county.
The lookup is a fixed definition, not a historical membership series.

For national datasets, use five-digit county GEOIDs or supply each row's state
with county names or county-only codes. County names alone assume Georgia.
An unmatched value can also be a typo or missing data, so \code{FALSE} is not
a county-validity check. Preserve GEOIDs as character strings. Filtering with
the returned logical vector preserves input row order and duplicates.
}
\source{
\url{https://atlantaregional.org/about-arc/about-the-atlanta-region/}
}
\examples{
arc_counties()
is_arc_county(c("Fulton", "Forsyth County", "Lumpkin", NA))

national <- data.frame(
  county = c("Fulton", "Forsyth", "Forsyth", "Lumpkin"),
  state = c("GA", "NC", "GA", "GA")
)
national[is_arc_county(national$county, state = national$state), ]

county_data <- data.frame(GEOID = c("13121", "37067", "13117", "13187"))
county_data[is_arc_county(county_fips = county_data$GEOID), , drop = FALSE]
}
