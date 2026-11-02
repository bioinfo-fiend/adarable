process FASTQC {
    tag "${meta.id}"
    container 'quay.io/biocontainers/fastqc:0.13.0--hdfd78af_0'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path('*_fastqc.zip'), emit: zip
    path '*_fastqc.html',                  emit: html
    path 'versions.yml',                   emit: versions

    script:
    // Link to sample-id names so reports and MultiQC rows are named by sample, not by input file
    def names = meta.single_end ? ["${meta.id}.fastq.gz"] : ["${meta.id}_1.fastq.gz", "${meta.id}_2.fastq.gz"]
    def links = [[reads].flatten(), names].transpose().collect { r, n -> "[ '${r}' = '${n}' ] || ln -s '${r}' '${n}'" }.join('\n')
    """
    ${links}
    fastqc --threads ${task.cpus} ${names.join(' ')}
    echo '"${task.process}": {fastqc: "'\$(fastqc --version | sed 's/FastQC v//')'"}' > versions.yml
    """
}
