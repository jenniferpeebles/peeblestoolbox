# Remove a decoded Unicode byte-order mark only when it appears at the start.
# A BOM elsewhere in text may be an intentional zero-width no-break space.
.strip_leading_bom <- function(x) {
  has_bom <- !is.na(x) & startsWith(x, "\ufeff")
  x[has_bom] <- substring(x[has_bom], 2L)
  list(value = x, found = has_bom)
}

#' Profile character data before a warehouse load
#'
#' @param data A data frame.
#' @param columns Character columns to inspect. By default all character columns.
#' @return A data frame with encoding and text-quality diagnostics by column.
#' @export
warehouse_profile_text <- function(data, columns = NULL) {
  if (!is.data.frame(data)) stop("`data` must be a data frame.", call. = FALSE)

  if (is.null(columns)) {
    columns <- names(data)[vapply(data, is.character, logical(1))]
  }
  missing <- setdiff(columns, names(data))
  if (length(missing)) {
    stop("Missing column(s): ", paste(missing, collapse = ", "), call. = FALSE)
  }

  rows <- lapply(columns, function(column) {
    x <- as.character(data[[column]])
    nonmissing <- !is.na(x)
    utf8 <- iconv(x, from = "", to = "UTF-8", sub = NA_character_)
    invalid <- nonmissing & is.na(utf8)
    leading_bom <- nonmissing & startsWith(x, "\ufeff")
    has_control <- nonmissing & grepl("[[:cntrl:]]", x)
    has_nbsp <- nonmissing & grepl("\u00a0", x, fixed = TRUE)
    lengths <- nchar(x, type = "chars", allowNA = TRUE, keepNA = TRUE)

    data.frame(
      column = column,
      rows = length(x),
      missing_n = sum(!nonmissing),
      invalid_encoding_n = sum(invalid),
      leading_bom_n = sum(leading_bom),
      column_name_has_bom = startsWith(column, "\ufeff"),
      control_character_n = sum(has_control),
      nonbreaking_space_n = sum(has_nbsp),
      max_characters = if (all(is.na(lengths))) NA_integer_ else max(lengths, na.rm = TRUE),
      stringsAsFactors = FALSE
    )
  })

  if (!length(rows)) {
    return(data.frame(
      column = character(), rows = integer(), missing_n = integer(),
      invalid_encoding_n = integer(), leading_bom_n = integer(),
      column_name_has_bom = logical(), control_character_n = integer(),
      nonbreaking_space_n = integer(), max_characters = integer()
    ))
  }
  do.call(rbind, rows)
}

