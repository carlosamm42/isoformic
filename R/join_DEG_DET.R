#' Merge Gene and Transcript Level Differential Expression Tables
#'
#' Combines gene-level and transcript-level differential expression results into a single table,
#' annotates the combined data with significance labels based on specified cutoffs, and filters
#' transcripts based on their types.
#'
#' @param deg_table A `data.frame` or `tibble` containing gene-level differential expression results,
#'   including `gene_id`, `gene_name`, `log2FC`, and `pvalue` columns.
#' @param det_table A `data.frame` or `tibble` containing transcript-level differential expression results,
#'   including `transcript_id`, `transcript_name`, `transcript_type`, `log2FC`, and `pvalue` columns.
#' @param logfc_cut A numeric value specifying the absolute log2 fold-change cutoff for significance.
#' @param pval_cut A numeric value specifying the p-value cutoff for significance.
#'
#' @returns A `tibble` combining gene and transcript differential expression results, with additional columns:
#'   - `id`: gene or transcript ID.
#'   - `name`: gene or transcript name.
#'   - `transcript_type`: type of transcript or `"gene"` for gene-level entries.
#'   - `abs_log2FC`: absolute value of log2 fold-change.
#'   - `significance`: `"sig"` if significant based on cutoffs, `"not_sig"` otherwise.
#'
#' @examples
#' # Sample gene-level data
#' deg_table <- data.frame(
#'   gene_id = c("gene1", "gene2"),
#'   gene_name = c("GeneA", "GeneB"),
#'   log2FC = c(1.5, -2.0),
#'   pvalue = c(0.01, 0.04)
#' )
#'
#' # Sample transcript-level data
#' det_table <- data.frame(
#'   transcript_id = c("tx1", "tx2", "tx3"),
#'   transcript_name = c("Transcript1", "Transcript2", "Transcript3"),
#'   transcript_type = c("protein_coding", "lncRNA", "processed_transcript"),
#'   log2FC = c(1.2, -1.8, 0.5),
#'   pvalue = c(0.02, 0.03, 0.2)
#' )
#'
#' # Merge and annotate differential expression results
#' deg_det_table <- join_DEG_DET(
#'   deg_table = deg_table,
#'   det_table = det_table,
#'   logfc_cut = 1,
#'   pval_cut = 0.05
#' )
#'
#' # View the result
#' print(deg_det_table)
#'
#' @export
join_DEG_DET <- function(
  deg_table,
  det_table,
  logfc_cut,
  pval_cut
) {
  deg_table_mod <- deg_table |>
    dplyr::rename(id = "gene_id")
  deg_table_mod <- deg_table_mod |>
    dplyr::rename(name = "gene_name")
  deg_table_mod <- deg_table_mod |>
    dplyr::mutate(transcript_type = "gene")
  deg_table_mod <- deg_table_mod |>
    dplyr::mutate(gene_name = .data[["name"]])

  det_table <- det_table |>
    dplyr::filter(
      .data[["transcript_type"]] %in%
        c(
          "retained_intron",
          "protein_coding_CDS_not_defined",
          "processed_transcript",
          "nonsense_mediated_decay",
          "lncRNA",
          "protein_coding",
          "pseudogene",
          "non_stop_decay",
          "processed_pseudogene",
          "transcribed_unprocessed_pseudogene",
          "transcribed_unitary_pseudogene",
          "unprocessed_pseudogene",
          "unitary_pseudogene"
        )
    )

  drop_columns <- c("DEG_sig")
  if (any(colnames(det_table) %in% drop_columns)) {
    det_table_mod <- det_table |>
      dplyr::select(-dplyr::any_of(drop_columns))
  } else {
    det_table_mod <- det_table
  }

  det_table_mod <- det_table_mod |>
    dplyr::rename(id = "transcript_id")
  det_table_mod <- det_table_mod |>
    dplyr::rename(name = "transcript_name")
  deg_table_mod <- deg_table_mod[
    colnames(deg_table_mod)[
      colnames(deg_table_mod) %in% colnames(det_table_mod)
    ]
  ]

  deg_det_table <- dplyr::bind_rows(deg_table_mod, det_table_mod)
  deg_det_table$abs_log2FC <- base::abs(deg_det_table$log2FC)
  deg_det_table$significance <- "not_sig"
  deg_det_table$DEG_sig <- "NO"
  deg_det_table$significance[
    deg_det_table$abs_log2FC > logfc_cut &
      deg_det_table$pvalue < pval_cut
  ] <- "sig"
  deg_det_table$DEG_sig[
    deg_det_table$abs_log2FC > logfc_cut &
      deg_det_table$pvalue < pval_cut
  ] <- "YES"

  deg_det_table <- deg_det_table |>
    dplyr::mutate(
      is_de = dplyr::if_else(.data$significance == "sig", "yes", "no")
    ) |>
    dplyr::rename(
      feature_id = "id",
      feature_name = "name",
      feature_type = "transcript_type"
    ) |>
    dplyr::select(
      -dplyr::any_of(c("abs_log2FC", "DEG_sig"))
    )
  return(deg_det_table)
}
