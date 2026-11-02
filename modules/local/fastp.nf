process FASTP {
    tag "${meta.id}"
    container 'quay.io/biocontainers/fastp:1.4.0--h43da1c4_0'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path('*.trim.fastq.gz'), emit: reads
    tuple val(meta), path('*.fastp.json'),    emit: json
    path '*.fastp.html',                      emit: html
    path 'versions.yml',                      emit: versions

    script:
    def names = meta.single_end ? ["${meta.id}.fastq.gz"] : ["${meta.id}_1.fastq.gz", "${meta.id}_2.fastq.gz"]
    def links = [[reads].flatten(), names].transpose().collect { r, n -> "[ '${r}' = '${n}' ] || ln -s '${r}' '${n}'" }.join('\n')
    def io = meta.single_end
        ? "--in1 ${names[0]} --out1 ${meta.id}.trim.fastq.gz"
        : "--in1 ${names[0]} --in2 ${names[1]} --out1 ${meta.id}_1.trim.fastq.gz --out2 ${meta.id}_2.trim.fastq.gz --detect_adapter_for_pe"
    // Adapters are auto-detected; --adapter_fasta adds known ones (e.g. MGI/DNBSEQ)
    def adapters = params.adapter_fasta ? "--adapter_fasta ${params.adapter_fasta}" : ''
    // UMI moved into the read name (:UMI_xxx) for UMI-aware dedup in phase 04
    def umi = params.umi_loc ? "--umi --umi_loc ${params.umi_loc} --umi_len ${params.umi_len}" : ''
    // Low-quality ends trimmed: end mismatches would look like editing
    """
    ${links}
    fastp ${io} \\
        --thread ${task.cpus} \\
        --cut_front --cut_tail --cut_mean_quality 20 \\
        --length_required 30 \\
        ${adapters} ${umi} \\
        --json ${meta.id}.fastp.json \\
        --html ${meta.id}.fastp.html
    echo '"${task.process}": {fastp: "'\$(fastp --version 2>&1 | sed 's/fastp //')'"}' > versions.yml
    """
}
