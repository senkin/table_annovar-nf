#!/usr/bin/env nextflow

params.help = null
params.output_folder = "."
params.table_extension = "tsv"
params.cpu = 1
params.annovar_db = "Annovar_db/"
params.mem    = 4
params.buildver = "hg38"
params.annovar_params = "--codingarg -includesnp -intronhgvs 20 -protocol refGene,ensGene,exac03nontcga,esp6500siv2_all,1000g2015aug_all,gnomad211_genome,gnomad211_exome,clinvar_20190305,revel,dbnsfp35a,dbnsfp31a_interpro,intervar_20180118,cosmic84_coding,cosmic84_noncoding,avsnp150,phastConsElements100way,wgRna -operation g,g,f,f,f,f,f,f,f,f,f,f,f,f,f,r,r -otherinfo "
// vep parameters
params.cache_dir = "$baseDir/cache_dir/"
params.cache_version = '112'
params.fasta = "$baseDir/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz"
params.plugin = "SpliceAI,snv=$baseDir/spliceai_scores/spliceai_scores.raw.snv.hg38.vcf.gz,indel=$baseDir/spliceai_scores/spliceai_scores.raw.indel.hg38.vcf.gz"
params.filter_functional = true
params.filter_genes_of_interest = true
params.genes_of_interest = "ABCB11|ALK|APC|ATM|ATR|AXIN2|BAP1|BLM|BMPR1A|BRAF|BRCA1|BRCA2|BRIP1|BUB1B|CBL|CDC73|CDH1|CDK4|CDKN1B|CDKN1C|CDKN2A|CEBPA|CHEK2|COL7A1|CTR9|CYLD|DDB2|DICER1|DIS3L2|DKC1|DOCK8|DROSHA|EGFR|ELANE|EPCAM|ERCC1|ERCC2|ERCC3|ERCC4|ERCC5|ETV6|EXT1|EXT2|FAH|FANCA|FANCC|FANCD2|FANCE|FANCF|FANCG|FANCI|FANCL|FANCM|FH|FLCN|GATA2|GBA|GJB2|GPC3|HFE|HMBS|HNF1A|HRAS|ITK|JMJD1C|KIT|KRAS|LMO1|MAP2K1|MAP2K2|MAX|MEN1|MET|MITF|MLH1|MPL|MSH2|MSH6|MTAP|MUTYH|NBN|NF1|NF2|NHP2|NOP10|NRAS|NTHL1|PALB2|PAX5|PDGFRA|PHOX2B|PMS2|POLD1|POLE|POLH|POT1|PRDM9|PRF1|PRKAR1A|PRSS1|PTCH1|PTEN|PTPN11|RAD51C|RAD51D|RAF1|RB1|RECQL4|RET|RHBDF2|RMRP|RUNX1|SBDS|SDHA|SDHAF2|SDHB|SDHC|SDHD|SERPINA1|SETBP1|SH2B3|SH2D1A|SHOC2|SLC25A13|SMAD4|SMARCA4|SMARCB1|SMARCE1|SOS1|SPRTN|SRY|STAT3|STK11|SUFU|TERT|TGFBR1|TMEM127|TNFRSF6|TP53|TRIM37|TSC1|TSC2|TSHR|UROD|VHL|WAS|WRN|WT1|XPA|XPC|BARD1|CTNNA1|CEP57|DDX41|FANCB|GREM1|RNF43|SLX4|MLH3|MSH3|ANKRD26|CDKN2B|HOXB13|KIF1B|LZTR1|MBD4|REST|RSPO1|RTEL1|SQSTM1|SRP72|TERC|APOBEC3B|ASPM|CDH10|FADD|FAT1|FEN1|HGF|KDR|MUC6|POLQ|PTPN13|RAD50|RFWD3|SPOP|TGFBR2|TP63|USP9X"

if (params.help) {
    log.info ''
    log.info '--------------------------------------------------------------'
    log.info 'table_annovar-nf 1.1.1: Nextflow pipeline to run TABLE ANNOVAR'
    log.info '--------------------------------------------------------------'
    log.info ''
    log.info 'Usage: '
    log.info 'nextflow run table_annovar.nf --table_folder myinputfolder'
    log.info ''
    log.info 'Mandatory arguments:'
    log.info '    --table_folder       FOLDER            Folder containing tables to process.'
    log.info 'Optional arguments:'
    log.info '    --cpu                INTEGER           Number of cpu used by annovar (default: 1).'
    log.info '    --mem                INTEGER           Size of memory (in GB) (default: 4).'
    log.info '    --output_folder      FOLDER		 Folder where output is written.'
    log.info '    --table_extension    STRING		 Extension of input tables (default: tsv).'
    log.info '    --annovar_db         FOLDER  	  	 Folder with annovar databases (default: Annovar_db)'
    log.info '    --buildver 	       STRING		 Version of genome build (default: hg38)'
    log.info '    --annovar_params     STRING		 Parameters given to table_annovar.pl (default: multiple databases--see README)'
    log.info ''
    exit 0
}

log.info "table_folder=${params.table_folder}"

