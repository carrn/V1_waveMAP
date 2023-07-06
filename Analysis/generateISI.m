%colors = {'b',[0.8 0.4 0.1],[0.2 0.8 0.2],[0.6 0 0],'y';};
%colors = {[0.2 0.8 0.2],[0.8 0.4 0.1],'b',[0.6 0 0];};
%colors = {[0 0.3 0.6],[1 0.5 0.2],[0.6 0 0],[0.7 0.5 0],[0 0.7 0.6];}; %res 2.5
colors = clusterColors;
alpha = 0.2;
avgISI = [];
errorISI = [];
concatSpikeTimes = {};
figure
for clusterID =1:max(cluster)
    cnt = 1;
    ISIvalues = [];
    ISIdensity = [];
    for sessionID = 1:5
        sessISIvalues = [];
        sessISIdensity = [];
        cluster_ID = allWaveforms(sessionID).clusters(clusterID).ID;
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
        
        allWaveforms(sessionID).clusters(clusterID).ISIvalues = sessISIvalues;
        allWaveforms(sessionID).clusters(clusterID).ISIdensity = sessISIdensity;
    end
    
    concatSpikeTimes{clusterID} = ISIdensity;
    avgISI(clusterID,:) = nanmean(ISIdensity);
    errorISI(clusterID,:) = nanstd(ISIdensity)./sqrt(cnt);
    fig = figure(2);
    shaded_errorbar(D(1:end-1), avgISI(clusterID,:),errorISI(clusterID,:),colors{clusterID},alpha)
    
    %errorbar(D(1:end-1), avgISI(cluster_num,:), errorISI(cluster_num,:), 'color',colors{cluster_num});
    
end
xlabel('Bin Size [s]')
ylabel('Spike Probability')
title('avg ISI Density')
%saveas(fig, 'ISI_neg.pdf','pdf')
%%
%xline([0])
set(gca,'box','off','TickDir','out') 
print -depsc -tiff -r300 -painters avgISIforPoster.eps



%keyboard