// GTF -> BED12 of transcripts for RSeQC infer_experiment.py (bin/gtf2bed12).
process PREP_GENE_BED {
    tag "${gtf.name}"
    container 'quay.io/biocontainers/samtools:1.24--h9dcdb79_1'
    storeDir "${params.ref_cache}/${cache_key}/genes_${gtf.simpleName}"

    input:
    val cache_key   // genome name + fasta fingerprint, see main.nf
    path gtf

    output:
    path 'genes.bed',    emit: bed
    path 'versions.yml', emit: versions

    script:
    """
    ${gtf.name.endsWith('.gz') ? 'gzip -cd' : 'cat'} ${gtf} | gtf2bed12 > genes.bed
    echo '"${task.process}": {awk: "'"\$(awk 2>&1 | head -1)"'"}' > versions.yml
    """
}
