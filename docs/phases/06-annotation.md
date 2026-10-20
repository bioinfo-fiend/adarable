# 06 — Annotation and site filtering

## Delivers
`bin/annotate_sites.py` (stdlib + pysam for tabix lookups) → `annotated_sites.tsv.gz` with added columns:
- `known_rediportal` (bool), `dbsnp` (rsID or empty), `repeat` (Alu/SINE family or empty), `gene`, `region` (exon/intron/UTR/intergenic from GTF), `edit_level` = G/(A+G) on the transcribed strand.

Filters (params, defaults):
- keep A>G on + strand, T>C read as A>G on − strand (unstranded: both, annotated as ambiguous)
- `min_coverage` 10, `min_edited_reads` 2, `min_edit_level` 0.01
- drop dbSNP sites unless `known_rediportal` (`--keep_snp_sites` to disable)
- self-check: `python bin/annotate_sites.py`

## Notes
- Assert chromosome names match between sites and references on first lookup; fail loudly.
- Interval lookups: GTF/BED loaded into per-chrom sorted lists + `bisect` (no pybedtools).

## Done when
Spike-ins listed in the test REDIportal file are flagged `known_rediportal=True`; those inside the test repeat BED get `repeat=Alu`.
