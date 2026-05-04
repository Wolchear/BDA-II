import argparse
from collections import defaultdict 

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Count covered CpG quantity.")
    parser.add_argument(
        "--input", "-i",
        type=str,
        required=True,
        help="Cov distribution"
    )
    parser.add_argument(
        "--output", "-o",
        type=str,
        required=True,
        help="Output plot file name"
    )

    return parser.parse_args()

def count_cov(file_name: str) -> dict[int, int]:
    thresholds = [1, 5, 10, 25, 50, 100]
    count: dict[int, int] = defaultdict(int)

    with open(file_name, "r") as fh:
        _ = fh.readline()  # skip header

        for line in fh:
            blocks = line.rstrip("\n").split("\t")

            cov = int(blocks[0])
            cpg_count = int(blocks[1])

            for threshold in thresholds:
                if cov >= threshold:
                    count[threshold] += cpg_count

    return dict(count)

def write_data(outfile: str, data: dict[int, int]) -> None:
    with open(outfile, 'w') as oh:
        oh.write("min_coverage\tpassed CpG_count\n")
        for key in sorted(data.keys()):
            oh.write(f"{key}\t{data[key]}\n")

def main() -> None:
    args = parse_args()
    data = count_cov(args.input)
    write_data(args.output, data)


if __name__ == '__main__':
    main()