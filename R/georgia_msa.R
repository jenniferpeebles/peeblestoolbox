.ga_msa_lookup <- function() {
  path <- system.file(
    "extdata",
    "georgia_msa_counties_2023.csv",
    package = "peeblestoolbox"
  )

  if (!nzchar(path)) {
    stop("The Georgia MSA lookup bundled with peeblestoolbox is missing.", call. = FALSE)
  }

  utils::read.csv(path, colClasses = "character", check.names = FALSE)
}

ga_msa_counties <- function(cbsa_code = NULL) {
  lookup <- .ga_msa_lookup()

  if (!is.null(cbsa_code)) {
    lookup <- lookup[lookup$cbsa_code %in% as.character(cbsa_code), , drop = FALSE]
  }

  rownames(lookup) <- NULL
  lookup
}

add_ga_msa <- function(data, county, county_fips = NULL) {
  stopifnot(is.data.frame(data))
  county_values <- data[[county]]

  if (is.null(county_values)) {
    stop("County column `", county, "` was not found.", call. = FALSE)
  }

  lookup <- .ga_msa_lookup()

  if (!is.null(county_fips)) {
    fips_values <- data[[county_fips]]
    if (is.null(fips_values)) {
      stop("County FIPS column `", county_fips, "` was not found.", call. = FALSE)
    }
    key <- sprintf("%05s", as.character(fips_values))
    key <- gsub(" ", "0", key, fixed = TRUE)
    matched <- match(key, lookup$county_geoid)
  } else {
    matched <- match(
      .normalize_county_name(county_values),
      .normalize_county_name(lookup$county)
    )
  }

  data$ga_msa_code <- lookup$cbsa_code[matched]
  data$ga_msa_name <- lookup$cbsa_title[matched]
  data$ga_msa_county_type <- lookup$county_type[matched]
  data$in_ga_msa <- !is.na(matched)
  data
}

is_atlanta_msa <- function(county) {
  lookup <- .ga_msa_lookup()
  atlanta <- lookup[lookup$cbsa_code == "12060", , drop = FALSE]
  .normalize_county_name(county) %in% .normalize_county_name(atlanta$county)
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
