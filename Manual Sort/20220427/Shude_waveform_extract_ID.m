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
%% Parsing through folder for waveforms
for sessionID = 1:p
    %% Initialize dynamic arrays
    avg_waveform = [];
    avg_waveformID =[];
    poor = [];
    poorID = [];
    good = [];
    goodID = [];
    pos = [];
    posID = [];
    align_pos = [];
    ID_pos = [];
    depth_pos = [];
    neg = [];
    negID = [];
    align_neg = [];
    ID_neg = [];
    depth_neg = [];
    align_all = [];
    depth_all = [];
    
    %% Load current datastructure
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
    allWaveforms(sessionID).stim_cond = s.templates.stimulus_conditionID;
    allWaveforms(sessionID).dur = s.templates.stimulus_duration;

    %% Plotting waveforms
    [~,idx] = sort(allWaveforms(sessionID).templateID);
    validChans = [1:384];
    fig = figure;

    for unitID = 1:size(idx,1)
%% For each template - extract the maximum waveform
        currWave = squeeze(allWaveforms(sessionID).template(idx(unitID),validChans,:));
        currWave = currWave - repmat(nanmean(currWave,2),[1 size(currWave,2)]);  % mean subtracted
        ampls = max(currWave,[],2)-min(currWave,[],2);             % amplitudes across channels
        [~,maxLoc] = max(ampls);                                   % index of max amplitude
        currWave = currWave(maxLoc,:);                             % maximum waveform from template
        currID = [allWaveforms(sessionID).templateID(idx(unitID)) , sessionID];
        
        % Store all waveforms and IDs
        avg_waveform = [avg_waveform; currWave];
        avg_waveformID = [avg_waveformID ; currID];
%% Sort out bad snr values, ie. low snrs or snr of -1 : too few corresponding spikes
        if allWaveforms(sessionID).snr(idx(unitID)) == -1 | allWaveforms(sessionID).snr(idx(unitID)) > 2 | abs(currWave(sessionID)/max(abs(currWave))) > 0.5% | abs(X(52)) > 30
            poor = [poor; currWave];
            poorID = [poorID ; currID];
        else
            
            good = [good; currWave];
            goodID = [goodID; currID];
            depth = allWaveforms(sessionID).depth(idx(unitID));

            %% Sort out positive spiking
            [y1, t1] = max(currWave);      % peak
            [y2, t2] = min(currWave);      % trough
            TtP = y1-y2;                   % trough to peak
            Slope = (y1-y2)/(t1-t2);
                
%% Positive spiking 
            if abs(y1)> abs(y2) %if max peak occurs before min peak = pos spike
                pos = [pos; currWave];
                posID = [posID; currID];
                %Reshape pos spiking waveforms
                try
                    currWave = reshape_max_waveforms(currWave);
                    align_pos = [align_pos; currWave];
                    depth_pos = [depth_pos; depth];
                    ID_pos = [ID_pos; currID];
                catch
                    actionmsg = sprintf('Unable to resolve %d, skipped.',unitID)
                end
%% Negative Spiking
            elseif abs(y1) < abs(y2) %if max peak occurs after min peak = neg spike
                neg = [neg; currWave];
                negID = [negID; currID];
                %Reshape neg spiking waveforms
                try
                    currWave = reshape_min_waveforms(currWave);
                    align_neg = [align_neg; currWave];
                    depth_neg = [depth_neg; depth];
                    ID_neg = [ID_neg; currID];
                catch
                    actionmsg = sprintf('Unable to resolve %d, skipped.',unitID)
                end               
            end
        end      
    end
%% store reshaped waveforms
     align_all = [align_neg; align_pos]; 
     ID_all = [ID_neg; ID_pos];
 
%% normalize between 1 and -1
    currTraj1=align_neg';
    normalizedwaveformsneg = bsxfun(@rdivide,currTraj1,max(abs(currTraj1)));
    
    currTraj2=align_pos';
    normalizedwaveformspos = bsxfun(@rdivide,currTraj2,max(abs(currTraj2)));
    
    currTraj3=align_all';
    normalizedwaveforms = bsxfun(@rdivide,currTraj3,max(abs(currTraj3)));

    allWaveforms(sessionID).avg_waveform = avg_waveform;
    allWaveforms(sessionID).avg_waveformID = avg_waveformID;
    allWaveforms(sessionID).align_neg = normalizedwaveformsneg';
    allWaveforms(sessionID).depth_neg = depth_neg;
    allWaveforms(sessionID).ID_neg = ID_neg;
    allWaveforms(sessionID).align_pos = normalizedwaveformspos';
    allWaveforms(sessionID).depth_pos = depth_pos;
    allWaveforms(sessionID).ID_pos = ID_pos;
    allWaveforms(sessionID).align_all = normalizedwaveforms';
    allWaveforms(sessionID).ID_all = ID_all;
    
    
    
    %% normalized waveform figure
    t = [0:0.03333:1.73]; % Time samples at 30000 Hz, 52 samples
    subplot(2,1,1)
    hold on
    title(sprintf(['S',num2str(sessionID),' Waveforms']))
    ylabel('Normalized Amplitude')
    xlabel('Time [ms]')
    plot(t, normalizedwaveformsneg,'color',[ 0.8902    0.5176    0.5176])
    plot(t, normalizedwaveformspos,'color',[0.2275    0.5961    0.8392])
   
    
    %% laminar figure
    %t = t/10;
    subplot(2,1,2)
    ylabel('Distance from Layer 4 [um]')
    hold on
    for m = 1:size(allWaveforms(sessionID).align_neg,1)
        d = allWaveforms(sessionID).align_neg(m,:)+allWaveforms(sessionID).depth_neg(m);
        plot(t,d,'color',[ 0.8902    0.5176    0.5176])
    end
    
    for n = 1:size(allWaveforms(sessionID).align_pos,1)
        d = allWaveforms(sessionID).align_pos(n,:)+allWaveforms(sessionID).depth_pos(n);
        plot(t,d,'color',[0.2275    0.5961    0.8392])
        
    end
    allWaveforms(sessionID).depth_all = [depth_neg; depth_pos];
    %saveas(gcf, sprintf(['S',num2str(sessionID),' Waveforms']),'pdf')
end
%% concatenating
align_neg = cat(1,allWaveforms(1:p).align_neg); 
align_pos = cat(1,allWaveforms(1:p).align_pos); 
align_all = cat(1,allWaveforms(1:p).align_all);

depth_neg = cat(1,allWaveforms(1:p).depth_neg);
depth_pos = cat(1,allWaveforms(1:p).depth_pos);
depth_all = cat(1,allWaveforms(1:p).depth_all);

ID_neg = cat(1,allWaveforms(1:p).ID_neg);
ID_pos = cat(1,allWaveforms(1:p).ID_pos);
ID_all = cat(1,allWaveforms(1:p).ID_all);


%% Saving
save('normalizednegwaveforms3.mat','align_neg');
save('normalizedposwaveforms3.mat','align_pos');
save('normalizedwaveforms3.mat','align_all');

save('depth_neg3.mat','depth_neg');
save('depth_pos3.mat','depth_pos');
save('depth3.mat','depth_all');

save('ID_neg3.mat', 'ID_neg', 'sessionID');
save('ID_pos3.mat', 'ID_pos', 'sessionID');
save('ID3.mat', 'ID_all', 'sessionID');

%% Saving manual sort
manualsort = cat(1,allWaveforms(1:p).avg_waveform);
manualsortID = cat(1,allWaveforms(1:p).avg_waveformID);

save('manualsort_allSessions.mat','manualsort')
save('manualsortID_allSessions.mat','manualsortID')
