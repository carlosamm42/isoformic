# isoformic — Code Review & Remediation Plan

Date: 2026-07-06
Scope: Full review of `DESCRIPTION`, `NAMESPACE`, and all files under `R/`
(33 files, ~3,830 lines), plus `tests/testthat/`.

Methodology: manual read of every file in `R/`, static analysis with
`lintr::lint_dir()`, dead-code detection with `codetools::checkUsage()`,
and direct execution of suspicious expressions in R to confirm (not just
suspect) bugs.

> **Implementation status (2026-07-06): Phases 1-3 fully implemented,
> Phase 4 (tests) mostly implemented.** See `TODO.md` for the detailed,
> item-by-item checklist of what was completed. Summary:
> - All 6 confirmed functional bugs in §2.1 were fixed.
> - All 3 metadata/CRAN-readiness issues in §1 were fixed.
> - All DRY/NSE/performance items in §2.2-§2.6 were addressed.
> - `styler`/`air format` were run manually; explicit `return()` calls
>   are kept intentionally (project style preference).
> - The test suite grew from 55 to 125 passing tests.
> - `devtools::check()` now reports **0 errors, 0 warnings, 0 notes**.
> - Not done: unit tests for `prepare_annotation()`,
>   `prepare_annotation_db()`, `run_enrichment()`, `ContextData()`, and
>   the `plotgardener`-based plotting functions (deferred — see TODO.md).

---

## 1. Package Structure & Metadata (`DESCRIPTION`, `NAMESPACE`)

### 1.1 Critical — Bioconductor-only packages in hard `Imports`

`plotgardener` and `txdbmaker` are declared in `Imports` (`DESCRIPTION`
lines ~22-42), meaning every install of `isoformic` requires them
unconditionally. But in the code they are treated as **optional**,
guarded by `rlang::check_installed()`:

```r
# R/ContextData-class.R:98
rlang::check_installed("txdbmaker")
# R/plot_genomic_context.R:55
rlang::check_installed("plotgardener")
```

Both packages are Bioconductor-only (not on CRAN). With no
`Additional_repositories` field in `DESCRIPTION`, this is a likely
**CRAN submission blocker**: hard dependencies must be resolvable from
CRAN. Fix: move both to `Suggests`, matching the already-correct pattern
used for `fgsea` and `condathis`.

### 1.2 Missing guard for other Suggests-only Bioconductor packages

`R/plot_genomic_context.R` calls `GenomicFeatures::exonsBy()` (line 115)
and `IRanges::start()/end()/ranges()` (lines 121-126) directly, with **no**
`rlang::check_installed(c("GenomicFeatures", "IRanges"))` guard. Users
without these Suggested packages get an opaque "could not find function"
error instead of the clean `cli_abort()` used elsewhere in the package.

### 1.3 `DESCRIPTION` metadata typo

```
Config/Needs/dev: devtools, pkgload, remotes, rcmdcheck, covr. testthat,
```

