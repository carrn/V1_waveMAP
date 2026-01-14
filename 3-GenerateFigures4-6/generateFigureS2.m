avgLayerBounds = [ -488 -990; 0 -488; 285.4 0; 588.8 285.4; 1039.4 588.8]; % [1 2 3 4 5]
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
% 23 - kurt
% 24 - FR
% 25 - kurt_2
% 26 - skew
% 27 - TP Type pass A
% 28 - TP Type pass B
% 29 - TP Type
% 30 - ISI PC loadings3
% 31 - ISI PC loadings2
% 32 - ISI PC loadings1
% 33 - SNR
%%  UMAP with duration
figure
umap_xFn = clusterFnData(:,19)+4; %Make positive for visualization
umap_yFn = clusterFnData(:,20)+4; % make positive for visualization
durFn = clusterFnData(:,17);
ampFn = clusterFnData(:,18);
for clusterID = 1:max(cluster)
    FnProp = umap_xFn(clusterFn==clusterID);
    FnProp1 = umap_yFn(clusterFn==clusterID);
    FnProp2 = durFn(clusterFn==clusterID);
    FnProp3 = ampFn(clusterFn==clusterID);
    scatter(FnProp, FnProp1,abs(FnProp2)/max(durFn)*100,colors{clusterID},'filled')%,'AlphaData',log(FnProp3),'MarkerFaceAlpha','flat')
    hold on
end
scatter(1,1,min(abs(durFn))*100,'k')
smallest_dur = min(abs(durFn))
hold on
scatter(1,2,max(abs(durFn))*100,'k')
largest_dur = max(abs(durFn))

%% UMAP with repWidth
figure
umap_xFn = clusterFnData(:,19)+4;
umap_yFn = clusterFnData(:,20)+4;
repFn = clusterFnData(:,22);

a = 100;% scale factor
for clusterID = 1:max(cluster)
    FnProp = umap_xFn(clusterFn==clusterID);
    FnProp1 = umap_yFn(clusterFn==clusterID);
    FnProp2 = repFn(clusterFn==clusterID);
    scatter(FnProp, FnProp1,FnProp2/max(repFn)*a,colors{clusterID},'filled')%,'AlphaData',log(FnProp3),'MarkerFaceAlpha','flat')
    hold on
end

smallest_rep = min(abs(repFn))
scatter(1,1,min(repFn/max(repFn))*a,'k')
hold on

middle_rep = mean([max(abs(repFn)), min(abs(repFn))])
scatter(1,2,middle_rep/max(repFn)*a,'k')
hold on

largest_rep = max(abs(repFn))
scatter(1,3,max(repFn/max(repFn))*a,'k')

%% UMAP with Amplitude
figure
umap_xFn = clusterFnData(:,19)+4;
umap_yFn = clusterFnData(:,20)+4;
durFn = clusterFnData(:,17);
ampFn = clusterFnData(:,18);
a = 100;% scale factor
for clusterID = 1:max(cluster)
    FnProp = umap_xFn(clusterFn==clusterID);
    FnProp1 = umap_yFn(clusterFn==clusterID);
    FnProp2 = ampFn(clusterFn==clusterID);
    scatter(FnProp, FnProp1,FnProp2/max(ampFn)*a,colors{clusterID},'filled')%,'AlphaData',log(FnProp3),'MarkerFaceAlpha','flat')
    hold on
end

figure
scatter(1,1,min(ampFn/max(ampFn))*a,'k')
smallest_amp = min(abs(ampFn))
hold on

scatter(1,2,max(ampFn/max(ampFn))*a,'k')
largest_amp = max(abs(ampFn))

%% correclation between umap and dur, rep, amp


umap_xyFn= sqrt(umap_xFn.^2 + umap_yFn.^2);
[rho,p] =corr(umap_xyFn,durFn)
[rho,p] =corr(umap_xyFn,repFn)
[rho,p] =corr(umap_xyFn,ampFn)
 
%% Fig. S2H  PCA

fProp = clusterFnData(:,[5 6 7 8 10 11]);
fProp = zscore(fProp);
% fProp = fProp./repmat(max(abs(fProp)), size(fProp,1),1);

