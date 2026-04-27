import argparse
import re
from pathlib import Path

import matplotlib.pyplot as plt

STAT_RE = re.compile(r"^No\. of (.+?):\s+(\d+)", re.IGNORECASE)

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Plot mapping rates.")
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

#No. of Reads:                                   406038742$
#No. of Unique Mapped Reads:                     346288912 (85.28%)$
#No. of Ambiguous Mapped Reads:                  17465684 (4.30%)$
#No. of Unmapped Reads:                          42284146 (10.41%)$

def extract_stats(file_name: str) -> dict[str, int]:
    try:
        stat: dict[str, int] = {}
        with open(file_name, 'r') as fh:
            for line in fh:
                m = STAT_RE.match(line.strip())
                if m:
                    stat[m.group(1)] = int(m.group(2))
            return stat
    except Exception as e:
        raise Exception(f"Something goes wrong: {e}")
                 

def plot_barplot(samples: list[str],
                 unique_pct: list[float],
                 ambiguous_pct: list[float],
                 unmapped_pct: list[float],
                 out_file: str
    ) -> None:
    x = range(len(samples))

    plt.bar(x, unique_pct, label="Unique mapped")
    plt.bar(x, ambiguous_pct, bottom=unique_pct, label="Ambiguous mapped")

    bottom2 = [u + a for u, a in zip(unique_pct, ambiguous_pct)]
    plt.bar(x, unmapped_pct, bottom=bottom2, label="Unmapped")

    for i in range(len(samples)):
        plt.text(i, unique_pct[i] / 2,
                f"{unique_pct[i]:.1f}%",
                ha='center', va='center', color='white', fontsize=8)

        plt.text(i, unique_pct[i] + ambiguous_pct[i] / 2,
                f"{ambiguous_pct[i]:.1f}%",
                ha='center', va='center', color='black', fontsize=8)

        plt.text(i, unique_pct[i] + ambiguous_pct[i] + unmapped_pct[i] / 2,
                f"{unmapped_pct[i]:.1f}%",
                ha='center', va='center', color='black', fontsize=8)
    
    plt.xticks(x, samples, rotation=45)
    plt.ylabel("Percentage (%)")
    plt.title("Mapping statistics per sample")

    plt.legend()
    plt.tight_layout()
    plt.savefig(out_file, dpi=300)

def main() -> None:
    args = parse_args()
    stats: dict[str, dict[str, int]] = {}
    for file in args.input:
        sample_id = Path(file).stem
        stats[sample_id] = extract_stats(file)
        
    samples: list[str] = []
    unique_pct: list[float] = []
    ambiguous_pct: list[float] = []
    unmapped_pct: list[float] = []

    for sample, stat in stats.items():
        total = int(stat["Reads"])
        unique = int(stat["Unique Mapped Reads"])
        ambiguous = int(stat["Ambiguous Mapped Reads"])
        unmapped = int(stat["Unmapped Reads"])

        samples.append(sample)

        unique_pct.append(unique / total * 100)
        ambiguous_pct.append(ambiguous / total * 100)
        unmapped_pct.append(unmapped / total * 100)

    plot_barplot(samples, unique_pct, ambiguous_pct, unmapped_pct, args.output)
    
    
    
if __name__ == "__main__":
    main()