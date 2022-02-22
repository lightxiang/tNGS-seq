#!/usr/bin/env nextflow

/*
========================================================================================
      sagene-plugins/rpdseq-reborn 主流程脚本
========================================================================================
 #### Homepage / Documentation
 #### http://git.sagene.com.cn/sagene-plugins/rpdseq-reborn
----------------------------------------------------------------------------------------
*/


/*
 * 帮助信息
 */
def helpMessage() {
    log.info"""
    Usage:

    The typical command for running the pipeline is as follows
      for dna library:
          nextflow run ${workflow.projectDir} --dbdir /path/to/db_base --input input.csv --data /path/to/rawdata --dedup

    Mandatory arguments
      --input                [file] Path to design input data (must be surrounded with quotes)
      --dbdir                 [str] rpdseq-reborn db root dir.
      -profile                [str] Configuration profile to use. Can use multiple (comma separated)
                                    Available: conda, docker, test and more.

    Generic
      --data                  [str] the main data dir
      --add                   [str] the additional data dir
      --length_required       [int] reads shorter than length_required will be discarded in AwsFastp/Fastp, default is 75
      --lims                  [float] min mapping identity allowed, default is 0.95
      --match                 [int] min mapping length allowed, default is 90
      --reads_to_process      [int] specify how many reads/pairs to be processed. Default 0 means process all reads.
      --pe                    [bool] input datas are paired-end, default is false (se)
      --libprepkit            [str] library preparation kit name, one of database.config libprepkit, default is ``auto``,
                                    Available: ELQ, XT, TruSeq, auto
                                    Attention: this argument is global, when a sample set it specified in
                                               design_input.libprepkit and could be found in database.config
                                               libprepkit, this argument will be ignored.
      --sample_type           [str] the sample type, effect to diagnosis test and summary schema, default is ``auto``
                                    Available: csf, ncov, auto
                                    Attention: this argument is global, when a sample set it specified in
                                               design_input.sample_type and could be found in database.config
                                               sample_type, this argument will be ignored.
      --algorithm             [str] pathogens alignment algorithm, default is ``bwa-men``,
                                  Available: bwa-mem
                            


    Database Version
      --tgdb                  [str] tNGS microbe database version, default is ``20220216``


    Other options
      -name                  [str] Name for the pipeline run. If not specified, Nextflow will automatically generate a random mnemonic.
      --outdir               [file] The output directory where The Intermediate and The Results will be saved
      --tracedir             [file] The output directory where the pipeline running info will be saved
      --help                        Print this help message.

    AWSBatch
      --awsqueue              [str] The AWSBatch JobQueue that needs to be set when running on AWSBatch
      --awsregion             [str] The AWS Region for your AWS Batch job to run on

    """.stripIndent()
}


// 显示帮助文档
if (params.help){
    helpMessage()
    exit 0
}

////////////////////////////////////////////////////
/* --                   AWS                    -- */
////////////////////////////////////////////////////

if (workflow.profile == 'awsbatch') {
    // AWSBatch sanity checking
    if (!params.awsqueue || !params.awsregion) exit 1, "Specify correct --awsqueue and --awsregion parameters on AWSBatch!"
    // Check outdir paths to be S3 buckets if running on AWSBatch
    // related: https://github.com/nextflow-io/nextflow/issues/813
    if (!params.outdir.startsWith('s3:')) exit 1, "Outdir not on S3 - specify S3 Bucket to run on AWSBatch!"
    // Prevent trace files to be stored on S3 since S3 does not support rolling files.
    if (workflow.tracedir.startsWith('s3:')) exit 1, "Specify a local tracedir or run without trace! S3 cannot be used for tracefiles."
}




// 检查设定参数是否符合规范
def algorithms = ['bwa-mem']
if (!algorithms.contains(params.algorithm)) {
    exit 1, "The provided alignment algorithms ${params.algorithm} is invalid."
}

// 参数设置
// PART 1: create align index channels
params.tg_bwa_index   = params.pathogenRefs.genomes.bwa
//params.tg_bowtie2_index   = params.pathogenRefs.genomes.bowtie2


//bwa index
if (params.tg_bwa_index) {
    lastPath = params.tg_bwa_index.lastIndexOf(File.separator)
    tg_bwa_dir =  params.tg_bwa_index.substring(0,lastPath+1)
    tg_bwa_base = params.tg_bwa_index.substring(lastPath+1)
    Channel
        .fromPath(tg_bwa_dir, checkIfExists: true)
        .set { ch_tg_bwa_index }
}
//bowtie2 index
//if (params.tg_bowtie2_index) {
//    lastPath = params.tg_bowtie2_index.lastIndexOf(File.separator)
//    tg_bowtie2_dir =  params.tg_bowtie2_index.substring(0,lastPath+1)
//    tg_bowtie2_base = params.tg_bowtie2_index.substring(lastPath+1)
//    Channel
//        .fromPath(tg_bowtie2_dir, checkIfExists: true)
//        .set { ch_tg_bowtie2_index }
//}

