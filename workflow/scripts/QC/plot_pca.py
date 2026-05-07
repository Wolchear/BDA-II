import argparse
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
from sklearn.decomposition import PCA


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

def plot_pca(
        meth: pd.DataFrame,
        output_file: str | Path,
        title: str,
    ) -> None:
    x = meth.T

    pca = PCA(n_components=2)
    coords = pca.fit_transform(x)

    pc1_var = pca.explained_variance_ratio_[0] * 100
    pc2_var = pca.explained_variance_ratio_[1] * 100

    pca_df = pd.DataFrame(
        coords,
        index=x.index,
        columns=["PC1", "PC2"],
    )

    plt.figure(figsize=(6, 5))
    plt.scatter(pca_df["PC1"], pca_df["PC2"])

    for sample, row in pca_df.iterrows():
        plt.text(
            row["PC1"],
            row["PC2"],
            sample,
            fontsize=8,
        )

    plt.xlabel(f"PC1 ({pc1_var:.1f}% variance)")
    plt.ylabel(f"PC2 ({pc2_var:.1f}% variance)")
    plt.title(title)

    plt.tight_layout()
    plt.savefig(output_file, dpi=300)
    plt.close()


def main() -> None:
    args = parse_args()

    if len(args.mask_files) != len(args.thresholds):
        raise ValueError("Number of --mask-files must match number of --thresholds")

    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)

    meth = read_bed_matrix(args.meth_matrix, na_values=["NA"])
    n_rows = len(meth)

    for threshold, mask_file in zip(args.thresholds, args.mask_files):
        keep = read_packed_mask(mask_file, n_rows=n_rows)

        meth_filtered = meth[keep].dropna(axis=0)

        n_cpgs = meth_filtered.shape[0]

        print(f"Coverage >= {threshold}x: {n_cpgs:,} CpGs used", flush=True)

        if n_cpgs < 2:
            print(
                f"Skipping coverage >= {threshold}x: not enough CpGs.",
                flush=True,
            )
            continue

        plot_pca(
            meth=meth_filtered,
            output_file=outdir / f"pca_{threshold}.png",
            title=f"PCA of methylation levels, CpGs >= {threshold}x in all samples",
        )


if __name__ == "__main__":
    main()