from workflow.lib.utils import get_path

TRIMMED_DIR = get_path(config["data"], 'trimmed')
REF_DIR = get_path(config["data"], 'references')
MAPPED_DIR =  get_path(config["output"], "mapped")


DATA_SUFFIX = f"{config['suffix']['fastq']}.{config['suffix']['compressed']}"

rule build_index:
    input:
        f"{REF_DIR}/genome.fa"
    output:
        multiext(f"{REF_DIR}/genome.fa.index.bs",
            ".index",
            ".index.bwt",
            ".index.occ",
            ".index.sa",
            ".pac"
        ),
        multiext(f"{REF_DIR}/genome.fa",
            ".index",
            ".index.methy",
        )
    threads: 1
    log:
        "logs/bitmapper/index.log"
    conda:
        "../envs/map_data.yml"
    shell:
        """
        bitmapperBS --index {input} > {log} 2>&1
        """

rule map_data:
    input:
        fasta_1 = f"{TRIMMED_DIR}/{{acc}}_1.{DATA_SUFFIX}",
        fasta_2 = f"{TRIMMED_DIR}/{{acc}}_2.{DATA_SUFFIX}",
        index = rules.build_index.output,
        ref_genome = f"{REF_DIR}/genome.fa"
    output:
        bam = temp(f"{MAPPED_DIR}/{{acc}}.unsorted.bam")
    threads: max(1, config['max_threads'])
    resources:
        mapping_slot=1,
        memory_slot=1
    conda:
        "../envs/map_data.yml"
    log:
        f"logs/bitmapper/{{acc}}.log"
    shell:
        r"""
        bitmapperBS --search {input.ref_genome} \
            --seq1 {input.fasta_1} \
            --seq2 {input.fasta_2} \
            --bam -o {output.bam} \
            --sensitive \
            -t {threads} > {log} 2>&1
        """


