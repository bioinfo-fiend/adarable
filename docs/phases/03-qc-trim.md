# 03 — QC and trimming

## Delivers
- `FASTQC` on raw (merged) reads.
- `FASTP`: adapter auto-detect, quality trim, length filter; `--json` for MultiQC. Optional UMI extraction (`params.umi_loc`, `params.umi_len`), off by default.
- `RIBODETECTOR` on the trimmed reads: % rRNA into the MultiQC general stats table. `--remove_rrna` maps only the non-rRNA reads; `--skip_ribodetector` turns it off.
- `MULTIQC` collecting fastqc/fastp/RiboDetector, extended by later phases (STAR, samtools, RSeQC).

## Decisions
- fastp instead of Trim Galore (fewer tools, faster, JSON output).
- No trimmed-read FastQC: fastp reports before/after.
- Editing-specific: trimming low-quality ends matters because read-end mismatches look like editing; REDItools also trims read ends in phase 05.

## Shipped
- Containers: biocontainers `fastqc:0.13.0`, `fastp:1.4.0`, `multiqc:1.35`.
- fastp: `--cut_front --cut_tail --cut_mean_quality 20 --length_required 30`; `--detect_adapter_for_pe` on paired-end. `--adapter_fasta` adds adapters auto-detection misses (e.g. MGI/DNBSEQ). `--umi_loc`/`--umi_len` turn on UMI extraction into the read name (`...:CAGGGTAC`); deduplication on it is phase 04.
- Inputs are linked to `<id>.fastq.gz` / `<id>_{1,2}.fastq.gz` before FastQC and fastp, so reports and MultiQC rows carry sample ids.
- Trimmed FASTQs stay in `work/` (feed STAR); only reports are published.
- Verified: `-profile test,docker` passes; `rnavar_pe` 8,318 -> 8,306 reads after filtering, 42 adapter-trimmed; MultiQC has fastqc and fastp sections for both samples; `--umi_loc read1 --umi_len 8` runs.
- RiboDetector `0.3.3` (CPU model, `-l --read_length`). Paired-end uses `-e rrna`: a pair counts as rRNA only when both mates are called rRNA. MultiQC has no RiboDetector module, so the step writes a custom-content `*_mqc.tsv` (log has ANSI colour codes, stripped in awk). Test reads: 0% (PE), 0.05% (SE); `--remove_rrna` feeds `*.nonrrna.fastq.gz` to STAR.
- Without `--remove_rrna`, only the first `--rrna_reads` (default 2 M) reads or pairs are classified. On a 20-sample human cohort RiboDetector managed about 2,600 pairs/s on 8 CPUs, so about 6.5 h for a 62 M-pair sample, and it held up STAR on a shared node.

## Done when
`results/samples/<id>/fastp/` and `results/multiqc/multiqc_report.html` exist on the test profile.
