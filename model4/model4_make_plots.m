function model4_make_plots(t, y, observables, model, outputDir)
figure('Color', 'w', 'Position', [100 100 1100 700]);

subplot(2, 3, 1);
plot(t, observables.insulin, 'LineWidth', 1.8);
xlabel('Time');
ylabel('Ins');
title('Insulin Input');
grid on;

subplot(2, 3, 2);
plot(t, observables.phosphoAkt473r, 'LineWidth', 1.8);
hold on;
plot(t, observables.phosphoAkt308r, 'LineWidth', 1.8);
xlabel('Time');
ylabel('Relative level');
title('Akt Phosphorylation');
legend({'pAkt473 total', 'pAkt308 total'}, 'Location', 'best');
grid on;

subplot(2, 3, 3);
plot(t, observables.totalmTORC2r, 'LineWidth', 1.8);
hold on;
plot(t, observables.totalmTORC1r, 'LineWidth', 1.8);
xlabel('Time');
ylabel('Complex abundance');
title('mTOR Complexes');
legend({'mTORC2 total', 'mTORC1 total'}, 'Location', 'best');
grid on;

subplot(2, 3, 4);
plot(t, observables.phosphos6k1r, 'LineWidth', 1.8);
xlabel('Time');
ylabel('Relative level');
title('pS6K1');
grid on;

subplot(2, 3, 5);
plot(t, observables.phosphoTSC2r, 'LineWidth', 1.8);
xlabel('Time');
ylabel('Relative level');
title('pTSC2');
grid on;

subplot(2, 3, 6);
plot(t, y(:, 7), 'LineWidth', 1.8);
hold on;
plot(t, y(:, 8), 'LineWidth', 1.8);
xlabel('Time');
ylabel('Relative amount');
title('mLST8 Pool');
legend({'GBL', 'GBLubi'}, 'Location', 'best');
grid on;

sgtitle(sprintf('Model 4 Baseline Simulation (Set %d)', model.parameterSet.id));

saveas(gcf, fullfile(outputDir, 'baseline_outputs.png'));
savefig(gcf, fullfile(outputDir, 'baseline_outputs.fig'));
close(gcf);
end
