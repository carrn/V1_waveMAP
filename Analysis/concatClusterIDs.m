
concatIDs = [];

for sessionID = 1:5
    
    for clusterID= 1:9
        currIDs = allWaveforms(sessionID).clusters(clusterID).ID;
        concatIDs = [concatIDs; currIDs];
        
    end
    
end

%%

concatPSTH = [];

for sessionID = 1:5
    
    for clusterID= 1:9
        currPSTH = allWaveforms(sessionID).clusters(clusterID).avgPSTH;
        concatPSTH = [concatPSTH; currPSTH];
        
    end
    
end


%%
concatISI = [];

for sessionID = 1:5
    
    for clusterID= 1:9
        currISI = allWaveforms(sessionID).clusters(clusterID).ISIdensity;
        concatISI = [concatISI; currISI];
        
    end
    
end


%%

concatLatency = [];

for sessionID = 1:5
    
    for clusterID= 1:9
        currLatency = allWaveforms(sessionID).clusters(clusterID).ISIdensity;
        concatLatency = [concatLatency ; currLatency];
        
    end
    
end

%%
concatWaveform = [];

for sessionID = 1:5
    
    for clusterID= 1:9
        
        currWaveform = allWaveforms(sessionID).clusters(clusterID).ISIdensity;
        concatwaveform = [concatwaveform ; currWaveform];
        
    end
    
end


