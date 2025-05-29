
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
    duration = [];
    depth_bins = [];
    
    for sessionID = 1:5
        time = linspace(0,82/30000*1000,82);
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
            [Mmin Imin] = min(currTraj');
            troughtraj = [troughtraj ; Mmin];
            troughIdx = [troughIdx ; Imin];
            [Mmax Imax] = max(currTraj');
            peaktraj = [peaktraj ; Mmax];
            peakIdx = [peakIdx ; Imax];
            t = [t; time];
            amp = [amp ; abs(max(max(currTraj(6,:)))-min(min(currTraj(6,:))))];
            
            [PkAmp, PkTime] = findpeaks(currTraj(6,:),time); 
            [~,idx] = sort(PkAmp,'descend');
            %PkAmp(idx(2)) %Amplitude of the second peak
            %PkTime(idx(2)) %Time of the second peak
            duration = [duration ; time(Imax(6))-time(Imin(6))];
        end
        unitIds = [unitIds ; uId-1, repmat(sessionID,length(uId),1)];
        depth_bins = [depth_bins ; allWaveforms(sessionID).layerId(uId)];
        
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
    AmpPerCluster(clusterID).duration = duration;
    AmpPerCluster(clusterID).depth_bins = depth_bins;
    
    caxis([-40 40])
    title(sprintf(['Cluster ',num2str(clusterID)]))
    set(gca,'box','off','TickDir','out')
    set(gca,'YDir','normal')
end

ylabel('Distance from Soma (mm)')
xlabel('Time (ms)')

%print -depsc -tiff -r300 -painters multiChannelWaveformforPoster.eps
%% Example of Spatial Profile
figure
for clusterID=1
    for sessionID = 1
        unitID = 4;
        uId = allWaveforms(sessionID).clusters(clusterID).ID(unitID)+1;
        depth = allWaveforms(sessionID).clusters(clusterID).depth_scaled(unitID);
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
        time = linspace(0,82/30000*1000,82);
        colormap turbo
        subplot(2,1,1)
        imagesc(time(11:55),distFromSoma,currSpread(:,11:55,:))
        colorbar
        
    title(sprintf(['Cluster ',num2str(clusterID),' Session ',num2str(sessionID),' Unit ',num2str(uId-1),' Depth ',num2str(depth)])) 
    %caxis([-60 60])
    set(gca,'box','off','TickDir','out') 
    set(gca,'YDir','normal')
    ylabel('Distance from Soma (mm)')
    
    subplot(2,1,2)
    for channels = 1:11
        a = 40
        [peak, peakIdx] = max(currSpread(channels,11:55)+channels*2*a);
        [trough, troughIdx] = min(currSpread(channels,11:55)+channels*2*a);
        time1 = time(11:55);
        plot(time1, currSpread(channels,11:55)+channels*2*a,'k')
        hold on
        plot(time1(peakIdx), peak, 'ro')
        hold on
        plot(time1(troughIdx), trough, 'bo')
    end
    ylabel('Channels')
        set(gca,'box','off','TickDir','out') 
    set(gca,'YDir','normal')
    end
end

xlabel('Time (ms)')

%xline([0])
%%
%print -depsc -tiff -r300 -painters multiChannelExample4forPoster.eps

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
    time = linspace(0,82/30000*1000,82);
    plot(distFromSoma,rescale(nanmedian(AmpPerCluster(clusterID).traj)',0,1),'-o', 'color', colors{clusterID},'Linewidth',2);  
    hold on
    
end

title('Median Amplitude')
ylabel('Amplitude (A.U.)')
xlabel('Distance from Soma (mm)')
set(gca,'box','off','TickDir','out') 
yline([0.1])

%print -depsc -tiff -r300 -painters MedianTrajectoriesforPoster.eps 
%
%
%
%
%% Trough Propagation Velocities
figure
allTroughTime = [];
fitTroughProp_below = [];
fitTroughProp = [];
allBt_above = [];

for clusterID=1:max(cluster)
    troughTime = [];
    errorTraj = [];
    for unitID = 1:size(AmpPerCluster(clusterID).data,3)
        t = AmpPerCluster(clusterID).time(unitID,:);
        a = AmpPerCluster(clusterID).troughIdx(unitID,:);
        troughTime = [troughTime ; t(a)];
    end
    
    %Center on trough (soma)
    troughTime = troughTime-troughTime(:,6);
    distFromSoma = [-0.1:0.02:0.1];
    % 95% confidence interval
    lims = prctile(troughTime(:),[5 95]);
    troughTime(troughTime < lims(1) | troughTime > lims(2))= NaN;
    %Standard Error
    errorTraj = nanstd(troughTime)./sqrt(size(troughTime,1));
    
    if ismember(clusterID,[1 2 6 8 7])
        subplot(121)
        errorbar(nanmean(troughTime),distFromSoma,errorTraj,'horizontal','-','color',colors{clusterID}, 'Linewidth', 1);
        %hold on
        %plot(troughTime,distFromSoma,'-','color',[0.5 0.5 0.5 0.5])
        %xlim([0.5 0.7])
    else
        subplot(122)
        %errorTraj(clusterID,:) = nanstd(troughTime)./sqrt(length(troughTime));
        errorbar(nanmean(troughTime),distFromSoma,errorTraj,'horizontal','-','color',colors{clusterID},'Linewidth', 1);
        %xlim([0.5 0.7])
    end
    allTroughTime = [allTroughTime; troughTime];  
    hold on
    
    % v_above
    surrG = bootstrp(100,@nanmean, troughTime(:,6:11));
    v_above = nanmean(troughTime(:,6:11))';
    dist_above = distFromSoma(6:11)';
    X2(:,1) = dist_above;
    X2(:,2) = 1;
    [b] = regress(v_above, X2);
    pred = X2*b;
    
    plot( pred,X2(:,1), '--','color',colors{clusterID}, 'Linewidth', 0.5);%plotting regression fit
    fitTroughProp = [fitTroughProp, b];

    for n=1:100
        X2(:,1) = dist_above;
        X2(:,2) = 1;
        [bS] = regress(surrG(n,:)', X2);
        allBt_above(clusterID,n,:) = bS;
    end
    
    % v_below
    b = [];
    surrG = bootstrp(100,@nanmean, troughTime(:,1:6));
    v_below = nanmean(troughTime(:,1:6))';
    dist_below = distFromSoma(1:6)';
    X2(:,1) = dist_below;
    X2(:,2) = 1;
    [b] = regress(v_below, X2);
    pred = X2*b;
    
    plot( pred,X2(:,1), '--','color',colors{clusterID}, 'Linewidth', 0.5); %plotting regression fit
    fitTroughProp_below = [fitTroughProp_below, b];
    
    for n=1:100
        X2(:,1) = dist_below;
        X2(:,2) = 1;
        [bS] = regress(surrG(n,:)', X2);
        allBt_below(clusterID,n,:) = bS;
    end
    
    ylim([-0.1 0.1]) 
    xlim([-0.1 0.2]) 
    grid on 
    ylabel('Distance from Soma (mm)') 
    xlabel('Time Relative to Soma (ms)') 
    set(gca,'box','off','TickDir','out') 
    set(gcf,'renderer','Painters')
end


title('Time of Waveform Trough per electrode channel')
%print -depsc -tiff -r300 -painters troughPropVelocitiesforPoster.eps 

%% Trough below and Trough above velocities
figure 
t = tiledlayout(1,2,'TileSpacing','compact');
bgAx = axes(t,'XTick',[],'YTick',[],'Box','off');
bgAx.Layout.TileSpan = [1 2];
ax1 = axes(t);
ax2 = axes(t);
ax2.Layout.Tile = 2;


linkaxes([ax1 ax2], 'y')

for clusterID = setdiff(1:9,[])
    troughErr = squeeze(nanstd(allBt_above(clusterID,:,1),[],2));
    peakErr = squeeze(nanstd(allBt_below(clusterID,:,1),[],2));
%errorbar(fitTroughProp_below(1,clusterID), fitTroughProp(1,clusterID),npeakErr,ppeakErr,ntroughErr,ptroughErr,'o', 'Color',colors{clusterID})    
%hold on
%axis equal
%grid on
%

% Create second plot
if clusterID ==7
errorbar(ax1,fitTroughProp_below(1,clusterID), fitTroughProp(1,clusterID),troughErr,troughErr,peakErr,peakErr,'o', 'Color',colors{clusterID})    
hold on
set(ax1,'box','off','TickDir','out') 
hold on

%plot(ax1,x,y)
else
errorbar(ax2,fitTroughProp_below(1,clusterID), fitTroughProp(1,clusterID),troughErr,troughErr,peakErr,peakErr,'o', 'Color',colors{clusterID})    
hold on
end
%plot(ax2,x,y)
set(ax2,'box','off','TickDir','out') 
end


xline(ax1,-1.25,':');
ax1.Box = 'off';
xlim(ax1,[-2.25 -1.25])
ax2.YAxis.Visible = 'off';
ax2.Box = 'off';
xlim(ax2,[-0.4 0.4])

yline([1])
xline([0])
hold on
plot([-2:0.1:2],[2:-0.1:-2])
%ylabel('Slope of Trough Propagation Velocity towards Pia (mm/ms)')
%xlabel('Slope of Trough Propagation Velocity away from Pia (mm/ms)')

%print -depsc -tiff -r300 -painters Trough_aboveandTrough_belowVelocitiesforPoster.eps  
%% symmetry index 
figure 
for clusterID = setdiff(1:9,[7])
    troughErr = squeeze(nanstd(allBt_above(clusterID,:,1),[],2));
    peakErr = squeeze(nanstd(allBt_below(clusterID,:,1),[],2));
errorbar(fitTroughProp_below(1,clusterID), fitTroughProp(1,clusterID),troughErr,troughErr,peakErr,peakErr,'o', 'Color',colors{clusterID})    
hold on
axis equal
grid on
hold on
%plot([-2:0.1:2],[2:-0.1:-2])
end


yline([1])
xline([0])
hold on
plot([-2:0.1:2],[2:-0.1:-2])
%ylim([-1 1])
xlim([-1.5 1])
%ylabel('Slope of Trough Propagation Velocity towards Pia (mm/ms)')
%xlabel('Slope of Trough Propagation Velocity away from Pia (mm/ms)')

%print -depsc -tiff -r300 -painters Trough_aboveandTrough_belowVelocitiesforPoster.eps  
%% Symmetry Index Fig 5 E
a = 1;
b = 1;
c = 0;
%x0 = fitTroughProp_below(1,:);
%y0 = fitTroughProp(1,:);

troughErr = squeeze(nanstd(allBt_below(:,:,1),[],2));
peakErr = squeeze(nanstd(allBt_above(:,:,1),[],2));


SI = abs(a*x0+b*y0+c)/sqrt(a^2+b^2);
SI_err = abs(a*troughErr+b*peakErr+c)/sqrt(a^2+b^2);

figure
cnt = 0;

for clusterID = [1 6 8 2 7 3 9 5 4]
    cnt = cnt+1;
    errorbar(cnt,SI(clusterID),SI_err(clusterID),SI_err(clusterID),'o','color',colors{clusterID})
    hold on
end
xlim([0 10])
%% Significance of SI differences


x0 = allBt_below(:,:,1);
y0 = allBt_above(:,:,1);

troughErr = squeeze(nanstd(allBt_below(:,:,1),[],2));
peakErr = squeeze(nanstd(allBt_above(:,:,1),[],2));

SI = abs(a*x0+b*y0+c)/sqrt(a^2+b^2);
SI_err = abs(a*troughErr+b*peakErr+c)/sqrt(a^2+b^2);

figure
cnt = 0;
for clusterID = [1 6 8 2 7 3 9 5 4]
    cnt = cnt+1;
    errorbar(cnt,nanmean(SI(clusterID),2),SI_err(clusterID),SI_err(clusterID),'o','color',colors{clusterID})
    hold on
end
% plot(nanmean(SI,2),'o')
[h,p,ci,stats]=ttest(SI(3,:),SI(4,:))
%v_1 = [x2,y2,0] - [x1,y1,0];
%v_2 = [x3,y3,0] - [x1,y1,0];
%Theta = atan2(norm(cross(v_1, v_2)), dot(v_1, v_2));

%% Backprop by layer
layerIds = vertcat(AmpPerCluster.depth_bins);
clusterIds = [];
for n=1:length(AmpPerCluster)
    clusterIds = [clusterIds; n*ones(size(AmpPerCluster(n).depth_bins,1),1)];
end
allTimes = vertcat(AmpPerCluster.time);
allTroughs = vertcat(AmpPerCluster.troughIdx);

for n=1:size(allTimes,1)
    selectedData(n,:) = allTimes(n,allTroughs(n,:));
end
selectedData = selectedData-selectedData(:,6);

lims = prctile(selectedData(:),[2.5 97.5]);
selectedData(selectedData < lims(1) | selectedData > lims(2) | selectedData < -0.3)= NaN;
       
distFromSoma = [-0.1:0.02:0.1];

%% Backprop by layer
figure;
% plot( nanmean(selectedData(layerIds==4  & ismember(clusterIds, [1 2 6 8]),:)), distFromSoma, 'r-');
hold on;
plot( nanmean(selectedData(layerIds==3 | layerIds==2 & ismember(clusterIds, [2 8]),:)), distFromSoma, 'g-');
hold on;
plot( nanmean(selectedData(layerIds==3 | layerIds==2 & ismember(clusterIds, [ 1 6]),:)), distFromSoma, 'm-');
hold on;

plot( nanmean(selectedData(layerIds==4  & ismember(clusterIds, [4]),:)), distFromSoma, 'r-');
hold on;
plot( nanmean(selectedData(layerIds==3 | layerIds==2 & ismember(clusterIds, [4  ]),:)), distFromSoma, 'g-');
hold on;
plot( nanmean(selectedData(layerIds==1 & ismember(clusterIds, [ 4 ]),:)), distFromSoma, 'b-');
hold on;

%%
% plot( nanmean(selectedData(layerIds==2 & clusterIds==9,:)), distFromSoma,'b-');
hold on;
plot( nanmean(selectedData(layerIds==1 & ismember(clusterIds, [1 5 9]),:)), distFromSoma,'b-');

hold on;

plot( nanmean(selectedData(layerIds==4 & ismember(clusterIds, [3  5 9]),:)), distFromSoma, 'r-');
hold on;
plot( nanmean(selectedData(layerIds==2 | layerIds == 3 & ismember(clusterIds, [3  5 9]),:)), distFromSoma, 'g-');
hold on;
% plot( nanmean(selectedData(layerIds==2 & clusterIds==9,:)), distFromSoma,'b-');
hold on;
plot( nanmean(selectedData(layerIds==1 & ismember(clusterIds, [3  5 9]),:)), distFromSoma,'b-');



%% Trough Propagation Velocities by layer and cluster
%figure
allTroughTime = [];
fitTroughProp_below = [];
fitTroughProp = [];
allBt_above = [];
SI = [];
SI_layerCluster = [];
clusters = [2:6,8,9];
layers = [1];
figure
for layerID= layers
    for clusterID = clusters
        
        troughTime = [];
        errorTraj = [];
        for unitID = [find(AmpPerCluster(clusterID).depth_bins==layerID)]'
            t = AmpPerCluster(clusterID).time(unitID,:);
            a = AmpPerCluster(clusterID).troughIdx(unitID,:);
            troughTime = [troughTime ; t(a)];
        end
        
        %Center on trough (soma)
        troughTime = troughTime-troughTime(:,6);
        distFromSoma = [-0.1:0.02:0.1];
        % 95% confidence interval
        lims = prctile(troughTime(:),[5 95]);
        troughTime(troughTime < lims(1) | troughTime > lims(2) | troughTime < -0.3)= NaN;
        %Standard Error
        %errorTraj = nanstd(troughTime)./sqrt(size(troughTime,1));
        
        %     if ismember(clusterID,[1 2 6 8 7 ])
        %         subplot(121)
        %         %errorbar(nanmean(troughTime),distFromSoma,errorTraj,'horizontal','-','color',colors{clusterID}, 'Linewidth', 1);
        %         %hold on
        
        %xlim([0.5 0.7])
        %     else
        %         subplot(122)
        %         %errorTraj(clusterID,:) = nanstd(troughTime)./sqrt(length(troughTime));
        %         %errorbar(nanmean(troughTime),distFromSoma,errorTraj,'horizontal','-','color',colors{clusterID},'Linewidth', 1);
        %         %xlim([0.5 0.7])
        %         plot(troughTime,distFromSoma,'-','color',[0.5 0.5 0.5 0.5])
        % end
        allTroughTime = [allTroughTime; troughTime];
        hold on
        
        plot(nanmean(troughTime),distFromSoma,'-','color',[0.5 0.5 0.5 0.5])
        hold on
        
        %     % v_above
        surrG = bootstrp(100,@nanmean, troughTime(:,6:11));
        v_above = nanmean(troughTime(:,6:11))';
        dist_above = distFromSoma(6:11)';
        X2(:,1) = dist_above;
        X2(:,2) = 1;
        [b] = regress(v_above, X2);
        pred = X2*b;
        hold on
        plot( pred,X2(:,1), '--','color',colors{clusterID}, 'Linewidth', 0.5);%plotting regression fit
        fitTroughProp = [fitTroughProp, b];
        
%         %     % v_below
%         b = [];
%         surrG = bootstrp(100,@nanmean, troughTime(:,1:6));
%         v_below = nanmean(troughTime(:,1:6))';
%         dist_below = distFromSoma(1:6)';
%         X2(:,1) = dist_below;
%         X2(:,2) = 1;
%         [b] = regress(v_below, X2);
%         pred = X2*b;
%         hold on
%         plot( pred,X2(:,1), '--','color',colors{clusterID}, 'Linewidth', 0.5); %plotting regression fit
%         fitTroughProp_below = [fitTroughProp_below, b];
%         
        %     % Symmetry Index
%         a = 1;
%         b = 1;
%         c = 0;
%         x0 = fitTroughProp_below(1,:);
%         y0 = fitTroughProp(1,:);
%         
%         SI = abs(a.*x0+b.*y0+c)./sqrt(a.^2+b.^2);
        
        
        ylim([-0.1 0.1])
        xlim([-0.1 0.2])
        grid on
        title(sprintf(['Cluster ',num2str(clusterID),' Layer ',num2str(layerID)]))
        
        ylabel('Distance from Soma (mm)')
        xlabel('Time Relative to Soma (ms)')
        set(gca,'box','off','TickDir','out')
    end
    
end
SI = reshape(SI,length(layers),length(clusters));

%%
fitTroughProp_below = [];
fitTroughProp = [];
        %     % v_above
        figure
plot(nanmean(allTroughTime),distFromSoma,'-','color',[0.5 0.5 0.5 0.5])
        surrG = bootstrp(100,@nanmean, allTroughTime(:,6:11));
        v_above = nanmean(allTroughTime(:,6:11))';
        dist_above = distFromSoma(6:11)';
        X2(:,1) = dist_above;
        X2(:,2) = 1;
        [b] = regress(v_above, X2);
        pred = X2*b;
        hold on
        plot( pred,X2(:,1), '--','color',colors{clusterID}, 'Linewidth', 0.5);%plotting regression fit
        fitTroughProp = [fitTroughProp, b];
        
        %     % v_below
        b = [];
        surrG = bootstrp(100,@nanmean, allTroughTime(:,1:6));
        v_below = nanmean(allTroughTime(:,1:6))';
        dist_below = distFromSoma(1:6)';
        X2(:,1) = dist_below;
        X2(:,2) = 1;
        [b] = regress(v_below, X2);
        pred = X2*b;
        hold on
        plot( pred,X2(:,1), '--','color',colors{clusterID}, 'Linewidth', 0.5); %plotting regression fit
        fitTroughProp_below = [fitTroughProp_below, b];
        
                %     % Symmetry Index
        a = 1;
        b = 1;
        c = 0;
        x0 = fitTroughProp_below(1,:);
        y0 = fitTroughProp(1,:);
        
        SI = abs(a.*x0+b.*y0+c)./sqrt(a.^2+b.^2)
        

%SI_layerCluster = [SI_layerCluster; SI];
%title('Time of Waveform Trough per electrode channel')
%print -depsc -tiff -r300 -painters troughPropVelocitiesforPoster.eps


%xline([0])
%%
%print -depsc -tiff -r300 -painters multiChannelExample4forPoster.eps
%% Peak Propagation velocities
figure
fitPeakProp = [];
allBp = [];
for clusterID=1:9
    peakTime = [];
    troughTime = [];
    errorTraj = [];
    
    for unitID = 1:size(AmpPerCluster(clusterID).data,3)
        t = AmpPerCluster(clusterID).time(unitID,:);
        a = AmpPerCluster(clusterID).peakIdx(unitID,:);
        peakTime = [peakTime ; t(a)];
        a = AmpPerCluster(clusterID).troughIdx(unitID,:);
        troughTime = [troughTime ; t(a)];
    end
    %Center on Peak (soma)
    peakTime = peakTime-troughTime(:,6);
    distFromSoma = [-0.1:0.02:0.1];
    % 95% confidence intervals
    lims = prctile(peakTime(:),[5 95]);
    peakTime(peakTime < lims(1) | peakTime > lims(2)) = NaN;
    % Standard Error
    errorTraj = nanstd(peakTime)./sqrt(length(peakTime));
    if ismember(clusterID,[1 2 6 8 7 2 4 5 9])
        %subplot(121)
        errorbar(nanmean(peakTime), distFromSoma, errorTraj,'horizontal','-','color',colors{clusterID},'Linewidth',1);
        %hold on
        %plot(peakTime,distFromSoma,'-','color',[0.5 0.5 0.5 0.5])
        %xlim([0.5 0.7])

    else
        %subplot(122)
        errorbar(nanmean(peakTime), distFromSoma, errorTraj,'horizontal','color',colors{clusterID},'Linewidth',1);
        %xlim([0.5 0.7])

    end
    hold on
    
    % Bootstrapping regression fit
    surrG = bootstrp(100,@nanmean, peakTime(:,6:11));
    v_above = nanmean(peakTime(:,6:11))';
    dist_above = distFromSoma(6:11)';
  
    X2(:,1) = dist_above;
    X2(:,2) = 1;
    [b] = regress(v_above, X2);
    pred = X2*b;
    
    for n=1:100
        X2(:,1) = dist_above;
        X2(:,2) = 1;
        [bS] = regress(surrG(n,:)', X2);
        allBp(clusterID,n,:) = bS;
    end
    
    plot( pred,X2(:,1), '--','color',colors{clusterID}, 'Linewidth', 0.5);
    fitPeakProp = [fitPeakProp, b];
      
    %X = [ones(size(v_above)) v_above ];
    %[b bint r rint] = regress(dist_above, X, 0.01); 
    %xx= [(0-b(1))/b(2):0.1:0.55];  
    %yy= b(1)+b(2)*xx;
    % plot(xx,yy, '--','color',colors{clusterID}, 'Linewidth', 0.5)
    % ylim([-0.1 0.1])    
    % xlim([-0.1 0.7])
    
    ylabel('Distance from Soma (mm)')
    xlabel('Time Relative to Soma (ms)')
    set(gca,'box','off','TickDir','out') 
end
title('Time of Waveform Peak per electrode channel')
%print -depsc -tiff -r300 -painters PeakPropVelocitiesforPoster.eps  

%% Peak and Trough Velocities
figure 
for clusterID = 1:9
    troughErr = squeeze(nanstd(allBp(clusterID,:,1),[],2));
    troughErr = squeeze(nanstd(allBp(clusterID,:,1),[],2));
    peakErr = squeeze(nanstd(allBt_above(clusterID,:,1),[],2));
    peakErr = squeeze(nanstd(allBt_above(clusterID,:,1),[],2));
errorbar(fitPeakProp(1,clusterID), fitTroughProp(1,clusterID),peakErr,peakErr,troughErr,troughErr,'o', 'Color',colors{clusterID})    
hold on
end
ylabel('Slope of Trough Propagation Velocity towards Pia (mm/ms)')
xlabel('Slope of Peak Propagation Velocity towards Pia (mm/ms)')
set(gca,'box','off','TickDir','out') 
%print -depsc -tiff -r300 -painters PeakandTroughVelocitiesforPoster.eps  
%%
colors1 = reshape(cell2mat(colors),3,9)';
figure
scatter(fitPeakProp(1,:), fitTroughProp(1,:), [], colors1,'filled')    
ylabel('Trough')
xlabel('Peak')
set(gca,'box','off','TickDir','out') 
errorbar(1:9, squeeze(nanmedian(allBt_above(:,:,1),2)), squeeze(nanstd(allBt_above(:,:,1),[],2)))
hold on
errorbar(1:9, squeeze(nanmedian(allBp(:,:,1),2)), squeeze(nanstd(allBp(:,:,1),[],2)))

%
%
%
%
%% Time of Waveform Trough per electrode channel
figure
allTroughTime = [];
fitTroughProp = [];
for clusterID=1:max(cluster)
    troughTime = [];
    %errorTraj = [];
    for unitID = 1:size(AmpPerCluster(clusterID).data,3)
        t = AmpPerCluster(clusterID).time(unitID,:);
        a = AmpPerCluster(clusterID).troughIdx(unitID,:);
        troughTime = [troughTime ; t(a)];
    end
    %Center on trough (soma)
    %troughTime = troughTime-troughTime(:,6);
    distFromSoma = [-0.1:0.02:0.1];

    lims = prctile(troughTime(:),[5 95]);
    troughTime(troughTime < lims(1) | troughTime > lims(2)) = NaN;
    errorTraj = nanstd(troughTime)./sqrt(length(troughTime));
    if ismember(clusterID,[1 2 6 8 7 ])
        subplot(121)
        
        plot(nanmedian(troughTime),distFromSoma,'-','color',colors{clusterID}, 'Linewidth', 1);
        %xlim([0.5 0.7])
    else
        subplot(122)
        %errorTraj(clusterID,:) = nanstd(troughTime)./sqrt(length(troughTime));
        plot(nanmedian(troughTime),distFromSoma,'-','color',colors{clusterID},'Linewidth', 1);
        %xlim([0.5 0.7])
    end
    allTroughTime = [allTroughTime; troughTime];  
    hold on
    ylabel('Distance from Soma (mm)')
    xlabel('Time Relative to Soma (ms)')
    set(gca,'box','off','TickDir','out') 
    
    v_above = nanmedian(troughTime(:,6:11))';
    dist_above = distFromSoma(6:11)';
    X = [ones(size(v_above)) v_above ];
    b = regress(dist_above, X);
    fitTroughProp = [fitTroughProp, b];
%     
    xx= [0:0.1:0.2]; 
    yy= b(1)+b(2)*xx;
    plot(xx,yy,'--','color',colors{clusterID})
    ylim([-0.1 0.1])
    
end


title('Time of Waveform Trough per electrode channel')
%print -depsc -tiff -r300 -painters troughPropVelocitiesforPoster.eps 

%% Time of Waveform Peak per electrode channel
figure
fitPeakProp = [];
for clusterID=1:max(cluster)
    peakTime = [];
    %troughTime = [];
    %errorTraj = [];
    
    for unitID = 1:size(AmpPerCluster(clusterID).data,3)
        t = AmpPerCluster(clusterID).time(unitID,:);
        a = AmpPerCluster(clusterID).peakIdx(unitID,:);
        peakTime = [peakTime ; t(a)];
        %a = AmpPerCluster(clusterID).troughIdx(unitID,:);
        %troughTime = [troughTime ; t(a)];
    end
    %Center on Peak (soma)
    %peakTime = peakTime-troughTime(:,6);
    distFromSoma = [-0.1:0.02:0.1];
    lims = prctile(peakTime(:),[5 95]);
    peakTime(peakTime < lims(1) | peakTime > lims(2)) = NaN;
    %errorTraj = nanstd(peakTime)./sqrt(length(peakTime));
    if ismember(clusterID,[1 2 6 8 7 3 4 5 9])
        %subplot(121)
        plot( nanmedian(peakTime),distFromSoma,'-','color',colors{clusterID},'Linewidth',1);
        %hold on
        %plot(peakTime,distFromSoma,'-','color',[0.5 0.5 0.5 0.5])
        %xlim([0.5 0.7])

    else
        %subplot(122)
        plot( nanmedian(peakTime),distFromSoma,'-','color',colors{clusterID},'Linewidth',1);
        %xlim([0.5 0.7])

    end
   
    hold on
    v_above = nanmedian(peakTime(:,6:11))';
    dist_above = distFromSoma(6:11)';
    X = [ones(size(v_above)) v_above ];
    [b bint r rint] = regress(dist_above, X, 0.01);
    fitPeakProp = [fitPeakProp, b];
    
    xx= [(0-b(1))/b(2):0.1:0.7];  
    yy= b(1)+b(2)*xx;
    plot(xx,yy, '--','color',colors{clusterID}, 'Linewidth', 0.5)
    ylim([-0.1 0.1])    
    
    ylabel('Distance from Soma (mm)')
    xlabel('Time Relative to Soma (ms)')
    set(gca,'box','off','TickDir','out') 
end
title('Time of Waveform Peak per electrode channel')
%print -depsc -tiff -r300 -painters PeakPropVelocitiesforPoster.eps  

%%
colors1 = reshape(cell2mat(colors),3,9)';
figure
scatter(fitPeakProp(2,:), fitTroughProp(1,:), [], colors1, 'filled')    
ylabel('Trough')
xlabel('Peak')
set(gca,'box','off','TickDir','out') 
%% Hist of trough to peak Duration and T-P Dur per cluster
allDur = [];
figure
for clusterID=1:max(cluster)
    Dur =  AmpPerCluster(clusterID).duration;
    DurErr = std(Dur);
    %subplot(max(cluster),1,clusterID);
    allDur = [allDur; Dur];
    
    %ylim([0 30])
    %fprintf('\n%3.2f', median(RangeV{f}))
    %fprintf('\n%3.2f', mean(RangeV{f}))
    title(sprintf(['Cluster ',num2str(clusterID)]))
    fprintf('\n%d: %3.2f +- %3.2f', clusterID, nanmedian(Dur),DurErr)
end
histogram(allDur,[-0.4:0.05:1],'Normalization','probability');
 xlabel('Amplitude')
 ylabel('Count')
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
%% Bar of Mean Amplitudes
allAmps = [];


figure
for clusterID=[1 6 8 2 7 3 9 5 4]
    AmpV =  AmpPerCluster(clusterID).amp;
    errorAmp(clusterID,:) = nanstd(AmpV)./sqrt(length(AmpV));
    %title(fprintf(['Cluster ',num2str(f)]))
    allAmps = [allAmps; nanmean(AmpV)];

    %fprintf('\n%3.2f', median(RangeV{f}))
    %fprintf('\n%3.2f', mean(RangeV{f}))
    title(sprintf(['Cluster ',num2str(clusterID)]))
    set(gca,'box','off','TickDir','out')
end


b = bar(allAmps);
hold on
b.FaceColor = 'flat';
b.CData(1,:) = colors{1};
b.CData(2,:) = colors{6};
b.CData(3,:) = colors{8};
b.CData(4,:) = colors{2};
b.CData(5,:) = colors{7};
b.CData(6,:) = colors{3};
b.CData(7,:) = colors{9};
b.CData(8,:) = colors{5};
b.CData(9,:) = colors{4};

%for colorID = 1:length(colors)
%    b.CData(colorID,:) = colors{colorID};
%end

errorbar(allAmps, errorAmp,'LineStyle', 'none','Color','k')
ylabel('Amplitude (A.U.)')
xlabel('Cluster')
set(gca,'box','off','TickDir','out') 
% print -depsc -tiff -r300 -painters medianAmpPerClusterforPoster.eps

%% mean Amp and Trough Velocity
xIds = 1:9;
Mu = squeeze(nanmean(allBt_above(xIds,:,1),2));
%MuErr = squeeze(nanstd(allBt_above(xIds,:,1),2));

Mu1 = squeeze(nanmean(allBt_above(xIds,:,1),2));
Mu1Err = squeeze(nanstd(allBt_above(xIds,:,1),[],2));

troughErr = squeeze(nanstd(allBt_above(clusterID,:,1),[],2));

Mu2 = squeeze(nanmean(allBt_below(xIds, :,:),2));

figure; 
for clusterID = 1:9
errorbar(allAmps(clusterID), Mu1(clusterID),Mu1Err(clusterID),Mu1Err(clusterID),errorAmp(clusterID),errorAmp(clusterID),'o','color',colors{clusterID})
hold on
grid on
end
set(gca,'box','off','TickDir','out') 

corr(Mu1, allAmps(xIds))
%figure; scatter3(allAmps(xIds), Mu1, Mu2(:,1),[],colors1)
%print -depsc -tiff -r300 -painters meanAmpandTroughVelocityAboveforPoster.eps
%% Median Trajectories
figure
for clusterID=1:max(cluster)

    distFromSoma = [-0.1:0.02:0.1];
    time = linspace(0,82/30000*1000,82);
    ampss = nanmedian(AmpPerCluster(clusterID).traj)'
    
    plot(ampss,distFromSoma,'-o', 'color', colors{clusterID},'Linewidth',2);  
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


%%
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

%%

figure
%v_below = allTroughTime(:,1:6);
v_above = allTroughTime(:, 1:6);
nn = length(v_above);
dist_above = repmat(distFromSoma(6:11),nn,1);

idx = any(isnan(v_above));
plot(v_above,dist_above, 'o')
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
