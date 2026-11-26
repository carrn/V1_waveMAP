"""
Reproduce Figures 3 and 4 (laminar distribution; direction selectivity & amplitude)
for the paper clusters AND for the laminar-position extension, swept over the
laminar-feature weight lambda, and repeated for several cluster counts
K in {3, 5, 7, 9}.  Everything is assembled into one HTML page grouped by K.

Functional metrics (direction index, amplitude, waveform width, depth, layer) are
the experimental measurements (identical across cases); only the cluster label
changes.  Each figure leads with the per-cluster mean spike (with the unit count
shown next to the name).  Clusters are classified by shape into narrow-spiking
(NS, cool), tri-phasic (TP, green) and broad-spiking (BS, warm) and grouped
NS -> TP -> BS, ordered top->bottom by median depth within group.

Forcing exactly K: Louvain on the UMAP graph does not produce fewer than ~6-8
communities at any resolution, so small K cannot be reached by resolution alone.
We use an exact Louvain resolution when one yields K, otherwise greedily merge
Louvain communities by modularity gain (CNM) down to K -- both on the same UMAP
graph.

lambda = inf  ->  features are the laminar position only (no waveform).

Run:  uv run python run_figures34.py
      uv run python run_figures34.py --weights 0 0.5 1 inf --ks 5 9
"""
import os
import argparse
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

from common import (seed_everything, waveforms_by_key, run_umap, scan_resolutions,
                    cluster_to_k, classify_shape, CUSTOM_PAL, ORDER_PUB, NAMES_PUB,
                    LAYER_TOP, LAYER_BOTTOM, WEIGHTS, KS)
from fig34 import make_figure3, make_figure4
import metrics34 as M

UMAP_SEED = 50
N_SUBSAMPLE = 8
SUBSAMPLE_FRAC = 0.85

HERE = os.path.dirname(os.path.abspath(__file__))
CSV = os.path.join(os.path.dirname(HERE), "3-GenerateFigures4-6", "cluster_data_final.csv")
OUT = os.path.join(HERE, "output")
os.makedirs(OUT, exist_ok=True)

CAT_CMAP = {"NS": plt.cm.Blues, "TP": plt.cm.Greens, "BS": plt.cm.OrRd}
CAT_GROUPS = ["NS", "TP", "BS"]


def load_table():
    df = pd.read_csv(CSV)
    df = df[(df["Vis Responsive"] == 1) & np.isfinite(df["depth_scaled"])].copy()
    df = df.rename(columns={"Direction Index": "DI", "TP Dur": "TPdur",
                            "depth_bins": "depth_bin"})
    df["session"] = df["Session"].astype(int)
    df["unit_id"] = df["ID"].astype(int)
    df = df.reset_index(drop=True)
    assert len(df) == 606, len(df)
    wbk = waveforms_by_key()
    wf = np.array([wbk[(s, i)] for s, i in zip(df.session, df.unit_id)])
    return df, wf


def laminar_position(depth_scaled):
    return np.clip(1 - 2 * (depth_scaled - LAYER_BOTTOM) / (LAYER_TOP - LAYER_BOTTOM),
                   -1.0, 1.0)


def features(wf, pos, weight):
    if not np.isfinite(weight):        # lambda = inf -> position only
        return pos[:, None]
    return wf if weight == 0 else np.column_stack([wf, weight * pos])


def build_graphs(feat):
    """UMAP fuzzy graph + resolution scan for the full data and for each
    subsample (computed ONCE per weight, reused across all K)."""
    seed_everything(UMAP_SEED)
    _, full = run_umap(feat, seed=UMAP_SEED)
    full_scan = scan_resolutions(full)
    subs = []
    n = feat.shape[0]
    for r in range(N_SUBSAMPLE):
        rng = np.random.default_rng(1000 + r)
        idx = np.sort(rng.choice(n, size=int(SUBSAMPLE_FRAC * n), replace=False))
        seed_everything(UMAP_SEED)
        _, g = run_umap(feat[idx], seed=UMAP_SEED)
        subs.append((idx, g, scan_resolutions(g)))
    return full, full_scan, subs


def categorize_order(df, wf, labels):
    """Classify each cluster's mean spike NS/TP/BS; group NS->TP->BS ordered
    top->bottom by median depth. Returns order, names, palette, counts, cats."""
    cats = {c: classify_shape(wf[labels == c].mean(0)) for c in set(labels)}
    counts = {c: int((labels == c).sum()) for c in set(labels)}
    order, names, palette = [], {}, {}
    ctr = {"NS": 0, "TP": 0, "BS": 0}
    for g in CAT_GROUPS:
        gg = sorted([c for c in set(labels) if cats[c] == g],
                    key=lambda c: -np.nanmedian(df["depth_scaled"][labels == c]))
        for j, c in enumerate(gg):
            order.append(c)
            ctr[g] += 1
            names[c] = f"{g}{ctr[g]}"
            frac = 0.45 + 0.45 * (j / max(1, len(gg) - 1))
            palette[c] = matplotlib.colors.to_hex(CAT_CMAP[g](frac))
    return order, names, palette, counts, cats


