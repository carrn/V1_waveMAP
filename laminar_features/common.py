"""
Common data loading + WaveMAP helpers for the Carr et al. 2025 WaveMAP pipeline.

Figure 2: "UMAP and Louvain Clustering on 801 negative spiking waveforms reveals
9 candidate cell types."  (Carr, Zhu, Lee, Xia, Chen, Perliss, Moore, Chandrasekaran,
bioRxiv 2025.05.14.653875 / PNAS).

Pipeline (from the authors' WaveMAP_analysisV1.ipynb):
  - load normalized negative-spiking waveforms (align_neg), depths, IDs
  - keep sessions 1-5 (keeps all 801)
  - UMAP: n_neighbors=20, min_dist=0.2, random_state=50
  - build kNN graph (mapper.graph_), Louvain best_partition at resolution=1.0
"""
import os
import random
import numpy as np
import scipy.io as sio

# ----------------------------------------------------------------------------
# Paths (data ships inside the cloned repo, no external download required)
# ----------------------------------------------------------------------------
HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)  # V1_waveMAP/
WAVEMAP_DIR = os.path.join(REPO, "1-PreWaveMAPProcessingFigure1", "WaveMAP")
CLUSTERFN_MAT = os.path.join(REPO, "2-WaveMAPPrcoessingFigures2-3", "clusterFnData042925.mat")

# ----------------------------------------------------------------------------
# Constants from the paper / notebook
# ----------------------------------------------------------------------------
RAND_STATE = 50
N_NEIGHBORS = 20
MIN_DIST = 0.2
RESOLUTION = 1.0

# Laminar-extension sweep: laminar-feature weights lambda (0 = waveform only,
# inf = position only) and forced cluster counts K.
WEIGHTS = [0, 0.125, 0.25, 0.5, 1, 2, 4, 8, 16, float("inf")]
KS = [3, 5, 7, 9]

# 9-cluster palette used for Figure 2 (res1_0 in the notebook).
# Cool colors = narrow-spiking, warm = broad-spiking, green = tri-phasic.
CUSTOM_PAL = ['#054b7d', '#416EB6', '#fe7f2d', '#9d0208', '#f0cb67',
              '#8bcdfc', '#00c49a', '#17A9C9', '#896B29']

# Layer boundaries (microns, distance from layer 4), from the notebook.
# avgLayerBounds rows: L23, L4B, L4C, L56, (top/bottom extremes).
# Top of cortex (top of L1/pia) .. bottom of L6 (white-matter boundary).
LAYER_TOP = 1039.4     # topmost (superficial, top of layer 1)
LAYER_BOTTOM = -990.0  # bottommost (deep, bottom of layer 6 / WM)
LAYER_BOUNDS = [588.8, 285.4, 0.0, -488.0]  # L23/L4B, L4B/L4C, L4C ref, L5/6

# Canonical candidate-cell-type ordering and names, from the authors' MATLAB
# (generateFigure4.m display order [1 6 8 2 7 3 9 5 4], 1-indexed) translated to
# the 0-indexed cluster ids used here (CSV 'cluster 1.0' / our Louvain output).
ORDER_PUB = [0, 5, 7, 1, 6, 2, 8, 4, 3]
NAMES_PUB = {0: "NS1", 5: "NS2", 7: "NS3", 1: "NS4", 6: "TP-1",
             2: "BS1", 8: "BS2", 4: "BS3", 3: "BS4"}

# Layer bins (depth_bins column): 1=L5/6, 2=L4C, 3=L4A/B, 4=L2/3, 5=WM, 6=NaN.
# Display order top -> bottom and the depth-axis boundaries (microns from L4).
LAYER_BIN_NAMES = {4: "L2/3", 3: "L4A/B", 2: "L4C", 1: "L5/6"}
LAYER_BIN_ORDER = [4, 3, 2, 1]                      # top -> bottom
LAYER_CENTERS = {  # for placing layer labels on a depth axis
    "L1": 814.1, "L2/3": 437.1, "L4A/B": 142.7, "L4C": -244.0, "L5/6": -739.0}


def waveforms_by_key():
    """Return a dict (session, unit_id) -> normalized waveform for all 801 units."""
    d = load_neg_waveforms()
    return {(s, i): w for s, i, w in zip(d["session"], d["unit_id"], d["waveforms"])}


def classify_shape(mean_wave):
    """Classify a cluster's mean (normalized) waveform as NS / TP / BS by shape.

    Calibrated on the paper's own clusters:
      - tri-phasic (TP): a positive deflection *before* the trough (prePeak > 0.1;
        paper TP cluster ~ +0.23, all others ~ -0.03).
      - otherwise narrow- vs broad-spiking by trough-to-peak width in samples
        (paper NS clusters 6-8 samples, BS clusters 11-17; split at 10).
    """
    tr = int(np.argmin(mean_wave))
    prepeak = float(mean_wave[:tr].max()) if tr > 0 else 0.0
    if prepeak > 0.10:
        return "TP"
    width = int(np.argmax(mean_wave[tr:]))  # samples from trough to following peak
    return "NS" if width < 10 else "BS"


def seed_everything(seed=RAND_STATE):
    np.random.seed(seed)
    os.environ['PYTHONHASHSEED'] = str(seed)
    random.seed(seed)


