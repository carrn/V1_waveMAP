"""Generate a standalone explainer HTML for the held-out functional-differentiation
metric: reasoning + math + relation to the paper + results. Self-contained (the
figure is base64-embedded). Run: uv run python write_explainer.py"""
import os
import base64

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "output")
IMG = os.path.join(OUT, "functional_quality.png")
IMG2 = os.path.join(OUT, "functional_per_variable.png")

# functional-differentiation z-scores from functional_quality.py
LAM = ["0", "0.125", "0.25", "0.5", "1", "2", "4", "8", "16", "∞"]
Z = {
    3: [10.65, 13.82, 15.60, 17.46, 12.69, 20.31, 18.82, 19.55, 13.79, 15.63],
    5: [10.74, 11.37, 13.04, 13.57, 25.34, 25.27, 26.90, 19.69, 25.32, 19.64],
    7: [11.85, 10.80, 11.04, 14.44, 23.20, 23.67, 20.48, 18.14, 21.76, 19.55],
    9: [11.63, 11.45, 9.62, 11.26, 21.31, 21.80, 24.43, 17.51, 21.24, 17.97],
}
Z_PUBLISHED = 10.75


def table_html():
    head = "<tr><th>K \\ λ</th>" + "".join(f"<th>{l}</th>" for l in LAM) + "</tr>"
    rows = []
    for K, vals in Z.items():
        mx = max(vals)
        cells = "".join(
            (f'<td class="hi">{v:.1f}</td>' if v == mx else f"<td>{v:.1f}</td>")
            for v in vals)
        rows.append(f"<tr><th>{K}</th>{cells}</tr>")
    return f'<table class="z">{head}{"".join(rows)}</table>'


def img_uri(path=IMG):
    with open(path, "rb") as f:
        return "data:image/png;base64," + base64.b64encode(f.read()).decode()


