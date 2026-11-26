# Laminar features for WaveMAP

Extends the WaveMAP cell-type clustering of Carr et al. 2025, *"High-resolution
laminar recordings reveal structure–function relationships in monkey V1"*
(bioRxiv 2025.05.14.653875 / PNAS), by adding each neuron's laminar position
(and, optionally, a NuCLR embedding) as clustering features.

## Setup

```bash
uv sync          # installs the pinned stack (umap-learn 0.5.3, networkx, …)
```

No external download is needed: the waveforms ship inside the cloned repo at
`1-PreWaveMAPProcessingFigure1/WaveMAP/` and the published per-neuron tables are
`2-WaveMAPPrcoessingFigures2-3/clusterFnData042925.mat` and
`3-GenerateFigures4-6/cluster_data_final.csv`.

## Shared code

| file | purpose |
|------|---------|
| `common.py`    | data loading, UMAP, Louvain wrappers, forcing exactly K clusters, constants |
| `louvain.py`   | the authors' pure-Python Louvain (`best_partition`), extracted verbatim from `WaveMAP_analysisV1.ipynb` |

## Base pipeline (faithful to the authors' notebook)

- Normalized negative-spiking waveforms (sessions 1–5), restricted to the 606
  visually-responsive neurons with valid laminar depth.
- UMAP: `n_neighbors=20`, `min_dist=0.2`, `random_state=50`.
- Louvain `best_partition` on the UMAP fuzzy graph.

With waveform-only features at resolution 1.0, this pipeline reproduces the
published 9 cell types exactly (ARI = 1.000 against the published labels; checked
by the `figure2.py` script removed in this branch's history).

## Extension — laminar position as a new feature

The extension adds the neuron's **laminar position** as an extra WaveMAP input
feature, weighted by `λ`, and re-clusters the **same 606 neurons** the paper used
(visually responsive, with valid laminar depth). See `run_figures34.py` and
`functional_quality.py` below.

Laminar position is a normalized cortical-depth coordinate in `[-1, +1]`:
`-1` = topmost of layer 1 (pia), `+1` = bottommost of layer 6 (white matter):

```
position = clip( 1 - 2*(depth - BOTTOM)/(TOP - BOTTOM), -1, 1 )
```

using the anatomical extents from the authors' code (`TOP=1039.4 um`,
`BOTTOM=-990 um`, depths in microns relative to layer 4). Feature vector =
`[52 waveform samples, λ * position]`.

## Figures 3 & 4 (paper + extension, in one HTML page)

```bash
uv run python run_figures34.py                       # full sweep, K=3,5,7,9
uv run python run_figures34.py --weights 0 1 inf --ks 5 9   # custom subset
# -> output/figures_3_4.html  (+ fig*_K*.png siblings; keep them together)
```

- `fig34.py` — `make_figure3` (laminar scatter sized by waveform width + depth
  density + per-layer composition) and `make_figure4` (per-cluster DI histograms,
  DI-vs-depth scatter sized by amplitude, amplitude heatmap cluster×layer, and
  median DI-vs-amplitude with 500-shuffle 2.5/97.5% bounds).
- `run_figures34.py` — renders both figures for the paper clusters and for the
  extension across the λ sweep and the K sweep, computes the quality metrics, and
  assembles everything into `figures_3_4.html` (grouped by K, file-referenced).

Direction index, amplitude, waveform width, depth and layer come from the
published per-neuron table `cluster_data_final.csv`; only the cluster label
differs between cases.

**Cell-type sorting & mean spikes.** Both figures lead with a per-cluster
mean-spike strip (faint members + bold mean, as in paper Fig 2A). Clusters are
classified by mean-waveform shape into **NS** (narrow-spiking), **TP**
(tri-phasic) and **BS** (broad-spiking) and grouped NS → TP → BS, with
cool/green/warm coloring matching the paper. The classifier (`classify_shape` in
`common.py`) is calibrated on the paper's own clusters: a tri-phasic cluster has
a positive pre-trough deflection (>0.1; paper TP ≈ +0.23 vs ≈ −0.03 for the
rest), and NS vs BS splits on trough-to-peak width (paper NS 6–8 samples, BS
11–17; threshold 10). Within each group clusters are ordered top→bottom by median
depth.

Spike counts (n units) are shown next to each cluster name on the mean-spike
panels.

**Weight sweep.** `λ ∈ {0, 0.125, 0.25, 0.5, 1, 2, 4, 8, 16, ∞}`. Small weights
(≤0.5) keep the clustering shape-driven, merely nudged by laminar position;
large weights make laminar position dominate (clusters collapse onto single
layers). **λ = ∞ uses the laminar position only** (no waveform). The sweep makes
this tradeoff visible so the weight can be chosen by eye.

