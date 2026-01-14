%% Depths and amplitudes and Direction Index Fig 4A
clusterFn = clusterFnData(:,15);
directionIdxFn = clusterFnData(:,7);
directionCircVarFn = clusterFnData(:,8);
orientationBandFn = clusterFnData(:,10);
scFn = clusterFnData(:,11);
scaledDepth = clusterFnData(:,16);
ampFn = clusterFnData(:,18);
durFn = clusterFnData(:,17);
depth_bins = clusterFnData(:,21);
edges = [0:0.2:1];
layerBin = 3;
figure
i = 0;
for clusterID = [1 6 8 2 7 3 9 5 4]
    i = i + 1;
    subplot(2,max(cluster),i)
    FnProp = directionIdxFn(clusterFn==clusterID);
    FnProp2 = ampFn(clusterFn==clusterID);
    depthIdx = scaledDepth(clusterFn==clusterID);
    
    scatter(FnProp,depthIdx,FnProp2/max(ampFn)*100,colors{clusterID},'filled')
    [r(clusterID),p(clusterID)] = corr(FnProp2, FnProp);
    yline([avgLayerBounds(:,1);avgLayerBounds(:,2)],'-')
    xline(0.5,'--')
    set(gca,'box','off','TickDir','out')
    
    subplot(2,max(cluster),i+max(cluster))
    
    histogram(FnProp,edges,'Normalization','probability','FaceColor',colors{clusterID})
    ylim([0 1])
    xline(0.5,'--')
    xline(nanmedian(FnProp),'-')
    set(gca,'box','off','TickDir','out')
    medi(clusterID) = nanmedian(FnProp);
    stmedi(clusterID) = nanstd(FnProp);
end
title('Direction Index')
ylabel('Distance from Layer 4 (um)')
xlabel('Cluster')

%% Shuffle test for DI and Amplitude
unCl = unique(clusterFnData(:,15));
unLa = [1:4];
AllAmps = clusterFnData(:,18);
AllDI = clusterFnData(:,7);
shuffledAmps = AllAmps(randperm(length(AllAmps)));
shuffledDI = AllDI(randperm(length(AllDI)));
allA = [];
allD = [];
% pvalue 2/1000
for n=1:1000
    shuffledAmps = AllAmps(randperm(length(AllAmps)));
    shuffledDI = AllDI(randperm(length(AllDI)));
    for clusterID=[1 6 8 2 7 3 9 5 4]
        iX2 = find(clusterFnData(:,15) == unCl(clusterID));
        AperCluster(clusterID) = nanmedian(shuffledAmps(iX2));
        DIperCluster(clusterID) = nanmedian(shuffledDI(iX2));
    end
    allA = [allA ; AperCluster];
    allD = [allD ; DIperCluster];
end

boundsA = median(prctile(allA, [1,99])');
boundsD = median(prctile(allD, [1,99])');
%% Fig4B Shuffle Test for Cluster and layer bin Revision
% 7  - Direction Index
% 15 - Res 1.0 Clustering
% 18 - Amplitude
% 21 - depth bins
unCl = unique(clusterFnData(:,15));
unLa = [1:4];
M = [];
MM = [];
b = 0;
for n = 1:1000
    tempLayerId = clusterFnData(:,21);
    tempLayerId = tempLayerId(randperm(size(tempLayerId,1)));
    
    tempClusterId = clusterFnData(:,15);
    tempClusterId = tempClusterId(randperm(size(tempClusterId,1)));
    for clusterID=[1 6 8 2 7 3 9 5 4]
        b = b+1;
        for layerID = 1:length(unLa)
            iX = find(tempClusterId == unCl(clusterID) & tempLayerId == unLa(layerID));
            M(b,layerID) = nanmedian(clusterFnData(iX,18));
            MM(b,layerID) = nanmedian(clusterFnData(iX,7));
        end
    end
    b = 0;
    ShuffledLayerClusterA(:,:,n) = M;
    ShuffledLayerClusterDI(:,:,n) = MM;
end

boundsCLA = prctile(ShuffledLayerClusterA,[1,99],3);
boundsCLALow = boundsCLA(:,:,1);
boundsCLAUpp = boundsCLA(:,:,2);


boundsCLDi = prctile(ShuffledLayerClusterDI,[1,99],3);
boundsCLDiLow = boundsCLDi(:,:,1);
boundsCLDiUpp = boundsCLDi(:,:,2);


%% Fig4B Median Amps/Depth/Cluster
unCl = unique(clusterFnData(:,15))
unLa = [1:4]
M = [];
MM = [];
b = 0;
for clusterID=[1 6 8 2 7 3 9 5 4]
    b = b+1;
    for layerID = 1:length(unLa)
        iX = find(clusterFnData(:,15) == unCl(clusterID) & clusterFnData(:,21) == unLa(layerID));
        M(b,layerID) = nanmedian(clusterFnData(iX,18));
        MM(b,layerID) = nanmedian(clusterFnData(iX,7));
    end
    iX2 = find(clusterFnData(:,15) == unCl(clusterID));
    AperCluster(clusterID) = nanmedian(clusterFnData(iX2,18));
    AperCluster_err(clusterID) = nanstd(clusterFnData(iX2,18))./sqrt(size(clusterFnData(iX2,18),1));
    DIperCluster(clusterID) = nanmedian(clusterFnData(iX2,7));
    DIperCluster_err(clusterID) = nanstd(clusterFnData(iX2,7))./sqrt(size(clusterFnData(iX2,7),1));
end

figure;
imagesc(M);
colorbar

figure;
imagesc(MM);
colorbar

% Which are significant? 
M<boundsCLALow
M>boundsCLAUpp

MM<boundsCLDiLow
MM>boundsCLDiUpp

%% Fig 4C
figure
for clusterID = 1:9
    errorbar(AperCluster(clusterID),DIperCluster(clusterID),DIperCluster_err(clusterID),DIperCluster_err(clusterID),AperCluster_err(clusterID),AperCluster_err(clusterID),'o','color',colors{clusterID})
    hold on
    xline([boundsA],'--')
    hold on
    yline([boundsD],'--')
    
end
%% Stats for Fig 4C
AllAmps = clusterFnData(:,18);
AllDI = clusterFnData(:,7);
SNR = clusterFnData(:,33);


[rho,pval] = partialcorr(AllAmps,AllDI,SNR)

%% Revisions statistics
% This generates two arrays which have the DI and Amp split into 9 groups (by cell cluster) for ANOVA single factor analysis
testClusterDI = nan([118,9]);
testClusterAmps = nan([118,9]);
for clusterID = 1:9
    testClusterDI(1:length(AllDI(clusterFn==clusterID)),clusterID) = AllDI(clusterFn==clusterID);
    testClusterAmps(1:length(AllAmps(clusterFn==clusterID)),clusterID) = AllAmps(clusterFn==clusterID);
end
