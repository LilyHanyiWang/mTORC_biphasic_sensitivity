# Model 4 Reconstruction Summary

## Files

- MATLAB entry point: `model4/run_model4_baseline.m`
- MATLAB functions: `model4/model4_setup.m`, `model4/model4_ode.m`, `model4/model4_observables.m`, `model4/model4_make_plots.m`
- Source equations: `paper_model_parameter/Model4.txtbc`
- Source parameters: `paper_model_parameter/ParameterSets.xlsx` sheet `Model 4`
- Output folder created at runtime: `results/model4_baseline`

## Reconstruction Status

- Structural reconstruction of the published Model 4 ODE system is verified against the local `Model4.txtbc` export.
- The repository now includes a dedicated validation workflow in [run_model4_validation.m](/Users/cecilia/Desktop/BME530/mTORC_biphasic_sensitivity/model4/run_model4_validation.m) that checks for a non-monotonic SIN1-mTORC1 response with an interior dominant peak.
- This baseline should be treated as a faithful local reconstruction, not yet as a claim of exact figure-level agreement with every published plot.

## Assumptions

1. The baseline parameterization is taken to be the best-fitting row from the `Model 4` worksheet, identified as the row with the minimum `Objective function value`.
2. In the local spreadsheet, that baseline corresponds to parameter set `1`.
3. The baseline simulation uses the initial conditions and time-dependent insulin input defined in `Model4.txtbc`:
   - initial states exactly as listed in the model file
   - `Timeinput1 = 5000`
   - `Tinfinput1 = 2000`
   - `Ins(t) = Ins0` for `5000 <= t < 7000`, otherwise `0`
4. `phosphoGBLubir = GBLubi + mTORC1 + pmTORC1` is preserved exactly as defined in the text model, even though the variable name is not biologically self-explanatory.

## State Variables

| State | Biological meaning |
| --- | --- |
| `InsR` | Unphosphorylated insulin receptor |
| `pInsR` | Activated/phosphorylated insulin receptor |
| `IRS` | Unphosphorylated insulin receptor substrate |
| `pIRS` | Activated/phosphorylated IRS |
| `otud` | Inactive OTUD deubiquitinase pool |
| `aotud` | Active OTUD deubiquitinase pool |
| `GBL` | Deubiquitinated mLST8 pool available for SIN1 binding |
| `GBLubi` | Ubiquitinated mLST8 pool available for Raptor binding |
| `Raptor` | Free Raptor subunit |
| `Sin1` | Free SIN1 subunit |
| `mTORC2` | Assembled mTORC2 complex |
| `pmTORC2` | Activated/phosphorylated mTORC2 |
| `mTORC1` | Assembled mTORC1 complex |
| `pmTORC1` | Activated/phosphorylated mTORC1 |
| `Akt` | Unphosphorylated Akt |
| `pAkt473` | Akt phosphorylated on Ser473 only |
| `pAkt308` | Akt phosphorylated on Thr308 only |
| `pAkt308473` | Doubly phosphorylated Akt |
| `s6k1` | Unphosphorylated S6K1 |
| `ps6k1` | Phosphorylated S6K1 |
| `TSC2` | Unphosphorylated TSC2 |
| `pTSC2` | Phosphorylated TSC2 |

## Biological Meaning of the ODEs

