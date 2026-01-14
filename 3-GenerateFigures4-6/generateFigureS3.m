
%% time window

t = [-50:1050];
tIdx = [t > -50 & t < 500];
fig = figure;
layers = {'Layer 5/6', 'Layer 4c', 'Layer 4b', 'Layer 2/3', 'WM','NAN'};
layerColors = {'m', 'b','g','r', 'k', 'y'};
colors = clusterColors;
alpha = 0.2;
%% PSTH by Layer
bigPSTH = [];
concatPSTH = [];
ids = [];
maxFR =[];
cluster_ID = [];
CNT = 0;
% Monkey 1
for layerID = 1:4
    %figure
    bigPSTH = [];
    
    for sessionID= [1 2 3]
        concatIDs = [];
        concatPSTH = [];
        cnt = 1;
        for clusterID = [1 2 3 4 5 6 7 8 9]
            
            currSessPSTH = allWaveforms(sessionID).clusters(clusterID).psthPerCondition((allWaveforms(sessionID).clusters(clusterID).layerID == layerID & allWaveforms(sessionID).clusters(clusterID).vis_resp == 1),:,:);
            
            % find average FR for each condition
            meanOverTime = nanmean(currSessPSTH(:,:,200:800),3);
            % Find max condition
            [~,maxCond] = max(meanOverTime,[],2);
            % For each unit, find PSTH for that max condition
            for ix=1:length(maxCond)
                V = squeeze(currSessPSTH(ix,maxCond(ix),:));
                concatPSTH(cnt,:) = [V];
                cnt = cnt + 1;
                CNT = CNT +1;
            end
        end
        % If there are more than 1 unit within that layer/session, save
        % within bigPSTH and plot
        if size(concatPSTH,1) > 1
            concatPSTH = concatPSTH(:,tIdx);
            PSTH_mean = nanmean(concatPSTH);
            tNew = t(tIdx)-60;
            
            
            ids = [ids clusterID*ones(1, size(concatPSTH,1))];
            bigPSTH = [bigPSTH; concatPSTH];
        else
            concatPSTH = [concatPSTH; NaN(1,1101)];
        end
        % big PSTH stores all max cond PSTHs for that layer
    end
    PSTH_mean = nanmean(bigPSTH);
    PSTH_sem = nanstd(bigPSTH)./sqrt(size(bigPSTH,1));
    figure(20);
    tNew = t(tIdx)-60;
    plot(tNew, PSTH_mean, 'color',layerColors{layerID});
    hold on
    patch = fill([tNew fliplr(tNew)] , [PSTH_mean+PSTH_sem fliplr(PSTH_mean-PSTH_sem)], layerColors{layerID});
    set(patch, 'edgecolor', 'none','FaceAlpha', alpha );
    hold on;
end
title('avg PSTH per preferred orientation Monkey 1')
xlabel('Time (ms)')
ylabel('Firing Rate')
set(gca,'box','off','TickDir','out')
xline([0])
set(gcf,'renderer','Painters')

%Monkey 2
bigPSTH = [];
concatPSTH = [];
ids = [];
maxFR =[];
cluster_ID = [];

for layerID = 1:3
    %figure
    bigPSTH = [];
    for sessionID= [4 5]
        concatIDs = [];
        concatPSTH = [];
        cnt = 1;
        for clusterID = [1 2 3 4 5 6 7 8 9]
            
            currSessPSTH = allWaveforms(sessionID).clusters(clusterID).psthPerCondition((allWaveforms(sessionID).clusters(clusterID).layerID == layerID & allWaveforms(sessionID).clusters(clusterID).vis_resp == 1),:,:);
            
            % find average FR for each condition
            meanOverTime = nanmean(currSessPSTH(:,:,200:800),3);
            % Find max condition
            [~,maxCond] = max(meanOverTime,[],2);
            % For each unit, find PSTH for that max condition
            for ix=1:length(maxCond)
                V = squeeze(currSessPSTH(ix,maxCond(ix),:));
                concatPSTH(cnt,:) = [V];
                cnt = cnt + 1;
                CNT = CNT+1;
            end
            %concatPSTH has the max cond PSTH for each unit in that
            %session, cluster, layer
        end
        % If there are more than 1 unit within that layer/session, save
        % within bigPSTH and plot
        if size(concatPSTH,1) > 1
            concatPSTH = concatPSTH(:,tIdx);
            PSTH_mean = nanmean(concatPSTH);
            tNew = t(tIdx)-60;
            
            ids = [ids clusterID*ones(1, size(concatPSTH,1))];
            bigPSTH = [bigPSTH; concatPSTH];
        else
            concatPSTH = [concatPSTH; NaN(1,1101)];
        end
        % big PSTH stores all max cond PSTHs for that layer
    end
    PSTH_mean = nanmean(bigPSTH);
    PSTH_sem = nanstd(bigPSTH)./sqrt(size(bigPSTH,1));
    figure(21);
    tNew = t(tIdx)-60;
    plot(tNew, PSTH_mean, 'color',layerColors{layerID});
    hold on
    patch = fill([tNew fliplr(tNew)] , [PSTH_mean+PSTH_sem fliplr(PSTH_mean-PSTH_sem)], layerColors{layerID});
    set(patch, 'edgecolor', 'none','FaceAlpha', alpha );
    hold on;
