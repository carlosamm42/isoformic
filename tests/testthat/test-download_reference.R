# tests/testthat/test-download_reference.R

# Mocking required functions
mock_has_internet <- function(value) {
  function(...) {
    return(value)
  }
}

mock_dir_exists <- function(value) {
  function(...) {
    return(value)
  }
}

mock_dir_create <- function() {
  function(...) {
    return(NULL)
  }
}

mock_file_exists <- function(value) {
  function(...) {
    return(value)
  }
}

mock_download_file_success <- function(return_value) {
  function(...) {
    return(return_value)
  }
}

mock_download_file_error <- function() {
  function(...) rlang::abort(class = "isoformic_download_reference_error")
}

testthat::test_that("download_reference handles no internet connection", {
  testthat::local_mocked_bindings(
    has_internet = mock_has_internet(FALSE),
    .package = "curl"
  )

  testthat::expect_error(
    download_reference(),
    class = "isoformic_download_reference_no_internet_error"
  )
})

testthat::test_that("download_reference handles existing file", {
  testthat::local_mocked_bindings(
    has_internet = mock_has_internet(TRUE),
    .package = "curl"
  )
  testthat::local_mocked_bindings(
    dir_exists = mock_dir_exists(TRUE),
    .package = "fs"
  )
  testthat::local_mocked_bindings(
    file_exists = mock_file_exists(TRUE),
    .package = "fs"
  )
  testthat::expect_message(
    download_reference(),
    "already exists"
  )
})

testthat::test_that("download_reference handles directory creation", {
  testthat::local_mocked_bindings(
    has_internet = mock_has_internet(TRUE),
    .package = "curl"
  )
  testthat::local_mocked_bindings(
    dir_exists = mock_dir_exists(FALSE),
    .package = "fs"
  )
  testthat::local_mocked_bindings(
    file_exists = mock_file_exists(FALSE),
    .package = "fs"
  )
  testthat::local_mocked_bindings(
    dir_create = mock_dir_create(),
    .package = "fs"
  )
  testthat::local_mocked_bindings(
    download.file = mock_download_file_success(0L),
    .package = "utils"
  )
  testthat::expect_message(
    download_reference(),
    "successfully downloaded"
  )
})

testthat::test_that("download_reference handles download errors", {
  testthat::local_mocked_bindings(
    has_internet = mock_has_internet(TRUE),
    .package = "curl"
  )
  testthat::local_mocked_bindings(
    dir_exists = mock_dir_exists(TRUE),
    .package = "fs"
  )
  testthat::local_mocked_bindings(
    file_exists = mock_file_exists(FALSE),
    .package = "fs"
  )
  testthat::local_mocked_bindings(
    download.file = mock_download_file_error(),
    .package = "utils"
  )

  testthat::expect_error(
    download_reference(),
    class = "isoformic_download_reference_error"
  )
})