def save(fig, name):
    path = os.path.join(OUT, name)
    fig.savefig(path, dpi=120, bbox_inches="tight")
    plt.close(fig)
    return name


def wlabel(w):
    return "winf" if not np.isfinite(w) else f"w{w:g}".replace(".", "p")


def wtext(w):
    return "∞ (position only)" if not np.isfinite(w) else f"{w:g}"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--weights", type=float, nargs="+", default=WEIGHTS)
    ap.add_argument("--ks", type=int, nargs="+", default=KS)
    args = ap.parse_args()
    weights = [float(w) for w in args.weights]
    Ks = args.ks

    df, wf = load_table()
    pos = laminar_position(df["depth_scaled"].values)
    print(f"loaded {len(df)} neurons; weights={weights}; K={Ks}")

    # paper-clustering reference (published 9 labels on the same 606)
    pub = df["cluster 1.0"].astype(int).values
    paper_ref = M.paper_reference(df, wf)

    # ---- precompute UMAP graphs + scans once per weight (reused across all K) ----
    graphs = {}
    for w in weights:
        graphs[w] = build_graphs(features(wf, pos, w))
        print(f"  graphs ready for lambda={wtext(w)}")

    # ---- paper figures (published K=9), shown once ----
    pal_pub = {c: CUSTOM_PAL[c] for c in range(9)}
    cnt_pub = {c: int((pub == c).sum()) for c in range(9)}
    dfp = df.copy(); dfp["clab"] = pub
    paper_imgs = (
        save(make_figure3(dfp, wf, ORDER_PUB, NAMES_PUB, pal_pub,
                          "Figure 3 — published candidate cell types (paper, K=9)",
                          counts=cnt_pub), "fig3_paper.png"),
        save(make_figure4(dfp, wf, ORDER_PUB, NAMES_PUB, pal_pub,
                          "Figure 4 — published candidate cell types (paper, K=9)",
                          counts=cnt_pub), "fig4_paper.png"))

    # ---- per K: weight sweep + metrics ----
    kgroups = []     # (K, metrics_img, [(weight_title, subtitle, f3, f4), ...])
    metrics_by_K = {}
    for K in Ks:
        met = {k: [] for k in M.METRIC_KEYS}
        wsections = []
        for w in weights:
            full, full_scan, subs = graphs[w]
            lab, how = cluster_to_k(full, full_scan, K, prefer=1.0)
            order, names, palette, counts, cats = categorize_order(df, wf, lab)
            ncat = {g: sum(v == g for v in cats.values()) for g in CAT_GROUPS}
            comp = f"{ncat['NS']} NS, {ncat['TP']} TP, {ncat['BS']} BS"

            vals = M.clustering_metrics(df, wf, lab, subs, K)
            for k in M.METRIC_KEYS:
                met[k].append(vals[k])
            s = vals["stab"]

            dfx = df.copy(); dfx["clab"] = lab
            tag = ("waveform only" if w == 0 else
                   "position only" if not np.isfinite(w) else
                   f"waveform + {w:g}·laminar-position")
            wl = wlabel(w)
            ttl = f"K={K}, λ={wtext(w)} ({how}; {comp})"
            f3 = save(make_figure3(dfx, wf, order, names, palette,
                                   f"Figure 3 — {ttl}", counts=counts),
                      f"fig3_K{K}_{wl}.png")
            f4 = save(make_figure4(dfx, wf, order, names, palette,
                                   f"Figure 4 — {ttl}", counts=counts),
                      f"fig4_K{K}_{wl}.png")
            wsections.append((f"λ = {wtext(w)}  ({how}: {comp})", tag, f3, f4))
            print(f"  K={K} λ={wtext(w):<18} {how:<14} {comp}  stability={s:.2f}")

        fmet = save(M.plot_metrics(weights, met["stab"], met["stab_err"],
                                   met["wspread"], met["dspread"], met["didiff"],
                                   paper_ref=paper_ref,
                                   suptitle=f"Cluster-quality metrics vs λ  (K = {K})"),
                    f"metrics_K{K}.png")
        kgroups.append((K, fmet, wsections))
        metrics_by_K[K] = {k: list(v) for k, v in met.items()}

    overlay = save(M.plot_metrics_overlay(weights, metrics_by_K, paper_ref=paper_ref),
                   "metrics_overlay.png")
    write_html(paper_imgs, kgroups, overlay)


