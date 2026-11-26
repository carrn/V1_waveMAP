"""
Regenerate ONLY the cross-K summary overlay (output/metrics_overlay.png), adding a
random-assignment baseline.

The baseline takes the lambda=0 clustering (per K) and shuffles the cluster labels
among neurons -- keeping the exact number of units per cluster -- then recomputes
the four quality metrics. It is the chance reference (no real structure) and is
drawn at lambda = 0.03125 (one octave left of the lambda=0 slot).

The per-(weight,K) curve metrics are cached to output/metrics_data.json on first
run, so subsequent summary tweaks are instant (no re-clustering). The full
Figure 3/4 image set is NOT regenerated.

Run:  uv run python summary.py
"""
import os
import json
import numpy as np

import run_figures34 as R
import metrics34 as M
from common import (cluster_to_k, seed_everything, run_umap, scan_resolutions,
                    WEIGHTS, KS)

CACHE = os.path.join(R.OUT, "metrics_data.json")
N_SHUFFLE = 20


def compute_curves(df, wf, pos, weights, Ks):
    """Per-(weight,K) metrics, identical to run_figures34 (cached to JSON)."""
    if os.path.exists(CACHE):
        with open(CACHE) as f:
            d = json.load(f)
        if d["weights"] == [("inf" if not np.isfinite(w) else w) for w in weights] \
           and d["Ks"] == Ks:
            print("loaded cached curve metrics")
            return {int(k): v for k, v in d["metrics_by_K"].items()}, d["paper_ref"]

    print("computing curve metrics (no figures rendered)...")
    paper_ref = M.paper_reference(df, wf)
    graphs = {w: R.build_graphs(R.features(wf, pos, w)) for w in weights}
    for w in weights:
        print(f"  graphs ready λ={R.wtext(w)}")
    metrics_by_K = {}
    for K in Ks:
        met = {k: [] for k in M.METRIC_KEYS}
        for w in weights:
            full, full_scan, subs = graphs[w]
            lab, _ = cluster_to_k(full, full_scan, K, prefer=1.0)
            vals = M.clustering_metrics(df, wf, lab, subs, K)
            for k in M.METRIC_KEYS:
                met[k].append(vals[k])
        metrics_by_K[K] = met
        print(f"  K={K} done")
    with open(CACHE, "w") as f:
        json.dump({"weights": [("inf" if not np.isfinite(w) else w) for w in weights],
                   "Ks": Ks, "metrics_by_K": metrics_by_K, "paper_ref": paper_ref}, f)
    return metrics_by_K, paper_ref


def random_baseline(df, wf, Ks):
    """Shuffle the lambda=0 labels (preserving cluster sizes) and recompute metrics."""
    depth = df["depth_scaled"].values
    DI = df["DI"].values
    seed_everything(R.UMAP_SEED)                       # lambda=0 graph (waveform only)
    _, full = run_umap(wf, seed=R.UMAP_SEED)
    scan = scan_resolutions(full)
    base = {}
    for K in Ks:
        lab0, _ = cluster_to_k(full, scan, K, prefer=1.0)
        rng = np.random.default_rng(0)
        shuffles = [rng.permutation(lab0) for _ in range(N_SHUFFLE)]
        ws = [M.waveform_spread(wf, s) for s in shuffles]
        ds = [M.depth_spread(depth, s) for s in shuffles]
        dd = [M.di_differentiation(DI, s) for s in shuffles]
        from itertools import combinations
        from sklearn.metrics import adjusted_rand_score
        aris = [adjusted_rand_score(a, b) for a, b in combinations(shuffles, 2)]
        base[K] = {"stab": float(np.mean(aris)), "stab_err": float(np.std(aris)),
                   "wspread": float(np.mean(ws)), "dspread": float(np.mean(ds)),
                   "didiff": float(np.mean(dd))}
        print(f"  baseline K={K}: stab={base[K]['stab']:.3f} "
              f"wspread={base[K]['wspread']:.3f} dspread={base[K]['dspread']:.1f} "
              f"didiff={base[K]['didiff']:.4f}")
    return base


def main():
    df, wf = R.load_table()
    pos = R.laminar_position(df["depth_scaled"].values)
    weights, Ks = WEIGHTS, KS

    metrics_by_K, paper_ref = compute_curves(df, wf, pos, weights, Ks)
    print("computing random-assignment baseline (shuffled λ=0 labels)...")
    base = random_baseline(df, wf, Ks)

    fig = M.plot_metrics_overlay(weights, metrics_by_K, paper_ref=paper_ref,
                                 baseline_by_K=base)
    out = os.path.join(R.OUT, "metrics_overlay.png")
    fig.savefig(out, dpi=120, bbox_inches="tight")
    print(f"saved {out}")


if __name__ == "__main__":
    main()
