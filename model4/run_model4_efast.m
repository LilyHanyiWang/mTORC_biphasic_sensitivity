function results = run_model4_efast(userOptions)
if nargin < 1 || isempty(userOptions)
    userOptions = struct();
end

scriptDir = fileparts(mfilename('fullpath'));
projectDir = fileparts(scriptDir);
outputDir = fullfile(projectDir, 'results', 'model4_efast');

addpath(scriptDir);

if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

options = struct();
options.sampleCount = 129;
options.interferenceFactor = 4;
options.randomSeed = 1234;
options.progressEvery = 25;
options.storeRepresentativeCurves = true;

userFields = fieldnames(userOptions);
for i = 1:numel(userFields)
    options.(userFields{i}) = userOptions.(userFields{i});
end

model = model4_setup(projectDir);
inputInfo = model4_goal1_inputs(model);
sampleSpec = model4_generate_efast_samples(inputInfo, options);
baselineSweepOptions = model4_default_sin1_sweep(model, model.y0);

nSamples = size(sampleSpec.sampleMatrix, 1);
nSweepPoints = numel(baselineSweepOptions.sin1InitialValues);
biphasicIndexValues = nan(nSamples, 1);
statusMessage = repmat({''}, nSamples, 1);
simulationSucceeded = false(nSamples, 1);
responseCurves = nan(nSamples, nSweepPoints);
peakSin1 = nan(nSamples, 1);
peakResponse = nan(nSamples, 1);
classification = repmat({''}, nSamples, 1);

for sampleId = 1:nSamples
    sampledValues = sampleSpec.sampleMatrix(sampleId, :)';
    [perturbedModel, perturbedY0] = model4_apply_goal1_inputs(model, inputInfo, sampledValues);
    sweepOptions = model4_default_sin1_sweep(perturbedModel, perturbedY0);

    try
        sweepResults = model4_run_sin1_sweep(perturbedModel, perturbedY0, sweepOptions, struct());
        biphasicIndexValues(sampleId) = sweepResults.biphasicIndex;
        responseCurves(sampleId, :) = sweepResults.finalPs6k1;
        peakSin1(sampleId) = sweepResults.biphasicDiagnostics.peakSin1;
        peakResponse(sampleId) = sweepResults.biphasicDiagnostics.peakResponse;
        classification{sampleId} = sweepResults.biphasicDiagnostics.classification;
        simulationSucceeded(sampleId) = all(sweepResults.simulationSucceeded);
        if simulationSucceeded(sampleId)
            statusMessage{sampleId} = 'ok';
        else
            failureMessages = unique(sweepResults.statusMessage(~sweepResults.simulationSucceeded));
            statusMessage{sampleId} = strjoin(failureMessages, ' | ');
        end
    catch analysisError
        statusMessage{sampleId} = analysisError.message;
        classification{sampleId} = 'analysis_error';
    end

    if mod(sampleId, options.progressEvery) == 0 || sampleId == nSamples
        fprintf('eFAST progress: %d / %d samples complete.\n', sampleId, nSamples);
    end
end

sensitivityTable = model4_compute_efast_indices(sampleSpec, biphasicIndexValues);
mechanismLabel = cell(size(sensitivityTable, 1), 1);
for i = 1:size(sensitivityTable, 1)
    mechanismLabel{i} = model4_goal1_mechanism_label(sensitivityTable.input_name{i});
end
sensitivityTable.mechanism = mechanismLabel;

sampleTable = table( ...
    (1:nSamples)', ...
    sampleSpec.factorIndex, ...
    biphasicIndexValues, ...
    peakSin1, ...
    peakResponse, ...
    simulationSucceeded, ...
    classification, ...
    statusMessage, ...
    'VariableNames', { ...
    'sample_id', ...
    'efast_factor_index', ...
    'biphasic_index', ...
    'peak_sin1', ...
    'peak_pS6K1', ...
    'simulation_succeeded', ...
    'classification', ...
    'status_message'});

