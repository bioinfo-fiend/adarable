# 05 — Editing-site detection (REDItools3)

## Delivers
- `REDITOOLS` process: REDItools3 (PyPI package `reditools3`, latest 3.7 as of 2026-10; pin exact version; container via Wave from `conda`/`pip`, fallback `containers/reditools/Dockerfile`).
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
Test run recovers the spike-ins.

## Spike-in ground truth
`bin/spike_edits.py` (run once, output committed to `assets/test/`): picks ~20 reference A positions in the slice with coverage ≥ 20 in the test reads, and converts A→G (T→C on reverse-strand reads) in a chosen fraction of the reads covering each one (levels 10–90%). Writes the edited FASTQs and `spikes.tsv` (`pos, level`). Done when every spike is called within ±10% of its level and no more than a handful of other A>G sites appear.
