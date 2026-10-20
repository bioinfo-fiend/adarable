# 02 — References

## Goal
All reference paths come from config, keyed by `--genome`; nothing hard-coded in processes.

## Delivers
- `conf/genomes.config`: `params.genomes.GRCh38` and `params.genomes.GRCm39`, each with
  `fasta`, `gtf`, `star_index` (optional), `rediportal`, `dbsnp`, `repeats_bed` (Alu/SINE).
- `STAR_GENOMEGENERATE` runs only when `star_index` is unset (`--sjdbOverhang` from `params.read_length - 1`).
- Test slice for `-profile test`: GRCh38 chr22 subregion (~1 Mb), matching GTF/REDIportal/dbSNP/Alu subsets, built once by `assets/test/make_test_refs.sh` and committed (small) or fetched by URL.

## Sources
| | GRCh38 | GRCm39 |
|---|---|---|
| FASTA/GTF | GENCODE primary assembly | GENCODE M-series |
| Known editing sites | REDIportal hg38 | REDIportal mouse is **mm10** → liftOver to mm39 once, outside the pipeline; document the chain file and drop rate |
| SNPs | dbSNP b156 common (VCF, tabix) | Ensembl variation / MGP strain SNPs |
| Repeats | RepeatMasker (UCSC rmsk) → Alu BED | RepeatMasker → B1/B2 SINE BED (mouse has no Alu; the "Alu index" becomes a SINE index) |

## Notes
- Chromosome naming must match across all files (`chr` prefix). Phase 06 asserts this on the first lookup.
- Users override any path with `--fasta` etc.; `params.genome` just fills defaults.

## Done when
`-profile test` runs with only config-provided references; `--genome GRCm39` resolves without editing code.
