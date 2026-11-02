process STAR_GENOMEGENERATE {
    tag "sjdbOverhang ${params.read_length - 1}"
    container 'community.wave.seqera.io/library/htslib_samtools_star_gawk:ae438e9a604351a4'   // same image as STAR_ALIGN (nf-core)
    storeDir "${params.ref_cache}/${cache_key}/star_${params.read_length - 1}"

    input:
    val cache_key   // genome name + fasta fingerprint, see main.nf
    tuple path(fasta), path(fai)
    path gtf

    output:
    path 'star',         emit: index
    path 'versions.yml', emit: versions

    script:
    // STAR manual: genomeSAindexNbases = min(14, log2(genome length)/2 - 1); matters for small/test genomes
    def nbases = """\$(awk '{s+=\$2} END {n=int(log(s)/log(2)/2-1); print (n<14?n:14)}' ${fai})"""
    """
    ${gtf.name.endsWith('.gz') ? 'gzip -cd' : 'cat'} ${gtf} > genes.gtf
    mkdir star
    STAR --runMode genomeGenerate \\
        --runThreadN ${task.cpus} \\
        --genomeDir star \\
        --genomeFastaFiles ${fasta} \\
        --sjdbGTFfile genes.gtf \\
        --sjdbOverhang ${params.read_length - 1} \\
        --genomeSAindexNbases ${nbases}
    rm genes.gtf
    echo '"${task.process}": {star: "'\$(STAR --version)'"}' > versions.yml
    """
}
