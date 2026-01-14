%% time window

t = [-50:1050];
tIdx = [t > -50 & t < 500];


%%
fig = figure;

colors = clusterColors;
alpha = 0.2;
bigPSTH = [];
ids = [];
layerId = 1;
maxFR =[];
cluster_ID = [];
for clusterID= 1:9
    
    concatIDs = [];
    concatPSTH = [];
    cnt = 1;
    clusterID
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
    tNew = t(tIdx);
    
    plot(tNew, PSTH_mean, 'color', colors{clusterID});
    hold on
    PSTH_sem = nanstd(concatPSTH)./sqrt(size(concatPSTH,1));
    
    patch = fill([tNew fliplr(tNew)] , [PSTH_mean+PSTH_sem fliplr(PSTH_mean-PSTH_sem)], colors{clusterID});
    set(patch, 'edgecolor', 'none','FaceAlpha', alpha );
    hold on
    ids = [ids clusterID*ones(1, size(concatPSTH,1))];
    bigPSTH = [bigPSTH; concatPSTH];
    %size(bigPSTH)
    
end
title('avg PSTH per preferred orientation')
xlabel('Time (ms)')
ylabel('Firing Rate')
set(gca,'box','off','TickDir','out') 
xline([0])
set(gcf,'renderer','Painters')
ylim([0 40])
%saveas(fig, 'PSTH_neg.pdf','pdf')
%print -depsc -tiff -r300 -painters avgPSTHforPoster.eps
%% PSTH by Layer
alpha = 0.2;
bigPSTH = [];
ids = [];
layerId = 1;
maxFR =[];
cluster_ID = [];
layers = {'Layer 5/6', 'Layer 4c', 'Layer 4b', 'Layer 2/3', 'WM'};
layerColors = {'m', 'b','g','r', 'k'};
for layerID = [1 2 3 4]
    figure
    bigPSTH = [];
    for sessionID= [1 2 3 4 5 6 7 8 9]% 3 4 5 9]
        
        concatIDs = [];
        concatPSTH = [];
        cnt = 1;
        for sessionID = [ 4 5]
            
            %currSessPSTH = allWaveforms(sessId).clusters(clusterID).psthPerCondition;
            %currSessPSTH = allWaveforms(sessionID).clusters(clusterID).psthPerCondition((allWaveforms(sessionID).clusters(clusterID).layerID == layerID & allWaveforms(sessionID).clusters(clusterID).vis_resp == 1),:,:);
            
            currSessPSTH = allWaveforms(sessionID).clusters(clusterID).psthPerCondition((allWaveforms(sessionID).clusters(clusterID).layerID == layerID),:,:);
            meanOverTime = nanmean(currSessPSTH(:,:,200:800),3);
            [~,maxCond] = max(meanOverTime,[],2);
            
            for ix=1:length(maxCond)
                V = squeeze(currSessPSTH(ix,maxCond(ix),:));
                concatPSTH(cnt,:) = [V];
                cnt = cnt + 1;
            end
            
        end
        %concatPSTH = concatPSTH(:,tIdx);
        %size(concatPSTH)
        if size(concatPSTH,1) > 8
            concatPSTH = concatPSTH(:,tIdx);
            PSTH_mean = nanmean(concatPSTH);
            tNew = t(tIdx);
            plot(tNew, PSTH_mean, 'color', colors{clusterID});
            hold on
            PSTH_sem = nanstd(concatPSTH)./sqrt(size(concatPSTH,1));
            
            patch = fill([tNew fliplr(tNew)] , [PSTH_mean+PSTH_sem fliplr(PSTH_mean-PSTH_sem)], colors{clusterID});
            set(patch, 'edgecolor', 'none','FaceAlpha', alpha );
            hold on
            ids = [ids clusterID*ones(1, size(concatPSTH,1))];
            bigPSTH = [bigPSTH; concatPSTH];
            % size(bigPSTH)
            title(sprintf([' Layer ', layers{layerID}]));
            ylim([0 70]);
            xline([0])
            set(gcf,'renderer','Painters')
            set(gca,'box','off','TickDir','out') 
        else
            %concatPSTH = [concatPSTH; concatPSTH];
            concatPSTH = [concatPSTH; NaN(1,1101)];
        end
    end
    %bigPSTH = bigPSTH(:,tIdx);
    PSTH_mean = nanmean(bigPSTH);
    PSTH_sem = nanstd(bigPSTH)./sqrt(size(bigPSTH,1));
    figure(5);
    plot(t(tIdx), PSTH_mean, 'color',layerColors{layerID});
    hold on
    patch = fill([tNew fliplr(tNew)] , [PSTH_mean+PSTH_sem fliplr(PSTH_mean-PSTH_sem)], layerColors{layerID});
    set(patch, 'edgecolor', 'none','FaceAlpha', alpha );
    hold on;