Note the **period** instead of a comma after `covr`. Tooling that parses
this comma-separated field (e.g. `pak::local_install_dev_deps()`, used by
the `justfile`'s `install-dev-deps` recipe) will try to resolve the
malformed token `"covr. testthat"` as one package spec and fail.

### 1.4 What is already correct

- `NAMESPACE` has no broad `import(pkg)` statements — every call site is
  namespace-qualified (`pkg::fun()`), which is best practice.
- The rest of the `Imports`/`Suggests` split is sound: `arrow`, `cli`,
  `DBI`, `dplyr`, `duckdb`, `fs`, `glue`, `purrr`, `rlang`, `S7`,
  `stringr`, `tibble`, `tidyr`, `vroom`, `withr` are core/unconditional
  and correctly placed in `Imports`. `condathis`, `fgsea`, `DESeq2`,
  `tximport`, `SummarizedExperiment`, etc. are correctly optional and
  in `Suggests`.
- `Config/testthat/edition: 3`, `VignetteBuilder: quarto`,
  `Encoding: UTF-8` are all present and correct.

---

## 2. Code Quality & Performance (`R/` directory)

### 2.1 Confirmed functional bugs (verified by execution)

| # | Location | Bug | Evidence |
|---|----------|-----|----------|
| 1 | `R/plot_genomic_context.R:76-81` | `paste0(assembly_name, annotation_name, sep = "_")` — `paste0()` has **no `sep` argument**. | Confirmed: `paste0("hg38","gencode",sep="_")` → `"hg38gencode_"`, not `"hg38_gencode"`. |
| 2 | `R/salmon_utils.R:117` and `:201` | `salmon_index()`/`salmon_quant()` accept a user-supplied `env_name`, validate it via `check_env_installed(env_name)`, then **hardcode `env_name = "salmon-env"`** in the actual `condathis::run()` call. Custom environments are silently ignored. | Direct code read; parameter never reaches the call. |
| 3 | `R/duckdb_run.R:40-46` | `read_only` is a documented/validated parameter, but `DBI::dbConnect(..., read_only = TRUE)` **hardcodes `TRUE`** regardless of the argument. Dead parameter. | Direct code read. |
| 4 | `R/prepare_profile_data.R:209-210` | `dplyr::mutate(parent_gene = "genename")` sets `parent_gene` to the **literal string `"genename"`** for every row instead of the column's values. | Direct code read; missing `.data$genename`. |
| 5 | `R/as_isoformic.R:16` | `rlang::check_installed("SummarizedExperiment")` is commented out, even though the package is only in `Suggests`. | Direct code read. |
| 6 | `R/IsoformicExperiment-class.R:142` | Leftover debug `message(names(value))` inside the `tx_type_palette` setter; prints noisy output on every property set. | Direct code read. |

### 2.2 NSE / global-variable safety

- Almost every function locally reassigns `.data <- rlang::.data` /
  `.env <- rlang::.env` / `` `:=` <- rlang::`:=` `` — confirmed **29
  occurrences across 15 files** (`ContextData-class.R`,
  `get_annot_metadata.R`, `is_deg_sig.R`, `IsoformicExperiment-class.R`,
  `join_DEG_DET.R`, `make_tx_to_gene.R`, `plot_genomic_context.R`,
  `plot_log2FC.R`, `plot_tx_context.R`, `prepare_annotation.R`,
  `prepare_exon_annotation.R`, `prepare_profile_data.R`,
  `profile_plot.R`, `run_enrichment.R`, `summarize_to_gene.R`). This is a
  workaround to avoid "no visible binding" NOTEs, but it is unusual,
  repetitive, and violates DRY. Idiomatic fix: a single
  `#' @importFrom rlang .data` tag in `R/isoformic-package.R`.
- Applied inconsistently:
  - `R/plot_tx_context.R:29,85`: `dplyr::group_by(tx_id)`,
    `dplyr::arrange(tx_id)` use **bare symbols**, not `.data$tx_id`.
    Confirmed with `codetools::checkUsage()` that this produces
    `no visible binding for global variable 'tx_id'` — a real
    `R CMD check` NOTE.
  - `R/prepare_exon_annotation.R:54`: `dplyr::select(.data$X9)` —
    confirmed this triggers a `tidyselect` **deprecation warning**
    (use of `.data` in tidyselect expressions deprecated since
    tidyselect 1.2.0). Should be `dplyr::select("X9")`.
  - `R/plot_log2FC.R:181` and `R/run_enrichment.R:84-85`: `.data`/`.env`
    assigned but **never used** in that scope (confirmed by
    `lintr::object_usage_linter`) — dead code from copy-paste.

### 2.3 Deprecated / dead code

- `R/join_DEG_DET.R:90`: `dplyr::select(-dplyr::one_of(drop_columns))`
  — `one_of()` is soft-deprecated; the rest of the file correctly uses
  `dplyr::any_of()` elsewhere (internal inconsistency).
- `R/join_DEG_DET.R:106`: `DEGs_DETs_table$significance <- c()` is a
  no-op (immediately overwritten on the next line) — vestigial.
- `R/prepare_exon_annotation.R:61`: `dplyr::arrange()` with no arguments
  is a no-op.

### 2.4 Performance bottlenecks (loops that should be vectorized)

- `R/profile_plot.R` `calculate_sd_min()`: explicit
  `for (i in seq_along(x))` with a per-element `if` to clamp negative
  values — trivially vectorizable:
  ```r
  neg <- (x - y) < 0
  x[neg] <- 0; y[neg] <- 0
  log2((x - y) + 1)
  ```
- `R/plot_tx_context.R:61-76`: `for (tx_id in tx_id_vector)` repeatedly
  re-filters `plot_data` to find the max exon per transcript. This is
  exactly `dplyr::group_by(tx_id) |> dplyr::mutate(exon_right_max = max(exon_right))`,
  computed once instead of once per transcript.
- `R/prepare_exon_annotation.R:44-50`: classic
  "growing-a-data-frame-in-a-loop" anti-pattern
  (`gene_annot_df <- dplyr::bind_rows(gene_annot_df, gene_annot_df_temp)`
  inside `for (i in gene_name)`), followed by a `purrr::map_dfr()` that
  re-scans the whole table with a fresh regex per transcript — O(n×m),
  will not scale to full-genome annotations.
- `R/is_deg_sig.R`: splits the table into matched/unmatched subsets and
  `dplyr::bind_rows()`s them back — should be a single
  `dplyr::mutate(DEG_sig = dplyr::if_else(transcript_name %in% DegsigVector, "YES", "NO"))`.
  As written it is slower **and** silently reorders rows relative to the
  input — a latent correctness risk for downstream code assuming stable
  row order.

### 2.5 DRY violations (duplication)

- `tx_annot()` and `row_data()`
  (`R/IsoformicExperiment-class.R:401-459`) are near-identical (same
  `cols_to_remove` vector, same `select`/`distinct`/`left_join` chain),
  differing only by one extra `filter()`. Should share a helper.
- `combine_deg_det_longer()` (`R/plot_log2FC.R:206-285`) duplicates the
  same `select(any_of(...))`/`rename`/`distinct` block for gene- and
  transcript-level data.
- The "path does not exist" `cli_abort()` block (class
  `isoformic_annot_file_dont_exist`) is copy-pasted verbatim in
  `R/prepare_annotation.R`, `R/prepare_annotation_db.R`,
  `R/prepare_isoformic_annotation.R`, and `R/make_tx_to_gene.R` — a
  shared `assert_file_exists()` helper would remove 4x duplication.

### 2.6 Naming convention inconsistencies

The package is ~95% clean `snake_case`, but `R/is_deg_sig.R` and
`R/join_DEG_DET.R` are outliers: `DegsigVector`, `DET_table`,
`DETs_DEGs`, `DETs_notDEGs`, `DET_table_final`, `DEG_tab`,
`DET_final_tab`, `DEGs_DETs_table`. These clash with the tidyverse style
guide and with the rest of the codebase.

### 2.7 Aggregate style metrics (via `lintr`, default linters)

262 total style lints across `R/`:
- **96** lines longer than 80 characters
- **72** blocks of commented-out code left in source
- **49** non-`snake_case` identifiers

(Explicit `return()` calls are a deliberate project style choice and are
not counted as an issue here.)

### 2.8 Test coverage gap

Only 4 test files exist:
`test-check_installed.R`, `test-download_reference.R`,
`test-IsoformicExperiment.R`, `test-set_random_experiment_name.R`.

This covers only a handful of the **37 exported functions**. Zero unit
tests exist for `prepare_annotation()`, `prepare_annotation_db()`,
`prepare_exon_annotation()`, `prepare_isoformic_annotation()`,
`prepare_profile_data()`, `join_DEG_DET()`, `is_deg_sig()`,
`run_enrichment()`, `make_tx_to_gene()`, any `plot_*()` function, or
`ContextData()`/`create_context_data()`. Notably, bugs #1, #2, and #4 in
§2.1 are exactly the class of bug that a basic `expect_equal()` on
output values would have caught immediately.

---

## 3. Remediation Plan (priority order)

### Phase 1 — Correctness fixes (blockers / silent-failure bugs)
1. Fix `paste0(sep = "_")` bug in `plot_genomic_context.R`.
2. Fix hardcoded `env_name = "salmon-env"` in `salmon_index()` and
   `salmon_quant()` (`salmon_utils.R`).
3. Fix `mutate(parent_gene = "genename")` literal-string bug in
   `prepare_profile_data.R`.
4. Restore the `SummarizedExperiment` install check in
   `as_isoformic.R`.
5. Remove the stray `message(names(value))` debug call in
   `IsoformicExperiment-class.R`.
6. Decide on and fix the `read_only` dead parameter in `duckdb_run.R`
   (either wire it through, or remove the parameter if intentionally
   always read-only).

### Phase 2 — Metadata / CRAN-readiness
7. Move `plotgardener` and `txdbmaker` from `Imports` to `Suggests`.
8. Add `rlang::check_installed(c("GenomicFeatures", "IRanges"))` guard
   in `plot_genomic_context.R`.
9. Fix the `DESCRIPTION` `Config/Needs/dev` typo (`covr. testthat` →
   `covr, testthat`).

### Phase 3 — Code quality / DRY / style
10. Replace the 29x repeated `.data <- rlang::.data` (and `.env`, `:=`)
    pattern with a single `@importFrom rlang .data` tag; remove
    now-redundant local reassignments.
11. Fix NSE inconsistencies in `plot_tx_context.R`
    (`group_by(tx_id)` → `group_by(.data$tx_id)`, etc.) and
    `prepare_exon_annotation.R` (`select(.data$X9)` → `select("X9")`).
12. Replace `dplyr::one_of()` with `dplyr::any_of()` in
    `join_DEG_DET.R`.
13. Remove dead/no-op code: `DEGs_DETs_table$significance <- c()`,
    bare `dplyr::arrange()`.
14. Vectorize loops: `calculate_sd_min()` in `profile_plot.R`, the
    per-transcript max-exon loop in `plot_tx_context.R`, and the
    gene/exon accumulation loops in `prepare_exon_annotation.R`.
15. Refactor `is_deg_sig()` to a single vectorized `mutate()` that
    preserves row order.
16. De-duplicate `tx_annot()`/`row_data()` and the repeated
    file-existence check across `prepare_*` functions.
17. Rename `is_deg_sig.R` / `join_DEG_DET.R` internals to `snake_case`.

### Phase 4 — Test coverage
18. Add `testthat` unit tests for every exported function currently
    untested, prioritizing the functions where bugs were found in
    Phase 1 (regression tests), then the `prepare_*` family, then the
    `plot_*` family (visual/structural assertions, not full rendering).

---

## Summary Table

| Category | Findings |
|---|---|
| Critical metadata issues | 1 (Bioconductor pkgs in Imports) |
| Confirmed functional bugs | 6 |
| NSE / global-variable issues | 4 locations |
| Deprecated/dead code | 3 |
| Performance bottlenecks | 4 |
| DRY violations | 3 |
| Style lints (via lintr) | 262 |
| Untested exported functions | ~30+ of 37 |
