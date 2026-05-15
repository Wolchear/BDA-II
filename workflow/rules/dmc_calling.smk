from workflow.lib.utils import get_path

MATRIX_DIR = get_path(config['output'], 'meth_matrix')
DMC_DIR = get_path(config['output'], 'dmc')

SCRIPTS = get_path(config['workflow'], 'scripts')

P_THRESHOLDS = {
    '000001': 0.00001,
    '00001': 0.0001,
    '0001': 0.001,
    '001': 0.01,
    '005': 0.05
}

DELTA_THRESHOLDS = {
    '0': 0,
    '01': 0.1,
    '02': 0.2
}


rule get_subset:
    input:
        f"{MATRIX_DIR}/{{matrix_type}}_matrix.bed"
    output:
        f"{MATRIX_DIR}/{{matrix_type}}_subset_matrix.bed"
    params:
        chromosomes = '21 22',
        script = f"{SCRIPTS}/dmc/get_meth_subset.py",
    threads: 1
    conda:
        "../envs/dmc_calling.yml"
    log:
        f"logs/matrices/{{matrix_type}}_subset_matrix.log"
    wildcard_constraints:
        matrix_type="cov|meth"
    shell:
        r"""
        python3 {params.script} -i {input} \
            --chromosomes {params.chromosomes} \
            > {output} \
            2> {log}
        """

rule get_bs:
    input:
        meth = f"{MATRIX_DIR}/meth_subset_matrix.bed",
        cov = f"{MATRIX_DIR}/cov_subset_matrix.bed",
        sample_info = "config/samples.tsv"
    output:
        f"{DMC_DIR}/filtered_BS.rds"
    params:
        script = f"{SCRIPTS}/dmc/prepare_bs.r"
    threads: 1
    conda:
        "../envs/dmc_calling.yml"
    log:
        f"logs/dmc/bs_filter.log"
    shell:
        r"""
        Rscript {params.script} \
            --meth {input.meth} \
            --cov {input.cov} \
            --sample-info {input.sample_info} \
            --output {output} \
            --cov-filter 10 \
            2> {log}
        """


rule test_dml:
    input:
        bs = rules.get_bs.output,
        sample_info = "config/samples.tsv"
    output:
        f"{DMC_DIR}/dml_test.rds"
    params:
        script = f"{SCRIPTS}/dmc/test_dml.r"
    threads: max(1, config['max_threads'] // 2)
    conda:
        "../envs/dmc_calling.yml"
    log:
        f"logs/dmc/test.log"
    shell:
        r"""
        Rscript {params.script} \
            --bs {input.bs} \
            --sample-info {input.sample_info} \
            --output {output} \
            --threads {threads} \
            2> {log}
        """

rule call_dss_dmc:
    input:
        dml = f"{DMC_DIR}/dml_test.rds"
    output:
        dmcs = f"{DMC_DIR}/dss/dmcs_p{{p}}_d{{delta}}.rds",
        table = f"{DMC_DIR}/dss/dmcs_p{{p}}_d{{delta}}.tsv"
    threads: 1
    log:
        f"logs/dmc/calling/dss/dmcs_p{{p}}_d{{delta}}.log"
    conda:
        "../envs/dmc_calling.yml"        
    params:
        p_value = lambda wc: P_THRESHOLDS[wc.p],
        delta = lambda wc: DELTA_THRESHOLDS[wc.delta],
        script = f"{SCRIPTS}/dmc/call_dmc.r"
    shell:
        r"""
        Rscript {params.script} \
            --dml {input.dml} \
            -p {params.p_value} \
            --delta {params.delta} \
            --output {output.dmcs} \
            --summary {output.table} \
            > {log} 2>&1
        """