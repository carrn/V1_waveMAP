truthTable = [];
for sessionID = 1:5
    truthRow = [];
    for clusterID = 1:6
        
        a = size(allWaveforms(sessionID).clusters(clusterID).ID,1);
        truthRow = [truthRow , a];

    end
    truthTable = [truthTable ; truthRow];
end
%     originalarray = [];
%     originalIDs = [];
%     desiredIDs = [];
%     desiredarray = [];
%     desiredIDsreal =[];
% 
% 
% sessionID = 1;
%     originalarray = allWaveforms(sessionID).depth;
%     originalIDs = allWaveforms(sessionID).avg_waveformID;
%     desiredIDs = allWaveforms(sessionID).waveform.ID_pos(:,1);
%     [desiredarray, desiredIDsreal] = extractarray(originalIDs, desiredIDs, originalarray);
%     
%     
    
    
%     [matchingunits_pos, ~] = extractarray(allWaveforms(sessionID).snrsort.ID_pos, allWaveforms(sessionID).manual.ID_pos);
%     [matchingunits_neg, ~] = eatractarray(allWaveforms(sessionID).snrsort.ID_neg, allWaveforms(sessionID).manual.ID_neg);
% 
%     
    
%     allWaveforms(sessionID).waveform.depth_all = allWaveforms(sessionID).snrsort.ID_all(matchingunits_all,:);
%     allWaveforms(sessionID).waveform.align_all = allWaveforms(sessionID).snrsort.align_all(matchingunits_all,:);
%     allWaveforms(sessionID).waveform.ID_pos = allWaveforms(sessionID).snrsort.ID_pos(matchingunits_pos,:);
%     allWaveforms(sessionID).waveform.align_pos = allWaveforms(sessionID).snrsort.align_pos(matchingunits_pos,:);
%     allWaveforms(sessionID).waveform.ID_neg = allWaveforms(sessionID).snrsort.ID_neg(matchingunits_neg,:);
%     allWaveforms(sessionID).waveform.align_neg = allWaveforms(sessionID).snrsort.align_neg(matchingunits_neg,:);
% %     
%end