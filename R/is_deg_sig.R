#' Annotate Transcripts with Differential Gene Expression Significance
#'
#' Adds a column to a transcript-level differential expression table indicating whether each transcript
#' originates from a gene that is significantly differentially expressed.
#'
#' @param deg_sig_vector A character vector containing the names of transcripts from significantly differentially expressed genes.
#' @param det_table A `data.frame` or `tibble` containing transcript-level differential expression results,
#'   including a `transcript_name` column.
#'
#' @returns A `tibble` with an additional column `DEG_sig` indicating whether the transcript is from a significantly
#'   differentially expressed gene (`"YES"` or `"NO"`). Row order matches the input `det_table`.
#'
#' @examples
#' # Sample data
#' significant_transcripts <- c("transcript1", "transcript3")
#' det_table <- data.frame(
#'   transcript_name = c("transcript1", "transcript2", "transcript3", "transcript4"),
#'   log2FC = c(2.5, -1.2, 0.8, -0.5),
#'   pvalue = c(0.01, 0.2, 0.03, 0.6)
#' )
#'
#' # Annotate transcripts with DEG significance
#' det_table_annotated <- is_deg_sig(
#'   deg_sig_vector = significant_transcripts,
#'   det_table = det_table
#' )
#'
#' # View the result
#' print(det_table_annotated)
#'
#' @export
is_deg_sig <- function(deg_sig_vector, det_table) {
  det_table |>
    dplyr::mutate(
      DEG_sig = dplyr::if_else(
        .data$transcript_name %in% deg_sig_vector,
        "YES",
        "NO"
      )
    )
}
