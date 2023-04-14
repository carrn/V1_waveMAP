
%% Multichannel Waveform


%for sessionID = 1;
figure
%colors = {[0 0.3 0.6],[1 0.5 0.2],[0.6 0 0],[0.7 0.5 0],[0 0.7 0.6];};
colors = clusterColors;
for clusterID=1:max(cluster)%[3 7 1 8]%
    uId = [];
    currSpread = [];
    spread = [];
    troughtraj = [];
    peaktraj = [];
    currTraj = [];
    amp = [];
    troughIdx = [];
    peakIdx = [];
    t = [];
    unitIds = [];

    for sessionID = 1:5
        time = linspace(0,82/30000*1000);
        uId = allWaveforms(sessionID).clusters(clusterID).ID(allWaveforms(sessionID).clusters(clusterID).vis_resp == 1)+1;
        trajectory = allWaveforms(sessionID).trajectory;
        numChannels = size(trajectory,1);
        if sessionID == 4 || sessionID ==5
            currSpread = flipud(squeeze(trajectory(1:2:numChannels,:,uId)));
        else
            currSpread = squeeze(trajectory(1:2:numChannels,:,uId));
        end
        spread = cat(3, spread , currSpread);
        minpeak = nanmean(spread,3);
        % keyboard
        for unitID = 1:length(uId)
            %currTraj = squeeze(trajectory(1:2:numChannels,:,uId(unitID))); %1:2:numChannels
            if sessionID == 4 || sessionID ==5
                currTraj = flipud(squeeze(trajectory(1:2:numChannels,:,uId(unitID))));
            else
                currTraj = squeeze(trajectory(1:2:numChannels,:,uId(unitID)));
            end
            [M I] = min(currTraj');
            troughtraj = [troughtraj ; M];
            troughIdx = [troughIdx ; I];
            [M I] = max(currTraj');
            peaktraj = [peaktraj ; M];
            peakIdx = [peakIdx ; I];
            t = [t; time];
            amp = [amp ; abs(max(max(currTraj))-min(min(currTraj)))];
        end
        unitIds = [unitIds ; uId-1, repmat(sessionID,length(uId),1)];
    end
    distFromSoma = [-0.1:0.02:0.1];
    %distFromSoma = [1:2:numChannels];
    subplot(max(cluster),1,clusterID);
    colormap turbo
    imagesc(time(11:50),distFromSoma,nanmedian(spread(:,11:50,:),3))
    colorbar
    
    AmpPerCluster(clusterID).id = unitIds;
    AmpPerCluster(clusterID).data = spread;
    AmpPerCluster(clusterID).amp = amp;
    AmpPerCluster(clusterID).traj = troughtraj;
    AmpPerCluster(clusterID).troughIdx = troughIdx;
    AmpPerCluster(clusterID).peakIdx = peakIdx;
    AmpPerCluster(clusterID).time = t;
    
    caxis([-50 40])
    title(sprintf(['Cluster ',num2str(clusterID)]))
    set(gca,'box','off','TickDir','out')
    set(gca,'YDir','normal')
end

ylabel('Distance from Soma (mm)')
xlabel('Time (ms)')

%print -depsc -tiff -r300 -painters multiChannelWaveformforPoster.eps
%% Example of Spatial Profile
figure
for clusterID=6
    for sessionID = 3
        unitID = 2;
        uId = allWaveforms(sessionID).clusters(clusterID).ID(unitID)+1;
        depth = allWaveforms(sessionID).clusters(clusterID).depth(unitID);
        trajectory = allWaveforms(sessionID).trajectory;
        numChannels = size(trajectory,1);
        
        if sessionID == 4 || sessionID == 5
            currSpread = flipud(squeeze(trajectory(1:2:numChannels,:,uId)));
        else
            currSpread = squeeze(trajectory(1:2:numChannels,:,uId));
        end
        
        %currSpread = squeeze(trajectory(1:2:numChannels,:,uId));
        
        distFromSoma = [-0.1:0.02:0.1];
        %channels = [1:2:numChannels];
        time = linspace(0,82/30000*1000);
        colormap turbo
        subplot(2,1,1)
        imagesc(time(11:50),distFromSoma,currSpread(:,11:50,:))
        colorbar
        
    title(sprintf(['Cluster ',num2str(clusterID),' Session ',num2str(sessionID),' Unit ',num2str(uId-1),' Depth ',num2str(depth)])) 
    %caxis([-60 60])
    set(gca,'box','off','TickDir','out') 
    set(gca,'YDir','normal')
    ylabel('Distance from Soma (mm)')
    
    subplot(2,1,2)
    
    for channels = 1:11
        plot(time(11:50), currSpread(channels,11:50)+channels*25,'k')
        hold on
    end
    ylabel('Channels')
        set(gca,'box','off','TickDir','out') 
    set(gca,'YDir','normal')
    end
end

% 8 5 11 11:50 
% 8 4 2   1:80 
% 7 5 15 
% 7 5 9 

xlabel('Time (ms)')

%xline([0])
%%
print -depsc -tiff -r300 -painters multiChannelExample4forPoster.eps

%% Hist of Voltage Spread
figure
for clusterID=1:max(cluster)
    RangeV{clusterID} =  max(squeeze(AmpPerCluster(clusterID).data(6,:,:)),[],2) - min(squeeze(AmpPerCluster(clusterID).data(6,:,:)),[],2);
    subplot(max(cluster),1,clusterID);
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

%print -depsc -tiff -r300 -painters multiChannelSpreadforPoster.eps

%% Normalized Voltage Spread
figure
for clusterID=1:max(cluster)

    distFromSoma = [-0.1:0.02:0.1];
    time = linspace(0,82/30000*1000);

    plot(distFromSoma,rescale(nanmedian(AmpPerCluster(clusterID).traj)',0,1),'-o', 'color', colors{clusterID},'Linewidth',2);  
    hold on
    
end
title('Median Amplitude')
ylabel('Amplitude (A.U.)')
xlabel('Distance from Soma (mm)')
set(gca,'box','off','TickDir','out') 
yline([0.1])
%print -depsc -tiff -r300 -painters MedianTrajectoriesforPoster.eps   
%% Time of Waveform Trough per electrode channel
figure
allTroughTime = [];
for clusterID=[1 2 6 8 7 3 4 5 9]
    troughTime = [];
    
    for unitID = 1:size(AmpPerCluster(clusterID).data,3)
        t = AmpPerCluster(clusterID).time(unitID,:);
        a = AmpPerCluster(clusterID).Idx(unitID,:);
        troughTime = [troughTime ; t(a)];
    end
    
    distFromSoma = [-0.1:0.02:0.1];

    lims = prctile(troughTime(:),[5 95]);
    troughTime(troughTime < lims(1) | troughTime > lims(2)) = NaN;
    if ismember(clusterID,[])
        subplot(121)
        plot( nanmean(troughTime),distFromSoma,'-','color',colors{clusterID});
        xlim([0.5 0.7])
    else
        subplot(122)
        plot( nanmean(troughTime),distFromSoma,'-','color',colors{clusterID});
        xlim([0.5 0.7])
    end
    allTroughTime = [allTroughTime; troughTime];
%     plot(troughTime,distFromSoma,'.-', 'color', [.5 .5 .5])%colors{clusterID},'Linewidth',1);  
    hold on
    %imagesc(troughTime)
    ylabel('Distance from Soma (mm)')
    xlabel('Time (ms)')
    set(gca,'box','off','TickDir','out') 
    
end

title('Time of Waveform Trough per electrode channel')
%print -depsc -tiff -r300 -painters troughPropVelocitiesforPoster.eps 
%%
hold on
m = bootstrp(100,@nanmean,allTroughTime);
scatter(m,distFromSoma)
%%

figure
v_below = allTroughTime(:,1:6);
%v_above = v_above(1:20,:);
nn = length(v_below);
dist_above = repmat(distFromSoma(1:6),nn,1);

idx = any(isnan(v_below));
plot(v_below,dist_above, 'o')
%%

%x1 = v_below;
%x2 = Horsepower;    % Contains NaN data
%y = MPG;

%X = [ones(size(x1)) x1 x2 x1.*x2];
%b = regress(y,X)    % Removes NaN data

%%
coefficients = polyfit(v_below(~idx,:),dist_above(~idx,:),1);
xFit = linspace(0.1, 1.2, 20);
yFit = polyval(coefficients, xFit);
hold on;
plot(xFit, yFit, 'r-', 'LineWidth', 2);
grid on;

%%
figure
v_above = allTroughTime(:,6:11);
nn = length(v_above);
dist_below = repmat(distFromSoma(6:11),nn,1);

idx = any(isnan(v_above));

plot(v_below,dist_above)
%%
coefficients = polyfit(v_below(~idx),dist_below(~idx),2);
xFit = linspace(0, 0.2, 20);
yFit = polyval(coefficients, xFit);
hold on;
plot(xFit, yFit, 'r-', 'LineWidth', 2);
grid on;

title('Median Amplitude')
ylabel('Distance from Soma (mm)')
xlabel('Time (ms)')
set(gca,'box','off','TickDir','out') 

%yline([0.1])
%print -depsc -tiff -r300 -painters MedianTrajectoriesforPoster.eps   

%% Time of Waveform Peak per electrode channel
figure
for clusterID=[1 2 6 8 7 3 4 5 9]
    peakTime = [];
    
    for unitID = 1:size(AmpPerCluster(clusterID).data,3)
        t = AmpPerCluster(clusterID).time(unitID,:);
        a = AmpPerCluster(clusterID).peakIdx(unitID,:);
        peakTime = [peakTime ; t(a)];
    end
    
    distFromSoma = [-0.1:0.02:0.1];

    lims = prctile(peakTime(:),[5 95]);
    %peakTime(peakTime < lims(1) | peakTime > lims(2)) = NaN;
    if ismember(clusterID,[1 2 6 8 7])
        subplot(121)
        plot( nanmean(peakTime),distFromSoma,'-','color',colors{clusterID});
        %xlim([0.5 0.7])
    else
        subplot(122)
        plot( nanmean(peakTime),distFromSoma,'-','color',colors{clusterID});
        %xlim([0.5 0.7])
    end
    
%    plot(troughTime,distFromSoma,'.-', 'color', [.5 .5 .5])%colors{clusterID},'Linewidth',1);  
    hold on
    %imagesc(troughTime)
    ylabel('Distance from Soma (mm)')
    xlabel('Time (ms)')
    set(gca,'box','off','TickDir','out') 
end
title('Time of Waveform  per electrode channel')
%print -depsc -tiff -r300 -painters PeakPropVelocitiesforPoster.eps  

%% Hist of Amplitudes

figure
for clusterID=1:max(cluster)
    AmpV =  AmpPerCluster(clusterID).amp;
    subplot(max(cluster),1,clusterID);
    
 
    hist(AmpV,[0:20:900]);
    ylim([0 30])
    %fprintf('\n%3.2f', median(RangeV{f}))
    %fprintf('\n%3.2f', mean(RangeV{f}))
    title(sprintf(['Cluster ',num2str(clusterID)]))
    
end
 xlabel('Amplitude')
 ylabel('Count')
%% Bar of Median Amplitudes
allAmps = [];

figure
for clusterID=[1 2 6 8 7 3 5 9 4]
    AmpV =  AmpPerCluster(clusterID).amp;
    errorAmp(clusterID,:) = nanstd(AmpV)./sqrt(length(AmpV));
    %title(fprintf(['Cluster ',num2str(f)]))
    allAmps = [allAmps; median(AmpV)];

    %fprintf('\n%3.2f', median(RangeV{f}))
    %fprintf('\n%3.2f', mean(RangeV{f}))
    title(sprintf(['Cluster ',num2str(clusterID)]))
    set(gca,'box','off','TickDir','out')
end


b = bar(allAmps);
hold on
b.FaceColor = 'flat';
b.CData(1,:) = colors{1};
b.CData(2,:) = colors{2};
b.CData(3,:) = colors{6};
b.CData(4,:) = colors{8};
b.CData(5,:) = colors{7};
b.CData(6,:) = colors{3};
b.CData(7,:) = colors{5};
b.CData(8,:) = colors{9};
b.CData(9,:) = colors{4};

%for colorID = 1:length(colors)
%    b.CData(colorID,:) = colors{colorID};
%end

errorbar(allAmps, errorAmp,'LineStyle', 'none','Color','k')
ylabel('Amplitude (A.U.)')
xlabel('Cluster')
set(gca,'box','off','TickDir','out') 
% print -depsc -tiff -r300 -painters medianAmpPerClusterforPoster.eps
%% Median Trajectories
figure
for clusterID=1:max(cluster)

    distFromSoma = [-0.1:0.02:0.1];
    time = linspace(0,82/30000*1000);
    ampss = nanmedian(AmpPerCluster(clusterID).traj)';
    
    plot(nanmedian(AmpPerCluster(clusterID).traj)',distFromSoma,'-o', 'color', colors{clusterID},'Linewidth',2);  
    hold on
     
end
title('Median Amplitude')
ylabel('Amplitude (A.U.)')
xlabel('Distance from Soma (mm)')
set(gca,'box','off','TickDir','out') 
%print -depsc -tiff -r300 -painters MedianTrajectoriesforPoster.eps   
% 
% title(sprintf(['Cluster ',num2str(f)]))
%  xlabel('Amplitude')
% ylabel('Count')
%% peaks of mean per cluster through time
figure
for clusterID = 1:max(cluster)
    
    A = AmpPerCluster(clusterID).data;
    %A = rescale(A,-40,40);
    if clusterID == 8
        whichIx = setdiff(1:size(A,3),[51:52, 59:64, 67:68, 70]);
    else
        whichIx = 1:size(A,3);
    end
    
    S = squeeze(nanmean(A(:,10:50,whichIx),3));
    [~,peakVelocities] = max(S,[],2);
    plot(peakVelocities,distFromSoma,'.-','color', colors{clusterID},'Linewidth',1)
    hold on
    
end
title('Peak Propogation Velocity')

xlabel('Time (ms)')
ylabel('Distance from Soma (mm)')
set(gca,'box','off','TickDir','out')
%print -depsc -tiff -r300 -painters meanPeakPropVelocitiesforPoster.eps  
%% troughs of mean per cluster through time
figure
for clusterID = 1:max(cluster)
    A = AmpPerCluster(clusterID).data;
    if clusterID == 8
        whichIx = setdiff(1:size(A,3),[51:52, 59:64, 67:68, 70]);
    else
        whichIx = 1:size(A,3);
    end
    S = squeeze(nanmean(A(:,10:50,whichIx),3));
    [~,troughVelocities] = min(S,[],2);
    plot(troughVelocities,distFromSoma,'.-','color', colors{clusterID},'Linewidth',1)
    hold on
end
xlabel('Time (ms)')
ylabel('Distance from Soma (mm)')
set(gca,'box','off','TickDir','out')