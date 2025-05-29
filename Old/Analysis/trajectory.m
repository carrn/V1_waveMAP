% 
% allAmp = [];
% unitID = length(allWaveforms(5).templateID)
% currTraj = allWaveforms(5).trajectory(:,:,114);
% 
% 
% maxAmp = max(currTraj');
% 
% allAmp = [allAmp ; maxAmp];
% 
% 
%  figure
%  plot(maxAmp')
 
 %%
 
 sessionID = 1;
 for clusterID=1:5
     uId = [];
     currtraj = [];
    % for sessionID = 1:5
        uId = allWaveforms(sessionID).clusters(clusterID).ID+1;
        currtraj = allWaveforms(sessionID).trajectory;
        traj = [traj ; squeeze(currtraj(1:2:11,:,uId));
        
    % end
     subplot(5,1,clusterID);
     imagesc(nanmean(traj))
     colorbar
     %caxis([-25 25])
 end
 
 