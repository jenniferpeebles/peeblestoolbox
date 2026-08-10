.state_reference <- function() {
  data.frame(
    state_abbr = c(
      "AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "DC", "FL", "GA",
      "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", "MA",
      "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY",
      "NC", "ND", "OH", "OK", "OR", "PA", "PR", "RI", "SC", "SD", "TN",
      "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY"
    ),
    state_name = c(
      "Alabama", "Alaska", "Arizona", "Arkansas", "California", "Colorado",
      "Connecticut", "Delaware", "District of Columbia", "Florida", "Georgia",
      "Hawaii", "Idaho", "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky",
      "Louisiana", "Maine", "Maryland", "Massachusetts", "Michigan", "Minnesota",
      "Mississippi", "Missouri", "Montana", "Nebraska", "Nevada", "New Hampshire",
      "New Jersey", "New Mexico", "New York", "North Carolina", "North Dakota",
      "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "Puerto Rico", "Rhode Island",
      "South Carolina", "South Dakota", "Tennessee", "Texas", "Utah", "Vermont",
      "Virginia", "Washington", "West Virginia", "Wisconsin", "Wyoming"
    ),
    state_fips = c(
      "01", "02", "04", "05", "06", "08", "09", "10", "11", "12", "13",
      "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25",
      "26", "27", "28", "29", "30", "31", "32", "33", "34", "35", "36",
      "37", "38", "39", "40", "41", "42", "72", "44", "45", "46", "47",
      "48", "49", "50", "51", "53", "54", "55", "56"
    ),
    stringsAsFactors = FALSE
  )
}

.normalize_states <- function(state, allow_na = FALSE) {
  if (is.null(state)) {
    return(NULL)
  }

  values <- trimws(as.character(state))
  missing_values <- is.na(values) | !nzchar(values)
  reference <- .state_reference()
  normalized <- rep(NA_character_, length(values))

  abbreviation_match <- match(toupper(values), reference$state_abbr)
  name_match <- match(tolower(values), tolower(reference$state_name))
  fips_values <- ifelse(grepl("^[0-9]{1,2}$", values), sprintf("%02d", as.integer(values)), NA_character_)
  fips_match <- match(fips_values, reference$state_fips)

  normalized[!is.na(abbreviation_match)] <- reference$state_abbr[abbreviation_match[!is.na(abbreviation_match)]]
  normalized[is.na(normalized) & !is.na(name_match)] <- reference$state_abbr[name_match[is.na(normalized) & !is.na(name_match)]]
  normalized[is.na(normalized) & !is.na(fips_match)] <- reference$state_abbr[fips_match[is.na(normalized) & !is.na(fips_match)]]

  invalid_values <- is.na(normalized) & !(allow_na & missing_values)
  if (any(invalid_values)) {
    invalid <- unique(values[invalid_values])
    stop(
      "Unknown state value: ", paste(invalid, collapse = ", "),
      ". Use a state abbreviation, full name, or FIPS code.",
      call. = FALSE
    )
  }

  normalized
}

peebles_state <- function() {
  state <- getOption("peeblestoolbox.state")
  if (is.null(state) || !length(state) || !nzchar(as.character(state[[1]]))) {
    state <- Sys.getenv("PEEBLESTOOLBOX_STATE", unset = "GA")
  }
  .normalize_states(state[[1]])
}

set_peebles_state <- function(state) {
  state <- .normalize_states(state)
  if (length(state) != 1L) {
    stop("`state` must identify exactly one state.", call. = FALSE)
  }
  options(peeblestoolbox.state = state)
  invisible(state)
}

.msa_lookup <- function() {
  path <- system.file(
    "extdata",
    "msa_counties_2023.csv",
    package = "peeblestoolbox"
  )

  if (!nzchar(path)) {
    stop("The national MSA lookup bundled with peeblestoolbox is missing.", call. = FALSE)
  }

  lookup <- utils::read.csv(path, colClasses = "character", check.names = FALSE)
  names(lookup)[names(lookup) == "geoid"] <- "county_geoid"
  names(lookup)[names(lookup) == "county_or_equivalent"] <- "county"
  names(lookup)[names(lookup) == "state"] <- "state_name"
  names(lookup)[names(lookup) == "central_outlying"] <- "county_type"
  names(lookup)[names(lookup) == "metropolitan_division_code"] <- "metro_division_code"
  names(lookup)[names(lookup) == "metropolitan_division_title"] <- "metro_division_name"
  names(lookup)[names(lookup) == "csa_title"] <- "csa_name"

  reference <- .state_reference()
  lookup$state_abbr <- reference$state_abbr[match(lookup$state_fips, reference$state_fips)]

  lookup[c(
    "cbsa_code", "cbsa_title", "metro_division_code", "metro_division_name",
    "csa_code", "csa_name", "county_geoid", "state_fips", "state_abbr",
    "state_name", "county_fips", "county", "county_type", "delineation_date"
  )]
}

