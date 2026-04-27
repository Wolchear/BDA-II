import csv

from workflow.lib.utils import get_path

with open("config/samples.tsv") as f:
    reader = csv.DictReader(f, delimiter="\t")
    SRA = [row["SRA"] for row in reader]

MAP_QC = get_path(config['qc'], "mapping")
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