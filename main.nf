#!/usr/bin/env nextflow
// ADARable: A-to-I RNA editing pipeline. Phase docs: docs/phases/

include { CHECK_SAMPLESHEET   } from './modules/local/check_samplesheet'
include { CAT_FASTQ           } from './modules/local/cat_fastq'
include { PREP_FASTA          } from './modules/local/prep_fasta'
include { STAR_GENOMEGENERATE } from './modules/local/star_genomegenerate'
include { PREP_REPEATS        } from './modules/local/prep_repeats'
include { PREP_KNOWN_SITES    } from './modules/local/prep_known_sites'

// --fasta etc. win over the --genome entry in conf/genomes.config; an entry with `base` falls back to that genome
def ref(String key) {
    if (!params.genome) return params[key]
    def g = params.genomes[params.genome]
    if (!g) error "Unknown --genome '${params.genome}'. Known: ${params.genomes.keySet().join(', ')}"
    params[key] ?: g[key] ?: (g.base ? params.genomes[g.base][key] : null)
}

// Relative FASTQ paths resolve against the samplesheet's directory.
def resolveFastq(String p, sheetDir) {
    file(p.contains('://') || p.startsWith('/') ? p : "${sheetDir}/${p}", checkIfExists: true)
}

workflow {
    if (!params.input) error "Provide --input samplesheet.csv"
    def sheet = file(params.input, checkIfExists: true)

    def info = file("${params.outdir}/pipeline_info")
    info.mkdirs()
    info.resolve('params.json').text = groovy.json.JsonOutput.prettyPrint(groovy.json.JsonOutput.toJson(params))

    ch_versions = channel.empty()

    CHECK_SAMPLESHEET(sheet)
    ch_versions = ch_versions.mix(CHECK_SAMPLESHEET.out.versions)

    ch_samples = CHECK_SAMPLESHEET.out.csv
        .splitCsv(header: true)
        .map { row ->
            def meta = [id: row.sample, single_end: row.single_end == 'true', strandedness: row.strandedness]
            def r1 = row.fastq_1.tokenize(';').collect { resolveFastq(it, sheet.parent) }
            def r2 = row.fastq_2 ? row.fastq_2.tokenize(';').collect { resolveFastq(it, sheet.parent) } : []
            [meta, r1, r2]
        }
        .branch { _meta, r1, _r2 ->
            multi:  r1.size() > 1
            single: true
        }

    CAT_FASTQ(ch_samples.multi)
    ch_versions = ch_versions.mix(CAT_FASTQ.out.versions)

    ch_reads = ch_samples.single
        .map { meta, r1, r2 -> [meta, r1 + r2] }
        .mix(CAT_FASTQ.out.reads)

    ch_reads.view { meta, reads -> "reads: ${meta.id} ${reads*.name}" }

    // References (phase 02): prepared once, cached in --ref_cache
    if (!ref('fasta') || !ref('gtf')) error "Need --fasta and --gtf (or a --genome with both)"

    // Cache folder per reference: the genome name alone would reuse a STAR index built from another FASTA
    def cache_key = "${params.genome ?: 'custom'}-${ref('fasta').toString().md5().take(8)}"

    PREP_FASTA(cache_key, file(ref('fasta'), checkIfExists: true))
    ch_fasta = PREP_FASTA.out.fasta
    ch_versions = ch_versions.mix(PREP_FASTA.out.versions)

    if (ref('star_index')) {
        ch_star = channel.value(file(ref('star_index'), checkIfExists: true))
    } else {
        STAR_GENOMEGENERATE(cache_key, ch_fasta, file(ref('gtf'), checkIfExists: true))
        ch_star = STAR_GENOMEGENERATE.out.index
        ch_versions = ch_versions.mix(STAR_GENOMEGENERATE.out.versions)
    }

    ch_repeats = channel.value([])
    if (ref('repeats')) {
        PREP_REPEATS(cache_key, file(ref('repeats'), checkIfExists: true), ref('repeat_families') ?: 'Alu')
        ch_repeats = PREP_REPEATS.out.bed
        ch_versions = ch_versions.mix(PREP_REPEATS.out.versions)
    }

    ch_known = channel.value([])
    if (ref('rediportal')) {
        def chain = ref('rediportal_chain') ? file(ref('rediportal_chain'), checkIfExists: true) : []
        PREP_KNOWN_SITES(cache_key, file(ref('rediportal'), checkIfExists: true), chain)
        ch_known = PREP_KNOWN_SITES.out.bed
        ch_versions = ch_versions.mix(PREP_KNOWN_SITES.out.versions)
    }

    ch_dbsnp = ref('dbsnp') ? channel.value([file(ref('dbsnp'), checkIfExists: true), file(ref('dbsnp_index'), checkIfExists: true)]) : channel.value([])

    // Provenance
    ch_versions
        .unique()
        .collectFile(name: 'software_versions.yml', storeDir: "${params.outdir}/pipeline_info", sort: true)
}

workflow.onComplete {
    log.info "Done: ${workflow.success ? 'OK' : 'FAILED'} — results in ${params.outdir}"
}