[coeff, score, latV] = pca(fProp');


% 
% figure;
% 
% colors = clusterColors;
% markers = {'x','o','d','s','s','s','s','s','s'};
% for clusterID=1:9
%     [f, xi] = ksdensity(coeff(clusterFn == clusterID,1));
%     subplot(2,2,1);
%     hold on;
%     plot(xi, f, 'color', colors{clusterID});
%     
%     subplot(2,2,2);
%     plot(nanmean(coeff(clusterFn == clusterID,1)), nanmean(coeff(clusterFn==clusterID,2)),'o','color',colors{clusterID});
%     hold on;
% end
%
corr(coeff(:,1), clusterFnData(:,[5 6 7 8 10 11]))



fig = figure;

for pcID=1
    
    X = clusterFnData(:,[2 13 14]); % Depth; UMAP X; UMAP Y
    X(:,4) = clusterFnData(:,2).*clusterFnData(:,13); % UMAP X + Depth interaction
    X(:,5) = clusterFnData(:,2).*clusterFnData(:,14); % UMAP Y + Depth interaction
    X(:,6) = clusterFnData(:,2).*clusterFnData(:,13).*clusterFnData(:,14); % Interaction between depth, UMAP XY
    
    X(:,7) = 1;
    X(:,8) = clusterFnData(:,16); % Depth Scaled
    X(:,9) = clusterFnData(:,2).*clusterFnData(:,13).*clusterFnData(:,14).*clusterFnData(:,30);
    %  partialcorr(coeff(:,k), A(:,13:14), A(:,2),'type','spearman')
    
    
    [clusterID,bi,layerID,ci,st] = regress(coeff(:,pcID), X(:,[1:7]));% Depth; UMAP X; UMAP Y; UMAP X + Depth interaction; UMAP Y + Depth interaction; % Interaction between depth, UMAP XY
    varExplained(1) = st(1);
    pExplained(1) = st(2);
    
    [clusterID,bi,layerID,ci,st] = regress(coeff(:,pcID), X(:,[1 2 3 7]));% Depth; UMAP X; UMAP Y
    varExplained(2) = st(1);
    pExplained(2) = st(2);
    %     [b,bi,c,ci,st] = regress(coeff(:,k), X(:,[1 2 7]));% Depth; UMAP X
    %     varExplained(3) = st(1);
    %
    %     [b,bi,c,ci,st] = regress(coeff(:,k), X(:,[1 3 7]));% Depth; UMAP Y
    %     varExplained(4) = st(1);
    
    [clusterID,bi,layerID,ci,st] = regress(coeff(:,pcID), X(:,[1 7]));%Depth
    varExplained(3) = st(1);
    pExplained(3) = st(2);
    [clusterID,bi,layerID,ci,st] = regress(coeff(:,pcID), X(:,[2 3 7])); %UMAP X; UMAP Y
    varExplained(4) = st(1);
    pExplained(4) = st(2);
    [clusterID,bi,layerID,ci,st] = regress(coeff(:,pcID), X(:,[8 7]));%Depth Scaled
    varExplained(5) = st(1);
    pExplained(5) = st(2);
    [clusterID,bi,layerID,ci,st] = regress(coeff(:,pcID), X(:,[9 7]));%SNR
    varExplained(6) = st(1);
    pExplained(6) = st(2);
    
    allData = clusterFnData(:,[15]); %Resolution 1.0
    X = dummyvar(allData + 1);
    X(:, end+1) = clusterFnData(:,2);
    [clusterID,bi,layerID,ci,st] = regress(coeff(:,pcID), X); %z-scored candidate cell type(1.0), depth;
    varExplained(7) = st(1);
    pExplained(7) = st(2);
    
    X = dummyvar(allData + 1);
    [clusterID,bi,layerID,ci,st] = regress(coeff(:,pcID), X); %z-scored candidate cell type(1.0);
    varExplained(8) = st(1);
    pExplained(8) = st(2);
    
    
    subplot(1,3,pcID);
    clusterID = bar(1:8, varExplained*100);
    set(gca,'xticklabel',{'Depth + UMAP + Interactions','Depth + UMAP', 'Depth', 'UMAP','Depth Scaled','SNR','Depth + Candidate Cell Type 1.0','Candidate Cell Type 1.0'});
    set(gca,'box','off','TickDir','out')
    ylim([0 11]);
    ylabel('% Variance Explained')
    title(sprintf(['PC',num2str(pcID)]))
    clusterID.FaceColor = 'flat';
    clusterID.CData(1,:) = [0.7490    0.4039    0.7490];
    clusterID.CData(2,:) = [0.7490    0.4039    0.7490];
    clusterID.CData(3,:) = [0.7490    0.4039    0.7490];
    clusterID.CData(4,:) = [0.7490    0.4039    0.7490];
    clusterID.CData(5,:) = [0.7490    0.4039    0.7490];
    clusterID.CData(6,:) = [0.7490    0.4039    0.7490];
    clusterID.CData(7,:) = [.5 0 .5];
    clusterID.CData(8,:) = [.5 0 .5];
end