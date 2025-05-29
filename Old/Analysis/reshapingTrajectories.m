maxsession = 5;
figure;
for sessionID = 1:maxsession
    numUnits = size(allWaveforms(sessionID).templateID,1);
    reshapedTraj = [];
    for unitID = 1:numUnits
        trajectory = allWaveforms(sessionID).trajectory;
        numChannels = size(trajectory,1);
        b = allWaveforms(sessionID).trajectory;
        B = squeeze(b(1:2:numChannels,:,unitID)); 
        BoB = reshape(B',1,[]);

        BoBby = reshape_traj(B);
        BoBy = reshape(BoBby',1,[]);
        hold on
        plot(BoBy)
        reshapedTraj = [reshapedTraj; BoBy];
        %figure;
        %imagesc(B)
    end
    
    normTraj = bsxfun(@rdivide,reshapedTraj',max(abs(reshapedTraj')));
    allWaveforms(sessionID).reshapedTraj = reshapedTraj;
    allWaveforms(sessionID).normTraj = normTraj';
end
%% Concatenating
ID_all = [];

align_all = [];

depth_all = [];

norm_all = [];

%%
for sessionID = 1:maxsession
    
align_all = [align_all; allWaveforms(sessionID).reshapedTraj];

depth_all = [depth_all; allWaveforms(sessionID).depth];

ID_all = [ID_all; [allWaveforms(sessionID).templateID, ones(size(allWaveforms(sessionID).templateID))*sessionID]];

norm_all = [norm_all; allWaveforms(sessionID).normTraj];

end
%% matching clean units
a = ~isnan(align_all);
align_= align_all(a);
align_all = reshape(align_,[],572);

depth_all = depth_all(a(:,1));

ID_ = ID_all(a(:,1:2));
ID_all = reshape(ID_,[],2);

norm_ = norm_all(a);
norm_all = reshape(norm_,[],572);

%%

for sessionID = 1:maxsession
    sessionIDs = ID_all(ID_all(:,2)==sessionID);
    
    [align_all, IDs, H, hh] = extractarray(allWaveforms(sessionID).avg_waveformID, allWaveforms(sessionID).waveform.ID_all, allWaveforms(sessionID).reshapedTraj);
    [depth_all, IDs, H, hh] = extractarray(allWaveforms(sessionID).avg_waveformID, allWaveforms(sessionID).waveform.ID_all, allWaveforms(sessionID).depth);
    [depth_scaled, IDs, H, hh] = extractarray(allWaveforms(sessionID).avg_waveformID, allWaveforms(sessionID).waveform.ID_all, allWaveforms(sessionID).scaled_depth);

    allWaveforms(sessionID).traj.ID_all = IDs;
    allWaveforms(sessionID).traj.align_all = align_all;
    allWaveforms(sessionID).traj.depth = depth_all;
    allWaveforms(sessionID).traj.depth_scaled = depth_scaled;


end

%%
ID_all = [];

align_all = [];

depth_all = [];

depth_scaled = [];
for sessionID = 1:maxsession
    
align_all = [align_all; allWaveforms(sessionID).traj.align_all];

depth_all = [depth_all; allWaveforms(sessionID).traj.depth];

ID_all = [ID_all; [allWaveforms(sessionID).traj.ID_all]];

depth_scaled = [depth_scaled; allWaveforms(sessionID).traj.depth_scaled];

end
%% clearing NANs
a = ~isnan(align_all);
align_= align_all(a);
align_all = reshape(align_,[],572);

depth_all = depth_all(a(:,1));

depth_scaled = depth_scaled(a(:,1));

ID_ = ID_all(a(:,1:2));
ID_all = reshape(ID_,[],2);

norm_ = norm_all(a);
norm_all = reshape(norm_,[],572);
 %% Saving for Wavemap Input

%save('wavemap_Traj_input/alignedwaveforms.mat','align_all');
%
%save('wavemap_Traj_input/depth.mat','depth_all');
% 
%save('wavemap_Traj_input/ID.mat', 'ID_all', 'sessionID');
 
%save('wavemap_Traj_input/depth_scaled.mat','depth_scaled');


% save('wavemap_Traj_input/depth_scaled.mat','depth');
% 
% % %% Saving manual sort
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