process Annovar {
  // publishDir params.output_folder, mode: 'copy' //, pattern: '{*.vcf}'
  cpus params.cpu
  memory params.mem+'G'
  tag { file_name }

  input:
  path table
  path annodb

  output:
  path "Full_annotation_${file_name}.txt", emit: annotated_table
  path "${file_name}.${params.buildver}_multianno.vcf", emit: annotated_vcf

  shell:
  if(params.table_extension=="vcf"|params.table_extension=="vcf.gz"){
	vcf="--vcfinput -nastring ."
  }else{
	 vcf="-nastring NA "
  }
  file_name = table.baseName
  '''
  bcftools view -i "FILTER='PASS' && FORMAT/GQ >= 50" !{table} > filtered_!{file_name}
  table_annovar.pl -buildver !{params.buildver} --thread !{params.cpu} --onetranscript !{vcf} !{params.annovar_params} filtered_!{file_name} !{annodb} -out !{file_name}
  cat !{file_name}*_multianno.txt | awk '{print "'!{file_name}'\\t" \$0}' \\
        | sed -e '1s/!{file_name}/SAMPLE/' \\
        >> Full_annotation_!{file_name}.txt
  '''
}

process FilterFunctional {
  // publishDir params.output_folder, mode: 'copy', pattern: '{*.txt}'
  memory '64 GB' // adjust
  cpus params.cpu
  tag { file_name }

  input:
  path table

  output:
  path "Filtered_annotation_${table}"

  shell:
  file_name = table.baseName

  script:
  """
  #!/usr/bin/env python
  import pandas as pd
  import os
  if os.path.getsize("${table}") > 0:
    full_annotation = pd.read_csv("${table}", sep='\t')
    # apply filters on Func.ensGene (splicing or exonic)
    full_annotation = full_annotation[(full_annotation['Func.ensGene']=='splicing') | (full_annotation['Func.ensGene']=='exonic;splicing') | (full_annotation['Func.ensGene']=='exonic')]
    # apply filtering restricting to the genes of interest:
    if '${params.filter_genes_of_interest}' == 'true':
      print('Filtering on the following genes of interest: ', '${params.genes_of_interest}')
      full_annotation = full_annotation[full_annotation['Gene.ensGene'].str.contains('${params.genes_of_interest}')]
    # apply functional filters on ExonicFunc.ensGene
    # full_annotation = full_annotation[(full_annotation['ExonicFunc.ensGene']=='nonsynonymous SNV') | (full_annotation['ExonicFunc.ensGene']=='stopgain') | (full_annotation['ExonicFunc.ensGene']=='startloss') | (full_annotation['ExonicFunc.ensGene']=='nonframeshift deletion') | (full_annotation['ExonicFunc.ensGene']=='nonframeshift insertion') | (full_annotation['ExonicFunc.ensGene']=='frameshift deletion') | (full_annotation['ExonicFunc.ensGene']=='frameshift insertion')]
    # apply filters on clinvar significance (excluding benign/likely benign)
    full_annotation = full_annotation[(full_annotation['CLNSIG']!='Benign') & (full_annotation['CLNSIG']!='Likely_benign')  & (full_annotation['CLNSIG']!='Benign/Likely_benign') ]
    full_annotation.reset_index(inplace=True)
    full_annotation.drop(['index'], axis=1, inplace=True)
    full_annotation.to_csv('Filtered_annotation_${table}',sep='\t')
  else:
    from pathlib import Path
    Path('Filtered_annotation_${table}').touch()
  """
}

process VepOnSplicing {
  cpus params.cpu
  memory params.mem+'G'
  tag { file_name }

  input:
  path vcf_file

  output:
  path "Full_vep_annotation_${file_name}.txt"

  shell:
  file_name = vcf_file.simpleName
  '''
  # filter for genes of interest

  if !{params.filter_genes_of_interest} ;
  then
    echo "Filtering on genes: !{params.genes_of_interest}"
    grep -E "^#|!{params.genes_of_interest}" !{vcf_file} > filtered_!{file_name}.vcf 
    mv filtered_!{file_name}.vcf !{vcf_file}
  fi

  # filter for splicing variants
  grep -E "^#|splicing" !{vcf_file} > filtered_splicing_!{file_name}.vcf
  
  # run VEP with SpliceAI plugin
  vep -i filtered_splicing_!{file_name}.vcf -o !{file_name} --hgvs \\
        --fasta !{params.fasta} --offline --mane_select --tab \\
        --cache --cache_version !{params.cache_version} --dir_cache !{params.cache_dir}/ \\
        --plugin !{params.plugin}

  # Keep the header at the top
  grep '^##' !{file_name} > Full_vep_annotation_!{file_name}.txt
  # Add the sample name as the first column  
  sed '/^##/d' !{file_name} | awk '{print "'!{file_name}'\\t" \$0}' \\
        | sed -e '1s/!{file_name}/SAMPLE/' \\
        >> Full_vep_annotation_!{file_name}.txt
  '''
}

workflow {
    // Grab input files
    tables = Channel.fromPath( params.table_folder+'/*.'+params.table_extension)
                 .ifEmpty { error "empty table folder, please verify your input." }
    // Launch the pipeline and merge inputs in a single file
    Annovar(tables, params.annovar_db)

    if ( params.filter_functional ) {
      FilterFunctional(Annovar.out.annotated_table).collectFile(name: 'filtered_annotation.txt', \
            newLine: false, \
            keepHeader: true, \
            skip: 1, \
            sort: { file -> file.baseName }, \
            storeDir: params.output_folder)
    }
    else {
      Annovar.out.annotated_table.collectFile(name: 'full_annotation.txt', \
            newLine: false, \
            keepHeader: true, \
            skip: 1, \
            sort: { file -> file.baseName }, \
            storeDir: params.output_folder)
    }

    VepOnSplicing(Annovar.out.annotated_vcf).collectFile(name: 'Vep_SpliceAI_annotation.txt', \
            newLine: false, \
            keepHeader: true, \
            skip: 46, \
            sort: { file -> file.baseName }, \
            storeDir: params.output_folder)

    // need to merge
}
