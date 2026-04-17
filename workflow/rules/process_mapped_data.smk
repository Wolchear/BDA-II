from workflow.lib.utils import get_path

REF_DIR = get_path(config["data"], 'references')
MAPPED_DIR =  get_path(config["output"], "mapped")

rule sort_name:
    input:
        unsorted_bam = f"{MAPPED_DIR}/{{acc}}.unsorted.bam"
    output:
        bam = temp(f"{MAPPED_DIR}/{{acc}}.sorted.names.bam")
    threads: max(1, config['max_threads'])
    resources:
        memory_slot=1
    conda:
        "../envs/process_mapped_data.yml"
    log:
        f"logs/sort/{{acc}}.log"
    shell:
        r"""
        samtools sort -n -@ {threads} \
            -m 1536M \
            -o {output.bam} \
            {input.unsorted_bam} > {log} 2>&1
        """

rule deduplicate:
    input:
        name_sorted_bam = rules.sort_name.output.bam
    output:
        deduplicated_bam = temp(f"{MAPPED_DIR}/{{acc}}.deduplicated.bam")
    threads: 1
    resources:
        memory_slot=1
    conda:
        "../envs/process_mapped_data.yml"
    log:
        f"logs/deduplication/{{acc}}.log"
    params:
        repot_file = lambda wc: f"{MAPPED_DIR}/dupsifter/{{acc}}.txt"
    shell:
        r"""
        dupsifter -r \
            -v \
            -o {output.deduplicated_bam} \
            -O {params.repot_file} \
            {input.name_sorted_bam} > {log} 2>&1
        """

rule sort_by_cords:
    input:
        deduplicated_bam = rules.deduplicate.output.deduplicated_bam
    output:
        bam = temp(f"{MAPPED_DIR}/{{acc}}.sorted.bam")
    threads: max(1, config['max_threads'])
    resources:
        memory_slot=1
    conda:
        "../envs/process_mapped_data.yml"
    log:
        f"logs/sort/{{acc}}.log"
    shell:
        r"""
        samtools sort -n -@ {threads} \
            -m 1536M \
            -o {output.bam} \
            {input.deduplicated_bam} > {log} 2>&1
        """

rule index:
    input:
        sorted_bam = rules.sort_by_cords.output.bam
    output:
        f"{MAPPED_DIR}/{{acc}}.sorted.bam.bai"
    threads: 1
    conda:
        "../envs/process_mapped_data.yml"
    log:
        f"logs/bam_index/{{acc}}.log"
    shell:
        r"""
        samtools index {input.sorted_bam} > {log} 2>&1
        """