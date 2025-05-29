
%avgPSTH = [];

sessionID =1;
%for sessions =1:3;
clusterID = 3;
%for iii = 1:size(sessions)
nSpikes = 10;
timeDur = 0.2; % [Seconds]

for sessionID = 1:5
    fprintf('\n%d.', sessionID);
    for clusterID = 1:max(cluster)
        fprintf('%d',clusterID);
        templateIDpercluster = allWaveforms(sessionID).clusters(clusterID).ID;
        allPSTHs = [];
        avgPSTH = [];
        perUnitBurst = [];
        for unitID = 1:size(templateIDpercluster)
            burstStartPerCondition = [];
            allSpikeTimes = allWaveforms(sessionID).spike_timing(allWaveforms(sessionID).spike_ID==[templateIDpercluster(unitID)]);
            stimTimes = allWaveforms(sessionID).stim_on;
            
            currData = [];
            preTime = 0;
            postTime = 1050;
            spkMatrix = zeros(length(stimTimes),preTime+postTime+1);
            
            g = normpdf([-0.2:0.001:0.2],0,0.015);
            psthv = [];
            allTimes = [];
            burstStart = [];
            try
                for j=1:length(stimTimes)
                    currData(j).spikes = [allSpikeTimes(allSpikeTimes >= stimTimes(j)-preTime/1000 & ...
                        allSpikeTimes <= stimTimes(j)+postTime/1000)]-stimTimes(j);
                    
                    if ~isempty(currData(j).spikes)
                        BurstSpikes = [];
                        forBurstTimes = currData(j).spikes + preTime./1000;
                        BurstSpikes.T = forBurstTimes;
                        burst = BurstDetectISIn(BurstSpikes, nSpikes, timeDur);
                        
                        if isempty(burst.T_start)
                            burstStart(j) = NaN;
                        else
                            burstStart(j) = burst.T_start(1);
                        end
                        
                    else
                        burstStart(j) = NaN;
                    end
                    
                end
            catch error
                spkMatrix = zeros(length(stimTimes),preTime+postTime+1);
                for j=1:length(stimTimes)
                    currData(j).spikes = [allSpikeTimes(allSpikeTimes >= stimTimes(j)-preTime/1000 & ...
                        allSpikeTimes <= stimTimes(j)+postTime/1000)]-stimTimes(j);
                    
                    if ~isempty(currData(j).spikes)
                        forBurstTimes = currData(j).spikes + preTime./1000;
                        BurstSpikes.T = forBurstTimes;
                        burst = BurstDetectISIn(BurstSpikes, nSpikes, timeDur);
                        
                        if isempty(burst.T_start)
                            burstStart(j) = NaN;
                        else
                            burstStart(j) = burst.T_start(1);
                        end
                    else
                        burstStart(j) = NaN;
                    end
                    
                    
                end
            end
            %keyboard
            
            binCenters = [0:10:preTime+postTime];
            Y = histc(allTimes,binCenters);
            
            
            actualConds = allWaveforms(sessionID).stim_cond;
            conds = unique(allWaveforms(sessionID).stim_cond);
            
            for j=1:length(conds)
                burstStartPerCondition(j) = nanmean(burstStart(actualConds == conds(j)));
            end
            fprintf('.');
            
            perUnitBurst(unitID,:) = burstStartPerCondition;
            allWaveforms(sessionID).clusters(clusterID).perUnitBurst(unitID) = nanmedian(nanmin(perUnitBurst,[],2)-preTime./1000);
            
        end
        
        
        
    end
end
%%
%
% figure; hist(min(perUnitBurst,[],2)-preTime./1000)
% %imagesc(perUnitBurst)
% figure; imagesc(perUnitBurst)
% figure; hist(min(perUnitBurst,[],2)-preTime./1000)
% nanmedian(nanmin(perUnitBurst,[],2)-preTime./1000)
%
%

burstV = [];
for clusterID = 1:max(cluster)
    temp = [];
    loc = [];
    for sessionID = 1:5
        temp = [temp allWaveforms(sessionID).clusters(clusterID).perUnitBurst];
        loc = [loc allWaveforms(sessionID).clusters(clusterID).depth_bins'];
    end
    burstV(clusterID).V = temp;
    burstV(clusterID).loc = loc;
    fprintf('\n %d,%3.3f', clusterID, nanmedian(temp))
end


%% Plotting
%colors = {[0 0.3 0.6],[1 0.5 0.2],[0.6 0 0],[0.7 0.5 0],[0 0.7 0.6];};
colors = clusterColors;
clusterName = {'1','2','3','4','5','6','7','8','9','stim on'};
fig = figure(1);
for clusterID = 1:max(cluster)
    
    
    hold on
    [f, x] = ksdensity(burstV(clusterID).V);
    plot(x,f,'color',colors{clusterID},'Linewidth',1)
    
end
xline([0])
legend(clusterName)

xlabel('Time [s]')
ylabel('Number of Bursts')
title('Estimated Burst Start [10 spikes in 325 ms]')
%saveas(fig, 'Latency_neg.pdf','pdf')

%% Plotting
%colors = {[0 0.3 0.6],[1 0.5 0.2],[0.6 0 0],[0.7 0.5 0],[0 0.7 0.6];};
colors = clusterColors;
clusterName = {'1','2','3','4','5','6','7','8','9','stim on'};
fig = figure(1);
layerID = 3;
for clusterID = 1:max(cluster)
    
    
    hold on
    [f, x] = ksdensity(burstV(clusterID).V(burstV(clusterID).loc == layerID));
    plot(x,f,'color',colors{clusterID},'Linewidth',1)
    
end
xline([0])
legend(clusterName)
set(gcf,'renderer','Painters')
xlabel('Time [s]')
ylabel('Number of Bursts')
title('Estimated Burst Start [10 spikes in 325 ms]')
%saveas(fig, 'Latency_neg.pdf','pdf')
%%
%hold off

set(gca,'box','off','TickDir','out') 
print -depsc -tiff -r300 -painters LatencyforPoster.eps
