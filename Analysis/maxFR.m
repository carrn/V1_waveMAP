

maximumFR = [];
combinedFR = [];

for sessionID = 1:5
    
    originalIDs = allWaveforms(sessionID).avg_waveformID;
    desiredIDs = allWaveforms(sessionID).waveform.ID_neg(:,1);
    originalarray = allWaveforms(sessionID).layerId;
    
    
    depthBin = extractarray(originalIDs, desiredIDs, originalarray);
    depthBin(isnan(depthBin))=6;
    allWaveforms(sessionID).waveform.depthBin = depthBin;
    
    for clusterID = 1:5
        originalIDs = allWaveforms(sessionID).waveform.ID_pos(:,1);
        desiredIDs = allWaveforms(sessionID).clusters(clusterID).ID(:,1);
        originalarray = allWaveforms(sessionID).waveform.depthBin;
        
        depthBinCluster  = extractarray(originalIDs, desiredIDs, originalarray);
        allWaveforms(sessionID).clusters(clusterID).depthBinCluster = depthBinCluster;
        combinedLayer = [combinedLayer; depthBinCluster];
        
        maximumFR = max(allWaveforms(sessionID).clusters(clusterID).avgPSTH,[],2);
        combinedFR = [combinedFR; maximumFR];
        combinedCluster = [combinedCluster; ones(size(maximumFR))*clusterID];
    end
end

%%

[table,chi2,p] = crosstab(combinedCluster,combinedLayer)
p = kruskalwallis(combinedCluster,combinedLayer, 'off')