end
title('avg PSTH per preferred orientation Monkey 2')
xlabel('Time (ms)')
ylabel('Firing Rate')
set(gca,'box','off','TickDir','out')
xline([0])
set(gcf,'renderer','Painters')



%% PSTH by Cluster
alpha = 0.2;
bigPSTH = [];
ids = [];
maxFR =[];
cluster_ID = [];
figure
for clusterID= 1:9
    
    concatIDs = [];
    concatPSTH = [];
    cnt = 1;
    
    for sessionID = 1:5
        %For each unit, find the condition that had the highest average
        %spikes/s
        currSessPSTH = allWaveforms(sessionID).clusters(clusterID).psthPerCondition;
        %currSessPSTH = allWaveforms(sessId).clusters(clusterID).psthPerCondition(allWaveforms(sessId).clusters(clusterID).layerID == layerId ,:,:);
        meanOverTime = nanmean(currSessPSTH(:,:,200:800),3);
        %size(meanOverTime);
        [~,maxCond] = max(meanOverTime,[],2);
        cluster_ID = [cluster_ID; allWaveforms(sessionID).clusters(clusterID).ID , sessionID*ones(size(allWaveforms(sessionID).clusters(clusterID).ID))];
        %For each unit, and its optimal condition, what is the PSTH?
        for ix=1:length(maxCond)
            V = squeeze(currSessPSTH(ix,maxCond(ix),:));
            concatPSTH(cnt,:) = [V];
            cnt = cnt + 1;
        end
    end
    concatPSTH = concatPSTH(:,tIdx);
    size(concatPSTH)
    maxFR = [maxFR; max(concatPSTH')'];
    PSTH_mean = nanmean(concatPSTH);
    tNew = t(tIdx)-60;
    
    plot(tNew, PSTH_mean, 'color', colors{clusterID});
    hold on
    PSTH_sem = nanstd(concatPSTH)./sqrt(size(concatPSTH,1));
    
    patch = fill([tNew fliplr(tNew)] , [PSTH_mean+PSTH_sem fliplr(PSTH_mean-PSTH_sem)], colors{clusterID});
    set(patch, 'edgecolor', 'none','FaceAlpha', alpha );
    hold on
    ids = [ids clusterID*ones(1, size(concatPSTH,1))];
    bigPSTH = [bigPSTH; concatPSTH];
    
    
end
title('avg PSTH per preferred orientation')
xlabel('Time (ms)')
ylabel('Firing Rate')
set(gca,'box','off','TickDir','out')
xline([0])
set(gcf,'renderer','Painters')
ylim([0 40])

%% Simple/Complex figure by cluster
clusterFn = clusterFnData(:,15);
scFn = clusterFnData(:,11);
sessionFn = clusterFnData(:,4);
scaledDepth = clusterFnData(:,16);
edges = [0:0.4:2];
monkey1FnProp = [];
monkey2FnProp = [];

monkey1FnProp1 = [];
monkey2FnProp1 = [];
figure
for sessionID = [1 2 3 4 5]
    i = 0;
    for clusterID = [1 6 8 2 7 3 9 5 4] %1:max(cluster)
        i = i +1;
        subplot(2,max(cluster),i)
        FnProp = scFn(clusterFn==clusterID & sessionFn==sessionID);
        depthIdx = scaledDepth(clusterFn==clusterID & sessionFn==sessionID);
        hold on
        if sessionID == 1 |  sessionID == 2 |  sessionID == 3
            scatter(FnProp,depthIdx,[],colors{clusterID},'diamond')
            monkey1FnProp = [monkey1FnProp ; FnProp];
            monkey1FnProp1 = [monkey1FnProp1 ; ones(size(FnProp))*clusterID];
        elseif sessionID == 4 |  sessionID == 5
            scatter(FnProp,depthIdx,[],colors{clusterID},'square','filled')
            monkey2FnProp = [monkey2FnProp ; FnProp];
            monkey2FnProp1 = [monkey2FnProp1 ; ones(size(FnProp))*clusterID];
        end
        yline([avgLayerBounds(:,1);avgLayerBounds(:,2)],'-')
        xline(1,'--')
        set(gca,'box','off','TickDir','out')
        xlim([0 2])
        
    end

end

title('Simple Complex Index')
ylabel('Distance from Layer 4 (um)')
xlabel('Cluster')



set(gca,'box','off','TickDir','out')
for sessionID = 1:5
i = 0;
for clusterID =  [1 6 8 2 7 3 9 5 4]
    i = i +1;
    subplot(2,max(cluster),i+max(cluster))
    if sessionID == 1 |  sessionID == 2 |  sessionID == 3
        FnProp = monkey1FnProp(monkey1FnProp1 == clusterID);
        histogram(FnProp,edges,'Normalization','probability','FaceColor',colors{clusterID})
        set(gca,'box','off','TickDir','out')
        xline(nanmedian(FnProp),'-')
        hold on
    elseif sessionID == 4 |  sessionID == 5
        FnProp = monkey2FnProp(monkey2FnProp1 == clusterID);
        histogram(FnProp,edges,'Normalization','probability','FaceColor',colors{clusterID}*0.2)
        set(gca,'box','off','TickDir','out')
        hold on
        xline(nanmedian(FnProp),':')
    end
    
    
    ylim([0 1])
        xlim([0 2])
        xline(1,'--')
end
end
%% All Simple Complex cells by monkey

clusterFn = clusterFnData(:,15);
sessionFn = clusterFnData(:,4);
scFn = clusterFnData(:,11);
scaledDepth = clusterFnData(:,16);
edges = [0:0.4:2];

figure
for sessionID = [1 2 3]
    for clusterID = 1:max(cluster)
        
        FnProp = scFn(clusterFn==clusterID & sessionFn==sessionID);
        depthIdx = scaledDepth(clusterFn==clusterID & sessionFn==sessionID);
        scatter(FnProp,depthIdx,[],[0.4 0.4 0.4],'diamond')
        yline([avgLayerBounds(:,1);avgLayerBounds(:,2)],'-')
        xline(1,'--')
        set(gca,'box','off','TickDir','out')
        hold on
        
    end
end
title('Simple Complex Index Monkey 1')
ylabel('Distance from Layer 4 (um)')
xlabel('Cluster')


for sessionID = [4 5]
    for clusterID = 1:max(cluster)
        
        FnProp = scFn(clusterFn==clusterID & sessionFn==sessionID);
        depthIdx = scaledDepth(clusterFn==clusterID & sessionFn==sessionID);
        scatter(FnProp,depthIdx,[],[0.4 0.4 0.4],'square','filled')
        yline([avgLayerBounds(:,1);avgLayerBounds(:,2)],'-')
        xline(1,'--')
        set(gca,'box','off','TickDir','out')
        hold on
        
    end
end
title('Simple Complex Index Monkey 2')
ylabel('Distance from Layer 4 (um)')
xlabel('Cluster')

%% Simple Complex Distributions by monkey
figure
subplot(2,1,1)
histogram(monkey1FnProp,edges,'Normalization','probability','FaceColor',[0.8 0.8 0.8])
ylim([0 1])
xlim([0 2])
xline(1,'--')
title('Simple Complex Index Monkey 1')
set(gca,'box','off','TickDir','out')

subplot(2,1,2)
histogram(monkey2FnProp,edges,'Normalization','probability','FaceColor',[0.4 0.4 0.4])
ylim([0 1])
xlim([0 2])
xline(1,'--')
title('Simple Complex Index Monkey 2')
set(gca,'box','off','TickDir','out')

