# 01 — Skeleton

## Goal
A pipeline that runs end to end on the test samplesheet and already writes provenance, before any biology is added.

## Delivers
- `main.nf` — single workflow; reads `--input`, validates it, merges re-sequenced FASTQs.
- `nextflow.config` — params, profiles (`docker`, `apptainer`, `test`), manifest, execution report/trace/timeline/DAG into `results/pipeline_info/`.
- `bin/check_samplesheet.py` — validates the contract in [00-overview.md](00-overview.md); writes one row per sample with `;`-joined FASTQs. Self-check: `python bin/check_samplesheet.py`.
- `modules/local/cat_fastq.nf` — `CAT_FASTQ`: concatenates runs for samples with >1 row; single-run samples pass straight through (no copy).
- `assets/test_samplesheet.csv` + `assets/test/*.fastq.gz` — tiny synthetic reads.
- `params.json` dumped into `pipeline_info/` at start.

## Conventions
- One process per file in `modules/local/`; each emits `versions.yml` (`"${task.process}": {tool: version}`), collected into `pipeline_info/software_versions.yml`.
- `meta` map per sample: `[id, single_end, strandedness]`.
- No nf-core template, no nf-schema plugin, no subworkflows dir. Add when `main.nf` gets unwieldy.

## Done when
`nextflow run main.nf -profile test,docker` succeeds and `results/pipeline_info/` contains params, versions, report, trace, timeline.
