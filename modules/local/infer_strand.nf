// RSeQC infer_experiment.py -> strand.txt: forward, reverse or unstranded.
process INFER_STRAND {
    tag "${meta.id}"
    container 'quay.io/biocontainers/rseqc:5.0.4--pyhdfd78af_1'

    input:
    tuple val(meta), path(bam), path(bai)
    path gene_bed

    output:
    tuple val(meta), path('strand.txt'),                       emit: strand
    tuple val(meta), path("${meta.id}.infer_experiment.txt"), emit: txt
    path 'versions.yml',                                       emit: versions

    script:
    // "1++,1--,2+-,2-+" (PE) / "++,--" (SE): read 1 on the gene strand = forward; "1+-,..." / "+-,-+" = reverse
    // ponytail: fixed 80% cut-off, anything weaker is called unstranded; add an "undetermined" class if mixed libraries show up
    """
    infer_experiment.py -r ${gene_bed} -i ${bam} -s 200000 > ${meta.id}.infer_experiment.txt
    awk -F': ' '
        /explained by "1?\\+\\+,/ { f = \$2 }
        /explained by "1?\\+-,/   { r = \$2 }
        END {
            t = f + r
            print (t > 0 && f / t >= 0.8) ? "forward" : (t > 0 && r / t >= 0.8) ? "reverse" : "unstranded"
        }' ${meta.id}.infer_experiment.txt > strand.txt
    echo '"${task.process}": {rseqc: "'\$(infer_experiment.py --version | sed 's/.* //')'"}' > versions.yml
    """
}
