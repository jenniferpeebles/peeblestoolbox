.require_toolbox_package <- function(package, purpose) {
  if (!requireNamespace(package, quietly = TRUE)) {
    stop(
      "Package `", package, "` is required to ", purpose, ". ",
      "Install it with install.packages(\"", package, "\").",
      call. = FALSE
    )
  }
}

.normalize_county_name <- function(x) {
  x <- trimws(as.character(x))
  x <- sub("[[:space:]]+county[[:space:]]*$", "", x, ignore.case = TRUE)
  x <- gsub("[^[:alnum:]]", "", x)
  tolower(x)
}
