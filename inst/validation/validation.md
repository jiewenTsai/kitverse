# kitverse validation report

Standard: [KIT validation standard](https://github.com/jiewenTsai/kitDesign/blob/main/inst/validation/criteria.md)
(`kitverse_validation("criteria")`). Version validated: kitverse 0.5.8. Date: 2026-11-04.

kitverse installs and loads the KIT packages and writes no number into a report, so its own scope
is empty. It holds the cross-package parts of the validation:

| File | What it is |
|---|---|
| `metamorphic.R`, `results/metamorphic_results.csv` | Metamorphic relations of kits, kitsUI and kitJoin (20 functions × 3; 59 of 60 hold) |
| `mutation/` | The mutation runner, the 37 mutants and their results (30 killed) |
| `results/bugs.csv`, `results/metrics.csv` | The fault history of all five packages from NEWS and git (159 faults) and the four metrics |

## The five packages

| Package | Engine | Metamorphic | Snapshot | Mutants killed | Faults after release (strict / broad) |
|---|---|---|---|---|---|
| [kits](https://github.com/jiewenTsai/kits/blob/main/inst/validation/validation.md) | 32 of 32 | 30 of 30 | in kitsUI | 18 of 20 | 3 / 4 |
| [kitsUI](https://github.com/jiewenTsai/kitsUI/blob/main/inst/validation/validation.md) | through kits | 12 of 12 | identical | 6 of 9 | 7 / 29 |
| [kitJoin](https://github.com/jiewenTsai/kitJoin/blob/main/inst/validation/validation.md) | not applicable | 17 of 18 | not yet | 6 of 8 | 12 / 41 |
| [kitDesign](https://github.com/jiewenTsai/kitDesign/blob/main/inst/validation/validation.md) | not applicable | not run | not applicable | not run | 5 / 6 |
| kitverse | not applicable | not applicable | not applicable | not run | 9 / 9 |

Strict: fixed after 2026-11-01, when the packages became installable from r-universe, or still
open. Broad: the fault was in any earlier tag or deployed version.

The faults that reached users were in data management, variable mapping and boundaries (74 of 93
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

- [ ] Warn when a free calibration gives a step with an unidentified estimate (beta near −20, SE in
  the thousands), e.g. `kitm03` lan at 3, 36 and 48 months.
- [ ] A metamorphic relation for the linking error in `se_total` (kitsUI).
- [ ] Sort or document the column order of wide files (kitJoin).
- [ ] A snapshot of kitJoin.
- [ ] Run the norm comparison with cNORM (needs kitsPreview and cNORM installed).