| Reaction / ODE contribution | Interpretation |
| --- | --- |
| `R1` | Insulin activates the receptor (`InsR -> pInsR`), opposed by receptor dephosphorylation and inhibited by `pmTORC1` feedback through `ki1` |
| `R2` | Activated receptor phosphorylates IRS (`IRS -> pIRS`), opposed by `kr2` and inhibited by S6K1 feedback through `ki2` |
| `R3` | `pIRS` activates OTUD (`otud -> aotud`) |
| `R4` | Active OTUD deubiquitinates `GBLubi` into `GBL`; the reverse/clearance term scales with `traf` |
| `R5` | Ubiquitinated mLST8 binds Raptor to assemble mTORC1 |
| `R6` | Deubiquitinated mLST8 binds SIN1 to assemble mTORC2 |
| `R7` | `pIRS` drives Akt Thr308 phosphorylation |
| `R8` | `pmTORC2` drives Akt Ser473 phosphorylation |
| `R9` | `pAkt473` acquires Thr308 to form doubly phosphorylated Akt |
| `R10` | `pAkt308` acquires Ser473 to form doubly phosphorylated Akt |
| `R11` | `pAkt308` and `pAkt308473` activate mTORC2 (`mTORC2 -> pmTORC2`) |
| `R12` | Akt-phosphorylated species phosphorylate TSC2 (`TSC2 -> pTSC2`) |
| `R13` | mTORC1 activation depends on assembled `mTORC1` and is inhibited by `TSC2` through `ki13` |
| `R14` | Active mTORC1 phosphorylates S6K1 (`s6k1 -> ps6k1`) |

The state ODEs are mass-balance equations built directly from these 14 reactions. Each species gains flux from reactions that produce it and loses flux from reactions that consume it.

## Role of the Parameters

| Parameter group | Role |
| --- | --- |
| `kf*` | Forward activation, conversion, or assembly rates |
| `km*` | Michaelis or saturation constants used in the nonlinear activation terms |
| `kr*` | Reverse, dephosphorylation, dissociation, or decay rates |
| `ki1`, `ki2`, `ki13` | Feedback inhibition strengths |
| `InsB0` | Basal insulin offset seen by the receptor |
| `Ins0` | Amplitude of the insulin pulse during stimulation |
| `traf` | Scaling factor in the `GBL ->` loss term within reaction `R4` |

## Main Outputs Saved by the MATLAB Code

- `baseline_states.csv`: all 22 state trajectories
- `baseline_observables.csv`: paper-style observables
- `baseline_results.mat`: MATLAB workspace snapshot with trajectories and metadata
- `baseline_outputs.png` and `baseline_outputs.fig`: overview plots

The observables reproduced from `Model4.txtbc` are:

- `phosphoGBLubir = GBLubi + mTORC1 + pmTORC1`
- `phosphoAkt473r = pAkt473 + pAkt308473`
- `phosphoAkt308r = pAkt308 + pAkt308473`
- `phosphos6k1r = ps6k1`
- `phosphoTSC2r = pTSC2`
- `totalmTORC2r = mTORC2 + pmTORC2`
- `totalmTORC1r = mTORC1 + pmTORC1`

## How To Run

Open MATLAB in the project root and run:

```matlab
run('model4/run_model4_baseline.m')
run_model4_validation()
```

## Expected Baseline Behavior

With the default initial conditions, the model starts from an unstimulated state and receives a finite insulin pulse between times `5000` and `7000`. The expected qualitative behavior is:

- rapid activation of `pInsR` and `pIRS` after insulin onset
- increased Akt phosphorylation (`pAkt308`, `pAkt473`, and `pAkt308473`)
- increased activation of `pmTORC2`, `pmTORC1`, and downstream `ps6k1`
- feedback-limited signaling through the inhibitory terms involving `pmTORC1`, `ps6k1`, and `TSC2`

This environment does not have a MATLAB executable available, so the baseline simulation could not be executed here for numerical verification. The MATLAB code is set up to reproduce the model directly from the provided local files when run in MATLAB.

## Explicitly Flagged Ambiguities

- The variable name `GBL` is not expanded in the provided local files; it is interpreted here from model context as the deubiquitinated mLST8 pool.
- The variable `phosphoGBLubir` is retained exactly from the source model definition, but its naming is less transparent than the other observables.
- The workbook contains multiple parameter sets and does not visibly mark one as `default` in the local XML. The implementation therefore uses the minimum-objective row as the baseline set.
