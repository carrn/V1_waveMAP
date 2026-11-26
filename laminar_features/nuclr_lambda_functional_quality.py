"""
functional_quality.py, but with THREE feature blocks: waveform shape, laminar
position, and the NuCLR embedding. The laminar weight is FROZEN at lambda=4 (the
paper's functional-differentiation peak); we sweep a new NuCLR weight mu:

    features(mu) = [ waveform , 4 * laminar_position , mu * nuclr_scaled ]
    mu = 0    -> waveform + 4*laminar      (the paper's lambda=4 solution)
    mu = inf  -> NuCLR embedding only

The 256-d NuCLR block is centered and rescaled to the SAME total variance as the
52-d waveform block, so mu=1 means "NuCLR contributes about as much as waveform
shape" (raw 256-d would otherwise dominate purely by dimension count).

For each (mu, K in {3,5,7,9}) we cluster with the paper's pipeline (UMAP graph ->
Louvain -> forced to exactly K) and score held-out functional differentiation
(mean eta^2 over 8 tuning variables, z-scored vs a 300x label-shuffle null) --
identical metric to functional_quality.py.

Run (from laminar_features/):  .venv/bin/python nuclr_lambda_functional_quality.py
Outputs (nuclr_carr/output/):
    nuclr_lambda_functional_quality.png       (z vs mu; per-variable eta^2 at K=9)
    nuclr_lambda_functional_per_variable.png  (per-variable eta^2 vs mu)
"""
import os
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

import run_figures34 as R
import metrics34 as M
from common import seed_everything, run_umap, scan_resolutions, cluster_to_k
from functional_quality import FUNC_VARS, func_z
from nuclr_functional_quality import join_nuclr_embeddings

LAM_POS = 4.0                                       # frozen laminar weight
MUS = [0, 0.125, 0.25, 0.5, 1, 2, 4, 8, 16, float("inf")]
KS = [3, 5, 7, 9]

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(os.path.dirname(os.path.dirname(HERE)), "nuclr_carr", "output")
os.makedirs(OUT, exist_ok=True)


def mtext(mu):
    return "∞ (NuCLR only)" if not np.isfinite(mu) else f"{mu:g}"


