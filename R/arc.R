# ARC's regional commission footprint, verified 2026-09-23:
# https://atlantaregional.org/about-arc/about-the-atlanta-region/
# Kept separate from the OMB MSA lookup and ARC's transportation planning area.
arc_counties <- function() {
  data.frame(
    county = c("Cherokee", "Clayton", "Cobb", "DeKalb", "Douglas", "Fayette",
               "Forsyth", "Fulton", "Gwinnett", "Henry", "Rockdale"),
    county_fips = c("057", "063", "067", "089", "097", "113", "117",
                    "121", "135", "151", "247"),
    county_geoid = c("13057", "13063", "13067", "13089", "13097", "13113",
                     "13117", "13121", "13135", "13151", "13247"),
    state_abbr = "GA",
    state_fips = "13",
    stringsAsFactors = FALSE
  )
}

is_arc_county <- function(county = NULL, county_fips = NULL, state = "GA") {
  if (is.null(county) == is.null(county_fips)) {
    stop("Supply exactly one of `county` or `county_fips`.", call. = FALSE)
  }
  values <- if (is.null(county_fips)) county else county_fips
  if (!is.atomic(values) || !is.null(dim(values))) {
    stop("County values must be a vector.", call. = FALSE)
  }
  n <- length(values)
  if (is.null(state) || !(length(state) %in% c(1L, n))) {
    stop("`state` must have length one or match the county vector.", call. = FALSE)
  }
  # Normalize distinct labels individually to support mixed names/FIPS without
  # coercion warnings, while avoiding repeated work on large datasets.
  state_values <- as.character(state)
  state_keys <- unique(state_values)
  normalized <- vapply(state_keys, .normalize_states, character(1),
                       allow_na = TRUE, USE.NAMES = FALSE)
  states <- rep_len(normalized[match(state_values, state_keys)], n)
  lookup <- arc_counties()

  if (is.null(county_fips)) {
    return(states %in% "GA" &
             .normalize_county_name(values) %in% .normalize_county_name(lookup$county))
  }

  codes <- trimws(as.character(values))
  # Full GEOIDs carry their own state; county-only codes need the supplied state.
  full <- !is.na(codes) & grepl("^[0-9]{5}$", codes)
  short <- !is.na(codes) & grepl("^[0-9]{1,3}$", codes)
  result <- rep(FALSE, n)
  result[full] <- codes[full] %in% lookup$county_geoid
  result[short] <- states[short] %in% "GA" &
    sprintf("%03d", as.integer(codes[short])) %in% lookup$county_fips
  result
}
