load('allWaveforms.mat')
load('AmpPerCluster.mat')
%%

A = readmatrix('/cluster_data_final.csv');
%Clusters = struct
session = A(:,4);
%cluster = A(:,1)+1; % 2.5 res
cluster = A(:,15)+1;
ID = A(:,3);
vis_resp = A(:,12);

for sessionID = 1:max(session)
    sessionI = A(:,4) ==sessionID;
    for clusterID = 1:max(cluster)
        allWaveforms(sessionID).clusters(clusterID).ID = ID(sessionI & cluster ==clusterID);
        allWaveforms(sessionID).clusters(clusterID).vis_resp = vis_resp(sessionI & cluster ==clusterID);
    end
end

%%
cluster_colors