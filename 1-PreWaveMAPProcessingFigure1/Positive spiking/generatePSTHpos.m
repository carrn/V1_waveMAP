%% Pos clusters

for sessionID = 1:5
    for clusterID = 1:5
        templateIDpercluster = allWaveforms(sessionID).posclusters(clusterID).ID;
        allPSTHs = [];
        avgPSTH = [];
        for unitID = 1:size(templateIDpercluster)
            
            allSpikeTimes = allWaveforms(sessionID).spike_timing(allWaveforms(sessionID).spike_ID==[templateIDpercluster(unitID)]);
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
            disp(unitID)
            
            allPSTHs(unitID,:,:) = psthPerCondition;
  
        end
        %keyboard
        
        %figure
        %plot(mean(avgPSTH))
        allWaveforms(sessionID).posclusters(clusterID).avgPSTH = avgPSTH;
        allWaveforms(sessionID).posclusters(clusterID).psthPerCondition = allPSTHs;
%       end
    end
end

