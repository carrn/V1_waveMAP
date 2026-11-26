"""
Reproduce Figure 2 of Carr et al. 2025 (PNAS / bioRxiv 2025.05.14.653875):
"UMAP and Louvain Clustering on 801 negative spiking waveforms reveals
9 candidate cell types."

Panels:
  A  UMAP scatter colored by Louvain cluster (resolution 1.0) + per-cluster
     member/average waveforms (9 candidate cell types: NS1-4, BS1-4, TP-1).
  B  Louvain resolution vs modularity and number of clusters; dashed line at
     the resolution of maximum modularity.
  C  Confusion matrix of a gradient-boosted-tree classifier (5-fold CV).
  D  UMAP at the higher resolution (2.5) showing clusters merging.

Run:  uv run python figure2.py
"""
import os
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.gridspec import GridSpec

from common import (seed_everything, load_neg_waveforms, load_clusterfn,
                    match_published_clusters, run_umap, louvain_clusters,
                    CUSTOM_PAL, RAND_STATE, RESOLUTION)
import louvain as lv

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "output")
os.makedirs(OUT, exist_ok=True)

# Display order + cell-type grouping (from the authors' notebook).
# NS (narrow-spiking, cool) = clusters 0,1,5,7 ; BS (broad-spiking, warm) =
# 2,3,4,8 ; TP (tri-phasic, green) = 6.   (0-indexed; published id = idx+1.)
HUE_ORDER = [0, 1, 7, 5, 6, 2, 8, 4, 3]
GROUP = {0: "NS", 1: "NS", 5: "NS", 7: "NS",
         6: "TP",
         2: "BS", 3: "BS", 4: "BS", 8: "BS"}


def cell_type_names(labels):
    """Assign NS1-4 / BS1-4 / TP-1 names following the paper's grouping."""
    counters = {"NS": 0, "BS": 0, "TP": 0}
    names = {}
    for c in HUE_ORDER:
        g = GROUP[c]
        counters[g] += 1
        names[c] = f"{g}{counters[g]}" if g != "TP" else "TP-1"
    return names


# ---------------------------------------------------------------------------
# Compute the embedding + clustering once (shared by all panels)
# ---------------------------------------------------------------------------
def compute():
    seed_everything()
    data = load_neg_waveforms()
    cfn = load_clusterfn()
    pub = match_published_clusters(data, cfn)
    emb, graph = run_umap(data["waveforms"])
    lab = louvain_clusters(graph, resolution=RESOLUTION)
    return data, pub, emb, graph, lab


