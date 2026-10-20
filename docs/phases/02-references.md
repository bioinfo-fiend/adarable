# 02 — References

## Goal
All reference paths come from config, keyed by `--genome`; nothing hard-coded in processes.

## Delivers
- `conf/genomes.config`: `params.genomes.GRCh38` and `params.genomes.GRCm39`, each with
  `fasta`, `gtf`, `star_index` (optional), `rediportal`, `dbsnp`, `repeats_bed` (Alu/SINE).
- `STAR_GENOMEGENERATE` runs only when `star_index` is unset (`--sjdbOverhang` from `params.read_length - 1`).
- Test references for `-profile test`, fetched by URL from nf-core/test-datasets `rnavar` (MIT): 40 kb chr22 slice `genome.fasta` (renumbered from 1), `genome.gtf`, `dbsnp_146.hg38.vcf.gz`, prebuilt `index/star/star.tar.gz`. Matches the test reads.
- The slice is renumbered and nearly edit-free, so the real REDIportal file can't be used against it. The test profile instead gets a small REDIportal-format file and repeat BED listing the spike-in positions (phase 05) in slice coordinates.

## Test data, two layers
| Layer | Data | Checks |
|---|---|---|
| `test` | rnavar reads + slice, with spiked-in A>G edits at known positions and levels | wiring of every phase; detection recovers the spikes (ground truth) |
| `test_full` (later) | a public high-editing sample (e.g. brain or ENCODE cell line) subset to an Alu-rich chr22 window, real hg38 coordinates | real REDIportal overlap and a plausible Alu Editing Index |

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
