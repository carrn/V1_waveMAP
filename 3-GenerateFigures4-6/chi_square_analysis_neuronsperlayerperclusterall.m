% Create the full contingency table with all 9 categories
% Format: rows are layers, columns are neuron subtypes (NS-1, NS-2, NS-3, NS-4, TP-1, BS-1, BS-2, BS-3, BS-4)
contingency_table = [
    6, 4, 5, 5, 3, 29, 14, 28, 12;  % Layer 2/3
    19, 28, 25, 23, 12, 24, 10, 13, 8;  % Layer 4AB
    13, 29, 10, 7, 19, 52, 36, 40, 9;  % Layer 4C
    1, 3, 12, 9, 15, 13, 5, 15, 35;  % Layer 5/6
    0, 0, 0, 0, 10, 0, 0, 0, 5;  % WM
];

contingency_table = [
    6, 4, 5, 5, 3, 29, 14, 28, 12;  % Layer 2/3
    19, 28, 25, 23, 12, 24, 10, 13, 8;  % Layer 4AB
    13, 29, 10, 7, 19, 52, 36, 40, 9;  % Layer 4C
    1, 3, 12, 9, 15, 13, 5, 15, 35;  % Layer 5/6
    0, 0, 0, 0, 10, 0, 0, 0, 5;  % WM
];


% Layer and neuron type labels
layer_labels = {'2/3', '4AB', '4C', '5/6', 'WM'};
neuron_labels = {'NS-1', 'NS-2', 'NS-3', 'NS-4', 'TP-1', 'BS-1', 'BS-2', 'BS-3', 'BS-4'};
group_colors = [repmat([0, 0.4470, 0.7410], 4, 1); ... % Blue for NS
                [0.4660, 0.6740, 0.1880]; ... % Green for TP
                repmat([0.8500, 0.3250, 0.0980], 4, 1)]; % Red for BS

% Perform chi-square test
[chi2, p, dof, expected] = chi2cont(contingency_table)

% Calculate standardized residuals
residuals = (contingency_table - expected) ./ sqrt(expected);

% Create figure with multiple visualizations
figure('Position', [100, 100, 1400, 1000]);

