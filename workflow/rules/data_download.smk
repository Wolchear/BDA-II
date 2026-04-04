from workflow.lib.utils import get_path

RAW_DIR = get_path(config["data"], 'raw')
REF_DIR = get_path(config["data"], 'references')

FASTQ_SUFFIX = config['suffix']['fastq']
GZIPPED_SUFFIX = config['suffix']['compressed']

REF_GEN_CONF = config["ref"]['genome']

rule get_data:
    output:
        fastq_1 = f"{RAW_DIR}/{{acc}}_1.{FASTQ_SUFFIX}.{GZIPPED_SUFFIX}",
        fastq_2 = f"{RAW_DIR}/{{acc}}_2.{FASTQ_SUFFIX}.{GZIPPED_SUFFIX}"
    threads: 1
    params:
        outdir=RAW_DIR,
        fastq_suffix=FASTQ_SUFFIX
    log:
        "logs/fasterq_dump/{acc}.log"
    conda:
        f"../envs/data_download.yml"
    shell:
        r"""
        echo "Downloading files for: {wildcards.acc}" >&2

        fastq-dump {wildcards.acc} \
            -O {params.outdir} \
            --split-files \
            -X 500000 \
            --gzip \
            > {log} 2>&1
        """


rule get_genome:
    output:
        genome = f"{REF_DIR}/genome.fa.gz"
    params:
        link=REF_GEN_CONF['link']
    threads: 1
    log:
        f"logs/ref/{REF_GEN_CONF['file_name']}.log"
    shell:
        """
        wget -c -O {output.genome} {params.link} > {log} 2>&1
        """