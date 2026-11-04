# 04 — Alignment, duplicates, strandedness

## Delivers
- `STAR_ALIGN`: `--twopassMode Basic`, `--outSAMtype BAM SortedByCoordinate`, `--outSAMattributes NH HI AS nM NM MD`, `--outFilterMultimapNmax 1` (unique only; editing in repeats needs unambiguous placement), `--alignEndsType EndToEnd` (soft-clipping hides end mismatches less predictably).
- `samtools index` + `samtools stats` / `flagstat` for MultiQC.
- `SAMTOOLS_MARKDUP` (default): collate, fixmate -m, sort, markdup. Marks, does not remove; REDItools skips flagged reads.
- `UMITOOLS_DEDUP` (when `--umi_loc` is set): umi_tools dedup on the UMI fastp put in the read name. Removes duplicates.
- `BAMCOVERAGE`: deepTools bamCoverage on the dedup BAM, CPM, duplicates excluded. Stranded libraries get `<id>.plus.bw` / `<id>.minus.bw` (gene strand), unstranded one `<id>.bw`.
- `INFER_STRAND`: RSeQC `infer_experiment.py` against a BED12 from the GTF. Writes `strand.txt` (`forward`/`reverse`/`unstranded`). Only overrides when samplesheet says `auto`; warns if a declared value disagrees. BED12 cached in `--ref_cache` (`bin/gtf2bed12`).

## No BQSR — on purpose
GATK BQSR uses known variant sites to model base-quality error. On RNA, real A>G editing mismatches outside the known set get treated as errors and down-weighted, biasing editing levels down. Replaced by explicit filters applied in phase 05:
- MAPQ ≥ 20 (STAR unique = 255)
- base quality ≥ 25
- duplicate-flagged reads excluded
- ignore mismatches within N bp of read ends

## Shipped
- Containers: STAR/samtools nf-core image (STAR 2.7.11b, samtools 1.21), `umi_tools:1.1.6`, `rseqc:5.0.4`, `deeptools:3.5.6`.
- Strand call: read 1 on the gene strand in >= 80% of informative reads = `forward`, the reverse >= 80% = `reverse`, else `unstranded`.
- deepTools `--filterRNAstrand` assumes dUTP (reverse) libraries; the labels are swapped for forward-stranded ones so `plus`/`minus` always mean gene strand.
- UMI guard: `UMITOOLS_DEDUP` stops if read names carry no UMI. STAR cuts names at `/`, so SRA-style `read/1:UMI` names lose it; Illumina names (`read 1:N:0`) keep it.
- Published: `bam/` (dedup BAM + BAI), `stats/star/` (Log.final.out), `stats/samtools/` (stats, flagstat), `stats/dedup/` (markdup stats or umi_tools log); `samples/<id>/` gets `SJ.out.tab`, `bigwig/`, `strand.txt`, `<id>.infer_experiment.txt`.
- Verified on `-profile test,docker`: both test samples infer `forward` (0.98 PE, 0.99 SE); MultiQC has STAR, samtools and RSeQC sections. UMI run on the test reads renamed Illumina-style: 251 -> 200 pairs, umi_tools section in MultiQC.
- Test data note: `rnavar_pe` maps 11% uniquely end-to-end (69% with `--alignEndsType Local`) because R2 of this dataset is noisy (5.7% mismatches per base on its own). EndToEnd stays: real libraries sit well under 1%.

## Done when
Test samples produce dedup BAMs, `strand.txt`, bigWigs, and STAR/samtools/RSeQC sections appear in MultiQC.
