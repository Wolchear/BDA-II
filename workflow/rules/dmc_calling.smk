from workflow.lib.utils import get_path

MATRIX_DIR = get_path(config['output'], 'meth_matrix')
DMC_DIR = get_path(config['output'], 'dmc')

SCRIPS = get_path(config['workflow'], 'scripts')

rule get_subset:
    input:
        f"{MATRIX_DIR}/{{matrix_type}}_matrix.bed"
    output:
        f"{MATRIX_DIR}/{{matrix_type}}_subset_matrix.bed"
    params:
        chromosomes = '21 22',
        script = f"{SCRIPS}/dmc/get_meth_subset.py",
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
        f"{DMC_DIR}/dml_test.rds"
    params:
        script = f"{SCRIPS}/dmc/test_dml.r"
    threads: max(1, config['max_threads'] // 2)
    conda:
        "../envs/dmc_calling.yml"
    log:
        f"logs/dmc/test.log"
    shell:
        r"""
        Rscript {params.script} \
            --meth {input.meth} \
            --cov {input.cov} \
            --sample-info {input.sample_info} \
            --output {output} \
            --cov-filter 10 \
            --threads {threads} \
            2> {log}
        """