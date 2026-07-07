test_that("prepare_exon_annotation extracts exons for requested genes", {
  gff_path <- testthat::test_path("testdata", "mini.gff")

  res <- prepare_exon_annotation(
    gene_name = c("GENEA", "GENEB"),
    file_path = gff_path,
    file_type = "gff"
  )

  expect_s3_class(res, "tbl_df")
  expect_true(all(
    c("exon_left", "exon_right", "strand", "tx_id", "tx_name") %in%
      colnames(res)
  ))
  expect_equal(nrow(res), 4L)
  expect_setequal(unique(res$tx_id), c("tx1", "tx2", "tx3"))
  expect_true(all(res$tx_name %in% c("GENEA", "GENEB")))
})

test_that("prepare_exon_annotation filters by a single gene name", {
  gff_path <- testthat::test_path("testdata", "mini.gff")

  res <- prepare_exon_annotation(
    gene_name = "GENEB",
    file_path = gff_path,
    file_type = "gff"
  )

  expect_equal(nrow(res), 1L)
  expect_equal(unique(res$tx_id), "tx3")
})

test_that("prepare_exon_annotation errors for a missing file", {
  expect_error(
    prepare_exon_annotation(
      gene_name = "GENEA",
      file_path = "/nonexistent/file.gff",
      file_type = "gff"
    ),
    class = "isoformic_annot_file_dont_exist"
  )
})
