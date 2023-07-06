
%avgPSTH = [];

sessionID = 1;
%for sessions =1:3;
clusterID = 3;
%for iii = 1:size(sessions)

for sessionID = 1:5
    fprintf('\n%d.', sessionID);
        allPSTHs = [];
        avgPSTH = [];
        
        for unitID = 1:length(allWaveforms(sessionID).avg_waveformID)
            currWaveform = allWaveforms(sessionID).avg_waveformID(unitID);
            allSpikeTimes = allWaveforms(sessionID).spike_timing(allWaveforms(sessionID).spike_ID==[avg_waveformID(unitID)]);
            stimTimes = allWaveforms(sessionID).stim_on;
            
            currData = [];
            preTime = 50;
            postTime = 1050;
            spkMatrix = zeros(length(stimTimes),preTime+postTime+1);
            
            g = normpdf([-0.2:0.001:0.2],0,0.015);
            psthv = [];
            allTimes = [];
            
            try
                for j=1:length(stimTimes)
                    currData(j).spikes = [allSpikeTimes(allSpikeTimes >= stimTimes(j)-preTime/1000 & ...
                    allSpikeTimes <= stimTimes(j)+postTime/1000)]-stimTimes(j);
                    
                    currTimes = ceil(1000*currData(j).spikes + preTime);
                    spkMatrix(j,currTimes) = 1;
                    psthv(j,:) = conv(spkMatrix(j,:),g,'same');
                    allTimes = [allTimes; currTimes];
                end
            catch error
                spkMatrix = zeros(length(stimTimes),preTime+postTime+1);
                for j=1:length(stimTimes)
                    currData(j).spikes = [allSpikeTimes(allSpikeTimes >= stimTimes(j)-preTime/1000 & ...
                        allSpikeTimes <= stimTimes(j)+postTime/1000)]-stimTimes(j);
                    currTimes = ceil(1000*currData(j).spikes + preTime+1);
                    spkMatrix(j,currTimes) = 1;
                    psthv(j,:) = conv(spkMatrix(j,:),g,'same');
                    allTimes = [allTimes; currTimes];
                end
            end
            
            binCenters = [0:10:preTime+postTime];
            Y = histc(allTimes,binCenters);
            %figure
            %plot(binCenters-preTime, Y./(size(psthv,1)*0.01),'r-');
            %hold on
            %plot([-preTime:postTime],nanmean(psthv));
            avgPSTH = [avgPSTH; nanmean(psthv)];
            
            actualConds = allWaveforms(sessionID).stim_cond;
            conds = unique(allWaveforms(sessionID).stim_cond);
            psthPerCondition = [];
            
            for j=1:length(conds)
                psthPerCondition(j,:) = nanmean(psthv(actualConds == conds(j),:));
            end
            
            fprintf('%d',allWaveforms(sessionID).avg_waveformID(unitID));
            allPSTHs(unitID,:,:) = psthPerCondition;
  
        end
        %keyboard
        
        %figure
        %plot(mean(avgPSTH))
        allWaveforms(sessionID).avgPSTH = avgPSTH;
        allWaveforms(sessionID).psthPerCondition = allPSTHs;

end
