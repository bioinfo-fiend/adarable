process MULTIQC {
    container 'quay.io/biocontainers/multiqc:1.35--pyhdfd78af_0'

    input:
    path '*'

    output:
    path 'multiqc_report.html',                           emit: report
    path 'multiqc_report_data',                           emit: data
    path 'sequencing_stats.tsv',                          emit: summary
    path 'versions.yml',                                  emit: versions

    script:
    """
    multiqc --force --filename multiqc_report.html .
    cp multiqc_report_data/multiqc_general_stats.txt sequencing_stats.tsv
    echo '"${task.process}": {multiqc: "'\$(multiqc --version | sed 's/.*version //')'"}' > versions.yml
    """
}
