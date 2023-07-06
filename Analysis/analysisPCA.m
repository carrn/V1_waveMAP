clusterFnData = readmatrix('/cluster_data_final.csv');
% 1  - Res 2.5  Clustering
% 2  - Raw Depth
% 3  - unit ID
% 4  - Session ID
% 5  - Orientation Index
% 6  - Orientation Cicular Variance
% 7  - Direction Index
% 8  - Direction Cicular Variance
% 9  - Orientation tuning fit_R35
% 10 - Orientation tuning Bandwidth
% 11 - simple complex
% 12 - vis resp
% 13 - umap_x
% 14 - umap_y
% 15 - Res 1.0 Clustering
% 16 - depth_scaled
% 17 - TP Dur
% 18 - Amplitude
% 19 - umap_x seed for paper
% 20 - umap_y seed for paper
% 21 - depth bins
% 22 - repWidth


%%


vResp = clusterFnData(:,12);
clusterFnData = clusterFnData(find(vResp), :);
clusterFnData(:,1) = clusterFnData(:,1)+1;
clusterFnData(:,15) = clusterFnData(:,15)+1;
clusterFn = clusterFnData(:,15);
depth_scaled = clusterFnData(:,16);
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
whichClusters = clusterFn == 1 | clusterFn == 2 | clusterFn == 6 | clusterFn == 8;
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
end

p = (nL23which)/length(nsDepthsBins);
errorr = sqrt((p*(1-p))/length(nsDepthsBins));


mD = nanmean(nsDepths);
sE = nanstd(nsDepths)./sqrt(length(nsDepths));
tV = tinv(0.975,length(nsDepths));
fprintf('\n %3.2f - %3.2f - %3.2f', mD-tV*sE, mD, mD + tV*sE);
%%
L23 = 4;
L4b = 3;
L4c = 2;
L56 = 1;
WM =  5;


nL = length(clusterFnData);
depth_bins  = clusterFnData(:,21);

nL23 =length(depth_bins(depth_bins==L23));%/nL*100;
nL4b =length(depth_bins(depth_bins==L4b));%/nL*100;
nL4c =length(depth_bins(depth_bins==L4c));%/nL*100;
nL56 =length(depth_bins(depth_bins==L56));%/nL*100;
nLWM =length(depth_bins(depth_bins==WM));%/nL*100;
%%

for clusterID = 1:9
whichClusters = clusterID;
layer = 4;
switch layer
    case 1
        nL = length(depth_bins(depth_bins==L56 & clusterFn==whichClusters))
    case 2
        nL = length(depth_bins(depth_bins==L4c & clusterFn==whichClusters))
    case 3
        nL = length(depth_bins(depth_bins==L4b & clusterFn==whichClusters))
    case 4
        nL = length(depth_bins(depth_bins==L23 & clusterFn==whichClusters))
    case 5
        nL = length(depth_bins(depth_bins==WM & clusterFn==whichClusters))
    otherwise
end
end
%%
size(clusterFnData);

