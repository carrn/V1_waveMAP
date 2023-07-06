
%avgPSTH = [];

sessionID =1;
%for sessions =1:3;
clusterID = 3;
%for iii = 1:size(sessions)
nSpikes = 10;
timeDur = 0.4;

for sessionID = 1:5
    fprintf('\n%d.', sessionID);
    for clusterID = 1:5
        fprintf('%d',clusterID);
        templateIDpercluster = allWaveforms(sessionID).clusters(clusterID).ID;
        allPSTHs = [];
        avgPSTH = [];
        
        for unitID = 1:size(templateIDpercluster)
            burstStartPerCondition = [];
            % all Spike times for this unit
            allSpikeTimes = allWaveforms(sessionID).spike_timing(allWaveforms(sessionID).spike_ID==[templateIDpercluster(unitID)]);
            
            stimTimes = allWaveforms(sessionID).stim_on;
            perUnitBurst = [];
            currData = [];
            currSpikes = [];
            preTime = 0;
            postTime = 1050;
            spkMatrix = zeros(length(stimTimes),preTime+postTime+1);
            
            g = normpdf([-0.2:0.001:0.2],0,0.015);
            psthv = [];
            allTimes = [];
            burstStart = [];
            BurstSpikes = [];
            stimCondV = [];
            cnt = 1;
            try
                
                for trial=1:length(stimTimes) % 1440 trials
                    currData(trial).spikes = [allSpikeTimes(allSpikeTimes >= stimTimes(trial)-preTime/1000 & ...
                        allSpikeTimes <= stimTimes(trial)+postTime/1000)]-stimTimes(trial);
                    
                    if ~isempty(currData(trial).spikes) % if not empty
                        forBurstTimes = currData(trial).spikes + preTime./1000; % get spike times per trial
                        BurstSpikes(cnt).T = forBurstTimes;
                        stimCondV(cnt) =  allWaveforms(sessionID).stim_cond(trial); % stim condition for the spike times
                        cnt = cnt + 1;
                    end
                    
                end
                
                %keyboard
                uniqueConds = unique(stimCondV); % should be less than 144,
                for cI=1:length(uniqueConds)
                    currSpikes = BurstSpikes(stimCondV == uniqueConds(cI));
                    
                    BurstSpikeData.T = [];
                    BurstSpikeData.C = [];
                    for trialId = 1:length(currSpikes)
                        BurstSpikeData.T = [BurstSpikeData.T currSpikes(trialId).T'];
                        BurstSpikeData.C = [BurstSpikeData.C trialId*ones(1,length(currSpikes(trialId).T))];
                    end
                    burst = BurstDetectISIn(BurstSpikeData, nSpikes, timeDur);
                    if isempty(burst.T_start)
                        burstStart(cI) = NaN;
                    else
                        burstStart(cI) = burst.T_start(1);
                    end
                end
               keyboard
            catch error
                spkMatrix = zeros(length(stimTimes),preTime+postTime+1);
                for trial=1:length(stimTimes)
                    currData(trial).spikes = [allSpikeTimes(allSpikeTimes >= stimTimes(trial)-preTime/1000 & ...
                        allSpikeTimes <= stimTimes(trial)+postTime/1000)]-stimTimes(trial);
                    
                    if ~isempty(currData(trial).spikes)
                        forBurstTimes = currData(trial).spikes + preTime./1000;
                        BurstSpikes(cnt).T = forBurstTimes;
                        stimCondV(cnt) =  allWaveforms(sessionID).stim_cond(trial);
                        cnt = cnt + 1;
                    end
                    
                end
               
                
                uniqueConds = unique(stimCondV);
                for cI=1:length(uniqueConds)
                    currSpikes = BurstSpikes(stimCondV == uniqueConds(cI));
                    
                    BurstSpikeData.T = [];
                    BurstSpikeData.C = [];
                    for trialId = 1:length(currSpikes)
                        BurstSpikeData.T = [BurstSpikeData.T currSpikes(trialId).T'];
                        BurstSpikeData.C = [BurstSpikeData.C trialId*ones(1,length(currSpikes(trialId).T))];
                    end
                    burst = BurstDetectISIn(BurstSpikeData, nSpikes, timeDur);
                    if isempty(burst.T_start)
                        burstStart(cI) = NaN;
                    else
                        burstStart(cI) = burst.T_start(1);
                    end
                end
                
                
            end

            fprintf('.');
            
            %allPSTHs(unitID,:,:) = psthPerCondition;
            perUnitBurst(unitID,:) = burstStart;
            allWaveforms(sessionID).clusters(clusterID).perUnitBurstPooled(unitID) = nanmedian(nanmin(perUnitBurst,[],2)-preTime./1000);
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
        temp = [temp allWaveforms(nSession).clusters(unitId).perUnitBurstPooled];
    end
    burstV(unitId).V = temp;
    fprintf('\n %d,%3.3f', unitId, nanmedian(temp))
end