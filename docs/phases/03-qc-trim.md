# 03 — QC and trimming

## Delivers
- `FASTQC` on raw (merged) reads.
- `FASTP`: adapter auto-detect, quality trim, length filter; `--json` for MultiQC. Optional UMI extraction (`params.umi_loc`, `params.umi_len`), off by default.
- `MULTIQC` collecting fastqc/fastp now, extended by later phases (STAR, MarkDuplicates, samtools stats).

## Decisions
- fastp instead of Trim Galore (fewer tools, faster, JSON output).
- No trimmed-read FastQC: fastp reports before/after.
- Editing-specific: trimming low-quality ends matters because read-end mismatches look like editing; REDItools also trims read ends in phase 05.

## Done when
`results/samples/<id>/fastp/` and `results/multiqc/multiqc_report.html` exist on the test profile.
