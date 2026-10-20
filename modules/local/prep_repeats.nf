// UCSC rmsk.txt(.gz) -> BED of the chosen repFamily values (human Alu; mouse Alu(=B1),B2).
// A file already ending in .bed is passed through (sorted).
process PREP_REPEATS {
    tag "${families}"
    container 'quay.io/biocontainers/samtools:1.24--h9dcdb79_1'
    storeDir "${params.ref_cache}/${cache_key}/repeats_${repeats.simpleName}_${families.replace(',', '-')}"

    input:
    val cache_key   // genome name + fasta fingerprint, see main.nf
    path repeats
    val families   // comma-separated rmsk repFamily values

    output:
    path 'repeats.bed',  emit: bed
    path 'versions.yml', emit: versions

    script:
    if (repeats.name =~ /\.bed(\.gz)?$/)
        """
        ${repeats.name.endsWith('.gz') ? 'gzip -cd' : 'cat'} ${repeats} | sort -k1,1 -k2,2n > repeats.bed
        echo '"${task.process}": {sort: "'"\$(sort --help 2>&1 | head -1)"'"}' > versions.yml
        """
    else
        """
        ${repeats.name.endsWith('.gz') ? 'gzip -cd' : 'cat'} ${repeats} \\
            | awk -F'\\t' -v OFS='\\t' -v fams='${families}' \\
                'BEGIN {n=split(fams,a,","); for(i=1;i<=n;i++) keep[a[i]]=1} keep[\$13] {print \$6,\$7,\$8,\$11,\$13,\$10}' \\
            | sort -k1,1 -k2,2n > repeats.bed
        echo '"${task.process}": {awk: "'"\$(awk --version 2>&1 | head -1)"'"}' > versions.yml
        """
}
