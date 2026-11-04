# 03 — QC and trimming

## Delivers
- `FASTQC` on raw (merged) reads.
- `FASTP`: adapter auto-detect, quality trim, length filter; `--json` for MultiQC. Optional UMI extraction (`params.umi_loc`, `params.umi_len`), off by default.
- `SORTMERNA` on the trimmed reads against `--rrna_db`: % rRNA into the MultiQC general stats table. `--remove_rrna` maps only the non-rRNA reads; `--skip_rrna_check` turns it off. `PREP_SORTMERNA_INDEX` builds the index once into `--ref_cache`.
- `MULTIQC` collecting fastqc/fastp/SortMeRNA, extended by later phases (STAR, samtools, RSeQC).

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
- SortMeRNA settings: `--paired_in --out2 --num_alignments 1`, so a pair counts as rRNA when either mate hits. In an internal comparison this matched bbduk within about 1 point. The % rRNA goes to MultiQC as a custom-content `*_mqc.tsv`.
- Without `--remove_rrna`, only the first `--rrna_reads` (default 2 M) reads or pairs are checked. Whole libraries take 1.5–3 min per 1 M pairs on 16 CPUs (pilot), so hours for a deep sample.
- Container: SortMeRNA 4.3.6. The 4.3.7 biocontainers need AVX-512 and die with SIGILL (exit 132) on AMD Zen 3.
- Test profile uses the small Rfam 5.8S database; real runs set `--rrna_db` to `smr_v4.3_fast_db.fasta` in `conf/local.config`.
- Verified: test reads 0%; 200 test pairs spiked with 50 pairs cut from 5.8S rRNA read 20.08%, and `--remove_rrna` sent 199 pairs to STAR.
- RiboDetector was tried first and dropped. On a 20-sample human cohort it classified about 2,600 pairs/s on 8 CPUs (about 6.5 h per 62 M-pair sample), and `-e rrna` (both mates must be rRNA) reads lower than bbduk.

## Done when
`results/fastp/` and `results/multiqc/multiqc_report.html` exist on the test profile.
