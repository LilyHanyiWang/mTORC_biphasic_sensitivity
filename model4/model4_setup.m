function model = model4_setup(projectDir)
parameterFile = fullfile(projectDir, 'paper_model_parameter', 'ParameterSets.xlsx');
sheetName = 'Model 4';

raw = readcell(parameterFile, 'Sheet', sheetName);

headers = raw(1, :);
data = raw(2:end, :);

parameterNames = string(headers(1, 3:end));
parameterNames = erase(parameterNames, "'");

objectiveValues = cellfun(@double, data(:, 2));
setIds = cellfun(@double, data(:, 1));

[bestObjective, bestIndex] = min(objectiveValues);
bestRow = data(bestIndex, :);
parameterValues = cellfun(@double, bestRow(1, 3:end));

params = cell2struct(num2cell(parameterValues), cellstr(parameterNames), 2);

constants = struct( ...
    'Timeinput1', 5000, ...
    'Tinfinput1', 2000);

stateNames = { ...
    'InsR', 'pInsR', 'IRS', 'pIRS', 'otud', 'aotud', ...
    'GBL', 'GBLubi', 'Raptor', 'Sin1', 'mTORC2', 'pmTORC2', ...
    'mTORC1', 'pmTORC1', 'Akt', 'pAkt473', 'pAkt308', 'pAkt308473', ...
    's6k1', 'ps6k1', 'TSC2', 'pTSC2'};

y0 = [ ...
    100; 0; 100; 0; 100; 0; ...
    0; 0; 0; 100; 0; 0; ...
    100; 0; 100; 0; 0; 0; ...
    100; 0; 100; 0];

model = struct();
model.params = params;
model.constants = constants;
model.stateNames = stateNames;
model.y0 = y0;
model.parameterSet = struct( ...
    'id', setIds(bestIndex), ...
    'objective', bestObjective);
end
