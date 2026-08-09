export_geojson <- function(
    layer,
    filename,
    folder = file.path("output", "geojson"),
    overwrite = FALSE,
    quiet = TRUE
) {
  .require_toolbox_package("sf", "convert and export a GIS layer")

  if (inherits(layer, "sfc")) {
    layer <- sf::st_sf(geometry = layer)
  } else if (is.character(layer) && length(layer) == 1L) {
    if (!file.exists(layer)) {
      stop("GIS layer file does not exist: ", layer, call. = FALSE)
    }
    layer <- sf::st_read(layer, quiet = quiet)
  }

  if (!inherits(layer, "sf")) {
    stop(
      "`layer` must be an sf object, an sfc geometry vector, or a path ",
      "to a GIS layer that sf can read.",
      call. = FALSE
    )
  }

  if (is.na(sf::st_crs(layer))) {
    stop(
      "The GIS layer has no coordinate reference system. Assign its true CRS ",
      "before exporting; guessing could put the features in the wrong place.",
      call. = FALSE
    )
  }

  filename <- as.character(filename)
  if (length(filename) != 1L || is.na(filename) || !nzchar(trimws(filename))) {
    stop("`filename` must be one nonempty filename.", call. = FALSE)
  }

  if (!grepl("\\.geojson$", filename, ignore.case = TRUE)) {
    filename <- paste0(filename, ".geojson")
  }

  dir.create(folder, recursive = TRUE, showWarnings = FALSE)
  output_path <- file.path(folder, filename)

  if (file.exists(output_path) && !isTRUE(overwrite)) {
    stop(
      "Output already exists: ", output_path,
      ". Use `overwrite = TRUE` to replace it.",
      call. = FALSE
    )
  }

  wgs84_layer <- sf::st_transform(layer, 4326)

  sf::st_write(
    wgs84_layer,
    dsn = output_path,
    driver = "GeoJSON",
    delete_dsn = isTRUE(overwrite),
    quiet = quiet
  )

  output_path <- normalizePath(output_path, winslash = "/", mustWork = TRUE)
  message("Saved WGS84 GeoJSON: ", output_path)
  invisible(output_path)
}
