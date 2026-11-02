// Marks duplicates (flag 1024), keeps them in the BAM; REDItools and bamCoverage skip flagged reads.
process SAMTOOLS_MARKDUP {
    tag "${meta.id}"
    container 'community.wave.seqera.io/library/htslib_samtools_star_gawk:ae438e9a604351a4'

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("${meta.id}.dedup.bam"), path("${meta.id}.dedup.bam.bai"), emit: bam
    path "${meta.id}.markdup.stats",                                                emit: stats
    path 'versions.yml',                                                            emit: versions

    script:
    // fixmate -m adds the mate tags markdup needs; it wants name-grouped input
    """
    samtools collate -@ ${task.cpus} -O -u ${bam} \\
        | samtools fixmate -m -u - - \\
        | samtools sort -@ ${task.cpus} -u - \\
        | samtools markdup -@ ${task.cpus} -f ${meta.id}.markdup.stats - ${meta.id}.dedup.bam
    samtools index ${meta.id}.dedup.bam
    echo '"${task.process}": {samtools: "'\$(samtools --version | head -1 | cut -d' ' -f2)'"}' > versions.yml
    """
}
