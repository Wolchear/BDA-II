import argparse


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description='Get meth and cov matrix subsets'
    )

    parser.add_argument(
        '--input', '-i',
        type=str,
        required=True,
        help='Specify matrix input file'
    )
    
    parser.add_argument(
        '--chromosomes', '-ch',
        type=int,
        nargs='+',
        help='Specify subset chromosomes'
    )
    
    return parser.parse_args()


def read_bed_matrix( file_name: str, chromosomes: list[int]) -> None:
    chrom_set = {f"chr{chrom}" for chrom in chromosomes}
    with open(file_name, 'r') as fh:
        header = fh.readline()
        print(header, end='')
        for line in fh:
            chrom = line.split("\t", 1)[0]
            if chrom in chrom_set:
                print(line, end='')

def main():
    args = parse_args()
    read_bed_matrix(args.input, args.chromosomes)

if __name__ == '__main__':
    main()