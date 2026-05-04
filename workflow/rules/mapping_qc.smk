import csv

from workflow.lib.utils import get_path

with open("config/samples.tsv") as f:
    reader = csv.DictReader(f, delimiter="\t")
    SRA = [row["SRA"] for row in reader]


FLAGSTAT_DIR = get_path(config["qc"], 'bam_stat')
METH_DIR = get_path(config['output'], 'meth_call')
MATRIX_DIR = get_path(config['output'], 'meth_matrix')

MAP_QC = get_path(config['qc'], "mapping")
CPG_COV = get_path(config['qc'], "cpg_cov")

SCRIPS = get_path(config['workflow'], 'scripts')

rule plot_mapping_rates:
    input:
        lambda wc: expand(
            "logs/bitmapper/{acc}.log",
            acc=SRA
        )
    output:
        f"{MAP_QC}/mapping_rates.png"
    threads: 1
    conda:
        f"../envs/mapping_qc.yml"
    params:
        script = f"{SCRIPS}/QC/plot_mapping_stat.py"
    shell:
        """
        python3 {params.script} -i {input} -o {output}
        """

plot_script = {
    'duplicates_rates': "plot_duplicates.py",
    'total_reads': "plot_total_mapped_reads.py"
}

rule plot_stats:
    input:
        expand(f"{FLAGSTAT_DIR}/{{acc}}.tsv", acc=SRA)
    output:
        f"{MAP_QC}/{{plot}}.png"
    threads: 1
    wildcard_constraints:
        plot="|".join(plot_script.keys())
    conda:
        f"../envs/mapping_qc.yml"
    params:
        script = lambda wc: f"{SCRIPS}/QC/{plot_script[wc.plot]}"
    shell:
        """
        python3 {params.script} -i {input} -o {output}
        """

rule plot_cpg_cov:
    input:
        f"{METH_DIR}/{{acc}}_CpG.bedGraph"
    output:
        plot = f"{CPG_COV}/{{acc}}_cov.png",
        tsv = f"{CPG_COV}/{{acc}}_cov.tsv"
    threads: 1
    conda:
        f"../envs/mapping_qc.yml"
    params:
        script = f"{SCRIPS}/QC/plot_methylation_coverage.py"
    shell:
        """
        python3 {params.script} -i {input} -o {output.plot} --tsv {output.tsv} --max-cov 50
        """

rule get_cov_matrix:
    input:
        f"{METH_DIR}/{{acc}}_CpG.bedGraph"
    output:
        f"{MATRIX_DIR}/cov/{{acc}}_CpG.cov.bedGraph"
    threads: 1
    conda:
        f"../envs/mapping_qc.yml"
    shell:
        r"""
        awk 'BEGIN{{OFS="\t"}} NR>1 {{
                cov = $5 + $6
                if (cov > 0) {{
                    print $1, $2, $3, cov
                }}
            }}' {input} > {output}
        """

rule get_meth_matrix:
    input:
        f"{METH_DIR}/{{acc}}_CpG.bedGraph"
    output:
        f"{MATRIX_DIR}/meth/{{acc}}_CpG.meth.bedGraph"
    threads: 1
    conda:
        f"../envs/mapping_qc.yml"
    shell:
        r"""
        awk 'BEGIN{{OFS="\t"}} NR>1 {{
                cov = $5 + $6
                if (cov > 0) {{
                    meth = $5 / cov
                    print $1, $2, $3, meth
                }}
            }}' {input} > {output}
        """

rule merge_matrix:
    input:
        lambda wc: expand(
            f"{MATRIX_DIR}/{{matrix_type}}/{{acc}}_CpG.{{matrix_type}}.bedGraph",
            acc=SRA,
            matrix_type=wc.matrix_type,
        )
    output:
        f"{MATRIX_DIR}/{{matrix_type}}_matrix.bed"
    params:
        names=lambda wc: " ".join(SRA),
        filler=lambda wc: "0" if wc.matrix_type == "cov" else "NA"
    threads: 1
    conda:
        "../envs/mapping_qc.yml"
    log:
        f"logs/matrices/{{matrix_type}}_matrix.log"
    wildcard_constraints:
        matrix_type="cov|meth"
    shell:
        r"""
        bedtools unionbedg \
            -header \
            -names {params.names} \
            -filler {params.filler} \
            -i {input} \
            > {output} 2> {log}
        """
