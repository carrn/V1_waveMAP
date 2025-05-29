
%% Initialize All ISI and SNR
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
[e,S,v, tSquare, Explained, mu] = pca(AllISI');


loadings = [uId, e(:,3), e(:,2), e(:,1)];
% transfer into ClusterFN Data in the correct order

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
hold on
plot(S(:,1)-S(:,3),'k', 'LineWidth', 1)
%% Figure 5D
figure
pc_a = 1;
pc_b = 2;
cnt = 1;
for clusterID=1:9
    c = clusterID;
    errorbar(eV(clusterID,pc_a),eV(clusterID,pc_b),eVe(clusterID,pc_b),eVe(clusterID,pc_b),eVe(clusterID,pc_a),eVe(clusterID,pc_a),'o','color',colors{clusterID})
    hold on;
end
xlabel(sprintf('PC %d',pc_a))
ylabel(sprintf('PC %d',pc_b))


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
%% Initialize layer vs orientation idx vs PC
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

%% Stats for loadings and orientation Fig 5F

orientationIdxFn = clusterFnData(:,5);
SNR = clusterFnData(:,33);
PC1 = clusterFnData(:,32);
PC2 = clusterFnData(:,31);
PC3 = clusterFnData(:,30);
loadingsPCsFn = PC1-PC3;

[rho,pval] = partialcorr(loadingsPCsFn,orientationIdxFn,SNR)