Channel
    .fromPath(params.databases.pathogens.tab, checkIfExists: true)
    .set { ch_pathogens_db }
Channel
    .fromPath(params.databases.pathogens.coefficient, checkIfExists: true)
    .set { ch_pathogens_coefficient }

Channel
    .fromPath(params.presets.summary.fastp_column_config, checkIfExists: true)
    .set { ch_fastp_column_config }






// 输出目录路径
Channel.fromPath("${params.outdir}").set{ result_path }
intermediate = "${params.outdir}/Intermediate"
results = "${params.outdir}/Results"


/*
 * 流程步骤
 */

// 原始数据处理逻辑
// STEP 0 - prefetch data
if (params.samples) {
// 输入流获取方式1 awsbatch params.samples
    sample_info = []
    for (it in params.samples) {
        it.data_source.eachWithIndex { elem, index ->
                sample_info.add([elem.data_id + '-' + elem.batch_id, file([params.indir, elem.machine_id, elem.batch_id, elem.data_id + "*.fq.gz"].join("/")), 
                                [it.primer[index]["forward"], it.primer[index]["reverse"]], elem.library_type, it.infos["s_type"]])
        }
    }
    // sample_info: [sample_name], [file(reads)], [library_type], [sample_type]
    // create channels for input fastq files
    Channel
        .from(sample_info)
        .map { it -> [it[0], it[1]] }
        .into { ch_raw_reads; ch_fastqc_raw_reads }

    // create channel sample traits
    Channel
        .from(sample_info)
        .map { it -> [it[0], it[2]] }
        .set { ch_adapter }

    Channel
        .from(sample_info)
        .map { it -> [it[0], it[3]] }
        .into { ch_library_type_I; ch_library_type_II; ch_library_type_III; ch_library_type_IV }

    Channel
        .from(sample_info)
        .map { it -> [it[0], it[4]] }
        .into { ch_sample_type_I; ch_sample_type_II }

} else if (params.lrmconf) {
// 输入流获取方式2 LRM params.lrmconf
    sample_info = []
    for (it in params.lrmconf) {
        it.data_source.eachWithIndex { elem, index ->
                sample_info.add([elem.data_id + '-' + elem.serial_number, file([params.indir, elem.serial_number, elem.data_id + "*.fq.gz"].join("/")), 
                                [it.primer[index]["forward"], it.primer[index]["reverse"]], elem.library_type, it.infos["sample_type"]])
        }
    }
    // sample_info: [sample_name], [file(reads)], [library_type], [sample_type]
    // create channels for input fastq files
    Channel
        .from(sample_info)
        .map { it -> [it[0], it[1]] }
        .into { ch_raw_reads; ch_fastqc_raw_reads }

    // create channel sample traits
    Channel
        .from(sample_info)
        .map { it -> [it[0], it[2]] }
        .set { ch_adapter }

    Channel
        .from(sample_info)
        .map { it -> [it[0], it[3]] }
        .into { ch_library_type_I; ch_library_type_II; ch_library_type_III; ch_library_type_IV }

    Channel
        .from(sample_info)
        .map { it -> [it[0], it[4]] }
        .into { ch_sample_type_I; ch_sample_type_II }

} else {
// 输入流获取方式3 localslurm params.input
    if (params.input) { ch_input = file(params.input, checkIfExists: true) } else { exit 1, "Samples design file not specified!" }

    process Prefetch {
        tag "$name"
        label 'process_low'
        publishDir "${intermediate}/01.Prefetch", mode: 'copy'

        input:
        file design from ch_input

        output:
        file "data.csv" into ch_ready_data_csv
        file "libprepkit.csv"  into ch_ready_libprepkit_csv
        file "library_type.csv" into ch_ready_library_type_csv
        file "sample_type.csv" into ch_ready_sample_type_csv
        file "name.csv"
        file "failed.csv"
        file "*.csv"

        script:
        seqdata = params.data ? "--sd ${params.data}" : ''
        rawdata = params.add  ? "--rd ${params.add}"  : ''
        """
        preFetch.py $seqdata $rawdata -i $design -o .
        """
    }
    // create channels for input fastq files
    if (params.pe) {
        ch_ready_data_csv
            .splitCsv(header:true, sep:',')
            .map { row -> [ row.sample_id, [ file(row.read1, checkIfExists: true), file(row.read2, checkIfExists: true) ] ] }
            .into { ch_raw_reads; ch_fastqc_raw_reads }
    } else {
        ch_ready_data_csv
            .splitCsv(header:true, sep:',')
            .map { row -> [ row.sample_id, [ file(row.read1, checkIfExists: true) ] ] }
            .into { ch_raw_reads; ch_fastqc_raw_reads }
    }

    // create channel sample traits
    ch_ready_libprepkit_csv
        .splitCsv(header:true, sep:',')
        .map { row -> [ row.sample_id, row.libprepkit ] }
        .set { ch_libprepkit }

    ch_ready_library_type_csv
        .splitCsv(header:true, sep:',')
        .map { row -> [ row.sample_id, row.library_type ] }
        .into { ch_library_type_I; ch_library_type_II; ch_library_type_III; ch_library_type_IV }

    ch_ready_sample_type_csv
        .splitCsv(header:true, sep:',')
        .map { row -> [ row.sample_id, row.sample_type ] }
        .into { ch_sample_type_I; ch_sample_type_II }
}


