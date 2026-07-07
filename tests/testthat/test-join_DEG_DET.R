deg_table <- data.frame(
  gene_id = c("gene1", "gene2"),
  gene_name = c("GeneA", "GeneB"),
  log2FC = c(1.5, -2.0),
  pvalue = c(0.01, 0.04)
)

det_table <- data.frame(
  transcript_id = c("tx1", "tx2", "tx3"),
  transcript_name = c("Transcript1", "Transcript2", "Transcript3"),
  transcript_type = c("protein_coding", "lncRNA", "processed_transcript"),
  log2FC = c(1.2, -1.8, 0.5),
  pvalue = c(0.02, 0.03, 0.2)
)

test_that("join_DEG_DET combines gene and transcript rows", {
  res <- join_DEG_DET(
    deg_table = deg_table,
    det_table = det_table,
    logfc_cut = 1,
    pval_cut = 0.05
  )

  expect_s3_class(res, "data.frame")
  expect_equal(nrow(res), 5L)
  expect_true(all(
    c(
      "feature_id",
      "feature_name",
      "feature_type",
      "log2FC",
      "pvalue",
      "is_de"
    ) %in%
      colnames(res)
  ))
  # DEG_sig / abs_log2FC are intermediate columns and must not leak out
  expect_false(any(c("DEG_sig", "abs_log2FC") %in% colnames(res)))
})

test_that("join_DEG_DET labels significance correctly", {
  res <- join_DEG_DET(
    deg_table = deg_table,
    det_table = det_table,
    logfc_cut = 1,
    pval_cut = 0.05
  )

  expected_is_de <- c("yes", "yes", "yes", "yes", "no")
  expect_equal(res$is_de, expected_is_de)
})

test_that("join_DEG_DET filters out non-relevant transcript types", {
  det_table_extra <- rbind(
    det_table,
    data.frame(
      transcript_id = "tx4",
      transcript_name = "Transcript4",
      transcript_type = "TEC",
      log2FC = 3,
      pvalue = 0.001
    )
  )
  res <- join_DEG_DET(
    deg_table = deg_table,
    det_table = det_table_extra,
    logfc_cut = 1,
    pval_cut = 0.05
  )
  expect_false("tx4" %in% res$feature_id)
})

test_that("join_DEG_DET works with positional arguments (backward compatible call style)", {
  res <- join_DEG_DET(deg_table, det_table, 1, 0.05)
  expect_equal(nrow(res), 5L)
})
