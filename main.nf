#!/usr/bin/env nextflow
// ADARable: A-to-I RNA editing pipeline. Phase docs: docs/phases/

include { CHECK_SAMPLESHEET } from './modules/local/check_samplesheet'
include { CAT_FASTQ         } from './modules/local/cat_fastq'

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

    // Provenance
    ch_versions
        .unique()
        .collectFile(name: 'software_versions.yml', storeDir: "${params.outdir}/pipeline_info", sort: true)
}

workflow.onComplete {
    log.info "Done: ${workflow.success ? 'OK' : 'FAILED'} — results in ${params.outdir}"
}
