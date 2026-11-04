# 05 — Editing-site detection (REDItools3)

## Delivers
- `REDITOOLS` process: REDItools3 (PyPI package `reditools3`, latest 3.7 as of 2026-10; pin exact version; container via Wave from `conda`/`pip`, fallback `containers/reditools/Dockerfile`).
  `reditools analyze <bam> --reference <fasta> --strand <0|1|2> --min-base-quality 25 --min-read-quality 20 ...` with optional `--bed-file` to restrict to known sites (fast mode).
- Output: `results/reditools/<id>.reditools.tsv.gz`.
- Parallelism: split by chromosome (scatter over `fasta.fai` contigs, gather with `cat`) when genome-wide.

## Detector swap contract
Any replacement detector must emit a TSV with these columns (REDItools3 layout):
`Region, Position, Reference, Strand, Coverage, MeanQ, BaseCount[A,C,G,T], AllSubs, Frequency, gCoverage, gMeanQ, gBaseCount[A,C,G,T], gAllSubs, gFrequency`.
Phase 06 reads only `Region, Position, Reference, Strand, Coverage, BaseCount[A,C,G,T]`, so a minimal adapter (e.g. from `samtools mpileup` or JACUSA2) needs only those.
Stranded samples are reported on the RNA strand (`Reference` and counts complemented on `-`), so A>G is always `A` with G counts; unstranded samples are on the genome `+` strand with `Strand` `*`, and A>G shows up as either `A`→G or `T`→C.

## Strand mapping
`unstranded → 0`, `forward → 1`, `reverse → 2` (REDItools convention; verify against installed version's `--help` when pinning).

## Shipped
- Container: biocontainers `reditools3:3.7--pyhdfd78af_0`. It has no `reditools` script on the PATH, so the module calls `python -m reditools analyze`.
- Flags: `-s <0|1|2>`, plus `-C` when stranded, `-q 20 -bq 25 -mbp 5 -Mbp 5 -t <cpus>`. Defaults kept: min read length 30, only sites with at least one substitution reported.
  - `-C` (strand correction) keeps only reads on the site's consensus strand and complements `-` sites. Without it a `-` site still shows the genome base, so A>G on a minus-strand gene reads as `T` / C.
  - `-mbp 5 -Mbp 5`: mismatches in the first and last 5 bases of each read are ignored (the read-end filter from phase 04).
  - No `--reference`: STAR writes MD tags, and REDItools3 reads the reference base from them (faster, one input less).
- Duplicates: no extra filter needed. REDItools3 keeps only flags 0, 16, 83, 99, 147 and 163 (primary, proper pairs, not duplicate-flagged) and drops reads with an `SA` tag.
- Parallelism: REDItools3's own `-t` splits by contig (`-w` would split further), so there is no Nextflow scatter/gather. Add one if a genome-wide sample is too slow on one node.
- Not shipped: `--bed-file` known-sites mode. Add it with phase 06 if genome-wide runs are too slow.
- Resources: 8 CPUs, 16 GB.

## Spike-in ground truth
`bin/spike_edits.py make` (run once, output committed to `assets/test/`) edits `rnavar_run1_R1.fastq.gz` and writes `assets/test/spikes.tsv` (`chrom, pos, strand, level, reads`). `bin/spike_edits.py check` compares a REDItools table with it.

- Built on the single-end sample `rnavar_se`. The paired sample is no use: its noisy R2 already sits at STAR's mismatch limit, so edited pairs fail to map or realign elsewhere, and the called level falls to about half the spiked level.
- Sites: A positions (RNA strand, from a `-s 1 -C -me 0` REDItools baseline of the unedited BAM) with coverage ≥ 20, no G yet, at least 10 bp apart. Skipped: sites with ≥ 5 fixed differences (≥ 90% of reads off the reference) within 75 bp. The reads there match a near-copy elsewhere in the slice, and one more G tips them into multimapping.
- Edits: a target fraction (0.1–0.9, alternating low and high) of the non-duplicate reads covering each site, A→G (T→C for `-` sites, genome orientation). A read only gets a spike while NM + spikes < 8: these reads already carry about 5 mismatches each and STAR drops a read at 10. Where that budget runs out the realized level is lower, and `spikes.tsv` records the realized level.
- Edits are placed in the raw read by finding the fastp-trimmed sequence in it.

```bash
# from a test run of the unedited reads (results in res/)
docker run --rm -u $(id -u) -v $PWD:/r -w /r quay.io/biocontainers/reditools3:3.7--pyhdfd78af_0 sh -c '
  python -m reditools analyze res/bam/rnavar_se.dedup.bam -s 1 -C -q 20 -bq 25 -mbp 5 -Mbp 5 -me 0 -o base.tsv &&
  python bin/spike_edits.py make base.tsv res/bam/rnavar_se.dedup.bam rnavar_run1_R1.orig.fastq.gz spiked/'
# after a test run on the spiked reads
python bin/spike_edits.py check assets/test/spikes.tsv results/reditools/rnavar_se.reditools.tsv.gz
```

- Verified on `-profile test,docker`: 19/19 spikes called within ±0.10 of their level (largest gap 0.06). Only 4 other A>G sites have ≥ 3 G reads, all at 100% and so look like homozygous variants, not editing. `rnavar_se` unique mapping 89.18% → 89.08% after spiking.
- `rnavar_pe` shares R1, so it carries the spikes on R1 only, and its unique mapping drops from 11.00% to 10.59%. Its calls are not checked.
- REDITOOLS takes about 2 s per test sample.

## Done when
`bin/spike_edits.py check assets/test/spikes.tsv results/reditools/rnavar_se.reditools.tsv.gz` passes on the test profile: every spike within ±0.10 and no more than a handful of other A>G sites.
