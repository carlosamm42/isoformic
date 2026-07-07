# isoformic — TODO

Actionable checklist derived from `PLAN.md`. Status as of the
implementation pass on 2026-07-06 (all items verified with
`devtools::test()`, `devtools::document()`, and `devtools::check()`,
which now reports **0 errors, 0 warnings, 0 notes**).

## Phase 1 — Correctness fixes (do first)

- [x] Fix `paste0(..., sep = "_")` bug in `R/plot_genomic_context.R`.
      Changed to `paste(a, b, sep = "_")`.
- [x] Fix `salmon_index()` in `R/salmon_utils.R`: `condathis::run()` now
      receives `env_name = env_name` instead of the hardcoded
      `"salmon-env"`. Covered by `test-salmon_utils.R` (mocked
      `condathis::run()`).
- [x] Fix `salmon_quant()` in `R/salmon_utils.R`: same fix applied.
      Covered by `test-salmon_utils.R`.
- [x] Fix `R/prepare_profile_data.R`: `parent_gene` now set to
      `.data$genename` instead of the literal string `"genename"`.
      Covered by `test-prepare_profile_data.R` (regression test).
- [x] Restored `rlang::check_installed("SummarizedExperiment")` in
      `R/as_isoformic.R`.
- [x] Removed leftover debug `message(names(value))` in the
      `tx_type_palette` setter, `R/IsoformicExperiment-class.R`.
- [x] Resolved the dead `read_only` parameter in `R/duckdb_run.R`:
      `DBI::dbConnect(..., read_only = read_only)` now actually uses the
      argument. Covered by `test-duckdb_run.R` (regression test
      confirming read-only vs. read-write behavior differs as
      expected).

## Phase 2 — Metadata / CRAN-readiness

- [x] Moved `plotgardener` from `Imports` to `Suggests` in `DESCRIPTION`.
- [x] Moved `txdbmaker` from `Imports` to `Suggests` in `DESCRIPTION`.
- [x] Added `rlang::check_installed(c("GenomicFeatures", "IRanges"))`
      guard near the top of `plot_genomic_context()`.
- [x] Fixed typo in `DESCRIPTION`'s `Config/Needs/dev` field
      (`covr. testthat` → `covr, testthat`).

## Phase 3 — Code quality / DRY / style

- [x] Added `#' @importFrom rlang .data` / `.env` / `:=` (once) to
      `R/isoformic-package.R` (now in `NAMESPACE`); removed the repeated
      local reassignments across all 15 affected files:
  - [x] `R/ContextData-class.R`
  - [x] `R/get_annot_metadata.R`
  - [x] `R/is_deg_sig.R`
  - [x] `R/IsoformicExperiment-class.R`
  - [x] `R/join_DEG_DET.R`
  - [x] `R/make_tx_to_gene.R`
  - [x] `R/plot_genomic_context.R`
  - [x] `R/plot_log2FC.R`
  - [x] `R/plot_tx_context.R`
  - [x] `R/prepare_annotation.R`
  - [x] `R/prepare_exon_annotation.R`
  - [x] `R/prepare_profile_data.R`
  - [x] `R/profile_plot.R`
  - [x] `R/run_enrichment.R`
  - [x] `R/summarize_to_gene.R`
  - Verified with `codetools::checkUsage()` against the loaded package
    namespace: **no** "no visible binding" warnings remain for `.data`,
    `.env`, or `:=` anywhere in `R/`.
- [x] Fixed NSE bare-symbol usage in `R/plot_tx_context.R`
      (`dplyr::group_by(tx_id)` → `dplyr::group_by(.data$tx_id)`, etc.).
- [x] Fixed deprecated tidyselect usage in
      `R/prepare_exon_annotation.R` (`dplyr::select(.data$X9)` →
      `dplyr::select("X9")`).
- [x] Replaced `dplyr::one_of(drop_columns)` with
      `dplyr::any_of(drop_columns)` in `R/join_DEG_DET.R`.
- [x] Removed no-op `DEGs_DETs_table$significance <- c()` in
      `R/join_DEG_DET.R`.
- [x] Removed no-op `dplyr::arrange()` (no args) in
      `R/prepare_exon_annotation.R`.
- [x] Vectorized `calculate_sd_min()` for-loop in `R/profile_plot.R`.
      Verified equivalent output against the original loop with a
      1000-element random vector before applying.
- [x] Vectorized the per-transcript max-exon `for` loop in
      `R/plot_tx_context.R` using
      `dplyr::group_by(.data$tx_id) |> dplyr::mutate(...)`. Verified
      equivalent output against the original loop on synthetic data
      before applying; covered by `test-plot_tx_context.R`.
- [x] Refactored the accumulation loops in
      `R/prepare_exon_annotation.R` (growing `gene_annot_df` in a loop,
      and the per-transcript `purrr::map_dfr()` scan) into a single
      vectorized regex-capture + filter approach. Verified equivalent
      output on synthetic GFF data before applying; covered by
      `test-prepare_exon_annotation.R`.
