// REDItools3 per-sample site table. Its read filter already drops duplicates, secondary, supplementary
// and improper pairs. Stranded libraries are reported on the RNA strand (-C), so A>G is always "AG".
process REDITOOLS {
    tag "${meta.id}"
    container 'quay.io/biocontainers/reditools3:3.7--pyhdfd78af_0'

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("${meta.id}.reditools.tsv.gz"), emit: tsv
    path 'versions.yml',                                  emit: versions

    script:
    def strand = [unstranded: '0', forward: '1', reverse: '2'][meta.strandedness]
    // -t parallelises by contig; -mbp/-Mbp drop mismatches in the first/last 5 bases of each read
    """
    python -m reditools analyze ${bam} \\
        -s ${strand} ${strand == '0' ? '' : '-C'} \\
        -q 20 -bq 25 -mbp 5 -Mbp 5 \\
        -t ${task.cpus} --temp-dir . \\
        -o ${meta.id}.reditools.tsv
    gzip -n ${meta.id}.reditools.tsv
    echo '"${task.process}": {reditools3: "'\$(python -c 'from importlib.metadata import version; print(version("reditools3"))')'"}' > versions.yml
    """
}
