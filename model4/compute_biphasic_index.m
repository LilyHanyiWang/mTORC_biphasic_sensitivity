function [biphasicIndex, diagnostics] = compute_biphasic_index(sin1Values, responseValues, options)
if nargin < 3 || isempty(options)
    options = struct();
end

if ~isfield(options, 'minDynamicRangeFraction')
    options.minDynamicRangeFraction = 1e-3;
end
if ~isfield(options, 'slopeToleranceFraction')
    options.slopeToleranceFraction = 1e-3;
end
if ~isfield(options, 'minProminenceFraction')
    options.minProminenceFraction = 0.05;
end
if ~isfield(options, 'minEndpointDropFraction')
    options.minEndpointDropFraction = 0.05;
end
if ~isfield(options, 'edgeExclusionFraction')
    options.edgeExclusionFraction = 0.1;
end

sin1Values = sin1Values(:);
responseValues = responseValues(:);

diagnostics = struct();
diagnostics.isValid = false;
diagnostics.classification = 'invalid';
diagnostics.message = '';
diagnostics.peakIndex = NaN;
diagnostics.peakSin1 = NaN;
diagnostics.peakResponse = NaN;
diagnostics.lowEndpointResponse = NaN;
diagnostics.highEndpointResponse = NaN;
diagnostics.leftRise = NaN;
diagnostics.rightDrop = NaN;
diagnostics.dynamicRange = NaN;
diagnostics.localPeakCount = 0;
diagnostics.hasDominantPeak = false;
diagnostics.hasInteriorPeak = false;

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

dynamicRange = max(responseValues) - min(responseValues);
scale = max(max(abs(responseValues)), 1);
minDynamicRange = options.minDynamicRangeFraction * scale;
diagnostics.dynamicRange = dynamicRange;
diagnostics.lowEndpointResponse = responseValues(1);
diagnostics.highEndpointResponse = responseValues(end);

if dynamicRange <= minDynamicRange
    biphasicIndex = 0;
    diagnostics.classification = 'flat';
    diagnostics.message = 'Response curve is too flat to classify as biphasic.';
    return;
end

slopeTolerance = options.slopeToleranceFraction * max(dynamicRange, scale * eps);
slopes = diff(responseValues);
signs = zeros(size(slopes));
signs(slopes > slopeTolerance) = 1;
signs(slopes < -slopeTolerance) = -1;

for i = 2:numel(signs)
    if signs(i) == 0
        signs(i) = signs(i - 1);
    end
end
for i = numel(signs) - 1:-1:1
    if signs(i) == 0
        signs(i) = signs(i + 1);
    end
end

peakCandidates = [];
for i = 2:numel(responseValues) - 1
    if responseValues(i) >= responseValues(i - 1) && responseValues(i) >= responseValues(i + 1)
        leftRise = responseValues(i) - min(responseValues(1:i));
        rightDrop = responseValues(i) - min(responseValues(i:end));
        if leftRise >= options.minProminenceFraction * dynamicRange && ...
                rightDrop >= options.minProminenceFraction * dynamicRange
            peakCandidates(end + 1, 1) = i; %#ok<AGROW>
        end
    end
end

diagnostics.localPeakCount = numel(peakCandidates);

[peakResponse, peakIndex] = max(responseValues);
peakSin1 = sin1Values(peakIndex);
lowResponse = responseValues(1);
highResponse = responseValues(end);
leftRise = peakResponse - lowResponse;
rightDrop = peakResponse - highResponse;

diagnostics.peakIndex = peakIndex;
diagnostics.peakSin1 = peakSin1;
diagnostics.peakResponse = peakResponse;
diagnostics.leftRise = leftRise;
diagnostics.rightDrop = rightDrop;

edgeMargin = max(1, floor(options.edgeExclusionFraction * numel(responseValues)));
hasInteriorPeak = peakIndex > edgeMargin && peakIndex < (numel(responseValues) - edgeMargin + 1);
hasDominantPeak = leftRise >= options.minProminenceFraction * dynamicRange && ...
    rightDrop >= options.minEndpointDropFraction * dynamicRange;

diagnostics.hasInteriorPeak = hasInteriorPeak;
diagnostics.hasDominantPeak = hasDominantPeak;

if ~hasInteriorPeak
    biphasicIndex = 0;
    diagnostics.classification = 'edge_peak';
    diagnostics.message = 'Global peak occurs too close to a sweep boundary.';
    return;
end

if ~hasDominantPeak
    biphasicIndex = 0;
    diagnostics.classification = 'monotonic_or_incomplete';
    diagnostics.message = 'Curve lacks a sufficiently strong rise and fall.';
    return;
end

if isempty(peakCandidates)
    biphasicIndex = 0;
    diagnostics.classification = 'smoothed_peak_missing';
    diagnostics.message = 'No dominant local maximum survived the prominence filter.';
    return;
end

if numel(peakCandidates) > 1
    peakCandidateResponses = responseValues(peakCandidates);
    if max(peakCandidateResponses) - min(peakCandidateResponses) > options.minProminenceFraction * dynamicRange
        biphasicIndex = 0;
        diagnostics.classification = 'multi_peak';
        diagnostics.message = 'Multiple comparably prominent local maxima were detected.';
        return;
    end
end

normalizedRise = leftRise / dynamicRange;
normalizedDrop = rightDrop / dynamicRange;
biphasicIndex = normalizedRise * normalizedDrop;

diagnostics.isValid = true;
diagnostics.classification = 'biphasic';
diagnostics.message = 'Curve passed interior-peak and prominence checks.';
end
