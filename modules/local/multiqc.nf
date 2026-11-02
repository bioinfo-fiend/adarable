process MULTIQC {
    container 'quay.io/biocontainers/multiqc:1.35--pyhdfd78af_0'

    input:
    path '*'

    output:
    path 'multiqc_report.html', emit: report
    path 'multiqc_report_data', emit: data
    path 'versions.yml',        emit: versions

    script:
    """
    multiqc --force --filename multiqc_report.html .
    echo '"${task.process}": {multiqc: "'\$(multiqc --version | sed 's/.*version //')'"}' > versions.yml
    """
}
