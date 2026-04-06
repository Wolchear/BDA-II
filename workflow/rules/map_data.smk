from workflow.lib.utils import get_path

TRIMMED_DIR = get_path(config["data"], 'trimmed')
REF_DIR = get_path(config["data"], 'references')
MAPPED_DIR =  get_path(config["output"], "mapped")


DATA_SUFFIX = f"{config['suffix']['fastq']}.{config['suffix']['compressed']}"

rule build_index:
    input:
        f"{REF_DIR}/genome.fa"
    output:
        multiext(f"{REF_DIR}/genome.fa.bwameth.c2t",
            "",
            ".amb",
            ".ann",
            ".bwt",
            ".pac",
            ".sa",
        )
    threads: 1
    log:
        "logs/bwameth/index.log"
    conda:
        "../envs/map_data.yml"
    shell:
        """
        bwameth.py index {input} > {log} 2>&1
        """

rule map_data:
    input:
        fasta_1 = f"{TRIMMED_DIR}/{{acc}}_1.{DATA_SUFFIX}",
        fasta_2 = f"{TRIMMED_DIR}/{{acc}}_2.{DATA_SUFFIX}",
        index = rules.build_index.output,
        ref_genome = f"{REF_DIR}/genome.fa"
    output:
        bam = f"{MAPPED_DIR}/{{acc}}.sorted.bam",
        bai = f"{MAPPED_DIR}/{{acc}}.sorted.bam.bai"
    threads: max(1, config['max_threads'])
    conda:
        "../envs/map_data.yml"
    log:
        f"logs/bwameth/{{acc}}.log"
    shell:
        r"""
        set -euo pipefail

        bwameth.py --reference {input.ref_genome} \
                   {input.fasta_1} \
                   {input.fasta_2} \
                   -t {threads} \
                   2> {log} \
                   | samtools sort -@ {threads} -o {output.bam} 2>> {log}

        samtools index {output.bam} 2>> {log}
        """