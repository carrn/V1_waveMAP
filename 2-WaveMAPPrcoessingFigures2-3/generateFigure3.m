%% Figure 3 Revision Stats
% This generates one array which has scaled depth split into 9 groups (by cell cluster) for ANOVA single factor analysis
clusterFn = clusterFnData(:,15);
scaledDepth = clusterFnData(:,16);
testClusterDepths = nan([118,9]);
for clusterID = 1:9
    testClusterDepths(1:length(scaledDepth(clusterFn==clusterID)),clusterID) = scaledDepth(clusterFn==clusterID);
end

%% Shuffle test for Cluster and Depth
unCl = unique(clusterFnData(:,15));
unLa = [1:4];

shuffledClusters = clusterFn(randperm(length(clusterFn)));
%shuffledDI = AllDI(randperm(length(AllDI)));
allC = [];
%allD = [];
% pvalue 2/500
for n=1:1000
    shuffledClusters = clusterFn(randperm(length(clusterFn)));
    %shuffledDI = AllDI(randperm(length(AllDI)));
    for clusterID=[1 6 8 2 7 3 9 5 4]
        iX2 = find(shuffledClusters == unCl(clusterID));
        depthperCluster(clusterID) = nanmedian(scaledDepth(iX2));
        %DIperCluster(clusterID) = nanmedian(shuffledDI(iX2));
    end
    allC = [allC ; depthperCluster];
    %allD = [allD ; DIperCluster];
end

