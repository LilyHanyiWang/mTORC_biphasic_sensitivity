# Model 4 Local Perturbation Analysis Summary

This document describes how `model4/run_model4_local_perturbation.m`
implements Section 2.2 of the project task description ("Local Perturbation
Analysis of Influential Parameters") for Model 4.

## Files

- MATLAB entry point: `model4/run_model4_local_perturbation.m`
- Reuses: `model4/model4_setup.m`, `model4/model4_simulate.m`,
  `model4/model4_ode.m`, `model4/model4_observables.m`
- Output folder created at runtime: `results/model4_local_perturbation/`

## What The Script Does

1. Loads the same best-fit Model 4 parameter set used by
   `run_model4_baseline.m` (the minimum-objective row from
   `paper_model_parameter/ParameterSets.xlsx`, sheet `Model 4`).
2. Overrides the insulin protocol so that 100 nM insulin is applied
   continuously from t = 0 to t = 300 min by setting
   `Timeinput1 = 0`, `Tinfinput1 = 300`, and `Ins0 = 100`.
3. Perturbs each of the three influential factors identified by the
   global sensitivity analysis: the initial value of `mTORC1`, `ki13`,
   and `kf7`. Each parameter is varied around its calibrated baseline by
   ±1, ±5, ±10, ±15, ±20, ±25, ±50, and ±100 percent, giving 16
   perturbed configurations per parameter plus the unperturbed baseline.
   All other parameters and initial conditions are held at their nominal
   baseline values, isolating the effect of one factor at a time.
4. For each perturbed configuration, integrates the Model 4 ODE system
   from t = 0 to t = 300 min and records:
   - **(i) pS6K1 time course**: the full trajectory of `phosphos6k1r`
     over 0–300 min on a 0.5 min grid.
   - **(ii) Steady-state pS6K1 and pAKT-S473**: the t = 300 min values
     of `phosphos6k1r` and `phosphoAkt473r = pAkt473 + pAkt308473`.
   - **(iii) Biphasic Index (BI)**: a 41-point logarithmic SIN1 sweep
     (initial total SIN1 from 0.01× to 100× the baseline value) is
     performed for the same configuration. The resulting SIN1–pS6K1
     dose–response curve is first peak-normalised so its maximum
     equals 1 (Fig. 6A in Ghomlaghi et al., 2021), and then
     ```
     a  = 1 - pS6K1_norm(lowest  SIN1) = (peak - pS6K1_low ) / peak
     b  = 1 - pS6K1_norm(highest SIN1) = (peak - pS6K1_high) / peak
     BI = (b - a) / (b + a)
     ```
     where `a` and `b` are the vertical gaps from the peak line down
     to the curve at the lowest and highest SIN1 levels tested. With
     this convention BI = −1 for a strictly monotonically increasing
     curve (peak at the high end ⇒ b = 0), BI = +1 for a strictly
     monotonically decreasing curve (peak at the low end ⇒ a = 0),
     and BI ≈ 0 for a pronounced biphasic decline that is roughly
     symmetric across the SIN1 range.

## Outputs

Saved under `results/model4_local_perturbation/`:

- `summary_baseline.csv` – baseline pS6K1, pAKT-S473, BI.
- `summary_<param>.csv` – one row per perturbation with the perturbation
  fraction, percentage, perturbed parameter value, steady-state pS6K1,
  steady-state pAKT-S473, and BI.
- `pS6K1_timecourse_<param>.csv` – time on the first column, pS6K1 for
  each perturbation in the remaining columns. Column headers use
  `pct_p<n>` for +n% and `pct_m<n>` for −n%.
- `sin1_curve_<param>.csv` – initial total SIN1 in the first column,
  the corresponding endpoint pS6K1 for each perturbation in the
  remaining columns.
- `sin1_curve_baseline.csv` – baseline SIN1 dose–response curve.
- `local_perturbation_results.mat` – complete MATLAB workspace with all
  matrices and metadata.
- `perturbation_<param>.png` / `.fig` – four-panel figure (pS6K1 time
  courses, steady-state pS6K1 vs %, steady-state pAKT-S473 vs %, BI
  vs %) for each parameter.
- `sin1_dose_response_grid.png` / `.fig` – overlaid SIN1–pS6K1 dose–
  response curves for every perturbation, side-by-side for the three
  parameters.

The four-panel figures use a continuous blue → white → red diverging
colormap with a `caxis` of ±100 %, so each line in the time-course panel
and in the dose–response panels can be read off the colorbar by
perturbation magnitude.

## How To Run

In MATLAB, with the project root as the working directory:

```matlab
run('model4/run_model4_local_perturbation.m')
```

The script clears the workspace, sets up the output folder, runs all
49 main simulations (1 baseline + 3 × 16 perturbations) and 49 SIN1
sweeps (41 simulations each, ≈ 2009 ODE integrations total), saves all
CSV/MAT outputs, and writes the figures.

## Assumptions And Notes

1. The baseline parameter set is the minimum-objective row from
   `ParameterSets.xlsx`, sheet `Model 4`, matching the convention used
   by `run_model4_baseline.m`.
2. "Steady-state" pS6K1 and pAKT-S473 are defined as the values at
   t = 300 min, as specified in Section 2.2.3 of the task description.
   The system is not necessarily at full mathematical steady state at
   that time; the value is the late-time signaling readout.
3. The "initial value of mTORC1" perturbation modifies `y0(mTORC1)`.
   At −100 %, this places the entire mTORC1 pool at zero. The resulting
   trajectories are degenerate (pS6K1 stays near zero); BI is reported
   as 0 because both `a` and `b` are zero.
4. The SIN1 sweep uses 41 logarithmically spaced points between 0.01×
   and 100× the baseline initial SIN1, which gives the same range as
   `run_model4_sin1_sweep.m` with somewhat coarser resolution to keep
   total runtime manageable (≈ 3-5 min on a typical workstation).
   Increase to 61 points by changing `logspace(-2, 2, 41)` if a finer
   curve is desired.
5. The BI formula uses peak normalisation of the SIN1–pS6K1 curve, as
   shown in Fig. 6A of Ghomlaghi et al., 2021. Because both `a` and `b`
   are normalised by the same peak value, BI is invariant under any
   common positive scaling of the curve (e.g. units of `phosphos6k1r`),
   but the use of the curve maximum in the denominator does matter when
   the curve is non-monotonic.
6. All other simulation settings (ode15s, RelTol = 1e-8, AbsTol = 1e-10,
   non-negativity constraint on every state) are inherited from
   `model4_simulate.m`, so this analysis is consistent with the
   baseline and SIN1-sweep scripts.
