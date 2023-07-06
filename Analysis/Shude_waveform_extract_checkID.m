clc;        % Clear Command Window
close all;  % Close all figures
clear all;  % Erase all existing variables
workspace;  % Make sure the workspace panel is showing

% This program requires:
% - folder containing data structures
% - function reshape_min_waveforms()
% - function reshape_max_waveforms()
%% Parsing for data structures folder
% Parse through folder for waveform templates and associated data
% Creates struct containing this information
matFiles = dir('*templates.mat');
% Initialize
allWaveforms = struct([]);
p = length(matFiles);
figure
%% Parsing through folder for waveforms
for sessionID = 1:p
    % Load current datastructure
    avg_waveform = [];
    poor = [];
    good = [];
    depth_pos = [];
    depth_neg = [];
    depth_all = []; 
    pos = [];
    neg = [];
    align_all = [];
    align_pos = [];
    align_neg = [];
    norm = [];
    norm_pos = [];
    norm_neg = [];
    ID_neg = [];
    ID_pos = [];
    ID_all = [];
    

    matFilename = fullfile(pwd, matFiles(sessionID).name);
    s = load(matFilename);
    fprintf('\n %d:',sessionID);
    allWaveforms(sessionID).templateID = s.templates.templateID;
    allWaveforms(sessionID).template = s.templates.template_waves;
    allWaveforms(sessionID).snr = s.templates.template_snr;
    allWaveforms(sessionID).depth = s.templates.template_depth_relativetolayer4;
    allWaveforms(sessionID).layerId = s.templates.template_layerID;
    allWaveforms(sessionID).spike_timing = s.templates.spike_timing;
    allWaveforms(sessionID).spike_ID = s.templates.spike_templateID;
    allWaveforms(sessionID).stim_on = s.templates.stimulus_onset;
    allWaveforms(sessionID).dur = s.templates.stimulus_duration;
    allWaveforms(sessionID).stim_cond = s.templates.stimulus_conditionID;
    

    %% Plotting waveforms
    [~,idx] = sort(allWaveforms(sessionID).templateID);
    validChans = [1:384];
    

    for unitID = 1:size(idx,1)
%% For each template - extract the maximum waveform
        X = squeeze(allWaveforms(sessionID).template(idx(unitID),validChans,:));
        X = X - repmat(nanmean(X,2),[1 size(X,2)]);
        ampls = max(X,[],2)-min(X,[],2);
        [~,maxLoc] = max(ampls);
        % maximum waveform from template
        X = X(maxLoc,:);
        avg_waveform = [avg_waveform; X];
        ID = [allWaveforms(sessionID).templateID(idx(unitID)) , sessionID];
        ID_all = [ID_all ; ID];
%% Sort out bad snr values, ie. low snrs or snr of -1 : too few corresponding spikes
        if allWaveforms(sessionID).snr(unitID) == -1% | allWaveforms(sessionID).snr(unitID) > 1 %| abs(X(1)) > 45 | abs(X(52)) > 45
            poor = [poor; ID];
        else
            good = [good; ID];
            depth = allWaveforms(sessionID).depth(idx(unitID));
            %D = [allWaveforms(sessionID).templateID(idx(unitID)) , sessionID];
            %hold on
            %plot(X)

            % Sort out positive spiking
            [y1, t1] = max(X);
            [y2, t2] = min(X);
            TtP = y1-y2;
            Slope = (y1-y2)/(t1-t2);
            
            SEM = std(X)/sqrt(length(X));
            X = X; %./abs(y1-y2);
            %temp = rescale(temp,-1,1);
            %temp = (temp-mean(temp))./std(temp);
            
            norm = [norm; X]; 
            
%% Positive spiking 
            if abs(y1)> abs(y2) %if max peak occurs before min peak = pos spike
                %Reshape pos spiking waveforms
                pos = [pos; X];
                norm_pos = [norm_pos; X];
                try
                    X = reshape_max_waveforms(X);
                    
                    align_pos = [align_pos; X];
                    depth_pos = [depth_pos; depth];
                    ID_pos = [ID_pos; ID];
                catch
                    actionmsg = sprintf('Unable to resolve %d, skipped.',unitID)
                end
