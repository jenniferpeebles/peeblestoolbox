\name{peebles_state}
\alias{peebles_state}
\alias{set_peebles_state}
\title{Get or Set the Default State}
\usage{
peebles_state()

set_peebles_state(state)
}
\arguments{
\item{state}{A state abbreviation, full name, or one- or two-digit state FIPS
code. The 50 states, District of Columbia, and Puerto Rico are supported.}
}
\value{
\code{peebles_state()} returns the current two-letter state abbreviation.
\code{set_peebles_state()} returns the normalized abbreviation invisibly.
}
\description{
Set the state used by state-aware PeeblesToolbox functions when their
\code{state} argument is omitted. Georgia is the default. Set the
\code{PEEBLESTOOLBOX_STATE} environment variable in a user-level
\code{.Renviron} file to choose a different default across R sessions.
}
\examples{
peebles_state()
set_peebles_state("North Carolina")
peebles_state()
set_peebles_state("GA")
}
