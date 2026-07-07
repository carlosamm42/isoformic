#' Assert That a File Path Exists
#'
#' Shared validation helper used by the annotation-preparation functions to
#' check that an input file exists before attempting to read it, raising a
#' consistent, catchable `cli_abort()` error otherwise.
#'
#' @param path Character string with the path to check.
#'
#' @keywords internal
#' @noRd
assert_file_exists <- function(path) {
  if (!isTRUE(fs::file_exists(path))) {
    cli::cli_abort(
      message = c(
        x = "{.path {path}} do {.strong not} exist."
      ),
      class = "isoformic_annot_file_dont_exist"
    )
  }
  return(invisible(TRUE))
}
