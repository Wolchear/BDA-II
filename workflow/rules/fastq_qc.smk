import csv

from workflow.lib.utils import get_path

with open("config/samples.tsv") as f:
    reader = csv.DictReader(f, delimiter="\t")
    SRA = [row["SRA"] for row in reader]

RAW_DIR = get_path(config["data"], 'raw')
TRIMMED_DIR = get_path(config["data"], 'trimmed')

RAW_REPORTS_DIR = get_path(config['qc'], 'raw') 
TRIMMED_REPORTS_DIR = get_path(config['qc'], 'trimmed')

DATA_SUFFIX = f"{config['suffix']['fastq']}.{config['suffix']['compressed']}"

DIR_MAP = {
    RAW_REPORTS_DIR: RAW_DIR,
    TRIMMED_REPORTS_DIR: TRIMMED_DIR
}

DIR_LOG = {
    RAW_REPORTS_DIR: 'raw',
    TRIMMED_REPORTS_DIR: 'trimmed'
}


rule trim:
    input:
        r1=f"{RAW_DIR}/{{acc}}_1.{DATA_SUFFIX}",
        r2=f"{RAW_DIR}/{{acc}}_2.{DATA_SUFFIX}",
        fastq1 = f"{RAW_REPORTS_DIR}/{{acc}}_1_fastqc.html",   # DAG hardlock
        fastq2 = f"{RAW_REPORTS_DIR}/{{acc}}_2_fastqc.html"
    output:
        r1=temp(f"{TRIMMED_DIR}/{{acc}}_1.{DATA_SUFFIX}"),
        r2=temp(f"{TRIMMED_DIR}/{{acc}}_2.{DATA_SUFFIX}")
    threads: max(1, config['max_threads'] // 2)
    log:
        "logs/trim_galore/{acc}.log"
    conda:
        f"../envs/fastq_qc.yml"
    params:
        outdir=TRIMMED_DIR
    resources:
        trim_job=1,
        memory_slot=1
    shell:
       r"""
        trim_galore \
            --paired \
            --gzip \
            -o {params.outdir} \
            --cores {threads} \
            {input.r1} {input.r2} \
            > {log} 2>&1
        
        mv {params.outdir}/{wildcards.acc}_1_val_1.fq.gz {output.r1}
        mv {params.outdir}/{wildcards.acc}_2_val_2.fq.gz {output.r2}
        """

rule fastqc:
    input:
        lambda wc: f"{DIR_MAP[wc.out_dir]}/{wc.acc}.{DATA_SUFFIX}"
    output:
        html="{out_dir}/{acc}_fastqc.html",
        zip="{out_dir}/{acc}_fastqc.zip"
    log:
        "logs/fastqc/{out_dir}/{acc}.log"
    params:
        outdir=lambda wc: wc.out_dir
    wildcard_constraints:
        out_dir=f"{RAW_REPORTS_DIR}|{TRIMMED_REPORTS_DIR}"
    threads: max(1, config["max_threads"] // 3)
    conda:
        "../envs/fastq_qc.yml"
    shell:
        """
        fastqc -t {threads} -o {params.outdir} {input} > {log} 2>&1
        """

rule multiqc:
    input:
        lambda wc: expand(
            "{input_dir}/{acc}_{paired_id}_fastqc.zip",
            acc=SRA,
            paired_id=["1", "2"],
            input_dir=wc.input_dir
        )
    output:
        f"{{input_dir}}/multiqc.html"
    threads: 1
    wildcard_constraints:
        input_dir=f"{RAW_REPORTS_DIR}|{TRIMMED_REPORTS_DIR}"
    params:
        outdir=lambda wc: wc.input_dir
    resources:
        multiqc_slot=1
    shell:
        r"""
        multiqc {params.outdir} \
          -o {params.outdir} \
          -n multiqc.html \
          -f
        """