from workflow.lib.utils import get_path

REF_DIR = get_path(config["data"], 'references')
MAPPED_DIR =  get_path(config["output"], "mapped")
METH_DIR = get_path(config['output'], 'meth_call')

MBIAS_DIR = get_path(config["qc"], 'mbias')

rule mbias:
    input:
        bam = f"{MAPPED_DIR}/{{acc}}.sorted.deduplicated.bam",
        bai = f"{MAPPED_DIR}/{{acc}}.sorted.deduplicated.bam.bai",
        ref_genome = f"{REF_DIR}/genome.fa"
    output:
        ob_plot = f"{MBIAS_DIR}/{{acc}}_OB.svg",
        ot_plot = f"{MBIAS_DIR}/{{acc}}_OT.svg"
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
            {params.prefix} 2> {log}
        """

rule extract:
    input:
        ot_plot = f"{MBIAS_DIR}/{{acc}}_OT.svg",
        ob_plot = f"{MBIAS_DIR}/{{acc}}_OB.svg",
        bam = f"{MAPPED_DIR}/{{acc}}.sorted.deduplicated.bam",
        bai = f"{MAPPED_DIR}/{{acc}}.sorted.deduplicated.bam.bai",
        ref_genome = f"{REF_DIR}/genome.fa"
    output:
        cpg = f"{METH_DIR}/{{acc}}_CpG.bedGraph"
    log:
        f"logs/MethylDackel/extract/{{acc}}.log"
    params:
        prefix = lambda wc: f"{METH_DIR}/{wc.acc}"
    threads: max(1, config["max_threads"])
    conda:
        "../envs/methylation_call.yml"
    resources:
        memory_slot=1
    shell:
        r"""
        OT=$(grep -oP -- '--OT \K[0-9,]+' {input.ot_plot} | head -n1)
        OB=$(grep -oP -- '--OB \K[0-9,]+' {input.ob_plot} | head -n1)

        echo "OT=$OT" > {log}
        echo "OB=$OB" >> {log}

        test -n "$OT"
        test -n "$OB"

        MethylDackel extract -@ {threads} \
            -o {params.prefix} \
            --OT "$OT" \
            --OB "$OB" \
            {input.ref_genome} \
            {input.bam} \
            >> {log} 2>&1
        """