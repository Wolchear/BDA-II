import csv

from workflow.lib.utils import get_path

with open("config/samples.tsv") as f:
    reader = csv.DictReader(f, delimiter="\t")
    SRA = [row["SRA"] for row in reader]

MAP_QC = get_path(config['qc'], "mapping")
SCRIPS = get_path(config['workflow'], 'scripts')
FLAGSTAT_DIR = get_path(config["qc"], 'bam_stat')



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