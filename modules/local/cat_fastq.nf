// Only called for samples with >1 run; single-run samples skip this process.
process CAT_FASTQ {
    tag "${meta.id}"
    container 'quay.io/biocontainers/pysam:0.24.1--py312hf5ad864_0'

    input:
    tuple val(meta), path(r1, stageAs: 'r1/*'), path(r2, stageAs: 'r2/*')

    output:
    tuple val(meta), path('*.merged.fastq.gz'), emit: reads
    path 'versions.yml',                        emit: versions

    script:
    if (meta.single_end)
        """
        cat ${r1} > ${meta.id}.merged.fastq.gz
        echo '"${task.process}": {cat: "'"\$(cat --help 2>&1 | head -1)"'"}' > versions.yml
        """
    else
        """
        cat ${r1} > ${meta.id}_1.merged.fastq.gz
        cat ${r2} > ${meta.id}_2.merged.fastq.gz
        echo '"${task.process}": {cat: "'"\$(cat --help 2>&1 | head -1)"'"}' > versions.yml
        """
}
