%colors = {'b',[0.8 0.4 0.1],[0.2 0.8 0.2],[0.6 0 0],'y';};
%colors = {[0.2 0.8 0.2],[0.8 0.4 0.1],'b',[0.6 0 0];};
%colors = {[0 0.3 0.6],[1 0.5 0.2],[0.6 0 0],[0.7 0.5 0],[0 0.7 0.6];}; %res 2.5
colors = clusterColors;
alpha = 0.2;
avgISI = [];
errorISI = [];
concatSpikeTimes = {};
figure
bigK = [];
bigCluster = [];
for clusterID = [1 2 6 8 7 3 4 5 9]%1:max(cluster)
    cnt = 1;
    ISIvalues = [];
    ISIdensity = [];
    layerIdvalues = [];
    CV = [];
    for sessionID = 1:5
        sessISIvalues = [];
        sessISIdensity = [];
        varISI = [];
        meanISI = [];
        %cluster_ID = allWaveforms(sessionID).clusters(clusterID).ID(allWaveforms(sessionID).clusters(clusterID).vis_resp ==1);
        cluster_ID = allWaveforms(sessionID).clusters(clusterID).ID;
        D = [0:0.0004:0.025];
        % D = logspace(-3,-1,30);
        for unitID = 1:size(cluster_ID)
            
            allSpikeTimes = allWaveforms(sessionID).spike_timing(allWaveforms(sessionID).spike_ID==[cluster_ID(unitID)]);
            stimTimes = allWaveforms(sessionID).stim_on;
            
            figure(1);
            xlabel('Bin Size (s)') 
            ylabel('Spike Probability')
            h = histogram(diff(allSpikeTimes),D,'Normalization','probability');
            
            
            ISIdensity(cnt,:) = h.Values;
            ISIvalues = [ISIvalues diff(allSpikeTimes)'];
            varISI(unitID,:) = nanstd(diff(allSpikeTimes));
            meanISI(unitID,:) = nanmean(diff(allSpikeTimes));
            sessISIdensity(unitID,:) = h.Values;
            sessISIvalues = [sessISIvalues diff(allSpikeTimes')];
            cnt = cnt + 1;
            hold off;
        end
        bigCluster = [bigCluster ; cluster_ID , sessionID*ones(size(cluster_ID))];
        allWaveforms(sessionID).clusters(clusterID).ISIvalues = sessISIvalues;
        allWaveforms(sessionID).clusters(clusterID).ISIdensity = sessISIdensity;
        allWaveforms(sessionID).clusters(clusterID).kurt = kurtosis(sessISIdensity,1,2);
        allWaveforms(sessionID).clusters(clusterID).varISI = varISI;
        allWaveforms(sessionID).clusters(clusterID).meanISI = meanISI;
        allWaveforms(sessionID).clusters(clusterID).CV = varISI./meanISI;
        %CV = [CV varISI./meanISI];
    end
    
    concatSpikeTimes{clusterID} = ISIdensity;
    avgISI(clusterID,:) = nanmean(ISIdensity);
    errorISI(clusterID,:) = nanstd(ISIdensity)./sqrt(cnt);
    
    kurt{clusterID} = kurtosis(ISIdensity,1,2);
    skew{clusterID} = skewness(ISIdensity,1,2);
    fig = figure(2);
    shaded_errorbar(D(1:end-1), avgISI(clusterID,:),errorISI(clusterID,:),colors{clusterID},alpha)
    
    bigK = [bigK; kurt{clusterID} skew{clusterID} clusterID*ones(size(kurt{clusterID},1),1)];
    
    %errorbar(D(1:end-1), avgISI(cluster_num,:), errorISI(cluster_num,:), 'color',colors{cluster_num});
    
end
xlabel('Bin Size [s]')
ylabel('Spike Probability')
title('avg ISI Density')
%saveas(fig, 'ISI_neg.pdf','pdf')
%% single unit examples
figure
for clusterID = 4
    for sessionID = 2
        cluster_ID = allWaveforms(sessionID).clusters(clusterID).ID;
        for unitID = 8
            
            allSpikeTimes = allWaveforms(sessionID).spike_timing(allWaveforms(sessionID).spike_ID==[cluster_ID(unitID)]);
            stimTimes = allWaveforms(sessionID).stim_on;
            
            xlabel('Bin Size (s)') 
            ylabel('Spike Probability')
            h = histogram(diff(allSpikeTimes),D,'Normalization','probability');
        end
    end
end
title(sprintf(['Cluster ',num2str(clusterID),' Session ',num2str(sessionID),' Unit ',num2str(cluster_ID(unitID))])) 
%caxis([-60 60])
set(gca,'box','off','TickDir','out')
set(gca,'YDir','normal')



%% Per layer
%colors = {'b',[0.8 0.4 0.1],[0.2 0.8 0.2],[0.6 0 0],'y';};
%colors = {[0.2 0.8 0.2],[0.8 0.4 0.1],'b',[0.6 0 0];};
%colors = {[0 0.3 0.6],[1 0.5 0.2],[0.6 0 0],[0.7 0.5 0],[0 0.7 0.6];}; %res 2.5
colors = clusterColors;
alpha = 0.2;
avgISI = [];
errorISI = [];
concatSpikeTimes = {};
k_values = [];
k_V = [];


%D = [0:0.0004:0.015];
iX = [1 6 8 2 7 3 9 5 4];
for layerID =1
    figure
    bigISI = [];
    % ISIdensity = [];
    for clusterID = [ 3 4 5 9]
        cnt = 0;
        ISIdensity = [];
        for sessionID = 1:5
            cluster_ID = allWaveforms(sessionID).clusters(clusterID).layerID==layerID & allWaveforms(sessionID).clusters(clusterID).vis_resp ==1;
            ISIdensity = [ISIdensity; allWaveforms(sessionID).clusters(clusterID).ISIdensity(cluster_ID,:)];
            cnt = cnt+sum(cluster_ID);
        end
        
        concatSpikeTimes{clusterID} = ISIdensity;
        avgISI(clusterID,:) = nanmean(ISIdensity);
        errorISI(clusterID,:) = nanstd(ISIdensity)./sqrt(cnt);
        
        kurt{layerID,clusterID} = kurtosis(ISIdensity,1,2);
        if size(ISIdensity,1)>9
            %fig = figure(2);
            shaded_errorbar(D(1:end-1), avgISI(clusterID,:),errorISI(clusterID,:),colors{clusterID},alpha)
            k_values(layerID,clusterID) = kurtosis(avgISI(clusterID,:));
            k_V(layerID,find(iX==clusterID)) = nanmean(kurt{layerID,clusterID});
            % ylim([0 0.12])
            title(sprintf(['Layer ',num2str(layerID)]))
            % colorbar
        else
            %
        end
    end
    
end
xlabel('Bin Size (s)')
ylabel('Spike Probability')
%title('avg ISI Density')
%saveas(fig, 'ISI_neg.pdf','pdf')
