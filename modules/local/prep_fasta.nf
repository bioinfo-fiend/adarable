// Uncompressed FASTA + .fai: STAR and REDItools both need it.
process PREP_FASTA {
    tag "${fasta.name}"
    container 'quay.io/biocontainers/samtools:1.24--h9dcdb79_1'
    storeDir "${params.ref_cache}/${cache_key}/fasta"

    input:
    val cache_key   // genome name + fasta fingerprint, see main.nf
    path fasta

    output:
    tuple path('genome.fa'), path('genome.fa.fai'), emit: fasta
    path 'versions.yml',                            emit: versions

    script:
    """
    ${fasta.name.endsWith('.gz') ? 'gzip -cd' : 'cat'} ${fasta} > genome.fa
    samtools faidx genome.fa
    echo '"${task.process}": {samtools: "'\$(samtools --version | head -1 | cut -d' ' -f2)'"}' > versions.yml
    """
}
