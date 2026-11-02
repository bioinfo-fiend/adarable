# 02 — References

## Goal
All reference paths come from config, keyed by `--genome`; nothing hard-coded in processes, and **no reference data in the repo**. Users point at their own local references (2026-10-29: cloud defaults dropped, too much to fetch and keep in sync). Only the tiny `test_rnavar` slice is still fetched, from nf-core/test-datasets.

## Delivers
- `conf/genomes.config`: only the `test_rnavar` slice.
- `conf/local.example.config`: template for your genomes (copy to the git-ignored `conf/local.config`, run with `-c conf/local.config --genome <name>`). Keys: `fasta`, `gtf` (required), `star_index`, `dbsnp` + `dbsnp_index`, `repeats`, `repeat_families`, `rediportal`, `rediportal_chain` (optional; their steps are skipped when unset).
- Any key can be overridden on the command line (`--fasta`, `--gtf`, …).
- Preparation steps, each stored once in `--ref_cache` (`storeDir`) and skipped on later runs:

| Process | Does | Cached at |
|---|---|---|
| `PREP_FASTA` | uncompress if needed, `samtools faidx` | `<key>/fasta/` |
| `STAR_GENOMEGENERATE` | STAR index, `--sjdbOverhang = read_length - 1`, `genomeSAindexNbases` sized to the genome; skipped when a `star_index` dir has a matching `sjdbOverhang` | `<key>/star_<overhang>/` |
| `PREP_REPEATS` | UCSC `rmsk.txt(.gz)` → BED of `repeat_families` (ready BEDs pass through) | `<key>/repeats_<source>_<families>/` |
| `PREP_KNOWN_SITES` | REDIportal TABLE1 → BED6 (`name = Ref>Ed:type`), liftOver when `rediportal_chain` is set | `<key>/known_sites_<source>/` |

`<key>` = genome name + 8-character fingerprint of the FASTA location, so a different FASTA never reuses another FASTA's STAR index.

## Contig names
`bin/match_chroms` renames repeat and known-site BEDs to the FASTA's contigs (from its `.fai`): `chr1` <-> `1`, `chrM` <-> `MT`, `chr1_KI270706v1_random` -> `KI270706.1`; rows on contigs the FASTA lacks (UCSC `_alt`/`_fix`) are dropped with a count on stderr. For REDIportal it runs after liftOver (UCSC chains use `chr`). dbSNP VCFs are not renamed: use one with the FASTA's naming (e.g. dbSNP 151 common, Ensembl names).

## Read length and STAR indexes
STAR fixes `sjdbOverhang` when the index is built and refuses a different value at mapping, even with `--sjdbGTFfile` passed again (checked 2026-10-29 on the test slice). So `star_index` takes one dir or several (list, or comma-separated on the command line), e.g. a 100 bp and a 150 bp build; the one whose `genomeParameters.txt` matches `--read_length - 1` is used. No match: a warning, and one is built into `--ref_cache`. Index build and alignment share the nf-core community image `htslib_samtools_star_gawk` (STAR 2.7.11b).

## Where to get references
Suggested public sources if you have no local copies (checked 2026-10-20): GENCODE FASTA/GTF, Broad dbSNP 138 (human), Ensembl variation VCF (mouse), UCSC `rmsk.txt.gz` (human `Alu`, mouse `Alu,B2`), REDIportal v3 TABLE1 (mouse mm10, lift with UCSC `mm10ToMm39`). Prefer prebuilt STAR indexes where you have them; any STAR >= 2.7.4a index works.

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
- Local GRCh38 (Ensembl 110), `--read_length 100`: prebuilt STAR index used; REDIportal hg38 v3 -> 15,678,583 / 15,680,832 sites on Ensembl names (2,249 on alt contigs dropped); 1,113,103 Alu intervals.
- Local GRCm39 (Ensembl 110) + REDIportal mm10 via liftOver: 107,094 / 107,094 sites, Ensembl names incl. GL/JH scaffolds.
