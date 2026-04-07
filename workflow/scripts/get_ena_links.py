import requests
import argparse
import sys

import pandas as pd

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Add ENA links to fasta files")
    parser.add_argument(
        "--table", "-t",
        type=str,
        required=True,
        help="Input table"
    )
    parser.add_argument(
        "--accession", "-acc",
        type=str,
        default="SRA",
        help="SRA accession column name (default: SRA)"
    )
    parser.add_argument(
        "--sep", "-s",
        type=str,
        default="\t",
        help="Column separator (default: tab)"
    )
    
    parser.add_argument(
        "--inplace",
        action="store_true",
        help="Modify the input file in place (otherwise print to stdout)"
    )
    
    return parser.parse_args()

def get_ena_responce(run_acc: str) -> tuple[str, str, str]:
    try:
        url = (
            "https://www.ebi.ac.uk/ena/portal/api/filereport"
            f"?accession={run_acc}"
            "&result=read_run"
            "&fields=run_accession,fastq_ftp"
            "&format=json"
        )
        data = requests.get(url, timeout=30).json()
        if not data or not data[0].get("fastq_ftp"):
            return ( "", "", 'NA' )

        files = data[0]["fastq_ftp"].split(";")
        files = [f"https://{f}" for f in files]

        if len(files) == 1:
            return ( files[0], "", 'SE' )
        elif len(files) >= 2:
            return ( files[0], files[1], 'PE' )
        else:
            return ( "", "", 'NA' )

    except requests.RequestException:
        return( "", "", 'NA' )


def main() -> None:
    args = parse_args()
    
    sep = args.sep.encode().decode("unicode_escape")
    
    df = pd.read_csv(
        args.table,
        sep=sep
    )
    
    if args.accession not in df.columns:
        raise ValueError(
            f"Column '{args.accession}' not found in table. "
            f"Available: {list(df.columns)}"
        )

    fastq_1: str = []
    fastq_2: str = []
    library_layout: str = []
    for acc in df[args.accession]:
        response = get_ena_responce(str(acc))
        fastq_1.append(response[0])
        fastq_2.append(response[1])
        library_layout.append(response[2])
        
    df["fastq_1"] = fastq_1
    df["fastq_2"] = fastq_2
    df["library_layout"] = library_layout

    if args.inplace:
        df.to_csv(args.table, sep=sep, index=False)
    else:
        df.to_csv(sys.stdout, sep=sep, index=False)

if __name__ == '__main__':
    main()