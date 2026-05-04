import argparse
from pathlib import Path
from collections import Counter

import matplotlib.pyplot as plt


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Plot coverage distribution per CpG.")
    parser.add_argument(
        "--input", "-i",
        type=str,
        required=True,
        help="Methylation calling bedGraph file"
    )
    parser.add_argument(
        "--output", "-o",
        type=str,
        required=True,
        help="Output plot file name"
    )
    parser.add_argument(
        "--tsv",
        type=str,
        default=None,
        help="Optional output TSV with coverage distribution"
    )
    parser.add_argument(
        "--max-cov",
        type=int,
        default=100,
        help="Maximum coverage shown on plot"
    )
    return parser.parse_args()


def read_coverage_distribution(file_name: str) -> Counter[int]:
    hist: Counter[int] = Counter()

    with open(file_name, "r") as fh:
        _ = fh.readline()  # skip header

        for line in fh:
            blocks = line.rstrip("\n").split("\t")

            if len(blocks) < 6:
                continue

            cov = int(blocks[4]) + int(blocks[5])

            if cov > 0:
                hist[cov] += 1

    return hist


def write_distribution_tsv(hist: Counter[int], out_file: str) -> None:
    with open(out_file, "w") as out:
        out.write("coverage\tCpG_count\n")

        for cov in sorted(hist):
            out.write(f"{cov}\t{hist[cov]}\n")


def plot_coverage_hist(
    sample: str,
    hist: Counter[int],
    out_file: str,
    max_cov: int = 100,
) -> None:
    x_values = []
    y_values = []

    for cov in range(1, max_cov + 1):
        x_values.append(cov)
        y_values.append(hist.get(cov, 0))

    above_max = sum(count for cov, count in hist.items() if cov > max_cov)

    plt.figure(figsize=(8, 5))

    plt.bar(x_values, y_values, width=1.0)

    plt.xlabel("CpG coverage")
    plt.ylabel("Number of CpGs")
    plt.title(f"Coverage distribution per CpG: {sample}")

    plt.xlim(0, max_cov)

    if above_max > 0:
        plt.figtext(
            0.99,
            0.01,
            f"CpGs with coverage > {max_cov}: {above_max:,}",
            ha="right",
            fontsize=8,
        )

    plt.tight_layout()
    plt.savefig(out_file, dpi=300)
    plt.close()


def main() -> None:
    args = parse_args()

    sample_id = Path(args.input).stem.replace("_CpG", "")

    hist = read_coverage_distribution(args.input)

    write_distribution_tsv(hist, args.tsv)

    plot_coverage_hist(
        sample=sample_id,
        hist=hist,
        out_file=args.output,
        max_cov=args.max_cov,
    )


if __name__ == "__main__":
    main()