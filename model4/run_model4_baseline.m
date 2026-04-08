clear;
clc;

scriptDir = fileparts(mfilename('fullpath'));
projectDir = fileparts(scriptDir);
outputDir = fullfile(projectDir, 'results', 'model4_baseline');

addpath(scriptDir);

if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

model = model4_setup(projectDir);

tStart = 0;
tStop = model.constants.Timeinput1 + model.constants.Tinfinput1 + 3000;
tEval = linspace(tStart, tStop, 2001);

[t, y, observables] = model4_simulate(model, model.y0, tEval);
model4_make_plots(t, y, observables, model, outputDir);

stateTable = array2table(y, 'VariableNames', model.stateNames);
stateTable = addvars(stateTable, t, 'Before', 1, 'NewVariableNames', 'time');

observableTable = table( ...
    t, ...
    observables.insulin, ...
    observables.phosphoGBLubir, ...
    observables.phosphoAkt473r, ...
    observables.phosphoAkt308r, ...
    observables.phosphos6k1r, ...
    observables.phosphoTSC2r, ...
    observables.totalmTORC2r, ...
    observables.totalmTORC1r, ...
    'VariableNames', { ...
    'time', 'insulin', 'phosphoGBLubir', 'phosphoAkt473r', ...
    'phosphoAkt308r', 'phosphos6k1r', 'phosphoTSC2r', ...
    'totalmTORC2r', 'totalmTORC1r'});

writetable(stateTable, fullfile(outputDir, 'baseline_states.csv'));
writetable(observableTable, fullfile(outputDir, 'baseline_observables.csv'));

save(fullfile(outputDir, 'baseline_results.mat'), ...
    't', 'y', 'observables', 'model');

fprintf('Model 4 baseline simulation complete.\n');
fprintf('Selected parameter set: %d\n', model.parameterSet.id);
fprintf('Objective function value: %.8g\n', model.parameterSet.objective);
fprintf('Results written to: %s\n', outputDir);
