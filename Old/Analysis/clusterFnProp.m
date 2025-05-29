avgLayerBounds = [ -488 -990; 0 -488; 285.4 0; 588.8 285.4; 1039.4 588.8]; % [1 2 3 4 5]


%% Simple/Complex figure
clusterFn = clusterFnData(:,15);
scFn = clusterFnData(:,11);
scaledDepth = clusterFnData(:,16);
edges = [0:0.4:2];
figure
i = 0;
for clusterID = [1 6 8 2 7 3 9 5 4] %1:max(cluster)
    i = i +1;
    subplot(2,max(cluster),i)
    FnProp = scFn(clusterFn==clusterID);
    depthIdx = scaledDepth(clusterFn==clusterID);
    
    scatter(FnProp,depthIdx,[],colors{clusterID},'filled')
    yline([avgLayerBounds(:,1);avgLayerBounds(:,2)],'-')
    xline(1,'--')
    set(gca,'box','off','TickDir','out') 
        xlim([0 2])
    subplot(2,max(cluster),i+max(cluster))

    histogram(FnProp,edges,'Normalization','probability','FaceColor',colors{clusterID})
    ylim([0 1])
    xlim([0 2])
    xline(1,'--')
    %xline(nanmean(FnProp),'-')
    set(gca,'box','off','TickDir','out') 
    
end
title('Simple Complex Index')
ylabel('Distance from Layer 4 (um)')
xlabel('Cluster')

%% All Simple Complex cells
figure
ampFn = clusterFnData(:,18);
edges = [0:0.4:1];
for clusterID = 1:max(cluster)
    %subplot(2,1,1)
    FnProp = scFn(clusterFn==clusterID);
    depthIdx = scaledDepth(clusterFn==clusterID);
    FnProp2 = ampFn(clusterFn==clusterID);
    FnProp1 = clusterFn(clusterFn==clusterID);
    %FnProp2/max(ampFn)*100;
    %FnProp1*5
    %colors{clusterID}
    scatter(FnProp,depthIdx,[],[0.4 0.4 0.4])
    yline([avgLayerBounds(:,1);avgLayerBounds(:,2)],'-')
    xline(1,'--')
    set(gca,'box','off','TickDir','out')
    hold on
    %subplot(2,2,1)
%     edges = [0:0.4:2];
%     histogram(FnProp,edges,'Normalization','probability','FaceColor',colors{clusterID})
%     ylim([0 1])
%     xlim([0 2])
%     xline(1,'--')
%     xline(mean(FnProp),'-')
%     set(gca,'box','off','TickDir','out') 
%     hold on
end
title('Simple Complex Index')
ylabel('Distance from Layer 4 (um)')
xlabel('Cluster')
%set(gca,'xtick',[],'XColor', 'none')


%% 
set(gcf,'renderer','Painters')
print -depsc -tiff -r300 -painters SimpleComplexIndexforPoster.eps 

%% Orientation Index figure
orientationIdxFn = clusterFnData(:,5);
figure
edges = [0:0.2:1];
i = 0;
for clusterID = [1 6 8 2 7 3 9 5 4] %1:max(cluster)
    i = i +1;
    subplot(2,max(cluster),i)
    FnProp = orientationIdxFn(clusterFn==clusterID);
    depthIdx = scaledDepth(clusterFn==clusterID);
    
    scatter(FnProp,depthIdx,[],colors{clusterID},'filled')
    yline([avgLayerBounds(:,1);avgLayerBounds(:,2)],'-')
    xline(0.5,'--')
    set(gca,'box','off','TickDir','out') 
    
    subplot(2,max(cluster),i+max(cluster))
    
    histogram(FnProp,edges,'Normalization','probability','FaceColor',colors{clusterID})
    ylim([0 1])
    xline(0.5,'--')
    set(gca,'box','off','TickDir','out') 
