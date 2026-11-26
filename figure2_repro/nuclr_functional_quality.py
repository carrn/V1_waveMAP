"""
The functional_quality.py analysis, but clustering the **NuCLR embeddings** instead
of waveform shape (+ laminar position). There is no laminar-weight lambda here --
NuCLR is a single learned embedding -- so the sweep is over cluster count K only.

For each K in {3,5,7,9} we cluster with the SAME pipeline the paper uses
(UMAP fuzzy graph -> Louvain -> forced to exactly K via common.cluster_to_k), then
score how strongly the clusters separate the 8 HELD-OUT functional/tuning variables
(never used for clustering): mean eta^2, z-scored against a 300x label-shuffle null.

Baselines kept for context, scored identically on the same units:
  - waveform-shape clustering (the paper's lambda=0 features)
  - the published WaveMAP K=9 labels

NuCLR embeddings are joined to the 606 visually-responsive units by exact cortical
depth (per-session affine; same key used to build the dataset).

Run (from figure2_repro/, with its venv):
    .venv/bin/python nuclr_functional_quality.py
Outputs (in nuclr_carr/output/):
    nuclr_functional_quality.png        (z vs K; per-variable eta^2 at K=9)
    nuclr_functional_per_variable.png   (per-variable eta^2 vs K)
"""
import os
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

import run_figures34 as R
from common import seed_everything, run_umap, scan_resolutions, cluster_to_k
from functional_quality import FUNC_VARS, func_z   # eta^2 + shuffle-null z-score

KS = [3, 5, 7, 9]
HERE = os.path.dirname(os.path.abspath(__file__))
CELLTYPES = os.path.dirname(os.path.dirname(HERE))
NPZ = os.path.join(CELLTYPES, "nuclr_carr", "embs", "wavemap_unit_embeddings.npz")
OUT = os.path.join(CELLTYPES, "nuclr_carr", "output")
os.makedirs(OUT, exist_ok=True)

C_NUCLR, C_WAVE, C_PUB = "#2ca25f", "#3182bd", "#bdbdbd"


def fit_affine(dryad, carr):
    """dryad_depth ~= sign*carr_depth + offset (offset voted on the integer grid)."""
    best = None
    for sign in (1.0, -1.0):
        diffs = (dryad[None, :] - sign * carr[:, None]).ravel()
        vals, counts = np.unique(np.round(diffs).astype(int), return_counts=True)
        off, inl = int(vals[counts.argmax()]), int(counts.max())
        if best is None or inl > best[2]:
            best = (sign, float(off), inl)
    return best[0], best[1]


def join_nuclr_embeddings(df):
    """Return an (n_df, dim) array of NuCLR embeddings aligned to df rows, matched
    by (session, exact depth). NaN rows = unmatched."""
    z = np.load(NPZ, allow_pickle=True)
    emb = z["embeddings"].astype(float)
    e_sess = z["session_id"].astype(str)
    e_depth = z["depth_um"].astype(float)
    E = np.full((len(df), emb.shape[1]), np.nan)
    for s in sorted(df.session.unique()):
        sid = f"m{1 if s <= 3 else 2}_s{s}"
        em = e_sess == sid
        de, ee = e_depth[em], emb[em]
        rows = np.where((df.session == s).values)[0]
        cd = df.Depth.values[rows]
        sign, off = fit_affine(de, cd)
        target = sign * cd + off
        for r_i, t in zip(rows, target):
            j = int(np.argmin(np.abs(de - t)))
            if abs(de[j] - t) < 1e-2:
                E[r_i] = ee[j]
    return E


