clear;
clc;

scriptDir = fileparts(mfilename('fullpath'));
projectDir = fileparts(scriptDir);
outputDir = fullfile(projectDir, 'results', 'model4_sin1_sweep');

addpath(scriptDir);

if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

model = model4_setup(projectDir);

sin1Index = find(strcmp(model.stateNames, 'Sin1'));
baselineTotalSin1 = model.y0(sin1Index);

sin1FoldChange = logspace(-2, 2, 61)';
sin1InitialValues = baselineTotalSin1 .* sin1FoldChange;

nPoints = numel(sin1InitialValues);
finalPs6k1 = zeros(nPoints, 1);
peakPs6k1 = zeros(nPoints, 1);
finalPmTORC1 = zeros(nPoints, 1);
finalTotalmTORC1 = zeros(nPoints, 1);
finalTotalmTORC2 = zeros(nPoints, 1);
finalFreeSin1 = zeros(nPoints, 1);

tStop = model.constants.Timeinput1 + model.constants.Tinfinput1 + 3000;
tEval = linspace(0, tStop, 2001);

for i = 1:nPoints
    y0 = model.y0;
    y0(sin1Index) = sin1InitialValues(i);

    [t, y, observables] = model4_simulate(model, y0, tEval);

    finalPs6k1(i) = observables.phosphos6k1r(end);
    peakPs6k1(i) = max(observables.phosphos6k1r);
    finalPmTORC1(i) = y(end, strcmp(model.stateNames, 'pmTORC1'));
    finalTotalmTORC1(i) = observables.totalmTORC1r(end);
    finalTotalmTORC2(i) = observables.totalmTORC2r(end);
    finalFreeSin1(i) = y(end, sin1Index);
end

sweepTable = table( ...
    sin1FoldChange, ...
    sin1InitialValues, ...
    finalFreeSin1, ...
    finalTotalmTORC2, ...
    finalTotalmTORC1, ...
    finalPmTORC1, ...
    finalPs6k1, ...
    peakPs6k1, ...
    'VariableNames', { ...
    'sin1_fold_change', ...
    'sin1_initial_total', ...
    'sin1_final_free', ...
    'mTORC2_total_final', ...
    'mTORC1_total_final', ...
    'pmTORC1_final', ...
    'pS6K1_final', ...
    'pS6K1_peak'});

writetable(sweepTable, fullfile(outputDir, 'sin1_sweep_results.csv'));
save(fullfile(outputDir, 'sin1_sweep_results.mat'), ...
    'sweepTable', 'sin1FoldChange', 'sin1InitialValues', ...
    'finalPs6k1', 'peakPs6k1', 'finalPmTORC1', ...
    'finalTotalmTORC1', 'finalTotalmTORC2', 'finalFreeSin1', ...
    'model');

figure('Color', 'w', 'Position', [100 100 950 420]);

subplot(1, 2, 1);
semilogx(sin1InitialValues, finalPs6k1, '-o', ...
    'LineWidth', 1.6, 'MarkerSize', 4, 'MarkerFaceColor', [0.1 0.4 0.8]);
xlabel('Initial total SIN1');
ylabel('Final pS6K1');
title('SIN1-mTORC1 Response');
grid on;

subplot(1, 2, 2);
semilogx(sin1InitialValues, peakPs6k1, '-o', ...
    'LineWidth', 1.6, 'MarkerSize', 4, 'MarkerFaceColor', [0.85 0.33 0.1]);
xlabel('Initial total SIN1');
ylabel('Peak pS6K1');
title('SIN1-mTORC1 Response (Peak)');
grid on;

sgtitle(sprintf('Model 4 SIN1 Sweep (Set %d)', model.parameterSet.id));

saveas(gcf, fullfile(outputDir, 'sin1_sweep_curve.png'));
savefig(gcf, fullfile(outputDir, 'sin1_sweep_curve.fig'));
close(gcf);

fprintf('Model 4 SIN1 sweep complete.\n');
fprintf('Selected parameter set: %d\n', model.parameterSet.id);
fprintf('Sweep points: %d\n', nPoints);
fprintf('Results written to: %s\n', outputDir);
