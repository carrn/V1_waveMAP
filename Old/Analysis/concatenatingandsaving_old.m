% Concatenating raw waveforms for Kenji

ID_all = [];

align_all = [];

depth_all = [];

depth_scaled = [];
%%

for sessionID = 1:maxsession
    
align_all = [align_all; allWaveforms(sessionID).avg_waveform];

depth_all = [depth_all; allWaveforms(sessionID).depth];

ID_all = [ID_all; allWaveforms(sessionID).avg_waveformID];
    
depth_scaled = [depth_scaled; allWaveforms(sessionID).scaled_depth];

end

 %% Saving for Wavemap Input

save('wavemap_old_input/alignedwaveforms.mat','align_all');
% 

save('wavemap_old_input/depth.mat','depth_all');
% 

save('wavemap_old_input/ID.mat', 'ID_all', 'sessionID');
 
 
save('wavemap_old_input/depth_scaled.mat','depth_scaled');