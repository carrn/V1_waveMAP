load('allWaveforms.mat')
load('AmpPerCluster.mat')
load('clusterFnData042925.mat')
%%

session = clusterFnData(:,4);
cluster = clusterFnData(:,15);
ID = clusterFnData(:,3);
vis_resp = clusterFnData(:,12);
vResp = clusterFnData(:,12);
clusterFnData = clusterFnData(find(vResp), :);
clusterFn = clusterFnData(:,15);
depth_scaled = clusterFnData(:,16);

for sessionID = 1:max(session)
    sessionI = clusterFnData(:,4) == sessionID;
    for clusterID = 1:max(cluster)
        allWaveforms(sessionID).clusters(clusterID).ID = ID(sessionI & cluster ==clusterID);
        allWaveforms(sessionID).clusters(clusterID).vis_resp = vis_resp(sessionI & cluster ==clusterID);
        
    end
end

%% laminar depth
avgLayerBounds = [ -488 -990; 0 -488; 285.4 0; 588.8 285.4; 1039.4 588.8];
cluster_colors
t = [0:0.03333:1.73];
for sessionID = 1:max(session)
    sessionI = clusterFnData(:,4) ==sessionID;
    for clusterID = 1:max(cluster)
        allWaveforms(sessionID).clusters(clusterID).depth = extractarray(allWaveforms(sessionID).waveform.ID_all(:,1),allWaveforms(sessionID).clusters(clusterID).ID,allWaveforms(sessionID).waveform.depth_all);
        allWaveforms(sessionID).clusters(clusterID).depth_scaled = extractarray(allWaveforms(sessionID).avg_waveformID,allWaveforms(sessionID).clusters(clusterID).ID,allWaveforms(sessionID).scaled_depth);
        allWaveforms(sessionID).clusters(clusterID).layerID = extractarray(allWaveforms(sessionID).avg_waveformID,allWaveforms(sessionID).clusters(clusterID).ID,allWaveforms(sessionID).layerId);
        allWaveforms(sessionID).clusters(clusterID).snr = extractarray(allWaveforms(sessionID).avg_waveformID,allWaveforms(sessionID).clusters(clusterID).ID,allWaveforms(sessionID).snr);

    end
end

%% Generate ISI
alpha = 0.2;
avgISI = [];
errorISI = [];
concatSpikeTimes = {};
figure
bigK = [];
bigCluster = [];
for clusterID = [1 2 6 8 7 3 4 5 9]
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
        cluster_ID = allWaveforms(sessionID).clusters(clusterID).ID;
        D = [0:0.0004:0.025];
        
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
       
    end
    
    concatSpikeTimes{clusterID} = ISIdensity;
    avgISI(clusterID,:) = nanmean(ISIdensity);
    errorISI(clusterID,:) = nanstd(ISIdensity)./sqrt(cnt);
    
    kurt{clusterID} = kurtosis(ISIdensity,1,2);
    skew{clusterID} = skewness(ISIdensity,1,2);
    fig = figure(2);
    shaded_errorbar(D(1:end-1), avgISI(clusterID,:),errorISI(clusterID,:),colors{clusterID},alpha)
    
    bigK = [bigK; kurt{clusterID} skew{clusterID} clusterID*ones(size(kurt{clusterID},1),1)];
    
end
xlabel('Bin Size [s]')
ylabel('Spike Probability')
title('avg ISI Density')