TEMPLATE = r"""<!doctype html>
<html><head><meta charset="utf-8">
<title>Held-out functional differentiation — a non-circular cluster-quality metric</title>
<style>
  body { font-family:-apple-system,Segoe UI,Helvetica,Arial,sans-serif;
         max-width:880px; margin:0 auto; padding:32px 24px; color:#1a1a1a;
         line-height:1.55; }
  h1 { font-size:24px; line-height:1.25; }
  h2 { font-size:18px; margin-top:34px; border-bottom:2px solid #eee; padding-bottom:4px; }
  h3 { font-size:15px; margin-top:22px; }
  p, li { font-size:15px; }
  code { background:#eef1f7; padding:1px 5px; border-radius:3px; font-size:13.5px; }
  .eq { display:block; text-align:center; font-family:"Cambria Math",Georgia,serif;
        font-size:17px; margin:16px 0; color:#10243e; }
  .eq i { font-style:italic; }
  .bar { text-decoration:overline; }
  .note { background:#f7f9fb; border-left:4px solid #9bb; padding:10px 16px;
          border-radius:4px; font-size:14px; }
  .warn { background:#fdf6f0; border-left:4px solid #e0a96d; padding:10px 16px;
          border-radius:4px; font-size:14px; }
  .paper { background:#f3f6ee; border-left:4px solid #8aa55a; padding:10px 16px;
           border-radius:4px; font-size:14px; }
  table.z { border-collapse:collapse; margin:14px 0; font-size:13px; width:100%; }
  table.z th, table.z td { border:1px solid #ddd; padding:4px 7px; text-align:center; }
  table.z th { background:#f0f3f8; }
  table.z td.hi { background:#cfe8d4; font-weight:700; }
  figure { margin:18px 0; } img { width:100%; border:1px solid #eee; border-radius:6px; }
  figcaption { font-size:13px; color:#555; padding-top:6px; }
  .small { color:#666; font-size:13px; }
</style></head><body>

<h1>Held-out functional differentiation<br><span class="small">a non-circular way
to ask whether a clustering of V1 neurons is "good"</span></h1>

<p>This note explains a single idea precisely: <b>a cluster solution is good to the
extent that its clusters separate variables that were never used to build the
clusters</b>. It motivates the metric, writes out the math, says exactly what was
computed, relates it to Carr et al. 2025, and lists the caveats.</p>

<h2>1. Why most of our metrics can't pick a model</h2>
<p>We clustered 606 V1 neurons with WaveMAP on a feature vector
<code>[ waveform shape , λ·laminar position ]</code> and looked at four quality
metrics vs the weight λ (and vs the cluster count K). Three of them are
<b>circular</b>:</p>
<ul>
  <li><b>Within-cluster waveform spread</b> can only go <i>down</i> as we put more
  weight on waveform shape — it is the clustering's own objective.</li>
  <li><b>Within-cluster depth spread</b> can only go down as we put more weight on
  laminar position — again the objective.</li>
</ul>
<p>So both are essentially monotonic in λ and tell us nothing about whether the
clusters are <i>real</i>; they only confirm the optimizer optimized its input. The
one informative metric was the <b>direction-selectivity index (DI)</b> — and the
reason is simple: <b>DI was held out of the clustering</b>. Separation on a held-out
variable can't be manufactured by the objective, so it is genuine validation.</p>

<h2>2. The fix: validate on held-out variables</h2>
<p>The dataset carries many functional measurements that are <i>not</i> inputs to the
clustering. We use a panel of <b>M = 8</b> held-out variables:</p>
<ul class="small">
  <li>direction selectivity index (DI), orientation selectivity index (OSI)</li>
  <li>orientation circular variance, direction circular variance</li>
  <li>orientation tuning bandwidth, simple–complex index</li>
  <li>log firing rate, log ISI kurtosis (a bursting proxy)</li>
</ul>
<p>A clustering is "good" if neurons in the same cluster have <i>similar</i> values of
these variables and different clusters have <i>different</i> values — more so than
you'd get by chance.</p>

<h2>3. The math</h2>
<h3>3a. Per-variable effect size: η²</h3>
<p>Let the clustering split the <i>N</i> neurons into <i>K</i> clusters
<i>C</i><sub>1</sub>,…,<i>C</i><sub>K</sub> of sizes <i>n</i><sub>k</sub>. For one
held-out variable <i>v</i> (value <i>v<sub>i</sub></i> for neuron <i>i</i>), define
the grand mean and the per-cluster means:</p>
<span class="eq"><span class="bar">v</span> = (1/<i>N</i>) Σ<sub>i</sub> <i>v<sub>i</sub></i>
&nbsp;&nbsp;&nbsp;&nbsp;
<span class="bar">v</span><sub>k</sub> = (1/<i>n<sub>k</sub></i>) Σ<sub>i∈C<sub>k</sub></sub> <i>v<sub>i</sub></i></span>
<p>Split the total variability into between-cluster and total sums of squares:</p>
<span class="eq">SS<sub>between</sub> = Σ<sub>k</sub> <i>n<sub>k</sub></i> (<span class="bar">v</span><sub>k</sub> − <span class="bar">v</span>)²
&nbsp;&nbsp;&nbsp;&nbsp;
SS<sub>total</sub> = Σ<sub>i</sub> (<i>v<sub>i</sub></i> − <span class="bar">v</span>)²</span>
<p>The effect size is the fraction of the variable's variance explained by cluster
identity (the one-way-ANOVA η²):</p>
<span class="eq">η²(<i>v</i>) = SS<sub>between</sub> / SS<sub>total</sub> ∈ [0, 1]</span>
<p>η² = 0 means clusters carry no information about <i>v</i>; η² = 1 means <i>v</i> is
constant within every cluster. (Missing values are dropped per variable.)</p>

<h3>3b. Why raw η² still can't be compared across K — the shuffle null</h3>
<p>η² rises <b>mechanically</b> with K: more groups capture more between-group variance
even for a random partition. So a bare η² (like the spreads) would drift with K. We
remove that by comparing to a <b>label-shuffle null with the same cluster sizes</b>.
Draw random permutations π of the cluster labels across neurons (sizes
<i>n<sub>k</sub></i> preserved exactly) and recompute η² each time, <i>B</i> = 300
times. This null has the same K and the same sizes, so it captures the chance level
of η² for this particular clustering geometry.</p>

<h3>3c. Aggregate over the panel, then standardize</h3>
<p>For a partition, average the effect size over the M held-out variables:</p>
<span class="eq"><i>T</i> = (1/<i>M</i>) Σ<sub>m=1…M</sub> η²(<i>v</i><sup>(m)</sup>)</span>
<p>Compute <i>T</i> for the real labels (<i>T</i><sub>obs</sub>) and for each shuffle
(<i>T</i><sub>b</sub>, the same permutation applied to all M variables). The metric is
the z-score of the observed aggregate against the null:</p>
<span class="eq"><i>z</i> = ( <i>T</i><sub>obs</sub> − mean<sub>b</sub> <i>T<sub>b</sub></i> ) / std<sub>b</sub> <i>T<sub>b</sub></i></span>
<p><i>z</i> is "how many null standard deviations the clusters separate held-out
function beyond chance." <b>z ≈ 0</b> is chance; large positive <b>z</b> means the
clusters are functionally meaningful. Because the null is matched in K and sizes,
<b>z is comparable across K and across λ</b> — which the circular spreads were not.</p>

<div class="note"><b>One line of code, in words:</b> for each (K, λ) clustering,
compute the mean across 8 held-out tuning variables of "fraction of that variable's
variance explained by cluster", then express it as a z-score against 300 size-matched
label shuffles.</div>

<h2>4. Exactly what was computed</h2>
<ul>
  <li><b>Neurons:</b> the 606 visually-responsive units (the paper's set).</li>
  <li><b>Clusterings:</b> WaveMAP (UMAP + Louvain) on <code>[waveform, λ·position]</code>,
  forced to exactly K, for K ∈ {3,5,7,9} and λ ∈ {0, 0.125, 0.25, 0.5, 1, 2, 4, 8, 16, ∞}
  (λ=0 = shape only; λ=∞ = position only).</li>
  <li><b>Held-out panel:</b> the M = 8 variables in §2, none of which is a clustering
  input. Firing rate and ISI kurtosis are log-transformed; missing values dropped
  per variable.</li>
  <li><b>Null:</b> B = 300 label permutations preserving cluster sizes; the same
  permutation is applied to all variables within a draw.</li>
  <li><b>Reported:</b> the z-score above, per (K, λ); plus per-variable η² for two
  reference solutions (shape-only K=9 vs position-only K=9).</li>
</ul>

<h2>5. How this relates to the paper</h2>
<div class="paper"><b>The mechanism is the paper's; the aggregate index is not.</b>
Carr et al. (Figs 3–4) use exactly this kind of <b>label-shuffle null on held-out
variables</b>: Fig 4C compares each cluster's <i>median DI</i> and <i>median
amplitude</i> to 2.5/97.5 percentile bounds from 500–1000 cluster-label shuffles
("only NS-3 differs from shuffle in amplitude and DI…"), and Fig 3 does the same for
<i>depth</i>. What is <b>not</b> in the paper: (i) aggregating a whole panel of ~8
functional variables into one score, (ii) using η² (a variance-explained effect size)
rather than a per-cluster median significance test, and (iii) using it to <b>choose
K and λ</b> — the paper fixes K = 9 and has no λ. So treat the z-score as a reasonable
generalization of the paper's Fig 3/4 shuffle tests, not as a published quantity.</div>

<h2>6. Results</h2>
<figure><img src="__IMG__"/>
<figcaption><b>Left:</b> functional-differentiation z vs λ, one line per K; grey band
is chance (|z|&lt;2); dashed line is the published K=9 labels. <b>Right:</b>
per-variable η² for K=9 at shape-only (λ=0), the z-peak (λ=4, outlined green), and
position-only (λ=∞). At the peak, most tuning variables — DI, orientation/direction
selectivity, and especially bursting — are separated at least as well as at either
extreme.</figcaption></figure>

<figure><img src="__IMG2__"/>
<figcaption>Each held-out variable's η² (between-cluster variance fraction) as a
function of λ, one panel per variable, one line per K. DI, direction circular
variance, firing rate and bursting (logKurt) climb steeply with λ — their structure
is largely laminar; orientation circular variance and the simple–complex index peak
at intermediate λ; orientation tuning bandwidth is weakly separated throughout. This
is the per-variable breakdown of the aggregate z on the left.</figcaption></figure>

<p>z-score by cluster count K (rows) and laminar weight λ (columns); the largest value
in each row is highlighted:</p>
__TABLE__
<p class="small">Published K=9 labels (clustered on all 801 units): z = __ZPUB__.</p>

<p><b>Reading it:</b></p>
<ul>
  <li><b>The original cell types are real.</b> Shape-only clustering (λ=0) already
  reaches z ≈ 11 — far above chance — so the waveform clusters genuinely separate
  held-out function. Independent validation of the paper, beyond the labels.</li>
  <li><b>Adding moderate laminar weight roughly doubles it</b> (z ≈ 21–27 around
  λ ≈ 1–4), with a sharp jump between λ = 0.5 and λ = 1, then a dip toward λ = ∞.
  The metric is <b>non-monotonic</b> — it can actually prefer a model.</li>
  <li><b>Shape + depth beats either alone:</b> position-only (λ=∞) is good but not the
  best; combining shape and a little laminar position is best.</li>
  <li><b>Per-variable (right):</b> direction/orientation selectivity, firing rate and
  bursting separate more under depth; orientation circular variance and simple–complex
  slightly favor shape.</li>
</ul>

<h2>7. Caveats — read it correctly</h2>
<div class="warn">
<ul style="margin:0">
  <li><b>Laminar confound.</b> In V1, function is itself laminar, so a depth-driven
  clustering separates depth-correlated functions partly for free. The rise in z with
  λ therefore partly reflects "depth predicts function," not strictly "better cell
  types." The clean, unconfounded validation of <i>shape</i> cell types is the
  <b>λ = 0</b> value (z ≈ 11).</li>
  <li><b>Not independent tests.</b> The 8 variables are correlated (orientation
  measures especially); averaging η² treats them as a descriptive panel, so z is a
  descriptive effect size, not a multiplicity-corrected p-value.</li>
  <li><b>Rewards any function-correlated axis.</b> A high z says "clusters track
  function," not "this partition is the unique natural one."</li>
  <li><b>Faithful-to-paper variant.</b> To stay strictly within what the paper
  sanctions, report each variable's shuffle significance separately (count clusters
  outside the 2.5/97.5 bounds), rather than the single aggregate score.</li>
</ul></div>

<h2>8. Reproduce</h2>
<p><code>uv run python functional_quality.py</code> recomputes the figure and z-scores
(~45 s; only the full-data graphs are needed). This explainer is regenerated by
<code>uv run python write_explainer.py</code>.</p>

<p class="small">Carr, Zhu, Lee, Xia, Chen, Perliss, Moore, Chandrasekaran — "High-resolution
laminar recordings reveal structure–function relationships in monkey V1",
bioRxiv 2025.05.14.653875 / PNAS.</p>
</body></html>"""


def main():
    html = (TEMPLATE
            .replace("__IMG2__", img_uri(IMG2))   # before __IMG__ (substring)
            .replace("__IMG__", img_uri(IMG))
            .replace("__TABLE__", table_html())
            .replace("__ZPUB__", f"{Z_PUBLISHED:.1f}"))
    out = os.path.join(OUT, "functional_differentiation.html")
    with open(out, "w") as f:
        f.write(html)
    print(f"saved {out}  ({len(html)//1024} KB)")


if __name__ == "__main__":
    main()