def load_neg_waveforms(maxsession=5):
    """Load the negative-spiking waveforms used for Figure 2.

    Returns dict with: waveforms (N,52), depth_scaled (N,), session (N,),
    unit_id (N,).  N = 801 with maxsession=5.
    """
    wf = sio.loadmat(os.path.join(WAVEMAP_DIR, "normalizednegwaveforms.mat"))['align_neg']
    depth = sio.loadmat(os.path.join(WAVEMAP_DIR, "depth_neg_scaled.mat"))['depth_neg_scaled'].ravel()
    ID = sio.loadmat(os.path.join(WAVEMAP_DIR, "ID_neg.mat"))['ID_neg'].astype(int)
    unit_id, session = ID[:, 0], ID[:, 1]

    keep = np.isin(session, np.arange(1, maxsession + 1))
    return {
        "waveforms": wf[keep].astype(float),
        "depth_scaled": depth[keep],
        "session": session[keep],
        "unit_id": unit_id[keep],
    }


def load_clusterfn():
    """Load the published per-neuron functional table (607 vis-responsive units).

    Columns of interest (0-indexed): 2=unit ID, 3=session, 11=vis_resp,
    14=cluster (1-9), 15=scaled depth, 20=depth/layer bin.
    """
    d = sio.loadmat(CLUSTERFN_MAT)['clusterFnData']
    return {
        "raw": d,
        "unit_id": d[:, 2].astype(int),
        "session": d[:, 3].astype(int),
        "cluster": d[:, 14].astype(int),   # 1..9
        "depth_scaled": d[:, 15],
        "depth_bin": d[:, 20],
    }


def match_published_clusters(data, cfn):
    """For each loaded waveform, return the published cluster id (1-9) or 0 if
    the unit is not in the vis-responsive 606/607 table.

    Matching is by (session, unit_id), which is unique and exact.
    """
    cf_keys = {(s, i): c for s, i, c in zip(cfn["session"], cfn["unit_id"], cfn["cluster"])}
    out = np.zeros(len(data["session"]), dtype=int)
    for k, (s, i) in enumerate(zip(data["session"], data["unit_id"])):
        out[k] = cf_keys.get((s, i), 0)
    return out


def run_umap(waveforms, n_neighbors=N_NEIGHBORS, min_dist=MIN_DIST, seed=RAND_STATE):
    """Fit UMAP and return (embedding (N,2), fuzzy-graph csr_matrix)."""
    from umap import umap_ as umap
    reducer = umap.UMAP(n_neighbors=n_neighbors, min_dist=min_dist, random_state=seed)
    mapper = reducer.fit(waveforms)
    embedding = reducer.transform(waveforms)
    return embedding, mapper.graph_.tocsr()


def louvain_clusters(graph_csr, resolution=RESOLUTION):
    """Run the authors' pure-Python Louvain on the UMAP fuzzy graph.

    Returns an int array of community labels (0-indexed) per node.
    """
    from louvain import best_partition
    part = best_partition(graph_csr, resolution=resolution)
    return np.array([part[i] for i in range(graph_csr.shape[0])], dtype=int)


def _relabel(comm):
    """Map community ids to contiguous 0..C-1."""
    comm = np.asarray(comm)
    uniq = {c: i for i, c in enumerate(sorted(set(comm.tolist())))}
    return np.array([uniq[c] for c in comm.tolist()], dtype=int)


def scan_resolutions(graph_csr, grid=None):
    """Louvain partition at each resolution in `grid`. Returns [(res, labels, k)]."""
    if grid is None:
        grid = np.round(np.arange(0.2, 1.81, 0.05), 2)
    out = []
    for r in grid:
        lab = louvain_clusters(graph_csr, resolution=float(r))
        out.append((float(r), lab, len(set(lab.tolist()))))
    return out


def merge_to_k(graph_csr, labels, target_k):
    """Greedily merge communities to exactly `target_k` by maximizing modularity
    gain at each step (Clauset-Newman-Moore agglomeration on the UMAP graph).
    Used only when no Louvain resolution yields exactly target_k (e.g. small K)."""
    comm = _relabel(labels)
    A = graph_csr.tocoo()
    row, col, dat = A.row, A.col, A.data.astype(float)
    while len(set(comm.tolist())) > target_k:
        comm = _relabel(comm)
        C = int(comm.max()) + 1
        Mm = np.zeros((C, C))
        np.add.at(Mm, (comm[row], comm[col]), dat)
        m = Mm.sum() / 2.0
        ktot = Mm.sum(1)
        dQ = Mm / m - np.outer(ktot, ktot) / (2 * m * m)
        iu = np.triu_indices(C, 1)
        between = Mm[iu] > 0
        if between.any():
            cand = np.where(between, dQ[iu], -np.inf)
            kbest = int(np.argmax(cand))
            a, b = int(iu[0][kbest]), int(iu[1][kbest])
        else:  # disconnected: merge the two smallest communities
            sizes = np.array([(comm == c).sum() for c in range(C)])
            a, b = sorted(np.argsort(sizes)[:2].tolist())
        comm[comm == b] = a
    return _relabel(comm)


def cluster_to_k(graph_csr, scan, target_k, prefer=1.0):
    """Force exactly target_k clusters: use an exact Louvain resolution if one
    exists in `scan` (closest to `prefer`), else merge down from the finest
    partition with more than target_k communities. Returns (labels, how)."""
    exact = [(r, lab) for r, lab, k in scan if k == target_k]
    if exact:
        r, lab = min(exact, key=lambda t: abs(t[0] - prefer))
        return lab, f"res {r:g}"
    bigger = [(k, r, lab) for r, lab, k in scan if k > target_k]
    if bigger:
        base = min(bigger, key=lambda t: (t[0], abs(t[1] - prefer)))[2]
    else:  # nothing finer than target_k available: take the finest there is
        base = max(scan, key=lambda t: t[2])[1]
    return merge_to_k(graph_csr, base, target_k), f"merge {len(set(base.tolist()))}→{target_k}"
