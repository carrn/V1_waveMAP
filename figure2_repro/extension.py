"""
EXTENSION to Figure 2 of Carr et al. 2025: add a new *feature type* to WaveMAP.

The paper clusters neurons purely on waveform shape.  Here we add the neuron's
laminar position as an extra input feature and re-run the WaveMAP pipeline on
the same 606 neurons used in the paper.

Laminar position
----------------
A normalized cortical-depth coordinate in [-1, +1]:
    -1  = topmost of layer 1 (superficial / pia)
    +1  = bottommost of layer 6 (deep / white-matter boundary)
computed from each neuron's scaled depth (distance from layer 4, in microns)
and the anatomical layer extents reported in the authors' code
(LAYER_TOP = 1039.4 um, LAYER_BOTTOM = -990 um):

    position = clip( 1 - 2 * (depth - BOTTOM) / (TOP - BOTTOM), -1, 1 )

Feature vector
--------------
    [ 52 normalized waveform samples ,  w * laminar_position ]
where w weights the new feature relative to waveform shape.  w = 1 (the literal
"add one feature" case) is the headline; a weight sweep shows the trend.

Run:  uv run python extension.py
"""
import os
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.gridspec import GridSpec
from sklearn.metrics import adjusted_rand_score

from common import (seed_everything, load_neg_waveforms, load_clusterfn,
                    match_published_clusters, run_umap, louvain_clusters,
                    CUSTOM_PAL, LAYER_TOP, LAYER_BOTTOM, RESOLUTION)

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "output")
os.makedirs(OUT, exist_ok=True)

PALETTE = CUSTOM_PAL + ["#777777", "#cccccc", "#000000", "#e377c2"]
PRIMARY_WEIGHT = 1.0
WEIGHTS = [1, 3, 5, 8, 12]


def laminar_position(depth_scaled):
    """Normalized cortical depth in [-1, +1] (top of L1 = -1, bottom of L6 = +1)."""
    return np.clip(1 - 2 * (depth_scaled - LAYER_BOTTOM) / (LAYER_TOP - LAYER_BOTTOM),
                   -1.0, 1.0)


def load_606():
    """The 606 paper neurons (visually responsive, valid laminar depth)."""
    seed_everything()
    data = load_neg_waveforms()
    cfn = load_clusterfn()
    pub = match_published_clusters(data, cfn)
    sel = (pub > 0) & np.isfinite(data["depth_scaled"])
    assert sel.sum() == 606, sel.sum()
    return {
        "waveforms": data["waveforms"][sel],
        "depth_scaled": data["depth_scaled"][sel],
        "position": laminar_position(data["depth_scaled"][sel]),
        "published": pub[sel],
    }


def cluster(features, seed_reset=True):
    if seed_reset:
        seed_everything()
    emb, graph = run_umap(features)
    lab = louvain_clusters(graph, resolution=RESOLUTION)
    return emb, lab


def within_cluster_pos_std(labels, pos):
    return float(np.mean([pos[labels == c].std() for c in set(labels)]))


def scatter(ax, emb, c, title, cmap=None, palette=False, cbar_label=None):
    if palette:
        cols = np.array(PALETTE)[c % len(PALETTE)]
        sc = ax.scatter(emb[:, 0], emb[:, 1], c=cols, s=20, edgecolor="w", linewidth=0.3)
    else:
        sc = ax.scatter(emb[:, 0], emb[:, 1], c=c, cmap=cmap, s=20,
                        edgecolor="w", linewidth=0.3, vmin=-1, vmax=1)
        cb = ax.figure.colorbar(sc, ax=ax, fraction=0.046, pad=0.04)
        if cbar_label:
            cb.set_label(cbar_label, fontsize=8)
        cb.ax.tick_params(labelsize=7)
    for sp in ax.spines.values():
        sp.set_visible(False)
    ax.set_xticks([]); ax.set_yticks([])
    ax.set_title(title, loc="left", fontsize=10, fontweight="bold")


