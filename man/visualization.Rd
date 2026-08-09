\name{theme_peebles_chart}
\alias{theme_peebles_chart}
\alias{theme_peebles_map}
\alias{add_peebles_watermark}
\alias{save_peebles_plot}
\title{Peebles Chart and Map Helpers}
\usage{
theme_peebles_chart(base_size = 11, legend_position = "right",
  angle_x_labels = 25)

theme_peebles_map(base_size = 11, legend_position = "right")

add_peebles_watermark(label = "NOT FOR PUBLICATION", color = "gray40",
  alpha = 0.22, angle = 35, size = 34)

save_peebles_plot(plot, filename, folder = file.path("output", "graphics"),
  width = 9, height = 6, dpi = 300, ...)
}
\arguments{
\item{base_size}{Base font size.}
\item{legend_position}{A ggplot2 legend position.}
\item{angle_x_labels}{Angle for chart x-axis labels.}
\item{label}{Watermark text.}
\item{color}{Watermark color.}
\item{alpha}{Watermark opacity.}
\item{angle}{Watermark rotation in degrees.}
\item{size}{Watermark font size.}
\item{plot}{A ggplot object.}
\item{filename}{Output filename.}
\item{folder}{Output directory, created if necessary.}
\item{width}{Output width in inches.}
\item{height}{Output height in inches.}
\item{dpi}{Output resolution.}
\item{...}{Additional arguments passed to \code{ggplot2::ggsave()}.}
}
\value{Themes and annotations return ggplot2 components. The save helper
invisibly returns the original plot.}
\description{Apply consistent styling, watermarking, and export behavior.}
