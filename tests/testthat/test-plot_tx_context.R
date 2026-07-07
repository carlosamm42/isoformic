exon_table <- tibble::tibble(
  tx_id = c("tx1", "tx1", "tx1", "tx2", "tx2"),
  exon_left = c(1L, 20L, 40L, 5L, 25L),
  exon_right = c(10L, 30L, 50L, 15L, 35L),
  transcript_type = "protein_coding",
  transcript_name = c("TX1", "TX1", "TX1", "TX2", "TX2")
)

test_that("plot_tx_context returns a ggplot object", {
  p <- plot_tx_context(exon_table)
  expect_s3_class(p, "ggplot")
})

test_that("plot_tx_context sets segment coordinates to NA only for the last exon of each transcript (regression test)", {
  # Regression test for the refactor of a per-transcript `for` loop into a
  # vectorized `dplyr::group_by()` + `dplyr::mutate()` pipeline: only the
  # last exon (by `exon_right`) of each `tx_id` should have its connecting
  # segment coordinates set to NA.
  p <- plot_tx_context(exon_table)
  built <- ggplot2::ggplot_build(p)

  # first geom_segment layer: exon_right -> segment_middle
  segment_layer_1 <- built$data[[2]]
  na_rows <- which(is.na(segment_layer_1$x))
  expect_length(na_rows, 2L)

  # the NA segments should correspond to the rows with the maximum
  # exon_right within each tx_id (the last exon of tx1 and tx2)
  arranged <- exon_table[order(exon_table$tx_id, exon_table$exon_right), ]
  last_exon_idx <- c(
    which(
      arranged$tx_id == "tx1" &
        arranged$exon_right == max(arranged$exon_right[arranged$tx_id == "tx1"])
    ),
    which(
      arranged$tx_id == "tx2" &
        arranged$exon_right == max(arranged$exon_right[arranged$tx_id == "tx2"])
    )
  )
  expect_setequal(na_rows, last_exon_idx)
})