# ---------------------------------------------------------------------------
# Panel A
# ---------------------------------------------------------------------------
def panel_A(fig, gs, data, emb, lab, names):
    wf = data["waveforms"]
    nsamp = wf.shape[1]
    xt = [0, 15, 30, 45]          # 30 kHz -> 0, 0.5, 1.0, 1.5 ms
    xtl = ["0", "0.5", "1.0", "1.5"]

    # Sub-gridspec: big scatter on the left, 3x3 waveform grid on the right.
    sub = gs.subgridspec(1, 2, width_ratios=[1.25, 1.0], wspace=0.18)
    ax = fig.add_subplot(sub[0, 0])
    colors = np.array(CUSTOM_PAL)[lab]
    ax.scatter(emb[:, 0], emb[:, 1], marker="o", c=colors, s=22,
               edgecolor="w", linewidth=0.4)
    for sp in ax.spines.values():
        sp.set_visible(False)
    ax.set_xticks([]); ax.set_yticks([])
    x0, y0 = emb[:, 0].min() - 1, emb[:, 1].min() - 1
    dx = (emb[:, 0].max() - emb[:, 0].min()) * 0.12
    dy = (emb[:, 1].max() - emb[:, 1].min()) * 0.12
    ax.annotate("", xy=(x0 + dx, y0), xytext=(x0, y0),
                arrowprops=dict(arrowstyle="-|>", color="k"))
    ax.annotate("", xy=(x0, y0 + dy), xytext=(x0, y0),
                arrowprops=dict(arrowstyle="-|>", color="k"))
    ax.text(x0 + dx * 0.5, y0 - dy * 0.45, "UMAP 1", ha="center", va="top", fontsize=9)
    ax.text(x0 - dx * 0.35, y0 + dy * 0.5, "UMAP 2", ha="right", va="center",
            rotation=90, fontsize=9)
    ax.set_title("A   801 negative-spiking waveforms\n9 candidate cell types",
                 loc="left", fontsize=11, fontweight="bold")

    wgrid = sub[0, 1].subgridspec(3, 3, hspace=0.55, wspace=0.35)
    n_total = len(lab)
    for pos, c in enumerate(HUE_ORDER):
        r, col = divmod(pos, 3)
        a = fig.add_subplot(wgrid[r, col])
        ixs = np.where(lab == c)[0]
        grp = wf[ixs]
        for w in grp:
            a.plot(w, c=CUSTOM_PAL[c], alpha=0.15, linewidth=0.5)
        a.plot(grp.mean(0), c="k", linewidth=1.2)
        a.set_ylim(-1.3, 1.3)
        for sp in ("right", "top"):
            a.spines[sp].set_visible(False)
        a.set_yticks([])
        a.set_xticks(xt); a.set_xticklabels([])
        a.set_xlim(0, nsamp)
        pct = 100 * len(ixs) / n_total
        a.set_title(f"{names[c]}  (n={len(ixs)}, {pct:.1f}%)", fontsize=7.5,
                    color=CUSTOM_PAL[c], fontweight="bold")
        if r == 2:
            a.set_xticklabels(xtl, fontsize=6)
            a.set_xlabel("ms", fontsize=6, labelpad=1)


# ---------------------------------------------------------------------------
# Panel B  - resolution vs modularity & n_clusters
# ---------------------------------------------------------------------------
def panel_B(fig, gs, graph):
    res_vals = np.round(np.arange(0.4, 3.01, 0.1), 2)
    mods, ncl = [], []
    for res in res_vals:
        part = lv.best_partition(graph, resolution=res)
        plist = [part[i] for i in range(graph.shape[0])]
        mods.append(lv.python_modularity(plist, graph, resolution=1.0))
        ncl.append(len(set(plist)))
    mods, ncl = np.array(mods), np.array(ncl)
    best = res_vals[np.argmax(mods)]

    ax = fig.add_subplot(gs)
    ax.plot(res_vals, mods, "-o", color="#333333", ms=3, label="modularity")
    ax.set_xlabel("Louvain resolution", fontsize=9)
    ax.set_ylabel("Modularity", fontsize=9, color="#333333")
    ax.axvline(best, ls="--", color="k", lw=1)
    ax2 = ax.twinx()
    ax2.plot(res_vals, ncl, "-s", color="#1f77b4", ms=3, label="# clusters")
    ax2.set_ylabel("# clusters", fontsize=9, color="#1f77b4")
    ax2.tick_params(axis="y", colors="#1f77b4")
    # mark resolution 1.0 (Panel A) and 2.5 (Panel D)
    for rr in (1.0, 2.5):
        k = np.argmin(np.abs(res_vals - rr))
        ax2.annotate(f"{int(ncl[k])}", (rr, ncl[k]), fontsize=7,
                     textcoords="offset points", xytext=(0, 5), ha="center",
                     color="#1f77b4")
    ax.set_title("B   Resolution sweep", loc="left", fontsize=11, fontweight="bold")
    for sp in ("top",):
        ax.spines[sp].set_visible(False); ax2.spines[sp].set_visible(False)
    return best