def main():
    df, wf = R.load_table()                       # 606 vis-responsive units
    # held-out functional panel (identical to functional_quality.py)
    cols = []
    for key, (col, tf) in FUNC_VARS.items():
        v = df[col].astype(float).values.copy()
        if tf == "log1p":
            v = np.log1p(v)
        elif tf == "log":
            v = np.log(np.clip(v, 1e-9, None))
        cols.append(v)
    varmat = np.column_stack(cols)

    E = join_nuclr_embeddings(df)
    matched = np.isfinite(E).all(1)
    print(f"loaded {len(df)} units; NuCLR embedding matched for {matched.sum()}")
    # restrict all three clusterings to the same matched units (apples-to-apples)
    df, wf, varmat, E = df[matched].reset_index(drop=True), wf[matched], varmat[matched], E[matched]

    # ---- UMAP graphs depend only on features, not K: build once ----
    seed_everything(R.UMAP_SEED)
    _, g_wave = run_umap(wf, seed=R.UMAP_SEED)
    scan_wave = scan_resolutions(g_wave)
    seed_everything(R.UMAP_SEED)
    _, g_nuclr = run_umap(E, seed=R.UMAP_SEED)
    scan_nuclr = scan_resolutions(g_nuclr)

    rng = np.random.default_rng(0)
    Zn, Zw, pvn, pvw = {}, {}, {}, {}
    for K in KS:
        lab_n, how_n = cluster_to_k(g_nuclr, scan_nuclr, K, prefer=1.0)
        lab_w, how_w = cluster_to_k(g_wave, scan_wave, K, prefer=1.0)
        Zn[K], pvn[K] = func_z(varmat, lab_n, rng)
        Zw[K], pvw[K] = func_z(varmat, lab_w, rng)
        print(f"  K={K}: NuCLR z={Zn[K]:6.2f} ({how_n})   waveform z={Zw[K]:6.2f} ({how_w})")

    pub = df["cluster 1.0"].astype(int).values
    z_pub, obs_pub = func_z(varmat, pub, rng)
    print(f"  published WaveMAP K=9 labels: z={z_pub:.2f}")
    names = list(FUNC_VARS)

    # ---------------- figure 1: z vs K + per-variable eta^2 at K=9 ----------------
    fig, (axL, axR) = plt.subplots(1, 2, figsize=(14, 5.2),
                                   gridspec_kw={"width_ratios": [1.05, 1.25]})
    axL.axhspan(-2, 2, color="0.88", alpha=0.7, zorder=0, label="≈ chance (|z|<2)")
    axL.plot(KS, [Zn[K] for K in KS], "-o", color=C_NUCLR, lw=2, ms=7, label="NuCLR embedding")
    axL.plot(KS, [Zw[K] for K in KS], "-o", color=C_WAVE, lw=2, ms=7, label="waveform shape")
    axL.axhline(z_pub, ls="--", color="0.4", lw=1.2, label=f"published WaveMAP K=9 (z={z_pub:.1f})")
    axL.axhline(0, color="k", lw=0.8)
    axL.set_xticks(KS)
    axL.set_xlabel("number of clusters  K", fontsize=10)
    axL.set_ylabel("functional differentiation  z  (vs shuffle null)", fontsize=10)
    axL.set_title("Held-out functional differentiation vs K\n"
                  "(↑ = clusters separate independent tuning variables beyond chance)",
                  fontsize=11, fontweight="bold", loc="left")
    axL.legend(fontsize=8, frameon=False)
    for sp in ("top", "right"):
        axL.spines[sp].set_visible(False)

    yy = np.arange(len(names))
    axR.barh(yy - 0.27, pvn[9], height=0.27, color=C_NUCLR, edgecolor="k", linewidth=0.6,
             label="NuCLR K=9")
    axR.barh(yy, pvw[9], height=0.27, color=C_WAVE, label="waveform K=9")
    axR.barh(yy + 0.27, obs_pub, height=0.27, color=C_PUB, label="published K=9")
    axR.set_yticks(yy); axR.set_yticklabels(names, fontsize=8); axR.invert_yaxis()
    axR.set_xlabel("η²  (between-cluster variance fraction)", fontsize=10)
    axR.set_title("Per-variable separation (K=9)\n(which functions distinguish the clusters)",
                  fontsize=11, fontweight="bold", loc="left")
    axR.legend(fontsize=8, frameon=False)
    for sp in ("top", "right"):
        axR.spines[sp].set_visible(False)
    fig.tight_layout()
    out1 = os.path.join(OUT, "nuclr_functional_quality.png")
    fig.savefig(out1, dpi=130, bbox_inches="tight")
    print(f"saved {out1}")

    # ---------------- figure 2: per-variable eta^2 vs K ----------------
    figv, axes = plt.subplots(2, 4, figsize=(15, 7), sharex=True)
    for j, (name, ax) in enumerate(zip(names, axes.ravel())):
        ax.plot(KS, [pvn[K][j] for K in KS], "-o", color=C_NUCLR, ms=4, lw=1.5, label="NuCLR")
        ax.plot(KS, [pvw[K][j] for K in KS], "-o", color=C_WAVE, ms=4, lw=1.5, label="waveform")
        ax.axhline(obs_pub[j], ls="--", color="0.5", lw=1, label="published K=9")
        ax.set_xticks(KS)
        ax.set_title(name, fontsize=10, fontweight="bold")
        ax.set_ylabel("η²", fontsize=9); ax.set_ylim(bottom=0)
        for sp in ("top", "right"):
            ax.spines[sp].set_visible(False)
        if j == 0:
            ax.legend(fontsize=7, frameon=False)
    figv.suptitle("Per-variable held-out separation η² vs K  (NuCLR vs waveform clustering)",
                  fontsize=13, fontweight="bold")
    figv.supxlabel("number of clusters  K", fontsize=11)
    figv.tight_layout(rect=[0, 0, 1, 0.96])
    out2 = os.path.join(OUT, "nuclr_functional_per_variable.png")
    figv.savefig(out2, dpi=130, bbox_inches="tight")
    print(f"saved {out2}")


if __name__ == "__main__":
    main()