fProp = clusterFnData(:,[5 6 7 8 10 11]);
fProp = zscore(fProp);
% fProp = fProp./repmat(max(abs(fProp)), size(fProp,1),1);
[coeff, score, latV] = pca(fProp');

%%
figure;
%colors = {[0 0.3 0.6],[1 0.5 0.2],[0.6 0 0],[0.7 0.5 0],[0 0.7 0.6];};
colors = clusterColors;
markers = {'x','o','d','s','s','s','s','s','s'};
for clusterID=1:9%max(cluster)
    [f, xi] = ksdensity(coeff(clusterFn == clusterID,1));
    subplot(2,2,1);
    hold on;
    plot(xi, f, 'color', colors{clusterID});
    
    subplot(2,2,2);
    plot(nanmean(coeff(clusterFn == clusterID,1)), nanmean(coeff(clusterFn==clusterID,2)),'o','color',colors{clusterID});
    hold on;
end

corr(coeff(:,1), clusterFnData(:,5:11));
plot(clusterFnData(:,1),coeff(:,1))
figure; plot(coeff(:,2),clusterFnData(:,2),'o')

%%
fig = figure;

for pcID=1:3
    
    
    X = clusterFnData(:,[2 13 14]); % Depth; UMAP X; UMAP Y
    X(:,4) = clusterFnData(:,2).*clusterFnData(:,13); % UMAP X + Depth interaction
    X(:,5) = clusterFnData(:,2).*clusterFnData(:,14); % UMAP Y + Depth interaction
    X(:,6) = clusterFnData(:,2).*clusterFnData(:,13).*clusterFnData(:,14); % Interaction between depth, UMAP XY

    X(:,7) = 1;
    X(:,8) = clusterFnData(:,16); 
    
    %  partialcorr(coeff(:,k), A(:,13:14), A(:,2),'type','spearman')
    
    
    
    [b,bi,c,ci,st] = regress(coeff(:,pcID), X(:,[1:7]));% Depth; UMAP X; UMAP Y; UMAP X + Depth interaction; UMAP Y + Depth interaction; % Interaction between depth, UMAP XY
    varExplained(1) = st(1);
    
    [b,bi,c,ci,st] = regress(coeff(:,pcID), X(:,[1 2 3 7]));% Depth; UMAP X; UMAP Y
    varExplained(2) = st(1);
    
    %     [b,bi,c,ci,st] = regress(coeff(:,k), X(:,[1 2 7]));% Depth; UMAP X
    %     varExplained(3) = st(1);
    %
    %     [b,bi,c,ci,st] = regress(coeff(:,k), X(:,[1 3 7]));% Depth; UMAP Y
    %     varExplained(4) = st(1);
    
    [b,bi,c,ci,st] = regress(coeff(:,pcID), X(:,[1 7]));%Depth
    varExplained(3) = st(1);
    
    [b,bi,c,ci,st] = regress(coeff(:,pcID), X(:,[2 3 7])); %UMAP X; UMAP Y
    varExplained(4) = st(1);
        
    [b,bi,c,ci,st] = regress(coeff(:,pcID), X(:,[8 7]));%Depth
    varExplained(5) = st(1);
    
    
    
    %     X = A(:,[1 2]);
    %     X(:,1) = zscore(X(:,1));
    %     X(:,3) = 1;
    %     [b,bi,c,ci,st] = regress(coeff(:,k), X);  %z-scored candidate cell type(2.5); depth
    %     varExplained(7) = st(1);
    %
    %     X = A(:,[1]);
    %     X(:,1) = zscore(X(:,1));
    %     X(:,2) = 1;
    %     [b,bi,c,ci,st] = regress(coeff(:,k), X); %z-scored candidate cell type(2.5);
    %     varExplained(8) = st(1);
    %
    %     X = A(:,[15 2]);
    %     X(:,1) = zscore(X(:,1));
    %     X(:,3) = 1;
    %     [b,bi,c,ci,st] = regress(coeff(:,k), X);  %z-scored candidate cell type(1.0); depth
    %     varExplained(9) = st(1);
    %
    %     X = A(:,[15]);
    %     % X(:,1) = zscore(X(:,1));
    %     X(:,2) = 1;
    %     [b,bi,c,ci,st] = regress(coeff(:,k), X); %z-scored candidate cell type(1.0);
    %     varExplained(10) = st(1);
    
    allData = clusterFnData(:,[15]);
    X = dummyvar(allData + 1);
    X(:, end+1) = clusterFnData(:,2);   
    [b,bi,c,ci,st] = regress(coeff(:,pcID), X); %z-scored candidate cell type(1.0), depth;
    varExplained(6) = st(1);
    
    
    X = dummyvar(allData + 1);
    [b,bi,c,ci,st] = regress(coeff(:,pcID), X); %z-scored candidate cell type(1.0);
    varExplained(7) = st(1);
    
    
    
    subplot(1,3,pcID);
    b = bar(1:7, varExplained*100);
    set(gca,'xticklabel',{'Depth + UMAP + Interactions','Depth + UMAP', 'Depth', 'UMAP','Depth Scaled','Depth + Candidate Cell Type 2.5','Candidate Cell Type 2.5'});
    set(gca,'box','off','TickDir','out') 
    ylim([0 11]);
    ylabel('% Variance Explained')
    title(sprintf(['PC',num2str(pcID)]))
    b.FaceColor = 'flat';
    b.CData(1,:) = [0.7490    0.4039    0.7490];
    b.CData(2,:) = [0.7490    0.4039    0.7490];
    b.CData(3,:) = [0.7490    0.4039    0.7490];
    b.CData(4,:) = [0.7490    0.4039    0.7490];
    b.CData(5,:) = [0.7490    0.4039    0.7490];
    b.CData(6,:) = [.5 0 .5];
    b.CData(7,:) = [.5 0 .5];
end
%%


print -depsc -tiff -r300 -painters PCA.eps