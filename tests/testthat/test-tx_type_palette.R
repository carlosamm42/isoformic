test_that("tx_type_palette returns a named character vector", {
  palette <- tx_type_palette()
  expect_type(palette, "character")
  expect_true(!is.null(names(palette)))
  expect_true(all(nzchar(names(palette))))
  expect_true(all(grepl("^#[0-9a-fA-F]{6}$", palette)))
})

test_that("tx_type_palette includes the core GENCODE transcript biotypes", {
  palette <- tx_type_palette()
  expect_true(all(
    c(
      "protein_coding",
      "retained_intron",
      "nonsense_mediated_decay",
      "gene"
    ) %in%
      names(palette)
  ))
})
