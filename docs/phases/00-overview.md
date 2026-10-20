# 00 — ADARable: overview

**ADARable** is an A-to-I RNA editing pipeline: per-sample FASTQ → QC/trim → STAR 2-pass → duplicate marking + read filters → REDItools3 site detection → annotation (REDIportal / dbSNP / Alu) → per-sample and cohort editing-index tables → interactive dashboard.

The name: ADAR enzymes deaminate adenosine to inosine, which sequencers read as G. ADAR + adorable.

Workflow manager: **Nextflow DSL2** (resume, trace, timeline, execution report). No extra orchestration layer.

## Run
```bash
nextflow run main.nf -profile test,docker                     # smoke test
nextflow run main.nf -profile docker --input samples.csv --genome GRCh38 --outdir results
nextflow run main.nf -profile apptainer ...                   # HPC
```

## Samplesheet contract
CSV, header required:

| column | required | values |
|---|---|---|
| `sample` | yes | `[A-Za-z0-9_.-]+`; repeated rows = re-sequenced runs, concatenated |
| `fastq_1` | yes | path/URL ending `.fastq.gz` / `.fq.gz` |
| `fastq_2` | no | empty for single-end; all rows of one sample must agree |
| `strandedness` | yes | `auto`, `forward`, `reverse`, `unstranded` |

## Phases
| # | Doc | Delivers |
|---|---|---|
| 01 | [01-skeleton.md](01-skeleton.md) | `main.nf`, config, profiles, samplesheet check, FASTQ merge, provenance |
| 02 | [02-references.md](02-references.md) | `conf/genomes.config` (GRCh38, GRCm39), STAR index, test slice |
| 03 | [03-qc-trim.md](03-qc-trim.md) | FastQC, fastp, MultiQC |
| 04 | [04-align-dedup.md](04-align-dedup.md) | STAR 2-pass, MarkDuplicates, strandedness inference |
| 05 | [05-editing-detection.md](05-editing-detection.md) | REDItools3, detector swap contract |
| 06 | [06-annotation.md](06-annotation.md) | known/SNP/Alu/gene annotation, A>G filtering |
| 07 | [07-editing-index.md](07-editing-index.md) | Alu Editing Index, cohort tables |
| 08 | [08-dashboard.md](08-dashboard.md) | `results/dashboard.html` |

Every phase ends runnable on `-profile test,docker`.

## What we took from the nf-core/rnaseq feature list
| Feature | Decision |
|---|---|
| cat re-sequenced FASTQs | **kept** (phase 01) |
| strandedness auto-infer | **kept**, via RSeQC `infer_experiment.py` on the BAM instead of Salmon (phase 04) |
| FastQC | **kept** (phase 03) |
| UMI extraction / dedup | **optional**, off by default, fastp `--umi` (phase 03) |
| Trim Galore | **replaced** by fastp: one tool, JSON for MultiQC |
| STAR | **kept**, 2-pass (phase 04) |
| SAMtools sort/index/stats | **kept** |
| Picard MarkDuplicates | **kept** |
| MultiQC | **kept** |
| BBSplit, SortMeRNA | skipped: add if contamination/rRNA shows up in QC |
| Salmon, RSEM, Kallisto, StringTie, DESeq2 | skipped: quantification, not editing; add for ADAR expression covariates |
| HISAT2 route | skipped: one aligner |
| bigWig coverage | skipped |
| RSeQC (beyond infer_experiment), Qualimap, dupRadar, Preseq, RustQC | skipped: add when QC questions need them |
| Kraken2/Bracken, Sylph | skipped |

## results/ layout
```
results/
  pipeline_info/   params.json, software_versions.yml, execution_report.html, timeline.html, trace.txt, dag.html
  samples/<id>/    fastp/, star/, markdup/, strand.txt, reditools/, annotated_sites.tsv.gz, editing_index.tsv
  cohort/          editing_index.tsv, sites_matrix.tsv.gz
  multiqc/         multiqc_report.html
  dashboard.html
```
