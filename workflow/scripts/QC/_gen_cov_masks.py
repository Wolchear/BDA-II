from pathlib import Path
import argparse

import numpy as np
import pandas as pd

CHUNKSIZE = 1_000_000

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Count meth matrix and cov matrix.")
    parser.add_argument(
        "--input", "-i",
        type=str,
        required=True,
        help="Coverage matrix file ( bed format )"
    )
    
    parser.add_argument(
        "--prefix", "-p",
        type=str,
        required=True,
        help="Output file's prefix"
    )
    
    parser.add_argument(
        "--masks", "-m",
        type=int,
        nargs='*',
        default=[1, 5, 15, 20],
        help="Output file's prefix"
    )
    
    
    return parser.parse_args()



def main() -> None:
    args = parse_args()
    out_dir = Path(args.prefix)
    out_dir.mkdir(parents=True, exist_ok=True)
    
    masks = {t: [] for t in args.masks}


    for cov_chunk in pd.read_csv(
        args.input,
        sep="\t",
        usecols=range(3, 7),
        dtype="uint16",
        chunksize=CHUNKSIZE,
    ):
        X = cov_chunk.to_numpy(copy=False)

        for t in args.masks:
            mask = (X >= t).all(axis=1)

            packed = np.packbits(mask)

            masks[t].append(packed)


    for t in args.masks:
        packed_mask = np.concatenate(masks[t])

        out_file = out_dir / f"cov_mask_{t}.packed.npy"

        np.save(out_file, packed_mask)

        print(
            f"threshold >= {t}: "
            f"{packed_mask.nbytes / 1024**2:.2f} MB "
            f"-> {out_file}"
        )
        


if __name__ == "__main__":
    main()
