# 07 — Editing index and cohort tables

## Delivers
- `bin/editing_index.py` → `samples/<id>/editing_index.tsv`:
  - **Alu Editing Index (AEI)** = ΣG / Σ(A+G) over all A positions inside Alu (mouse: SINE B1/B2) with coverage ≥ N. Computed from REDItools output restricted to the repeat BED, not from called sites, so it is not biased by site-calling thresholds.
  - counts: sites total, known, novel, in Alu, non-Alu; median edit level.
- `bin/cohort_table.py` → `cohort/editing_index.tsv` (one row per sample) and `cohort/sites_matrix.tsv.gz` (site × sample edit levels, NA where uncovered).

## Ceiling
AEI here approximates Roth et al. 2019 (RNAEditingIndexer). For exact parity, swap in RNAEditingIndexer as its own process; the output columns stay the same.

## Done when
Cohort tables exist for the test samples; self-checks pass.