def main():
    d = load_606()
    wf, pos, pub = d["waveforms"], d["position"], d["published"]
    print(f"N = {len(pos)} neurons (the paper's 606)")
    print(f"laminar position range: [{pos.min():.2f}, {pos.max():.2f}]  "
          f"std {pos.std():.3f};  per-sample waveform std ~ {wf.std(0).mean():.3f}")

    # baseline: waveform shape only (on the same 606)
    emb_b, lab_b = cluster(wf)
    base_pos_std = within_cluster_pos_std(lab_b, pos)
    print(f"\nBaseline (waveform only):     {len(set(lab_b))} clusters, "
          f"within-cluster pos-std {base_pos_std:.3f}, "
          f"ARI vs published {adjusted_rand_score(pub, lab_b):.3f}")

    # extension: waveform + laminar position
    feat = np.column_stack([wf, PRIMARY_WEIGHT * pos])
    emb_e, lab_e = cluster(feat)
    ext_pos_std = within_cluster_pos_std(lab_e, pos)
    print(f"Extended (waveform+position): {len(set(lab_e))} clusters, "
          f"within-cluster pos-std {ext_pos_std:.3f}, "
          f"ARI vs baseline {adjusted_rand_score(lab_b, lab_e):.3f}")

    # weight sweep
    print("\nWeight sweep (laminar feature weight w):")
    sweep = []
    for w in WEIGHTS:
        _, lab = cluster(np.column_stack([wf, w * pos]))
        sweep.append((w, len(set(lab)), within_cluster_pos_std(lab, pos),
                      adjusted_rand_score(lab_b, lab)))
        print(f"  w={w:2d}: {sweep[-1][1]} clusters, within-cluster pos-std "
              f"{sweep[-1][2]:.3f}, ARI vs baseline {sweep[-1][3]:.3f}")
    sweep = np.array(sweep)

    # ---------------- figure ----------------
    fig = plt.figure(figsize=(15, 9))
    gs = GridSpec(2, 3, figure=fig, hspace=0.30, wspace=0.28,
                  left=0.05, right=0.96, top=0.90, bottom=0.08)

    scatter(fig.add_subplot(gs[0, 0]), emb_b, lab_b,
            f"A  Baseline WaveMAP (waveform only)\n{len(set(lab_b))} clusters, 606 neurons",
            palette=True)
    scatter(fig.add_subplot(gs[0, 1]), emb_e, lab_e,
            f"B  Extended (waveform + laminar position, w={PRIMARY_WEIGHT:g})\n"
            f"{len(set(lab_e))} clusters",
            palette=True)
    scatter(fig.add_subplot(gs[0, 2]), emb_e, pos,
            "C  Extended UMAP, colored by laminar position",
            cmap="PiYG_r", cbar_label="laminar position (-1 top L1 .. +1 bottom L6)")

    # Panel D: weight sweep
    axd = fig.add_subplot(gs[1, 0])
    axd.axhline(base_pos_std, ls="--", color="gray", lw=1,
                label="baseline (no position)")
    axd.plot(sweep[:, 0], sweep[:, 2], "-o", color="#9d0208", ms=4)
    axd.set_xlabel("laminar-feature weight w", fontsize=9)
    axd.set_ylabel("within-cluster position std\n(lower = more laminar)", fontsize=9)
    axd.set_title("D  Clusters get more laminar with w", loc="left",
                  fontsize=10, fontweight="bold")
    axd.legend(fontsize=7, frameon=False)
    for sp in ("top", "right"):
        axd.spines[sp].set_visible(False)

    # Panel E: per-cluster depth distributions (extended)
    axe = fig.add_subplot(gs[1, 1])
    order = sorted(set(lab_e), key=lambda c: np.median(pos[lab_e == c]))
    data_box = [pos[lab_e == c] for c in order]
    bp = axe.boxplot(data_box, vert=False, patch_artist=True, widths=0.6,
                     showfliers=False)
    for patch, c in zip(bp["boxes"], order):
        patch.set_facecolor(PALETTE[c % len(PALETTE)]); patch.set_alpha(0.8)
    for med in bp["medians"]:
        med.set_color("k")
    axe.set_yticks(range(1, len(order) + 1))
    axe.set_yticklabels([f"c{c}" for c in order], fontsize=7)
    axe.set_xlabel("laminar position", fontsize=9)
    axe.set_xlim(-1.05, 1.05)
    axe.set_title("E  Per-cluster laminar position (extended)", loc="left",
                  fontsize=10, fontweight="bold")
    for sp in ("top", "right"):
        axe.spines[sp].set_visible(False)

    # Panel F: feature-definition schematic
    axf = fig.add_subplot(gs[1, 2])
    axf.scatter(pos, d["depth_scaled"], c=pos, cmap="PiYG_r", s=12,
                vmin=-1, vmax=1)
    axf.set_xlabel("laminar position (normalized)", fontsize=9)
    axf.set_ylabel("scaled depth (um, dist. from L4)", fontsize=9)
    axf.set_title("F  New feature: laminar position\n(-1 top L1 .. +1 bottom L6)",
                  loc="left", fontsize=10, fontweight="bold")
    for b in [588.8, 285.4, 0.0, -488.0]:
        axf.axhline(b, ls=":", color="gray", lw=0.7)
    for sp in ("top", "right"):
        axf.spines[sp].set_visible(False)

    fig.suptitle("Figure 2 extension — adding laminar position as a WaveMAP feature "
                 "(606 neurons)", fontsize=13, fontweight="bold")
    out = os.path.join(OUT, "figure2_extension.png")
    fig.savefig(out, dpi=200)
    print(f"\nsaved {out}")


if __name__ == "__main__":
    main()
