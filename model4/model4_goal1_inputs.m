function inputInfo = model4_goal1_inputs(model)
parameterNames = model.parameterNames(:);
parameterValues = model.parameterValues(:);
stateNames = model.stateNames(:);
y0 = model.y0(:);

positiveStateMask = y0 > 0;
variableStateNames = stateNames(positiveStateMask);
variableStateValues = y0(positiveStateMask);
fixedZeroStateNames = stateNames(~positiveStateMask);

inputInfo = struct();
inputInfo.names = [strcat('param:', parameterNames); strcat('state:', variableStateNames(:))];
inputInfo.kinds = [repmat({'parameter'}, numel(parameterNames), 1); repmat({'initial_condition'}, numel(variableStateNames), 1)];
inputInfo.labels = [parameterNames; variableStateNames(:)];
inputInfo.baselineValues = [parameterValues; variableStateValues];
inputInfo.lowerBounds = 0.1 .* inputInfo.baselineValues;
inputInfo.upperBounds = 10 .* inputInfo.baselineValues;
inputInfo.parameterNames = parameterNames;
inputInfo.stateNames = stateNames(:);
inputInfo.variableStateNames = variableStateNames(:);
inputInfo.fixedZeroStateNames = fixedZeroStateNames(:);
inputInfo.fixedZeroStateIndices = find(~positiveStateMask);
end
