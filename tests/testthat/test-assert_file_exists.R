test_that("assert_file_exists passes silently for an existing file", {
  tmp_file <- withr::local_tempfile(lines = "hello")
  expect_true(assert_file_exists(tmp_file))
})

test_that("assert_file_exists aborts with a catchable class for missing files", {
  expect_error(
    assert_file_exists("/path/does/not/exist-12345"),
    class = "isoformic_annot_file_dont_exist"
  )
})
