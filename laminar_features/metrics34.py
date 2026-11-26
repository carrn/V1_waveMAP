"""
Cluster-quality metrics as a function of the laminar-feature weight lambda
(the extension's free parameter).  All metrics use the K=9 forced clusterings.

  - stability        : mean pairwise adjusted Rand index across UMAP re-seeds
                       (how reproducible the 9-cluster solution is).
  - waveform spread  : within-cluster RMS distance to the cluster-mean waveform,
                       in the 52-d waveform space (shape coherence; lower = tighter).
  - depth spread     : mean within-cluster std of laminar depth (laminar coherence).
  - DI differentiation: std across clusters of the per-cluster mean direction
                       index (how much cell types differ in selectivity).
"""
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from itertools import combinations
from sklearn.metrics import adjusted_rand_score

from common import cluster_to_k

METRIC_KEYS = ("stab", "stab_err", "wspread", "dspread", "didiff")


def paper_reference(df, wf):
    """Waveform spread, depth spread and DI differentiation of the published
    K=9 labels on the same neurons (the dashed reference lines)."""
    pub = df["cluster 1.0"].astype(int).values
    return {"wspread": waveform_spread(wf, pub),
            "dspread": depth_spread(df["depth_scaled"].values, pub),
            "didiff": di_differentiation(df["DI"].values, pub)}


def clustering_metrics(df, wf, labels, subs, K):
    """All quality metrics for one full-data clustering `labels` (forced to K).

    `subs` is the list of (idx, graph, scan) subsample graphs from
    run_figures34.build_graphs; each is re-clustered to K for the stability score.
    Returns {key: value} for every key in METRIC_KEYS."""
    runs = [(idx, cluster_to_k(g, sc, K, prefer=1.0)[0]) for idx, g, sc in subs]
    s, se = overlap_stability(runs)
    return {"stab": s, "stab_err": se,
            "wspread": waveform_spread(wf, labels),
            "dspread": depth_spread(df["depth_scaled"].values, labels),
            "didiff": di_differentiation(df["DI"].values, labels)}


def overlap_stability(runs):
    """Mean +/- std pairwise adjusted Rand index across subsample re-clusterings.

    `runs` is a list of (idx_array, labels_array): each a clustering of a random
    neuron subsample. ARI is computed on the neurons shared by each pair of runs.
    (Pure UMAP-seed re-runs are degenerate here -- for ~600 points the fuzzy kNN
    graph Louvain clusters is seed-invariant, giving ARI=1.0 regardless of the
    layout seed -- so we perturb the neuron set instead.)
    """
    maps = [(idx, dict(zip(idx.tolist(), lab.tolist()))) for idx, lab in runs]
    aris = []
    for (i1, m1), (i2, m2) in combinations(maps, 2):
        common = np.intersect1d(i1, i2)
        if len(common) > 10:
            aris.append(adjusted_rand_score([m1[c] for c in common],
                                            [m2[c] for c in common]))
    return float(np.mean(aris)), float(np.std(aris))


def waveform_spread(wf, labels):
    per = []
    for c in set(labels):
        g = wf[labels == c]
        if len(g) > 1:
            per.append(np.sqrt(((g - g.mean(0)) ** 2).sum(1).mean()))
    return float(np.mean(per))


def depth_spread(depth, labels):
    per = [np.nanstd(depth[labels == c]) for c in set(labels)]
    return float(np.nanmean(per))


def di_differentiation(di, labels):
    """Cluster-size-weighted std of per-cluster mean direction index.

    Each cluster's mean DI is weighted by its proportion of cells p_c = n_c/N:
        wmean = Σ p_c m_c ,   weighted-std = sqrt( Σ p_c (m_c - wmean)^2 ).
    So large clusters count more than small ones (vs the plain unweighted std)."""
    labels = np.asarray(labels)
    N = len(labels)
    cs = sorted(set(labels.tolist()))
    means = np.array([np.nanmean(di[labels == c]) for c in cs])
    w = np.array([(labels == c).sum() / N for c in cs])
    wmean = np.sum(w * means)
    return float(np.sqrt(np.sum(w * (means - wmean) ** 2)))


