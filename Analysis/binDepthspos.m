
poscombinedLayer = [];
combinedCluster = [];



for sessionID = 1:5
    
    originalIDs = allWaveforms(sessionID).avg_waveformID;
    desiredIDs = allWaveforms(sessionID).waveform.ID_pos(:,1);
    originalarray = allWaveforms(sessionID).layerId;
    
    
    depthBin = extractarray(originalIDs, desiredIDs, originalarray);
    depthBin(isnan(depthBin))=6;
    allWaveforms(sessionID).waveform.depthBin = depthBin;
    
    for clusterID = 1:5
        originalIDs = allWaveforms(sessionID).waveform.ID_pos(:,1);
        desiredIDs = allWaveforms(sessionID).posclusters(clusterID).ID(:,1);
        originalarray = allWaveforms(sessionID).waveform.depthBin;
        
        depthBinCluster  = extractarray(originalIDs, desiredIDs, originalarray);
        allWaveforms(sessionID).posclusters(clusterID).depthBinCluster = depthBinCluster;
        poscombinedLayer = [poscombinedLayer; depthBinCluster];
    end
end


[table,chi2,p] = crosstab(poscluster,poscombinedLayer)