%% Negative Spiking
            elseif abs(y1) < abs(y2) %if max peak occurs after min peak = neg spike
                neg = [neg; X];
                norm_neg = [norm_neg; X];
                %Reshape neg spiking waveforms
                try
                    X = reshape_min_waveforms(X);
                    align_neg = [align_neg; X];
                    depth_neg = [depth_neg; depth];
                    ID_neg = [ID_neg; ID];
                catch
                    actionmsg = sprintf('Unable to resolve %d, skipped.',unitID)
                end               
            end
        end      
    end
%% store reshaped waveforms
    %align_all = [align_neg; align_pos]; 
    %ID_all = [ID_neg; ID_pos];
    %allWaveforms(j).good = [good];
    %allWaveforms(j).poor = [poor];

    
%% normalized
    currTraj2=align_neg';
    normalizedwaveformsneg = bsxfun(@rdivide,currTraj2,max(abs(currTraj2)));
    
    currTraj1=align_pos';
    normalizedwaveformspos = bsxfun(@rdivide,currTraj1,max(abs(currTraj1)));
    
    currTraj3=align_all';
    normalizedwaveforms = bsxfun(@rdivide,currTraj3,max(abs(currTraj3)));
    
    allWaveforms(sessionID).avg_waveform = avg_waveform;
    allWaveforms(sessionID).norm_neg = normalizedwaveformsneg';
    allWaveforms(sessionID).depth_neg = depth_neg;
    allWaveforms(sessionID).ID_neg = ID_neg;
    allWaveforms(sessionID).norm_pos = normalizedwaveformspos';
    allWaveforms(sessionID).depth_pos = depth_pos;
    allWaveforms(sessionID).ID_pos = ID_pos;
    allWaveforms(sessionID).norm_all = normalizedwaveforms';
    allWaveforms(sessionID).ID_all = ID_all;
    
    
    %% normalized waveform figure
    t = [0:0.03333:1.73]; % Time samples at 30000 Hz, 52 samples
    subplot(2,1,1)
    hold on
    title(sprintf(['All Sessions']))
    ylabel('Normalized Amplitude')
    xlabel('Time [ms]')
    plot(t, normalizedwaveformspos,'color',[0.2275    0.5961    0.8392 0.5])
    subplot(2,1,2)
    ylabel('Normalized Amplitude')
    xlabel('Time [ms]')
    plot(t, normalizedwaveformsneg,'color',[ 0.8902    0.5176    0.5176 0.5])
    
%     %% laminar figure
%     subplot(2,1,2)
%     hold on
%     for m = 1:size(allWaveforms(sessionID).norm_neg,1)
%         d = allWaveforms(sessionID).norm_neg(m,:)+allWaveforms(sessionID).depth_neg(m);
%         %depth_all = [depth_all ; d];
%         plot(d,'color',[ 0.8902    0.5176    0.5176])
%     end
%     
%     for n = 1:size(allWaveforms(sessionID).norm_pos,1)
%         d = allWaveforms(sessionID).norm_pos(n,:)+allWaveforms(sessionID).depth_pos(n);
%         plot(d,'color',[0.2275    0.5961    0.8392])
%         
%     end
    allWaveforms(sessionID).depth_all = [depth_neg; depth_pos];
end
%% concatenating
align_neg = cat(1,allWaveforms(1:p).norm_neg); 
align_pos = cat(1,allWaveforms(1:p).norm_pos); 
%align_all = cat(1,allWaveforms(1:p).norm_all);

%depth_all = cat(1,allWaveforms(1:p).depth_all);
depth_neg = cat(1,allWaveforms(1:p).depth_neg);
depth_pos = cat(1,allWaveforms(1:p).depth_pos);


ID_neg = cat(1,allWaveforms(1:p).ID_neg);
ID_pos = cat(1,allWaveforms(1:p).ID_pos);
%ID_all = cat(1,allWaveforms(1:p).ID_all);
% %% aligned and normalized waveforms
% figure 
% hold on
% plot(align_neg')
% plot(align_pos')
format long
functional_data = cat(2, [allWaveforms(1).spike_timing] , [allWaveforms(1).spike_ID]);


%% Saving
save('normalizedwaveforms2.mat','align_all');
save('normalizednegwaveforms2.mat','align_neg');
save('normalizedposwaveforms2.mat','align_pos');

save('depth2.mat','depth_all');
save('depth_neg2.mat','depth_neg');
save('depth_pos2.mat','depth_pos');

save('ID_neg2.mat', 'ID_neg', 'sessionID');
save('ID_pos2.mat', 'ID_pos', 'sessionID');
save('ID2.mat', 'ID_all', 'sessionID');

