is_toggle <- function(x) {
  length(x) == 1 && is.logical(x) && !is.na(x)
}

is_path <- function(x) {
  length(x) == 1 && is.character(x) && !grepl("\n$", x)
}

read_lines <- function(path) {
  if (is.null(path)) return(NULL)
  readLines(path)
}

## from purrr, among other places
`%||%` <- function(x, y) {
  if (is.null(x)) {
    y
  } else {
    x
  }
}

## deparse that returns NULL for NULL instead of "NULL"
deparse2 <- function(expr, ...) {
  if (is.null(expr)) return(NULL)
  deparse(expr, ...)
}

prep_opts <- function(txt, which = "chunk") {
  txt <- deparse2(txt)
  setter <- paste0("knitr::opts_", which, "$set")
  sub("^list", setter, txt)
}

trim_ws <- function(x) {
  sub("\\s*$", "", sub("^\\s*", "", x))
}

trim_common_leading_ws <- function(x) {
  m <- regexpr("^(\\s*)", x)
  ws <- regmatches(x, m)
  num <- min(nchar(ws))
  substring(x, num + 1)
}

ingest_input <- function(input = NULL) {
  if (is.null(input)) { ## clipboard or bust
    if (clipboard_available()) {
      return(suppressWarnings(clipr::read_clip()))
    } else {
      message("No input provided and clipboard is not available.")
      return(character())
    }
  }

  if (is_path(input)) { ## path
    read_lines(input)
  } else {
    escape_newlines(sub("\n$", "", input)) ## vector or string
  }
}

escape_regex <- function(x) {
  chars <- c("*", ".", "?", "^", "+", "$", "|", "(", ")", "[", "]", "{", "}", "\\")
  gsub(paste0("([\\", paste0(collapse = "\\", chars), "])"), "\\\\\\1", x, perl = TRUE)
}

escape_newlines <- function(x) {
  gsub("\n", "\\\\n", x, perl = TRUE)
}

ds_is_gh <- function(venue) {
  if (venue == "ds") {
    message(
      "FYI, the Discourse venue \"ds\" is currently an alias for the ",
      "default GitHub venue \"gh\".\nYou don't need to specify it."
    )
    venue <- "gh"
  }
  venue
}

pandoc2.0 <- function() rmarkdown::pandoc_available("2.0")

enfence <- function(lines,
                    tag = NULL,
                    fallback = "-- nothing to show --") {
  if (length(lines) == 0) {
    lines <- fallback
  }
  paste0(c(tag, "``` sh", lines, "```"), collapse = "\n")
}

inject_file <- function(path, inject_path, pre_process = identity, ...) {
  lines <- readLines(path, encoding = "UTF-8")
  inject_lines <- readLines(inject_path, encoding = "UTF-8")
  inject_lines <- pre_process(inject_lines, ...)

  inject_locus <- grep(paste0("`", inject_path, "`"), lines, fixed = TRUE)
  lines <- c(
    lines[seq_len(inject_locus - 1)],
    inject_lines,
    lines[-seq_len(inject_locus)]
  )
  writeLines(lines, path)
  path
}
