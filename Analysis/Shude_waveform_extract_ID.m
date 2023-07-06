clc;        % Clear Command Window
%close all;  % Close all figures
%clear all;  % Erase all existing variables
%workspace;  % Make sure the workspace panel is showing

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
maxsession = length(matFiles);
%% Parsing through folder for waveforms
for sessionID = 1:maxsession
    %% Initialize dynamic arrays
    avg_waveform = [];
    avg_waveformID =[];
    waveformTraj = [];
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
    waveform_amp = [];
    tp_dur = [];
    repWidth = [];
    
    %% Load current datastructure
    matFilename = fullfile(pwd, matFiles(sessionID).name);
    s = load(matFilename);
    fprintf('\n %d:',sessionID);
    allWaveforms(sessionID).templateID = s.templates.templateID;
    allWaveforms(sessionID).template = s.templates.template_waves;
    allWaveforms(sessionID).snr = s.templates.template_snr;
    allWaveforms(sessionID).depth = s.templates.template_depth_relativetolayer4;
    allWaveforms(sessionID).depth_mat = s.depth_mat;
    allWaveforms(sessionID).layerId = s.templates.template_layerID;
    allWaveforms(sessionID).spike_timing = s.templates.spike_timing;
    allWaveforms(sessionID).spike_ID = s.templates.spike_templateID;
    allWaveforms(sessionID).stim_on = s.templates.stimulus_onset;
    allWaveforms(sessionID).stim_cond = s.templates.stimulus_conditionID;
    allWaveforms(sessionID).dur = s.templates.stimulus_duration;
    allWaveforms(sessionID).PSTH = s.templates.stimulus_duration;    

    %% Plotting waveforms
    [~,idx] = sort(allWaveforms(sessionID).templateID);
    validChans = [1:384];
    fig = figure;

    for unitID = 1:size(idx,1)
%% For each template - extract the maximum waveform
        currWave = squeeze(allWaveforms(sessionID).template(idx(unitID),validChans,:));
        currWave = currWave - repmat(nanmean(currWave,2),[1 size(currWave,2)]);  % mean subtracted
        ampls = max(currWave,[],2)-min(currWave,[],2);             % amplitudes across channels
        [ampp,maxLoc] = max(ampls);                                   % index of max amplitude
        % Store real unit ID
        currID = [allWaveforms(sessionID).templateID(idx(unitID)) , sessionID];
        avg_waveformID = [avg_waveformID ; currID];
        % Store Max amplitude trajectory
        try
            currTraj = currWave([maxLoc-10:maxLoc+10],:);
        catch
            try
                currTraj = [zeros(8,82) ;currWave([maxLoc-2:maxLoc+2],:); zeros(8,82)];
            catch
                currTraj = zeros(21,82);
                disp(['Not enough channels above or below max amp for unit ',num2str(currID)])
            end
        end
        
        waveformTraj(:,:,idx(unitID)) = currTraj;
        % Store avg waveform
        currWave = currWave(maxLoc,:);                             % maximum waveform from template
        avg_waveform = [avg_waveform; currWave];
        waveform_amp = [waveform_amp; ampp];
        %% Waveform Features
        time = linspace(0,82/30000*1000,82); % Time samples at 30000 Hz, 82 samples
        [p t w s wi] = findmypeaks(currWave,time,'SortStr','descend','Annotate','extents','WidthReference','halfheight');
        %[peakAmp, ptime] = max(currWave);      % peak
        [troughAmp, ttime] = min(currWave);      % trough
        if size(p) > 1 & ~isempty(p)
            if t(1) > ttime
                peakAmp = p(1);
                ptime = t(1);
                rtime = wi(1,2)-ptime;
            else
                peakAmp = p(2);
                ptime = t(2);
                rtime = wi(2,2)-ptime;
            end
        elseif ~isempty(p) 
            peakAmp = p(1);
            ptime = t(1);
            rtime = wi(1,2)-ptime;
        else
            peakAmp = 0;
            ptime = 0;
            rtime = 0;
        end
        TtP = peakAmp-troughAmp;                   % trough to peak amp
        
        repWidth = [repWidth; rtime];           % repolarization time from peak to 1/2 peak
        tp_dur = [tp_dur; ptime-time(ttime)]; % trough to peak time
%% Sort out bad snr values, ie. low snrs or snr of -1 : too few corresponding spikes
        if allWaveforms(sessionID).snr(idx(unitID)) == -1 || allWaveforms(sessionID).snr(idx(unitID)) > 3.7 || abs(currWave(sessionID)/max(abs(currWave))) > 0.5% | abs(X(52)) > 30
            poor = [poor; currWave];
            poorID = [poorID ; currID];
        else
            
            good = [good; currWave];
            goodID = [goodID; currID];
            depth = allWaveforms(sessionID).depth(idx(unitID));


