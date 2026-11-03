// SortMeRNA index of --rrna_db, built once by the same SortMeRNA version that reads it.
// 4.3.6, not 4.3.7: the 4.3.7 biocontainers need AVX-512 and die with SIGILL on AMD Zen 3.
process PREP_SORTMERNA_INDEX {
    tag "${db.name}"
    container 'quay.io/biocontainers/sortmerna:4.3.6--h9ee0642_0'
    storeDir "${params.ref_cache}/sortmerna_${db.simpleName}"

    input:
    path db

    output:
    path 'idx',          emit: index
    path 'versions.yml', emit: versions

    script:
    """
    sortmerna --ref ${db} --idx-dir idx --index 1 --workdir wd --threads ${task.cpus}
    rm -rf wd
    echo '"${task.process}": {sortmerna: "'\$(sortmerna --version 2>&1 | sed -n 's/^SortMeRNA version //p')'"}' > versions.yml
    """
}
