# Noisy System Identification

## Difficulty

This is a scientific system-identification workflow rather than a short programming exercise. The supplied data are **synthetic**, generated from an independently defined continuous-time dynamical system with multiple excitation regimes, unequal sampling intervals, measurement noise, and deliberately injected corrupt observations. The reference solution is not used to generate the ground truth.

A focused domain expert is expected to spend several hours exploring the observations, selecting an appropriate model representation, fitting coupled parameters robustly, checking residual behavior, and validating the model across independent experiments.

## Reference solution

`solution/solve.sh` performs a robust joint nonlinear fit across all five experiments, using multiple data-driven starting points and a second refinement pass. It then computes parameter uncertainty and validation diagnostics and writes `/app/result.json` and `/app/diagnostics.json`.

## Verification

The verifier is built as a separate offline image. The agent cannot see `tests/ground_truth.json` because the ground-truth values are encoded directly in the verifier test module. The verifier checks the required model family, parameter tolerances, uncertainty fields, anomaly count, aggregate validation RMSE, and the presence and numerical validity of diagnostics for all five experiments. `tests/test.sh` always writes exactly `0` or `1` to `/logs/verifier/reward.txt` and emits a CTRF report.

The synthetic measurements and ground truth were created independently by `authoring/provenance/generate_data.py` using a fixed seed. The provenance materials are not mounted into the agent container.
