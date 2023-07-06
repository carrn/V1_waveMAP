
negcombinedLayer = [];
combinedCluster = [];



for sessionID = 1:5
    
    originalIDs = allWaveforms(sessionID).avg_waveformID;
    desiredIDs = allWaveforms(sessionID).waveform.ID_neg(:,1);
    originalarray = allWaveforms(sessionID).layerId;
    
    
    depthBin = extractarray(originalIDs, desiredIDs, originalarray);
    depthBin(isnan(depthBin))=6;
    allWaveforms(sessionID).waveform.depthBin = depthBin;
    
    for clusterID = 1:max(cluster)
        originalIDs = allWaveforms(sessionID).waveform.ID_neg(:,1);
        desiredIDs = allWaveforms(sessionID).clusters(clusterID).ID(:,1);
        originalarray = allWaveforms(sessionID).waveform.depthBin;
        
        depthBinCluster  = extractarray(originalIDs, desiredIDs, originalarray);
        allWaveforms(sessionID).clusters(clusterID).depthBinCluster = depthBinCluster;
        negcombinedLayer = [negcombinedLayer; depthBinCluster];
    end
end


[table,chi2,p] = crosstab(cluster,negcombinedLayer)

%%
% depthBinperCluster = [];
% depthperCluster = [];
% for clusterID = 1:9
%     
%     for sessionID = 1:5
% 
%         nsDepthBins = allWaveforms(sessionID).clusters(clusterID).depthBinCluster;
%         nsDepth_scaled = allWaveforms(sessionID).clusters(clusterID).depth_scaled;
%         depthBinperCluster = [depthBinperCluster; nsDepthBins];
%         depthperCluster = [depthperCluster; nsDepth_scaled];
%         
%     end
%     
% end
% %%




