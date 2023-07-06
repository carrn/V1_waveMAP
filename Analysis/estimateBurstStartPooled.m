
%avgPSTH = [];

sessionID =1;
%for sessions =1:3;
clusterID = 3;
%for iii = 1:size(sessions)
nSpikes = 10;
timeDur = 0.15;

for sessionID = 1:5
    fprintf('\n%d.', sessionID);
    for clusterID = 1:5
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
            cnt = 1;
            
            for j=1:length(stimTimes)
                currData(j).spikes = [allSpikeTimes(allSpikeTimes >= stimTimes(j)-preTime/1000 & ...
                    allSpikeTimes <= stimTimes(j)+postTime/1000)]-stimTimes(j);
                
                if ~isempty(currData(j).spikes)
                    forBurstTimes = currData(j).spikes + preTime./1000;
                    BurstSpikes(cnt).T = forBurstTimes;
                    stimCondV(cnt) =  allWaveforms(sessionID).stim_cond(j);
                  
                    cnt = cnt + 1;
                else
                    BurstSpikes(cnt).T = [];
                    stimCondV(cnt) =  allWaveforms(sessionID).stim_cond(j);
                    cnt = cnt + 1;
                end
                
            end
            
            %keyboard
            uniqueConds = unique(stimCondV);
            for cI=1:length(uniqueConds)
                currSpikes = BurstSpikes(stimCondV == uniqueConds(cI));
                
                BurstSpikeData.T = [];
                BurstSpikeData.C = [];
                hasSpikes = false;
                for trialId = 1:length(currSpikes)
                    if ~isempty(currSpikes(trialId).T')
                        BurstSpikeData.T = [BurstSpikeData.T currSpikes(trialId).T'];
                        BurstSpikeData.C = [BurstSpikeData.C trialId*ones(1,length(currSpikes(trialId).T))];
                        hasSpikes = true;
                    else
                    
                    end
                end
                
                BurstSpikeData;
                if hasSpikes
                    burst = BurstDetectISIn(BurstSpikeData, nSpikes, timeDur);
                    if isempty(burst.T_start)
                        burstStart(cI) = NaN;
                    else
                        burstStart(cI) = burst.T_start(1);
                    end
                else
                    burstStart(cI) = NaN;
                end
            end
            
        
            
            fprintf('.');
            
            %allPSTclcHs(unitID,:,:) = psthPerCondition;
            perUnitBurst(unitID,:) = burstStart;
            allWaveforms(sessionID).clusters(clusterID).perUnitBurst(unitID) = nanmedian(nanmin(perUnitBurst,[],2)-preTime./1000);
        end
        %keyboard
        
        %figure
        %plot(mean(avgPSTH))
        %allWaveforms(sessionID).clusters(clusterID).avgPSTH = avgPSTH;
        %allWaveforms(sessionID).clusters(clusterID).psthPerCondition = allPSTHs;
        %allWaveforms(sessionID).clusters(clusterID).perUnitBurst = nanmedian(nanmin(perUnitBurst,[],2)-preTime./1000);
        %       end
        %keyboard
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
    for nSession = 1:5
        temp = [temp allWaveforms(nSession).clusters(unitId).perUnitBurst];
    end
    burstV(unitId).V = temp;
    fprintf('\n %d,%3.3f', unitId, nanmedian(temp))
end