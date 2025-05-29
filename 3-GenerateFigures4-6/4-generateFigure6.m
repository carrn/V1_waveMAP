%% Figure 6B

figure
colors = clusterColors;
allSpread = [];
idVc = [];

for clusterID=1:9
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
        %         currSpread = currSpread./range(currSpread(:));
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
            duration = [duration ; time(Imax(6))-time(Imin(6))];
        end
        unitIds = [unitIds ; uId-1, repmat(sessionID,length(uId),1)];
        depth_bins = [depth_bins ; allWaveforms(sessionID).layerId(uId)];
        
    end
    distFromSoma = [-0.1:0.02:0.1];
    subplot(3,3,clusterID);
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
    
    title(sprintf(['Cluster ',num2str(clusterID)]))
    set(gca,'box','off','TickDir','out')
    set(gca,'YDir','normal')
    
    allSpread = cat(3, allSpread, spread);
    idVc = cat(1, idVc, clusterID*ones(size(spread,3),1));
end

ylabel('Distance from Soma (mm)')
xlabel('Time (ms)')


%% Figure 6A

for clusterID=1
    for sessionID = 2
        
        unitID = 3;
        figure
        uId = allWaveforms(sessionID).clusters(clusterID).ID(unitID)+1;
        depth = allWaveforms(sessionID).clusters(clusterID).depth_scaled(unitID);
        trajectory = allWaveforms(sessionID).trajectory;
        numChannels = size(trajectory,1);
        
        if sessionID == 4 || sessionID == 5
            currSpread = flipud(squeeze(trajectory(1:2:numChannels,:,uId)));
        else
            currSpread = squeeze(trajectory(1:2:numChannels,:,uId));
        end
        
        distFromSoma = [-0.1:0.02:0.1];
        time = linspace(0,82/30000*1000,82);
        colormap turbo
        subplot(2,1,1)
        imagesc(time(11:55),distFromSoma,currSpread(:,11:55,:))
        colorbar
        
        title(sprintf(['Cluster ',num2str(clusterID),' Session ',num2str(sessionID),' Unit ',num2str(uId-1),' Depth ',num2str(depth)]))
        set(gca,'box','off','TickDir','out')
        set(gca,'YDir','normal')
        ylabel('Distance from Soma (mm)')
        
        subplot(2,1,2)
        for channels = 1:11
            a = 40;
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