%% Positive spiking 
            if abs(peakAmp)> abs(troughAmp) %if max peak occurs before min peak = pos spike
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
            elseif abs(peakAmp) < abs(troughAmp) %if max peak occurs after min peak = neg spike
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
    allWaveforms(sessionID).trajectory = waveformTraj;
    allWaveforms(sessionID).amp = waveform_amp;
    allWaveforms(sessionID).tp_dur = tp_dur;
    allWaveforms(sessionID).repWidth = repWidth;
    allWaveforms(sessionID).snrsort.align_neg = normalizedwaveformsneg';
    allWaveforms(sessionID).snrsort.depth_neg = depth_neg;
    allWaveforms(sessionID).snrsort.ID_neg = ID_neg;
    allWaveforms(sessionID).snrsort.align_pos = normalizedwaveformspos';
    allWaveforms(sessionID).snrsort.depth_pos = depth_pos;
    allWaveforms(sessionID).snrsort.ID_pos = ID_pos;
    allWaveforms(sessionID).snrsort.align_all = normalizedwaveforms';
    allWaveforms(sessionID).snrsort.ID_all = ID_all;
    
    
    
    %% normalized waveform figure
    time = linspace(0,82/30000*1000,82); % Time samples at 30000 Hz, 82 samples
    t = time(1:52); % Time samples at 30000 Hz, 52 samples
    subplot(2,1,1)
    hold on
    title(sprintf(['S',num2str(sessionID),' Waveforms']))
    ylabel('Normalized Amplitude')
    xlabel('Time [ms]')
    plot(t, normalizedwaveformsneg,'color',[ 0.8902    0.5176    0.5176])
    plot(t, normalizedwaveformspos,'color',[0.2275    0.5961    0.8392])
    set(gca,'TickDir','out')

    
    %% laminar figure
    
    a = 100; % this is the scale factor
    b = 40; % this is the scatter plot range
    subplot(2,1,2)
    ylabel('Distance from Layer 4 [um]')
    hold on
    for m = 1:size(allWaveforms(sessionID).snrsort.align_neg,1)
        r = 0 + (b-0)*rand();
        d = allWaveforms(sessionID).snrsort.align_neg(m,:)*a+allWaveforms(sessionID).snrsort.depth_neg(m);
        plot(t+r,d,'color',[ 0.8902    0.5176    0.5176])
    end
    
    for n = 1:size(allWaveforms(sessionID).snrsort.align_pos,1)
        r = 0 + (b-0)*rand();
        d = allWaveforms(sessionID).snrsort.align_pos(n,:)*a+allWaveforms(sessionID).snrsort.depth_pos(n);
        plot(t+r,d,'color',[0.2275    0.5961    0.8392])
        
    end
    
    yline(allWaveforms(sessionID).depth_mat(:,1)-allWaveforms(sessionID).depth_mat(2,1))
    ylim([-1500 2000])
    set(gca,'xtick',[],'XColor', 'none','TickDir','out')
    set(gcf,'renderer','Painters')
    allWaveforms(sessionID).snrsort.depth_all = [depth_neg; depth_pos];
    %saveas(gcf, sprintf(['S',num2str(sessionID),' Waveforms']),'pdf')
end
%% concatenating
for sessionID = 1:maxsession
    
align_neg = [align_neg; allWaveforms(sessionID).snrsort.align_neg]; 
align_pos = [align_pos; allWaveforms(sessionID).snrsort.align_pos]; 
align_all = [align_all; allWaveforms(sessionID).snrsort.align_all];

depth_neg = [depth_neg; allWaveforms(sessionID).snrsort.depth_neg];
depth_pos = [depth_pos; allWaveforms(sessionID).snrsort.depth_pos];
depth_all = [depth_all; allWaveforms(sessionID).snrsort.depth_all];

ID_neg = [ID_neg; allWaveforms(sessionID).snrsort.ID_neg];
ID_pos = [ID_pos; allWaveforms(sessionID).snrsort.ID_pos];
ID_all = [ID_all; allWaveforms(sessionID).snrsort.ID_all];

disp(['Total Number of Waveforms in session ',num2str(sessionID),' = ',num2str(size(allWaveforms(sessionID).snrsort.ID_all,1))])
end
%% Saving
% save('normalizednegwaveforms3.mat','align_neg');
% save('normalizedposwaveforms3.mat','align_pos');
% save('normalizedwaveforms3.mat','align_all');
% 
% save('depth_neg3.mat','depth_neg');
% save('depth_pos3.mat','depth_pos');
% save('depth3.mat','depth_all');
% 
% save('ID_neg3.mat', 'ID_neg', 'sessionID');
% save('ID_pos3.mat', 'ID_pos', 'sessionID');
% save('ID3.mat', 'ID_all', 'sessionID');
% 
% % %% Saving manual sort
% % manualsort = cat(1,allWaveforms(1:p).avg_waveform);
% % manualsortID = cat(1,allWaveforms(1:p).avg_waveformID);
% % 
% % save('manualsort_allSessions.mat','manualsort')
% % save('manualsortID_allSessions.mat','manualsortID')
  %  set(gca,'xtick',[],'XColor', 'none','TickDir','out')
  %  set(gcf,'renderer','Painters')
    %%
  %  print -depsc -tiff -r300 -painters MessyWaveformsS5.eps
