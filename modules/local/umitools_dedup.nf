// UMI-aware dedup (used when --umi_loc is set): removes duplicates, using the UMI fastp put after the last ':' of the read name.
process UMITOOLS_DEDUP {
    tag "${meta.id}"
    container 'quay.io/biocontainers/umi_tools:1.1.6--py312h0fa9677_0'

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("${meta.id}.dedup.bam"), path("${meta.id}.dedup.bam.bai"), emit: bam
    path "${meta.id}.umi_dedup.log",                                                emit: log
    path 'versions.yml',                                                            emit: versions

    script:
    // Fail fast if the UMI is not in the read names: STAR cuts names at '/', so SRA-style '.../1:UMI' loses it
    """
    python - <<'PY'
    import itertools, re, sys, pysam
    names = [r.query_name for r in itertools.islice(pysam.AlignmentFile('${bam}'), 1000)]
    if not all(re.fullmatch('[ACGTN_]+', n.rsplit(':', 1)[-1]) for n in names):
        sys.exit("No UMI after the last ':' in read names (e.g. %s). Read names with '/1' lose it at STAR." % names[0])
    PY
    umi_tools dedup \\
        --stdin ${bam} \\
        --stdout ${meta.id}.dedup.bam \\
        --log ${meta.id}.umi_dedup.log \\
        --umi-separator ':' \\
        ${meta.single_end ? '' : '--paired'}
    python -c "import pysam; pysam.index('${meta.id}.dedup.bam')"
    echo '"${task.process}": {umi_tools: "'\$(umi_tools --version | sed 's/.*: //')'"}' > versions.yml
    """
}
