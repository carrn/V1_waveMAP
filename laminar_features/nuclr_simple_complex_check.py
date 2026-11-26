"""Diagnostic: per-variable observed eta^2 vs its OWN label-shuffle null, for the
NuCLR K=9 and waveform K=9 clusterings. Answers whether SimpleComplex is below the
random baseline (i.e. clusters more homogeneous than chance) or merely below the
other clusterings."""
import numpy as np
import run_figures34 as R
from common import seed_everything, run_umap, scan_resolutions, cluster_to_k
from functional_quality import FUNC_VARS, eta2
from nuclr_functional_quality import join_nuclr_embeddings

N_NULL = 2000


def per_var_z(x, labels, rng):
    obs = eta2(x, labels)
    null = np.array([eta2(x, rng.permutation(labels)) for _ in range(N_NULL)])
    return obs, null.mean(), null.std(), (obs - null.mean()) / (null.std() + 1e-12)


df, wf = R.load_table()
cols = []
for key, (col, tf) in FUNC_VARS.items():
    v = df[col].astype(float).values.copy()
    if tf == "log1p": v = np.log1p(v)
    elif tf == "log": v = np.log(np.clip(v, 1e-9, None))
    cols.append(v)
varmat = np.column_stack(cols)

E = join_nuclr_embeddings(df)
m = np.isfinite(E).all(1)
df, wf, varmat, E = df[m].reset_index(drop=True), wf[m], varmat[m], E[m]

seed_everything(R.UMAP_SEED); _, gw = run_umap(wf, seed=R.UMAP_SEED); sw = scan_resolutions(gw)
seed_everything(R.UMAP_SEED); _, gn = run_umap(E, seed=R.UMAP_SEED); sn = scan_resolutions(gn)
lab_n = cluster_to_k(gn, sn, 9, prefer=1.0)[0]
lab_w = cluster_to_k(gw, sw, 9, prefer=1.0)[0]
pub = df["cluster 1.0"].astype(int).values

names = list(FUNC_VARS)
rng = np.random.default_rng(0)
print(f"K=9; null mean expectation (K-1)/(N-1) = {8/(len(df)-1):.4f}\n")
for label, lab in [("NuCLR", lab_n), ("waveform", lab_w), ("published", pub)]:
    print(f"=== {label} (K={len(set(lab.tolist()))}) ===")
    print(f"  {'var':14s} {'obs_eta2':>9s} {'null_mean':>9s} {'null_sd':>8s} {'z':>7s}")
    for j, nm in enumerate(names):
        o, nm_, sd, zz = per_var_z(varmat[:, j], lab, rng)
        flag = "  <-- below null" if zz < 0 else ""
        print(f"  {nm:14s} {o:9.4f} {nm_:9.4f} {sd:8.4f} {zz:7.2f}{flag}")
    print()
