
%% Multichannel Waveform


%for sessionID = 1;
figure
%colors = {[0.8549    0.9098    0.9608],[0.7294    0.8392    0.9176],[0.5333    0.7451    0.8627],[0.3255    0.6157    0.8000],[0.1647    0.4784    0.7255];};
colors = clusterColors;
alpha = 0.2;
lines = {'-','--','-.',':','-'};
linew = {3 , 1, 1 ,1, 1};
for clusterID=1:5
    uId = [];
    currSpread = [];
    spread = [];
    traj = [];
    currTraj = [];
    amp = [];
    for sessionID = 1:5
        
        uId = allWaveforms(sessionID).posclusters(clusterID).ID+1;
        trajectory = allWaveforms(sessionID).trajectory;
        numChannels = size(trajectory,1);
        currSpread = squeeze(trajectory(1:2:numChannels,:,uId));
        
        spread = cat(3, spread , currSpread);
        % keyboard
        for unitID = 1:length(uId)
            currTraj = squeeze(trajectory(1:2:numChannels,:,unitID));
            traj = [traj ; max(abs(currTraj'))];
            amp = [amp ; abs(max(max(currTraj))-min(min(currTraj)))];
        end
        
    end
    distFromSoma = [-0.1:0.02:0.1];
    time = linspace(0,82/30000*1000);
    subplot(5,1,clusterID);
    imagesc(time,distFromSoma,nanmean(spread,3))
    colorbar
    
    AmpPerCluster(clusterID).data = spread;
    AmpPerCluster(clusterID).amp = amp;
    AmpPerCluster(clusterID).traj = traj;

    %caxis([-80 60])
    title(sprintf(['Cluster ',num2str(clusterID)]))

end

ylabel('Distance from Soma [mm]')
xlabel('Time [ms]')
%print -depsc -tiff -r300 -painters multiChannelWaveformposforPoster.eps

%% Hist of Voltage Spread
figure
for clusterID=1:5
    RangeV{clusterID} =  max(squeeze(AmpPerCluster(clusterID).data(6,:,:)),[],2) - min(squeeze(AmpPerCluster(clusterID).data(6,:,:)),[],2);
    subplot(5,1,clusterID);
    %title(fprintf(['Cluster ',num2str(f)]))
    hist(RangeV{clusterID},[0:20:500]);
    fprintf('\n%3.2f', median(RangeV{clusterID}))
    %fprintf('\n%3.2f', mean(RangeV{f}))
    title(sprintf(['Cluster ',num2str(clusterID)]))
    set(gca,'box','off') 
end
 xlabel('Voltage Spread')
ylabel('Count')

%xline([0])

%print -depsc -tiff -r300 -painters multiChannelSpreadposforPoster.eps
%% Hist of Amplitudes
figure
for clusterID=1:5
    AmpV =  AmpPerCluster(clusterID).amp;
    subplot(5,1,clusterID);
    %title(fprintf(['Cluster ',num2str(f)]))
    hist(AmpV,[0:20:900]);
    %fprintf('\n%3.2f', median(RangeV{f}))
    %fprintf('\n%3.2f', mean(RangeV{f}))
    title(sprintf(['Cluster ',num2str(clusterID)]))
end
 xlabel('Amplitude')
 ylabel('Count')
 
%% Median Trajectories
figure
for clusterID=1:5

    distFromSoma = [-0.1:0.02:0.1];
    time = linspace(0,82/30000*1000);

    

     plot(distFromSoma,mean(AmpPerCluster(clusterID).traj)',  'color', colors{clusterID},'Linestyle', lines{clusterID},'LineWidth',linew{clusterID});  
     hold on
end
title('Median Amplitude')
ylabel('Amplitude [A.U.]')
xlabel('Distance from Soma [mm]')
set(gca,'box','off') 
%print -depsc -tiff -r300 -painters MedianTrajectoriesposforPoster.eps   
% 
% title(sprintf(['Cluster ',num2str(f)]))
%  xlabel('Amplitude')
% ylabel('Count')