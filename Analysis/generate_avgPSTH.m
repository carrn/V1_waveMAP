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

for clusterID= [1 2 6 8 7]
    
    concatIDs = [];
    concatPSTH = [];
    cnt = 1;
    for sessId = 1:5
        
        currSessPSTH = allWaveforms(sessId).clusters(clusterID).psthPerCondition;
        %currSessPSTH = allWaveforms(sessId).clusters(clusterID).psthPerCondition(allWaveforms(sessId).clusters(clusterID).layerID == layerId ,:,:);
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
xline([0])
set(gcf,'renderer','Painters')
ylim([0 40])
%saveas(fig, 'PSTH_neg.pdf','pdf')
print -depsc -tiff -r300 -painters avgPSTHforPoster.eps
%% PSTH by Layer

layers = {'Layer 5/6', 'Layer 4c', 'Layer 4b', 'Layer 2/3', 'WM'};
layerColors = {'m', 'b','g','r', 'k'};
for layerID = [1 2 3 4]
    figure
    bigPSTH = [];
    for clusterID= [1 2 3 4 5 6 7 8 9]% 3 4 5 9]
        
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
        if size(concatPSTH,1) > 8
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
            concatPSTH = [concatPSTH; NaN(1,549)];
        end
    end
    PSTH_mean = nanmean(bigPSTH);
    PSTH_sem = nanstd(bigPSTH)./sqrt(size(bigPSTH,1));
    figure(6);
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
