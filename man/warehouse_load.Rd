\name{warehouse_load_helpers}
\alias{warehouse_profile_text}
\alias{warehouse_clean_text}
\alias{warehouse_validate_schema}
\alias{warehouse_plan_load}
\alias{warehouse_write_chunks}
\title{Prepare and Safely Append Data to a Warehouse}
\usage{
warehouse_profile_text(data, columns = NULL)

warehouse_clean_text(data, columns = NULL, from = "",
  invalid = c("error", "substitute"), replacement = "\\ufffd",
  repair_mojibake = FALSE, squish_whitespace = TRUE)

warehouse_validate_schema(data, schema, allow_extra = FALSE)

warehouse_plan_load(connection, data, table, chunk_size = 100000L)

warehouse_write_chunks(connection, data, table, chunk_size = 100000L,
  execute = FALSE)
}
\arguments{
\item{data}{A data frame.}
\item{columns}{Character columns to inspect or clean; by default all character columns.}
\item{from}{Source encoding supplied to \code{iconv()}.}
\item{invalid}{Whether invalid encoding stops cleaning or uses a visible replacement.}
\item{replacement}{Replacement used when \code{invalid = "substitute"}.}
\item{repair_mojibake}{Whether to apply a small explicit set of common legacy text repairs.}
\item{squish_whitespace}{Whether to replace tabs, newlines, and repeated whitespace with spaces.}
\item{schema}{A named character vector containing SQL column definitions.}
\item{allow_extra}{Whether data columns absent from \code{schema} are allowed.}
\item{connection}{A valid DBI connection.}
\item{table}{An existing destination table name.}
\item{chunk_size}{Positive number of rows per insert chunk.}
\item{execute}{Set to \code{TRUE} to append; the default performs a dry run.}
}
\value{
The profile, validation result, dry-run plan, cleaned data with an audit
attribute, or completed-load audit, depending on the function.
}
\description{
Profile and conservatively clean difficult government-export text, validate
explicit schemas, inspect a proposed warehouse load, and append in controlled
chunks. The writer defaults to a dry run and never creates, drops, truncates,
or replaces a table. Text profiling reports leading Unicode byte-order marks,
and text cleaning removes them from column names and character values. Header
changes are recorded in the \code{warehouse_column_name_audit} attribute.
}
