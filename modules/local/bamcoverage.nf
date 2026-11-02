// CPM bigWigs, duplicates excluded. Stranded libraries get one file per gene strand (plus/minus).
process BAMCOVERAGE {
    tag "${meta.id}"
    container 'quay.io/biocontainers/deeptools:3.5.6--pyhdfd78af_0'

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path('*.bw'), emit: bigwig
    path 'versions.yml',           emit: versions

    script:
    def args = "-b ${bam} -p ${task.cpus} --normalizeUsing CPM --samFlagExclude 1024"
    // --filterRNAstrand assumes dUTP (reverse) libraries; forward-stranded ones need the two labels swapped
    def (plus, minus) = meta.strandedness == 'reverse' ? ['forward', 'reverse'] : ['reverse', 'forward']
    def cmd = meta.strandedness == 'unstranded'
        ? "bamCoverage ${args} -o ${meta.id}.bw"
        : "bamCoverage ${args} --filterRNAstrand ${plus} -o ${meta.id}.plus.bw\n    bamCoverage ${args} --filterRNAstrand ${minus} -o ${meta.id}.minus.bw"
    """
    ${cmd}
    echo '"${task.process}": {deeptools: "'\$(bamCoverage --version | sed 's/bamCoverage //')'"}' > versions.yml
    """
}
