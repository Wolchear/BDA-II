import argparse
import re
from pathlib import Path

import matplotlib.pyplot as plt

STAT_RE = re.compile(r"^No\. of (.+?):\s+(\d+)", re.IGNORECASE)

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
                 duplicates: list[float],
                 out_file: str
    ) -> None:
    x = range(len(samples))

    plt.bar(x, duplicates)

    for i in range(len(samples)):
        plt.text(i, duplicates[i] / 2,
                f"{duplicates[i]:.1f}%",
                ha='center', va='center', color='white', fontsize=8)
    
    plt.xticks(x, samples, rotation=45)
    plt.ylabel("Percentage (%)")
    plt.title("Duplicates statistics per sample")

    plt.legend()
    plt.tight_layout()
    plt.savefig(out_file, dpi=300)


def main() -> None:
    args =  parse_args()
    
    stats: dict[str, dict[str, int]] = {}
    for file in args.input:
        sample_id = Path(file).stem
        stats[sample_id] = read_flagstat(file)
    
    
    samples: list[str] = []
    duplicates: list[float] = []

    for sample, stat in stats.items():
        total = int(stat["total (QC-passed reads + QC-failed reads)"])
        duplicate = int(stat["duplicates"])

        samples.append(sample)

        duplicates.append(duplicate / total * 100)
    
    plot_barplot(samples, duplicates, args.output)
        
if __name__ == '__main__':
    main()