#' Clean character data for a MySQL or MariaDB load
#'
#' Cleaning is deliberately conservative. Invalid encodings stop the function by
#' default instead of silently deleting bytes. The returned data frame carries a
#' `warehouse_cleaning_audit` attribute describing changes by column.
#' Leading Unicode byte-order marks (`U+FEFF`) are removed from column names
#' and character values. Header changes are recorded in the
#' `warehouse_column_name_audit` attribute.
#'
#' @param data A data frame.
#' @param columns Character columns to clean. By default all character columns.
#' @param from Source encoding passed to `iconv()`. Use a known value such as
#'   `"latin1"` for legacy exports; the default lets R use marked/native encoding.
#' @param invalid Either `"error"` or `"substitute"`.
#' @param replacement Replacement used when `invalid = "substitute"`.
#' @param repair_mojibake Apply a short, explicit set of common Windows/UTF-8
#'   mojibake repairs. Keep this `FALSE` unless diagnostics support using it.
#' @param squish_whitespace Replace tabs/newlines and repeated whitespace with spaces.
#' @return A cleaned data frame with a `warehouse_cleaning_audit` attribute.
#' @export
warehouse_clean_text <- function(
    data,
    columns = NULL,
    from = "",
    invalid = c("error", "substitute"),
    replacement = "\ufffd",
    repair_mojibake = FALSE,
    squish_whitespace = TRUE
) {
  if (!is.data.frame(data)) stop("`data` must be a data frame.", call. = FALSE)
  invalid <- match.arg(invalid)

  original_names <- names(data)
  cleaned_names <- .strip_leading_bom(original_names)$value
  if (anyDuplicated(cleaned_names)) {
    stop("Removing leading byte-order marks would create duplicate column names.", call. = FALSE)
  }
  name_changed <- original_names != cleaned_names
  names(data) <- cleaned_names
  name_audit <- data.frame(
    original = original_names[name_changed],
    cleaned = cleaned_names[name_changed],
    stringsAsFactors = FALSE
  )

  if (is.null(columns)) columns <- names(data)[vapply(data, is.character, logical(1))]
  missing <- setdiff(columns, names(data))
  if (length(missing)) stop("Missing column(s): ", paste(missing, collapse = ", "), call. = FALSE)

  audit <- lapply(columns, function(column) {
    original <- as.character(data[[column]])
    checked <- iconv(original, from = from, to = "UTF-8", sub = NA_character_)
    bad <- !is.na(original) & is.na(checked)
    if (any(bad) && invalid == "error") {
      stop(
        "Column `", column, "` contains ", sum(bad),
        " value(s) that cannot be converted from ", if (nzchar(from)) from else "the marked/native encoding",
        " to UTF-8. No cleaned data was returned.", call. = FALSE
      )
    }

    x <- if (invalid == "substitute") {
      iconv(original, from = from, to = "UTF-8", sub = replacement)
    } else {
      checked
    }
    bom <- .strip_leading_bom(x)
    x <- bom$value
    x <- gsub("\u00a0", " ", x, fixed = TRUE)
    if (repair_mojibake) {
      mojibake_patterns <- c(
        "\u00e2\u20ac\u2122", "\u00e2\u20ac\u02dc",
        "\u00e2\u20ac\u0153", "\u00e2\u20ac\u009d",
        "\u00e2\u20ac\u201c", "\u00e2\u20ac\u201d"
      )
      mojibake_replacements <- c("'", "'", "\"", "\"", "-", "-")
      for (i in seq_along(mojibake_patterns)) {
        x <- gsub(mojibake_patterns[[i]], mojibake_replacements[[i]], x, fixed = TRUE)
      }
    }
    if (squish_whitespace) {
      x <- gsub("[\r\n\t]", " ", x)
      x <- gsub("[[:space:]]+", " ", x)
      x <- trimws(x)
    } else {
      x <- gsub("[[:cntrl:]&&[^\r\n\t]]", "", x)
    }
    Encoding(x) <- "UTF-8"
    changed <- !(is.na(original) & is.na(x)) & (is.na(original) | is.na(x) | original != x)
    data[[column]] <<- x

    data.frame(
      column = column,
      changed_n = sum(changed, na.rm = TRUE),
      invalid_encoding_n = sum(bad),
      leading_bom_n = sum(bom$found),
      stringsAsFactors = FALSE
    )
  })

  attr(data, "warehouse_cleaning_audit") <- if (length(audit)) do.call(rbind, audit) else data.frame(
    column = character(), changed_n = integer(), invalid_encoding_n = integer(),
    leading_bom_n = integer()
  )
  attr(data, "warehouse_column_name_audit") <- name_audit
  data
}

#' Validate a data frame against an explicit warehouse schema
#'
#' @param data A data frame.
#' @param schema A named character vector of SQL column definitions.
#' @param allow_extra Whether columns not present in `schema` are allowed.
#' @return A structured validation result with `ok`, `issues`, and column lists.
#' @export
warehouse_validate_schema <- function(data, schema, allow_extra = FALSE) {
  if (!is.data.frame(data)) stop("`data` must be a data frame.", call. = FALSE)
  if (!is.character(schema) || !length(schema) || is.null(names(schema)) || any(!nzchar(names(schema)))) {
    stop("`schema` must be a nonempty named character vector.", call. = FALSE)
  }
  if (anyDuplicated(names(schema))) stop("`schema` contains duplicate column names.", call. = FALSE)

  missing <- setdiff(names(schema), names(data))
  extra <- setdiff(names(data), names(schema))
  issues <- c(
    if (length(missing)) paste0("Missing schema column(s): ", paste(missing, collapse = ", ")),
    if (length(extra) && !allow_extra) paste0("Unexpected data column(s): ", paste(extra, collapse = ", "))
  )
  structure(
    list(ok = !length(issues), issues = issues, missing_columns = missing, extra_columns = extra,
         schema_columns = names(schema)),
    class = "warehouse_schema_validation"
  )
}

