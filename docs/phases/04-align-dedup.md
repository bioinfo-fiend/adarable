# 04 — Alignment, duplicates, strandedness

## Delivers
- `STAR_ALIGN`: `--twopassMode Basic`, `--outSAMtype BAM SortedByCoordinate`, `--outSAMattributes NH HI AS nM NM MD`, `--outFilterMultimapNmax 1` (unique only; editing in repeats needs unambiguous placement), `--alignEndsType EndToEnd` (soft-clipping hides end mismatches less predictably).
- `samtools index` + `samtools stats` / `flagstat` for MultiQC.
- `MARKDUP`: Picard MarkDuplicates (marks, does not remove; REDItools skips flagged reads).
- `INFER_STRAND`: RSeQC `infer_experiment.py` against a BED12 from the GTF. Writes `strand.txt` (`forward`/`reverse`/`unstranded`). Only overrides when samplesheet says `auto`; warns if a declared value disagrees.

## No BQSR — on purpose
GATK BQSR uses known variant sites to model base-quality error. On RNA, real A>G editing mismatches outside the known set get treated as errors and down-weighted, biasing editing levels down. Replaced by explicit filters applied in phase 05:
- MAPQ ≥ 20 (STAR unique = 255)
- base quality ≥ 25
- duplicate-flagged reads excluded
- ignore mismatches within N bp of read ends

## Done when
Test samples produce markdup BAMs, `strand.txt`, and STAR/Picard sections appear in MultiQC.
