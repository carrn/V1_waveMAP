% Create the contingency table: rows are layers, columns are neuron types (NS, TP, BS)
contingency_table = [
    20, 3, 83;   % Layer 2/3: NS, TP, BS
    95, 12, 55;  % Layer 4AB: NS, TP, BS
    59, 19, 137; % Layer 4C: NS, TP, BS
    25, 15, 68;  % Layer 5/6: NS, TP, BS
    0, 10, 5     % WM: NS, TP, BS
];

% Layer and neuron type labels for reference
layer_labels = {'2/3', '4AB', '4C', '5/6', 'WM'};
neuron_labels = {'NS', 'TP', 'BS'};

% Calculate percentages for visualization
row_sums = sum(contingency_table, 2);
percentages = 100 * contingency_table ./ row_sums;

% Set up the figure
figure('Position', [100, 100, 1200, 900]);

% 1. Stacked bar chart showing raw counts
subplot(2, 2, 1);
bar(contingency_table, 'stacked');
xlabel('Cortical Layer');
ylabel('Count');
title('Neuron Type Distribution by Layer (Counts)');
set(gca, 'XTickLabel', layer_labels);
legend(neuron_labels, 'Location', 'northeastoutside');
grid on;

% 2. Stacked bar chart showing percentages
subplot(2, 2, 2);
bar(percentages, 'stacked');
xlabel('Cortical Layer');
ylabel('Percentage (%)');
title('Neuron Type Distribution by Layer (%)');
set(gca, 'XTickLabel', layer_labels);
legend(neuron_labels, 'Location', 'northeastoutside');
grid on;

% 3. Side-by-side bar chart for comparison
subplot(2, 2, 3);
bar(contingency_table, 'grouped');
xlabel('Cortical Layer');
ylabel('Count');
title('Neuron Type Comparison by Layer');
set(gca, 'XTickLabel', layer_labels);
legend(neuron_labels, 'Location', 'northeastoutside');
grid on;

% 4. Standardized residuals heatmap
subplot(2, 2, 4);

% Perform chi-square test
[chi2, p, dof, expected] = chi2cont(contingency_table)

% Calculate expected frequencies and residuals
residuals = (contingency_table - expected) ./ sqrt(expected);

figure
% Create heatmap of standardized residuals
imagesc(residuals);
colormap(redblue(21)); % Custom colormap from blue to red
colorbar;
caxis([-5 5]); % Set color limits for better visualization
title('Standardized Residuals');
xlabel('Neuron Type');
ylabel('Cortical Layer');
set(gca, 'XTick', 1:length(neuron_labels), 'XTickLabel', neuron_labels);
set(gca, 'YTick', 1:length(layer_labels), 'YTickLabel', layer_labels);


% Add annotation for residual values
for i = 1:size(residuals, 1)
    for j = 1:size(residuals, 2)
        if abs(residuals(i, j)) > 2
            fontColor = 'k';
            textValue = sprintf('%.1f*', residuals(i, j));
        else
            fontColor = 'k';
            textValue = sprintf('%.1f', residuals(i, j));
        end
        text(j, i, textValue, 'HorizontalAlignment', 'center', 'Color', fontColor, 'FontWeight', 'bold');
    end
end

% Add overall title with chi-square results
% sgtitle({sprintf('Chi-Square Analysis of Neuron Subtype Distribution Across Cortical Layers'), ...
%     sprintf('\\chi^2 = %.2f, p = %.2e, df = %d', chi2, p, dof)}, ...
%     'FontSize', 14, 'FontWeight', 'bold');


% Custom red-blue colormap function
function cmap = redblue(m)
    if nargin < 1
        m = 64;
    end
    
    % Define the colors
    bottom = [0, 0, 0.5];
    botmiddle = [0, 0.5, 1];
    middle = [1, 1, 1];
    topmiddle = [1, 0.5, 0];
    top = [0.5, 0, 0];
    
    % Create segments of the colormap
    n = floor(m/4);
    r1 = linspace(bottom(1), botmiddle(1), n)';
    g1 = linspace(bottom(2), botmiddle(2), n)';
    b1 = linspace(bottom(3), botmiddle(3), n)';
    
    r2 = linspace(botmiddle(1), middle(1), n)';
    g2 = linspace(botmiddle(2), middle(2), n)';
    b2 = linspace(botmiddle(3), middle(3), n)';
    
    r3 = linspace(middle(1), topmiddle(1), n)';
    g3 = linspace(middle(2), topmiddle(2), n)';
    b3 = linspace(middle(3), topmiddle(3), n)';
    
    r4 = linspace(topmiddle(1), top(1), m-3*n)';
    g4 = linspace(topmiddle(2), top(2), m-3*n)';
    b4 = linspace(topmiddle(3), top(3), m-3*n)';
    
    % Combine the segments
    cmap = [r1 g1 b1; r2 g2 b2; r3 g3 b3; r4 g4 b4];
end

% Helper function for chi-square test
function [chi2, p, dof, expected] = chi2cont(observed)
    % Calculate row and column sums
    row_sums = sum(observed, 2);
    col_sums = sum(observed, 1);
    n = sum(observed(:));
    
    % Calculate expected frequencies
    %expected = row_sums * col_sums / n;
    expected = [ col_sums./size(observed,1)].*ones(size(observed));
    
    % Calculate chi-square statistic
    chi2 = sum(((observed - expected).^2) ./ expected);
    
    % Calculate degrees of freedom
    dof = (size(observed, 1) - 1);% * (size(observed, 2) - 1);
    
    % Calculate p-value
    p = 1 - chi2cdf(chi2, dof);
end