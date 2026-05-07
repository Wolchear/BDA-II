import argparse
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd
import numpy as np

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run Pearson correlation and PCA on methylation matrix."
    )

    parser.add_argument(
        "--meth-matrix",
        required=True,
        help="Merged methylation matrix from bedtools unionbedg",
    )

    parser.add_argument(
        "--mask-files",
        nargs="+",
        required=True,
        help="Packed numpy mask files, e.g. cov_mask_1.packed.npy cov_mask_5.packed.npy",
    )

    parser.add_argument(
        "--outdir",
        required=True,
        help="Output directory",
    )

    parser.add_argument(
        "--thresholds",
        nargs="+",
        type=int,
        default=[1, 5, 15, 20],
        help="Coverage thresholds for filtering CpGs",
    )

    return parser.parse_args()


def read_bed_matrix(
    file_name: str,
    mask: np.ndarray | None = None,
    na_values: list[str] | None = None,
) -> pd.DataFrame:

    df = pd.read_csv(
        file_name,
        sep="\t",
        usecols=range(3, 7),
        dtype="float32",
        na_values=na_values,
    )

    if mask is not None:
        df = df[mask]

    return df

def read_packed_mask(mask_file: str | Path, n_rows: int) -> np.ndarray:
    packed = np.load(mask_file)
    mask = np.unpackbits(packed)[:n_rows].astype(bool)
    return mask


def plot_correlation(
    meth: pd.DataFrame,
    output_file: str | Path,
    title: str,
) -> None:
    corr = meth.corr(method="pearson")

    plt.figure(figsize=(6, 5))

    im = plt.imshow(corr, vmin=-1, vmax=1)
    plt.colorbar(im, label="Pearson correlation")

    plt.xticks(
        ticks=range(len(corr.columns)),
        labels=corr.columns,
        rotation=45,
        ha="right",
    )
    plt.yticks(
        ticks=range(len(corr.index)),
        labels=corr.index,
    )

    for i in range(corr.shape[0]):
        for j in range(corr.shape[1]):
            plt.text(
                j, i,
                f"{corr.iloc[i, j]:.2f}",
                ha="center",
                va="center",
                fontsize=8,
            )

    plt.title(title)
    plt.tight_layout()
    plt.savefig(output_file, dpi=300)
    plt.close()


def main() -> None:
    args = parse_args()

    if len(args.mask_files) != len(args.thresholds):
        raise ValueError(
            "Number of --mask-files must match number of --thresholds"
        )

    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)

    meth = read_bed_matrix(args.meth_matrix, na_values=["NA"])

    n_rows = len(meth)

    for threshold, mask_file in zip(args.thresholds, args.mask_files):
        keep = read_packed_mask(mask_file, n_rows=n_rows)

        meth_filtered = meth.loc[keep].dropna(axis=0)

        plot_correlation(
            meth=meth_filtered,
            output_file=outdir / f"cor_{threshold}.png",
            title=f"Pearson correlation, CpGs >= {threshold}x in all samples",
        )

        print(
            f"threshold >= {threshold}: "
            f"used {len(meth_filtered)} CpGs "
            f"from mask {mask_file}"
        )
        
if __name__ == "__main__":
    main()