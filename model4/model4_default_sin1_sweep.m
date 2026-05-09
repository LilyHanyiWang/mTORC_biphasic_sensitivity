function sweepOptions = model4_default_sin1_sweep(model, y0)
if nargin < 2 || isempty(y0)
    y0 = model.y0;
end

sin1Index = find(strcmp(model.stateNames, 'Sin1'), 1);
baselineTotalSin1 = y0(sin1Index);
tStop = model.constants.Timeinput1 + model.constants.Tinfinput1 + 3000;

sweepOptions = struct();
sweepOptions.sin1Index = sin1Index;
sweepOptions.sin1FoldChange = logspace(-2, 2, 61)';
sweepOptions.sin1InitialValues = baselineTotalSin1 .* sweepOptions.sin1FoldChange;
sweepOptions.tEval = linspace(0, tStop, 2001);
sweepOptions.readoutName = 'final_pS6K1';
sweepOptions.responseLabel = 'Final pS6K1';
sweepOptions.storeTrajectories = false;
end
