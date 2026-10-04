import json
from pathlib import Path
import math

ROOT=Path('/app')
TRUTH={
    'model':'second_order_continuous_lti',
    'gain':1.73,
    'natural_frequency':12.85,
    'damping_ratio':0.315,
}

def load(name):
    p=ROOT/name
    assert p.is_file(), f'missing {name}'
    return json.loads(p.read_text())

def finite(x):
    return isinstance(x,(int,float)) and math.isfinite(float(x))

def test_result_schema_and_fit():
    r=load('result.json')
    assert r.get('model')==TRUTH['model']
    for k in ['gain','natural_frequency','damping_ratio','gain_uncertainty','frequency_uncertainty','damping_uncertainty','outlier_count','validation_rmse']:
        assert k in r
        assert finite(r[k])
    assert 1.64 <= r['gain'] <= 1.82
    assert 12.50 <= r['natural_frequency'] <= 13.20
    assert 0.285 <= r['damping_ratio'] <= 0.345
    assert r['gain_uncertainty'] >= 0
    assert r['frequency_uncertainty'] >= 0
    assert r['damping_uncertainty'] >= 0
    assert 4 <= r['outlier_count'] <= 30
    assert r['validation_rmse'] < 0.12

def test_diagnostics_evidence():
    d=load('diagnostics.json')
    ex=d.get('experiments')
    assert isinstance(ex,list) and len(ex)==5
    ids=[x.get('experiment') for x in ex]
    assert ids==[1,2,3,4,5]
    for x in ex:
        assert finite(x['rmse']) and finite(x['mae'])
        assert x['rmse'] < 0.25
    assert finite(d['optimization_cost'])
    assert d['observations'] > 5000
