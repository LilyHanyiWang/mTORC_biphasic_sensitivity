# Model 4 SIN1 Sweep Summary

## What Was Varied

The sweep varies the `Sin1` state in Model 4. In the local ODE model, `Sin1` is the free SIN1 pool and participates in mTORC2 assembly through:

`GBL + Sin1 <-> mTORC2`

Because the baseline initial conditions are:

- `Sin1(0) = 100`
- `mTORC2(0) = 0`
- `pmTORC2(0) = 0`

the initial total SIN1 pool is equal to `Sin1(0)`. The sweep therefore changes only `Sin1(0)` while leaving every other initial condition and every parameter unchanged.

## What Output Was Measured

The primary mTORC1 activity readout is final `pS6K1`, taken from:

- state variable `ps6k1`
- observable `phosphos6k1r = ps6k1`

This is a direct downstream readout of mTORC1 activity in the model and is the main output used for the SIN1-response curve.

For additional context, the sweep also saves:

- peak `pS6K1`
- final `pmTORC1`
- final total `mTORC1`
- final total `mTORC2`
- final free `Sin1`

## How The Curve Was Generated

The MATLAB script [run_model4_sin1_sweep.m](/Users/cecilia/Desktop/BME530/mTORC_biphasic_sensitivity/model4/run_model4_sin1_sweep.m) performs the following steps:

1. Load the same Model 4 parameter set and baseline initial conditions used by the baseline simulation.
2. Identify the `Sin1` state index from `model.stateNames`.
3. Replace only `Sin1(0)` with a log-spaced sweep from `0.01x` to `100x` of the baseline value, using 61 points.
4. Run the unchanged ODE model for each SIN1 level.
5. Record the final-time `pS6K1` value as the main mTORC1 output.
6. Plot initial total SIN1 versus final `pS6K1` on a log-scaled x-axis.

The simulation helper [model4_simulate.m](/Users/cecilia/Desktop/BME530/mTORC_biphasic_sensitivity/model4/model4_simulate.m) is used so the sweep reuses the same solver settings and observable calculations as the baseline run.

The shared helper [model4_run_sin1_sweep.m](/Users/cecilia/Desktop/BME530/mTORC_biphasic_sensitivity/model4/model4_run_sin1_sweep.m) now underpins:

- the standalone SIN1 sweep script
- the baseline validation workflow
- the Goal 1 eFAST sensitivity pipeline

The sweep also computes a reusable biphasic index through [compute_biphasic_index.m](/Users/cecilia/Desktop/BME530/mTORC_biphasic_sensitivity/model4/compute_biphasic_index.m), while keeping `final pS6K1` as the primary mTORC1 activity readout.

## How To Interpret The Result

If the reproduced curve is biphasic, then increasing SIN1 should:

- first increase mTORC1 output over a lower SIN1 range
- then reduce mTORC1 output over a higher SIN1 range

In this model, that interpretation is consistent with competition involving mLST8 partitioning between mTORC1 and mTORC2 assembly, together with downstream Akt-TSC2-mTORC1 signaling and feedback regulation.

If the curve appears monotonic instead, likely causes to check are:

- the chosen SIN1 range is too narrow
- the final-time readout does not fully capture the response shape, in which case peak `pS6K1` may be informative
- the baseline parameter set differs from the exact one used for the paper figure

## Files Produced When Run In MATLAB

The script writes results to `results/model4_sin1_sweep`:

- `sin1_sweep_results.csv`
- `sin1_sweep_results.mat`
- `sin1_sweep_curve.png`
- `sin1_sweep_curve.fig`

## Explicit Assumptions

- SIN1 is treated as the conserved total pool at time zero because all SIN1 is initially free in the provided Model 4 initial conditions.
- The baseline parameter set remains the same as in the existing Model 4 implementation: the minimum-objective row from `ParameterSets.xlsx`, sheet `Model 4`.
- Final `pS6K1` is used as the main mTORC1 activity measure because it is a direct downstream readout in the model and matches the requested paper-relevant output.

## Run Command

```matlab
run('model4/run_model4_sin1_sweep.m')
```

This repository now distinguishes between:

- structural reconstruction and qualitative biphasic validation
- exact paper-level quantitative matching, which still requires explicit figure-by-figure comparison