end
%title('avg PSTH per preferred orientation')
xlabel('Time (ms)')
ylabel('Firing Rate')
set(gca,'box','off','TickDir','out') 
xline([0])
%saveas(fig, 'PSTH_neg.pdf','pdf')

set(gcf,'renderer','Painters')


%% Sanity Check x2

CNT = 0;
for layerID = 1:4
    bigPSTH = [];
    
    for clusterID = 1:9
        concatPSTH = [];
        cnt = 1;
        for sessionID = 1:3
            currLayer = allWaveforms(sessionID).clusters(clusterID).layerID == layerID;
            vis_resp = allWaveforms(sessionID).clusters(clusterID).vis_resp == 1;
            currSessPSTH = allWaveforms(sessionID).clusters(clusterID).psthPerCondition((currLayer & vis_resp),:,:);
            %currSessPSTH = allWaveforms(sessionID).clusters(clusterID).psthPerCondition((allWaveforms(sessionID).clusters(clusterID).layerID == layerID & allWaveforms(sessionID).clusters(clusterID).vis_resp == 1),:,:);
       
            % find average FR for each condition
            meanOverTime = nanmean(currSessPSTH(:,:,200:800),3);
            % Find max condition
            [~,maxCond] = max(meanOverTime,[],2);
            % For each unit, find PSTH for that max condition
            for ix=1:length(maxCond)
                maxCondPSTH = squeeze(currSessPSTH(ix,maxCond(ix),:));
                concatPSTH(cnt,:) = [maxCondPSTH];
                cnt = cnt + 1;
                CNT = CNT +1;
            end
            %concatPSTH has the max cond PSTH for each unit in that
            %session, cluster, layer
            
            

        end
                    % big PSTH stores all max cond PSTHs for that layer
            bigPSTH = [bigPSTH; concatPSTH];
    end
    size(bigPSTH)
    bigPSTH = bigPSTH(:,tIdx);
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


for layerID = 1:4
    bigPSTH = [];
    for clusterID = 1:9
        concatPSTH = [];
        cnt = 1;
        for sessionID = 4:5
            currLayer = allWaveforms(sessionID).clusters(clusterID).layerID == layerID;
            vis_resp = allWaveforms(sessionID).clusters(clusterID).vis_resp == 1;
            %currSessPSTH = allWaveforms(sessionID).clusters(clusterID).psthPerCondition((allWaveforms(sessionID).clusters(clusterID).layerID == layerID),:,:);
            currSessPSTH = allWaveforms(sessionID).clusters(clusterID).psthPerCondition((currLayer & vis_resp),:,:);

            
            % find average FR for each condition
            meanOverTime = nanmean(currSessPSTH(:,:,200:800),3);
            % Find max condition
            [~,maxCond] = max(meanOverTime,[],2);
            % For each unit, find PSTH for that max condition
            for ix=1:length(maxCond)
                maxCondPSTH = squeeze(currSessPSTH(ix,maxCond(ix),:));
                concatPSTH(cnt,:) = [maxCondPSTH];
                cnt = cnt + 1;
                CNT = CNT+1;
            end
            %concatPSTH has the max cond PSTH for each unit in that
            %session, cluster, layer
            
            

        end
                    % big PSTH stores all max cond PSTHs for that layer
            bigPSTH = [bigPSTH; concatPSTH];
    end
    size(bigPSTH)
    bigPSTH = bigPSTH(:,tIdx);
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

%CNT Should equal 591 ( all units in layerIDs 1-4 )
       
%% Sanity Check
figure
for sessionID = 4:5
   for clusterID = 1:9
       for layerID = 4
           
       currSessPSTH = allWaveforms(sessionID).clusters(clusterID).avgPSTH((allWaveforms(sessionID).clusters(clusterID).layerID == layerID),:)';
            
       plot(currSessPSTH, 'color',layerColors{layerID});
        hold on
       end
   end
end



