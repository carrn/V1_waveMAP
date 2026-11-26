"""
Reproduce Figure 3 (laminar / density distribution of candidate cell types) and
Figure 4 (direction selectivity and amplitude) from Carr et al. 2025.

Both figures now lead with a per-cluster mean-spike strip (faint member waveforms
+ bold mean), as in the paper's Figure 2A, with clusters grouped/ordered into
narrow-spiking (NS), tri-phasic (TP) and broad-spiking (BS).

Each plotting function takes a per-neuron table `df` (RangeIndex) with columns:
    clab, depth_scaled, DI, Amp, TPdur, depth_bin
plus `wf` (an N x n_samples array of normalized waveforms aligned to df rows),
an ordered list of cluster ids `order`, a {clab: name} dict, and a
{clab: hex-color} palette.  Functional metrics are the experimental measurements;
only `clab` differs between the paper and the laminar-extension cases.
"""
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.gridspec import GridSpec
from matplotlib.lines import Line2D
from scipy.stats import gaussian_kde

from common import (LAYER_BOUNDS, LAYER_CENTERS, LAYER_BIN_NAMES, LAYER_BIN_ORDER)

DEPTH_LIM = (-1000, 1050)
WAVE_XT = [0, 15, 30, 45]          # 30 kHz -> 0, 0.5, 1.0, 1.5 ms
WAVE_XTL = ["0", "0.5", "1.0", "1.5"]


def _layer_lines(ax, style="--", lw=0.8, color="k"):
    for b in LAYER_BOUNDS:
        ax.axhline(b, ls=style, lw=lw, color=color, zorder=0)


def _layer_labels(ax, x):
    for name, y in LAYER_CENTERS.items():
        ax.text(x, y, name, fontsize=6, va="center", ha="left", color="0.4")


def _size_from(values, lo=8, hi=180):
    v = np.asarray(values, float)
    vmin, vmax = np.nanmin(v), np.nanmax(v)
    if vmax <= vmin:
        return np.full_like(v, (lo + hi) / 2)
    return lo + (v - vmin) / (vmax - vmin) * (hi - lo)


def _draw_wave(ax, waves, color, title, show_x=False):
    nsamp = waves.shape[1]
    for w in waves:
        ax.plot(w, color=color, alpha=0.12, lw=0.4)
    ax.plot(waves.mean(0), color="k", lw=1.3)
    ax.set_ylim(-1.3, 1.3)
    ax.set_xlim(0, nsamp)
    ax.set_yticks([])
    ax.set_xticks(WAVE_XT)
    ax.set_xticklabels(WAVE_XTL if show_x else [], fontsize=6)
    for sp in ("top", "right", "left"):
        ax.spines[sp].set_visible(False)
    ax.set_title(title, fontsize=7.5, color=color, fontweight="bold", pad=2)


def _wave_title(names, counts, c):
    nm = names.get(c, f"c{c}")
    return f"{nm}  n={counts[c]}" if counts and c in counts else nm


