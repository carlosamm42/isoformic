test_that("is_deg_sig labels transcripts correctly", {
  significant_transcripts <- c("transcript1", "transcript3")
  det_table <- data.frame(
    transcript_name = c(
      "transcript1",
      "transcript2",
      "transcript3",
      "transcript4"
    ),
    log2FC = c(2.5, -1.2, 0.8, -0.5),
    pvalue = c(0.01, 0.2, 0.03, 0.6)
  )

  res <- is_deg_sig(
    deg_sig_vector = significant_transcripts,
    det_table = det_table
  )

  expect_equal(res$DEG_sig, c("YES", "NO", "YES", "NO"))
})

test_that("is_deg_sig preserves the original row order (regression test)", {
  # Previously this function split the table into matched/unmatched subsets
  # and `bind_rows()`-ed them back together, which silently reordered rows.
  significant_transcripts <- c("transcript4", "transcript1")
  det_table <- data.frame(
    transcript_name = c(
      "transcript1",
      "transcript2",
      "transcript3",
      "transcript4"
    ),
    log2FC = c(2.5, -1.2, 0.8, -0.5),
    pvalue = c(0.01, 0.2, 0.03, 0.6)
  )

  res <- is_deg_sig(
    deg_sig_vector = significant_transcripts,
    det_table = det_table
  )

  expect_identical(res$transcript_name, det_table$transcript_name)
  expect_equal(nrow(res), nrow(det_table))
})

test_that("is_deg_sig works with positional arguments", {
  det_table <- data.frame(transcript_name = c("a", "b"), log2FC = c(1, 2))
  res <- is_deg_sig(c("a"), det_table)
  expect_equal(res$DEG_sig, c("YES", "NO"))
})
