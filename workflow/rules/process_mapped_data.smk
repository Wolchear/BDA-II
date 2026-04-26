from workflow.lib.utils import get_path

REF_DIR = get_path(config["data"], 'references')
MAPPED_DIR =  get_path(config["output"], "mapped")

FLAGSTAT_DIR = get_path(config["qc"], 'bam_stat')

rule sort:
    input:
        unsorted_bam = f"{MAPPED_DIR}/{{acc}}.unsorted.bam"
    output:
        cord_sorted_bam = temp(f"{MAPPED_DIR}/{{acc}}.sorted.bam")
    threads: max(1, config['max_threads'])
    resources:
        memory_slot=1
    conda:
        "../envs/process_mapped_data.yml"
    log:
        f"logs/samtools/sort/{{acc}}.log"
    params:
        acc = lambda wc: wc.acc
    shell:
        r"""
        (
            samtools addreplacerg \
                -r ID:{params.acc} \
                -r SM:{params.acc} \
                -r PL:ILLUMINA \
                -o - \
                {input.unsorted_bam} \
            | samtools sort -@ {threads} \
                -m 1536M \
                -o {output.cord_sorted_bam} \
                -
        ) > {log} 2>&1
        """

rule deduplicate:
    input:
        cord_sorted_bam = rules.sort.output.cord_sorted_bam,
        ref_genome = f"{REF_DIR}/genome.fa"
    output:
        deduplicated_bam = f"{MAPPED_DIR}/{{acc}}.sorted.deduplicated.bam"
    threads: 1
    resources:
        memory_slot=1,
        mem_mb=12000
    conda:
        "../envs/process_mapped_data.yml"
    log:
        f"logs/deduplication/{{acc}}.log"
    params:
        repot_file = lambda wc: f"{MAPPED_DIR}/{wc.acc}_deduplication.txt",
        java_heap_mb=lambda wc, resources: int(resources.mem_mb * 0.85)
    shell:
        r"""
        export JAVA_TOOL_OPTIONS="-Xmx{params.java_heap_mb}m"

        picard MarkDuplicates \
            I={input.cord_sorted_bam} \
            O={output.deduplicated_bam} \
            M={params.repot_file} \
            > {log} 2>&1
        """

rule index:
    input:
        deduplicated_bam = rules.deduplicate.output.deduplicated_bam
    output:
        f"{MAPPED_DIR}/{{acc}}.sorted.deduplicated.bam.bai"
    threads: 1
    conda:
        "../envs/process_mapped_data.yml"
    log:
        f"logs/samtools/index/{{acc}}.log"
    shell:
        r"""
        samtools index {input.deduplicated_bam} > {log} 2>&1
        """

rule flagstat:
    input:
        deduplicated_bam = rules.deduplicate.output.deduplicated_bam
    output:
        f"{FLAGSTAT_DIR}/{{acc}}.tsv"
    threads: max(1, config["max_threads"] // 2)
    conda:
        "../envs/process_mapped_data.yml"
    log:
        f"logs/samtools/flagstat/{{acc}}.log"
    shell:
        r"""
        samtools flagstat -@ {threads} \
            -O tsv \
            {input.deduplicated_bam} \
            > {output} 2> {log}
        """