# kitverse validation report

Standard: [KIT validation standard](https://github.com/jiewenTsai/kitDesign/blob/main/inst/validation/criteria.md)
(`kitverse_validation("criteria")`). Version validated: kitverse 0.5.8. Date: 2026-11-04.

kitverse installs and loads the KIT packages and writes no number into a report, so its own scope
is empty. It holds the cross-package parts of the validation:

| File | What it is |
|---|---|
| `metamorphic.R`, `results/metamorphic_results.csv` | Metamorphic relations of kits, kitsUI and kitJoin (20 functions × 3, plus an interval relation for `kitsui_score`; 61 of 61 hold) |
| `mutation/` | The mutation runner, the 37 mutants and their results (30 killed) |
| `results/bugs.csv`, `results/metrics.csv` | The fault history of all five packages from NEWS and git (160 faults) and the four metrics |

## The five packages

| Package | Engine | Metamorphic | Snapshot | Mutants killed | Faults after release (strict / broad) |
|---|---|---|---|---|---|
| [kits](https://github.com/jiewenTsai/kits/blob/main/inst/validation/validation.md) | 35 of 35 (cNORM included) | 30 of 30 | in kitsUI | 18 of 20 | 3 / 4 |
| [kitsUI](https://github.com/jiewenTsai/kitsUI/blob/main/inst/validation/validation.md) | through kits | 13 of 13 | identical | 6 of 9 | 8 / 30 |
| [kitJoin](https://github.com/jiewenTsai/kitJoin/blob/main/inst/validation/validation.md) | not applicable | 18 of 18 | identical | 6 of 8 | 12 / 41 |
| [kitDesign](https://github.com/jiewenTsai/kitDesign/blob/main/inst/validation/validation.md) | not applicable | not run | not applicable | not run | 5 / 6 |
| kitverse | not applicable | not applicable | not applicable | not run | 9 / 9 |

Strict: fixed after 2026-11-01, when the packages became installable from r-universe, or still
open. Broad: the fault was in any earlier tag or deployed version.

The faults that reached users were in data management, variable mapping and boundaries (75 of 94
faults outside the interface), not in formulas. The 9 kitverse faults were all about installing
and updating: pandoc, Windows folders, SSL, old R versions, Chinese shortcut names.

## Faults and metrics of kitverse

| Metric | Value |
|---|---|
| Acceptance criteria written beforehand | 0 |
| First-generation pass rate | 5 of 10 versions with a behaviour change (50%) |
| Faults caught per layer | Manual use 1, r-universe 2, not stated 6 |
| Faults found after release | 9 |

## Open

All the items of the first validation are done (kitverse 0.5.8 with kits 0.26.1, kitsUI 0.8.8,
kitJoin 0.10.2):

- [x] kitsUI warns when kits flags the estimates of a round (U35): a round log row "estimate
  warning", status warn, also in `checks.csv` and the status box. kits already had the diagnostic.
- [x] A metamorphic relation for the linking error in `se_total` (`kitsui_score` R4).
- [x] The column order of wide files in kitJoin: the tidyr default, documented, and `names_sort` as
  an option.
- [x] A snapshot of kitJoin (`kitJoin/inst/validation/snapshot.R`).
- [x] The norm comparison with cNORM: direct, without kitsPreview, live when cNORM is installed and
  from stored values otherwise.

Still not run here: `kits/tests/testthat/test-against-kitsPreview.R` (kitsPreview is not
installed), which also covers the wave screening and the DIF combination.