# ---------------------------------------------------------------------------
# Panel C  - gradient-boosted-tree confusion matrix (5-fold CV)
# ---------------------------------------------------------------------------
def panel_C(fig, gs, data, lab, names):
    import xgboost as xgb
    from sklearn.model_selection import train_test_split, GridSearchCV
    from sklearn.metrics import confusion_matrix

    X = data["waveforms"]
    y = lab.copy()
    Xtr, Xte, ytr, yte = train_test_split(X, y, test_size=0.3,
                                          random_state=RAND_STATE, stratify=y)
    model = xgb.XGBClassifier(eval_metric="mlogloss")
    grid = GridSearchCV(model, param_grid={
        "max_depth": [4], "min_child_weight": [2.5], "n_estimators": [100],
        "learning_rate": [0.3], "seed": [RAND_STATE]},
        cv=5, n_jobs=-1)
    grid.fit(Xtr, ytr)
    yhat = grid.predict(Xte)
    order = HUE_ORDER
    cm = confusion_matrix(yte, yhat, labels=order).astype(float)
    cmn = cm / cm.sum(1, keepdims=True)
    acc = np.trace(cm) / cm.sum()

    ax = fig.add_subplot(gs)
    cmap = plt.cm.YlGnBu.copy(); cmap.set_under("w")
    im = ax.imshow(cmn, cmap=cmap, vmin=np.spacing(0.0), vmax=1.0)
    cb = fig.colorbar(im, ax=ax, extend="min", fraction=0.046, pad=0.04)
    cb.set_label("P(Predicted | True)", fontsize=8)
    cb.ax.tick_params(labelsize=7)
    nC = len(order)
    for i in range(nC):
        for j in range(nC):
            v = cmn[i, j]
            if v > 0:
                ax.text(j, i, f"{int(round(v*100))}", ha="center", va="center",
                        fontsize=6, color="white" if v > 0.5 else "k")
    labs = [names[c] for c in order]
    ax.set_xticks(range(nC)); ax.set_xticklabels(labs, fontsize=6, rotation=90)
    ax.set_yticks(range(nC)); ax.set_yticklabels(labs, fontsize=6)
    ax.set_xlabel("Predicted", fontsize=9); ax.set_ylabel("True", fontsize=9)
    ax.set_title(f"C   GBT classifier ({acc*100:.0f}% acc.)", loc="left",
                 fontsize=11, fontweight="bold")
    return acc


# ---------------------------------------------------------------------------
# Panel D  - UMAP at resolution 2.5
# ---------------------------------------------------------------------------
def panel_D(fig, gs, emb, graph):
    lab = louvain_clusters(graph, resolution=2.5)
    ax = fig.add_subplot(gs)
    colors = np.array(CUSTOM_PAL + ["#777777", "#cccccc"])[lab % 11]
    ax.scatter(emb[:, 0], emb[:, 1], marker="o", c=colors, s=18,
               edgecolor="w", linewidth=0.3)
    for sp in ax.spines.values():
        sp.set_visible(False)
    ax.set_xticks([]); ax.set_yticks([])
    ax.set_title(f"D   UMAP, resolution 2.5  ({len(set(lab))} clusters)",
                 loc="left", fontsize=11, fontweight="bold")


def main():
    data, pub, emb, graph, lab = compute()
    names = cell_type_names(lab)

    # report
    u, c = np.unique(lab, return_counts=True)
    print(f"N waveforms: {len(lab)}   N clusters (res {RESOLUTION}): {len(u)}")
    from sklearn.metrics import adjusted_rand_score
    m = pub > 0
    print(f"ARI vs published labels (606/607 vis-responsive subset): "
          f"{adjusted_rand_score(pub[m], lab[m]):.3f}")

    fig = plt.figure(figsize=(15, 9))
    gs = GridSpec(2, 3, figure=fig, height_ratios=[1.15, 1.0],
                  hspace=0.32, wspace=0.30,
                  left=0.05, right=0.97, top=0.93, bottom=0.07)
    panel_A(fig, gs[0, :], data, emb, lab, names)
    best = panel_B(fig, gs[1, 0], graph)
    acc = panel_C(fig, gs[1, 1], data, lab, names)
    panel_D(fig, gs[1, 2], emb, graph)
    fig.suptitle("Figure 2 (reproduced) — Carr et al. 2025, monkey V1 WaveMAP",
                 fontsize=13, fontweight="bold")
    out = os.path.join(OUT, "figure2.png")
    fig.savefig(out, dpi=200)
    print(f"max-modularity resolution: {best}   classifier accuracy: {acc*100:.1f}%")
    print(f"saved {out}")


if __name__ == "__main__":
    main()
