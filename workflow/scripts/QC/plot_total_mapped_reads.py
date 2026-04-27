import argparse
from pathlib import Path

import matplotlib.pyplot as plt

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Plot duplication rates.")
    parser.add_argument(
        "--input", "-i",
        type=str,
        nargs="+",
        required=True,
        help="Flagstat files"
    )
    
    parser.add_argument(
        "--output", "-o",
        type=str,
        required=True,
        help="Output file name"
    )
    
    return parser.parse_args()

def read_flagstat(file_name: str) -> dict[str, int]:
    content: dict[str, int] = {}

    with open(file_name, "r") as fh:
        for line in fh:
            blocks = line.strip().split("\t")

            if blocks[-1].endswith("%"):
                continue

            metric = blocks[2]
            qc_passed = int(blocks[0])

            content[metric] = qc_passed

    return content

def plot_barplot(samples: list[str],
                 totals: list[int],
                 out_file: str) -> None:

    x = range(len(samples))
    totals_m = [t / 1e6 for t in totals]

    plt.figure(figsize=(8, 5))

    plt.bar(x, totals_m)

    for i in range(len(samples)):
        plt.text(i, totals_m[i],
                 f"{totals_m[i]:.1f}M",
                 ha='center', va='bottom', fontsize=8)

    plt.xticks(x, samples, rotation=45, ha="right")
    plt.ylabel("Reads (millions)")
    plt.title("Total mapped reads per sample")

    plt.tight_layout()
    plt.savefig(out_file, dpi=300)


def main() -> None:
    args =  parse_args()
    
    stats: dict[str, dict[str, int]] = {}
    for file in args.input:
        sample_id = Path(file).stem
        stats[sample_id] = read_flagstat(file)
    
    
    samples: list[str] = []
    totals: list[int] = []

    for sample, stat in stats.items():
        total = int(stat["total (QC-passed reads + QC-failed reads)"])

        samples.append(sample)

        totals.append(total)
    
    plot_barplot(samples, totals, args.output)
        
if __name__ == '__main__':
    main()