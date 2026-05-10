% run_model4_local_perturbation.m
% -------------------------------------------------------------------------
% Section 2.2 - Local Perturbation Analysis of Influential Parameters
% -------------------------------------------------------------------------
% Implements the local perturbation analysis for Model 4 described in
% Section 2.2 of the project task description:
%
%   2.2.1 Parameter selection
%       The three input factors with the highest total-order Sobol indices
%       are perturbed: initial value of mTORC1, ki13, and kf7.
%
%   2.2.2 Perturbation scheme
%       Each parameter is varied around its calibrated baseline value by
%       +/- 1, 5, 10, 15, 20, 25, 50, and 100 percent (16 perturbed
%       configurations per parameter, plus the unperturbed baseline). All
%       other parameters and initial conditions are held at their nominal
%       baseline values, isolating the effect of each factor individually.
%
%   2.2.3 Simulations and recorded outputs
%       For each perturbed configuration, the Model 4 ODE system is
%       integrated from t = 0 to t = 300 min under sustained 100 nM
%       insulin. The script records:
%         (i)   pS6K1 time course over 0-300 min,
%         (ii)  steady-state pS6K1 and pAKT-S473 at t = 300 min,
%         (iii) Biphasic Index (BI) computed from the SIN1-pS6K1
%               dose-response curve as
%                       BI = (b - a) / (b + a)
%               where, after peak-normalising the curve so that its
%               maximum equals 1,
%                   a = 1 - pS6K1_norm(lowest  SIN1)
%                     = (peak - pS6K1_low ) / peak
%                   b = 1 - pS6K1_norm(highest SIN1)
%                     = (peak - pS6K1_high) / peak
%               i.e. a and b are the vertical gaps from the peak line
%               down to the curve at the lowest and highest SIN1 levels
%               tested (Fig. 6A panel A in Ghomlaghi et al., 2021). With
%               this convention, BI = -1 for a strictly monotonically
%               increasing response (peak at the high end => b = 0),
%               BI = +1 for a strictly monotonically decreasing response
%               (peak at the low end => a = 0), and BI ~= 0 indicates a
%               pronounced biphasic pattern.
%
% The same best-fit Model 4 parameter set used in run_model4_baseline.m is
% used here (minimum objective-function row from ParameterSets.xlsx).
% -------------------------------------------------------------------------

clear;
clc;

scriptDir  = fileparts(mfilename('fullpath'));
projectDir = fileparts(scriptDir);
outputDir  = fullfile(projectDir, 'results', 'model4_local_perturbation');

addpath(scriptDir);
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

% -------------------------------------------------------------------------
% 1. Baseline model setup
% -------------------------------------------------------------------------
baseModel = model4_setup(projectDir);

% Override the insulin protocol: 100 nM sustained insulin from t = 0 to
% t = 300 min, matching the simulation conditions of Section 2.2.3.
baseModel.constants.Timeinput1 = 0;     % insulin onset at t = 0
baseModel.constants.Tinfinput1 = 300;   % insulin on for the full window
baseModel.params.Ins0          = 100;   % 100 nM insulin amplitude

% Time grid for the main 0-300 min simulation (0.5 min resolution).
tEval = linspace(0, 300, 601)';

% State indices used repeatedly below.
stateNames    = baseModel.stateNames;
mTORC1Idx     = find(strcmp(stateNames, 'mTORC1'));
sin1Idx       = find(strcmp(stateNames, 'Sin1'));
ps6k1Idx      = find(strcmp(stateNames, 'ps6k1'));
pAkt473Idx    = find(strcmp(stateNames, 'pAkt473'));
pAkt308473Idx = find(strcmp(stateNames, 'pAkt308473'));

