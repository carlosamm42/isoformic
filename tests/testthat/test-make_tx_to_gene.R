make_fasta_fixture <- function() {
  lines <- c(
    ">ENST00000001.1|ENSG00000001.1|OTTHUMG00000001.1|OTTHUMT00000001.1|GENEA-201|GENEA|1000|protein_coding|",
    "ACGTACGTACGT",
    ">ENST00000002.1|ENSG00000001.1|OTTHUMG00000001.1|OTTHUMT00000002.1|GENEA-202|GENEA|500|retained_intron|",
    "ACGTACGT"
  )
  fasta_path <- withr::local_tempfile(
    lines = lines,
    .local_envir = testthat::teardown_env()
  )
  fasta_path
}

test_that("make_tx_to_gene parses GENCODE-style FASTA headers", {
  fasta_path <- make_fasta_fixture()

  res <- make_tx_to_gene(file_path = fasta_path, file_type = "fasta")

  expect_s3_class(res, "tbl_df")
  expect_equal(
    colnames(res),
    c(
      "transcript_id",
      "gene_id",
      "havanna_gene_id",
      "havanna_transcript_id",
      "transcript_name",
      "gene_name",
      "tx_length",
      "transcript_type"
    )
  )
  expect_equal(nrow(res), 2L)
  expect_equal(res$transcript_id, c("ENST00000001.1", "ENST00000002.1"))
  expect_equal(res$gene_name, c("GENEA", "GENEA"))
  expect_equal(res$transcript_type, c("protein_coding", "retained_intron"))
})

test_that("make_tx_to_gene errors for a missing file", {
  expect_error(
    make_tx_to_gene(file_path = "/nonexistent/file.fasta", file_type = "fasta"),
    class = "isoformic_annot_file_dont_exist"
  )
})

test_that("make_tx_to_gene errors for unsupported gff/gtf file types", {
  fasta_path <- make_fasta_fixture()
  expect_error(
    make_tx_to_gene(file_path = fasta_path, file_type = "gff")
  )
})
