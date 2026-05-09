function sweepResults = model4_run_sin1_sweep(model, y0, sweepOptions, indexOptions)
if nargin < 2 || isempty(y0)
    y0 = model.y0;
end
if nargin < 3 || isempty(sweepOptions)
    sweepOptions = model4_default_sin1_sweep(model, y0);
end
if nargin < 4
    indexOptions = struct();
end

sin1Index = sweepOptions.sin1Index;
sin1InitialValues = sweepOptions.sin1InitialValues(:);
nPoints = numel(sin1InitialValues);

finalPs6k1 = nan(nPoints, 1);
peakPs6k1 = nan(nPoints, 1);
finalPmTORC1 = nan(nPoints, 1);
finalTotalmTORC1 = nan(nPoints, 1);
finalTotalmTORC2 = nan(nPoints, 1);
finalFreeSin1 = nan(nPoints, 1);
simulationSucceeded = false(nPoints, 1);
statusMessage = repmat({''}, nPoints, 1);

storeTrajectories = isfield(sweepOptions, 'storeTrajectories') && sweepOptions.storeTrajectories;
if storeTrajectories
    trajectoryTimes = repmat({[]}, nPoints, 1);
    trajectoryReadouts = repmat({[]}, nPoints, 1);
else
    trajectoryTimes = {};
    trajectoryReadouts = {};
end

pmTORC1Index = find(strcmp(model.stateNames, 'pmTORC1'), 1);

for i = 1:nPoints
    trialY0 = y0;
    trialY0(sin1Index) = sin1InitialValues(i);

    try
        [t, y, observables] = model4_simulate(model, trialY0, sweepOptions.tEval);
        if any(~isfinite(y(:))) || any(~isfinite(observables.phosphos6k1r(:)))
            error('Non-finite values detected in the simulated trajectory.');
        end

        finalPs6k1(i) = observables.phosphos6k1r(end);
        peakPs6k1(i) = max(observables.phosphos6k1r);
        finalPmTORC1(i) = y(end, pmTORC1Index);
        finalTotalmTORC1(i) = observables.totalmTORC1r(end);
        finalTotalmTORC2(i) = observables.totalmTORC2r(end);
        finalFreeSin1(i) = y(end, sin1Index);
        simulationSucceeded(i) = true;
        statusMessage{i} = 'ok';

        if storeTrajectories
            trajectoryTimes{i} = t;
            trajectoryReadouts{i} = observables.phosphos6k1r;
        end
    catch simulationError
        statusMessage{i} = simulationError.message;
    end
end

[biphasicIndex, biphasicDiagnostics] = compute_biphasic_index( ...
    sin1InitialValues, finalPs6k1, indexOptions);

sweepTable = table( ...
    sweepOptions.sin1FoldChange(:), ...
    sin1InitialValues, ...
    finalFreeSin1, ...
    finalTotalmTORC2, ...
    finalTotalmTORC1, ...
    finalPmTORC1, ...
    finalPs6k1, ...
    peakPs6k1, ...
    simulationSucceeded, ...
    statusMessage, ...
    'VariableNames', { ...
    'sin1_fold_change', ...
    'sin1_initial_total', ...
    'sin1_final_free', ...
    'mTORC2_total_final', ...
    'mTORC1_total_final', ...
    'pmTORC1_final', ...
    'pS6K1_final', ...
    'pS6K1_peak', ...
    'simulation_succeeded', ...
    'status_message'});

sweepResults = struct();
sweepResults.sweepOptions = sweepOptions;
sweepResults.sin1InitialValues = sin1InitialValues;
sweepResults.finalPs6k1 = finalPs6k1;
sweepResults.peakPs6k1 = peakPs6k1;
sweepResults.finalPmTORC1 = finalPmTORC1;
sweepResults.finalTotalmTORC1 = finalTotalmTORC1;
sweepResults.finalTotalmTORC2 = finalTotalmTORC2;
sweepResults.finalFreeSin1 = finalFreeSin1;
sweepResults.simulationSucceeded = simulationSucceeded;
sweepResults.statusMessage = statusMessage;
sweepResults.biphasicIndex = biphasicIndex;
sweepResults.biphasicDiagnostics = biphasicDiagnostics;
sweepResults.sweepTable = sweepTable;
sweepResults.trajectoryTimes = trajectoryTimes;
sweepResults.trajectoryReadouts = trajectoryReadouts;
end
