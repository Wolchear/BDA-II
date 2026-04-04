import pandas as pd
from snakemake.utils import min_version
min_version("6.0")

from workflow.lib.utils import get_path

configfile: "config/config.yaml"

SUFFIX = config["suffix"]
DATA = config['data']
QC = config['qc']

samples = pd.read_table("config/samples.tsv").set_index('SRA')
SRA = samples.index.tolist()

rule all:
    input:
        expand(
            "{data_dir}/{acc}_{paired}.{suffix}",
            data_dir=get_path(DATA, "raw"),
            acc=SRA,
            paired=[1, 2],
            suffix=f'{SUFFIX["fastq"]}.{SUFFIX["compressed"]}'
        ),
        expand(
            "{report_dir}/multiqc.html",
            report_dir=[get_path(QC,'raw'), get_path(QC,'trimmed')]
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