import pandas as pd
from snakemake.utils import min_version
min_version("6.0")

from workflow.lib.utils import get_path

configfile: "config/config.yaml"

SUFFIX = config["suffix"]
DATA = config['data']
OUTPUT = config['output']
QC = config['qc']

samples = pd.read_table("config/samples.tsv").set_index('SRA')
SRA = samples.index.tolist()

rule all:
    input:
        expand(
            "{report_dir}/multiqc.html",
            report_dir=[get_path(QC,'raw'), get_path(QC,'trimmed')]
        ),
        expand(
            "{mapped_dir}/{acc}.sorted.bam",
            mapped_dir=get_path(OUTPUT, "mapped"),
            acc=SRA
        )

RULES_DIR = get_path(config['workflow'], "rules")

module raw_data:
    snakefile: f"{RULES_DIR}/data_download.smk"
    config: config
use rule * from raw_data

module fastq_qc:
    snakefile: f"{RULES_DIR}/fastq_qc.smk"
    config: config
use rule * from fastq_qc

module map_data:
    snakefile: f"{RULES_DIR}/map_data.smk"
    config: config
use rule * from map_data