msa_counties <- function(state = peebles_state(), cbsa_code = NULL) {
  lookup <- .msa_lookup()

  if (!is.null(state)) {
    lookup <- lookup[lookup$state_abbr %in% .normalize_states(state), , drop = FALSE]
  }
  if (!is.null(cbsa_code)) {
    lookup <- lookup[lookup$cbsa_code %in% as.character(cbsa_code), , drop = FALSE]
  }

  rownames(lookup) <- NULL
  lookup
}

add_msa <- function(
    data,
    county = NULL,
    county_fips = NULL,
    state = peebles_state(),
    state_column = NULL
) {
  stopifnot(is.data.frame(data))
  lookup <- .msa_lookup()

  if (!is.null(state_column)) {
    state_values <- data[[state_column]]
    if (is.null(state_values)) {
      stop("State column `", state_column, "` was not found.", call. = FALSE)
    }
    state_abbr <- .normalize_states(state_values, allow_na = TRUE)
  } else {
    state_abbr <- .normalize_states(state)
    if (length(state_abbr) != 1L) {
      stop("`state` must identify exactly one state when `state_column` is not used.", call. = FALSE)
    }
    state_abbr <- rep(state_abbr, nrow(data))
  }

  if (!is.null(county_fips)) {
    fips_values <- data[[county_fips]]
    if (is.null(fips_values)) {
      stop("County FIPS column `", county_fips, "` was not found.", call. = FALSE)
    }
    digits <- gsub("[^0-9]", "", as.character(fips_values))
    state_reference <- .state_reference()
    state_fips <- state_reference$state_fips[match(state_abbr, state_reference$state_abbr)]
    key <- rep(NA_character_, length(digits))
    valid <- !is.na(fips_values) & nzchar(digits) & nchar(digits) <= 5L
    full_geoid <- valid & nchar(digits) > 3L
    county_only <- valid & nchar(digits) <= 3L
    key[full_geoid] <- sprintf("%05d", as.integer(digits[full_geoid]))
    key[county_only] <- paste0(
      state_fips[county_only],
      sprintf("%03d", as.integer(digits[county_only]))
    )
    matched <- match(key, lookup$county_geoid)
  } else {
    if (is.null(county)) {
      stop("Supply the name of a county column or a `county_fips` column.", call. = FALSE)
    }
    county_values <- data[[county]]
    if (is.null(county_values)) {
      stop("County column `", county, "` was not found.", call. = FALSE)
    }
    key <- paste(state_abbr, .normalize_county_name(county_values), sep = "|")
    lookup_key <- paste(lookup$state_abbr, .normalize_county_name(lookup$county), sep = "|")
    matched <- match(key, lookup_key)
  }

  data$msa_code <- lookup$cbsa_code[matched]
  data$msa_name <- lookup$cbsa_title[matched]
  data$metro_division_code <- lookup$metro_division_code[matched]
  data$metro_division_name <- lookup$metro_division_name[matched]
  data$csa_code <- lookup$csa_code[matched]
  data$csa_name <- lookup$csa_name[matched]
  data$msa_county_type <- lookup$county_type[matched]
  data$in_msa <- !is.na(matched)
  data
}

is_msa_county <- function(county, cbsa_code, state = peebles_state()) {
  lookup <- msa_counties(state = state, cbsa_code = cbsa_code)
  .normalize_county_name(county) %in% .normalize_county_name(lookup$county)
}

ga_msa_counties <- function(cbsa_code = NULL) {
  msa_counties(state = "GA", cbsa_code = cbsa_code)
}

add_ga_msa <- function(data, county, county_fips = NULL) {
  classified <- add_msa(
    data,
    county = county,
    county_fips = county_fips,
    state = "GA"
  )
  data$ga_msa_code <- classified$msa_code
  data$ga_msa_name <- classified$msa_name
  data$ga_msa_county_type <- classified$msa_county_type
  data$in_ga_msa <- classified$in_msa
  data
}

is_atlanta_msa <- function(county) {
  is_msa_county(county, cbsa_code = "12060", state = "GA")
}

add_atlanta_msa <- function(data, county) {
  stopifnot(is.data.frame(data))
  county_values <- data[[county]]

  if (is.null(county_values)) {
    stop("County column `", county, "` was not found.", call. = FALSE)
  }

  data$in_atlanta_msa <- is_atlanta_msa(county_values)
  data
}
