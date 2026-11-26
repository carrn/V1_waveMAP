"""How noisy is the functional-z of a single NuCLR-only K=9 clustering?

Two checks:
 (1) raw embeddings E vs centered+variance-rescaled nuclr_s at the SAME UMAP seed
     (a global affine UMAP is invariant to -> any difference is approximate-kNN noise)
 (2) the z distribution across UMAP seeds (clustering-instability noise)
"""
import numpy as np
import run_figures34 as R
from common import seed_everything, run_umap, scan_resolutions, cluster_to_k
from functional_quality import FUNC_VARS, func_z
from nuclr_functional_quality import join_nuclr_embeddings
from sklearn.metrics import adjusted_rand_score as ARI

K = 9


def varmatrix(df):
    cols = []
    for key, (col, tf) in FUNC_VARS.items():
        v = df[col].astype(float).values.copy()
        if tf == "log1p": v = np.log1p(v)
        elif tf == "log": v = np.log(np.clip(v, 1e-9, None))
        cols.append(v)
    return np.column_stack(cols)


def cluster_z(feat, varmat, seed):
    seed_everything(seed)
    _, g = run_umap(feat, seed=seed)
    lab, how = cluster_to_k(g, scan_resolutions(g), K, prefer=1.0)
    z, _ = func_z(varmat, lab, np.random.default_rng(0))   # fixed null rng
    return z, lab, how


def main():
    df, wf = R.load_table()
    E = join_nuclr_embeddings(df)
    m = np.isfinite(E).all(1)
    df, E, varmat = df[m].reset_index(drop=True), E[m], varmatrix(df)[m]

    Ec = E - E.mean(0)
    nuclr_s = Ec * np.sqrt(wf[m].var(0).sum() / Ec.var(0).sum())

    # (1) same seed, raw vs centered+scaled (should be identical if UMAP were exact)
    z_raw, lab_raw, how_raw = cluster_z(E, varmat, R.UMAP_SEED)
    z_scl, lab_scl, how_scl = cluster_z(nuclr_s, varmat, R.UMAP_SEED)
    print(f"seed={R.UMAP_SEED}: raw E  z={z_raw:.2f} ({how_raw}, {len(set(lab_raw))} clusters)")
    print(f"seed={R.UMAP_SEED}: scaled z={z_scl:.2f} ({how_scl}, {len(set(lab_scl))} clusters)")
    print(f"  ARI(raw, scaled) = {ARI(lab_raw, lab_scl):.3f}  (1.0 = identical partition)\n")

    # (2) z across UMAP seeds (raw embeddings)
    seeds = [0, 7, 17, 42, 50, 99, 123, 202, 314, 777]
    zs = []
    for s in seeds:
        z, lab, how = cluster_z(E, varmat, s)
        zs.append(z)
        print(f"  seed {s:4d}: z={z:6.2f}  ({how}, {len(set(lab))} clusters)")
    zs = np.array(zs)
    print(f"\nNuCLR-only K=9 functional-z across {len(seeds)} seeds: "
          f"mean={zs.mean():.1f}  std={zs.std():.1f}  range=[{zs.min():.1f}, {zs.max():.1f}]")


if __name__ == "__main__":
    main()