%% Saving
set(gcf,'renderer','Painters')
xline([0])
set(gca,'box','off') 
%print -depsc -tiff -r300 -painters avgPSTHforPoster.eps
    
    
%% All PSTHs
    
bigPSTH = bigPSTH';
bigPSTH_pca = bigPSTH./repmat(max(bigPSTH),[size(bigPSTH,1) 1]);
[coeff, score, varExplained] = pca(bigPSTH_pca);


%%
figure;
for clusterID = 1:max(cluster)
    plot(coeff(ids==clusterID,1), coeff(ids==clusterID,2),'o','color',colors{clusterID});
    hold on
end


%%
%
[pdca] = fitdist(bigPSTH(:,1),'Gamma')
%
%
%
%%%%%%%%%%%%
%% PSTH by Layer
alpha = 0.2;
bigPSTH = [];
ids = [];
layerId = 1;
maxFR =[];
cluster_ID = [];
layers = {'Layer 5/6', 'Layer 4c', 'Layer 4b', 'Layer 2/3', 'WM'};
layerColors = {'m', 'b','g','r', 'k'};
for layerID = [1 2 3 4]
    figure
    bigPSTH = [];
    for sessionID= [1 2 3]
        
        concatIDs = [];
        concatPSTH = [];
        cnt = 1;
        for clusterID = [1 2 3 4 5 6 7 8 9]
             
            %currSessPSTH = allWaveforms(sessId).clusters(clusterID).psthPerCondition;
            %currSessPSTH = allWaveforms(sessionID).clusters(clusterID).psthPerCondition((allWaveforms(sessionID).clusters(clusterID).layerID == layerID & allWaveforms(sessionID).clusters(clusterID).vis_resp == 1),:,:);
            
            currSessPSTH = allWaveforms(sessionID).clusters(clusterID).psthPerCondition((allWaveforms(sessionID).clusters(clusterID).layerID == layerID),:,:);
           
       
        % find average FR for each condition
        meanOverTime = nanmean(currSessPSTH(:,:,200:800),3);
        % Find max condition
            [~,maxCond] = max(meanOverTime,[],2);
            % For each unit, find PSTH for that max condition
            for ix=1:length(maxCond)
                V = squeeze(currSessPSTH(ix,maxCond(ix),:));
                concatPSTH(cnt,:) = [V];
                cnt = cnt + 1;
            end
            
        end
        %concatPSTH = concatPSTH(:,tIdx);
        %size(concatPSTH)
        if size(concatPSTH,1) > 2
            concatPSTH = concatPSTH(:,tIdx);
            PSTH_mean = nanmean(concatPSTH);
            tNew = t(tIdx);
            plot(tNew, PSTH_mean, 'color', colors{clusterID});
            hold on
            PSTH_sem = nanstd(concatPSTH)./sqrt(size(concatPSTH,1));
            
            patch = fill([tNew fliplr(tNew)] , [PSTH_mean+PSTH_sem fliplr(PSTH_mean-PSTH_sem)], colors{clusterID});
            set(patch, 'edgecolor', 'none','FaceAlpha', alpha );
            hold on
            ids = [ids clusterID*ones(1, size(concatPSTH,1))];
            bigPSTH = [bigPSTH; concatPSTH];
            % size(bigPSTH)
            title(sprintf([' Layer ', layers{layerID}]));
            ylim([0 70]);
            xline([0])
            set(gcf,'renderer','Painters')
            set(gca,'box','off','TickDir','out') 
        else
            % concatPSTH = [concatPSTH; concatPSTH];
            concatPSTH = [concatPSTH; NaN(1,1101)];
        end
    end
    %bigPSTH = bigPSTH(:,tIdx);
    PSTH_mean = nanmean(bigPSTH);
    PSTH_sem = nanstd(bigPSTH)./sqrt(size(bigPSTH,1));
    figure(10);
    plot(t(tIdx), PSTH_mean, 'color',layerColors{layerID});
    hold on
    patch = fill([tNew fliplr(tNew)] , [PSTH_mean+PSTH_sem fliplr(PSTH_mean-PSTH_sem)], layerColors{layerID});
    set(patch, 'edgecolor', 'none','FaceAlpha', alpha );
    hold on;
end
%title('avg PSTH per preferred orientation')
xlabel('Time (ms)')
ylabel('Firing Rate')
set(gca,'box','off','TickDir','out')
xline([0])
%saveas(fig, 'PSTH_neg.pdf','pdf')

set(gcf,'renderer','Painters')