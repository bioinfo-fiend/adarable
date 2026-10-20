// REDIportal TABLE1 -> BED6 (chrom, start0, end, name=Ref>Ed:type, 0, strand), lifted over when a chain is given (mouse: mm10 -> mm39).
// Columns found by header name: hg38 v3 has a leading Accession column, mm10 does not.
process PREP_KNOWN_SITES {
    tag "${rediportal.name}"
    container 'quay.io/biocontainers/ucsc-liftover:482--h0b57e2e_0'
    storeDir "${params.ref_cache}/${cache_key}/known_sites_${rediportal.simpleName}"

    input:
    val cache_key   // genome name + fasta fingerprint, see main.nf
    path rediportal
    path chain   // [] when no liftover needed

    output:
    path 'known_sites.bed', emit: bed
    path 'versions.yml',    emit: versions

    script:
    def lift = chain
        ? "liftOver sites.bed ${chain} lifted.bed unlifted.bed && sort -k1,1 -k2,2n lifted.bed > known_sites.bed && echo \"lifted \$(wc -l < known_sites.bed), dropped \$(grep -vc '^#' unlifted.bed)\" >&2"
        : "mv sites.bed known_sites.bed"
    """
    ${rediportal.name.endsWith('.gz') ? 'gzip -cd' : 'cat'} ${rediportal} \\
        | awk -F'\\t' -v OFS='\\t' 'NR==1 {for (i=1; i<=NF; i++) c[\$i]=i; next}
            {print \$c["Region"], \$c["Position"]-1, \$c["Position"], \$c["Ref"] ">" \$c["Ed"] ":" \$c["type"], 0, \$c["Strand"]}' \\
        | sort -k1,1 -k2,2n > sites.bed
    ${lift}
    echo '"${task.process}": {liftOver: "ucsc-482"}' > versions.yml
    """
}