% -------------------------------------------------------------------------
% 2. Perturbation specification
% -------------------------------------------------------------------------
% Sixteen signed perturbation magnitudes, ordered from -100% to +100%.
perturbations = [-1.00 -0.50 -0.25 -0.20 -0.15 -0.10 -0.05 -0.01 ...
                  0.01  0.05  0.10  0.15  0.20  0.25  0.50  1.00]';
nPert = numel(perturbations);

% Three influential parameters identified from the global sensitivity
% analysis. 'mTORC1_init' is treated specially because it is an initial
% condition rather than a kinetic rate constant.
paramsToPerturb   = {'mTORC1_init', 'ki13', 'kf7'};
paramDisplayNames = {'Initial mTORC1', 'k_{i13}', 'k_{f7}'};

% -------------------------------------------------------------------------
% 3. SIN1 dose-response sweep configuration (used for BI)
% -------------------------------------------------------------------------
% A log-spaced sweep of total initial SIN1 from 0.01x to 100x of the
% baseline value, matching run_model4_sin1_sweep.m. 41 points strikes a
% balance between dose-response resolution and runtime.
sin1FoldChange    = logspace(-2, 2, 41)';
baselineSin1      = baseModel.y0(sin1Idx);
sin1InitialValues = baselineSin1 .* sin1FoldChange;
nSin1             = numel(sin1InitialValues);

% -------------------------------------------------------------------------
% 4. Unperturbed baseline simulation and baseline BI
% -------------------------------------------------------------------------
fprintf('Running unperturbed baseline (100 nM insulin, 0-300 min)...\n');
[~, y_base, obs_base] = model4_simulate(baseModel, baseModel.y0, tEval);
ps6k1_baseline      = obs_base.phosphos6k1r;
ss_pS6K1_baseline   = obs_base.phosphos6k1r(end);
ss_pAkt473_baseline = obs_base.phosphoAkt473r(end);

fprintf('Running baseline SIN1 sweep (%d points) for BI...\n', nSin1);
sin1Curve_baseline = run_sin1_sweep(baseModel, baseModel.y0, ...
                                    sin1Idx, sin1InitialValues, tEval);
BI_baseline = compute_bi(sin1Curve_baseline);

fprintf('Baseline: pS6K1_ss=%.4g | pAkt473_ss=%.4g | BI=%+.4f\n', ...
        ss_pS6K1_baseline, ss_pAkt473_baseline, BI_baseline);

% -------------------------------------------------------------------------
% 5. Loop over the three parameters and the 16 perturbations
% -------------------------------------------------------------------------
results = struct();

for p = 1:numel(paramsToPerturb)
    paramName = paramsToPerturb{p};
    fprintf('\n=== Perturbing parameter: %s ===\n', paramName);

    % Resolve the calibrated baseline value for this parameter.
    if strcmp(paramName, 'mTORC1_init')
        baselineValue = baseModel.y0(mTORC1Idx);
    else
        baselineValue = baseModel.params.(paramName);
    end
    fprintf('  Baseline value: %.6g\n', baselineValue);

    % Allocate output containers for this parameter.
    perturbedValues  = zeros(nPert, 1);
    pS6K1_timeCourse = zeros(numel(tEval), nPert);
    ss_pS6K1         = zeros(nPert, 1);
    ss_pAkt473       = zeros(nPert, 1);
    BI               = zeros(nPert, 1);
    sin1Curves       = zeros(nSin1, nPert);

    for k = 1:nPert
        delta    = perturbations(k);
        newValue = baselineValue * (1 + delta);
        perturbedValues(k) = newValue;

        % Build the perturbed model: only the chosen factor is changed.
        thisModel = baseModel;
        y0        = baseModel.y0;
        if strcmp(paramName, 'mTORC1_init')
            y0(mTORC1Idx) = newValue;
        else
            thisModel.params.(paramName) = newValue;
        end

        % --- Output (i) and (ii): main 0-300 min simulation -----------
        [~, ~, obsK] = model4_simulate(thisModel, y0, tEval);
        pS6K1_timeCourse(:, k) = obsK.phosphos6k1r;
        ss_pS6K1(k)            = obsK.phosphos6k1r(end);
        ss_pAkt473(k)          = obsK.phosphoAkt473r(end);

        % --- Output (iii): SIN1 sweep and Biphasic Index --------------
        sin1Curves(:, k) = run_sin1_sweep(thisModel, y0, ...
                                          sin1Idx, sin1InitialValues, tEval);
        BI(k) = compute_bi(sin1Curves(:, k));

        fprintf(['  %s: %+5.0f%% (val=%.4g) | pS6K1_ss=%.4g | ' ...
                 'pAkt473_ss=%.4g | BI=%+.4f\n'], ...
                paramName, delta*100, newValue, ss_pS6K1(k), ...
                ss_pAkt473(k), BI(k));
    end

    % Pack per-parameter results.
    results.(paramName) = struct( ...
        'displayName',       paramDisplayNames{p}, ...
        'baselineValue',     baselineValue, ...
        'perturbations',     perturbations, ...
        'perturbedValues',   perturbedValues, ...
        'tEval',             tEval, ...
        'pS6K1_timeCourse',  pS6K1_timeCourse, ...
        'ss_pS6K1',          ss_pS6K1, ...
        'ss_pAkt473',        ss_pAkt473, ...
        'BI',                BI, ...
        'sin1FoldChange',    sin1FoldChange, ...
        'sin1InitialValues', sin1InitialValues, ...
        'sin1Curves',        sin1Curves);