# ---------------------------------------------------------------------------
# Figure 3
# ---------------------------------------------------------------------------
def make_figure3(df, wf, order, names, palette, suptitle, counts=None):
    n = len(order)
    fig = plt.figure(figsize=(13, 7.6))
    outer = GridSpec(2, 1, height_ratios=[0.85, 3.0], hspace=0.42,
                     left=0.06, right=0.97, top=0.90, bottom=0.10)

    # ---- top: per-cluster mean spike + shapes (NS -> TP -> BS) ----
    wgs = outer[0, 0].subgridspec(1, n, wspace=0.3)
    for j, c in enumerate(order):
        ax = fig.add_subplot(wgs[0, j])
        _draw_wave(ax, wf[(df.clab == c).values], palette[c],
                   _wave_title(names, counts, c), show_x=(j == 0))
    fig.text(0.06, 0.915, "mean spike & shapes (NS → TP → BS)",
             fontsize=9, style="italic", color="0.3")

    main = outer[1, 0].subgridspec(1, 3, width_ratios=[1.0, 2.4, 1.0], wspace=0.28)

    # ---- left: depth density per cluster ----
    axk = fig.add_subplot(main[0, 0])
    yy = np.linspace(DEPTH_LIM[0], DEPTH_LIM[1], 200)
    for c in order:
        d = df.loc[df.clab == c, "depth_scaled"].dropna().values
        if len(d) < 3:
            continue
        kde = gaussian_kde(d, bw_method=0.4)
        axk.plot(kde(yy), yy, color=palette[c], lw=1.4, label=names.get(c, f"c{c}"))
    _layer_lines(axk)
    axk.set_ylim(*DEPTH_LIM)
    axk.set_xlabel("density (a.u.)", fontsize=9)
    axk.set_ylabel("distance from layer 4 (um)", fontsize=9)
    axk.set_xticks([])
    axk.set_title("density distribution", fontsize=10)
    axk.legend(fontsize=6, loc="lower right", frameon=False, ncol=1)
    for sp in ("top", "right"):
        axk.spines[sp].set_visible(False)

    # ---- center: laminar scatter per cluster, marker size ~ waveform width ----
    axc = fig.add_subplot(main[0, 1])
    rng = np.random.default_rng(0)
    width = df["TPdur"].values
    wpos = width - np.nanmin(width) + 1e-3
    for slot, c in enumerate(order):
        m = df.clab == c
        y = df.loc[m, "depth_scaled"].values
        s = _size_from(wpos[m.values], lo=6, hi=90)
        x = slot + rng.uniform(-0.32, 0.32, size=len(y))
        axc.scatter(x, y, s=s, c=palette[c], alpha=0.75, edgecolor="w", linewidth=0.2)
        wv = df.loc[m, "TPdur"].dropna()
        axc.text(slot, DEPTH_LIM[1] + 20, f"{wv.mean():.2f}\n±{wv.std():.2f}",
                 fontsize=6, ha="center", va="bottom", color=palette[c])
    _layer_lines(axc)
    _layer_labels(axc, len(order) - 0.4)
    axc.set_xticks(range(len(order)))
    axc.set_xticklabels([names.get(c, f"c{c}") for c in order], fontsize=7, rotation=45)
    axc.set_ylim(*DEPTH_LIM)
    axc.set_xlim(-0.7, len(order) - 0.1)
    axc.set_ylabel("distance from layer 4 (um)", fontsize=9)
    axc.set_title("laminar location per cluster   (marker size ~ waveform width)",
                  fontsize=10)
    for sp in ("top", "right"):
        axc.spines[sp].set_visible(False)

    # ---- right: per-layer composition ----
    axr = fig.add_subplot(main[0, 2])
    layer_cols = {4: "#E8D652", 3: "#6ABD45", 2: "#3953A4", 1: "#B9529F"}
    for slot, c in enumerate(order):
        sub = df.loc[df.clab == c, "depth_bin"].dropna()
        nn = len(sub)
        bottom = 0.0
        for lb in LAYER_BIN_ORDER:
            frac = (sub == lb).sum() / nn * 100 if nn else 0
            axr.bar(slot, frac, bottom=bottom, color=layer_cols[lb], width=0.8,
                    edgecolor="w", linewidth=0.3)
            bottom += frac
    axr.set_xticks(range(len(order)))
    axr.set_xticklabels([names.get(c, f"c{c}") for c in order], fontsize=7, rotation=45)
    axr.set_ylabel("% of units in layer", fontsize=9)
    axr.set_ylim(0, 100)
    axr.set_title("laminar composition", fontsize=10)
    axr.legend(handles=[Line2D([0], [0], color=layer_cols[lb], lw=6,
                               label=LAYER_BIN_NAMES[lb]) for lb in LAYER_BIN_ORDER],
               fontsize=6, frameon=False, loc="upper right")
    for sp in ("top", "right"):
        axr.spines[sp].set_visible(False)

    fig.suptitle(suptitle, fontsize=12, fontweight="bold")
    return fig


# ---------------------------------------------------------------------------
# Figure 4
# ---------------------------------------------------------------------------
def _shuffle_bounds(df, order, n_shuffle=500, seed=0):
    rng = np.random.default_rng(seed)
    di = df["DI"].values
    amp = df["Amp"].values
    labels = df["clab"].values
    medD = np.full((n_shuffle, len(order)), np.nan)
    medA = np.full((n_shuffle, len(order)), np.nan)
    for k in range(n_shuffle):
        sl = rng.permutation(labels)
        for j, c in enumerate(order):
            mask = sl == c
            if mask.any():
                medD[k, j] = np.nanmedian(di[mask])
                medA[k, j] = np.nanmedian(amp[mask])
    dlo, dhi = np.nanpercentile(medD, [2.5, 97.5], axis=0)
    alo, ahi = np.nanpercentile(medA, [2.5, 97.5], axis=0)
    return (np.median(dlo), np.median(dhi)), (np.median(alo), np.median(ahi))