def _log_positions(weights):
    """x positions for a log axis: λ=0 -> half the smallest positive weight
    (i.e. 0.0625 when the smallest is 0.125); λ=∞ -> twice the largest finite."""
    finite_pos = [w for w in weights if np.isfinite(w) and w > 0]
    pseudo_zero = min(finite_pos) / 2.0
    inf_pos = max(finite_pos) * 2.0

    def xp(w):
        if w == 0:
            return pseudo_zero
        return inf_pos if not np.isfinite(w) else w
    X = np.array([xp(w) for w in weights], float)
    xtl = [("∞" if not np.isfinite(w) else f"{w:g}") for w in weights]
    return X, xtl, pseudo_zero, inf_pos


def plot_metrics_overlay(weights, metrics_by_K, paper_ref=None, baseline_by_K=None):
    """One 2x2 figure overlaying every K on each of the four quality metrics.
    Log λ-axis; λ=0 drawn at the 0.0625 slot, λ=∞ just past the largest weight;
    xlim auto-padded to frame the points.

    baseline_by_K: optional {K: {stab, stab_err, wspread, dspread, didiff}} from
    randomly shuffling the λ=0 labels (chance reference), drawn as X markers at
    λ=0.03125 (one octave left of the λ=0 slot)."""
    X, xtl, pz, infp = _log_positions(weights)
    base_x = pz / 2.0
    Ks = sorted(metrics_by_K)
    cmap = plt.cm.viridis
    kcol = {K: cmap(0.1 + 0.8 * i / max(1, len(Ks) - 1)) for i, K in enumerate(Ks)}

    panels = [
        ("stab", "A  Cluster stability (↑ better)",
         "mean pairwise ARI (subsample)", None, True),
        ("wspread", "B  Waveform spread (↑ less shape-coherent)",
         "within-cluster waveform RMS", "wspread", False),
        ("dspread", "C  Depth spread (↓ more laminar)",
         "within-cluster depth std (um)", "dspread", False),
        ("didiff", "D  Direction-selectivity differentiation (size-weighted)",
         "size-weighted std of per-cluster mean DI", "didiff", False),
    ]
    fig, axes = plt.subplots(2, 2, figsize=(12, 9))
    for ax, (key, title, ylabel, refkey, is_stab) in zip(axes.ravel(), panels):
        for K in Ks:
            y = metrics_by_K[K][key]
            if is_stab:
                ax.errorbar(X, y, yerr=metrics_by_K[K]["stab_err"], fmt="-o", ms=4,
                            capsize=2, lw=1.4, color=kcol[K], label=f"K={K}")
            else:
                ax.plot(X, y, "-o", ms=4, lw=1.4, color=kcol[K], label=f"K={K}")
        if baseline_by_K:  # random-shuffle (chance) reference at lambda=0.03125
            for K in Ks:
                b = baseline_by_K[K]
                if is_stab:
                    ax.errorbar(base_x, b["stab"], yerr=b.get("stab_err", 0),
                                fmt="X", ms=8, color=kcol[K], mec="k", mew=0.6, capsize=2)
                else:
                    ax.plot(base_x, b[key], "X", ms=8, color=kcol[K], mec="k", mew=0.6)
            ax.plot([], [], "X", color="0.5", mec="k", mew=0.6,
                    label="shuffled λ=0 (chance)")
        if refkey and paper_ref:
            ax.axhline(paper_ref[refkey], ls="--", color="0.4", lw=1,
                       label="paper (K=9)")
        ax.set_xscale("log")
        ticks = ([base_x] + list(X)) if baseline_by_K else list(X)
        tlabs = (["rand\n0.03", *xtl]) if baseline_by_K else xtl
        ax.set_xticks(ticks)
        ax.set_xticklabels(tlabs, fontsize=8)
        ax.xaxis.set_minor_locator(plt.NullLocator())
        ax.set_xlim((base_x if baseline_by_K else pz) / 1.6, infp * 1.6)
        ax.set_xlabel("laminar-feature weight  λ", fontsize=10)
        ax.set_ylabel(ylabel, fontsize=10)
        ax.set_title(title, fontsize=11, fontweight="bold", loc="left")
        if is_stab:
            ax.set_ylim(0, 1.02)
        for sp in ("top", "right"):
            ax.spines[sp].set_visible(False)
        ax.legend(fontsize=7, frameon=False, ncol=2)
    fig.suptitle("Cluster-quality metrics vs λ — overlaid across K (3, 5, 7, 9)",
                 fontsize=13, fontweight="bold")
    fig.tight_layout(rect=[0, 0, 1, 0.96])
    return fig