def features3(wf, pos, nuclr_s, mu):
    """waveform + LAM_POS*position + mu*nuclr_scaled  (mu=inf -> NuCLR only)."""
    if not np.isfinite(mu):
        return nuclr_s
    base = np.column_stack([wf, LAM_POS * pos[:, None]])
    return base if mu == 0 else np.column_stack([base, mu * nuclr_s])


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
    varmat = np.column_stack(cols)

    E = join_nuclr_embeddings(df)
    m = np.isfinite(E).all(1)
    df, wf, pos, varmat, E = (df[m].reset_index(drop=True), wf[m], pos[m],
                              varmat[m], E[m])
    print(f"{m.sum()} units with NuCLR embedding")

    # scale the NuCLR block to the waveform block's total variance
    V_w = wf.var(0).sum()
    Ec = E - E.mean(0)
    V_n = Ec.var(0).sum()
    nuclr_s = Ec * np.sqrt(V_w / V_n)

    # UMAP graph + resolution scan per mu (depends only on features, reused across K)
    graphs = {}
    for mu in MUS:
        seed_everything(R.UMAP_SEED)
        _, g = run_umap(features3(wf, pos, nuclr_s, mu), seed=R.UMAP_SEED)
        graphs[mu] = (g, scan_resolutions(g))
        print(f"  graph ready  mu={mtext(mu)}")

    rng = np.random.default_rng(0)
    Z = {K: [] for K in KS}
    per_var = {}
    for K in KS:
        for mu in MUS:
            g, scan = graphs[mu]
            lab, _ = cluster_to_k(g, scan, K, prefer=1.0)
            z, obs = func_z(varmat, lab, rng)
            Z[K].append(z)
            per_var[(K, mu)] = obs
            print(f"  K={K} mu={mtext(mu):<16} z={z:6.2f}")

    pub = df["cluster 1.0"].astype(int).values
    z_pub, _ = func_z(varmat, pub, rng)
    print(f"  published WaveMAP K=9: z={z_pub:.2f}")

    # ----- figure 1: z vs mu (line per K) + per-variable eta^2 at K=9 -----
    X, xtl, pz, infp = M._log_positions(MUS)
    xtl = [t.replace("λ", "μ") if isinstance(t, str) else t for t in xtl]
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
    axL.set_xlabel("NuCLR-feature weight  μ   (laminar frozen at λ=4;  μ=0: wave+laminar,  μ=∞: NuCLR only)",
                   fontsize=9.5)
    axL.set_ylabel("functional differentiation  z  (vs shuffle null)", fontsize=10)
    axL.set_title("Held-out functional differentiation vs NuCLR weight μ\n"
                  "(waveform + 4·laminar + μ·NuCLR;  ↑ = clusters separate tuning beyond chance)",
                  fontsize=11, fontweight="bold", loc="left")
    axL.legend(fontsize=8, frameon=False, ncol=2)
    for sp in ("top", "right"):
        axL.spines[sp].set_visible(False)

    names = list(FUNC_VARS)
    peak_mu = MUS[int(np.argmax(Z[9]))]
    base, peak, only = per_var[(9, 0)], per_var[(9, peak_mu)], per_var[(9, float("inf"))]
    yy = np.arange(len(names))
    axR.barh(yy - 0.27, base, height=0.27, color="#9ecae1", label="K=9, μ=0 (wave+4·lam)")
    axR.barh(yy, peak, height=0.27, color="#2ca25f", edgecolor="k", linewidth=0.8,
             label=f"K=9, μ={mtext(peak_mu)} (peak)")
    axR.barh(yy + 0.27, only, height=0.27, color="#fcae91", label="K=9, μ=∞ (NuCLR only)")
    axR.set_yticks(yy); axR.set_yticklabels(names, fontsize=8); axR.invert_yaxis()
    axR.set_xlabel("η²  (between-cluster variance fraction)", fontsize=10)
    axR.set_title("Per-variable separation (K=9)\n(which functions distinguish the clusters)",
                  fontsize=11, fontweight="bold", loc="left")
    axR.legend(fontsize=8, frameon=False)
    for sp in ("top", "right"):
        axR.spines[sp].set_visible(False)
    fig.tight_layout()
    out1 = os.path.join(OUT, "nuclr_lambda_functional_quality.png")
    fig.savefig(out1, dpi=130, bbox_inches="tight")
    print(f"saved {out1}")

    # ----- figure 2: per-variable eta^2 vs mu (panel per variable, line per K) -----
    figv, axes = plt.subplots(2, 4, figsize=(15, 7), sharex=True)
    for j, (name, ax) in enumerate(zip(names, axes.ravel())):
        for K in KS:
            y = [per_var[(K, mu)][j] for mu in MUS]
            ax.plot(X, y, "-o", ms=3, lw=1.3, color=kcol[K], label=f"K={K}")
        ax.set_xscale("log"); ax.set_xticks(X)
        ax.set_xticklabels(xtl, fontsize=6, rotation=90)
        ax.xaxis.set_minor_locator(plt.NullLocator())
        ax.set_xlim(pz / 1.6, infp * 1.6)
        ax.set_title(name, fontsize=10, fontweight="bold")
        ax.set_ylabel("η²", fontsize=9); ax.set_ylim(bottom=0)
        for sp in ("top", "right"):
            ax.spines[sp].set_visible(False)
        if j == 0:
            ax.legend(fontsize=7, frameon=False, ncol=2)
    figv.suptitle("Per-variable separation η² vs NuCLR weight μ  (waveform + 4·laminar + μ·NuCLR)",
                  fontsize=13, fontweight="bold")
    figv.supxlabel("NuCLR-feature weight  μ", fontsize=11)
    figv.tight_layout(rect=[0, 0, 1, 0.97])
    out2 = os.path.join(OUT, "nuclr_lambda_functional_per_variable.png")
    figv.savefig(out2, dpi=130, bbox_inches="tight")
    print(f"saved {out2}")


if __name__ == "__main__":
    main()
