# 05 — Editing-site detection (REDItools3)

## Delivers
- `REDITOOLS` process: REDItools3 (`pip install reditools`, pinned latest; container via Wave from `conda`/`pip`, fallback `containers/reditools/Dockerfile`).
  `reditools analyze <bam> --reference <fasta> --strand <0|1|2> --min-base-quality 25 --min-read-quality 20 ...` with optional `--bed-file` to restrict to known sites (fast mode).
- Output: `results/samples/<id>/reditools/<id>.reditools.tsv.gz`.
- Parallelism: split by chromosome (scatter over `fasta.fai` contigs, gather with `cat`) when genome-wide.

## Detector swap contract
Any replacement detector must emit a TSV with these columns (REDItools layout):
`Region, Position, Reference, Strand, Coverage-q30, MeanQ, BaseCount[A,C,G,T], AllSubs, Frequency, gCoverage-q30, gMeanQ, gBaseCount[A,C,G,T], gAllSubs, gFrequency`.
Phase 06 reads only `Region, Position, Reference, Strand, Coverage-q30, BaseCount[A,C,G,T]`, so a minimal adapter (e.g. from `samtools mpileup` or JACUSA2) needs only those.

## Strand mapping
`unstranded → 0`, `forward → 1`, `reverse → 2` (REDItools convention; verify against installed version's `--help` when pinning).

## Done when
Test run produces a REDItools table containing the spiked known chr22 site.
