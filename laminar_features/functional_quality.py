"""
A non-circular cluster-quality metric: how strongly do clusters separate
HELD-OUT functional variables (never used for clustering), relative to chance?

For each held-out variable we use eta^2 (between-cluster variance fraction). Raw
eta^2 grows mechanically with K, so we standardize against a label-shuffle null
(same cluster sizes): z = (eta^2_observed - mean_null) / std_null.  Averaged over
the panel of functional variables this gives one "functional differentiation"
z-score per (K, lambda) -- high = clusters are functionally meaningful beyond
chance.  Unlike waveform/depth spread (which are circular and monotonic in
lambda), this can peak at the genuinely good solutions.

Run:  uv run python functional_quality.py
"""
import os
import numpy as np

import run_figures34 as R
import metrics34 as M
from common import seed_everything, run_umap, scan_resolutions, cluster_to_k
import matplotlib.pyplot as plt

WEIGHTS = [0, 0.125, 0.25, 0.5, 1, 2, 4, 8, 16, float("inf")]
KS = [3, 5, 7, 9]
N_NULL = 300

# held-out functional variables (NOT used for clustering); (column, transform)
FUNC_VARS = {
    "DI": ("DI", None),
    "OSI": ("Orientation Index", None),
    "OriCircVar": ("Orientation Cicular Variance", None),
    "DirCircVar": ("Direction Cicular Variance", None),
    "OriTuneBW": ("Orientation tuning BandWidth", None),
    "SimpleCmplx": ("SimpleComplexIndex", None),
    "logFR": ("FR", "log1p"),
    "logKurt(burst)": ("kurt", "log"),
}


def eta2(x, labels):
    """Between-cluster variance fraction for one variable (NaNs dropped)."""
    m = np.isfinite(x)
    x, lab = x[m], labels[m]
    grand = x.mean()
    sst = np.sum((x - grand) ** 2)
    if sst <= 0:
        return 0.0
    ssb = 0.0
    for c in np.unique(lab):
        xc = x[lab == c]
        ssb += len(xc) * (xc.mean() - grand) ** 2
    return ssb / sst


def func_z(varmat, labels, rng):
    """Mean eta^2 over variables, z-scored against a label-shuffle null."""
    obs = np.array([eta2(varmat[:, j], labels) for j in range(varmat.shape[1])])
    obs_mean = obs.mean()
    null = np.empty(N_NULL)
    for n in range(N_NULL):
        sl = rng.permutation(labels)
        null[n] = np.mean([eta2(varmat[:, j], sl) for j in range(varmat.shape[1])])
    z = (obs_mean - null.mean()) / (null.std() + 1e-12)
    return z, obs   # z-score and per-variable observed eta^2


