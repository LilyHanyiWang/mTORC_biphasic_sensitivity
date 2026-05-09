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
sweepOptions = model4_default_sin1_sweep(model, model.y0);
sweepResults = model4_run_sin1_sweep(model, model.y0, sweepOptions, struct());
sweepTable = sweepResults.sweepTable;

writetable(sweepTable, fullfile(outputDir, 'sin1_sweep_results.csv'));
save(fullfile(outputDir, 'sin1_sweep_results.mat'), ...
    'sweepTable', 'sweepOptions', 'sweepResults', 'model');

figure('Color', 'w', 'Position', [100 100 950 420]);

subplot(1, 2, 1);
semilogx(sweepResults.sin1InitialValues, sweepResults.finalPs6k1, '-o', ...
    'LineWidth', 1.6, 'MarkerSize', 4, 'MarkerFaceColor', [0.1 0.4 0.8]);
xlabel('Initial total SIN1');
ylabel('Final pS6K1');
title('SIN1-mTORC1 Response');
grid on;

subplot(1, 2, 2);
semilogx(sweepResults.sin1InitialValues, sweepResults.peakPs6k1, '-o', ...
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
fprintf('Sweep points: %d\n', numel(sweepResults.sin1InitialValues));
fprintf('Biphasic index: %.6f\n', sweepResults.biphasicIndex);
fprintf('Results written to: %s\n', outputDir);