**Cluster-count sweep `K ∈ {3,5,7,9}`** — the whole analysis is repeated for
each K and grouped in the HTML. Every clustering is **forced to exactly K**.
Louvain on this UMAP graph won't produce fewer than ~6–8 communities at any
resolution (position-only won't go below ~14), so small K can't be reached by
resolution alone: `cluster_to_k` (`common.py`) uses an exact Louvain resolution
when one yields K, otherwise greedily **merges Louvain communities by modularity
gain** (Clauset-Newman-Moore) down to K — both on the same UMAP graph. Each
figure title records which mechanism was used (`res 1.1` vs `merge 14→9`).

**Efficiency.** UMAP + a Louvain resolution scan are computed **once per λ**
(full data + 8 subsamples) and reused across all K — UMAP depends only on the
feature matrix, not on K. Full run ≈ 5–6 min.

**Quality metrics vs λ** (`metrics34.py`, one panel set per K):
- **Stability** — mean pairwise adjusted Rand index across 8 random 85%-neuron
  subsamples. (Pure UMAP-seed re-runs are degenerate: for ~600 points the fuzzy
  kNN graph Louvain clusters is seed-invariant, so layout-seed ARI = 1.0;
  subsampling actually perturbs the graph.)
- **Waveform spread** — within-cluster RMS distance to the mean waveform (shape
  coherence). Low/flat for small λ, rising steeply once depth overrides shape.
- **Depth spread** — mean within-cluster depth std. Matches the paper for small λ,
  collapsing as clusters become laminar (minimal at λ=∞).
- **DI differentiation** — **cluster-size-weighted** std of per-cluster mean
  direction index (weights = proportion of cells per cluster): how strongly the
  cell types separate in selectivity vs λ.

Dashed reference lines mark the published K=9 clustering on the same 606 neurons.

**Cross-K overlay + random baseline** (`summary.py` → `output/metrics_overlay.png`,
shown in the HTML "Overview"). One 2×2 figure overlays all K on each metric. The
λ-axis is log-scaled with λ=0 drawn at the 0.0625 slot and λ=∞ just past 16.
A **random-assignment baseline** (X markers at λ=0.03125, one octave further left)
shuffles the λ=0 labels — keeping the exact unit count per cluster — and recomputes
the metrics: it is the chance reference (stability ≈ 0, waveform spread ≈ 1.0 = no
shape coherence, depth spread ≈ 368 µm = full global spread, DI differentiation ≈ 0).
`summary.py` regenerates only the overlay (not the 80 detail figures) and caches the
per-(λ,K) curve metrics to `output/metrics_data.json`, so re-tweaking the summary is
instant after the first run.

## Other fields in the data (verification / extension ideas)

`cluster_data_final.csv` carries more per-neuron columns than Figures 3–4 use:

- **`umap_x`, `umap_y`** — the authors' published UMAP coordinates. Reproducing the
  embedding and aligning to these (Procrustes) gives **disparity ≈ 0.09** (0 =
  identical up to rotation/scale) — independent verification of the embedding, not
  just the cluster labels.
- **`umap_x2`, `umap_y2`, `Cluster 2.5`** — the resolution-2.5 solution (Fig 2D),
  for cross-checking the merged clustering.
- **`SNR`** — unit quality, for QC filtering.
- **Orientation Index / circular variance / tuning BandWidth / fit R², Direction
  circular variance, SimpleComplexIndex, `FR` (firing rate), `repWidth`, `kurt`,
  `skew`** — independent functional measures that can validate cell types as
  *construct* checks (do clusters differ in orientation tuning / firing as expected?)
  or serve as additional feature types for further extensions.
- **`poscluster_data_final.csv`** (105 positive-spiking units) — a separate WaveMAP
  population for cross-checking.

## Non-circular cluster-quality metric (`functional_quality.py`)

Waveform spread and depth spread are *circular* — they just track the clustering's
own objective, so they're monotonic in λ and useless for model selection. The only
informative one before was DI, *because DI is held out of the clustering*. This
generalizes that: a **functional-differentiation z-score** over a panel of ~8
held-out functional/tuning variables (DI, orientation selectivity, ori/dir circular
variance, tuning bandwidth, simple-complex, log firing rate, log ISI kurtosis≈
bursting). For each it computes η² (between-cluster variance fraction) and
standardizes against a label-shuffle null (same cluster sizes) — the shuffle
removes the mechanical K-bias that made raw η²/spread monotonic. Output:
`output/functional_quality.png`.

Result (genuinely discriminative & non-monotonic): shape-only clusters (λ=0, the
published recipe) already separate held-out function well above chance (z≈11), but
adding moderate laminar weight (λ≈1–4) **roughly doubles** functional differentiation
(z≈21–27), then it dips at λ=∞. Per-variable, most tuning measures (DI, OSI, dir
selectivity, firing rate, bursting) are *more laminar than shape-driven*. Caveat:
because function in V1 is itself laminar, this metric rewards laminar organization,
so the rise with λ partly reflects "depth predicts function" rather than strictly
"better cell types"; the clean shape-based validation is the λ=0 value (z≈11).

Other principled options not yet built: the **gap statistic** (compares within-cluster
dispersion to a null reference — turns the circular spread metrics into a proper
non-monotonic "right K" criterion), and **cross-validated classifier reproducibility**
(the paper's Fig 2C, ~88%) as a separability/stability measure.
