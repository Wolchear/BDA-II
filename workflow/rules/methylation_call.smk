from workflow.lib.utils import get_path

REF_DIR = get_path(config["data"], 'references')
MAPPED_DIR =  get_path(config["output"], "mapped")
METH_DIR = get_path(config['output'], 'meth_call')

MBIAS_DIR = get_path(config["qc"], 'mbias')

rule mbias:
    input:
        bam = f"{MAPPED_DIR}/{{acc}}.sorted.bam",
        bai = f"{MAPPED_DIR}/{{acc}}.sorted.bam.bai",
        ref_genome = f"{REF_DIR}/genome.fa"
    output:
        ob_plot = f"{MBIAS_DIR}/{{acc}}_plot_OB.svg",
        ot_plot = f"{MBIAS_DIR}/{{acc}}_plot_OT.svg",
        mbias_borders = f"{MBIAS_DIR}/{{acc}}_mbias_borders.txt"
    threads: max(1, config['max_threads'])
    log:
        f"logs/MethylDackel/mbias/{{acc}}.log"
    params:
        prefix = lambda wc: f"{MBIAS_DIR}/{wc.acc}"
    resources:
        memory_slot=1
    conda:
        "../envs/methylation_call.yml"
    shell:
        r"""
        MethylDackel mbias -@ {threads} \
            {input.ref_genome} \
            {input.bam} \
            {params.prefix} > {output.mbias_borders} 2> {log}
        """

rule extract:
    input:
        mbias_borders = rules.mbias.output.mbias_borders,
        bam = f"{MAPPED_DIR}/{{acc}}.sorted.bam",
        bai = f"{MAPPED_DIR}/{{acc}}.sorted.bam.bai",
        ref_genome = f"{REF_DIR}/genome.fa"
    output:
        f"{METH_DIR}/{{acc}}_CpG.bedGraph",
    threads: max(1, config['max_threads'])
    log:
        f"logs/MethylDackel/extract/{{acc}}.log"
    params:
        prefix=lambda wc: f"{METH_DIR}/{wc.acc}"
    resources:
        memory_slot=1
    conda:
        "../envs/methylation_call.yml"
    shell:
        r"""
        OT=$(grep -oP '(?<=--OT )[^ ]+' {input.mbias_borders})
        OB=$(grep -oP '(?<=--OB )[^ ]+' {input.mbias_borders})

        MethylDackel extract -@ {threads} \
            -o {params.prefix} \
            --OT "$OT" \
            --OB "$OB" \
            {input.ref_genome} \
            {input.bam} \
            > {log} 2>&1
        """