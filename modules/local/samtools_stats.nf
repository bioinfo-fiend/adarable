process SAMTOOLS_STATS {
    tag "${meta.id}"
    container 'community.wave.seqera.io/library/htslib_samtools_star_gawk:ae438e9a604351a4'

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    path "${meta.id}.{stats,flagstat}", emit: stats
    path 'versions.yml',                emit: versions

    script:
    """
    samtools stats -@ ${task.cpus} ${bam} > ${meta.id}.stats
    samtools flagstat -@ ${task.cpus} ${bam} > ${meta.id}.flagstat
    echo '"${task.process}": {samtools: "'\$(samtools --version | head -1 | cut -d' ' -f2)'"}' > versions.yml
    """
}
