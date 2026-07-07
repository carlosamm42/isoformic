tx_to_gene <- tibble::tibble(
  transcript_id = c("tx1", "tx2", "tx3"),
  gene_id = c("gene1", "gene1", "gene2"),
  gene_name = c("GeneA", "GeneA", "GeneB"),
  transcript_name = c("Tx1", "Tx2", "Tx3"),
  transcript_type = c("protein_coding", "retained_intron", "protein_coding")
)

sample_metadata <- tibble::tibble(
  sample_id = c("s1", "s2", "s3", "s4"),
  condition = c("control", "control", "treated", "treated")
)

txi_transcript <- tibble::tibble(
  transcript_id = c("tx1", "tx2", "tx3"),
  s1 = c(10, 2, 20),
  s2 = c(12, 3, 19),
  s3 = c(5, 8, 21),
  s4 = c(6, 9, 22)
)

de_result_gene <- tibble::tibble(
  gene_name = c("GeneA", "GeneB"),
  log2FC = c(1.5, 0.2),
  qvalue = c(0.01, 0.5)
)

de_result_transcript <- tibble::tibble(
  transcript_name = c("Tx1", "Tx2", "Tx3"),
  log2FC = c(2.0, 0.1, 0.3),
  qvalue = c(0.01, 0.9, 0.8)
)

test_that("prepare_profile_data sets parent_gene to the actual gene name for gene-level rows (regression test)", {
  # Regression test for a bug where `parent_gene` was set to the literal
  # string "genename" instead of the `genename` column's values.
  res <- prepare_profile_data(
    txi_gene = NULL,
    txi_transcript = txi_transcript,
    sample_metadata = sample_metadata,
    tx_to_gene = tx_to_gene,
    de_result_gene = de_result_gene,
    de_result_transcript = de_result_transcript,
    var = "condition",
    var_levels = c("control", "treated"),
    gene_col = "gene_name",
    tx_col = "transcript_name"
  )

  gene_rows <- res[res$transcript_type == "gene", ]
  expect_true(nrow(gene_rows) > 0)
  expect_false(any(gene_rows$parent_gene == "genename"))
  expect_equal(gene_rows$parent_gene, gene_rows$genename)
})

test_that("prepare_profile_data associates transcripts with their parent gene", {
  res <- prepare_profile_data(
    txi_gene = NULL,
    txi_transcript = txi_transcript,
    sample_metadata = sample_metadata,
    tx_to_gene = tx_to_gene,
    de_result_gene = de_result_gene,
    de_result_transcript = de_result_transcript,
    var = "condition",
    var_levels = c("control", "treated"),
    gene_col = "gene_name",
    tx_col = "transcript_name"
  )

  tx1_rows <- res[res$genename == "Tx1", ]
  tx3_rows <- res[res$genename == "Tx3", ]
  expect_true(all(tx1_rows$parent_gene == "GeneA"))
  expect_true(all(tx3_rows$parent_gene == "GeneB"))
})

test_that("prepare_profile_data flags differentially expressed features", {
  res <- prepare_profile_data(
    txi_gene = NULL,
    txi_transcript = txi_transcript,
    sample_metadata = sample_metadata,
    tx_to_gene = tx_to_gene,
    de_result_gene = de_result_gene,
    de_result_transcript = de_result_transcript,
    var = "condition",
    var_levels = c("control", "treated"),
    gene_col = "gene_name",
    tx_col = "transcript_name"
  )

  gene_a_rows <- res[res$genename == "GeneA", ]
  gene_b_rows <- res[res$genename == "GeneB", ]
  expect_true(all(gene_a_rows$DE == "Yes"))
  expect_true(all(gene_b_rows$DE == "No"))
})