def main():
    df, wf = R.load_table()
    pos = R.laminar_position(df["depth_scaled"].values)

    cols = []
    for key, (col, tf) in FUNC_VARS.items():
        v = df[col].astype(float).values.copy()
        if tf == "log1p":
            v = np.log1p(v)
        elif tf == "log":
            v = np.log(np.clip(v, 1e-9, None))
        cols.append(v)
    varmat = np.column_stack(cols)               # (606, n_vars)

    # full-data graphs only (cheap; no subsampling needed for this metric)
    graphs = {}
    for w in WEIGHTS:
        seed_everything(R.UMAP_SEED)
        _, g = run_umap(R.features(wf, pos, w), seed=R.UMAP_SEED)
        graphs[w] = (g, scan_resolutions(g))
        print(f"  graph ready λ={R.wtext(w)}")

    rng = np.random.default_rng(0)
    Z = {K: [] for K in KS}
    per_var = {}      # (K, w) -> per-variable eta^2  (for a couple of solutions)
    for K in KS:
        for w in WEIGHTS:
            g, scan = graphs[w]
            lab, _ = cluster_to_k(g, scan, K, prefer=1.0)
            z, obs = func_z(varmat, lab, rng)
            Z[K].append(z)
            per_var[(K, w)] = obs
            print(f"  K={K} λ={R.wtext(w):<16} functional-z={z:6.2f}")

    # paper published labels (K=9) as a reference z
    pub = df["cluster 1.0"].astype(int).values
    z_pub, obs_pub = func_z(varmat, pub, rng)
    print(f"  published K=9 labels: functional-z={z_pub:.2f}")

    # ---------- plot ----------
    X, xtl, pz, infp = M._log_positions(WEIGHTS)
    cmap = plt.cm.viridis
    kcol = {K: cmap(0.1 + 0.8 * i / max(1, len(KS) - 1)) for i, K in enumerate(KS)}
    fig, (axL, axR) = plt.subplots(1, 2, figsize=(15, 5.4),
                                   gridspec_kw={"width_ratios": [1.4, 1.0]})

    for K in KS:
        axL.plot(X, Z[K], "-o", ms=4, lw=1.5, color=kcol[K], label=f"K={K}")
    axL.axhline(z_pub, ls="--", color="0.4", lw=1, label=f"published K=9 (z={z_pub:.1f})")
    axL.axhline(0, color="k", lw=0.8)
    axL.fill_between([pz / 1.6, infp * 1.6], -2, 2, color="0.85", alpha=0.5, zorder=0,
                     label="≈ chance (|z|<2)")
    axL.set_xscale("log"); axL.set_xticks(X); axL.set_xticklabels(xtl, fontsize=8)
    axL.xaxis.set_minor_locator(plt.NullLocator())
    axL.set_xlim(pz / 1.6, infp * 1.6)
    axL.set_xlabel("laminar-feature weight  λ", fontsize=10)
    axL.set_ylabel("functional differentiation  z  (vs shuffle null)", fontsize=10)
    axL.set_title("Held-out functional differentiation vs λ\n"
                  "(↑ = clusters separate independent tuning variables beyond chance)",
                  fontsize=11, fontweight="bold", loc="left")
    axL.legend(fontsize=8, frameon=False, ncol=2)
    for sp in ("top", "right"):
        axL.spines[sp].set_visible(False)

    # right: per-variable eta^2 for K=9 at shape (λ=0), the peak (λ=4), and depth (λ=∞)
    names = list(FUNC_VARS)
    shape, best, posonly = per_var[(9, 0)], per_var[(9, 4)], per_var[(9, float("inf"))]
    yy = np.arange(len(names))
    axR.barh(yy - 0.27, shape, height=0.27, color="#9ecae1", label="K=9, λ=0 (shape)")
    axR.barh(yy, best, height=0.27, color="#2ca25f", edgecolor="k", linewidth=0.8,
             label="K=9, λ=4 (peak)")          # singled out
    axR.barh(yy + 0.27, posonly, height=0.27, color="#fcae91", label="K=9, λ=∞ (depth)")
    axR.set_yticks(yy); axR.set_yticklabels(names, fontsize=8)
    axR.invert_yaxis()
    axR.set_xlabel("η²  (between-cluster variance fraction)", fontsize=10)
    axR.set_title("Per-variable separation (K=9)\n(which functions distinguish cell types)",
                  fontsize=11, fontweight="bold", loc="left")
    axR.legend(fontsize=8, frameon=False)
    for sp in ("top", "right"):
        axR.spines[sp].set_visible(False)

    fig.tight_layout()
    out = os.path.join(R.OUT, "functional_quality.png")
    fig.savefig(out, dpi=130, bbox_inches="tight")
    print(f"saved {out}")

    # ---------- per-variable eta^2 vs λ (one small panel per variable, line per K) ----------
    figv, axes = plt.subplots(2, 4, figsize=(15, 7), sharex=True)
    for j, (name, ax) in enumerate(zip(names, axes.ravel())):
        for K in KS:
            y = [per_var[(K, w)][j] for w in WEIGHTS]
            ax.plot(X, y, "-o", ms=3, lw=1.3, color=kcol[K], label=f"K={K}")
        ax.set_xscale("log"); ax.set_xticks(X)
        ax.set_xticklabels(xtl, fontsize=6, rotation=90)
        ax.xaxis.set_minor_locator(plt.NullLocator())
        ax.set_xlim(pz / 1.6, infp * 1.6)
        ax.set_title(name, fontsize=10, fontweight="bold")
        ax.set_ylabel("η²", fontsize=9)
        ax.set_ylim(bottom=0)
        for sp in ("top", "right"):
            ax.spines[sp].set_visible(False)
        if j == 0:
            ax.legend(fontsize=7, frameon=False, ncol=2)
    figv.suptitle("Per-variable separation η² vs λ  (one panel per held-out variable; "
                  "lines = K)", fontsize=13, fontweight="bold")
    figv.supxlabel("laminar-feature weight  λ", fontsize=11)
    figv.tight_layout(rect=[0, 0, 1, 0.97])
    outv = os.path.join(R.OUT, "functional_per_variable.png")
    figv.savefig(outv, dpi=130, bbox_inches="tight")
    print(f"saved {outv}")


if __name__ == "__main__":
    main()