def write_html(paper_imgs, kgroups, overlay):
    def figrow(f3, f4):
        return (f'<div class="figrow">'
                f'<figure><img loading="lazy" src="{f3}"/>'
                f'<figcaption>Figure 3 — laminar &amp; density distribution</figcaption></figure>'
                f'<figure><img loading="lazy" src="{f4}"/>'
                f'<figcaption>Figure 4 — direction selectivity &amp; amplitude</figcaption></figure>'
                f'</div>')

    blocks = [f'<section id="overview"><h2>Overview — metrics overlaid across K</h2>'
              f'<p class="sub">All four quality metrics with K=3,5,7,9 overlaid. '
              f'Log λ-axis: λ=0 is drawn at the 0.0625 slot, λ=∞ (position only) just '
              f'past 16. Dashed line = published K=9 clustering.</p>'
              f'<figure style="flex:1 1 1000px"><img loading="lazy" src="{overlay}"/>'
              f'<figcaption>A stability · B waveform spread · C depth spread · '
              f'D size-weighted direction-selectivity differentiation</figcaption></figure></section>']
    blocks.append(
              f'<section id="paper"><h2>Paper clusters (published WaveMAP, K=9)</h2>'
              f'<p class="sub">Waveform-shape clustering of all 801 units; the '
              f'published labels (4 NS, 1 TP, 4 BS).</p>{figrow(*paper_imgs)}</section>')
    for K, fmet, wsections in kgroups:
        inner = [f'<section id="k{K}"><h2>K = {K} clusters</h2>'
                 f'<p class="sub">Quality metrics vs λ (paper K=9 reference dashed). '
                 f'Each clustering forced to exactly K=&nbsp;{K}.</p>'
                 f'<figure style="flex:1 1 900px"><img loading="lazy" src="{fmet}"/>'
                 f'<figcaption>A stability · B waveform spread · C depth spread · '
                 f'D size-weighted direction-selectivity differentiation</figcaption></figure></section>']
        for title, subtitle, f3, f4 in wsections:
            inner.append(f'<section><h3>K={K} · {title}</h3>'
                         f'<p class="sub">{subtitle}</p>{figrow(f3, f4)}</section>')
        blocks.append("".join(inner))

    nav = " · ".join(['<a href="#overview">Overview</a>', '<a href="#paper">Paper</a>'] +
                     [f'<a href="#k{K}">K={K}</a>' for K, *_ in kgroups])
    html = f"""<!doctype html><html><head><meta charset="utf-8">
    <title>Carr et al. 2025 — Figures 3 &amp; 4 (paper + laminar extension, K sweep)</title>
    <style>
      body {{ font-family:-apple-system,Segoe UI,Helvetica,Arial,sans-serif;
              margin:0 auto; max-width:1700px; padding:24px; color:#1a1a1a; }}
      h1 {{ font-size:22px; }} h2 {{ font-size:18px; margin:2px 0; }}
      h3 {{ font-size:14px; margin:2px 0; color:#333; }}
      .sub {{ color:#666; margin-top:0; font-size:13px; }}
      .nav {{ position:sticky; top:0; background:#fff; padding:10px 0;
              border-bottom:1px solid #ddd; font-size:13px; z-index:10; }}
      .nav a {{ margin-right:8px; color:#1a5; text-decoration:none; font-weight:600; }}
      section {{ border-top:1px solid #eee; padding-top:12px; margin-top:18px; }}
      section[id] {{ border-top:3px solid #ccd; margin-top:30px; }}
      .figrow {{ display:flex; gap:18px; flex-wrap:wrap; }}
      figure {{ margin:0; flex:1 1 640px; }}
      img {{ width:100%; border:1px solid #eee; border-radius:6px; }}
      figcaption {{ font-size:12px; color:#555; padding-top:4px; }}
      .intro {{ background:#f7f9fb; padding:14px 18px; border-radius:8px; font-size:14px; }}
      code {{ background:#eef; padding:1px 4px; border-radius:3px; }}
    </style></head><body>
    <h1>Carr et al. 2025 (monkey V1 WaveMAP) — Figures 3 &amp; 4</h1>
    <div class="intro">
      WaveMAP re-run on the same 606 visually-responsive neurons using
      <b>waveform shape + λ·laminar position</b> as features (λ=0: waveform only;
      <b>λ=∞: position only</b>), repeated for several cluster counts
      <b>K ∈ {{3,5,7,9}}</b>. Each clustering is <b>forced to exactly K</b> (an exact
      Louvain resolution where one exists, otherwise modularity-greedy merging of
      Louvain communities). Figures lead with the per-cluster <b>mean spike</b>
      (unit count next to the name); clusters are classified by shape into
      narrow-spiking (NS, cool), tri-phasic (TP, green) and broad-spiking (BS,
      warm), grouped NS→TP→BS. Direction index, amplitude, width, depth and layer
      are experimental measurements; only cluster membership changes.
      Stability = mean pairwise ARI across 8 random 85%-neuron subsamples; the
      direction-selectivity differentiation is the <b>cluster-size-weighted</b>
      std of per-cluster mean DI.
    </div>
    <div class="nav">{nav}</div>
    {''.join(blocks)}
    </body></html>"""
    out = os.path.join(OUT, "figures_3_4.html")
    with open(out, "w") as f:
        f.write(html)
    print(f"\nsaved {out}")


if __name__ == "__main__":
    main()