end
title('Orientation Index')
ylabel('Distance from Layer 4 (um)')
xlabel('Cluster')
%set(gca,'xtick',[],'XColor', 'none')
%set(gcf,'renderer','Painters')
%% 
%print -depsc -tiff -r300 -painters OrientationIndexforPoster.eps   
%% Direction Index figure
directionIdxFn = clusterFnData(:,7);
figure
edges = [0:0.2:1];
i = 0;
for clusterID = [1 6 8 2 7 3 9 5 4] %1:max(cluster)
    i = i +1;
    subplot(2,max(cluster),i)
    FnProp = directionIdxFn(clusterFn==clusterID);
    depthIdx = scaledDepth(clusterFn==clusterID);
    
    scatter(FnProp,depthIdx,[],colors{clusterID},'filled')
    yline([avgLayerBounds(:,1);avgLayerBounds(:,2)],'-')
    xline(0.5,'--')
    set(gca,'box','off','TickDir','out') 
    
    subplot(2,max(cluster),i+max(cluster))
    
    histogram(FnProp,edges,'Normalization','probability','FaceColor',colors{clusterID})
    ylim([0 1])
    xline(0.5,'--')
    set(gca,'box','off','TickDir','out') 
end
title('Direction Index')
ylabel('Distance from Layer 4 (um)')
xlabel('Cluster')
%set(gca,'xtick',[],'XColor', 'none')
%set(gcf,'renderer','Painters')
%% 
%print -depsc -tiff -r300 -painters DirectionIndexforPoster.eps 
%% Simple Complex and Orientation Index figure
directionIdxFn = clusterFnData(:,7);
orientationIdxFn = clusterFnData(:,5);
figure
edges = [0:0.4:2];
i = 0;
for clusterID = [1 6 8 2 7 3 9 5 4] %1:max(cluster)
    i = i +1;
    subplot(2,max(cluster),i)
    FnProp = scFn(clusterFn==clusterID);
    FnProp2 = orientationIdxFn(clusterFn==clusterID);
    depthIdx = scaledDepth(clusterFn==clusterID);
    
    scatter(FnProp,depthIdx,FnProp2*50,colors{clusterID},'filled')
    [r(clusterID),p(clusterID)] = corr(FnProp2, FnProp, 'type','spearman');
    yline([avgLayerBounds(:,1);avgLayerBounds(:,2)],'-')
    xline(1,'--')
    set(gca,'box','off','TickDir','out') 
    
    subplot(2,max(cluster),i+max(cluster))
    
    histogram(FnProp,edges,'Normalization','probability','FaceColor',colors{clusterID})
    ylim([0 1])
    xline(1,'--')
    xline(nanmean(FnProp))
    set(gca,'box','off','TickDir','out') 
end
title('Simple Complex Index')
ylabel('Distance from Layer 4 (um)')
xlabel('Cluster')
%set(gca,'xtick',[],'XColor', 'none')
%set(gcf,'renderer','Painters')

%% Direction and Orientation Index figure
directionIdxFn = clusterFnData(:,7);
orientationIdxFn = clusterFnData(:,5);
figure
edges = [0:0.2:1];
i = 0;
for clusterID = [1 6 8 2 7 3 9 5 4] %1:max(cluster)
    i = i +1;
    subplot(2,max(cluster),i)
    FnProp = directionIdxFn(clusterFn==clusterID);
    FnProp2 = orientationIdxFn(clusterFn==clusterID);
    depthIdx = scaledDepth(clusterFn==clusterID);
    
    scatter(FnProp2,depthIdx,FnProp*30,colors{clusterID},'filled')
    [r(clusterID),p(clusterID)] = corr(FnProp2, FnProp, 'type','spearman');
    yline([avgLayerBounds(:,1);avgLayerBounds(:,2)],'-')
    xline(0.5,'--')
    set(gca,'box','off','TickDir','out') 
    
    subplot(2,max(cluster),i+max(cluster))
    
    histogram(FnProp2,edges,'Normalization','probability','FaceColor',colors{clusterID})
    ylim([0 1])
    xline(0.5,'--')
    set(gca,'box','off','TickDir','out') 
