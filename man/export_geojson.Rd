\name{export_geojson}
\alias{export_geojson}
\title{Convert a GIS Layer to WGS84 and Export GeoJSON}
\usage{
export_geojson(layer, filename,
  folder = file.path("output", "geojson"),
  overwrite = FALSE, quiet = TRUE)
}
\arguments{
\item{layer}{An \code{sf} object, an \code{sfc} geometry vector, or a path to
a GIS layer readable by \code{sf::st_read()}.}
\item{filename}{Output filename. The \code{.geojson} extension is added when
it is omitted.}
\item{folder}{Output folder, created when necessary.}
\item{overwrite}{Whether an existing output file may be replaced.}
\item{quiet}{Whether to suppress messages from sf while reading and writing.}
}
\value{The normalized output path, invisibly.}
\description{
Read or accept a GIS layer, transform it to WGS84 longitude/latitude
(EPSG:4326), and write a GeoJSON file for handoff or publication.
}
\details{
The function refuses to guess when the input layer has no coordinate reference
system. Assign the layer's true source CRS before calling this function.
}
