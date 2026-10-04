Analyze the five experimental time-series datasets under `/app/data/` and identify the low-order continuous-time dynamical model that consistently explains the measured output across all experiments.

Your work should treat the CSV files as experimental observations rather than as a pre-labeled training set. Examine the sampling intervals, excitation signals, transient and steady-state behavior, noise, and anomalous measurements. Determine an appropriate model family from the observations, estimate its physically meaningful parameters, and validate the fitted model across all five experiments rather than relying on a single dataset.

You must account for the fact that some observations are corrupted. Use a defensible robust fitting or anomaly-handling strategy, and do not simply discard large portions of the data. Report uncertainty estimates for the fitted physical parameters and quantitative validation diagnostics.

Write the final parameter estimates and diagnostics to exactly these files:

- `/app/result.json`
- `/app/diagnostics.json`

`result.json` must be valid JSON and contain the selected model family, the fitted gain, natural frequency, damping ratio, uncertainty estimate for each of those three parameters, the number of observations identified as anomalous, and the overall validation RMSE. `diagnostics.json` must contain per-experiment validation metrics for all five experiments plus enough aggregate fitting diagnostics to make the validation reproducible.

The numerical values must be derived from the supplied observations. Do not copy a pre-existing answer, manufacture values solely to satisfy expected ranges, or use task-specific online solutions.

You may install or use appropriate scientific-computing software available through the container's package manager or Python environment. You have full internet access while working, but the supplied measurements and your analysis must be the basis of the result.

You have 14400 seconds to complete this task. Do not cheat by using online solutions or hints specific to this task.
