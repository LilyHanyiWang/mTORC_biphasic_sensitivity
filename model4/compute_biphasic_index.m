function [biphasicIndex, diagnostics] = compute_biphasic_index(sin1Values, responseValues, options)
if nargin < 3 || isempty(options)
    options = struct();
end

sin1Values = sin1Values(:);
responseValues = responseValues(:);

diagnostics = struct();
diagnostics.isValid = false;
diagnostics.message = '';
diagnostics.peakIndex = NaN;
diagnostics.peakSin1 = NaN;
diagnostics.peakResponse = NaN;
diagnostics.peakValue = NaN;
diagnostics.lowEndpointResponse = NaN;
diagnostics.highEndpointResponse = NaN;
diagnostics.lowResponse = NaN;
diagnostics.highResponse = NaN;
diagnostics.dynamicRange = NaN;
diagnostics.normalizedLowResponse = NaN;
diagnostics.normalizedHighResponse = NaN;
diagnostics.classification = 'invalid';
diagnostics.leftRise = NaN;
diagnostics.rightDrop = NaN;
diagnostics.localPeakCount = NaN;
diagnostics.hasDominantPeak = NaN;
diagnostics.hasInteriorPeak = NaN;

if numel(sin1Values) ~= numel(responseValues) || numel(responseValues) < 3
    biphasicIndex = NaN;
    diagnostics.message = 'Inputs must be finite vectors of equal length >= 3.';
    return;
end

validMask = isfinite(sin1Values) & isfinite(responseValues);
if nnz(validMask) < 3
    biphasicIndex = NaN;
    diagnostics.message = 'Fewer than three finite points were available.';
    return;
end

sin1Values = sin1Values(validMask);
responseValues = responseValues(validMask);
[sin1Values, sortIndex] = sort(sin1Values);
responseValues = responseValues(sortIndex);

[peakResponse, peakIndex] = max(responseValues);
lowResponse = responseValues(1);
highResponse = responseValues(end);
dynamicRange = peakResponse - min(responseValues);

diagnostics.dynamicRange = dynamicRange;
diagnostics.lowEndpointResponse = responseValues(1);
diagnostics.highEndpointResponse = responseValues(end);
peakSin1 = sin1Values(peakIndex);
leftRise = peakResponse - lowResponse;
rightDrop = peakResponse - highResponse;

diagnostics.peakIndex = peakIndex;
diagnostics.peakSin1 = peakSin1;
diagnostics.peakResponse = peakResponse;
diagnostics.peakValue = peakResponse;
diagnostics.leftRise = leftRise;
diagnostics.rightDrop = rightDrop;
diagnostics.lowResponse = lowResponse;
diagnostics.highResponse = highResponse;
diagnostics.localPeakCount = sum(responseValues(2:end-1) >= responseValues(1:end-2) & ...
    responseValues(2:end-1) >= responseValues(3:end));
diagnostics.hasInteriorPeak = peakIndex > 1 && peakIndex < numel(responseValues);
diagnostics.hasDominantPeak = peakResponse > 0 && diagnostics.hasInteriorPeak;

if ~isfinite(peakResponse) || peakResponse <= 0
    biphasicIndex = NaN;
    diagnostics.classification = 'invalid_peak';
    diagnostics.message = 'Peak response is non-positive, so paper BI normalization is undefined.';
    return;
end

normalizedLow = lowResponse / peakResponse;
normalizedHigh = highResponse / peakResponse;
denominator = normalizedHigh + normalizedLow;

diagnostics.normalizedLowResponse = normalizedLow;
diagnostics.normalizedHighResponse = normalizedHigh;

if abs(denominator) <= eps
    biphasicIndex = NaN;
    diagnostics.classification = 'invalid_denominator';
    diagnostics.message = 'Normalized endpoint sum is too close to zero.';
    return;
end

biphasicIndex = (normalizedHigh - normalizedLow) / denominator;
diagnostics.isValid = true;
diagnostics.classification = 'paper_bi';
diagnostics.message = 'Paper-style biphasic index computed from normalized low/high SIN1 endpoints.';
end
