add_peebles_watermark <- function(
    label = "NOT FOR PUBLICATION",
    color = "gray40",
    alpha = 0.22,
    angle = 35,
    size = 34
) {
  ggplot2::annotation_custom(
    grid::textGrob(
      label,
      x = grid::unit(0.5, "npc"),
      y = grid::unit(0.5, "npc"),
      rot = angle,
      gp = grid::gpar(
        col = grDevices::adjustcolor(color, alpha.f = alpha),
        fontsize = size,
        fontface = "bold"
      )
    )
  )
}

theme_peebles_map <- function(base_size = 11, legend_position = "right") {
  ggplot2::theme_void(base_size = base_size) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = 16),
      plot.subtitle = ggplot2::element_text(size = 11),
      plot.caption = ggplot2::element_text(color = "gray40", hjust = 0),
      legend.position = legend_position,
      panel.grid = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_blank()
    )
}

theme_peebles_chart <- function(
    base_size = 11,
    legend_position = "right",
    angle_x_labels = 25
) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = 16),
      plot.subtitle = ggplot2::element_text(size = 11),
      plot.caption = ggplot2::element_text(color = "gray40", hjust = 0),
      axis.text.x = ggplot2::element_text(
        angle = angle_x_labels,
        hjust = if (angle_x_labels == 0) 0.5 else 1
      ),
      panel.grid.minor = ggplot2::element_blank(),
      legend.position = legend_position
    )
}

save_peebles_plot <- function(
    plot,
    filename,
    folder = file.path("output", "graphics"),
    width = 9,
    height = 6,
    dpi = 300,
    ...
) {
  if (!inherits(plot, "ggplot")) {
    stop("`plot` must be a ggplot object.", call. = FALSE)
  }

  dir.create(folder, recursive = TRUE, showWarnings = FALSE)
  full_path <- file.path(folder, filename)

  ggplot2::ggsave(
    filename = full_path,
    plot = plot,
    width = width,
    height = height,
    dpi = dpi,
    ...
  )

  message("Saved plot: ", normalizePath(full_path, winslash = "/", mustWork = FALSE))
  invisible(plot)
}