end
title('Orientation Index')
ylabel('Distance from Layer 4 (um)')
xlabel('Cluster')
%set(gca,'xtick',[],'XColor', 'none')
%set(gcf,'renderer','Painters')

%% OrientationTuning Bandwidth figure
orientationTuningBandWidthIdxFn = clusterFnData(:,10);
figure
edges = [1:10:90];
i = 0;
for clusterID = [1 6 8 2 7 3 9 5 4] %1:max(cluster)
    i = i +1;
    subplot(2,max(cluster),i)
    FnProp = orientationTuningBandWidthIdxFn(clusterFn==clusterID);
    depthIdx = scaledDepth(clusterFn==clusterID);
    
    scatter(FnProp,depthIdx,[],colors{clusterID},'filled')
    yline([avgLayerBounds(:,1);avgLayerBounds(:,2)],'-')
    xline(45,'--')
    xlim([0 90])
    xticks([0 30 60 90])
    set(gca,'box','off','TickDir','out') 
    
    subplot(2,max(cluster),i+max(cluster))
    
    histogram(FnProp,edges,'Normalization','probability','FaceColor',colors{clusterID})
    ylim([0 1])
    xlim([0 90])
    xticks([0 30 60 90])
    xline(45,'--')
    set(gca,'box','off','TickDir','out') 
end
title('Orientation Tuning Bandwidth')
ylabel('Distance from Layer 4 (um)')
xlabel('Cluster')
%set(gca,'xtick',[],'XColor', 'none')
%set(gcf,'renderer','Painters')
%% 
%print -depsc -tiff -r300 -painters OrientationTuningBandwidthIndexforPoster.eps 
%% Depths and amplitudes and simple/Complex
clusterFn = clusterFnData(:,15);
scFn = clusterFnData(:,11);
scaledDepth = clusterFnData(:,16);
ampFn = clusterFnData(:,18);
durFn = clusterFnData(:,17);
edges = [0:0.4:2];
figure
i = 0;
for clusterID = [1 6 8 2 7 3 9 5 4] %1:max(cluster)
    i = i +1;
    subplot(2,max(cluster),i)
    FnProp = scFn(clusterFn==clusterID);
    FnProp2 = ampFn(clusterFn==clusterID);
    depthIdx = scaledDepth(clusterFn==clusterID);
    
    scatter(FnProp,depthIdx,FnProp2/max(ampFn)*50,colors{clusterID},'filled')
    
    yline([avgLayerBounds(:,1);avgLayerBounds(:,2)],'-')
    xline(1,'--')
    set(gca,'box','off','TickDir','out') 
    
    subplot(2,max(cluster),i+max(cluster))
    
    histogram(FnProp,edges,'Normalization','probability','FaceColor',colors{clusterID})
    ylim([0 1])
    xlim([0 2])
    xline(1,'--')
    xline(nanmean(FnProp),'-')
    set(gca,'box','off','TickDir','out') 
    
end
title('Simple Complex Index')
ylabel('Distance from Layer 4 (um)')
xlabel('Cluster')
%% Depths and amplitudes and Direction Index correlation by layer
clusterFn = clusterFnData(:,15);
directionIdxFn = clusterFnData(:,7);
scFn = clusterFnData(:,11);
scaledDepth = clusterFnData(:,16);
ampFn = clusterFnData(:,18);
durFn = clusterFnData(:,17);
depth_bins = clusterFnData(:,21);
edges = [0:0.2:1];
figure
i = 0;
layerBin = 3;
for clusterID = 1:max(cluster)
    i = i +1;
    subplot(2,max(cluster),i)
    FnProp = directionIdxFn(clusterFn==clusterID & depth_bins==layerBin);
    FnProp2 = ampFn(clusterFn==clusterID & depth_bins==layerBin);
    depthIdx = scaledDepth(clusterFn==clusterID & depth_bins==layerBin);
    
    scatter(FnProp,depthIdx,FnProp2/max(ampFn)*50,colors{clusterID},'filled')
    [r(clusterID),p(clusterID)] = corr(FnProp2, FnProp,'type','spearman');
    yline([avgLayerBounds(:,1);avgLayerBounds(:,2)],'-')
    xline(0.5,'--')
    set(gca,'box','off','TickDir','out') 
    
    subplot(2,max(cluster),i+max(cluster))
    
    histogram(FnProp,edges,'Normalization','probability','FaceColor',colors{clusterID})
    ylim([0 1])
    xline(0.5,'--')
    xline(nanmean(FnProp),'-')
    set(gca,'box','off','TickDir','out') 
    medi(clusterID) = nanmean(FnProp);
    stmedi(clusterID) = nanstd(FnProp);
