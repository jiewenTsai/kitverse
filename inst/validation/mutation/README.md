# Mutation testing

Scripts to plant the mutants in `mutants.csv` into copies of the package sources and run each
package's own testthat suite. No external tool is needed.

1. Set `KIT_MUTATION_DIR` to an empty folder and copy the source checkouts of kits, kitsUI and
   kitJoin into `<KIT_MUTATION_DIR>/work/<package>`. Never mutate your own checkout.
2. Copy `mutants.csv`, `run_mutants.R` and `run_tests.R` into `KIT_MUTATION_DIR`.
3. `Rscript run_mutants.R check` checks that every mutant applies to its line (lines move when the
   code changes; update `mutants_spec.R` and rerun it).
4. `Rscript run_mutants.R run kits` (or `kitsUI`, `kitJoin`), then `Rscript summarise_results.R`.

`mutation_results.csv` holds the results of 2026-11-04 (kits 0.26.0, kitsUI 0.8.7, kitJoin 0.10.1).