% 1. Heatmap of raw counts
subplot(2, 2, 1);
imagesc(contingency_table);
colorbar;
title('Neuron Distribution: Raw Counts');
xlabel('Neuron Subtype');
ylabel('Cortical Layer');
set(gca, 'XTick', 1:length(neuron_labels), 'XTickLabel', neuron_labels);
set(gca, 'YTick', 1:length(layer_labels), 'YTickLabel', layer_labels);
colormap(gca, parula);
% Add annotation for total counts
for i = 1:size(contingency_table, 1)
    for j = 1:size(contingency_table, 2)
        text(j, i, num2str(contingency_table(i, j)), ...
            'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'Color', 'w');
    end
end

subplot(2, 2, 2);

% 3. Stacked bar chart of percentages within each layer
subplot(2, 2, 3);
% Calculate percentages
row_sums = sum(contingency_table, 2);
percentages = 100 * contingency_table ./ row_sums;
h = bar(percentages, 'stacked');
% Set colors for each neuron subtype
for i = 1:length(h)
    set(h(i), 'FaceColor', group_colors(i,:));
end
xlabel('Cortical Layer');
ylabel('Percentage within Layer (%)');
title('Proportional Distribution of Neuron Subtypes');
set(gca, 'XTickLabel', layer_labels);
legend(neuron_labels, 'Location', 'eastoutside');
grid on;

% 4. Mosaic plot (area proportional to counts)
subplot(2, 2, 4);
% Create mosaic plot using basic MATLAB functions
mosaicplot(contingency_table, 'Tile', neuron_labels, 'TileLabels', layer_labels, ...
    'TileLabelsLocation', 'west', 'Title', 'Mosaic Plot of Neuron Distribution');

% Add overall title with chi-square results
sgtitle({sprintf('Chi-Square Analysis of Neuron Subtype Distribution Across Cortical Layers'), ...
    sprintf('\\chi^2 = %.2f, p = %.2e, df = %d', chi2, p, dof)}, ...
    'FontSize', 14, 'FontWeight', 'bold');

% 2. Standardized residuals heatmap
figure
imagesc(residuals);
colormap(gca, redblue(21));
colorbar;
caxis([-5 5]); % Set color limits
title('Standardized Residuals');
xlabel('Neuron Subtype');
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

% Helper function for chi-square test
function [chi2, p, dof, expected] = chi2cont(observed)
    % Calculate row and column sums
    row_sums = sum(observed, 2);
    col_sums = sum(observed, 1);
    n = sum(observed(:));
    
    % Calculate expected frequencies
    %expected = row_sums * col_sums / n;
    expected = [ col_sums./5].*[1;1;1;1;1];
    % Calculate chi-square statistic
    chi2 = sum(((observed - expected).^2) ./ expected, 'all');
    
    % Calculate degrees of freedom
    dof = (size(observed, 1) - 1);% * (size(observed, 2) - 1);
    
    % Calculate p-value
    p = 1 - chi2cdf(chi2, dof);
end

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

% Simplified mosaic plot function (since MATLAB doesn't have a built-in one)
function mosaicplot(data, varargin)
    p = inputParser;
    addParameter(p, 'Tile', {}, @(x) iscell(x) || isstring(x));
    addParameter(p, 'TileLabels', {}, @(x) iscell(x) || isstring(x));
    addParameter(p, 'TileLabelsLocation', 'south', @ischar);
    addParameter(p, 'Title', '', @ischar);
    parse(p, varargin{:});
    
    xLabels = p.Results.Tile;
    yLabels = p.Results.TileLabels;
    titleText = p.Results.Title;
    
    % Normalize data for area calculations
    normalizedData = data / sum(data(:));
    
    % Calculate row and column positions
    rows = size(data, 1);
    cols = size(data, 2);
    
    % Create the basic plot
    hold on;
    colorOrder = [0, 0.4470, 0.7410; 0.8500, 0.3250, 0.0980; 0.9290, 0.6940, 0.1250; 
                 0.4940, 0.1840, 0.5560; 0.4660, 0.6740, 0.1880; 0.3010, 0.7450, 0.9330;
                 0.6350, 0.0780, 0.1840];
    
    % Repeat colors if needed
    colorOrder = repmat(colorOrder, ceil(cols/size(colorOrder,1)), 1);
    
    % Calculate cumulative widths for each row
    yPos = linspace(0, 1, rows+1);
    xCumulative = zeros(rows, 1);
    
    for i = 1:rows
        rowSum = sum(data(i,:));
        rowNorm = data(i,:) / rowSum;
        
        for j = 1:cols
            if rowSum > 0
                % Calculate box dimensions
                x = xCumulative(i);
                y = 1 - yPos(i+1);
                width = rowNorm(j);
                height = yPos(i+1) - yPos(i);
                
                % Draw rectangle
                rectangle('Position', [x, y, width, height], ...
                          'FaceColor', colorOrder(j,:), ...
                          'EdgeColor', 'k');
                
                % Add text label if box is large enough
                if width*height > 0.02
                    text(x + width/2, y + height/2, sprintf('%d', data(i,j)), ...
                         'HorizontalAlignment', 'center', ...
                         'VerticalAlignment', 'middle', ...
                         'FontWeight', 'bold');
                end
                
                xCumulative(i) = xCumulative(i) + width;
            end
        end
    end
    
    % Add labels
    if ~isempty(yLabels)
        for i = 1:rows
            text(-0.05, 1 - (yPos(i) + yPos(i+1))/2, yLabels{i}, ...
                 'HorizontalAlignment', 'right', ...
                 'VerticalAlignment', 'middle');
        end
    end
    
    % Add column labels
    if ~isempty(xLabels)
        ax = gca;
        ax.XTick = [];
        ax.YTick = [];
        
        % Calculate position for column labels
        for j = 1:cols
            % Find the center position of this column
            colWidths = data(:,j) ./ sum(data, 2);
            colStarts = zeros(rows, 1);
            for i = 1:rows
                rowData = data(i,:);
                if sum(rowData) > 0
                    rowNorm = rowData / sum(rowData);
                    colPos = 0;
                    for k = 1:j-1
                        colPos = colPos + rowNorm(k);
                    end
                    colStarts(i) = colPos;
                end
            end
            
            % Use the median position as the label position
            validRows = find(sum(data, 2) > 0);
            medianStart = median(colStarts(validRows));
            medianWidth = median(colWidths(validRows));
            
            % Add the label
            text(medianStart + medianWidth/2, 1.05, xLabels{j}, ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'bottom', ...
                'Rotation', 45);
        end
    end
    
    % Set plot properties
    axis tight;
    axis equal;
    xlim([-0.1, 1.1]);
    ylim([0, 1.1]);
    set(gca, 'XTick', [], 'YTick', []);
    box on;
    
    % Add title
    title(titleText);
end