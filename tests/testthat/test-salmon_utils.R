test_that("salmon_index passes the user-supplied env_name through to condathis::run() (regression test)", {
  testthat::skip_if_not_installed("condathis")

  captured_args <- NULL
  mock_run <- function(...) {
    captured_args <<- list(...)
    invisible(NULL)
  }

  testthat::local_mocked_bindings(
    env_exists = function(...) TRUE,
    run = mock_run,
    .package = "condathis"
  )

  salmon_index(
    fasta_path = "transcripts.fa",
    index_path = "salmon_index",
    env_name = "my-custom-env"
  )

  expect_equal(captured_args$env_name, "my-custom-env")
})

test_that("salmon_quant passes the user-supplied env_name through to condathis::run() (regression test)", {
  testthat::skip_if_not_installed("condathis")

  captured_args <- NULL
  mock_run <- function(...) {
    captured_args <<- list(...)
    invisible(NULL)
  }

  index_dir <- withr::local_tempdir()

  testthat::local_mocked_bindings(
    env_exists = function(...) TRUE,
    run = mock_run,
    .package = "condathis"
  )

  salmon_quant(
    input_r1 = "reads_1.fq",
    index_path = index_dir,
    env_name = "another-custom-env"
  )

  expect_equal(captured_args$env_name, "another-custom-env")
})

test_that("salmon_index defaults to salmon-env when env_name is not supplied", {
  testthat::skip_if_not_installed("condathis")

  captured_args <- NULL
  mock_run <- function(...) {
    captured_args <<- list(...)
    invisible(NULL)
  }

  testthat::local_mocked_bindings(
    env_exists = function(...) TRUE,
    run = mock_run,
    .package = "condathis"
  )

  salmon_index(fasta_path = "transcripts.fa", index_path = "salmon_index")

  expect_equal(captured_args$env_name, "salmon-env")
})
