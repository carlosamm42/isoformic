test_that("duckdb_run runs a simple query in-memory with read_only = FALSE", {
  testthat::skip_if_not_installed("duckdb")
  expect_null(
    duckdb_run(
      sql_string = "SELECT 1 AS x;",
      db_type = "duckdb_memory",
      db_file_path = NULL,
      read_only = FALSE
    )
  )
})

test_that("duckdb_run runs a simple query in-memory with read_only = TRUE", {
  testthat::skip_if_not_installed("duckdb")
  expect_null(
    duckdb_run(
      sql_string = "SELECT 1 AS x;",
      db_type = "duckdb_memory",
      db_file_path = NULL,
      read_only = TRUE
    )
  )
})

test_that("duckdb_run validates that read_only is a scalar logical", {
  expect_error(
    duckdb_run(
      sql_string = "SELECT 1 AS x;",
      db_type = "duckdb_memory",
      db_file_path = NULL,
      read_only = "yes"
    ),
    class = "isoformic_read_only_not_logical"
  )
})

test_that("duckdb_run's read_only argument is actually wired to the connection (regression test)", {
  # Previously `read_only` was accepted and validated but the actual
  # `DBI::dbConnect()` call hardcoded `read_only = TRUE`, making the
  # argument a no-op. Opening a *non-existent* database file in read-only
  # mode must fail, while opening it with `read_only = FALSE` must succeed
  # (and create the file).
  testthat::skip_if_not_installed("duckdb")

  tmp_db <- withr::local_tempfile(fileext = ".duckdb")

  expect_error(
    duckdb_run(
      sql_string = "CREATE TABLE t AS SELECT 1 AS x;",
      db_type = "duckdb_file",
      db_file_path = tmp_db,
      read_only = TRUE
    )
  )

  expect_null(
    duckdb_run(
      sql_string = "CREATE TABLE t AS SELECT 1 AS x;",
      db_type = "duckdb_file",
      db_file_path = tmp_db,
      read_only = FALSE
    )
  )
  expect_true(fs::file_exists(fs::path(
    fs::path_ext_remove(tmp_db),
    ext = "duckdb"
  )))
})
