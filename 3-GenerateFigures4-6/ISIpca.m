%% Generate All ISI
AllISI = [];
AllSNR = [];
cId = [];
uId = [];
for clusterID = [1 6 8 2 7 3 9 5 4]
    for sessionID=1:5
   
        temp = allWaveforms(sessionID).clusters(clusterID).ISIdensity(allWaveforms(sessionID).clusters(clusterID).vis_resp == 1,:);
        tempId = allWaveforms(sessionID).clusters(clusterID).ID(allWaveforms(sessionID).clusters(clusterID).vis_resp == 1,:);
        tempSnr = allWaveforms(sessionID).clusters(clusterID).snr(allWaveforms(sessionID).clusters(clusterID).vis_resp == 1,:);
        AllISI = [AllISI; temp];
        AllSNR = [AllSNR; tempSnr];
        cId = [cId; clusterID*ones(size(temp,1),1)];
        uId = [uId; tempId, sessionID*ones(size(tempId,1),1)];
    end
end

AllISI = AllISI./repmat(max(AllISI,[],2),[1 size(AllISI,2)]);
% AllISI = (AllISI - repmat(nanmean(AllISI,2),[1 size(AllISI,2)]))./repmat(nanstd(AllISI,[],2),[1 size(AllISI,2)])
[e,S,v, tSquare, Explained, mu] = pca(AllISI');
% e = rotatefactors(e(:,1:6));
%e(:,3) = -e(:,3);
%S(:,3) = -S(:,3);

loadings = [uId, e(:,3), e(:,2), e(:,1)];
% transfer into ClusterFN Data in the correct order

%clusterFnData(:,30) = -clusterFnData(:,30);
%% PC shapes Fig 5C
figure;
cnt = 1;
eV = [];
eVe = [];

for clusterID = [1:9]
    eV(cnt,:) = nanmean(e(cId==clusterID,:));
    eVe(cnt,:) = nanstd(e(cId==clusterID,:))./sqrt(sum(cId==clusterID));
    cnt = cnt + 1;
end
plot(S(:,1:4))
%% 3D PCs
figure; 
% hold on;
  plot3(e(cId==1,1), e(cId==1,2), e(cId==1,3),'.','color',colors{1});
 hold on
 plot3(e(cId==4,1), e(cId==4,2), e(cId==4,3),'.','color',colors{5});
% hold on
% plot3(e(cId==4,1), e(cId==4,2), e(cId==4,3),'.','color',colors{4});

%% Figure 5D
figure
pc_a = 1;
pc_b = 3;
cnt = 1;
for clusterID=1:9
    c = clusterID;
    %plot3(eV(c,1), eV(c,2), eV(c,3), 'o','markerfacecolor',colors{c},'markeredgecolor','k','markersize',12);
     errorbar(eV(clusterID,pc_a),eV(clusterID,pc_b),eVe(clusterID,pc_b),eVe(clusterID,pc_b),eVe(clusterID,pc_a),eVe(clusterID,pc_a),'o','color',colors{clusterID})
    hold on;
end
xlabel(sprintf('PC %d',pc_a))
ylabel(sprintf('PC %d',pc_b))


%%
figure
for clusterID = 1:9
    shaded_errorbar(D(1:end-1), nanmean(AllISI(cId==clusterID,:)),nanstd(AllISI(cId==clusterID,:))./sqrt(sum(cId==clusterID)),colors{clusterID},alpha)
 %plot(D(2:end),nanmean(AllISI(cId==c,:)),'color',colors{c})
hold on
end
%% sorted ISIs
clear ISIcolor
clear sortedISI
clear ISIidx
clear ISIcluster
[sortedISI, ISIidx] = sortrows(AllISI, 'ascend');
for i = 1:length(ISIidx)
    ISIcluster(i) = clusterFnData(ISIidx(i),21);
    if isnan(ISIcluster(i))
        ISIcluster(i) = 6;
    end
    ISIcolor(i) = clusterColors(ISIcluster(i));
end
figure
imagesc(sortedISI)
%% Rug plot
n_pixels = 5;
ISIcolor = cell2mat(ISIcolor);
ISIcolor = reshape(ISIcolor, [3, 607]).*255;
ISIr = repmat(ISIcolor(1,:),n_pixels,1);
ISIg = repmat(ISIcolor(2,:),n_pixels,1);
ISIb = repmat(ISIcolor(3,:),5,1);
ISIcolorrgb(:,:,1) = ISIr;
ISIcolorrgb(:,:,2) = ISIg;
ISIcolorrgb(:,:,3) = ISIb;
ISIcolorrgb = uint8(ISIcolorrgb);
%
ISIcolorrgb = uint8(ISIcolorrgb);
figure
imshow(ISIcolorrgb)

%% ISI by cluster
clear ISIcolor
clear sortedISI
clear ISIidx
clear ISIcluster
sortedISI = [];
for clusterID = [1 6 8 2 7 3 9 5 4]
    sortedISI = [sortedISI; sortrows(AllISI(cId == clusterID,:),[1 2 3 4 5 6 7 8])];

end
figure
imagesc(sortedISI)
%% Rug plot by cluster Fig 5B
for i = 1:length(cId)

    ISIcolor(i) = clusterColors(cId(i));
end

n_pixels = 5;
ISIcolor = cell2mat(ISIcolor);
ISIcolor = reshape(ISIcolor, [3, 607]).*255;
ISIr = repmat(ISIcolor(1,:),n_pixels,1);
ISIg = repmat(ISIcolor(2,:),n_pixels,1);
ISIb = repmat(ISIcolor(3,:),5,1);
ISIcolorrgb(:,:,1) = ISIr;
ISIcolorrgb(:,:,2) = ISIg;
ISIcolorrgb(:,:,3) = ISIb;
ISIcolorrgb = uint8(ISIcolorrgb);
%
ISIcolorrgb = uint8(ISIcolorrgb);
figure
imshow(ISIcolorrgb)
%% ISI by cluster peaks Fig 5B
clear ISIcolor
clear sortedISI
clear ISIidx
clear ISIcluster
sortedISI = [];
for clusterID = [1 6 8 2 7 3 9 5 4]
    isi_data = AllISI(cId == clusterID,:);
    % Get the size of the input data
    [num_neurons, num_bins] = size(isi_data);
    
    % Find the bin index with maximum value for each neuron
    [~, max_peak_indices] = max(isi_data, [], 2);
    
    % Create an array with neuron indices and their peak positions
    neuron_indices = (1:num_neurons)';
    sorting_array = [neuron_indices, max_peak_indices];
    
    % Sort the array by peak positions (column 2)
    [~, sort_idx] = sortrows(sorting_array, 2);
    
    % Reorder the ISI data according to the sorted indices
    sorted_data = isi_data(sort_idx, :);
    
    sortedISI = [sortedISI; sorted_data];

end
figure
imagesc(sortedISI)
%% Shuffle test for ISI and Orientation
SNR = clusterFnData(:,33);
PC1 = clusterFnData(:,32);
PC2 = clusterFnData(:,31);
PC3 = clusterFnData(:,30);
loadingsPCsFn = PC1-PC3;
unCl = unique(clusterFnData(:,15));
AllOI = clusterFnData(:,5);
shuffledLoadings = loadingsPCsFn(randperm(length(loadingsPCsFn)));
shuffledOI = AllOI(randperm(length(AllOI)));
allL = [];
allO = [];

for n=1:500
    shuffledLoadings = loadingsPCsFn(randperm(length(loadingsPCsFn)));
    shuffledOI = AllOI(randperm(length(AllOI)));
    for clusterID=[1 6 8 2 7 3 9 5 4]
        iX2 = find(clusterFnData(:,15) == unCl(clusterID));
        LperCluster(clusterID) = nanmedian(shuffledLoadings(iX2));
        OIperCluster(clusterID) = nanmedian(shuffledOI(iX2));
    end
    allL = [allL ; LperCluster];
    allO = [allO ; OIperCluster];
end

boundsL = median(prctile(allL, [2.5,97.5])');
boundsO = median(prctile(allO, [2.5,97.5])');
%% Fig6 layer vs orientation idx vs PC
%clusterFnData = readmatrix('/cluster_data_chand.csv');
% 15 cluster
% 21 Depth ID
% 5  Orientation IDX
% 23 Kurtosis
% 30 PC 3
SNR = clusterFnData(:,33);
PC1 = clusterFnData(:,32);
PC2 = clusterFnData(:,31);
PC3 = clusterFnData(:,30);
loadingsPCsFn = PC1-PC3;
unCl = unique(clusterFnData(:,15));
depth_bins = clusterFnData(:,21);
unLa = [1:4];
M = [];
order = 0;
for clusterID=[1 6 8 2 7 3 9 5 4]
    order = order+1;
  for layerID = 1:length(unLa)
    currLayer = find(clusterFnData(:,15) == unCl(clusterID) & clusterFnData(:,21) == unLa(layerID));
    M(order,layerID) = nanmedian(clusterFnData(currLayer,32));
  end
  currCluster = find(clusterFnData(:,15) == unCl(clusterID));
  lV = clusterFnData(currCluster,32)-clusterFnData(currCluster,30); 
  %PC1 - PC3
  LperCluster(clusterID) = nanmedian(lV);
  LperCluster_err(clusterID) = nanstd(bootstrp(1000,@nanmean, lV)); % nanstd(lV)./sqrt(size(clusterFnData(currCluster,30),1));
  OIperCluster(clusterID) = nanmedian(clusterFnData(currCluster,5));
  OIperCluster_err(clusterID) = nanstd(clusterFnData(currCluster,5))./sqrt(size(clusterFnData(currCluster,5),1));
end
%[a b ] =partialcorr(clusterFnData(:,5),PC3-PC1,SNR)

figure;
imagesc(M);
colorbar
%% Loadings vs orientation idx Fig 5F
kurtFn = clusterFnData(:,23);
orientationIdxFn = clusterFnData(:,5);
figure
for clusterID = 1:9
    errorbar(LperCluster(clusterID),OIperCluster(clusterID),OIperCluster_err(clusterID),OIperCluster_err(clusterID),LperCluster_err(clusterID),LperCluster_err(clusterID),'o','color',colors{clusterID})
    hold on
    xline([boundsL],'--')
    hold on
    yline([boundsO],'--')
end
ylabel('orientation Idx')
xlabel('PC1-PC3')

%% Depths and Loadings and orientation idx Fig 5E
clusterFn = clusterFnData(:,15);
scFn = clusterFnData(:,11);
orientationIdxFn = clusterFnData(:,5);
scaledDepth = clusterFnData(:,16);
kurtFn = clusterFnData(:,25);
loadingsPC1Fn = rescale(PC1, 0, 1);
loadingsPC3Fn = rescale(PC3, 0, 1);
%loadingsPCsFn = rescale(loadingsPC3Fn.*loadingsPC1Fn, 0, 1);
loadingsPCsFn = rescale(PC1-PC3,1,40);
%kurtFn(kurtFn>6.5) = 20;  %kurtFn(kurtFn>6.5)+
skewFn = clusterFnData(:,26);
frFn = clusterFnData(:,24);
lims = prctile(frFn, 95);

edges = [0:0.2:1];
figure
i = 0;
for clusterID = [1 6 8 2 7 3 9 5 4] %1:max(cluster)
    i = i +1;
    subplot(2,max(cluster),i)
    %FnProp = rescale(orientationIdxFn(clusterFn==clusterID),1,50);
    FnProp2 = orientationIdxFn(clusterFn==clusterID);
    %FnProp2 = skewFn(clusterFn==clusterID)./max(kurtFn).*500;
    FnProp = loadingsPCsFn(clusterFn==clusterID);
    depthIdx = scaledDepth(clusterFn==clusterID);
    %nanmean(bigK(bigK(:,2)==3,1) > 6.5)
    scatter(FnProp2,depthIdx,FnProp,colors{clusterID},'filled')
    hold on
    yline([avgLayerBounds(:,1);avgLayerBounds(:,2)],'-')
    xline(0.5,'--')
    xlim([0 1])
    set(gca,'box','off','TickDir','out') 
    
    subplot(2,max(cluster),i+max(cluster))
    
    histogram(FnProp2,edges,'Normalization','probability','FaceColor',colors{clusterID})
    ylim([0 1])
    xlim([0 1])
    xline(0.5,'--')
    xline(nanmedian(FnProp2),'-')
    set(gca,'box','off','TickDir','out') 
    set(gcf,'renderer','Painters')
end
title('PC1-PC3 Loadings')
ylabel('Distance from Layer 4 (um)')
xlabel('Cluster')
legend('OI')

%% Stats for loadings and orientation Fig 5F

orientationIdxFn = clusterFnData(:,5);
SNR = clusterFnData(:,33);
PC1 = clusterFnData(:,32);
PC2 = clusterFnData(:,31);
PC3 = clusterFnData(:,30);
loadingsPCsFn = PC1-PC3;

[rho,pval] = partialcorr(loadingsPCsFn,orientationIdxFn,SNR)
%%
anova1(PC3, clusterFn)
%old stats
clusterID = [4]
G = PC1 - PC3;
[h,p,ci,st] = ttest2(orientationIdxFn(ismember(clusterFn,clusterID)),...
    orientationIdxFn(ismember(clusterFn,setdiff(1:9,clusterID))))
[h,p,ci,st] = ttest2(G(ismember(clusterFn,clusterID)),...
    G(ismember(clusterFn,setdiff(1:9,clusterID))))
%[p] = ranksum(G(ismember(clusterFn,clusterID)),...
%    G(ismember(clusterFn,setdiff(1:9,clusterID))))
%%

distV = e(:,1:3) - repmat(nanmean(e(:,1:3)),[size(e,1), 1]);
sqrt(sum(distV.^2,2))
hist(sqrt(sum(distV.^2,2)))
X = sqrt(sum(distV.^2,2));
anova1(X, clusterFn)
[p,table,stats] = kruskalwallis(X, clusterFn)
%%  ISI cdf based on kurtosis
figure
cdfplot(bigK(ismember(bigK(:,3), [4]),1))
hold on
cdfplot(bigK(ismember(bigK(:,3), [3 5 9]),1))
hold on
cdfplot(bigK(ismember(bigK(:,3), [7]),1))
hold on
cdfplot(bigK(ismember(bigK(:,3), [1 2]),1))
hold on
cdfplot(bigK(ismember(bigK(:,3), [6 8]),1))
hold on
legend('4','3 5 9','7','1 2','6 8')