boundsC = median(prctile(allC, [2.5,97.5])');
%boundsD = median(prctile(allD, [2.5,97.5])');

%%  % of L4
%
% CC, NC - June 16th 2023 
%
% Calculating mean depths
whichClusters = clusterFn == 1 | clusterFn == 2 | clusterFn == 6 | clusterFn == 8;
nsDepths = clusterFnData(find(whichClusters), 16);
nsDepthsBins = clusterFnData(find(whichClusters), 21);

nL4b = sum(nsDepthsBins == 3);
nL4c = sum(nsDepthsBins == 2);
p = (nL4b+nL4c)/length(nsDepthsBins)
errorr = sqrt((p*(1-p))/length(nsDepthsBins))


mD = nanmean(nsDepths);
sE = nanstd(nsDepths)./sqrt(length(nsDepths));
tV = tinv(0.975,length(nsDepths))
fprintf('\n %3.2f - %3.2f - %3.2f', mD-tV*sE, mD, mD + tV*sE);
%%  % of L4
%
% CC, NC - June 16th 2023 
%
% Calculating mean depths
whichClusters = clusterFn == 2 | clusterFn == 8 | clusterFn == 6 | clusterFn == 1;
%whichClusters = clusterFn == 7;
%whichClusters = clusterFn == 4 | clusterFn == 3 | clusterFn == 5 | clusterFn == 9;
nsDepths = clusterFnData(find(whichClusters), 16);
nsDepthsBins = clusterFnData(find(whichClusters), 21);

nL23which = sum(nsDepthsBins == 4);
nL4bwhich = sum(nsDepthsBins == 3);
nL4cwhich = sum(nsDepthsBins == 2);
nL56which = sum(nsDepthsBins == 1);
nLWMwhich = sum(nsDepthsBins == 5);

clear pc;
pc.L23 = 0;
fieldNames = {'L56','L4C','L4B','L23','WM', 'L4'};
for layerId = 1:length(fieldNames)
    if layerId <= 5
        nTemp = sum(nsDepthsBins == layerId);
    else
        nTemp = sum(nsDepthsBins == 2 | nsDepthsBins == 3);
    end
    pc.(fieldNames{layerId}) = 100*nTemp/length(nsDepthsBins);
    p = pc.(fieldNames{layerId});
    s = sprintf('%s_se',fieldNames{layerId});
    pc.(s) = sqrt(p*(100-p))/sqrt(length(nsDepthsBins));
    pc.(sprintf('%s_n',fieldNames{layerId})) = length(nsDepthsBins);
end

p = (nL23which)/length(nsDepthsBins);
errorr = sqrt((p*(1-p))/length(nsDepthsBins));


mD = nanmean(nsDepths);
sE = nanstd(nsDepths)./sqrt(length(nsDepths));
tV = tinv(0.975,length(nsDepths));
fprintf('\n %3.2f - %3.2f - %3.2f', mD-tV*sE, mD, mD + tV*sE);

%% Position-Preserving Cell Type Shuffle Test
% This script performs a shuffle test to control for depth-dependent confounds
% when comparing properties across cell types

%% Load your data
% depths: 1x607 array of scaled depth positions
% clusterIDs: 1x607 array of cell type cluster identifiers
% property: 1x607 array of the property you're measuring (e.g., firing rate, size, etc.)

% Example data loading (replace with your actual data):
% load('your_data.mat', 'depths', 'clusterIDs', 'property');
% Your data

depths = scaledDepth;      % 1x607 scaled depth values
clusterIDs = clusterFn;  % 1x607 cluster identifiers
property = scaledDepth;    % 1x607 values you're comparing (e.g., firing rate)
valid_depths = ~isnan(depths);
valid_property = ~isnan(property);

% For clusterIDs: handle both numeric and cell arrays
if iscell(clusterIDs)
    valid_clusters = ~cellfun(@(x) isempty(x) || (isnumeric(x) && isnan(x)), clusterIDs);
else
    valid_clusters = ~isnan(clusterIDs);
end

% Combine: keep only cells that are valid in ALL arrays
valid_mask = valid_depths & valid_property & valid_clusters;

%% Display removal statistics
fprintf('Original number of cells: %d\n', length(depths));
fprintf('Cells with NaN in depths: %d\n', sum(~valid_depths));
fprintf('Cells with NaN in property: %d\n', sum(~valid_property));
fprintf('Cells with NaN in clusterIDs: %d\n', sum(~valid_clusters));
fprintf('Total cells to remove: %d\n', sum(~valid_mask));
fprintf('Remaining cells: %d\n', sum(valid_mask));

%% Remove NaN entries
depths = depths(valid_mask);
clusterIDs = clusterIDs(valid_mask);
property = property(valid_mask);

fprintf('\nData cleaned! New size: %d cells\n', length(depths));
% Then run the script
%% Parameters
n_shuffles = 10000;  % Number of shuffle iterations
n_cells = length(clusterIDs);

%% Calculate observed test statistic
% Example: mean property value for each cluster
unique_clusters = unique(clusterIDs);
n_clusters = length(unique_clusters);

observed_means = zeros(1, n_clusters);
for i = 1:n_clusters
    mask = clusterIDs == unique_clusters(i);
    observed_means(i) = nanmean(property(mask));
end

% Define test statistic (e.g., variance across cluster means)
observed_stat = nanvar(observed_means);

%% Run shuffle test
shuffle_stats = zeros(n_shuffles, 1);

fprintf('Running %d shuffles...\n', n_shuffles);
for s = 1:n_shuffles
    % Shuffle cluster IDs while maintaining depth positions
    shuffled_clusterIDs = clusterIDs(randperm(n_cells));
    
    % Calculate test statistic on shuffled data
    shuffle_means = zeros(1, n_clusters);
    for i = 1:n_clusters
        mask = shuffled_clusterIDs == unique_clusters(i);
        shuffle_means(i) = nanmean(property(mask));
    end
    
    shuffle_stats(s) = nanvar(shuffle_means);
    
    % Progress update
    if mod(s, 1000) == 0
        fprintf('Completed %d/%d shuffles\n', s, n_shuffles);
    end
end

%% Calculate p-value

p_value = sum(shuffle_stats >= observed_stat) / n_shuffles;
z_score = (observed_stat - nanmean(shuffle_stats)) / nanstd(shuffle_stats);

%% Display results
fprintf('\n=== Shuffle Test Results ===\n');
fprintf('Observed statistic: %.4f\n', observed_stat);
fprintf('Mean of shuffle distribution: %.4f\n', nanmean(shuffle_stats));
fprintf('Std of shuffle distribution: %.4f\n', nanstd(shuffle_stats));
fprintf('P-value: %.4f\n', p_value);
fprintf('Z-score: %.4f\n', z_score);

%% Visualize results
figure('Position', [100, 100, 1200, 400]);

% Plot 1: Shuffle distribution
subplot(1,3,1);
histogram(shuffle_stats, 50, 'Normalization', 'probability', 'FaceColor', [0.7 0.7 0.7]);
hold on;
xline(observed_stat, 'r-', 'LineWidth', 2, 'Label', 'Observed');
xlabel('Test Statistic (Variance of Cluster Means)');
ylabel('Probability');
title('Shuffle Distribution');
legend('Shuffled', 'Observed');

% Plot 2: Observed cluster means
subplot(1,3,2);
bar(1:n_clusters, observed_means);
xlabel('Cluster ID');
ylabel('Mean Property Value');
title('Observed Cluster Means');
xticks(1:n_clusters);
xticklabels(unique_clusters);

% Plot 3: Property vs Depth colored by cluster
subplot(1,3,3);
scatter(depths, property, 30, clusterIDs, 'filled');
xlabel('Scaled Depth');
ylabel('Property Value');
title('Property vs Depth by Cluster');
colormap(jet(n_clusters));
cb = colorbar;
cb.Label.String = 'Cluster ID';

% %% Optional: Pairwise comparisons between clusters
% fprintf('\n=== Pairwise Cluster Comparisons ===\n');
% for i = 1:n_clusters
%     for j = i+1:n_clusters
%         % Observed difference
%         obs_diff = observed_means(i) - observed_means(j);
%         
%         % Shuffle distribution of differences
%         shuffle_diffs = zeros(n_shuffles, 1);
%         for s = 1:n_shuffles
%             shuffled_clusterIDs = clusterIDs(randperm(n_cells));
%             
%             mean_i = mean(property(shuffled_clusterIDs == unique_clusters(i)));
%             mean_j = mean(property(shuffled_clusterIDs == unique_clusters(j)));
%             shuffle_diffs(s) = mean_i - mean_j;
%         end
%         
%         % Two-tailed p-value
%         p_pair = 2 * min(sum(shuffle_diffs >= obs_diff), sum(shuffle_diffs <= obs_diff)) / n_shuffles;
%         
%         fprintf('Cluster %d vs %d: diff = %.4f, p = %.4f\n', ...
%             unique_clusters(i), unique_clusters(j), obs_diff, p_pair);
%     end
% end

%% %%%

% Position-Shuffling Test (Maintain Cluster IDs)
% This script shuffles depth positions while keeping cluster IDs fixed
% to test if depth-dependent effects explain observed patterns

%% Load your data
% depths: 1x607 array of scaled depth positions
% clusterIDs: 1x607 array of cell type cluster identifiers
% property: 1x607 array of the property you're measuring (e.g., firing rate, size, etc.)

% Example data loading (replace with your actual data):
% load('your_data.mat', 'depths', 'clusterIDs', 'property');

%% Parameters
n_shuffles = 10000;  % Number of shuffle iterations
n_cells = length(clusterIDs);

%% Calculate observed test statistic
% Example: mean property value for each cluster
unique_clusters = unique(clusterIDs);
n_clusters = length(unique_clusters);

observed_means = zeros(1, n_clusters);
for i = 1:n_clusters
    mask = clusterIDs == unique_clusters(i);
    observed_means(i) = mean(property(mask));
end

% Define test statistic (e.g., variance across cluster means)
observed_stat = nanvar(observed_means);

%% Run shuffle test
shuffle_stats = zeros(n_shuffles, 1);

fprintf('Running %d shuffles...\n', n_shuffles);
for s = 1:n_shuffles
    % Shuffle depth positions while maintaining cluster IDs
    shuffled_depths = depths(randperm(n_cells));
    
    % Calculate test statistic on shuffled data
    % Note: property values stay with their cluster IDs,
    % but now have randomized depth assignments
    shuffle_means = zeros(1, n_clusters);
    for i = 1:n_clusters
        mask = clusterIDs == unique_clusters(i);
        shuffle_means(i) = nanmean(property(mask));
    end
    
    shuffle_stats(s) = nanvar(shuffle_means);
    
    % Progress update
    if mod(s, 1000) == 0
        fprintf('Completed %d/%d shuffles\n', s, n_shuffles);
    end
end

%% Calculate p-value
p_value = sum(shuffle_stats >= observed_stat) / n_shuffles;
z_score = (observed_stat - mean(shuffle_stats)) / std(shuffle_stats);

%% Display results
fprintf('\n=== Shuffle Test Results ===\n');
fprintf('Observed statistic: %.4f\n', observed_stat);
fprintf('Mean of shuffle distribution: %.4f\n', mean(shuffle_stats));
fprintf('Std of shuffle distribution: %.4f\n', std(shuffle_stats));
fprintf('P-value: %.4f\n', p_value);
fprintf('Z-score: %.4f\n', z_score);

%% Visualize results
figure('Position', [100, 100, 1200, 800]);

% Plot 1: Shuffle distribution
subplot(2,2,1);
histogram(shuffle_stats, 50, 'Normalization', 'probability', 'FaceColor', [0.7 0.7 0.7]);
hold on;
xline(observed_stat, 'r-', 'LineWidth', 2, 'Label', 'Observed');
xlabel('Test Statistic (Variance of Cluster Means)');
ylabel('Probability');
title('Shuffle Distribution');
legend('Shuffled', 'Observed');

% Plot 2: Observed cluster means
subplot(2,2,2);
bar(1:n_clusters, observed_means);
xlabel('Cluster ID');
ylabel('Mean Property Value');
title('Observed Cluster Means');
xticks(1:n_clusters);
xticklabels(unique_clusters);

% Plot 3: Property vs Depth colored by cluster (OBSERVED)
subplot(2,2,3);
shuffled_depths_example = depths(randperm(n_cells));
scatter(shuffled_depths_example, property, 30, clusterIDs, 'filled');
xlabel('Scaled Depth');
ylabel('Property Value');
title('Observed: Property vs Depth by Cluster');
colormap(jet(n_clusters));
cb = colorbar;
cb.Label.String = 'Cluster ID';

% Plot 4: Example shuffled data
subplot(2,2,4);
scatter(shuffled_depths_example, clusterIDs, 30, clusterIDs, 'filled');
xlabel('Scaled Depth (Shuffled)');
ylabel('Property Value');
title('Example Shuffle: Same Clusters, Random Depths');
colormap(jet(n_clusters));
cb = colorbar;
cb.Label.String = 'Cluster ID';


%% Layer assignment analysis
% Define layer boundaries
% avgLayerBounds = [-488 -990; 0 -488; 285.4 0; 588.8 285.4; 1039.4 588.8];
% n_layers = size(avgLayerBounds, 1);
% layer_names = {'wm', 'Layer 5/6', 'Layer 4c', 'Layer 4a/4b', 'Layer 2/3'};
% 
% 
% % Function to assign cells to layers based on depth
% assign_to_layer = @(depth_vals) arrayfun(@(d) find(d >= avgLayerBounds(:,2) & d < avgLayerBounds(:,1), 1, 'first'), depth_vals, 'UniformOutput', false, 'ErrorHandler', @(s,varargin) NaN);
% 
% % Calculate observed layer assignments
% olayers = assign_to_layer(depths);
% observed_layers = cell2mat(olayers);

%%
% Count cells per cluster per layer (OBSERVED)
% observed_counts = zeros(n_clusters, n_layers);
% for i = 1:n_clusters
%     for j = 1:n_layers
%         observed_counts(i, j) = sum(clusterIDs == unCl(i) & observed_layers == j);
%     end
% end
% 
% % [Print observed counts table]
% 
% % Run shuffle to get distribution of layer assignments
% shuffle_counts = zeros(n_shuffles, n_clusters, n_layers);
% 
% for s = 1:n_shuffles
%     shuffled_depths = depths(randperm(n_cells));
%     shuffled_layers = assign_to_layer(shuffled_depths);
%     shuffled_layers = cell2mat(shuffled_layers);
%     for i = 1:n_clusters
%         for j = 1:n_layers
%             shuffle_counts(s, i, j) = sum(clusterIDs == unique_clusters(i) & shuffled_layers == j);
%         end
%     end
% end
% 
% % Calculate mean and std of shuffled counts
% mean_shuffle_counts = squeeze(mean(shuffle_counts, 1))
% std_shuffle_counts = squeeze(std(shuffle_counts, 1))



%% Optional: Pairwise comparisons between clusters
% fprintf('\n=== Pairwise Cluster Comparisons ===\n');
% for i = 1:n_clusters
%     for j = i+1:n_clusters
%         % Observed difference
%         obs_diff = observed_means(i) - observed_means(j);
%         
%         % Shuffle distribution of differences
%         shuffle_diffs = zeros(n_shuffles, 1);
%         for s = 1:n_shuffles
%             shuffled_depths_temp = depths(randperm(n_cells));
%             
%             mean_i = mean(property(clusterIDs == unique_clusters(i)));
%             mean_j = mean(property(clusterIDs == unique_clusters(j)));
%             shuffle_diffs(s) = mean_i - mean_j;
%         end
%         
%         % Two-tailed p-value
%         p_pair = 2 * min(sum(shuffle_diffs >= obs_diff), sum(shuffle_diffs <= obs_diff)) / n_shuffles;
%         
%         fprintf('Cluster %d vs %d: diff = %.4f, p = %.4f\n', ...
%             unique_clusters(i), unique_clusters(j), obs_diff, p_pair);
%     end
% end

% Repeated shuffle analysis: Calculate percentage of specific clusters in specific layers
% Runs 100 shuffle iterations and tracks the percentage each time

%% Parameters
n_iterations = 1000;
selected_rows = [1, 2, 6, 8];  % Clusters of interest
selected_cols = [3, 4];         % Layers of interest (Layer 4 and Layer 5)

%% Storage for results
percentages = zeros(n_iterations, 1);
selected_counts = zeros(n_iterations, 1);

%% Layer boundaries
avgLayerBounds = [-488 -990; 0 -488; 285.4 0; 588.8 285.4; 1039.4 588.8];
n_layers = size(avgLayerBounds, 1);

% Function to assign cells to layers
assign_to_layer = @(depth_vals) arrayfun(@(d) find(d >= avgLayerBounds(:,2) & d < avgLayerBounds(:,1), 1, 'first'), depth_vals, 'UniformOutput', true, 'ErrorHandler', @(s,varargin) NaN);

%% Run iterations
fprintf('Running %d shuffle iterations...\n', n_iterations);
for iter = 1:n_iterations
    % Shuffle depths while maintaining cluster IDs
    shuffled_depths = depths(randperm(n_cells));
    shuffled_layers = assign_to_layer(shuffled_depths);
    
    % Count cells per cluster per layer
    shuffle_counts = zeros(n_clusters, n_layers);
    for i = 1:n_clusters
        for j = 1:n_layers
            shuffle_counts(i, j) = sum(clusterIDs == i & shuffled_layers == j);
        end
    end
    
    % Calculate percentage for selected clusters and layers
    total_cells_in_selected_clusters = sum(shuffle_counts(selected_rows, :), 'all');
    selected_cells = sum(shuffle_counts(selected_rows, selected_cols), 'all');
    percentages(iter) = (selected_cells / total_cells_in_selected_clusters) * 100;
    selected_counts(iter) = selected_cells;
    
    % Progress update
    if mod(iter, 100) == 0
        fprintf('Completed %d/%d iterations\n', iter, n_iterations);
    end
end

%% Calculate statistics
mean_percentage = mean(percentages);
std_percentage = std(percentages);
min_percentage = min(percentages);
max_percentage = max(percentages);
median_percentage = median(percentages);
prtile(percentages)

%% Display results
fprintf('\n=== Results for Clusters %s in Layers %s ===\n', ...
    mat2str(selected_rows), mat2str(selected_cols));
fprintf('Mean percentage: %.2f%%\n', mean_percentage);
fprintf('Std deviation: %.2f%%\n', std_percentage);
fprintf('Median: %.2f%%\n', median_percentage);
fprintf('Range: %.2f%% - %.2f%%\n', min_percentage, max_percentage);
fprintf('Mean count: %.1f cells\n', mean(selected_counts));



%% Optional: Compare to observed data
% Calculate observed percentage
observed_layers = assign_to_layer(depths);
observed_counts = zeros(n_clusters, n_layers);
for i = 1:n_clusters
    for j = 1:n_layers
        observed_counts(i, j) = sum(clusterIDs == i & observed_layers == j);
    end
end

observed_selected = sum(observed_counts(selected_rows, selected_cols), 'all');
observed_total_in_clusters = sum(observed_counts(selected_rows, :), 'all');
observed_percentage = (observed_selected / observed_total_in_clusters) * 100;

fprintf('\n=== Comparison to Observed Data ===\n');
fprintf('Observed percentage: %.2f%%\n', observed_percentage);
fprintf('Observed count: %d cells out of %d total in selected clusters\n', ...
    observed_selected, observed_total_in_clusters);
fprintf('Z-score: %.2f\n', (observed_percentage - mean_percentage) / std_percentage);

% Is observed significantly different?
p_value = sum(percentages >= observed_percentage) / n_iterations;
fprintf('P-value (one-tailed): %.4f\n', p_value);