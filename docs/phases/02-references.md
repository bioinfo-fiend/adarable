# 02 — References

## Goal
All reference paths come from config, keyed by `--genome`; nothing hard-coded in processes, and **no reference data in the repo**. Defaults are public cloud URLs that Nextflow downloads when a step needs them; users with local copies point at those instead.

## Delivers
- `conf/genomes.config`: cloud URLs for `GRCh38`, `GRCm39`, and the `test_rnavar` slice. Keys: `fasta`, `gtf`, `star_index` (optional), `dbsnp` + `dbsnp_index`, `repeats`, `repeat_families`, `rediportal`, `rediportal_chain`.
- Any key can be overridden on the command line (`--fasta`, `--gtf`, …). A genome entry may set `base: 'GRCh38'` to take every key it leaves out from that entry.
- `conf/local.example.config`: template for local references (copy to the git-ignored `conf/local.config`, run with `-c conf/local.config`).
- Preparation steps, each stored once in `--ref_cache` (`storeDir`) and skipped on later runs:

| Process | Does | Cached at |
|---|---|---|
| `PREP_FASTA` | uncompress if needed, `samtools faidx` | `<key>/fasta/` |
| `STAR_GENOMEGENERATE` | STAR index, `--sjdbOverhang = read_length - 1`, `genomeSAindexNbases` sized to the genome; skipped when `star_index` is given | `<key>/star_<overhang>/` |
| `PREP_REPEATS` | UCSC `rmsk.txt(.gz)` → BED of `repeat_families` (ready BEDs pass through) | `<key>/repeats_<source>_<families>/` |
| `PREP_KNOWN_SITES` | REDIportal TABLE1 → BED6 (`name = Ref>Ed:type`), liftOver when `rediportal_chain` is set | `<key>/known_sites_<source>/` |

`<key>` = genome name + 8-character fingerprint of the FASTA location, so a different FASTA never reuses another FASTA's STAR index.

## Cloud sources (all checked 2026-10-20)
| | GRCh38 | GRCm39 |
|---|---|---|
| FASTA | Broad public GCS `hg38/v0/GRCh38.primary_assembly.genome.fa` (GENCODE primary assembly) | Broad public GCS `GRCm39/GRCm39.primary_assembly.genome.fa.gz` (GENCODE M32 copy) |
| GTF | GENCODE release 50 | GENCODE release M39 |
| SNPs | Broad GCS dbSNP 138 VCF + tbi (`chr` names) | Ensembl variation VCF + csi (Ensembl names `1`) |
| Repeats | UCSC hg38 `rmsk.txt.gz`, family `Alu` | UCSC mm39 `rmsk.txt.gz`, families `Alu,B2` (UCSC files mouse B1 under `Alu`) |
| Known editing sites | REDIportal hg38 v3 (1.5 GB) | REDIportal mm10 v3, lifted to mm39 with UCSC `mm10ToMm39` (107,094 / 107,094 sites lifted) |

Broad GCS is read over `https://storage.googleapis.com/...`, so no Google login is needed.

Not used: Broad's STAR indexes (built for 10x single-cell with a filtered GTF), and NCBI's latest dbSNP (29.5 GB, RefSeq contig names). Add a newer human dbSNP when filtering needs it.

## Test references
`test_rnavar`: 40 kb chr22 slice (renumbered from 1), GTF and dbSNP 146 from nf-core/test-datasets `rnavar` (MIT), matching the test reads. The STAR index is built from the slice (seconds). The slice is nearly edit-free, so `repeats` and `rediportal` stay unset until phase 05 adds a spike-in truth set in slice coordinates.

| Layer | Data | Checks |
|---|---|---|
| `test` | rnavar reads + slice, with spiked-in A>G edits at known positions and levels | wiring of every phase; detection recovers the spikes (ground truth) |
| `test_full` (later) | a public high-editing sample (e.g. brain or ENCODE cell line) subset to an Alu-rich chr22 window, real hg38 coordinates | real REDIportal overlap and a plausible Alu Editing Index |

## Notes
- Chromosome names may differ between files: GENCODE/UCSC/REDIportal use `chr1`, Ensembl files use `1`. Phase 06 normalises names when comparing, so mixed sources work.
- `--genome` with an unknown name fails with the list of known genomes.
- Human STAR index needs about 32 GB RAM (`STAR_GENOMEGENERATE`: 8 CPUs, 40 GB by default).

## Shipped / verified
- `-profile test,docker` and `-profile test,apptainer` pass; a fresh run without `-resume` skips `PREP_FASTA` and `STAR_GENOMEGENERATE` ("Stored").
- Real mouse inputs through `PREP_KNOWN_SITES` (liftOver) and `PREP_REPEATS` (929,102 Alu/B2 intervals) on the test profile.
- `-preview` with a local config resolves local FASTA/GTF plus cloud dbSNP/REDIportal for both GRCh38 and GRCm39.
