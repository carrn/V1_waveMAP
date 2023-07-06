%% time window

t = [-50:1050];
tIdx = [t > -50 & t < 750];


%%
fig = figure;

colors = clusterColors;
alpha = 0.2;
bigPSTH = [];
ids = [];
layerId = 1;

for clusterID= [ 2 6 8 7]
    
    concatIDs = [];
    concatPSTH = [];
    cnt = 1;
    for sessId = 1:5
        
        %currSessPSTH = allWaveforms(sessId).clusters(clusterID).psthPerCondition;
        currSessPSTH = allWaveforms(sessId).clusters(clusterID).psthPerCondition(allWaveforms(sessId).clusters(clusterID).layerID == layerId ,:,:);
        meanOverTime = nanmean(currSessPSTH(:,:,200:800),3);
        [~,maxCond] = max(meanOverTime,[],2);
        
        for ix=1:length(maxCond)
            V = squeeze(currSessPSTH(ix,maxCond(ix),:));
            concatPSTH(cnt,:) = [V];
            
            cnt = cnt + 1;
        end
        
    end
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
    size(bigPSTH)
    
end
title('avg PSTH per preferred orientation')
xlabel('Time (ms)')
ylabel('Firing Rate')
set(gca,'box','off','TickDir','out') 
%saveas(fig, 'PSTH_neg.pdf','pdf')
%% PSTH by Layer

layers = {'Layer 5/6', 'Layer 4c', 'Layer 4b', 'Layer 2/3'};
layerColors = {'m', 'b','g','r'};
for layerID = [2 3 4 1]
    figure
    bigPSTH = [];
    for clusterID= [7]
        
        concatIDs = [];
        concatPSTH = [];
        cnt = 1;
        for sessId = 1:5
            
            %currSessPSTH = allWaveforms(sessId).clusters(clusterID).psthPerCondition;
            currSessPSTH = allWaveforms(sessId).clusters(clusterID).psthPerCondition(allWaveforms(sessId).clusters(clusterID).layerID == layerID ,:,:);
            meanOverTime = nanmean(currSessPSTH(:,:,200:800),3);
            [~,maxCond] = max(meanOverTime,[],2);
            
            for ix=1:length(maxCond)
                V = squeeze(currSessPSTH(ix,maxCond(ix),:));
                concatPSTH(cnt,:) = [V];
                
                cnt = cnt + 1;
            end
            
        end
        concatPSTH = concatPSTH(:,tIdx);
        if size(concatPSTH,1) == 1
            concatPSTH = [concatPSTH; concatPSTH];
        end
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
        set(gcf,'renderer','Painters')
    end
    figure(6);
    plot(t(tIdx), nanmean(bigPSTH), 'color',layerColors{layerID});
    hold on;
end
%title('avg PSTH per preferred orientation')
xlabel('Time (ms)')
ylabel('Firing Rate')
set(gca,'box','off','TickDir','out') 

%saveas(fig, 'PSTH_neg.pdf','pdf')

set(gcf,'renderer','Painters')
%% Saving
% set(gcf,'renderer','Painters')
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
