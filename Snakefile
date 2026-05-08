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

MAP_QC = get_path(config['qc'], "mapping")
MATRIX_DIR = get_path(config['output'], 'meth_matrix')
PCA_DIR = get_path(config['qc'], "pca")
COR_DIR = get_path(config['qc'], "cor")


rule all:
    input:
        expand(
            "{report_dir}/multiqc.html",
            report_dir=[get_path(QC,'raw'), get_path(QC,'trimmed')]
        ),
        expand(
            "{meth_dir}/{acc}_CpG.bedGraph",
            meth_dir=get_path(config['output'], 'meth_call'),
            acc=SRA
        ),
        expand(
            f"{MAP_QC}/{{plot}}.png",
            plot=QC['plots']
        ),
        expand(
            "{plots_dir}/{acc}_cov.png",
            acc=SRA,
            plots_dir=get_path(config['qc'], "cpg_cov")
        ),
        expand(
            "{plots_dir}/pca_{threshold}.png",
            threshold=[1, 5, 15, 20],
            plots_dir = PCA_DIR
        ),
        expand(
            "{plots_dir}/cor_{threshold}.png",
            threshold=[1, 5, 15, 20],
            plots_dir = COR_DIR
        ),
        expand(
             "{_dir}/{acc}_cov.tsv",
             _dir = get_path(config['qc'], "cov_per_sample"),
             acc=SRA
        ),
        f"{get_path(config['output'], 'dmc')}/filterd_BS.rds"

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

module process_mapped_data:
    snakefile: f"{RULES_DIR}/process_mapped_data.smk"
    config: config
use rule * from process_mapped_data

module methylation_call:
    snakefile: f"{RULES_DIR}/methylation_call.smk"
    config: config
use rule * from methylation_call

module mapping_qc:
    snakefile: f"{RULES_DIR}/mapping_qc.smk"
    config: config
use rule * from mapping_qc

module dmc_calling:
    snakefile: f"{RULES_DIR}/dmc_calling.smk"
    config: config
use rule * from dmc_calling
