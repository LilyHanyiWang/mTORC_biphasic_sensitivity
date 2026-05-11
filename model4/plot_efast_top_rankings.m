S = load('/Users/hanyiwang/Desktop/BME 530/mTORC_biphasic_sensitivity/results/model4_efast/efast_results.mat');
T = S.sensitivityTable;

% 排序
T = sortrows(T, 'total_sensitivity_index', 'descend');

topN = min(15, height(T));
T = T(1:topN,:);

labels = erase(T.input_name, "param:");
labels = erase(labels, "state:");

ranks = (1:topN)';
labels = strcat(string(ranks), ". ", labels);

values = T.total_sensitivity_index;

% ===== ⭐ 关键：设置 figure 尺寸（letter 横向更宽） =====
figure('Color','w', 'Units','inches', 'Position',[1 1 10 6]);  
% 宽10 inch，高6 inch（非常适合 letter 横向）

barh(values, ...
    'FaceColor',[0.18 0.45 0.72], ...
    'EdgeColor','none');

yticks(1:topN)
yticklabels(labels)

set(gca,'YDir','reverse')

% ===== ⭐ 字体优化 =====
ax = gca;
ax.FontSize = 12;          % y轴 labels
ax.LineWidth = 1.2;

xlabel('Total-order sensitivity index (ST)', 'FontSize',14);
title('Top eFAST-ranked Model 4 inputs', 'FontSize',16);

% ===== ⭐ 数值标注（更论文友好） =====
for i = 1:topN
    text(values(i), i, sprintf(' %.2f', values(i)), ...
        'VerticalAlignment','middle', ...
        'FontSize',11);
end

% ===== ⭐ 保存（保持比例） =====
exportgraphics(gcf, ...
    '/Users/hanyiwang/Desktop/BME 530/mTORC_biphasic_sensitivity/results/model4_efast/efast_top_rankings_white.png', ...
    'Resolution', 300);