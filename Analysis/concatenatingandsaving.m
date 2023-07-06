ID_all = [];
ID_pos = [];
ID_neg = [];
align_all = [];
align_pos = [];
align_neg = [];
depth_all = [];
depth_pos = [];
depth_neg = [];

%% concatenating
for sessionID = 1:maxsession
    
align_neg = [align_neg; allWaveforms(sessionID).waveform.align_neg]; 
align_pos = [align_pos; allWaveforms(sessionID).waveform.align_pos]; 
align_all = [align_all; allWaveforms(sessionID).waveform.align_all];

depth_neg = [depth_neg; allWaveforms(sessionID).waveform.depth_neg];
depth_pos = [depth_pos; allWaveforms(sessionID).waveform.depth_pos];
depth_all = [depth_all; allWaveforms(sessionID).waveform.depth_all];

ID_neg = [ID_neg; allWaveforms(sessionID).waveform.ID_neg];
ID_pos = [ID_pos; allWaveforms(sessionID).waveform.ID_pos];
ID_all = [ID_all; allWaveforms(sessionID).waveform.ID_all];

end

%% Saving for Wavemap Input
save('wavemap_input/normalizednegwaveforms5.mat','align_neg');
save('wavemap_input/normalizedposwaveforms5.mat','align_pos');
save('wavemap_input/normalizedwaveforms5.mat','align_all');

save('wavemap_input/depth_neg5.mat','depth_neg');
save('wavemap_input/depth_pos5.mat','depth_pos');
save('wavemap_input/depth5.mat','depth_all');

save('wavemap_input/ID_neg5.mat', 'ID_neg', 'sessionID');
save('wavemap_input/ID_pos5.mat', 'ID_pos', 'sessionID');
save('wavemap_input/ID5.mat', 'ID_all', 'sessionID');

% %% Saving manual sort
% manualsort = cat(1,allWaveforms(1:p).avg_waveform);
% manualsortID = cat(1,allWaveforms(1:p).avg_waveformID);
% 
% save('manualsort_allSessions.mat','manualsort')
% save('manualsortID_allSessions.mat','manualsortID')
keyboard
%% Saving for ISI output

%allWaveforms_clusters = struct('cluster', {allWaveforms(1:5).clusters});
%allWaveforms_clusters = allWaveforms(2).clusters;

%save('allWaveforms_clusters.mat','allWaveforms_clusters');




