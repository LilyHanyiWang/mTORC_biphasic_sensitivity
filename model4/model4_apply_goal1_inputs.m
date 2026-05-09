function [perturbedModel, perturbedY0] = model4_apply_goal1_inputs(model, inputInfo, sampledValues)
perturbedModel = model;
perturbedY0 = model.y0;

for i = 1:numel(inputInfo.names)
    label = inputInfo.labels{i};
    if strcmp(inputInfo.kinds{i}, 'parameter')
        perturbedModel.params.(label) = sampledValues(i);
    else
        stateIndex = find(strcmp(perturbedModel.stateNames, label), 1);
        perturbedY0(stateIndex) = sampledValues(i);
    end
end
end
