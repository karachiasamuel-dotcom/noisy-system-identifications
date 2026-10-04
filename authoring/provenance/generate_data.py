import json
from pathlib import Path
import numpy as np
from scipy import signal

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / 'environment' / 'data'
DATA.mkdir(parents=True, exist_ok=True)

# Independent synthetic ground truth. This file is never copied into the agent image.
SEED = 481927
rng = np.random.default_rng(SEED)
K = 1.73
WN = 12.85
ZETA = 0.315

# Continuous-time state model: x'' + 2*zeta*wn*x' + wn^2*x = K*wn^2*u
A = np.array([[0.0, 1.0],[-WN**2, -2*ZETA*WN]])
B = np.array([[0.0],[K*WN**2]])
C = np.array([[1.0,0.0]])
D = np.array([[0.0]])

def simulate(t, u):
    sys = signal.StateSpace(A,B,C,D)
    tout, y, _ = signal.lsim(sys, U=u, T=t)
    return y

experiments = []

# 1: step excitation, fine sampling
for i, spec in enumerate([
    ('step', 0.01, 12.0),
    ('sine', 0.008, 14.0),
    ('prbs', 0.012, 15.0),
    ('chirp', 0.015, 16.0),
    ('multistep', 0.01, 13.0),
], start=1):
    kind, dt, duration = spec
    t = np.arange(0, duration + 1e-10, dt)
    if kind == 'step':
        u = np.ones_like(t)
        u[t < 0.8] = 0.0
    elif kind == 'sine':
        u = 0.75*np.sin(2*np.pi*0.8*t) + 0.35*np.sin(2*np.pi*2.1*t + 0.4)
    elif kind == 'prbs':
        block = np.floor(t/0.096).astype(int)
        vals = rng.choice([-1.0, 1.0], size=block.max()+1)
        u = 0.85*vals[block]
    elif kind == 'chirp':
        u = 0.7*signal.chirp(t, f0=0.25, f1=3.8, t1=duration, method='linear')
    else:
        u = np.where(t < 2.0, 0.0, np.where(t < 4.5, 0.8, np.where(t < 7.0, -0.45, np.where(t < 9.5, 1.15, -0.7))))
    y = simulate(t, u)
    noise = rng.normal(0, 0.035 + 0.008*np.std(y), size=len(y))
    yobs = y + noise
    outlier_idx = []
    if i in (3,5):
        candidates = rng.choice(np.arange(80, len(y)-80), size=7, replace=False)
        outlier_idx = sorted(int(x) for x in candidates)
        yobs[candidates] += rng.normal(0, 0.8, size=len(candidates))
    header = 'time,input,output\n'
    lines = [header]
    lines += [f'{tt:.8f},{uu:.10f},{yy:.10f}\n' for tt,uu,yy in zip(t,u,yobs)]
    path = DATA / f'experiment_{i:02d}.csv'
    path.write_text(''.join(lines))
    experiments.append({'id': i, 'kind': kind, 'dt': dt, 'n': len(t), 'outlier_indices': outlier_idx})

truth = {
    'seed': SEED,
    'model_family': 'second_order_continuous_lti',
    'gain': K,
    'natural_frequency': WN,
    'damping_ratio': ZETA,
    'experiments': experiments,
}
(ROOT / 'authoring' / 'provenance' / 'ground_truth_manifest.json').write_text(json.dumps(truth, indent=2))
print(json.dumps(truth, indent=2))
