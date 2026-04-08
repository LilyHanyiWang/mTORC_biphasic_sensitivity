function observables = model4_observables(t, y, p, c)
observables = struct();
observables.insulin = zeros(size(t));
stimulusMask = t >= c.Timeinput1 & t < (c.Timeinput1 + c.Tinfinput1);
observables.insulin(stimulusMask) = p.Ins0;

observables.phosphoGBLubir = y(:, 8) + y(:, 13) + y(:, 14);
observables.phosphoAkt473r = y(:, 16) + y(:, 18);
observables.phosphoAkt308r = y(:, 17) + y(:, 18);
observables.phosphos6k1r = y(:, 20);
observables.phosphoTSC2r = y(:, 22);
observables.totalmTORC2r = y(:, 11) + y(:, 12);
observables.totalmTORC1r = y(:, 13) + y(:, 14);
end
