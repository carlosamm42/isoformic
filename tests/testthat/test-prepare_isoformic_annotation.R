test_that("prepare_isoformic_annotation + IsoformicExperiment integration works end-to-end", {
  testthat::skip_if_not_installed("duckdb")
  testthat::skip_if_not_installed("arrow")

  gff_path <- testthat::test_path("testdata", "mini.gff")
  parquet_dir <- withr::local_tempdir()

  annot_dir <- prepare_isoformic_annotation(
    input_path = gff_path,
    output_path = parquet_dir,
    file_type = "gff"
  )

  expect_true(fs::dir_exists(annot_dir))
  expect_true(fs::file_exists(fs::path(annot_dir, "annot_data_genes.parquet")))
  expect_true(fs::file_exists(fs::path(
    annot_dir,
    "annot_data_transcripts.parquet"
  )))
  expect_true(fs::file_exists(fs::path(annot_dir, "annot_data_exons.parquet")))

  assay_mat <- matrix(
    c(10, 20, 30, 40, 50, 60),
    nrow = 3,
    ncol = 2,
    dimnames = list(c("tx1", "tx2", "tx3"), c("s1", "s2"))
  )
  col_data <- tibble::tibble(sample_id = c("s1", "s2"), condition = c("a", "b"))

  iso <- IsoformicExperiment(
    experiment_name = "test_exp",
    annot_path = annot_dir,
    assay = list(tpm = assay_mat),
    col_data = col_data
  )

  expect_s7_class(iso, IsoformicExperiment)
  expect_equal(nrow(annot_data_genes(iso) |> dplyr::collect()), 2L)
  expect_equal(nrow(annot_data_transcripts(iso) |> dplyr::collect()), 3L)
  expect_equal(nrow(annot_data_exons(iso) |> dplyr::collect()), 4L)

  tx2gene <- tx_to_gene(iso)
  expect_setequal(tx2gene$transcript_id, c("tx1", "tx2", "tx3"))
  expect_equal(tx2gene$gene_id[tx2gene$transcript_id == "tx1"], "gene1")
})

test_that("tx_annot() and row_data() return consistent, deduplicated annotation (regression test for shared helper)", {
  # Regression test for refactoring `tx_annot()` and `row_data()` (which
  # were previously near-duplicated implementations) into a shared
  # `get_tx_gene_annot()` helper.
  testthat::skip_if_not_installed("duckdb")
  testthat::skip_if_not_installed("arrow")

  gff_path <- testthat::test_path("testdata", "mini.gff")
  parquet_dir <- withr::local_tempdir()
  annot_dir <- prepare_isoformic_annotation(
    input_path = gff_path,
    output_path = parquet_dir,
    file_type = "gff"
  )

  assay_mat <- matrix(
    c(10, 20, 30),
    nrow = 3,
    ncol = 1,
    dimnames = list(c("tx1", "tx2", "tx3"), c("s1"))
  )
  col_data <- tibble::tibble(sample_id = "s1", condition = "a")

  iso <- IsoformicExperiment(
    experiment_name = "test_exp2",
    annot_path = annot_dir,
    assay = list(tpm = assay_mat),
    col_data = col_data
  )

  tx_annot_res <- tx_annot(iso)
  row_data_res <- row_data(iso)

  expect_true(all(
    c("transcript_id", "gene_id", "gene_name", "gene_type") %in%
      colnames(tx_annot_res)
  ))
  # tx_annot() returns all annotated transcripts; row_data() is filtered to
  # the transcript IDs present in the object's assay. With all 3 transcripts
  # present in the assay here, they should be identical.
  expect_equal(nrow(tx_annot_res), 3L)
  expect_equal(
    dplyr::arrange(tx_annot_res, .data$transcript_id),
    dplyr::arrange(row_data_res, .data$transcript_id)
  )

  # position columns must be dropped from both
  expect_false(any(
    c("seqid", "start_pos", "end_pos", "strand") %in% colnames(tx_annot_res)
  ))
  expect_false(any(
    c("seqid", "start_pos", "end_pos", "strand") %in% colnames(row_data_res)
  ))
})

test_that("row_data() filters down to the assay's transcript IDs", {
  testthat::skip_if_not_installed("duckdb")
  testthat::skip_if_not_installed("arrow")

  gff_path <- testthat::test_path("testdata", "mini.gff")
  parquet_dir <- withr::local_tempdir()
  annot_dir <- prepare_isoformic_annotation(
    input_path = gff_path,
    output_path = parquet_dir,
    file_type = "gff"
  )

  # only include tx1 and tx3 in the assay
  assay_mat <- matrix(
    c(10, 20),
    nrow = 2,
    ncol = 1,
    dimnames = list(c("tx1", "tx3"), c("s1"))
  )
  col_data <- tibble::tibble(sample_id = "s1", condition = "a")

  iso <- IsoformicExperiment(
    experiment_name = "test_exp3",
    annot_path = annot_dir,
    assay = list(tpm = assay_mat),
    col_data = col_data
  )

  row_data_res <- row_data(iso)
  expect_setequal(row_data_res$transcript_id, c("tx1", "tx3"))
  expect_false("tx2" %in% row_data_res$transcript_id)
})
