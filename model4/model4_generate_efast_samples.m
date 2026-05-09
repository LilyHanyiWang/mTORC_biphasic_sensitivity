function sampleSpec = model4_generate_efast_samples(inputInfo, options)
if nargin < 2 || isempty(options)
    options = struct();
end
if ~isfield(options, 'sampleCount')
    options.sampleCount = 129;
end
if ~isfield(options, 'interferenceFactor')
    options.interferenceFactor = 4;
end
if ~isfield(options, 'randomSeed')
    options.randomSeed = 1234;
end

D = numel(inputInfo.names);
N = options.sampleCount;
M = options.interferenceFactor;

if mod(N, 2) == 0
    error('eFAST sampleCount must be odd.');
end

omegaBase = floor((N - 1) / (2 * M));
if omegaBase < 1
    error('sampleCount is too small for the requested interferenceFactor.');
end

secondaryMax = max(1, floor(omegaBase / (2 * M)));
s = linspace(0, 2 * pi, N + 1)';
s(end) = [];

rng(options.randomSeed, 'twister');

sampleMatrix = zeros(D * N, D);
factorIndex = zeros(D * N, 1);
phaseShift = zeros(D * N, 1);
sampleAngle = zeros(D * N, 1);
omegaAssignments = zeros(D, D);

lowerLog = log10(inputInfo.lowerBounds(:)');
upperLog = log10(inputInfo.upperBounds(:)');

for factor = 1:D
    omega = ones(1, D);
    omega(factor) = omegaBase;

    if D > 1
        secondaryFrequencies = repmat(1:secondaryMax, 1, ceil((D - 1) / secondaryMax));
        secondaryFrequencies = secondaryFrequencies(1:(D - 1));
        secondaryFrequencies = secondaryFrequencies(randperm(D - 1));
        otherIndices = [1:(factor - 1), (factor + 1):D];
        omega(otherIndices) = secondaryFrequencies;
    end

    omegaAssignments(factor, :) = omega;
    phi = 2 * pi * rand();

    u = zeros(N, D);
    for j = 1:D
        u(:, j) = 0.5 + asin(sin(omega(j) .* s + phi)) / pi;
    end

    X = 10 .^ (lowerLog + u .* (upperLog - lowerLog));
    rowIndex = (factor - 1) * N + (1:N);
    sampleMatrix(rowIndex, :) = X;
    factorIndex(rowIndex) = factor;
    phaseShift(rowIndex) = phi;
    sampleAngle(rowIndex) = s;
end

sampleSpec = struct();
sampleSpec.sampleMatrix = sampleMatrix;
sampleSpec.factorIndex = factorIndex;
sampleSpec.phaseShift = phaseShift;
sampleSpec.sampleAngle = sampleAngle;
sampleSpec.omegaAssignments = omegaAssignments;
sampleSpec.omegaBase = omegaBase;
sampleSpec.secondaryMax = secondaryMax;
sampleSpec.options = options;
sampleSpec.inputInfo = inputInfo;
end