def plot_metrics(weights, stab, stab_err, wspread, dspread, didiff,
                 paper_ref=None, suptitle=None):
    """paper_ref: optional dict with keys 'wspread','dspread','didiff' for the
    published-clustering reference lines."""
    fig, axes = plt.subplots(2, 2, figsize=(11, 8))
    # map weights (which may include inf) to x positions on a symlog axis;
    # inf (position-only) is placed just past the largest finite weight.
    finite = [w for w in weights if np.isfinite(w)]
    inf_x = max(finite) * 2 if finite else 1.0
    x = np.array([w if np.isfinite(w) else inf_x for w in weights], float)
    xtl = [("∞" if not np.isfinite(w) else f"{w:g}") for w in weights]

    def style(ax, ylabel, title):
        ax.set_xlabel("laminar-feature weight  λ", fontsize=10)
        ax.set_ylabel(ylabel, fontsize=10)
        ax.set_title(title, fontsize=11, fontweight="bold", loc="left")
        ax.set_xscale("symlog", linthresh=0.1)
        ax.set_xticks(x)
        ax.set_xticklabels(xtl, fontsize=8)
        for sp in ("top", "right"):
            ax.spines[sp].set_visible(False)

    ax = axes[0, 0]
    ax.errorbar(x, stab, yerr=stab_err, fmt="-o", color="#1f77b4", capsize=3)
    ax.set_ylim(0, 1.02)
    style(ax, "mean pairwise ARI (subsample)", "A  Cluster stability (↑ better)")

    ax = axes[0, 1]
    ax.plot(x, wspread, "-o", color="#9d0208")
    if paper_ref:
        ax.axhline(paper_ref["wspread"], ls="--", color="0.5", lw=1,
                   label="paper clustering")
        ax.legend(fontsize=8, frameon=False)
    style(ax, "within-cluster waveform RMS", "B  Waveform spread (↑ = less shape-coherent)")

    ax = axes[1, 0]
    ax.plot(x, dspread, "-o", color="#2e7d32")
    if paper_ref:
        ax.axhline(paper_ref["dspread"], ls="--", color="0.5", lw=1,
                   label="paper clustering")
        ax.legend(fontsize=8, frameon=False)
    style(ax, "within-cluster depth std (um)", "C  Depth spread (↓ = more laminar)")

    ax = axes[1, 1]
    ax.plot(x, didiff, "-o", color="#6a1b9a")
    if paper_ref:
        ax.axhline(paper_ref["didiff"], ls="--", color="0.5", lw=1,
                   label="paper clustering")
        ax.legend(fontsize=8, frameon=False)
    style(ax, "size-weighted std of per-cluster mean DI",
          "D  Direction-selectivity differentiation (size-weighted)")

    fig.suptitle(suptitle or "Cluster-quality metrics vs laminar-feature weight λ",
                 fontsize=13, fontweight="bold")
    fig.tight_layout(rect=[0, 0, 1, 0.96])
    return fig
