allAmps = [];
allTP = [];
alldepth_bin = [];
allRepWidth = [];

for sessionID = 1:5
        
    size(allWaveforms(sessionID).waveform.ID_neg)
    [ampp, ampIDs, ~, ~] = extractarray(allWaveforms(sessionID).avg_waveformID, allWaveforms(sessionID).waveform.ID_neg(:,1), allWaveforms(sessionID).amp);
    allAmps = [allAmps; ampp];
    
    [tp_dur, tpIDs, ~, ~] = extractarray(allWaveforms(sessionID).avg_waveformID, allWaveforms(sessionID).waveform.ID_neg(:,1), allWaveforms(sessionID).tp_dur);
    allTP = [allTP; tp_dur];
    
    [depth_bin, depth_binIDs, ~, ~] = extractarray(allWaveforms(sessionID).avg_waveformID, allWaveforms(sessionID).waveform.ID_neg(:,1), allWaveforms(sessionID).layerId);
    alldepth_bin = [alldepth_bin; depth_bin];

    [repWidth, repWidthIDs, ~, ~] = extractarray(allWaveforms(sessionID).avg_waveformID, allWaveforms(sessionID).waveform.ID_neg(:,1), allWaveforms(sessionID).repWidth);
    allRepWidth = [allRepWidth; repWidth];
end