#' Plan a chunked warehouse write without changing the database
#'
#' @param connection A valid DBI connection.
#' @param data A data frame.
#' @param table Destination table name.
#' @param chunk_size Positive number of rows per chunk.
#' @return A one-row data frame describing the proposed write.
#' @export
warehouse_plan_load <- function(connection, data, table, chunk_size = 100000L) {
  .require_toolbox_package("DBI", "plan a warehouse load")
  if (!DBI::dbIsValid(connection)) stop("`connection` is not valid.", call. = FALSE)
  if (!is.data.frame(data)) stop("`data` must be a data frame.", call. = FALSE)
  if (!is.character(table) || length(table) != 1L || !nzchar(table)) stop("`table` must be one nonempty name.", call. = FALSE)
  chunk_size <- as.integer(chunk_size)
  if (is.na(chunk_size) || chunk_size < 1L) stop("`chunk_size` must be positive.", call. = FALSE)

  exists <- DBI::dbExistsTable(connection, table)
  existing_rows <- if (exists) DBI::dbGetQuery(
    connection,
    paste0("SELECT COUNT(*) AS n FROM ", as.character(DBI::dbQuoteIdentifier(connection, table)))
  )$n[[1]] else NA_real_

  data.frame(
    table = table,
    table_exists = exists,
    existing_rows = as.numeric(existing_rows),
    proposed_rows = nrow(data),
    columns = ncol(data),
    chunk_size = chunk_size,
    chunks = if (nrow(data)) ceiling(nrow(data) / chunk_size) else 0L,
    stringsAsFactors = FALSE
  )
}

#' Append data to an existing warehouse table in controlled chunks
#'
#' This function never creates, drops, truncates, or replaces a table. It defaults
#' to a dry run and requires `execute = TRUE` for writes.
#'
#' @param connection A valid DBI connection.
#' @param data A data frame whose columns already match the destination.
#' @param table Existing destination table.
#' @param chunk_size Positive number of rows per chunk.
#' @param execute Set `TRUE` to perform inserts; the default only returns a plan.
#' @return A load plan when dry-running, or a load audit after execution.
#' @export
warehouse_write_chunks <- function(connection, data, table, chunk_size = 100000L, execute = FALSE) {
  .require_toolbox_package("DBI", "write warehouse data")
  plan <- warehouse_plan_load(connection, data, table, chunk_size)
  if (!plan$table_exists) stop("Destination table does not exist: ", table, call. = FALSE)
  if (!isTRUE(execute)) return(plan)

  destination_fields <- DBI::dbListFields(connection, table)
  if (!identical(names(data), destination_fields)) {
    stop("Data columns and order do not exactly match the destination table.", call. = FALSE)
  }
  before <- plan$existing_rows
  if (!nrow(data)) {
    return(data.frame(table = table, rows_before = before, rows_requested = 0, rows_after = before,
                      row_count_matches = TRUE, stringsAsFactors = FALSE))
  }

  starts <- seq.int(1L, nrow(data), by = as.integer(chunk_size))
  for (i in seq_along(starts)) {
    first <- starts[[i]]
    last <- min(first + as.integer(chunk_size) - 1L, nrow(data))
    DBI::dbWriteTable(connection, table, data[first:last, , drop = FALSE], append = TRUE, row.names = FALSE)
    message("Loaded chunk ", i, "/", length(starts), " (rows ", first, "-", last, ") into ", table, ".")
  }
  after <- DBI::dbGetQuery(
    connection,
    paste0("SELECT COUNT(*) AS n FROM ", as.character(DBI::dbQuoteIdentifier(connection, table)))
  )$n[[1]]
  matches <- as.numeric(after) == as.numeric(before) + nrow(data)
  if (!matches) stop("Post-load row-count reconciliation failed for ", table, ".", call. = FALSE)

  data.frame(table = table, rows_before = as.numeric(before), rows_requested = nrow(data),
             rows_after = as.numeric(after), row_count_matches = matches, stringsAsFactors = FALSE)
}
