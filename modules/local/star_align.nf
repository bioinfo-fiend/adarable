// 2-pass, unique mappers only, no soft-clipping: see docs/phases/04-align-dedup.md
process STAR_ALIGN {
    tag "${meta.id}"
    container 'community.wave.seqera.io/library/htslib_samtools_star_gawk:ae438e9a604351a4'

    input:
    tuple val(meta), path(reads)
    path index

    output:
    tuple val(meta), path("${meta.id}.star.bam"), path("${meta.id}.star.bam.bai"), emit: bam
    tuple val(meta), path("${meta.id}.Log.final.out"),                            emit: log
    tuple val(meta), path("${meta.id}.SJ.out.tab"),                               emit: sj
    path 'versions.yml',                                                          emit: versions

    script:
    """
    STAR --runThreadN ${task.cpus} \\
        --genomeDir ${index} \\
        --readFilesIn ${reads} \\
        --readFilesCommand 'gzip -cd' \\
        --outFileNamePrefix ${meta.id}. \\
        --twopassMode Basic \\
        --outSAMtype BAM SortedByCoordinate \\
        --outSAMattributes NH HI AS nM NM MD \\
        --outFilterMultimapNmax 1 \\
        --alignEndsType EndToEnd
    mv ${meta.id}.Aligned.sortedByCoord.out.bam ${meta.id}.star.bam
    samtools index ${meta.id}.star.bam
    echo '"${task.process}": {star: "'\$(STAR --version)'", samtools: "'\$(samtools --version | head -1 | cut -d' ' -f2)'"}' > versions.yml
    """
}