%% Figure 6C
figure
allTroughTime = [];
inverseSlopeTrough_below = [];
inverseSlopeTrough_above = [];
allBootstrappedTrough_above = [];
allBootstrappedTrough_below = [];
nboot = 500;
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
    else
        subplot(122)
        errorbar(nanmean(troughTime),distFromSoma,errorTraj,'horizontal','-','color',colors{clusterID},'Linewidth', 1);
    end
    allTroughTime = [allTroughTime; troughTime];
    hold on
    
    % v_above
    surrG = bootstrp(nboot,@nanmean, troughTime(:,6:11)); % smooth the troughTimes by creating more samples with a bootstrap
    
    v_above = nanmean(troughTime(:,6:11))';             % find the mean of troughTimes
    dist_above = distFromSoma(6:11)';                   % y axis channels
    X2(:,1) = dist_above;                               % Create X Array with the channels as the predictor
    X2(:,2) = 1;                                        % Include Column of ones
    [b] = regress(v_above, X2);                         % regress v_above as the response to the channels
    pred = X2*b;                                        % x axis points for inverse velocity above soma
    
    % plotting regression fit
    plot(pred,dist_above, '--','color',colors{clusterID}, 'Linewidth', 0.5);
    inverseSlopeTrough_above = [inverseSlopeTrough_above, b];
    
    % Bootstrap regression for error bars
    for n=1:nboot
        X2(:,1) = dist_above;
        X2(:,2) = 1;
        [bS] = regress(surrG(n,:)', X2);
        allBootstrappedTrough_above(clusterID,n,:) = bS; % slope per n of the bootstrapped data
    end
    
    %     %calc regression for each unit 1/v_above  I think this is calculated
    %     %correctly, but does not account for dead channels
    %
    %     Pred = [];
    %     fitTrough_above =[];
    %     X2(:,1) = dist_above;
    %     X2(:,2) = 1;
    %     for unitID = 1:size(AmpPerCluster(clusterID).data,3)
    %         B = regress(troughTime(unitID,6:11)',X2);
    %         Pred(unitID,:) = X2*B;
    %         fitTrough_above = [fitTrough_above, B];
    %     end
    %
    %     AmpPerCluster(clusterID).Bt_pred_above = Pred;             % Regression Line
    %     AmpPerCluster(clusterID).Bt_above = fitTrough_above;    % B
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % v_below
    b = [];
    surrG = bootstrp(nboot,@nanmean, troughTime(:,1:6));      % smooth the troughTimes by creating more samples with a bootstrap
    
    v_below = nanmean(troughTime(:,1:6))';                  % mean of trough times below soma
    dist_below = distFromSoma(1:6)';                        % distance below soma
    X2(:,1) = dist_below;                                   % Create X Array with the channels as the predictor
    X2(:,2) = 1;                                            % Include Column of ones
    [b] = regress(v_below, X2);                              % regress v_below as the response to the channels
    pred = X2*b;                                            % x axis points for inverse velocity regression line
    
    %plotting regression fit
    plot(pred,dist_below, '--','color',colors{clusterID}, 'Linewidth', 0.5); %plot regression line
    inverseSlopeTrough_below = [inverseSlopeTrough_below, b];
    
    % Bootstrap regression for error bars
    for n=1:nboot
        X2(:,1) = dist_below;
        X2(:,2) = 1;
        [bS] = regress(surrG(n,:)', X2);
        allBootstrappedTrough_below(clusterID,n,:) = bS;  % bootstrapped regressions
    end
    
    %     %calc regression for each unit 1/v below I think this is wrong
    %     Pred = [];
    %     fitTrough_below =[];
    %     X2(:,1) = dist_below;
    %     X2(:,2) = 1;
    %     for unitID = 1:size(AmpPerCluster(clusterID).data,3)        % For each unit
    %         v_below = troughTime(unitID,1:6)';                      % take the trough time
    %         B = regress(v_below,X2);                                % regress against channels
    %         Pred(unitID,:) = X2*B;                                  % regression line per unit
    %         fitTrough_below = [fitTrough_below, B];                 % stores the inverse slope of regression line
    %     end
    %
    %     AmpPerCluster(clusterID).pred_below = Pred;                 % Regression Line per unit
    %     AmpPerCluster(clusterID).slope_below = fitTrough_below;    % B = inverse slope of regression line
    
    ylim([-0.1 0.1])
    xlim([-0.1 0.2])
    grid on
    ylabel('Distance from Soma (mm)')
    xlabel('Time Relative to Soma (ms)')
    set(gca,'box','off','TickDir','out')
    set(gcf,'renderer','Painters')
end

title('Time of Waveform Trough per electrode channel')


%% Figure 5D Trough above vs trough below
figure
for clusterID = setdiff(1:9,[])
    
    peakErr = squeeze(nanstd(allBootstrappedTrough_above(clusterID,:,1),[],2));
    troughErr = squeeze(nanstd(allBootstrappedTrough_below(clusterID,:,1),[],2));
    errorbar(inverseSlopeTrough_below(1,clusterID), inverseSlopeTrough_above(1,clusterID),peakErr,peakErr,troughErr,troughErr,'o', 'Color',colors{clusterID})
    hold on
    grid on
    
end
axis equal
yline([1])
xline([0])
hold on
plot([-2:0.1:2],[2:-0.1:-2])

xlim([-1.15 0.5])
ylim([0 2])
ylabel('Slope of Trough Propagation Velocity towards Pia (mm/ms)')
xlabel('Slope of Trough Propagation Velocity away from Pia (mm/ms)')


%% Asymmetry Index Fig 5E
a = 1;
b = 1;
c = 0;
x0 = inverseSlopeTrough_below(1,:);
y0 = inverseSlopeTrough_above(1,:);

SI = abs(a*x0+b*y0+c)./sqrt(a.^2+b.^2);

SIBootTrough = allBootstrappedTrough_below(:,:,1);
SIBootPeak= allBootstrappedTrough_above(:,:,1);

SIBoot = abs(a*SIBootTrough+b*SIBootPeak+c)/sqrt(a^2+b^2);


troughErr = squeeze(nanstd(allBootstrappedTrough_below(:,:,1),[],2));
peakErr = squeeze(nanstd(allBootstrappedTrough_above(:,:,1),[],2));

SI = abs(a.*x0+b.*y0+c)./sqrt(a.^2+b.^2);
SI_err = abs(a*troughErr+b*peakErr+c)/sqrt(a^2+b^2);

figure
cnt = 0;

for clusterID = [1 6 8 2 7 3 9 5 4]
    cnt = cnt+1;
    errorbar(cnt,SI(clusterID),SI_err(clusterID),SI_err(clusterID),'o','color',colors{clusterID})
    hold on
end
xlim([0 10])

%[h,p,ci,stats] = ttest(SI(8,:),SI(1,:))

% 
% a = 1;
% b = 1;
% c = 0;
% % x0 = inverseSlopeTrough_below(1,:);
% % y0 = inverseSlopeTrough_above(1,:);
% x0 = allBootstrappedTrough_below(:,:,1);
% y0 = allBootstrappedTrough_above(:,:,1);
% 
% troughErr = squeeze(nanstd(allBootstrappedTrough_below(:,:,1),[],2));
% peakErr = squeeze(nanstd(allBootstrappedTrough_above(:,:,1),[],2));
% 
% SI = abs(a.*x0+b.*y0+c)./sqrt(a.^2+b.^2);
% SI_err = abs(a*troughErr+b*peakErr+c)/sqrt(a^2+b^2);


%% Significance of SI differences
clear ci_ind
clear ci_ind_low
clear ci_ind_upp
clear significant
cnt = 0;
cnt2 = 0;
for clu1 = [1 6 8 2 7 3 9 5 4]
    cnt2 = cnt2 +1;
    for clu2 = [1 6 8 2 7 3 9 5 4]


cnt = cnt +1;
sample1 = [SIBoot(clu1,:)];
sample2 = [SIBoot(clu2,:)];

% figure;
% histfit(sample1);
% hold on
% histfit(sample2);

    boot_diffs = sample1 - sample2;
    ci_ind = prctile(boot_diffs, [1, 99]);
     ci_ind_low(clu1,clu2) = ci_ind(1);
     ci_ind_upp(clu1,clu2) = ci_ind(2);
    
    if ci_ind_low(clu1,clu2) <= 0 && ci_ind_upp(clu1,clu2) >= 0
        significant(cnt2, cnt) = 0;
    else
        significant(cnt2, cnt) = 1;
    end

    end
    cnt = 0;
end
figure
imagesc(significant)
colormap hot
axis equal
colorbar

%%  Fig 5F
figure
cnt = 0;

for clusterID = [1 6 8 2 7 3 9 5 4]
    cnt = cnt+1;
    troughErr = squeeze(nanstd(allBootstrappedTrough_below(clusterID,:,1),[],2));
    peakErr = squeeze(nanstd(allBootstrappedTrough_above(clusterID,:,1),[],2));
    errorbar(cnt, inverseSlopeTrough_below(1,clusterID),troughErr,troughErr,'o', 'Color',colors{clusterID})
    
    hold on
    yline([0])
end
xlim([0 10])

%% stats for Fig 5F

for clusterID = 1:9
BootstrappedTrough = allBootstrappedTrough_below(clusterID,:,1);
CI(clusterID,:) = prctile(BootstrappedTrough,[5 95])
%figure
%histfit(BootstrappedTrough);
end



