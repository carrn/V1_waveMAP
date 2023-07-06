nSpikes = 10;
timeDur = 0.4;


for sessionID =1:5
    fprintf('\n%d.', sessionID);
    for clusterID = 1:5
        fprintf('%d',clusterID);
        templateIDpercluster = allWaveforms(sessionID).clusters(clusterID).ID;
        perUnitBurst = [];
        for unitID = 1:size(templateIDpercluster)
            allSpikeTimes = allWaveforms(sessionID).spike_timing(allWaveforms(sessionID).spike_ID==[templateIDpercluster(unitID)]);
            stimTimes = allWaveforms(sessionID).stim_on;
            preTime = 0;
            postTime = 1050;
            burstStart = [];
            for trial=1:length(stimTimes)
                currTrial(trial).spikes = [allSpikeTimes(allSpikeTimes >= stimTimes(trial)-preTime/1000 & ...
                    allSpikeTimes <= stimTimes(trial)+postTime/1000)]-stimTimes(trial);
                cnt = 1;
                if ~isempty(currTrial(trial).spikes)
                    forBurstTimes = currTrial(trial).spikes + preTime./1000;
                    BurstSpikes(cnt).T = forBurstTimes;
                    stimCondV(cnt) =  allWaveforms(sessionID).stim_cond(trial);
                  
                    cnt = cnt + 1;
                else
                    BurstSpikes(cnt).T = [];
                    stimCondV(cnt) =  allWaveforms(sessionID).stim_cond(trial);
                    cnt = cnt + 1;
                end
                
            end
                
            end
            
            actualConds = allWaveforms(sessionID).stim_cond;
            conds = unique(allWaveforms(sessionID).stim_cond);
            burstStartPerCondition = [];
            for j=1:length(conds)
                
                burstStartPerCondition(j) = nanmean(burstStart(actualConds == conds(j)));
            end
            fprintf('.');
            perUnitBurst(unitID,:) = burstStartPerCondition;
            unitBurst = nanmedian(nanmin(perUnitBurst,[],2)-preTime./1000);
            
        end
    end
end
%%
% Spike.T = allSpikeTimes ; % Load spike times here.
% %Spike.C = ---- ; % Load spike channels here.
%  N = 10; % Set N
%  ISI_N = 0.10; % Set ISI_N threshold [sec]
% % % Run the detector
%  [Burst Spike.N] = BurstDetectISIn( Spike, N, ISI_N );
% %
% % % Plot results
%  figure, hold on
% %
% % % Order y-axis trials by firing rates
%  tmp = zeros( 1, max(Spike.C)-min(Spike.C) );
%  for c = min(Spike.C):max(Spike.C)
%  tmp(c-min(Spike.C)+1) = length( find(Spike.C==c) );
% end
% [tmp ID] = sort(tmp);
% OrderedChannels = zeros( 1, max(Spike.C)-min(Spike.C) );
% for c = min(Spike.C):max(Spike.C)
% OrderedChannels(c-min(Spike.C)+1) = find( ID==c-min(Spike.C)+1 );
% end

%
% % Raster plot
% plot( Spike.T, OrderedChannels(1+Spike.C), 'k.' )
% % set( gca, 'ytick', (min(Spike.C):max(Spike.C))+1, 'yticklabel', ...
% % ID-min(ID)+min(Spike.C) ) % set yaxis to channel ID
%
% % Plot times when bursts were detected
% ID = find(Burst.T_end<max(Spike.T));
% Detected = [];
% for i=ID
% Detected = [ Detected Burst.T_start(i) Burst.T_end(i) NaN ];
% end
% plot( Detected, 128*ones(size(Detected)), 'r', 'linewidth', 4 )
%
% xlabel 'Time [sec]'
% ylabel 'Channel'

burstV = [];
for clusterID = 1:5
    temp = [];
    for sessionID = 1:5
        temp = [temp allWaveforms(sessionID).clusters(clusterID).perUnitBurst];
    end
    burstV(clusterID).V = temp;
    fprintf('\n %d,%3.3f', clusterID, nanmedian(temp))
end