// STEP 1-1 - Fastp
if (params.samples || params.lrmconf) {
    process AwsFastp {
        tag "$name"
        cpus 8
        memory { 16.GB * (0.5 + 0.5 * task.attempt) }
        time   { 10.m * task.attempt }
        publishDir "${intermediate}/02.Fastp", mode: 'copy',
            saveAs: { filename ->
                          if (filename.endsWith(".json")) "json/$filename"
                          else if (filename.endsWith(".html")) "html/$filename"
                          else if (filename.endsWith(".FastQ.gz")) "clean_data/$filename"
                          else filename
                    }

        input:
        set val(name), file(reads), val(adapter) from ch_raw_reads
                                                       .join(ch_adapter, by:[0])

        output:
        set val(name), file("*.FastQ.gz") into ch_clean_reads
        set val(name), file("${name}.json") into ch_item_fastp,
                                                 ch_diagnosis_fastp,
                                                 ch_fastp_summary,
                                                 multiqc_qc_fastp
        file "${name}.html"

        script:
        if (adapter) {
            adapter_arg = params.pe ? "--adapter_sequence ${adapter[0]} --adapter_sequence_r2 ${adapter[1]}" : "--adapter_sequence ${adapter[0]}"
        } else {
            adapter_arg = ""
        }
        inputs  = params.pe ? "--in1 <(zcat *_1.fq.gz) --in2 <(zcat *_2.fq.gz)" : "--in1 <(zcat *.fq.gz)"
        outputs = params.pe ? "--out1 ${name}_1.FastQ.gz --out2 ${name}_2.FastQ.gz" : "--out1 ${name}.FastQ.gz"
        """
        fastp --thread $task.cpus \\
            --trim_poly_g --poly_g_min_len 5 \\
            --trim_poly_x --poly_x_min_len 5 \\
            --cut_tail --qualified_quality_phred 20 \\
            --length_required $params.length_required \\
            --reads_to_process $params.reads_to_process \\
            --stdin $inputs $adapter_arg $outputs \\
            --json ${name}.json \\
            --html ${name}.html
        """
    }
} else {
    process Fastp {
        tag "$name"
        label 'process_medium'
        publishDir "${intermediate}/02.Fastp", mode: 'copy',
            saveAs: { filename ->
                          if (filename.endsWith(".json")) "json/$filename"
                          else if (filename.endsWith(".html")) "html/$filename"
                          else if (filename.endsWith(".FastQ.gz")) "clean_data/$filename"
                          else filename
                    }

        input:
        set val(name), file(reads), val(libprepkit) from ch_raw_reads
                                                         .join(ch_libprepkit, by:[0])

        output:
        set val(name), file("*.FastQ.gz") into ch_clean_reads
        set val(name), file("${name}.json") into ch_item_fastp,
                                                 ch_diagnosis_fastp,
                                                 ch_fastp_summary,
                                                 multiqc_qc_fastp
        file "${name}.html"

        script:
        adapter = params.presets.libprepkit.get(libprepkit) ?: params.presets.libprepkit.get(params.libprepkit) ?: false
        if (adapter) {
            adapter_arg = params.pe ? "--adapter_sequence ${adapter.r1} --adapter_sequence_r2 ${adapter.r2}" : "--adapter_sequence ${adapter.r1}"
        } else {
            adapter_arg = ""
        }
        inputs  = params.pe ? "--in1 ${reads[0]} --in2 ${reads[1]}" : "--in1 ${reads}"
        outputs = params.pe ? "--out1 ${name}_1.FastQ.gz --out2 ${name}_2.FastQ.gz" : "--out1 ${name}.FastQ.gz"
        """
        fastp --thread $task.cpus \\
            --trim_poly_g --poly_g_min_len 5 \\
            --trim_poly_x --poly_x_min_len 5 \\
            --cut_tail --qualified_quality_phred 20 \\
            --length_required $params.length_required \\
            --reads_to_process $params.reads_to_process \\
            $inputs $adapter_arg $outputs \\
            --json ${name}.json \\
            --html ${name}.html
        """
    }
}

