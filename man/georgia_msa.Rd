\name{ga_msa_counties}
\alias{ga_msa_counties}
\alias{add_ga_msa}
\alias{is_atlanta_msa}
\alias{add_atlanta_msa}
\title{Classify Georgia Counties by Metropolitan Statistical Area}
\usage{
ga_msa_counties(cbsa_code = NULL)

add_ga_msa(data, county, county_fips = NULL)

is_atlanta_msa(county)

add_atlanta_msa(data, county)
}
\arguments{
\item{cbsa_code}{Optional five-character CBSA code used to filter the lookup.}
\item{data}{A data frame containing Georgia counties.}
\item{county}{For vector functions, county names. For data-frame functions, the
name of the county column as a character string. Names may include or omit
\code{"County"} and are matched without regard to case or punctuation.}
\item{county_fips}{Optional name of a column containing three- or five-digit
county FIPS codes.}
}
\value{
\code{ga_msa_counties()} returns the official Georgia county-to-MSA lookup.
\code{add_ga_msa()} adds CBSA code, MSA name, county type, and membership
columns. \code{is_atlanta_msa()} returns a logical vector.
\code{add_atlanta_msa()} adds a logical column.
}
\description{
Classify Georgia counties using the July 2023 OMB metropolitan-area
delineations. The lookup includes Georgia portions of cross-state MSAs.
}
\details{
Atlanta-Sandy Springs-Roswell has CBSA code 12060. Under this vintage, Lumpkin
County is included and Lamar County is not.
}
