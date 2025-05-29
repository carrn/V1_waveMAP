%colors = {'b',[0.8 0.4 0.1],[0.2 0.8 0.2],[0.6 0 0],'y';};
%colors = {[0.2 0.8 0.2],[0.8 0.4 0.1],'b',[0.6 0 0];};
colors = {[0.8549    0.9098    0.9608],[0.7294    0.8392    0.9176],[0.5333    0.7451    0.8627],[0.3255    0.6157    0.8000],[0.1647    0.4784    0.7255];};
alpha = 0.2;
lines = {'-','--','-.',':','-'};
linew = {3 , 1, 1 ,1, 1};

avgISI = [];
errorISI = [];
concatSpikeTimes = {};

for clusterID = 1:5
        cnt = 1;
        ISIvalues = [];
        ISIdensity = [];
    for sessionID = 1:5
        sessISIvalues = [];
        sessISIdensity = [];
        cluster_ID = allWaveforms(sessionID).posclusters(clusterID).ID;
        D = [0:0.0004:0.02];
        for unitID = 1:size(cluster_ID)
            
            allSpikeTimes = allWaveforms(sessionID).spike_timing(allWaveforms(sessionID).spike_ID==[cluster_ID(unitID)]);
            stimTimes = allWaveforms(sessionID).stim_on;
            
            figure(1);
            xlabel('Bin Size [s]')
            ylabel('Spike Probability')
            h = histogram(diff(allSpikeTimes),D,'Normalization','probability');
            ISIdensity(cnt,:) = h.Values;
            ISIvalues = [ISIvalues diff(allSpikeTimes)'];
            sessISIdensity(unitID,:) = h.Values;
            sessISIvalues = [sessISIvalues diff(allSpikeTimes')];
            cnt = cnt + 1;
            hold off;
        end
        
        allWaveforms(sessionID).posclusters(clusterID).ISIvalues = sessISIvalues;
        allWaveforms(sessionID).posclusters(clusterID).ISIdensity = sessISIdensity;
    end
    
    concatSpikeTimes{clusterID} = ISIdensity;
    avgISI(clusterID,:) = nanmean(ISIdensity);
    errorISI(clusterID,:) = nanstd(ISIdensity)./sqrt(cnt);
    fig = figure(2);
    shaded_errorbar(D(1:end-1), avgISI(clusterID,:),errorISI(clusterID,:),colors{clusterID},alpha,lines{clusterID},linew{clusterID})

    %errorbar(D(1:end-1), avgISI(cluster_num,:), errorISI(cluster_num,:), 'color',colors{cluster_num});

end
xlabel('Bin Size [s]')
ylabel('Spike Probability')
title('avg ISI Density')

%%

%% Saving
% set(gcf,'renderer','Painters')
%xline([0])
set(gca,'box','off') 
print -depsc -tiff -r300 -painters avgISIposforPoster.eps


%saveas(fig, 'ISI_pos.pdf','pdf')


%keyboard