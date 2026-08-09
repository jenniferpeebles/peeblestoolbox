\name{warehouse_connect}
\alias{warehouse_connect}
\alias{warehouse_disconnect}
\title{Connect to and Disconnect from a MariaDB or MySQL Warehouse}
\usage{
warehouse_connect(host = Sys.getenv("WAREHOUSE_HOST"),
  user = Sys.getenv("WAREHOUSE_USER"),
  password = Sys.getenv("WAREHOUSE_PASSWORD"),
  dbname = Sys.getenv("WAREHOUSE_DATABASE"),
  port = Sys.getenv("WAREHOUSE_PORT", unset = "3306"), ...)

warehouse_disconnect(connection)
}
\arguments{
\item{host}{Database host, normally read from \code{WAREHOUSE_HOST}.}
\item{user}{Database user, normally read from \code{WAREHOUSE_USER}.}
\item{password}{Password, normally read from \code{WAREHOUSE_PASSWORD}.}
\item{dbname}{Database name, normally read from \code{WAREHOUSE_DATABASE}.}
\item{port}{Database port, normally read from \code{WAREHOUSE_PORT}.}
\item{...}{Additional arguments passed to \code{DBI::dbConnect()}.}
\item{connection}{A DBI connection.}
}
\value{A DBI connection, or an invisible result when disconnecting.}
\description{
Open a warehouse connection through RMariaDB using credentials stored outside
the project. No passwords are bundled with the package.
}