end

% -------------------------------------------------------------------------
% 6. Save numerical outputs (CSV + MAT)
% -------------------------------------------------------------------------
fprintf('\nWriting CSV and MAT outputs to %s ...\n', outputDir);

% Per-parameter CSVs.
for p = 1:numel(paramsToPerturb)
    paramName = paramsToPerturb{p};
    R         = results.(paramName);

    % Summary table: one row per perturbation.
    summaryT = table( ...
        R.perturbations, ...
        R.perturbations * 100, ...
        R.perturbedValues, ...
        R.ss_pS6K1, ...
        R.ss_pAkt473, ...
        R.BI, ...
        'VariableNames', { ...
            'perturbation_fraction', ...
            'perturbation_percent', ...
            'parameter_value', ...
            'pS6K1_steady_state', ...
            'pAkt_S473_steady_state', ...
            'biphasic_index'});
    writetable(summaryT, fullfile(outputDir, ...
        sprintf('summary_%s.csv', paramName)));

    % pS6K1 time course matrix: first column is time, remaining columns
    % correspond to each perturbation (header encodes the percentage).
    % Use 'p' / 'm' as sign tokens so the headers are valid identifiers.
    pertHeaders = cell(nPert, 1);
    for k = 1:nPert
        pct = round(R.perturbations(k) * 100);
        if pct >= 0
            pertHeaders{k} = sprintf('pct_p%d', pct);
        else
            pertHeaders{k} = sprintf('pct_m%d', abs(pct));
        end
    end

    timeCourseT = array2table([R.tEval, R.pS6K1_timeCourse], ...
        'VariableNames', [{'time_min'}, pertHeaders']);
    writetable(timeCourseT, fullfile(outputDir, ...
        sprintf('pS6K1_timecourse_%s.csv', paramName)));

    % SIN1 dose-response curves (one column per perturbation).
    sin1CurveT = array2table([R.sin1InitialValues, R.sin1Curves], ...
        'VariableNames', [{'sin1_initial_total'}, pertHeaders']);
    writetable(sin1CurveT, fullfile(outputDir, ...
        sprintf('sin1_curve_%s.csv', paramName)));
end

% Baseline (unperturbed) CSV for reference.
baselineT = table( ...
    {'baseline'}, ss_pS6K1_baseline, ss_pAkt473_baseline, BI_baseline, ...
    'VariableNames', {'configuration', 'pS6K1_steady_state', ...
                      'pAkt_S473_steady_state', 'biphasic_index'});
writetable(baselineT, fullfile(outputDir, 'summary_baseline.csv'));

baselineSin1T = table(sin1InitialValues, sin1Curve_baseline, ...
    'VariableNames', {'sin1_initial_total', 'pS6K1_final'});
writetable(baselineSin1T, fullfile(outputDir, 'sin1_curve_baseline.csv'));

% MAT snapshot of all results.
save(fullfile(outputDir, 'local_perturbation_results.mat'), ...
    'results', 'baseModel', 'tEval', 'perturbations', ...
    'paramsToPerturb', 'paramDisplayNames', ...
    'sin1FoldChange', 'sin1InitialValues', ...
    'ps6k1_baseline', 'ss_pS6K1_baseline', 'ss_pAkt473_baseline', ...
    'BI_baseline', 'sin1Curve_baseline');

% -------------------------------------------------------------------------
% 7. Plots
% -------------------------------------------------------------------------
fprintf('Generating plots...\n');
make_perturbation_plots(results, paramsToPerturb, paramDisplayNames, ...
                        ss_pS6K1_baseline, ss_pAkt473_baseline, ...
                        BI_baseline, ps6k1_baseline, ...
                        sin1Curve_baseline, sin1InitialValues, outputDir);

fprintf('\nLocal perturbation analysis complete.\n');
fprintf('Selected baseline parameter set: %d (objective = %.6g)\n', ...
        baseModel.parameterSet.id, baseModel.parameterSet.objective);
fprintf('All outputs saved under: %s\n', outputDir);

% =========================================================================
%                              Helper Functions
% =========================================================================

function finalPs6k1 = run_sin1_sweep(model, y0_base, sin1Idx, ...
                                     sin1InitialValues, tEval)
% RUN_SIN1_SWEEP   SIN1 dose-response sweep for a fixed model configuration.
%   For each requested initial total SIN1 value, integrate the ODE under
%   the prescribed insulin protocol and record the t = 300 min pS6K1
%   value. All other initial conditions and parameters are held fixed at
%   the values supplied in the model / y0_base arguments.

    nPoints    = numel(sin1InitialValues);
    finalPs6k1 = zeros(nPoints, 1);

    for s = 1:nPoints
        y0 = y0_base;
        y0(sin1Idx) = sin1InitialValues(s);
        [~, ~, obs] = model4_simulate(model, y0, tEval);
        finalPs6k1(s) = obs.phosphos6k1r(end);
    end
end

function bi = compute_bi(sin1Curve)
% COMPUTE_BI   Biphasic Index from a SIN1-pS6K1 dose-response curve.
%
%   The curve is first peak-normalised so its maximum equals 1, matching
%   Fig. 6A of Ghomlaghi et al., 2021. Then
%
%       a = 1 - pS6K1_norm(lowest  SIN1) = (peak - pS6K1_low ) / peak
%       b = 1 - pS6K1_norm(highest SIN1) = (peak - pS6K1_high) / peak
%
%   are the vertical gaps from the peak line down to the curve at the
%   lowest and highest SIN1 levels tested, and
%
%       BI = (b - a) / (b + a)
%
%   ranges from -1 (strictly increasing curve, b = 0) through 0
%   (symmetric biphasic decline, a == b) to +1 (strictly decreasing
%   curve, a = 0).

    pS6K1_low  = sin1Curve(1);
    pS6K1_high = sin1Curve(end);
    peakValue  = max(sin1Curve);

    if peakValue <= 0
        bi = 0;
        return;
    end

    a = (peakValue - pS6K1_low ) / peakValue;
    b = (peakValue - pS6K1_high) / peakValue;

    denom = a + b;
    if denom > 0
        bi = (b - a) / denom;
    else
        % Both endpoints sit exactly at the peak: the curve is essentially
        % flat across the tested range, so the biphasic decline is zero.
        bi = 0;
    end
end

function make_perturbation_plots(results, paramsToPerturb, ...
                                  paramDisplayNames, ...
                                  ss_pS6K1_baseline, ss_pAkt473_baseline, ...
                                  BI_baseline, ps6k1_baseline, ...
                                  sin1Curve_baseline, sin1InitialValues, ...
                                  outputDir)
% MAKE_PERTURBATION_PLOTS   Per-parameter four-panel summary plots and a
% SIN1 dose-response figure aggregating all parameters.

    % Continuous diverging colormap reused for every figure.
    cmapContinuous = make_diverging_colormap(256);
    pmaxPct        = 100;   % colorbar range will span -100% to +100%

    for p = 1:numel(paramsToPerturb)
        paramName    = paramsToPerturb{p};
        displayName  = paramDisplayNames{p};
        R            = results.(paramName);
        nPert        = numel(R.perturbations);

        % Discrete line colors for each perturbation (blue->white->red).
        lineColors = zeros(nPert, 3);
        for k = 1:nPert
            tInterp = (R.perturbations(k) + 1) / 2;     % map [-1,1] -> [0,1]
            tInterp = max(0, min(1, tInterp));
            ci      = max(1, min(size(cmapContinuous, 1), ...
                          round(tInterp * (size(cmapContinuous, 1) - 1)) + 1));
            lineColors(k, :) = cmapContinuous(ci, :);
        end

        figH = figure('Color', 'w', 'Position', [80 80 1200 800], ...
                      'Visible', 'off');

        % --- Panel (1): pS6K1 time courses --------------------------------
        ax1 = subplot(2, 2, 1); hold(ax1, 'on');
        for k = 1:nPert
            plot(ax1, R.tEval, R.pS6K1_timeCourse(:, k), ...
                 'Color', lineColors(k, :), 'LineWidth', 1.1);
        end
        plot(ax1, R.tEval, ps6k1_baseline, 'k--', 'LineWidth', 1.6);
        xlabel(ax1, 'Time (min)'); ylabel(ax1, 'pS6K1');
        title(ax1, sprintf('pS6K1 time course (perturbing %s)', displayName));
        grid(ax1, 'on'); box(ax1, 'on');
        colormap(ax1, cmapContinuous);
        caxis(ax1, [-pmaxPct, pmaxPct]);
        cb = colorbar(ax1);
        cb.Label.String = 'Perturbation (%)';

        % --- Panel (2): steady-state pS6K1 vs perturbation ---------------
        subplot(2, 2, 2); hold on;
        plot(R.perturbations * 100, R.ss_pS6K1, '-o', ...
             'Color', [0.10 0.40 0.80], 'MarkerFaceColor', [0.10 0.40 0.80], ...
             'LineWidth', 1.4, 'MarkerSize', 5);
        yline(ss_pS6K1_baseline, 'k--', 'baseline');
        xline(0, 'k:');
        xlabel('Perturbation (%)'); ylabel('Steady-state pS6K1 at t = 300 min');
        title(sprintf('SS pS6K1 vs %s', displayName));
        grid on; box on;

        % --- Panel (3): steady-state pAKT-S473 vs perturbation -----------
        subplot(2, 2, 3); hold on;
        plot(R.perturbations * 100, R.ss_pAkt473, '-o', ...
             'Color', [0.85 0.33 0.10], 'MarkerFaceColor', [0.85 0.33 0.10], ...
             'LineWidth', 1.4, 'MarkerSize', 5);
        yline(ss_pAkt473_baseline, 'k--', 'baseline');
        xline(0, 'k:');
        xlabel('Perturbation (%)'); ylabel('Steady-state pAKT-S473 at t = 300 min');
        title(sprintf('SS pAKT-S473 vs %s', displayName));
        grid on; box on;

        % --- Panel (4): Biphasic Index vs perturbation -------------------
        subplot(2, 2, 4); hold on;
        plot(R.perturbations * 100, R.BI, '-o', ...
             'Color', [0.45 0.20 0.55], 'MarkerFaceColor', [0.45 0.20 0.55], ...
             'LineWidth', 1.4, 'MarkerSize', 5);
        yline(BI_baseline, 'k--', 'baseline');
        yline(0, 'Color', [0.5 0.5 0.5], 'LineStyle', ':');
        xline(0, 'k:');
        xlabel('Perturbation (%)'); ylabel('Biphasic Index (BI)');
        title(sprintf('BI vs %s', displayName));
        grid on; box on; ylim([-1.05, 1.05]);

        sgtitle(sprintf('Local perturbation of %s (Model 4)', displayName));

        figFile = fullfile(outputDir, sprintf('perturbation_%s', paramName));
        saveas(figH, [figFile '.png']);
        savefig(figH, [figFile '.fig']);
        close(figH);
    end

    % Aggregated SIN1 dose-response curves for each perturbed parameter.
    figS = figure('Color', 'w', 'Position', [80 80 1200 380], 'Visible', 'off');
    for p = 1:numel(paramsToPerturb)
        paramName   = paramsToPerturb{p};
        displayName = paramDisplayNames{p};
        R           = results.(paramName);
        nPert       = numel(R.perturbations);

        lineColors = zeros(nPert, 3);
        for k = 1:nPert
            tInterp = (R.perturbations(k) + 1) / 2;
            tInterp = max(0, min(1, tInterp));
            ci      = max(1, min(size(cmapContinuous, 1), ...
                          round(tInterp * (size(cmapContinuous, 1) - 1)) + 1));
            lineColors(k, :) = cmapContinuous(ci, :);
        end

        axS = subplot(1, numel(paramsToPerturb), p); hold(axS, 'on');
        for k = 1:nPert
            plot(axS, R.sin1InitialValues, R.sin1Curves(:, k), ...
                 'Color', lineColors(k, :), 'LineWidth', 1.0);
        end
        plot(axS, sin1InitialValues, sin1Curve_baseline, 'k--', ...
             'LineWidth', 1.6);
        set(axS, 'XScale', 'log');
        xlabel(axS, 'Initial total SIN1');
        ylabel(axS, 'pS6K1 at t = 300 min');
        title(axS, sprintf('SIN1 dose-response (%s)', displayName));
        grid(axS, 'on'); box(axS, 'on');

        colormap(axS, cmapContinuous);
        caxis(axS, [-pmaxPct, pmaxPct]);
        cbS = colorbar(axS);
        cbS.Label.String = 'Perturbation (%)';
    end
    sgtitle('SIN1-pS6K1 dose-response curves under local perturbations');
    saveas(figS, fullfile(outputDir, 'sin1_dose_response_grid.png'));
    savefig(figS, fullfile(outputDir, 'sin1_dose_response_grid.fig'));
    close(figS);
end

function cmap = make_diverging_colormap(n)
% MAKE_DIVERGING_COLORMAP   Continuous blue-white-red diverging colormap
% used both for line colors (sampled at each perturbation value) and as
% the axis colormap so that the attached colorbar correctly labels the
% perturbation percentage on a [-100, 100] scale via caxis.

    if nargin < 1
        n = 256;
    end

    blue = [0.10 0.30 0.85];
    mid  = [0.92 0.92 0.92];
    red  = [0.85 0.20 0.20];

    cmap = zeros(n, 3);
    half = floor(n / 2);
    for i = 1:half
        w = (half - i + 1) / half;          % 1 at i=1, ~0 at i=half
        cmap(i, :) = mid + (blue - mid) * w;
    end
    for i = (half + 1):n
        w = (i - half) / (n - half);        % ~0 at i=half+1, 1 at i=n
        cmap(i, :) = mid + (red - mid) * w;
    end
end
