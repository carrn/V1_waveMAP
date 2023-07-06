%% time window

t = [-50:1050];
tIdx = [t > -50 & t < 750];


%% pos PSTHs


fig = figure;
% colors = {'b',[0.8 0.4 0.1],[0.2 0.8 0.2],[0.6 0 0],'y';};
%colors = {[0.2 0.8 0.2],[0.8 0.4 0.1],'b',[0.6 0 0];};
colors = {[0.8549    0.9098    0.9608],[0.7294    0.8392    0.9176],[0.5333    0.7451    0.8627],[0.3255    0.6157    0.8000],[0.1647    0.4784    0.7255];};
alpha = 0.2;
lines = {'-','--','-.',':','-'};
linew = {3 , 1, 1 ,1, 1};
bigPSTH = [];
ids = [];
for clusterID=1:5
    concatPSTH = [];
    cnt = 1;
    for sessionID = 1:5

        currSessPSTH = allWaveforms(sessionID).posclusters(clusterID).psthPerCondition;
        try
            meanOverTime = nanmean(currSessPSTH(:,:,200:800),3);
        catch
            meanOverTime = [];
        end
        
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
    plot(tNew, PSTH_mean, 'color', colors{clusterID},'Linestyle', lines{clusterID},'LineWidth',linew{clusterID});
    hold on
    PSTH_sem = nanstd(concatPSTH)./sqrt(size(concatPSTH,1));
   
    patch = fill([tNew fliplr(tNew)] , [PSTH_mean+PSTH_sem fliplr(PSTH_mean-PSTH_sem)], colors{clusterID});
    set(patch, 'edgecolor', 'none','FaceAlpha', alpha );
    hold on
    ids = [ids clusterID*ones(1, size(concatPSTH,1))];
    bigPSTH = [bigPSTH; concatPSTH];
    
end
title('avg PSTH per preferred orientation')
xlabel('Time [ms]')
ylabel('Firing Rate')


%% Saving
% set(gcf,'renderer','Painters')
xline([0])
set(gca,'box','off') 
print -depsc -tiff -r300 -painters avgPSTHposforPoster.eps


%saveas(fig, 'PSTH_pos.pdf','pdf')



%% All PSTHs


bigPSTH = bigPSTH';
bigPSTH = bigPSTH./repmat(max(bigPSTH),[size(bigPSTH,1) 1]);
[coeff, score, varExplained] = pca(bigPSTH);

figure;
for clusterID = 1:4
    plot(coeff(ids==clusterID,1), coeff(ids==clusterID,2),'o','color',colors{clusterID});
    hold on
end


