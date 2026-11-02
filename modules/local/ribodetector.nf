// rRNA read classification. % rRNA always goes to MultiQC; the non-rRNA reads replace the trimmed ones with --remove_rrna.
process RIBODETECTOR {
    tag "${meta.id}"
    container 'quay.io/biocontainers/ribodetector:0.3.3--pyhdfd78af_0'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path('*.nonrrna.fastq.gz'), emit: reads
    path "${meta.id}.ribodetector.log",         emit: log
    path "${meta.id}.ribodetector_mqc.tsv",     emit: mqc
    path 'versions.yml',                        emit: versions

    script:
    def out = meta.single_end ? "${meta.id}.nonrrna.fastq.gz" : "${meta.id}_1.nonrrna.fastq.gz ${meta.id}_2.nonrrna.fastq.gz"
    // -e rrna: a pair counts as rRNA only when both mates are called rRNA
    """
    ribodetector_cpu -t ${task.cpus} \\
        -l ${params.read_length} \\
        -i ${reads} \\
        -o ${out} \\
        ${meta.single_end ? '' : '-e rrna'} \\
        --chunk_size 256 \\
        --log ${meta.id}.ribodetector.log
    awk -v id=${meta.id} '
            { gsub(/\\033\\[[0-9;]*m/, "") }   # log has colour codes
            /Processed .* sequences in total/ { n = \$(NF - 3) }
            /Detected .* rRNA sequences/ && !/non-rRNA/ { r = \$(NF - 2) }
            END {
                print "# id: ribodetector"
                print "# plot_type: generalstats"
                print "# pconfig:"
                print "#     pct_rrna:"
                print "#         title: \\"% rRNA\\""
                print "#         description: \\"RiboDetector: reads (pairs) classified as rRNA\\""
                print "#         suffix: \\"%\\""
                print "#         max: 100"
                print "Sample\\tpct_rrna"
                printf "%s\\t%.2f\\n", id, n ? 100 * r / n : 0
            }' ${meta.id}.ribodetector.log > ${meta.id}.ribodetector_mqc.tsv
    echo '"${task.process}": {ribodetector: "'\$(ribodetector_cpu --version | sed 's/.* //')'"}' > versions.yml
    """
}