writetable(sampleTable, fullfile(outputDir, 'efast_sample_results.csv'));
writetable(sensitivityTable, fullfile(outputDir, 'efast_sensitivity_rankings.csv'));

excludedStateTable = table(inputInfo.fixedZeroStateNames(:), ...
    'VariableNames', {'fixed_zero_initial_condition'});
writetable(excludedStateTable, fullfile(outputDir, 'fixed_zero_initial_conditions.csv'));

validIndexMask = isfinite(biphasicIndexValues) & all(isfinite(responseCurves), 2);
validIndices = find(validIndexMask);

representativeSummary = table();
if ~isempty(validIndices) && options.storeRepresentativeCurves
    [~, order] = sort(biphasicIndexValues(validIndices));
    orderedIndices = validIndices(order);
    representativeIds = unique(round(linspace(1, numel(orderedIndices), min(3, numel(orderedIndices)))));
    chosenSamples = orderedIndices(representativeIds);
    curveLabels = {'low', 'mid', 'high'};
    curveLabels = curveLabels(1:numel(chosenSamples));

    representativeSummary = table( ...
        chosenSamples(:), ...
        curveLabels(:), ...
        biphasicIndexValues(chosenSamples), ...
        peakSin1(chosenSamples), ...
        peakResponse(chosenSamples), ...
        'VariableNames', { ...
        'sample_id', ...
        'curve_label', ...
        'biphasic_index', ...
        'peak_sin1', ...
        'peak_pS6K1'});
    writetable(representativeSummary, fullfile(outputDir, 'representative_curve_summary.csv'));

    figure('Color', 'w', 'Position', [100 100 1000 420]);
    tiledlayout(1, numel(chosenSamples), 'Padding', 'compact', 'TileSpacing', 'compact');
    for i = 1:numel(chosenSamples)
        nexttile;
        semilogx(baselineSweepOptions.sin1InitialValues, responseCurves(chosenSamples(i), :), '-o', ...
            'LineWidth', 1.4, 'MarkerSize', 3);
        xlabel('Initial total SIN1');
        ylabel('Final pS6K1');
        title(sprintf('%s biphasic index = %.3f', curveLabels{i}, biphasicIndexValues(chosenSamples(i))));
        grid on;
    end
    saveas(gcf, fullfile(outputDir, 'representative_curves.png'));
    savefig(gcf, fullfile(outputDir, 'representative_curves.fig'));
    close(gcf);
end

topRows = min(15, size(sensitivityTable, 1));
figure('Color', 'w', 'Position', [100 100 900 520]);
barh(categorical(flipud(sensitivityTable.input_name(1:topRows))), ...
    flipud(sensitivityTable.total_sensitivity_index(1:topRows)));
xlabel('Total sensitivity index');
ylabel('Input');
title(sprintf('Model 4 eFAST Rankings (top %d)', topRows));
grid on;
saveas(gcf, fullfile(outputDir, 'efast_top_rankings.png'));
savefig(gcf, fullfile(outputDir, 'efast_top_rankings.fig'));
close(gcf);

save(fullfile(outputDir, 'efast_results.mat'), ...
    'model', 'inputInfo', 'sampleSpec', 'sampleTable', 'sensitivityTable', ...
    'responseCurves', 'biphasicIndexValues', 'representativeSummary', 'options');

fprintf('Model 4 eFAST analysis complete.\n');
fprintf('Inputs varied: %d\n', numel(inputInfo.names));
fprintf('Sample trajectories: %d\n', nSamples);
fprintf('Results written to: %s\n', outputDir);

results = struct();
results.model = model;
results.inputInfo = inputInfo;
results.sampleSpec = sampleSpec;
results.sampleTable = sampleTable;
results.sensitivityTable = sensitivityTable;
results.representativeSummary = representativeSummary;
results.options = options;
end
