process CHECK_SAMPLESHEET {
    container 'quay.io/biocontainers/pysam:0.24.1--py312hf5ad864_0'

    input:
    path samplesheet

    output:
    path 'samplesheet.valid.csv', emit: csv
    path 'versions.yml',          emit: versions

    script:
    """
    check_samplesheet.py ${samplesheet} samplesheet.valid.csv
    echo '"${task.process}": {python: "'\$(python3 --version | cut -d' ' -f2)'"}' > versions.yml
    """
}