def make_figure4(df, wf, order, names, palette, suptitle, counts=None):
    n = len(order)
    fig = plt.figure(figsize=(15, 10))
    outer = GridSpec(2, 1, height_ratios=[1.35, 1.0], hspace=0.30,
                     left=0.05, right=0.97, top=0.90, bottom=0.07)

    # ===== Panel A: mean spike + DI histogram + DI-vs-depth scatter per cluster =====
    topgs = outer[0, 0].subgridspec(3, n, height_ratios=[0.9, 0.9, 2.4],
                                    hspace=0.18, wspace=0.25)
    edges = np.linspace(0, 1, 6)
    for j, c in enumerate(order):
        ax_w = fig.add_subplot(topgs[0, j])
        _draw_wave(ax_w, wf[(df.clab == c).values], palette[c],
                   _wave_title(names, counts, c))

        di = df.loc[df.clab == c, "DI"].dropna().values
        ax_h = fig.add_subplot(topgs[1, j])
        ax_h.hist(di, bins=edges, density=True, color=palette[c], alpha=0.85)
        ax_h.axvline(0.5, ls="--", lw=0.7, color="k")
        if len(di):
            ax_h.axvline(np.median(di), ls="-", lw=1.3, color="k")
        ax_h.set_xlim(0, 1); ax_h.set_xticks([0, 0.5, 1]); ax_h.set_yticks([])
        ax_h.tick_params(labelsize=6)
        for sp in ("top", "right", "left"):
            ax_h.spines[sp].set_visible(False)

        ax_s = fig.add_subplot(topgs[2, j])
        m = df.clab == c
        s = _size_from(df.loc[m, "Amp"].values, lo=4, hi=70)
        ax_s.scatter(df.loc[m, "DI"], df.loc[m, "depth_scaled"], s=s,
                     c=palette[c], alpha=0.7, edgecolor="w", linewidth=0.2)
        for b in LAYER_BOUNDS:
            ax_s.axhline(b, ls="-", lw=0.6, color="0.6", zorder=0)
        ax_s.axvline(0.5, ls="--", lw=0.7, color="k")
        ax_s.set_xlim(0, 1); ax_s.set_ylim(*DEPTH_LIM)
        ax_s.set_xticks([0, 0.5, 1]); ax_s.tick_params(labelsize=6)
        if j == 0:
            ax_s.set_ylabel("dist. from L4 (um)", fontsize=8)
        else:
            ax_s.set_yticklabels([])
        if j == n // 2:
            ax_s.set_xlabel("direction selectivity index", fontsize=9)
        for sp in ("top", "right"):
            ax_s.spines[sp].set_visible(False)
    fig.text(0.05, 0.915, "A  Mean spike, direction-selectivity histogram & "
             "DI-vs-depth (marker size ~ amplitude; bold line = median DI)",
             fontsize=11, fontweight="bold")

    # ===== bottom: B amplitude heatmap, C median DI vs amp =====
    botgs = outer[1, 0].subgridspec(1, 2, width_ratios=[1.3, 1.0], wspace=0.28)

    axb = fig.add_subplot(botgs[0, 0])
    layers = LAYER_BIN_ORDER
    M = np.full((n, len(layers)), np.nan)
    for i, c in enumerate(order):
        for k, lb in enumerate(layers):
            mask = (df.clab == c) & (df.depth_bin == lb)
            if mask.any():
                M[i, k] = np.nanmedian(df.loc[mask, "Amp"])
    im = axb.imshow(M, aspect="auto", cmap="magma")
    fig.colorbar(im, ax=axb, fraction=0.046, pad=0.04).set_label(
        "median amplitude (uV)", fontsize=8)
    axb.set_xticks(range(len(layers)))
    axb.set_xticklabels([LAYER_BIN_NAMES[lb] for lb in layers], fontsize=7)
    axb.set_yticks(range(n))
    axb.set_yticklabels([names.get(c, f"c{c}") for c in order], fontsize=7)
    axb.set_title("B  Amplitude by cluster x layer", fontsize=11, fontweight="bold",
                  loc="left")

    axc = fig.add_subplot(botgs[0, 1])
    boundsD, boundsA = _shuffle_bounds(df, order, n_shuffle=500)
    for c in order:
        m = df.clab == c
        amp = df.loc[m, "Amp"].dropna()
        di = df.loc[m, "DI"].dropna()
        mA, mD = amp.median(), di.median()
        eA = amp.std() / np.sqrt(len(amp)) if len(amp) else 0
        eD = di.std() / np.sqrt(len(di)) if len(di) else 0
        axc.errorbar(mA, mD, xerr=eA, yerr=eD, fmt="o", color=palette[c], ms=6, capsize=2)
        axc.annotate(names.get(c, f"c{c}"), (mA, mD), fontsize=6,
                     textcoords="offset points", xytext=(4, 4))
    for b in boundsA:
        axc.axvline(b, ls="--", lw=0.8, color="0.5")
    for b in boundsD:
        axc.axhline(b, ls="--", lw=0.8, color="0.5")
    axc.set_xlabel("median amplitude (uV)", fontsize=9)
    axc.set_ylabel("median direction index", fontsize=9)
    axc.set_title("C  Median DI vs amplitude (dashed = shuffle 2.5/97.5%)",
                  fontsize=11, fontweight="bold", loc="left")
    for sp in ("top", "right"):
        axc.spines[sp].set_visible(False)

    fig.suptitle(suptitle, fontsize=12, fontweight="bold")
    return fig
