
%avgPSTH = [];

sessionID =1;
%for sessions =1:3;
clusterID = 3;
%for iii = 1:size(sessions)
nSpikes = 4;
timeDur = 0.325; % [Seconds]

for sessionID = 1:5
    fprintf('\n%d.', sessionID);
    for clusterID = 1:5
        fprintf('%d',clusterID);
        templateIDpercluster = allWaveforms(sessionID).posclusters(clusterID).ID;
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
            allWaveforms(sessionID).posclusters(clusterID).perUnitBurst(unitID) = nanmedian(nanmin(perUnitBurst,[],2)-preTime./1000);
            
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
for unitId = 1:5
    temp = [];
    loc = [];
    for nSession = 1:5
        temp = [temp allWaveforms(nSession).posclusters(unitId).perUnitBurst];
        loc = [loc allWaveforms(nSession).posclusters(unitId).depthBinCluster'];
    end
    burstV(unitId).V = temp;
    burstV(unitId).loc = loc;
    fprintf('\n %d,%3.3f', unitId, nanmedian(temp))
end


%% Plotting
%colors = {[0 0.3 0.6],[1 0.5 0.2],[0.6 0 0],[0.7 0.5 0],[0 0.7 0.6];};

colors = {[0.8549    0.9098    0.9608],[0.7294    0.8392    0.9176],[0.5333    0.7451    0.8627],[0.3255    0.6157    0.8000],[0.1647    0.4784    0.7255];};
alpha = 0.2;
lines = {'-','--','-.',':','-'};
linew = {3 , 1, 1 ,1, 1};
clusterName = {'6','7','8','9','10','stim on'};
fig = figure(1);
for clusterID = 1:5
    
try
hold on
[f, x] = ksdensity(burstV(clusterID).V);
plot(x,f, 'color', colors{clusterID},'Linestyle', lines{clusterID},'LineWidth',linew{clusterID})
catch
    disp('Error')
end

end

%saveas(fig, 'Latency_neg.pdf','pdf')
%%
%hold off
xline([0])
legend(clusterName)

xlabel('Time [s]')
ylabel('Number of Bursts')
title('Estimated Burst Start [10 spikes in 325 ms]')
set(gca,'box','off','TickDir','out')  
print -depsc -tiff -r300 -painters LatencyforPosterpos.eps
