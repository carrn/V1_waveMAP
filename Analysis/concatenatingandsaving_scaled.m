ID_all = [];
ID_pos = [];
ID_neg = [];
align_all = [];
align_pos = [];
align_neg = [];
depth_all = [];
depth_pos = [];
depth_neg = [];
depth_all_scaled = [];
depth_pos_scaled = [];
depth_neg_scaled = [];


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
%%
depth_neg_scaled = [depth_neg_scaled; allWaveforms(sessionID).waveform.depth_neg_scaled];
depth_pos_scaled = [depth_pos_scaled; allWaveforms(sessionID).waveform.depth_pos_scaled];
depth_all_scaled = [depth_all_scaled; allWaveforms(sessionID).waveform.depth_all_scaled];

end

%% Saving for Wavemap Input
save('wavemap_input/normalizednegwaveforms6.mat','align_neg');
save('wavemap_input/normalizedposwaveforms6.mat','align_pos');
save('wavemap_input/normalizedwaveforms6.mat','align_all');

save('wavemap_input/depth_neg6.mat','depth_neg');
save('wavemap_input/depth_pos6.mat','depth_pos');
save('wavemap_input/depth6.mat','depth_all');

save('wavemap_input/ID_neg6.mat', 'ID_neg', 'sessionID');
save('wavemap_input/ID_pos6.mat', 'ID_pos', 'sessionID');
save('wavemap_input/ID6.mat', 'ID_all', 'sessionID');

save('wavemap_input/depth_neg_scaled6.mat','depth_neg_scaled');
save('wavemap_input/depth_pos_scaled6.mat','depth_pos_scaled');
save('wavemap_input/depth_scaled6.mat','depth_all_scaled');

% %% Saving manual sort
% manualsort = cat(1,allWaveforms(1:p).avg_waveform);
% manualsortID = cat(1,allWaveforms(1:p).avg_waveformID);
% 21.091
% 8.091
% save('manualsort_allSessions.mat','manualsort')
% save('manualsortID_allSessions.mat','manualsortID')
%keyboard
%% Saving for ISI output

%allWaveforms_clusters = struct('cluster', {allWaveforms(1:5).clusters});
%allWaveforms_clusters = allWaveforms(2).clusters;

%save('allWaveforms_clusters.mat','allWaveforms_clusters');




