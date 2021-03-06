
#' First regular expression match and positions
#'
#' Match a regular expression to a string, and return the first match,
#' match positions, and also capture groups, if any.
#'
#' The results are returned in a data frame with list columns. The strings
#' of the character vector correspond to the rows of the data frame.
#' The columns correspond to capture groups and the first matching
#' (sub)string. The columns of named capture groups are named accordingly,
#' the column called \code{.text} contains the input text, and the
#' column of the full match is last, and it is named \code{.match}.
#'
#' Each column of the result is a list, containing match records.
#' A match record is a named list, with entries \code{match}, \code{start}
#' and \code{end}; the matching (sub) string, the start and end positions
#' (using one based indexing).
#'
#' Non-matching strings contain NAs in their corresponding rows, for the
#' matches and the positions as well.
#'
#' To make it easier to extract matching substrings or positions, a
#' special \code{$} operator is defined on match columns. (Both the
#' \code{.match} column and the columns corresponsing to the match groups.)
#' See example below.
#'
#' @inheritParams re_match
#' @param x Object returned by \code{re_exec}.
#' @param name \code{match}, \code{start} or \code{end}.
#' @param perl logical should perl compatible regular expressions be used?
#' @return A data frame with list columns. See the details below.
#'
#' @family tidy regular expression matching
#' @export
#' @examples
#' name_rex <- paste0(
#'   "(?<first>[[:upper:]][[:lower:]]+) ",
#'   "(?<last>[[:upper:]][[:lower:]]+)"
#' )
#' notables <- c(
#'   "  Ben Franklin and Jefferson Davis",
#'   "\tMillard Fillmore"
#' )
#' pos <- re_exec(notables, name_rex)
#' pos
#'
#' # Custom $ to extract matches and positions
#' # for groups or the whole match
#' pos$first$match
#' pos$first$start
#' pos$first$end

re_exec <- function(text, pattern, perl=TRUE, ...) {

  stopifnot(is.character(pattern), length(pattern) == 1, !is.na(pattern))
  text <- as.character(text)

  match <- regexpr(pattern, text, perl = perl, ...)

  start  <- as.vector(match)
  length <- attr(match, "match.length")
  end    <- start + length - 1L

  matchstr <- substring(text, start, end)
  matchstr[ start == -1 ] <- NA_character_
  end     [ start == -1 ] <- NA_integer_
  start   [ start == -1 ] <- NA_integer_

  names <- c("match", "start", "end")

  matchlist <- structure(
    lapply(seq_along(text), function(i) {
      structure(list(matchstr[i], start[i], end[i]), names = names)
    }),
    class = "rematch_records"
  )

  res <- structure(
    list(text, matchlist),
    names = c(".text", ".match"),
    row.names = seq_along(text),
    class = c("tbl_df", "tbl", "data.frame")
  )

  if (!is.null(attr(match, "capture.start"))) {

    gstart  <- unname(attr(match, "capture.start"))
    glength <- unname(attr(match, "capture.length"))
    gend    <- gstart + glength - 1L

    groupstr <- substring(text, gstart, gend)
    groupstr[ gstart == -1 ] <- NA_character_
    gend    [ gstart == -1 ] <- NA_integer_
    gstart  [ gstart == -1 ] <- NA_integer_
    dim(groupstr) <- dim(gstart)

    grouplists <- lapply(
      seq_along(attr(match, "capture.names")),
      function(g) {
        structure(
          lapply(seq_along(text), function(i) {
            structure(
              list(groupstr[i, g], gstart[i, g], gend[i, g]),
              names = names
            )
          }),
          class = "rematch_records"
        )
      }
    )

    res <- structure(
      c(grouplists, res),
      names = c(attr(match, "capture.names"), ".text", ".match"),
      row.names = seq_along(text),
      class = c("tbl_df", "tbl", "data.frame")
    )
  }

  res
}
