function sensitivityTable = model4_compute_efast_indices(sampleSpec, outputValues)
D = numel(sampleSpec.inputInfo.names);
N = sampleSpec.options.sampleCount;
M = sampleSpec.options.interferenceFactor;
omegaBase = sampleSpec.omegaBase;

inputName = cell(D, 1);
factorLabel = cell(D, 1);
inputKind = cell(D, 1);
baselineValue = nan(D, 1);
firstOrderIndex = nan(D, 1);
totalSensitivityIndex = nan(D, 1);
trajectoryComplete = false(D, 1);
validSampleCount = zeros(D, 1);
varianceEstimate = nan(D, 1);

for factor = 1:D
    rowIndex = (factor - 1) * N + (1:N);
    y = outputValues(rowIndex);
    validMask = isfinite(y);

    inputName{factor} = sampleSpec.inputInfo.names{factor};
    factorLabel{factor} = sampleSpec.inputInfo.labels{factor};
    inputKind{factor} = sampleSpec.inputInfo.kinds{factor};
    baselineValue(factor) = sampleSpec.inputInfo.baselineValues(factor);
    validSampleCount(factor) = nnz(validMask);

    if ~all(validMask)
        continue;
    end

    trajectoryComplete(factor) = true;
    y = y(:) - mean(y);

    spectrum = fft(y) / N;
    powerSpectrum = abs(spectrum(2:floor(N / 2) + 1)) .^ 2;
    totalVariance = 2 * sum(powerSpectrum);
    varianceEstimate(factor) = totalVariance;

    if totalVariance <= eps
        firstOrderIndex(factor) = 0;
        totalSensitivityIndex(factor) = 0;
        continue;
    end

    harmonics = (1:M) * omegaBase;
    harmonics = harmonics(harmonics <= floor(N / 2));
    complementHarmonics = 1:max(1, floor(omegaBase / 2));
    complementHarmonics = complementHarmonics(complementHarmonics <= floor(N / 2));

    firstOrderVariance = 2 * sum(abs(spectrum(harmonics + 1)) .^ 2);
    complementVariance = 2 * sum(abs(spectrum(complementHarmonics + 1)) .^ 2);

    firstOrderIndex(factor) = firstOrderVariance / totalVariance;
    totalSensitivityIndex(factor) = max(0, min(1, 1 - complementVariance / totalVariance));
end

sensitivityTable = table( ...
    inputName, ...
    factorLabel, ...
    inputKind, ...
    baselineValue, ...
    firstOrderIndex, ...
    totalSensitivityIndex, ...
    trajectoryComplete, ...
    validSampleCount, ...
    varianceEstimate, ...
    'VariableNames', { ...
    'input_name', ...
    'input_label', ...
    'input_kind', ...
    'baseline_value', ...
    'first_order_index', ...
    'total_sensitivity_index', ...
    'trajectory_complete', ...
    'valid_sample_count', ...
    'variance_estimate'});

sensitivityTable = sortrows(sensitivityTable, 'total_sensitivity_index', 'descend');
end
