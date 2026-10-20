# 08 — Results dashboard

## Delivers
`bin/make_dashboard.py` → `results/dashboard.html`: one self-contained file (Plotly JS inlined), opens offline, no server.

Panels:
1. Run summary: samples, genome, pipeline version, run date, link to `pipeline_info/` and MultiQC.
2. AEI per sample (bar, colored by group if samplesheet has a `group` column later).
3. Sites per sample: known vs novel, Alu vs non-Alu (stacked bar).
4. Edit-level distribution per sample (violin/box).
5. Top variable sites heatmap from `sites_matrix` (samples × top 50 sites by variance).
6. QC table: input reads, % trimmed, % uniquely mapped, % duplicates, inferred strand — pulled from fastp JSON, STAR `Log.final.out`, Picard metrics.
7. Sortable/filterable site table (top N by coverage) via a plain HTML table + small inline JS filter.

## Decisions
- Static HTML over Shiny/Dash: shareable as a file, archived with results, no running process.
- Runs as the final Nextflow process; also runnable standalone: `make_dashboard.py --results results/`.

## Done when
`results/dashboard.html` renders all panels from the test run, offline.
