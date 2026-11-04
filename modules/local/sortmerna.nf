// rRNA check with SortMeRNA, settings checked against bbduk. % rRNA always goes to MultiQC; with --remove_rrna the
// whole library is classified and the non-rRNA reads go on to STAR. Otherwise only the first
// --rrna_reads reads (pairs) are checked: whole libraries take hours (1.5-3 min per 1 M pairs, 16 CPUs).
process SORTMERNA {
    tag "${meta.id}"
    container 'quay.io/biocontainers/sortmerna:4.3.6--h9ee0642_0'

    input:
    tuple val(meta), path(reads)
    path db
    path index

    output:
    tuple val(meta), path('*.nonrrna.fastq.gz'), emit: reads, optional: true
    path "${meta.id}.sortmerna.log",            emit: log
    path "${meta.id}.sortmerna_mqc.tsv",        emit: mqc
    path 'versions.yml',                        emit: versions

    script:
    def input = [reads].flatten()
    // ponytail: first N reads, not a random sample; fine for a percentage unless a run's first tiles are odd
    def take = params.remove_rrna
        ? input.withIndex().collect { r, i -> "ln -s ${r} in_${i + 1}.fastq.gz" }.join('\n    ')
        : input.withIndex().collect { r, i -> "gzip -cd ${r} | head -n ${4 * params.rrna_reads} | gzip -1 > in_${i + 1}.fastq.gz || true" }.join('\n    ')
    def reads_args = (1..input.size()).collect { "--reads in_${it}.fastq.gz" }.join(' ')
    // --paired_in: a pair is rRNA when either mate hits (matches bbduk in an internal comparison)
    def paired = meta.single_end ? '' : '--paired_in --out2'
    def keep = params.remove_rrna
        ? (meta.single_end ? "mv non_rRNA.f*q.gz ${meta.id}.nonrrna.fastq.gz"
                           : "mv non_rRNA_fwd.f*q.gz ${meta.id}_1.nonrrna.fastq.gz\n    mv non_rRNA_rev.f*q.gz ${meta.id}_2.nonrrna.fastq.gz")
        : ''
    """
    ${take}
    sortmerna \\
        --ref ${db} --idx-dir ${index} --index 0 \\
        ${reads_args} \\
        ${paired} --num_alignments 1 \\
        --fastx --aligned rRNA ${params.remove_rrna ? '--other non_rRNA' : ''} \\
        --threads ${task.cpus} --workdir wd
    ${keep}
    mv rRNA.log ${meta.id}.sortmerna.log

    n=\$(( \$(gzip -cd in_1.fastq.gz | wc -l) / 4 ))
    r=\$(( \$(gzip -cd \$(ls rRNA*.f*q.gz | head -1) | wc -l) / 4 ))
    {
        echo '# id: sortmerna'
        echo '# plot_type: generalstats'
        echo '# pconfig:'
        echo '#     pct_rrna:'
        echo '#         title: "% rRNA"'
        echo '#         description: "SortMeRNA: reads (pairs) with an rRNA hit"'
        echo '#         suffix: "%"'
        echo '#         max: 100'
        printf 'Sample\\tpct_rrna\\n'
        awk -v id=${meta.id} -v n=\$n -v r=\$r 'BEGIN { printf "%s\\t%.2f\\n", id, n ? 100 * r / n : 0 }'
    } > ${meta.id}.sortmerna_mqc.tsv
    rm -rf wd rRNA*.f*q.gz in_*.fastq.gz
    echo '"${task.process}": {sortmerna: "'\$(sortmerna --version 2>&1 | sed -n 's/^SortMeRNA version //p')'"}' > versions.yml
    """
}
