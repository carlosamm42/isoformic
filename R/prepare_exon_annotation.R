#' Prepare Exon based Position Annotation Table
#' @param gene_name String or vector of gene names to extract.
#' @param file_path Path to annotation file.
#' @inheritParams download_reference
#' @export
prepare_exon_annotation <- function(
  gene_name,
  file_path,
  file_type = c("gff", "gtf")
) {
  file_type <- stringr::str_to_lower(file_type)
  file_type <- rlang::arg_match(file_type)
  assert_file_exists(file_path)
  if (isTRUE(file_type %in% c("gff"))) {
    gff_file_path <- fs::path(file_path)
    annot_df <- readr::read_table(
      file = gff_file_path,
      col_names = FALSE,
      col_types = readr::cols(
        X1 = readr::col_skip(),
        X2 = readr::col_skip(),
        X3 = "c",
        X4 = "c",
        X5 = "c",
        X6 = readr::col_skip(),
        X7 = "c",
        X8 = readr::col_skip(),
        X9 = "c"
      ),
      comment = "#",
      progress = FALSE
    )
  }
  gene_annot_df <- tibble::tibble()
  if (length(gene_name) > 0L) {
    gene_pattern <- paste(
      paste0("gene_name=", gene_name, ";"),
      collapse = "|"
    )
    gene_annot_df <- annot_df |>
      dplyr::filter(stringr::str_detect(.data$X9, gene_pattern))
  }

  tx_id_vector <- gene_annot_df |>
    dplyr::filter(.data$X3 %in% "transcript") |>
    dplyr::select("X9") |>
    dplyr::mutate(
      tx_id = stringr::str_extract(.data$X9, "transcript_id=.*?;") |>
        stringr::str_remove("^transcript_id=") |>
        stringr::str_remove(";")
    ) |>
    dplyr::select("tx_id") |>
    dplyr::distinct() |>
    dplyr::pull("tx_id")

  # Single vectorized pass over all exons instead of one `str_detect()` scan
  # of the whole table per transcript (previously via `purrr::map_dfr()`).
  tx_exon_table <- gene_annot_df |>
    dplyr::filter(.data$X3 %in% "exon") |>
    dplyr::mutate(
      tx_id = stringr::str_extract(.data$X9, "Parent=.*?;") |>
        stringr::str_remove("^Parent=") |>
        stringr::str_remove(";"),
      tx_name = stringr::str_extract(.data$X9, "gene_name=.*?;") |>
        stringr::str_remove("^gene_name=") |>
        stringr::str_remove(";")
    ) |>
    dplyr::filter(.data$tx_id %in% tx_id_vector) |>
    dplyr::select(c("X4", "X5", "X7", "tx_id", "tx_name")) |>
    dplyr::relocate("tx_name", .after = "tx_id")
  # dplyr::mutate(tx_name = gene_name)
  tx_exon_table <- tx_exon_table |>
    dplyr::rename(
      `exon_left` = "X4",
      `exon_right` = "X5",
      `strand` = "X7"
    )
  return(tx_exon_table)
}
