load('allWaveforms.mat')
load('AmpPerCluster.mat')
%%

clusterFnData = readmatrix('/cluster_data_final.csv');
%Clusters = struct
session = clusterFnData(:,4);
%cluster = A(:,1)+1; % 2.5 res
cluster = clusterFnData(:,15)+1;
ID = clusterFnData(:,3);
vis_resp = clusterFnData(:,12);

for sessionID = 1:max(session)
    sessionI = clusterFnData(:,4) ==sessionID;
    for clusterID = 1:max(cluster)
        allWaveforms(sessionID).clusters(clusterID).ID = ID(sessionI & cluster ==clusterID);
        allWaveforms(sessionID).clusters(clusterID).vis_resp = vis_resp(sessionI & cluster ==clusterID);
    end
end

%%
cluster_colors

%%

vResp = clusterFnData(:,12);
clusterFnData = clusterFnData(find(vResp), :);
clusterFnData(:,1) = clusterFnData(:,1)+1;
clusterFnData(:,15) = clusterFnData(:,15)+1;
clusterFn = clusterFnData(:,15);
depth_scaled = clusterFnData(:,16);