end
title('Direction Index')
ylabel('Distance from Layer 4 (um)')
xlabel('Cluster')
r
p
medi
%% Depths and amplitudes and Direction Index
figure
i = 0;
for clusterID = [1 6 8 2 7 3 9 5 4]
    i = i +1;
    subplot(2,max(cluster),i)
    FnProp = directionIdxFn(clusterFn==clusterID);
    FnProp2 = ampFn(clusterFn==clusterID);
    depthIdx = scaledDepth(clusterFn==clusterID);
    
    scatter(FnProp,depthIdx,FnProp2/max(ampFn)*50,colors{clusterID},'filled')
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
    medi(clusterID) = nanmean(FnProp);
    stmedi(clusterID) = nanstd(FnProp);
end
title('Direction Index')
ylabel('Distance from Layer 4 (um)')
xlabel('Cluster')
r
p
medi
%print -depsc -tiff -r300 -painters durAmpLaminarforPoster.eps 
%% Depths and amplitudes jittered
figure
i = 0;

for clusterID = [1 6 8 2 7 3 9 5 4] %1:max(cluster)
    i = i +1;
    subplot(1,max(cluster),i)  
    FnProp2 = ampFn(clusterFn==clusterID);
    FnProp =  rand(size(FnProp2));
    depthIdx = scaledDepth(clusterFn==clusterID);
    scale = 200/max(ampFn);
    scatter(FnProp,depthIdx,FnProp2*scale,colors{clusterID},'filled')
    
    yline([avgLayerBounds(:,1);avgLayerBounds(:,2)],'-')
    set(gca,'box','off','TickDir','out') 
  
end
hold on
scatter(0.5,-750,min(ampFn)*scale,'k')
smallest_dur = min(ampFn)
hold on
scatter(0.5,-800,max(ampFn)*scale/2,'k')
largest_dur = max(ampFn)/2
hold on
scatter(0.5,-900,max(ampFn)*scale,'k')
largest_dur = max(ampFn)
title('Laminar Organization by amplitude')
%ylabel('Distance from Layer 4 (um)')
xlabel('Cluster')
%%  UMAP with duration
figure
umap_xFn = clusterFnData(:,19)+4;
umap_yFn = clusterFnData(:,20)+4;
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
%print -depsc -tiff -r300 -painters UMAPdurforPoster.eps 
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
scatter(1,1,min(ampFn/max(ampFn))*a,'k')
smallest_amp = min(abs(ampFn))
hold on

scatter(1,2,max(ampFn/max(ampFn))*a,'k')
largest_amp = max(abs(ampFn))
%print -depsc -tiff -r300 -painters UMAPampforPoster.eps 

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

smallest_amp = min(abs(repFn))
scatter(1,1,min(repFn/max(repFn))*a,'k')
hold on

middle_amp = mean([max(abs(repFn)), min(abs(repFn))])
scatter(1,2,middle_amp/max(repFn)*a,'k')
hold on

largest_amp = max(abs(repFn))
scatter(1,3,max(repFn/max(repFn))*a,'k')
%print -depsc -tiff -r300 -painters UMAPRepforPoster.eps 

%%
figure
[h c] = hist(ampFn);
bar(c, h)
%%
figure

%%
figure
[h c] = hist(durFn);
bar(c, h)