// STEP 1-2 - FastQC
//process FastQC {
 //   tag "$name"
  //  label 'process_low'
  //  publishDir "${intermediate}/02.1.FastQC", mode: 'copy',
  //      saveAs: { filename -> filename.indexOf(".zip") > 0 ? "zips/$filename" : "$filename" }

   // when:
   // params.research && !params.skip_fastqc

 //   input:
 //   set val(name), file(reads) from ch_fastqc_raw_reads

  //  output:
   // file "*_fastqc.{zip,html}" into multiqc_fastqc

  //  script:
  //  """
  //  fastqc --quiet --threads $task.cpus *.fq.gz
  //  """
///}






// STEP 2 align Target database
process TargetAlign {
    tag "$name"
    cpus 12
    memory { 32.GB * (0.5 + 0.5 * task.attempt) }
    time   { 2.h * task.attempt }
    publishDir "${intermediate}/03.TargetAlign", mode: 'copy'

    input:
    file index1 from ch_tg_bwa_index.collect()
   // file index2 from ch_tg_bowtie2_index.collect()
    set val(name), file(reads) from ch_clean_reads

    output:
    set val(name), file("${name}.bam") into ch_target_mapped

    script:
    out_bam = "${name}.bam"
    in_reads = params.pe ? "${reads[0]} ${reads[1]}" : "${reads}"
    filter_flags = params.pe ? "-F 0x004 -F 0x0008 -f 0x001" : "-F 0x004"
    if (params.algorithm == 'bwa-mem') {
        """
        bwa mem -t $task.cpus ${index1}/${tg_bwa_base} $in_reads \\
            | samtools view --threads $task.cpus -bS $filter_flags -o ${name}.bam \\
            
        """
    }
  //  else if (params.algorithm == 'bowtie2') {
  //    """
  //      bowtie2  -x ${index2}/${tg_bowtie2_base} \
  //      -1 ${reads[0]} -2 ${reads[1]} \
  //     --un-conc-gz ${name}_%.fq.gz \
  //      2> ${name}.summary \
  //      | samtools view --threads $task.cpus -bS -F 0x004 -F 0x0008 -f 0x001 -o ${name}.bam \
  //    """
  //  }
}

// STEP 3 align Target database
process TargetAlignFilter {
    tag "$name"
    label 'process_low'
    publishDir "${intermediate}/03.TargetAlign", mode: 'copy'
    //publishDir "${results}/$name", mode: "copy", pattern: "*.report.txt"

    input:
    file db from ch_pathogens_db.collect()
    set val(name), file(tmap) from ch_target_mapped

    output:
    set val(name), file("${name}.pass.bam") into ch_pass_mapped
    set val(name), file("${name}.report.tmp") into ch_report
    set val(name), file("${name}.report.xls") into ch_report_xls

    script:
    read_type = params.pe ? "pe" : "se"

        """
        samFilter.py --rt $read_type --in $tmap --out ${name}.pass.bam --threads $task.cpus --lims $params.lims --match $params.match
        bamsort SO=coordinate \\
            I=${name}.pass.bam \\
            O=${name}.sormadup.bam \\
            inputthreads=$task.cpus \\
            outputthreads=$task.cpus \\
            sortthreads=$task.cpus
        samtools depth ${name}.sormadup.bam > depth.tsv
        depthAgg.py --threads $task.cpus --cnpx align --in depth.tsv --out ${name}-pathogens_depth_align
        samtools view ${name}.sormadup.bam |total.reads.pl - > ${name}.total.csv
        sp.tab.pl --db ${db} --reads ${name}.total.csv --depth ${name}-pathogens_depth_align.csv > ${name}.report.tmp
            
        """
        
}

// STEP  summary
process Summary {
    tag "$name"
    label 'process_low'
    publishDir "${intermediate}/04.Summary", mode: 'copy'
    publishDir "${results}/", mode: "copy", pattern: "*.report.txt"
    publishDir "${results}/", mode: "copy", pattern: "*.json"

    input:
    file coe from ch_pathogens_coefficient.collect()
    file fastp_column_config from ch_fastp_column_config.collect()
    file ("fastp_summary/*") from ch_fastp_summary.collect()
    file ("report/*") from ch_report.collect()


    output:
    file("fastp_summary.csv")
    file("tngs.summary.csv")
    file("merge.summary.csv") 
    file("max.summary.csv")
    file("total.summary.csv")
    file("*.report.txt")
    //set val(name), file("${name}.report.txt") into ch_report_final
    file("report.json")

    script:
    """
    fastp_summary.py -c $fastp_column_config \\
        -i ./fastp_summary -o ./

    stats.tngs.pl report fastp_summary.csv > tngs.summary.csv
    summary_filter.pl report fastp_summary.csv  ${coe} > report.json

    """
}
