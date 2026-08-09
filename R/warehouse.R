warehouse_connect <- function(
    host = Sys.getenv("WAREHOUSE_HOST"),
    user = Sys.getenv("WAREHOUSE_USER"),
    password = Sys.getenv("WAREHOUSE_PASSWORD"),
    dbname = Sys.getenv("WAREHOUSE_DATABASE"),
    port = Sys.getenv("WAREHOUSE_PORT", unset = "3306"),
    ...
) {
  .require_toolbox_package("DBI", "connect to the data warehouse")
  .require_toolbox_package("RMariaDB", "connect to the data warehouse")

  settings <- c(
    WAREHOUSE_HOST = host,
    WAREHOUSE_USER = user,
    WAREHOUSE_PASSWORD = password,
    WAREHOUSE_DATABASE = dbname
  )
  missing <- names(settings)[!nzchar(settings)]

  if (length(missing) > 0) {
    stop(
      "Missing warehouse settings: ",
      paste(missing, collapse = ", "),
      ". Put these values in your user .Renviron file; never save passwords ",
      "inside a project or package.",
      call. = FALSE
    )
  }

  port <- suppressWarnings(as.integer(port))
  if (is.na(port)) {
    stop("WAREHOUSE_PORT must be a number.", call. = FALSE)
  }

  DBI::dbConnect(
    RMariaDB::MariaDB(),
    host = host,
    user = user,
    password = password,
    dbname = dbname,
    port = port,
    ...
  )
}

warehouse_disconnect <- function(connection) {
  .require_toolbox_package("DBI", "disconnect from the data warehouse")

  if (DBI::dbIsValid(connection)) {
    DBI::dbDisconnect(connection)
  } else {
    invisible(TRUE)
  }
}
