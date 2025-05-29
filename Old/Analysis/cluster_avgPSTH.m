%clc;        % Clear Command Window
%close all;  % Close all figures
%clear all;  % Erase all existing variables
workspace;  % Make sure the workspace panel is showing
% This program requires:
% - folder containing data structures
% - function psth()

A = readmatrix('/wavemap_output/cluster_data.csv');
%Clusters = struct
session = A(:,4);
%cluster = A(:,1)+1; % 2.5 res
cluster = A(:,5)+1;
ID = A(:,3);

for sessionID = 1:max(session)
    sessionI = A(:,4) ==sessionID;
    for clusterID = 1:max(cluster)
        allWaveforms(sessionID).clusters(clusterID).ID = ID(sessionI & cluster ==clusterID);
        
    end
end

%% Shortcut


A = readmatrix('/cluster_data_final.csv');
%Clusters = struct
session = A(:,4);
%cluster = A(:,1)+1; % 2.5 res
cluster = A(:,15)+1;
ID = A(:,3);
vis_resp = A(:,12);
depth_bins = A(:,21);

for sessionID = 1:max(session)
    sessionI = A(:,4) ==sessionID;
    for clusterID = 1:max(cluster)
        allWaveforms(sessionID).clusters(clusterID).ID = ID(sessionI & cluster ==clusterID);
        allWaveforms(sessionID).clusters(clusterID).depth_bins = depth_bins(sessionI & cluster ==clusterID);
        allWaveforms(sessionID).clusters(clusterID).vis_resp = vis_resp(sessionI & cluster ==clusterID);
    end
end
%% Waveforms
for sessionID = 1:max(session)
    sessionI = A(:,4) ==sessionID;
    for clusterID = 1:max(cluster)
        allWaveforms(sessionID).clusters(clusterID).waveform = extractarray(allWaveforms(sessionID).waveform.ID_all(:,1),allWaveforms(sessionID).clusters(clusterID).ID,allWaveforms(sessionID).waveform.align_all);
        %figure
        %plot(allWaveforms(sessionID).clusters(clusterID).waveform')
    end

end

%% laminar depth
avgLayerBounds = [ -488 -990; 0 -488; 285.4 0; 588.8 285.4; 1039.4 588.8];
for sessionID = 1:max(session)
    sessionI = A(:,4) ==sessionID;
    for clusterID = 1:max(cluster)
        allWaveforms(sessionID).clusters(clusterID).depth = extractarray(allWaveforms(sessionID).waveform.ID_all(:,1),allWaveforms(sessionID).clusters(clusterID).ID,allWaveforms(sessionID).waveform.depth_all);
        allWaveforms(sessionID).clusters(clusterID).depth_scaled = extractarray(allWaveforms(sessionID).avg_waveformID,allWaveforms(sessionID).clusters(clusterID).ID,allWaveforms(sessionID).scaled_depth);
        allWaveforms(sessionID).clusters(clusterID).layerID = extractarray(allWaveforms(sessionID).avg_waveformID,allWaveforms(sessionID).clusters(clusterID).ID,allWaveforms(sessionID).layerId);
        %figure
        %plot(allWaveforms(sessionID).clusters(clusterID).waveform')
    end
end

%% pos spiking clusters

% 
% A = readmatrix('/wavemap_output/poscluster_data.csv');
% %Clusters = struct  
% session = A(:,4);
% poscluster = A(:,1)+1;
% ID = A(:,3);
% 
% for sessionID = 1:max(session)
%     sessionI = A(:,4) ==sessionID;
%     for clusterID = 1:max(poscluster)
%         allWaveforms(sessionID).posclusters(clusterID).ID = ID(sessionI & poscluster ==clusterID);
%     end
% end
% 
