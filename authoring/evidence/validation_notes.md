# Validation notes

The data generator uses seed 481927 and creates five experiments with step, multisine, PRBS, chirp, and multistep excitation. Experiments 3 and 5 contain seven injected response corruptions each. The independently generated physical parameters are retained only in authoring/provenance and in the sealed verifier.

Before submission, run the oracle and nop Harbor checks repeatedly. The oracle must return 1 and nop must return 0 on every run. The author should also run the benchmark's quality check and difficulty probe.
