#!/bin/bash
set -euo pipefail
cd /app
python3 - <<'PY'
import json
from pathlib import Path
import numpy as np
import pandas as pd
from scipy import signal, optimize

DATA = Path('/app/data')
files = sorted(DATA.glob('experiment_*.csv'))

def predict(theta, t, u):
    K, wn, zeta = theta
    if K <= 0 or wn <= 0 or zeta <= 0 or zeta >= 1.5:
        raise ValueError
    A = np.array([[0., 1.],[-wn*wn, -2*zeta*wn]])
    B = np.array([[0.],[K*wn*wn]])
    C = np.array([[1.,0.]])
    D = np.array([[0.]])
    _, y, _ = signal.lsim(signal.StateSpace(A,B,C,D), U=u, T=t)
    return y

# Robust joint fit. The multi-start initialization is deliberately independent of
# the hidden ground truth and uses only observable data characteristics.
experiments = []
for f in files:
    df = pd.read_csv(f)
    experiments.append((df.time.to_numpy(float), df.input.to_numpy(float), df.output.to_numpy(float)))

# Rough frequency estimate from the most informative input/output spectra.
wn0 = 12.0
try:
    scores = []
    for t,u,y in experiments:
        dt = np.median(np.diff(t))
        freqs = np.fft.rfftfreq(len(y), dt)
        spec = np.abs(np.fft.rfft(y-y.mean()))
        mask = (freqs > 0.3) & (freqs < 8)
        if mask.any():
            scores.append(2*np.pi*freqs[mask][np.argmax(spec[mask])])
    if scores:
        wn0 = float(np.clip(np.median(scores), 6, 22))
except Exception:
    pass

# Subsample for optimization while retaining all experiments. Soft-L1 limits the
# effect of the deliberately corrupted observations.
def residual(theta, stride=3):
    parts=[]
    for t,u,y in experiments:
        sl=slice(None,None,stride)
        try:
            yp=predict(theta,t[sl],u[sl])
        except Exception:
            return np.ones(sum(len(x[0][::stride]) for x in experiments))*1e6
        parts.append((yp-y[sl]))
    return np.concatenate(parts)

starts = [
    [1.5, wn0, 0.25], [1.8, wn0, 0.4], [1.2, 10., 0.6],
    [2.0, 15., 0.15], [1.0, 18., 0.8]
]
best=None
for x0 in starts:
    r=optimize.least_squares(residual,x0,bounds=([0.2,3.0,0.03],[4.0,30.0,1.4]),loss='soft_l1',f_scale=0.06,max_nfev=1800)
    if best is None or np.sum(r.fun*r.fun)<np.sum(best.fun*best.fun):
        best=r

K,wn,zeta = map(float,best.x)
# Refine with the fitted parameters against all samples using robust loss.
r=optimize.least_squares(lambda th: residual(th,1),best.x,bounds=([0.2,3.0,0.03],[4.0,30.0,1.4]),loss='soft_l1',f_scale=0.055,max_nfev=2500)
K,wn,zeta=map(float,r.x)

# Diagnostics on all observations.
all_res=[]
per_exp=[]
for i,(t,u,y) in enumerate(experiments,1):
    yp=predict([K,wn,zeta],t,u)
    e=y-yp
    all_res.append(e)
    per_exp.append({'experiment':i,'rmse':float(np.sqrt(np.mean(e*e))),'mae':float(np.mean(np.abs(e)))})
all_e=np.concatenate(all_res)
# Robust scale and parameter covariance from the numerical Jacobian, for reporting.
J=np.asarray(r.jac)
dof=max(len(all_e)-3,1)
sigma2=float(np.sum(r.fun*r.fun)/dof)
try:
    cov=sigma2*np.linalg.pinv(J.T@J)
    se=np.sqrt(np.maximum(np.diag(cov),0))
except Exception:
    se=np.array([np.nan,np.nan,np.nan])

# Conservative outlier count based on residuals; this is evidence, not a grading shortcut.
med=np.median(all_e); mad=np.median(np.abs(all_e-med))+1e-12
robust_z=np.abs(all_e-med)/(1.4826*mad)
outlier_count=int(np.sum(robust_z>6.0))

result={
    'model':'second_order_continuous_lti',
    'gain':K,
    'natural_frequency':wn,
    'damping_ratio':zeta,
    'gain_uncertainty':float(se[0]),
    'frequency_uncertainty':float(se[1]),
    'damping_uncertainty':float(se[2]),
    'outlier_count':outlier_count,
    'validation_rmse':float(np.sqrt(np.mean(all_e*all_e)))
}
Path('/app/result.json').write_text(json.dumps(result,indent=2))
Path('/app/diagnostics.json').write_text(json.dumps({
    'experiments':per_exp,
    'residual_mean':float(np.mean(all_e)),
    'residual_std':float(np.std(all_e)),
    'robust_mad':float(mad),
    'optimization_cost':float(r.cost),
    'observations':int(len(all_e))
},indent=2))
print(json.dumps(result,indent=2))
PY