- [x] Refactored `is_deg_sig()` to a single vectorized
      `dplyr::mutate(DEG_sig = dplyr::if_else(...))`, which also fixes
      the row-order-changing side effect of the old split/bind_rows
      approach. Covered by `test-is_deg_sig.R` (explicit row-order
      regression test).
- [x] De-duplicated `tx_annot()` and `row_data()` in
      `R/IsoformicExperiment-class.R` into a shared
      `get_tx_gene_annot()` internal helper. Covered by
      `test-prepare_isoformic_annotation.R`.
- [x] De-duplicated the `deg_df`/`det_df` blocks in
      `combine_deg_det_longer()` (`R/plot_log2FC.R`) via a shared
      `select_deg_det_cols()` helper and a single `deg_gene_annot`
      lookup table.
- [x] Extracted a shared `assert_file_exists()` helper
      (`R/assert_file_exists.R`) and applied it in
      `R/prepare_annotation.R`, `R/prepare_annotation_db.R`,
      `R/prepare_isoformic_annotation.R`, `R/prepare_exon_annotation.R`,
      and `R/make_tx_to_gene.R` (the last of which previously had no
      error `class` at all — now consistent). Covered by
      `test-assert_file_exists.R`.
- [x] Renamed non-`snake_case` identifiers in `R/is_deg_sig.R`
      (`DegsigVector` → `deg_sig_vector`, `DET_table` → `det_table`, and
      all internal variables) and `R/join_DEG_DET.R` (`DEG_tab` →
      `deg_table`, `DET_final_tab` → `det_table`, `DEGs_DETs_table` →
      `deg_det_table`, etc.). Confirmed no call sites broke (all
      existing callers use positional arguments).
- [x] `lintr` findings reduced from 262 → 227: removed all dead/no-op
      code and fixed the naming violations addressed above
      (`object_name_linter` hits dropped from 49 → 22; the remaining 22
      are S7 class name identifiers like `IsoformicExperiment`/
      `ContextData`, which are intentional and part of the public API).
      `styler`/`air format` were run manually. Explicit `return()` calls
      are intentionally kept (project style preference) and are not a
      lint target.

## Phase 4 — Test coverage

Test suite grew from 55 to 125 passing tests (`devtools::test()`,
0 failures). New test files added:
`test-assert_file_exists.R`, `test-duckdb_run.R`, `test-is_deg_sig.R`,
`test-join_DEG_DET.R`, `test-make_tx_to_gene.R`,
`test-plot_tx_context.R`, `test-prepare_exon_annotation.R`,
`test-prepare_isoformic_annotation.R`, `test-prepare_profile_data.R`,
`test-salmon_utils.R`, `test-tx_type_palette.R`, plus a shared
`testdata/mini.gff` fixture.

- [x] Added regression tests for the Phase 1 bugs that could be tested
      without heavy Bioconductor fixtures: `salmon_index()`/
      `salmon_quant()` env_name passthrough, `duckdb_run()` read_only
      wiring, `prepare_profile_data()` parent_gene fix, `is_deg_sig()`
      row-order preservation.
- [ ] `prepare_annotation()` — **not covered** (no dedicated test file
      added yet).
- [ ] `prepare_annotation_db()` — **not covered**.
- [x] `prepare_exon_annotation()` — covered (`test-prepare_exon_annotation.R`).
- [x] `prepare_isoformic_annotation()` — covered, including a full
      `IsoformicExperiment` integration test
      (`test-prepare_isoformic_annotation.R`).
- [x] `prepare_profile_data()` — covered (`test-prepare_profile_data.R`).
- [x] `join_DEG_DET()` — covered (`test-join_DEG_DET.R`).
- [x] `is_deg_sig()` — covered (`test-is_deg_sig.R`).
- [ ] `run_enrichment()` — **not covered** (requires `fgsea`; deferred).
- [x] `make_tx_to_gene()` — covered (`test-make_tx_to_gene.R`).
- [ ] `ContextData()` / `create_context_data()` — **not covered**
      (requires `txdbmaker` + a full `TxDb` build; deferred).
- [x] `plot_tx_context()` — covered via `ggplot_build()` inspection
      (`test-plot_tx_context.R`).
- [ ] `plot_genomic_context()`, `plot_log2FC()`, `plot_tx_expr()` —
      **not covered** (require `plotgardener`/heavy annotation fixtures
      or full `IsoformicExperiment` DEA setup; deferred).
- [x] `salmon_index()` / `salmon_quant()` argument passthrough — covered
      via mocked `condathis::run()` (`test-salmon_utils.R`), which is
      exactly the regression test that would have caught the `env_name`
      bug.

## Remaining follow-up (not done in this pass)

- Unit tests for `prepare_annotation()`, `prepare_annotation_db()`,
  `run_enrichment()`, `ContextData()`/`create_context_data()`, and the
  `plotgardener`-based plotting functions.
