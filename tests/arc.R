library(peeblestoolbox)

expected_names <- c("Cherokee", "Clayton", "Cobb", "DeKalb", "Douglas",
                    "Fayette", "Forsyth", "Fulton", "Gwinnett", "Henry", "Rockdale")
expected_geoids <- c("13057", "13063", "13067", "13089", "13097", "13113",
                     "13117", "13121", "13135", "13151", "13247")
lookup <- arc_counties()
stopifnot(
  identical(lookup$county, expected_names),
  identical(lookup$county_geoid, expected_geoids),
  identical(lookup$county_fips, substring(expected_geoids, 3L)),
  all(lookup$state_abbr == "GA"), all(lookup$state_fips == "13"),
  !anyDuplicated(lookup$county_geoid),
  all(is_arc_county(lookup$county)),
  all(is_arc_county(county_fips = lookup$county_geoid)),
  all(is_arc_county(county_fips = lookup$county_fips)),
  all(is_arc_county(county_fips = as.integer(lookup$county_fips), state = 13)),
  identical(is_arc_county(c(" DEKALB COUNTY ", "De Kalb", "Forsyth", "Lumpkin",
                            "Coweta", "Atlanta", "", NA)),
            c(TRUE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE)),
  identical(is_arc_county(c("Forsyth", "Forsyth", "Fulton", "Fulton"),
                          state = c("NC", "Georgia", "Illinois", NA)),
            c(FALSE, TRUE, FALSE, FALSE)),
  identical(is_arc_county(county_fips = c("13121", "17121", "057", "057",
                                         "131210", "13-121", "13.121", "", NA),
                          state = c("NC", "GA", "13", "NC", rep("GA", 5))),
            c(TRUE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE)),
  identical(is_arc_county(character()), logical()),
  identical(is_arc_county(county_fips = character()), logical())
)

# Verify the literal GEOIDs against the independent bundled county lookup.
ga <- ga_msa_counties()
stopifnot(identical(
  sub(" County$", "", ga$county[match(expected_geoids, ga$county_geoid)]),
  expected_names
))

local({
  old <- options(warn = 2)
  on.exit(options(old))
  stopifnot(identical(
    is_arc_county(c("Fulton", "Fulton", "Forsyth", NA),
                  state = c("GA", "13", "North Carolina", NA)),
    c(TRUE, TRUE, FALSE, FALSE)
  ))
})

local({
  old <- options(peeblestoolbox.state = "NC")
  on.exit(options(old))
  stopifnot(is_arc_county("Forsyth"), nrow(arc_counties()) == 11L)
})

national <- data.frame(id = 1:5, county = c("Forsyth", "Forsyth", "Fulton",
                                          "Lumpkin", "Fulton"),
                       state = c("NC", "GA", "GA", "GA", "GA"))
selected <- national[is_arc_county(national$county, state = national$state), ]
stopifnot(identical(selected$id, c(2L, 3L, 5L)), identical(names(selected), names(national)))

expect_error <- function(expr) {
  stopifnot(inherits(tryCatch(force(expr), error = identity), "error"))
}
expect_error(is_arc_county())
expect_error(is_arc_county("Fulton", county_fips = "13121"))
expect_error(is_arc_county(c("Fulton", "Cobb"), state = c("GA", "GA", "NC")))
expect_error(is_arc_county("Fulton", state = NULL))
expect_error(is_arc_county("Fulton", state = "not a state"))
expect_error(is_arc_county(data.frame(county = "Fulton")))
