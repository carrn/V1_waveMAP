clc;        % Clear Command Window
close all;  % Close all figures
clear all;  % Erase all existing variables
workspace;  % Make sure the workspace panel is showing

% This program requires:
% - folder containing data structures - templates from all sessions (output from kilosort2)
% - function reshape_min_waveforms()
% - function reshape_max_waveforms()
% - function extractarray()
% - function findmypeaks()
% 
% 

% Parsing for data structures folder
% Parse through folder for waveform templates and associated data
% Creates struct containing this information
mydir = 'C:\Users\ncarr\Documents\Data\Shude\Analysis';
addpath(mydir)

matFiles = dir([mydir '\*templates.mat']);

%% 1a. Extract waveforms for manual sorting
% Parse through folder for waveform templates and associated data
% Creates struct containing this information

% Initialize
allWaveforms = struct([]);
maxsession = length(matFiles);
% Parsing through folder for waveforms
for sessionID = 1:maxsession
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
    matFilename = fullfile(mydir, matFiles(sessionID).name);
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

% concatenating
align_neg = cat(1,allWaveforms(1:maxsession).align_neg); 
align_pos = cat(1,allWaveforms(1:maxsession).align_pos); 
align_all = cat(1,allWaveforms(1:maxsession).align_all);

depth_neg = cat(1,allWaveforms(1:maxsession).depth_neg);
depth_pos = cat(1,allWaveforms(1:maxsession).depth_pos);
depth_all = cat(1,allWaveforms(1:maxsession).depth_all);

ID_neg = cat(1,allWaveforms(1:maxsession).ID_neg);
ID_pos = cat(1,allWaveforms(1:maxsession).ID_pos);
ID_all = cat(1,allWaveforms(1:maxsession).ID_all);


% Saving for manual sort
save([pwd '\manual_sort\manualsort_normalizednegwaveforms.mat'],'align_neg');
save([pwd '\manual_sort\manualsort_normalizedposwaveforms.mat'],'align_pos');
save([pwd '\manual_sort\manualsort_normalizedwaveforms.mat'],'align_all');

save([pwd '\manual_sort\manualsort_negID.mat'],'ID_neg');
save([pwd '\manual_sort\manualsort_posID.mat'],'ID_pos');
save([pwd '\manual_sort\manualsort_ID.mat'],'ID_all');

% Run Waves1.m at this point before proceeding 

%% 1b. Extract Waveforms for SNR sort

% Initialize
allWaveforms = struct([]);
maxsession = length(matFiles);
% Parsing through folder for waveforms
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
    matFilename = fullfile(mydir, matFiles(sessionID).name);
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
end

% concatenating
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



% % Saving manual sort
% manualsort = cat(1,allWaveforms(1:p).avg_waveform);
% manualsortID = cat(1,allWaveforms(1:p).avg_waveformID);
% 
% save('manualsort_allSessions.mat','manualsort')
% save('manualsortID_allSessions.mat','manualsortID')
% set(gca,'xtick',[],'XColor', 'none','TickDir','out')
% set(gcf,'renderer','Painters')
%     
%   %  print -depsc -tiff -r300 -painters MessyWaveformsS5.eps

  
%% 2. Manual Sort ID extract
% This requires the output of the Waves GUI, the interface used to
% sort Waveforms by visual quality
% 
% To run Waves GUI, open Waves1.m

manualWaveforms = load('manual_sort/20220516/storage20220516.mat');
passWaveforms = load('manual_sort/20220516/good_2ndpass.mat');
manualWaveforms = manualWaveforms.storage; % waveforms that went through second pass
passWaveforms = passWaveforms.good2; % waveforms that were "good"
manualWaveforms = sortrows(sortrows(unique([manualWaveforms ; passWaveforms],'rows'),1),2);
currsession = manualWaveforms(:,2);
manual_ID = manualWaveforms(:,1);

for sessionID = 1:maxsession
    allWaveforms(sessionID).manual.manual_ID = sort(manual_ID(currsession ==sessionID));
    figure
    avg_waveform = [];
    depth_pos = [];
    depth_neg = [];
    depth_all = [];
    pos = [];
    neg = [];
    align_all = [];
    align_pos = [];
    align_neg = [];
    ID_neg = [];
    ID_pos = [];
    ID_all = [];
    
    for unitID = 1:length(allWaveforms(sessionID).manual.manual_ID)
        idx_currID = allWaveforms(sessionID).templateID==allWaveforms(sessionID).manual.manual_ID(unitID);
        currID = allWaveforms(sessionID).templateID(idx_currID);
        currWave = allWaveforms(sessionID).avg_waveform((idx_currID),:);
        avg_waveform = [avg_waveform ; currWave];
        depth = allWaveforms(sessionID).depth(idx_currID);
        %disp(allWaveforms(i).manual_ID(ii))
        
        %         currWave = currWave; %./abs(y1-y2);
        %         currWave = rescale(currWave,-1,1);
        %         currWave = (currWave-mean(currWave))./std(currWave);
        %
        %         norm = [norm; currWave];
        %
        %% Positive spiking
        %Sort out positive spiking
        [y1, t1] = max(currWave);
        [y2, t2] = min(currWave);
        TtP = y1-y2;
        Slope = (y1-y2)/(t1-t2);
        if abs(y1)> abs(y2) %if max peak occurs before min peak = pos spike
            %Reshape pos spiking waveforms
            pos = [pos; currWave];
            
            try
                currWave = reshape_max_waveforms(currWave);
                align_pos = [align_pos; currWave];
                depth_pos = [depth_pos; depth];
                ID_pos = [ID_pos; currID];
            catch
                actionmsg = sprintf('Unable to resolve %d, skipped.',sessionID)
            end
            %% Negative Spiking
        elseif abs(y1) < abs(y2) %if max peak occurs after min peak = neg spike
            neg = [neg; currWave];
            
            %Reshape neg spiking waveforms
            try
                currWave = reshape_min_waveforms(currWave);
                align_neg = [align_neg; currWave];
                depth_neg = [depth_neg; depth];
                ID_neg = [ID_neg; currID];
            catch
                actionmsg = sprintf('Unable to resolve %d, skipped.',sessionID)
            end
        end
        
        align_all = [align_neg; align_pos];
        ID_all = [ID_neg; ID_pos];
        
        currTraj2=align_neg';
        normalizedwaveformsneg = bsxfun(@rdivide,currTraj2,max(abs(currTraj2)));
        
        currTraj1=align_pos';
        normalizedwaveformspos = bsxfun(@rdivide,currTraj1,max(abs(currTraj1)));
        
        currTraj3=align_all';
        normalizedwaveforms = bsxfun(@rdivide,currTraj3,max(abs(currTraj3)));
        
        
        
    end
    
    allWaveforms(sessionID).manual.avg_waveform = avg_waveform;
    allWaveforms(sessionID).manual.align_neg = normalizedwaveformsneg';
    allWaveforms(sessionID).manual.depth_neg = depth_neg;
    allWaveforms(sessionID).manual.ID_neg = ID_neg;
    allWaveforms(sessionID).manual.align_pos = normalizedwaveformspos';
    allWaveforms(sessionID).manual.depth_pos = depth_pos;
    allWaveforms(sessionID).manual.ID_pos = ID_pos;
    allWaveforms(sessionID).manual.align_all = normalizedwaveforms';
    allWaveforms(sessionID).manual.ID_all = ID_all;
    
    %% normalized waveform figure
    %t = [0:0.03333:1.73]; % Time samples at 30000 Hz, 52 samples
    time = linspace(0,82/30000*1000,82); % Time samples at 30000 Hz, 82 samples
    t = time(1:52); % Time samples at 30000 Hz, 52 samples
    subplot(2,1,1)
    hold on
    title(sprintf(['S',num2str(sessionID),' Manual Sorted Waveforms']))
    ylabel('Normalized Amplitude')
    xlabel('Time samples at 30000 Hz')
    plot(t, normalizedwaveformspos,'color',[0.2275    0.5961    0.8392])
    plot(t, normalizedwaveformsneg,'color',[ 0.8902    0.5176    0.5176])
    %keyboard
    %% laminar figure
    a = 100; % this is the scale factor
    b = 40; % this is the scatter plot range
    subplot(2,1,2)
    hold on
    for m = 1:size(allWaveforms(sessionID).manual.ID_neg,1)
        r = 0 + (b-0)*rand();
        d = allWaveforms(sessionID).manual.align_neg(m,:)*a+allWaveforms(sessionID).manual.depth_neg(m);
        depth_all = [depth_all ; d];
        plot(t+r,d,'color',[ 0.8902    0.5176    0.5176])
    end
    
    for n = 1:size(allWaveforms(sessionID).manual.ID_pos,1)
        r = 0 + (b-0)*rand();
        d = allWaveforms(sessionID).manual.align_pos(n,:)*a+allWaveforms(sessionID).manual.depth_pos(n);
        plot(t+r,d,'color',[0.2275    0.5961    0.8392])
    end
disp(['Total Number of Waveforms in session ',num2str(sessionID),' = ',num2str(size(allWaveforms(sessionID).manual.ID_all,1))])
end

%% 3. Compare SNR and Waveform
% compares the SNR sorted waveforms to the manual sorted waveforms
% Requires:
% - SNR sorted waveform unit IDs and avg waveforms
% - manual sorted waveform unit IDs and avg waveforms
% - matchingSNR_manual.m function that returns a logical array of all
%  units in that session (1 if matching, 0, if not), and an icc (intra
%  class correlation) score
%
% Outputs:
% - allWaveforms(sessionID).waveform
%   This contains IDs, depths, and logical array of matching units
for sessionID = 1:5
    
    [matchingunits_all, icc] = matchingSNR_manual(allWaveforms(sessionID).snrsort.ID_all, allWaveforms(sessionID).manual.ID_all);
    [matchingunits_pos, ~] = matchingSNR_manual(allWaveforms(sessionID).snrsort.ID_pos, allWaveforms(sessionID).manual.ID_pos);
    [matchingunits_neg, ~] = matchingSNR_manual(allWaveforms(sessionID).snrsort.ID_neg, allWaveforms(sessionID).manual.ID_neg);
    
    
    allWaveforms(sessionID).waveform.all = matchingunits_all;
    allWaveforms(sessionID).waveform.icc = icc;
    allWaveforms(sessionID).waveform.ID_all = allWaveforms(sessionID).snrsort.ID_all(matchingunits_all,:);
    allWaveforms(sessionID).waveform.align_all = allWaveforms(sessionID).snrsort.align_all(matchingunits_all,:);
    allWaveforms(sessionID).waveform.pos = matchingunits_pos;
    allWaveforms(sessionID).waveform.ID_pos = allWaveforms(sessionID).snrsort.ID_pos(matchingunits_pos,:);
    allWaveforms(sessionID).waveform.align_pos = allWaveforms(sessionID).snrsort.align_pos(matchingunits_pos,:);
    allWaveforms(sessionID).waveform.neg = matchingunits_neg;
    allWaveforms(sessionID).waveform.ID_neg = allWaveforms(sessionID).snrsort.ID_neg(matchingunits_neg,:);
    allWaveforms(sessionID).waveform.align_neg = allWaveforms(sessionID).snrsort.align_neg(matchingunits_neg,:);
    
end


%% 4. Plot 3rd pass waveforms
% Previous steps:
% - Shude_waveforms_extract_ID.m - normalizes and averages all waveforms, snr
% sort
% - Waves1.m - 2 Pass Manual Sort
% - manualsort_ID_extract.m - normalizes and averages manual sort waveforms
% - compareSNRandWaveform.m - compares the SNR sorted waveforms to the manual sorted waveforms
%
% This program requires:
% - extractarray()
%
% Outputs:
% - plots of final waveforms to be exported to WaveMAP
figure

for sessionID = 1:maxsession
    
    normalizedwaveformspos = allWaveforms(sessionID).waveform.align_pos;
    normalizedwaveformsneg = allWaveforms(sessionID).waveform.align_neg;
    
    originalarray = allWaveforms(sessionID).depth;
    originalIDs = allWaveforms(sessionID).avg_waveformID;
    
    depth_pos = extractarray(originalIDs, allWaveforms(sessionID).waveform.ID_pos(:,1), originalarray);
    depth_neg = extractarray(originalIDs, allWaveforms(sessionID).waveform.ID_neg(:,1), originalarray);
    %% normalized waveform figure
    %t = [0:0.03333:1.73]; % Time samples at 30000 Hz, 52 samples
    time = linspace(0,82/30000*1000,82); % Time samples at 30000 Hz, 82 samples
    t = time(1:52); % Time samples at 30000 Hz, 52 samples
    subplot(5,1,sessionID)
    
    title(sprintf(['S',num2str(sessionID),' Waveforms']))
    ylabel('Normalized Amplitude')
    xlabel('Time [ms]')
    plot(t, normalizedwaveformsneg,'color',[ 0.8902    0.5176    0.5176])
    hold on
    plot(t, normalizedwaveformspos,'color',[0.2275    0.5961    0.8392])
    
    hold on
    %set(gca,'xtick',[],'XColor', 'none')
    set(gca,'box','off','TickDir','out')
end
% print -depsc -tiff -r300 -painters allsessionsWaveforms.eps
%
figure
for sessionID = 1:maxsession
    
    normalizedwaveformspos = allWaveforms(sessionID).waveform.align_pos;
    normalizedwaveformsneg = allWaveforms(sessionID).waveform.align_neg;
    
    originalarray = allWaveforms(sessionID).depth;
    originalIDs = allWaveforms(sessionID).avg_waveformID;
    
    depth_pos = extractarray(originalIDs, allWaveforms(sessionID).waveform.ID_pos(:,1), originalarray);
    depth_neg = extractarray(originalIDs, allWaveforms(sessionID).waveform.ID_neg(:,1), originalarray);
    % laminar figure
    %t = t/10;
    a = 100; % this is the scale factor
    b = 10; % this is the scatter plot range
    subplot(1,5,sessionID)
    ylabel('Distance from Layer 4 [um]')
    hold on
    for m = 1:size(normalizedwaveformsneg,1)
        r = 0 + (b-0)*rand();
        d = normalizedwaveformsneg(m,:)*a+depth_neg(m);
        plot(t+r,d,'color',[ 0.8902    0.5176    0.5176])
        hold on
    end
    
    for n = 1:size(normalizedwaveformspos,1)
        r = 0 + (b-0)*rand();
        d = normalizedwaveformspos(n,:)*a+depth_pos(n);
        plot(t+r,d,'color',[0.2275    0.5961    0.8392])
        hold on
    end
    %ylim([-1500 3000])
    hold on
    if sessionID == 4
        
        yline(([allWaveforms(sessionID).depth_mat(:,1); allWaveforms(sessionID).depth_mat(5,2)]-allWaveforms(sessionID).depth_mat(1,1)));
        ylim([-1500 3000])
        
    elseif sessionID == 5
        yline(([allWaveforms(sessionID).depth_mat(:,1); allWaveforms(sessionID).depth_mat(5,2)]-allWaveforms(sessionID).depth_mat(1,1)));
        ylim([-1500 3000])
    else
        yline(([allWaveforms(sessionID).depth_mat(:,1); allWaveforms(sessionID).depth_mat(4,2)]-allWaveforms(sessionID).depth_mat(1,2)));
        ylim([-1500 2000])
        
    end
    hold on
    
    % avgLayerBounds = [ 0 -488; 285.4 0; 588.8 285.4; 1039.4 588.8; -488 -990];
    % yline([avgLayerBounds(:,1);avgLayerBounds(:,2)],'LineWidth',3)
    depth_all = [depth_neg; depth_pos];
    allWaveforms(sessionID).waveform.depth_all = depth_all;
    allWaveforms(sessionID).waveform.depth_pos = depth_pos;
    allWaveforms(sessionID).waveform.depth_neg = depth_neg;
    %saveas(gcf, sprintf(['S',num2str(sessionID),' Waveforms']),'pdf')
    disp(['Total Number of Waveforms in session ',num2str(sessionID),' = ',num2str(size(allWaveforms(sessionID).waveform.ID_all,1))])
    set(gca,'box','off','TickDir','out')
end
%set(gca,'xtick',[],'XColor', 'none')
% print -depsc -tiff -r300 -painters allsessionsDepths.eps
%
%  sessionID = 2;
%
% yline(([allWaveforms(sessionID).depth_mat(:,1); allWaveforms(sessionID).depth_mat(5,2)]-allWaveforms(sessionID).depth_mat(1,1)));
% ylim([-1500 3000])
% set(gca,'xtick',[],'XColor', 'none')
% set(gcf,'renderer','Painters')
% print -depsc -tiff -r300 -painters session2raw.eps




%% 5. Layer Bounds with L5 and 6 separate
% average Boundaries

avgLayerBounds_L56 = [-488 -242.4; -242.4 0; 0 285.4; 285.4 588.8 ; 588.8 1039.4; -990 -488]; % [1 2 3 4 5]

allWaveforms(1).depth_mat_L56 = [508,789;789,1070;1070,1353;1353,1609;1609,2300;0,508];
allWaveforms(2).depth_mat_L56 = [702,956;956,1190;1190,1432;1432,1748;1748,2355;0,702];
allWaveforms(3).depth_mat_L56 = [353,671.5;671.5,990;990,1302;1302,1610;1610,2262;0,353];
allWaveforms(4).depth_mat_L56 = [937,1124;750,937;422,750;73,422;0,73;1124,1500];
%allWaveforms(4).depth_mat_L56 = [750,937;937,1124;422,750;73,422;0,73;1124,1500];
allWaveforms(5).depth_mat_L56 = [741.5,933;550,741.5;312,550;0,312;-230,-13;933,1500];
%allWaveforms(5).depth_mat_L56 = [550,741.5;741.5,933;312,550;0,312;-230,-13;933,1500];


t = [0:0.03333:1.73];
%
figure
for sessionID =1:5
    allWaveforms(sessionID).scaled_depth_L56 = NaN(size(allWaveforms(sessionID).depth));
    
    sessionDepth = allWaveforms(sessionID).depth;
    if sessionID == 4
        layerBound = (allWaveforms(sessionID).depth_mat_L56-allWaveforms(sessionID).depth_mat_L56(2,1))*-1;
        layerBound = [layerBound(:,2), layerBound(:,1)];
        sessionDepth = sessionDepth*-1;
    elseif sessionID == 5
        layerBound = (allWaveforms(sessionID).depth_mat_L56-allWaveforms(sessionID).depth_mat_L56(2,1))*-1;
        layerBound = [layerBound(:,2), layerBound(:,1)];
        sessionDepth = sessionDepth*-1;
    else
        layerBound = allWaveforms(sessionID).depth_mat_L56-allWaveforms(sessionID).depth_mat_L56(2,2);
        sessionDepth = sessionDepth;
    end
   
    layerId_L56 =  NaN(size(allWaveforms(sessionID).depth));
    for layerID = 1:6
        mini = layerBound(layerID,1);
        maxi = layerBound(layerID,2);
        
        depthsBoundIdx = find(sessionDepth<=maxi & sessionDepth>=mini);
        depthsBound = sessionDepth(sessionDepth<=maxi & sessionDepth>=mini);
        
        
        %scaled = scaledDepths(avgLayerBounds(layerID,1),avgLayerBounds(layerID,2), depthsBound);
        scaled = rescale(depthsBound, avgLayerBounds_L56(layerID,1),avgLayerBounds_L56(layerID,2));
        allWaveforms(sessionID).scaled_depth_L56(depthsBoundIdx) = scaled;
        layerId_L56(depthsBoundIdx) = ones(size(scaled))*layerID;
        %disp(size(depthsBound))
         %a = ~isnan(depthsBound)
    end
    allWaveforms(sessionID).layerId_L56 = layerId_L56;

    %% Plotting
    normalizedwaveformspos = allWaveforms(sessionID).waveform.align_pos;
    normalizedwaveformsneg = allWaveforms(sessionID).waveform.align_neg;
    
    originalarray = allWaveforms(sessionID).scaled_depth_L56;
    originalIDs = allWaveforms(sessionID).avg_waveformID;
    
    depth_pos = extractarray(originalIDs, allWaveforms(sessionID).waveform.ID_pos(:,1), originalarray);
    depth_neg = extractarray(originalIDs, allWaveforms(sessionID).waveform.ID_neg(:,1), originalarray);
    %% laminar figure scaled
    %t = t/10;
    time = linspace(0,82/30000*1000,82); % Time samples at 30000 Hz, 82 samples
    t = time(1:52); % Time samples at 30000 Hz, 52 samples
    a = 50; % this is the scale factor %100
    b = 20; % this is the scatter plot range %40
    ylabel('Distance from Layer 4 [um]')
    hold on
    for m = 1:size(normalizedwaveformsneg,1)
        r = 0 + (b-0)*rand();
        d = normalizedwaveformsneg(m,:)*a+depth_neg(m);
        plot(t+r,d,'color',[ 0.8902    0.5176    0.5176])
    end
    
    for n = 1:size(normalizedwaveformspos,1)
        r = 0 + (b-0)*rand();
        d = normalizedwaveformspos(n,:)*a+depth_pos(n);
        plot(t+r,d,'color',[0.2275    0.5961    0.8392])
        
    end
    yline([avgLayerBounds_L56(:,1);avgLayerBounds_L56(:,2)])
    set(gca,'xtick',[],'XColor', 'none')
    set(gcf,'renderer','Painters')
    %saveas(gcf, sprintf(['S',num2str(sessionID),' Waveforms']),'pdf')
    %disp(['Total Number of Waveforms in session ',num2str(sessionID),' = ',num2str(size(depth_all,1))])
    depth_all = [depth_neg; depth_pos];
        allWaveforms(sessionID).waveform.depth_all_scaled_L56 = depth_all;
        allWaveforms(sessionID).waveform.depth_pos_scaled_L56 = depth_pos;
        allWaveforms(sessionID).waveform.depth_neg_scaled_L56 = depth_neg;
        %saveas(gcf, sprintf(['S',num2str(sessionID),' Waveforms']),'pdf') 
        disp(['Total Number of Waveforms in session ',num2str(sessionID),' = ',num2str(size(depth_all,1))])
   %% how many in each layer?
    
        normalizedwaveformspos = allWaveforms(sessionID).waveform.align_pos;
        normalizedwaveformsneg = allWaveforms(sessionID).waveform.align_neg;
        
        originalarray = allWaveforms(sessionID).layerId_L56;
        originalIDs = allWaveforms(sessionID).avg_waveformID;
        
        depth_pos_num = extractarray(originalIDs, allWaveforms(sessionID).waveform.ID_pos(:,1), originalarray);
        depth_neg_num = extractarray(originalIDs, allWaveforms(sessionID).waveform.ID_neg(:,1), originalarray);
    disp('pos')
    for layerID = 1:6
        disp(['Layer ID: ',num2str(layerID)])
        disp(size(depth_pos_num(depth_pos_num == layerID)))
    end
    disp('neg')
    for layerID = 1:6
        disp(['Layer ID: ',num2str(layerID)])
        disp(size(depth_neg_num(depth_neg_num == layerID)))
    end
    
end





  %% 5. Layer Bounds
% average Boundaries

avgLayerBounds = [-488 0; 0 285.4; 285.4 588.8 ; 588.8 1039.4; -990 -488]; % [1 2 3 4 5]

t = [0:0.03333:1.73];

figure
for sessionID =1:5
    allWaveforms(sessionID).scaled_depth = NaN(size(allWaveforms(sessionID).depth));
    
    sessionDepth = allWaveforms(sessionID).depth;
    if sessionID == 4
        layerBound = (allWaveforms(sessionID).depth_mat-allWaveforms(sessionID).depth_mat(1,1))*-1;
        layerBound = [layerBound(:,2), layerBound(:,1)];
        sessionDepth = sessionDepth*-1;
    elseif sessionID == 5
        layerBound = (allWaveforms(sessionID).depth_mat-allWaveforms(sessionID).depth_mat(1,1))*-1;
        layerBound = [layerBound(:,2), layerBound(:,1)];
        sessionDepth = sessionDepth*-1;
    else
        layerBound = allWaveforms(sessionID).depth_mat-allWaveforms(sessionID).depth_mat(1,2);
        sessionDepth = sessionDepth;
    end
    
    for layerID = 1:5

        mini = layerBound(layerID,1);
        maxi = layerBound(layerID,2);
        
        depthsBoundIdx = find(sessionDepth<=maxi & sessionDepth>=mini);
        depthsBound = sessionDepth(sessionDepth<=maxi & sessionDepth>=mini);
        
        
        %scaled = scaledDepths(avgLayerBounds(layerID,1),avgLayerBounds(layerID,2), depthsBound);
        scaled = rescale(depthsBound, avgLayerBounds(layerID,1),avgLayerBounds(layerID,2));
        allWaveforms(sessionID).scaled_depth(depthsBoundIdx) = scaled;
        disp(size(depthsBound))
         %a = ~isnan(depth_neg_scaled);
    end

    %% Plotting
    normalizedwaveformspos = allWaveforms(sessionID).waveform.align_pos;
    normalizedwaveformsneg = allWaveforms(sessionID).waveform.align_neg;
    
    originalarray = allWaveforms(sessionID).scaled_depth;
    originalIDs = allWaveforms(sessionID).avg_waveformID;
    
    depth_pos = extractarray(originalIDs, allWaveforms(sessionID).waveform.ID_pos(:,1), originalarray);
    depth_neg = extractarray(originalIDs, allWaveforms(sessionID).waveform.ID_neg(:,1), originalarray);
    %% laminar figure scaled
    %t = t/10;
    time = linspace(0,82/30000*1000,82); % Time samples at 30000 Hz, 82 samples
    t = time(1:52); % Time samples at 30000 Hz, 52 samples
    a = 70; % this is the scale factor %100
    b = 10; % this is the scatter plot range %40
    ylabel('Distance from Layer 4 [um]')
    hold on
    for m = 1:size(normalizedwaveformsneg,1)
        r = 0 + (b-0)*rand();
        d = normalizedwaveformsneg(m,:)*a+depth_neg(m);
        plot(t+r,d,'color',[ 0.8902    0.5176    0.5176])
    end
    
    for n = 1:size(normalizedwaveformspos,1)
        r = 0 + (b-0)*rand();
        d = normalizedwaveformspos(n,:)*a+depth_pos(n);
        plot(t+r,d,'color',[0.2275    0.5961    0.8392])
        
    end
    yline([avgLayerBounds(:,1);avgLayerBounds(:,2)])
    set(gca,'xtick',[],'XColor', 'none')
    set(gcf,'renderer','Painters')
    %saveas(gcf, sprintf(['S',num2str(sessionID),' Waveforms']),'pdf')
    %disp(['Total Number of Waveforms in session ',num2str(sessionID),' = ',num2str(size(depth_all,1))])
    depth_all = [depth_neg; depth_pos];
        allWaveforms(sessionID).waveform.depth_all_scaled = depth_all;
        allWaveforms(sessionID).waveform.depth_pos_scaled = depth_pos;
        allWaveforms(sessionID).waveform.depth_neg_scaled = depth_neg;
        %saveas(gcf, sprintf(['S',num2str(sessionID),' Waveforms']),'pdf')
        disp(['Total Number of Waveforms in session ',num2str(sessionID),' = ',num2str(size(depth_all,1))])
        
end


 %print -depsc -tiff -r300 -painters scaledDepths.eps

%% 6. Concatenating and saving Scaled
ID_all = [];
ID_pos = [];
ID_neg = [];
align_all = [];
align_pos = [];
align_neg = [];
depth_all = [];
depth_pos = [];
depth_neg = [];
depth_all_scaled = [];
depth_pos_scaled = [];
depth_neg_scaled = [];
depth_bin_L56 = [];

% concatenating
for sessionID = 1:maxsession
    
align_neg = [align_neg; allWaveforms(sessionID).waveform.align_neg]; 
align_pos = [align_pos; allWaveforms(sessionID).waveform.align_pos]; 
align_all = [align_all; allWaveforms(sessionID).waveform.align_all];

depth_neg = [depth_neg; allWaveforms(sessionID).waveform.depth_neg];
depth_pos = [depth_pos; allWaveforms(sessionID).waveform.depth_pos];
depth_all = [depth_all; allWaveforms(sessionID).waveform.depth_all];

ID_neg = [ID_neg; allWaveforms(sessionID).waveform.ID_neg];
ID_pos = [ID_pos; allWaveforms(sessionID).waveform.ID_pos];
ID_all = [ID_all; allWaveforms(sessionID).waveform.ID_all];

depth_neg_scaled = [depth_neg_scaled; allWaveforms(sessionID).waveform.depth_neg_scaled];
depth_pos_scaled = [depth_pos_scaled; allWaveforms(sessionID).waveform.depth_pos_scaled];
depth_all_scaled = [depth_all_scaled; allWaveforms(sessionID).waveform.depth_all_scaled];

end

figure; 
histogram(depth_neg_scaled, 20, 'Normalization', 'countdensity')
hold on 
histogram(depth_pos_scaled, 20, 'Normalization', 'countdensity')

 a = ~isnan(depth_neg_scaled);
disp(['Total Number of negative units in scaled bounds = ',num2str(sum(a))])
 a = ~isnan(depth_pos_scaled);
disp(['Total Number of positive units in scaled bounds = ',num2str(sum(a))])



%% Saving for WaveMAP
save([pwd '\WaveMAP\normalizednegwaveforms.mat'],'align_neg');
save([pwd '\WaveMAP\normalizedposwaveforms.mat'],'align_pos');
save([pwd '\WaveMAP\normalizedwaveforms.mat'],'align_all');

save([pwd '\WaveMAP\depth_neg.mat'],'depth_neg');
save([pwd '\WaveMAP\depth_pos.mat'],'depth_pos');
save([pwd '\WaveMAP\depth.mat'],'depth_all');


save([pwd '\WaveMAP\depth_neg_scaled.mat'],'depth_neg_scaled');
save([pwd '\WaveMAP\depth_pos_scaled.mat'],'depth_pos_scaled');
save([pwd '\WaveMAP\depth_scaled.mat'],'depth_all_scaled');

save([pwd '\WaveMAP\ID_neg.mat'], 'ID_neg', 'sessionID');
save([pwd '\WaveMAP\ID_pos.mat'], 'ID_pos', 'sessionID');
save([pwd '\WaveMAP\ID.mat'], 'ID_all', 'sessionID');



% %% 7. Reshaping trajectories
% 
% maxsession = 5;
% %figure;
% for sessionID = 1:maxsession
%     numUnits = size(allWaveforms(sessionID).templateID,1);
%     reshapedTraj = [];
%     for unitID = 1:numUnits
%         trajectory = allWaveforms(sessionID).trajectory;
%         numChannels = size(trajectory,1);
%         b = allWaveforms(sessionID).trajectory;
%         B = squeeze(b(1:2:numChannels,:,unitID)); 
%         BoB = reshape(B',1,[]);
% 
%         BoBby = reshape_traj(B);
%         BoBy = reshape(BoBby',1,[]);
%         %hold on
%         %plot(BoBy)
%         reshapedTraj = [reshapedTraj; BoBy];
%         %figure;
%         %imagesc(B)
%     end
%     
%     normTraj = bsxfun(@rdivide,reshapedTraj',max(abs(reshapedTraj')));
%     allWaveforms(sessionID).reshapedTraj = reshapedTraj;
%     allWaveforms(sessionID).normTraj = normTraj';
% end
% %% Concatenating
% ID_all = [];
% align_all = [];
% depth_all = [];
% norm_all = [];
% 
% %%
% for sessionID = 1:maxsession
%     
% align_all = [align_all; allWaveforms(sessionID).reshapedTraj];
% depth_all = [depth_all; allWaveforms(sessionID).depth];
% ID_all = [ID_all; [allWaveforms(sessionID).templateID, ones(size(allWaveforms(sessionID).templateID))*sessionID]];
% norm_all = [norm_all; allWaveforms(sessionID).normTraj];
% 
% end
% %% matching clean units
% a = ~isnan(align_all);
% align_= align_all(a);
% align_all = reshape(align_,[],572);
% 
% depth_all = depth_all(a(:,1));
% 
% ID_ = ID_all(a(:,1:2));
% ID_all = reshape(ID_,[],2);
% 
% norm_ = norm_all(a);
% norm_all = reshape(norm_,[],572);
% 
% %%
% 
% for sessionID = 1:maxsession
%     sessionIDs = ID_all(ID_all(:,2)==sessionID);
%     
%     [align_all, IDs, H, hh] = extractarray(allWaveforms(sessionID).avg_waveformID, allWaveforms(sessionID).waveform.ID_all, allWaveforms(sessionID).reshapedTraj);
%     [depth_all, IDs, H, hh] = extractarray(allWaveforms(sessionID).avg_waveformID, allWaveforms(sessionID).waveform.ID_all, allWaveforms(sessionID).depth);
%     [depth_scaled, IDs, H, hh] = extractarray(allWaveforms(sessionID).avg_waveformID, allWaveforms(sessionID).waveform.ID_all, allWaveforms(sessionID).scaled_depth);
% 
%     allWaveforms(sessionID).traj.ID_all = IDs;
%     allWaveforms(sessionID).traj.align_all = align_all;
%     allWaveforms(sessionID).traj.depth = depth_all;
%     allWaveforms(sessionID).traj.depth_scaled = depth_scaled;
% 
% 
% end
% 
% %%
% ID_all = [];
% align_all = [];
% depth_all = [];
% depth_scaled = [];
% for sessionID = 1:maxsession
%     
% align_all = [align_all; allWaveforms(sessionID).traj.align_all];
% depth_all = [depth_all; allWaveforms(sessionID).traj.depth];
% ID_all = [ID_all; [allWaveforms(sessionID).traj.ID_all]];
% depth_scaled = [depth_scaled; allWaveforms(sessionID).traj.depth_scaled];
% 
% end
% %% clearing NANs
% a = ~isnan(align_all);
% align_= align_all(a);
% align_all = reshape(align_,[],572);
% 
% depth_all = depth_all(a(:,1));
% depth_scaled = depth_scaled(a(:,1));
% 
% ID_ = ID_all(a(:,1:2));
% ID_all = reshape(ID_,[],2);
% 
% norm_ = norm_all(a);
% norm_all = reshape(norm_,[],572);
%  %% Saving for Wavemap Input
% 
% %save('wavemap_Traj_input/alignedwaveforms.mat','align_all');
% %
% %save('wavemap_Traj_input/depth.mat','depth_all');
% % 
% %save('wavemap_Traj_input/ID.mat', 'ID_all', 'sessionID');
%  
% %save('wavemap_Traj_input/depth_scaled.mat','depth_scaled');
% 
% 
% % save('wavemap_Traj_input/depth_scaled.mat','depth');
% % 
% % % %% Saving manual sort
% % manualsort = cat(1,allWaveforms(1:p).avg_waveform);
% % manualsortID = cat(1,allWaveforms(1:p).avg_waveformID);
% % 21.091
% % 8.091
% % save('manualsort_allSessions.mat','manualsort')
% % save('manualsortID_allSessions.mat','manualsortID')
% %keyboard
% %% Saving for ISI output
% 
% %allWaveforms_clusters = struct('cluster', {allWaveforms(1:5).clusters});
% %allWaveforms_clusters = allWaveforms(2).clusters;
% 
% %save('allWaveforms_clusters.mat','allWaveforms_clusters');
% 
%% 8. Run WaveMAP on depth_neg_scaled array

%% 9. cluster Avg PSTH
% cluster_data_final
clusterFnData = readmatrix('/cluster_data_final.csv');
% 1  - Res 2.5  Clustering
% 2  - Raw Depth
% 3  - unit ID
% 4  - Session ID
% 5  - Orientation Index
% 6  - Orientation Cicular Variance
% 7  - Direction Index
% 8  - Direction Cicular Variance
% 9  - Orientation tuning fit_R35
% 10 - Orientation tuning Bandwidth
% 11 - simple complex
% 12 - vis resp
% 13 - umap_x
% 14 - umap_y
% 15 - Res 1.0 Clustering
% 16 - depth_scaled
% 17 - TP Dur
% 18 - Amplitude
% 19 - umap_x seed for paper
% 20 - umap_y seed for paper
% 21 - depth bins
% 22 - repWidth
% 23 - kurt
% 24 - FR
% 25 - kurt_2
% 26 - skew
% 27 - TP Type pass A
% 28 - TP Type pass B
% 29 - TP Type
% 30 - ISI PC loadings3
% 31 - ISI PC loadings2
% 32 - ISI PC loadings1
% 33 - SNR
% 34 - layer 56 separate ids
vResp = clusterFnData(:,12);
depthBins = clusterFnData(:,21);
clusterFnData = clusterFnData(find(vResp), :);
clusterFn = clusterFnData(:,15)+1;
depth_bins_L56Fn = clusterFnData(:,34);
depth_bins = clusterFnData(:,21);
sessionFn = clusterFnData(:,4);
ID = clusterFnData(:,3);




for sessionID = 1:max(sessionFn)
    sessionI = clusterFnData(:,4) ==sessionID;
    for clusterID = 1:max(clusterFn)
        allWaveforms(sessionID).clusters(clusterID).ID = ID(sessionI & clusterFn ==clusterID);
        allWaveforms(sessionID).clusters(clusterID).depth_bins = depth_bins(sessionI & clusterFn ==clusterID);
        allWaveforms(sessionID).clusters(clusterID).vis_resp = vResp(sessionI & clusterFn ==clusterID);
    end
end
% Waveforms
for sessionID = 1:max(sessionFn)
    sessionI = clusterFnData(:,4) ==sessionID;
    for clusterID = 1:max(clusterFn)
        allWaveforms(sessionID).clusters(clusterID).waveform = extractarray(allWaveforms(sessionID).waveform.ID_all(:,1),allWaveforms(sessionID).clusters(clusterID).ID,allWaveforms(sessionID).waveform.align_all);
        %figure
        %plot(allWaveforms(sessionID).clusters(clusterID).waveform')
    end

end

% laminar depth
avgLayerBounds = [ -488 -990; 0 -488; 285.4 0; 588.8 285.4; 1039.4 588.8];
for sessionID = 1:max(sessionFn)
    sessionI = clusterFnData(:,4) ==sessionID;
    for clusterID = 1:max(clusterFn)
        allWaveforms(sessionID).clusters(clusterID).depth = extractarray(allWaveforms(sessionID).waveform.ID_all(:,1),allWaveforms(sessionID).clusters(clusterID).ID,allWaveforms(sessionID).waveform.depth_all);
        allWaveforms(sessionID).clusters(clusterID).depth_scaled = extractarray(allWaveforms(sessionID).avg_waveformID,allWaveforms(sessionID).clusters(clusterID).ID,allWaveforms(sessionID).scaled_depth);
        allWaveforms(sessionID).clusters(clusterID).layerID = extractarray(allWaveforms(sessionID).avg_waveformID,allWaveforms(sessionID).clusters(clusterID).ID,allWaveforms(sessionID).layerId);
        allWaveforms(sessionID).clusters(clusterID).layerID_L56 = extractarray(allWaveforms(sessionID).avg_waveformID,allWaveforms(sessionID).clusters(clusterID).ID,allWaveforms(sessionID).layerId_L56);
        allWaveforms(sessionID).clusters(clusterID).snr = extractarray(allWaveforms(sessionID).avg_waveformID,allWaveforms(sessionID).clusters(clusterID).ID,allWaveforms(sessionID).snr);
        %figure
        %plot(allWaveforms(sessionID).clusters(clusterID).waveform')
    end
end


%% 10. cluster colors
res1_0 = {'#054b7d','#2e94db','#fe7f2d','#9d0208','#f0cb67','#416EB6','#00c49a','#17A9C9','#896B29'};
colors_gen ={'#93CEB3','#C5E3EA','#F2D0BF'};%,'#9d0208','#f0cb67','#8bcdfc','#00c49a','#35c8db','#ab8620'}; Old colors
colors_layer = {'#B9529F','#3953A4','#6ABD45','#E8D652','#5C21EA','#ffffff'}; % 5/6, 4C, 4AB, 2/3, WM, NAN
colors_cluster = {'#054b7d','#416EB6','#fe7f2d','#9d0208','#f0cb67','#8bcdfc','#00c49a','#17A9C9','#896B29'};
colors_7 = {'#33BA97','#287C64','#FFFFFF'};
colors = colors_cluster;
clusterColors = [];
layerColors = [];
for colorID = 1:length(colors)

    currColor = hex2rgb(colors(colorID));
    clusterColors = [clusterColors, {currColor}];

end

colors = clusterColors;


%% 11. generate PSTH


for sessionID = 1:5
    fprintf('\n%d.', sessionID);
    for clusterID = 1:max(clusterFn)
        fprintf('%d',clusterID);
        templateIDpercluster = allWaveforms(sessionID).clusters(clusterID).ID;
        allPSTHs = [];
        avgPSTH = [];
        for unitID = 1:size(templateIDpercluster)
            currWaveform = allWaveforms(sessionID).waveform.ID_neg(unitID);
            allSpikeTimes = allWaveforms(sessionID).spike_timing(allWaveforms(sessionID).spike_ID==[templateIDpercluster(unitID)]);
            stimTimes = allWaveforms(sessionID).stim_on;  
            
            currData = [];
            preTime = 50;
            postTime = 1050;
            spkMatrix = zeros(length(stimTimes),preTime+postTime+1);
            
            g = normpdf([-0.2:0.001:0.2],0,0.013);
            psthv = [];
            allTimes = [];
            
            try
                for j=1:length(stimTimes)
                    currData(j).spikes = [allSpikeTimes(allSpikeTimes >= stimTimes(j)-preTime/1000 & ...
                    allSpikeTimes <= stimTimes(j)+postTime/1000)]-stimTimes(j);
                    
                    currTimes = ceil(1000*currData(j).spikes + preTime);
                    spkMatrix(j,currTimes) = 1;
                    psthv(j,:) = conv(spkMatrix(j,:),g,'same');clea 
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
                nTrialsPerCondition(j,:) = size(psthv(actualConds == conds(j),:));
            end
            fprintf('.');
            
            allPSTHs(unitID,:,:) = psthPerCondition;
            allTrialsPerPSTH(unitID,:,:) = nTrialsPerCondition;
  
        end
        %keyboard
        
        %figure
        %plot(mean(avgPSTH))
        allWaveforms(sessionID).clusters(clusterID).avgPSTH = avgPSTH;
        allWaveforms(sessionID).clusters(clusterID).psthPerCondition = allPSTHs;
        allWaveforms(sessionID).clusters(clusterID).nTrialsPerCOndition = allTrialsPerPSTH;
%       end
    end
end


%% 12. generate avg PSTH

% time window

t = [-50:1050];
tIdx = [t > -50 & t < 500];

%
fig = figure;

colors = clusterColors;
alpha = 0.2;
bigPSTH = [];
ids = [];
layerId = 1;
maxFR =[];
cluster_ID = [];
for clusterID= 1:9
    
    concatIDs = [];
    concatPSTH = [];
    cnt = 1;
    clusterID
    for sessionID = 1:5
        %For each unit, find the condition that had the highest average
        %spikes/s
        currSessPSTH = allWaveforms(sessionID).clusters(clusterID).psthPerCondition;
        %currSessPSTH = allWaveforms(sessId).clusters(clusterID).psthPerCondition(allWaveforms(sessId).clusters(clusterID).layerID == layerId ,:,:);
        meanOverTime = nanmean(currSessPSTH(:,:,200:800),3);
        %size(meanOverTime);
        [~,maxCond] = max(meanOverTime,[],2);
        cluster_ID = [cluster_ID; allWaveforms(sessionID).clusters(clusterID).ID , sessionID*ones(size(allWaveforms(sessionID).clusters(clusterID).ID))];
        %For each unit, and its optimal condition, what is the PSTH?
        for ix=1:length(maxCond)
            V = squeeze(currSessPSTH(ix,maxCond(ix),:));
            concatPSTH(cnt,:) = [V];
            cnt = cnt + 1;
        end
    end
    concatPSTH = concatPSTH(:,tIdx);
    size(concatPSTH)
    maxFR = [maxFR; max(concatPSTH')'];
    PSTH_mean = nanmean(concatPSTH);
    tNew = t(tIdx);
    
    plot(tNew, PSTH_mean, 'color', colors{clusterID});
    hold on
    PSTH_sem = nanstd(concatPSTH)./sqrt(size(concatPSTH,1));
    
    patch = fill([tNew fliplr(tNew)] , [PSTH_mean+PSTH_sem fliplr(PSTH_mean-PSTH_sem)], colors{clusterID});
    set(patch, 'edgecolor', 'none','FaceAlpha', alpha );
    hold on
    ids = [ids clusterID*ones(1, size(concatPSTH,1))];
    bigPSTH = [bigPSTH; concatPSTH];
    %size(bigPSTH)
    
end
title('avg PSTH per preferred orientation')
xlabel('Time (ms)')
ylabel('Firing Rate')
set(gca,'box','off','TickDir','out') 
xline([0])
set(gcf,'renderer','Painters')
ylim([0 40])
%saveas(fig, 'PSTH_neg.pdf','pdf')
%print -depsc -tiff -r300 -painters avgPSTHforPoster.eps
%

%PSTH by Layer
alpha = 0.2;
bigPSTH = [];
ids = [];
layerId = 1;
maxFR =[];
cluster_ID = [];
layers = {'Layer 5/6', 'Layer 4c', 'Layer 4b', 'Layer 2/3', 'WM'};
layerColors = {'m', 'b','g','r', 'k'};
for layerID = [1 2 3 4]
    figure
    bigPSTH = [];
    for sessionID= [1 2 3 4 5 6 7 8 9]% 3 4 5 9]
        
        concatIDs = [];
        concatPSTH = [];
        cnt = 1;
        for sessionID = [ 4 5]
            
            %currSessPSTH = allWaveforms(sessId).clusters(clusterID).psthPerCondition;
            %currSessPSTH = allWaveforms(sessionID).clusters(clusterID).psthPerCondition((allWaveforms(sessionID).clusters(clusterID).layerID == layerID & allWaveforms(sessionID).clusters(clusterID).vis_resp == 1),:,:);
            
            currSessPSTH = allWaveforms(sessionID).clusters(clusterID).psthPerCondition((allWaveforms(sessionID).clusters(clusterID).layerID == layerID),:,:);
            meanOverTime = nanmean(currSessPSTH(:,:,200:800),3);
            [~,maxCond] = max(meanOverTime,[],2);
            
            for ix=1:length(maxCond)
                V = squeeze(currSessPSTH(ix,maxCond(ix),:));
                concatPSTH(cnt,:) = [V];
                cnt = cnt + 1;
            end
            
        end
        %concatPSTH = concatPSTH(:,tIdx);
        %size(concatPSTH)
        if size(concatPSTH,1) > 8
            concatPSTH = concatPSTH(:,tIdx);
            PSTH_mean = nanmean(concatPSTH);
            tNew = t(tIdx);
            plot(tNew, PSTH_mean, 'color', colors{clusterID});
            hold on
            PSTH_sem = nanstd(concatPSTH)./sqrt(size(concatPSTH,1));
            
            patch = fill([tNew fliplr(tNew)] , [PSTH_mean+PSTH_sem fliplr(PSTH_mean-PSTH_sem)], colors{clusterID});
            set(patch, 'edgecolor', 'none','FaceAlpha', alpha );
            hold on
            ids = [ids clusterID*ones(1, size(concatPSTH,1))];
            bigPSTH = [bigPSTH; concatPSTH];
            % size(bigPSTH)
            title(sprintf([' Layer ', layers{layerID}]));
            ylim([0 70]);
            xline([0])
            set(gcf,'renderer','Painters')
            set(gca,'box','off','TickDir','out') 
        else
            %concatPSTH = [concatPSTH; concatPSTH];
            concatPSTH = [concatPSTH; NaN(1,1101)];
        end
    end
    %bigPSTH = bigPSTH(:,tIdx);
    PSTH_mean = nanmean(bigPSTH);
    PSTH_sem = nanstd(bigPSTH)./sqrt(size(bigPSTH,1));
    figure(5);
    plot(t(tIdx), PSTH_mean, 'color',layerColors{layerID});
    hold on
    patch = fill([tNew fliplr(tNew)] , [PSTH_mean+PSTH_sem fliplr(PSTH_mean-PSTH_sem)], layerColors{layerID});
    set(patch, 'edgecolor', 'none','FaceAlpha', alpha );
    hold on;
end
%title('avg PSTH per preferred orientation')
xlabel('Time (ms)')
ylabel('Firing Rate')
set(gca,'box','off','TickDir','out') 
xline([0])
%saveas(fig, 'PSTH_neg.pdf','pdf')

set(gcf,'renderer','Painters')


% % Sanity Check x2
% 
% CNT = 0;
% for layerID = 1:4
%     bigPSTH = [];
%     
%     for clusterID = 1:9
%         concatPSTH = [];
%         cnt = 1;
%         for sessionID = 1:3
%             currLayer = allWaveforms(sessionID).clusters(clusterID).layerID == layerID;
%             vResp = allWaveforms(sessionID).clusters(clusterID).vis_resp == 1;
%             currSessPSTH = allWaveforms(sessionID).clusters(clusterID).psthPerCondition((currLayer & vResp),:,:);
%             %currSessPSTH = allWaveforms(sessionID).clusters(clusterID).psthPerCondition((allWaveforms(sessionID).clusters(clusterID).layerID == layerID & allWaveforms(sessionID).clusters(clusterID).vis_resp == 1),:,:);
%        
%             % find average FR for each condition
%             meanOverTime = nanmean(currSessPSTH(:,:,200:800),3);
%             % Find max condition
%             [~,maxCond] = max(meanOverTime,[],2);
%             % For each unit, find PSTH for that max condition
%             for ix=1:length(maxCond)
%                 maxCondPSTH = squeeze(currSessPSTH(ix,maxCond(ix),:));
%                 concatPSTH(cnt,:) = [maxCondPSTH];
%                 cnt = cnt + 1;
%                 CNT = CNT +1;
%             end
%             %concatPSTH has the max cond PSTH for each unit in that
%             %session, cluster, layer
%             
%             
% 
%         end
%                     % big PSTH stores all max cond PSTHs for that layer
%             bigPSTH = [bigPSTH; concatPSTH];
%     end
%     size(bigPSTH)
%     bigPSTH = bigPSTH(:,tIdx);
%     PSTH_mean = nanmean(bigPSTH);
%     PSTH_sem = nanstd(bigPSTH)./sqrt(size(bigPSTH,1));
%     figure(20);
%     tNew = t(tIdx)-60;
%     plot(tNew, PSTH_mean, 'color',layerColors{layerID});
%     hold on
%     patch = fill([tNew fliplr(tNew)] , [PSTH_mean+PSTH_sem fliplr(PSTH_mean-PSTH_sem)], layerColors{layerID});
%     set(patch, 'edgecolor', 'none','FaceAlpha', alpha );
%     hold on;
% end
% 
% 
% for layerID = 1:4
%     bigPSTH = [];
%     for clusterID = 1:9
%         concatPSTH = [];
%         cnt = 1;
%         for sessionID = 4:5
%             currLayer = allWaveforms(sessionID).clusters(clusterID).layerID == layerID;
%             vResp = allWaveforms(sessionID).clusters(clusterID).vis_resp == 1;
%             %currSessPSTH = allWaveforms(sessionID).clusters(clusterID).psthPerCondition((allWaveforms(sessionID).clusters(clusterID).layerID == layerID),:,:);
%             currSessPSTH = allWaveforms(sessionID).clusters(clusterID).psthPerCondition((currLayer & vResp),:,:);
% 
%             
%             % find average FR for each condition
%             meanOverTime = nanmean(currSessPSTH(:,:,200:800),3);
%             % Find max condition
%             [~,maxCond] = max(meanOverTime,[],2);
%             % For each unit, find PSTH for that max condition
%             for ix=1:length(maxCond)
%                 maxCondPSTH = squeeze(currSessPSTH(ix,maxCond(ix),:));
%                 concatPSTH(cnt,:) = [maxCondPSTH];
%                 cnt = cnt + 1;
%                 CNT = CNT+1;
%             end
%             %concatPSTH has the max cond PSTH for each unit in that
%             %session, cluster, layer
%             
%             
% 
%         end
%                     % big PSTH stores all max cond PSTHs for that layer
%             bigPSTH = [bigPSTH; concatPSTH];
%     end
%     size(bigPSTH)
%     bigPSTH = bigPSTH(:,tIdx);
%     PSTH_mean = nanmean(bigPSTH);
%     PSTH_sem = nanstd(bigPSTH)./sqrt(size(bigPSTH,1));
%     figure(21);
%     tNew = t(tIdx)-60;
%     plot(tNew, PSTH_mean, 'color',layerColors{layerID});
%     hold on
%     patch = fill([tNew fliplr(tNew)] , [PSTH_mean+PSTH_sem fliplr(PSTH_mean-PSTH_sem)], layerColors{layerID});
%     set(patch, 'edgecolor', 'none','FaceAlpha', alpha );
%     hold on;
% end
% 
% %CNT Should equal 591 ( all units in layerIDs 1-4 )
%        
% % Sanity Check
% figure
% for sessionID = 4:5
%    for clusterID = 1:9
%        for layerID = 4
%            
%        currSessPSTH = allWaveforms(sessionID).clusters(clusterID).avgPSTH((allWaveforms(sessionID).clusters(clusterID).layerID == layerID),:)';
%             
%        plot(currSessPSTH, 'color',layerColors{layerID});
%         hold on
%        end
%    end
% end
% 
% 
% 
% % Saving figure
% set(gcf,'renderer','Painters')
% xline([0])
% set(gca,'box','off') 
% %print -depsc -tiff -r300 -painters avgPSTHforPoster.eps
%     
%     
% % All PSTHs
%     
% bigPSTH = bigPSTH';
% bigPSTH_pca = bigPSTH./repmat(max(bigPSTH),[size(bigPSTH,1) 1]);
% [coeff, score, varExplained] = pca(bigPSTH_pca);
% 
% 
% %
% figure;
% for clusterID = 1:max(clusterFn)
%     plot(coeff(ids==clusterID,1), coeff(ids==clusterID,2),'o','color',colors{clusterID});
%     hold on
% end
% 
% 
% %
% %
% [pdca] = fitdist(bigPSTH(:,1),'Gamma')
% %
% %
% %
% %%%%%%%%%%%%
% % PSTH by Layer
% alpha = 0.2;
% bigPSTH = [];
% ids = [];
% layerId = 1;
% maxFR =[];
% cluster_ID = [];
% layers = {'Layer 5/6', 'Layer 4c', 'Layer 4b', 'Layer 2/3', 'WM'};
% layerColors = {'m', 'b','g','r', 'k'};
% for layerID = [1 2 3 4]
%     figure
%     bigPSTH = [];
%     for sessionID= [1 2 3]
%         
%         concatIDs = [];
%         concatPSTH = [];
%         cnt = 1;
%         for clusterID = [1 2 3 4 5 6 7 8 9]
%              
%             %currSessPSTH = allWaveforms(sessId).clusters(clusterID).psthPerCondition;
%             %currSessPSTH = allWaveforms(sessionID).clusters(clusterID).psthPerCondition((allWaveforms(sessionID).clusters(clusterID).layerID == layerID & allWaveforms(sessionID).clusters(clusterID).vis_resp == 1),:,:);
%             
%             currSessPSTH = allWaveforms(sessionID).clusters(clusterID).psthPerCondition((allWaveforms(sessionID).clusters(clusterID).layerID == layerID),:,:);
%            
%        
%         % find average FR for each condition
%         meanOverTime = nanmean(currSessPSTH(:,:,200:800),3);
%         % Find max condition
%             [~,maxCond] = max(meanOverTime,[],2);
%             % For each unit, find PSTH for that max condition
%             for ix=1:length(maxCond)
%                 V = squeeze(currSessPSTH(ix,maxCond(ix),:));
%                 concatPSTH(cnt,:) = [V];
%                 cnt = cnt + 1;
%             end
%             
%         end
%         %concatPSTH = concatPSTH(:,tIdx);
%         %size(concatPSTH)
%         if size(concatPSTH,1) > 2
%             concatPSTH = concatPSTH(:,tIdx);
%             PSTH_mean = nanmean(concatPSTH);
%             tNew = t(tIdx);
%             plot(tNew, PSTH_mean, 'color', colors{clusterID});
%             hold on
%             PSTH_sem = nanstd(concatPSTH)./sqrt(size(concatPSTH,1));
%             
%             patch = fill([tNew fliplr(tNew)] , [PSTH_mean+PSTH_sem fliplr(PSTH_mean-PSTH_sem)], colors{clusterID});
%             set(patch, 'edgecolor', 'none','FaceAlpha', alpha );
%             hold on
%             ids = [ids clusterID*ones(1, size(concatPSTH,1))];
%             bigPSTH = [bigPSTH; concatPSTH];
%             % size(bigPSTH)
%             title(sprintf([' Layer ', layers{layerID}]));
%             ylim([0 70]);
%             xline([0])
%             set(gcf,'renderer','Painters')
%             set(gca,'box','off','TickDir','out') 
%         else
%             % concatPSTH = [concatPSTH; concatPSTH];
%             concatPSTH = [concatPSTH; NaN(1,1101)];
%         end
%     end
%     %bigPSTH = bigPSTH(:,tIdx);
%     PSTH_mean = nanmean(bigPSTH);
%     PSTH_sem = nanstd(bigPSTH)./sqrt(size(bigPSTH,1));
%     figure(10);
%     plot(t(tIdx), PSTH_mean, 'color',layerColors{layerID});
%     hold on
%     patch = fill([tNew fliplr(tNew)] , [PSTH_mean+PSTH_sem fliplr(PSTH_mean-PSTH_sem)], layerColors{layerID});
%     set(patch, 'edgecolor', 'none','FaceAlpha', alpha );
%     hold on;
% end
% %title('avg PSTH per preferred orientation')
% xlabel('Time (ms)')
% ylabel('Firing Rate')
% set(gca,'box','off','TickDir','out')
% xline([0])
% %saveas(fig, 'PSTH_neg.pdf','pdf')
% 
% set(gcf,'renderer','Painters')
% 
%

%% At this point in the analysis, initFigures can be picked up.

%% 13. Generate ISI

alpha = 0.2;
avgISI = [];
errorISI = [];
concatSpikeTimes = {};
figure
bigK = [];
bigCluster = [];
for clusterID = [1 2 6 8 7 3 4 5 9]
    cnt = 1;
    ISIvalues = [];
    ISIdensity = [];
    layerIdvalues = [];
    CV = [];
    for sessionID = 1:5
        sessISIvalues = [];
        sessISIdensity = [];
        varISI = [];
        meanISI = [];
        cluster_ID = allWaveforms(sessionID).clusters(clusterID).ID;
        D = [0:0.0004:0.025];
        
        for unitID = 1:size(cluster_ID)
            
            allSpikeTimes = allWaveforms(sessionID).spike_timing(allWaveforms(sessionID).spike_ID==[cluster_ID(unitID)]);
            stimTimes = allWaveforms(sessionID).stim_on;
            
            figure(1);
            xlabel('Bin Size (s)') 
            ylabel('Spike Probability')
            h = histogram(diff(allSpikeTimes),D,'Normalization','probability');
            
            
            ISIdensity(cnt,:) = h.Values;
            ISIvalues = [ISIvalues diff(allSpikeTimes)'];
            varISI(unitID,:) = nanstd(diff(allSpikeTimes));
            meanISI(unitID,:) = nanmean(diff(allSpikeTimes));
            sessISIdensity(unitID,:) = h.Values;
            sessISIvalues = [sessISIvalues diff(allSpikeTimes')];
            cnt = cnt + 1;
            hold off;
        end
        bigCluster = [bigCluster ; cluster_ID , sessionID*ones(size(cluster_ID))];
        allWaveforms(sessionID).clusters(clusterID).ISIvalues = sessISIvalues;
        allWaveforms(sessionID).clusters(clusterID).ISIdensity = sessISIdensity;
        allWaveforms(sessionID).clusters(clusterID).kurt = kurtosis(sessISIdensity,1,2);
        allWaveforms(sessionID).clusters(clusterID).varISI = varISI;
        allWaveforms(sessionID).clusters(clusterID).meanISI = meanISI;
        allWaveforms(sessionID).clusters(clusterID).CV = varISI./meanISI;
        
    end
    
    concatSpikeTimes{clusterID} = ISIdensity;
    avgISI(clusterID,:) = nanmean(ISIdensity);
    errorISI(clusterID,:) = nanstd(ISIdensity)./sqrt(cnt);
    
    kurt{clusterID} = kurtosis(ISIdensity,1,2);
    skew{clusterID} = skewness(ISIdensity,1,2);
    fig = figure(2);
    shaded_errorbar(D(1:end-1), avgISI(clusterID,:),errorISI(clusterID,:),colors{clusterID},alpha)
    
    bigK = [bigK; kurt{clusterID} skew{clusterID} clusterID*ones(size(kurt{clusterID},1),1)];
    
end
xlabel('Bin Size [s]')
ylabel('Spike Probability')
title('avg ISI Density')

%% 14. Bin Depths


negcombinedLayer = [];
combinedCluster = [];



for sessionID = 1:5
    
    originalIDs = allWaveforms(sessionID).avg_waveformID;
    desiredIDs = allWaveforms(sessionID).waveform.ID_neg(:,1);
    originalarray = allWaveforms(sessionID).layerId;
    
    
    depthBin = extractarray(originalIDs, desiredIDs, originalarray);
    depthBin(isnan(depthBin))=6;
    allWaveforms(sessionID).waveform.depthBin = depthBin;
    
    for clusterID = 1:max(clusterFn)
        originalIDs = allWaveforms(sessionID).waveform.ID_neg(:,1);
        desiredIDs = allWaveforms(sessionID).clusters(clusterID).ID(:,1);
        originalarray = allWaveforms(sessionID).waveform.depthBin;
        
        depthBinCluster  = extractarray(originalIDs, desiredIDs, originalarray);
        allWaveforms(sessionID).clusters(clusterID).depthBinCluster = depthBinCluster;
        negcombinedLayer = [negcombinedLayer; depthBinCluster];
    end
end


[table,chi2,p] = crosstab(clusterFn,negcombinedLayer)



%% 15. Adding to final cluster Fn
allAmps = [];
allTP = [];
alldepth_bin = [];
allRepWidth = [];
allSNR = [];
alllayerId_L56 =[];

for sessionID = 1:5
        
    size(allWaveforms(sessionID).waveform.ID_neg)
    [ampp, ampIDs, ~, ~] = extractarray(allWaveforms(sessionID).avg_waveformID, allWaveforms(sessionID).waveform.ID_neg(:,1), allWaveforms(sessionID).amp);
    allAmps = [allAmps; ampp];
    
    [tp_dur, tpIDs, ~, ~] = extractarray(allWaveforms(sessionID).avg_waveformID, allWaveforms(sessionID).waveform.ID_neg(:,1), allWaveforms(sessionID).tp_dur);
    allTP = [allTP; tp_dur];
    
    [depth_bin, depth_binIDs, ~, ~] = extractarray(allWaveforms(sessionID).avg_waveformID, allWaveforms(sessionID).waveform.ID_neg(:,1), allWaveforms(sessionID).layerId);
    alldepth_bin = [alldepth_bin; depth_bin];
    
    [SNR, SNRIDs, ~, ~] = extractarray(allWaveforms(sessionID).avg_waveformID, allWaveforms(sessionID).waveform.ID_neg(:,1), allWaveforms(sessionID).snr);
    allSNR = [allSNR; SNR];

    [repWidth, repWidthIDs, ~, ~] = extractarray(allWaveforms(sessionID).avg_waveformID, allWaveforms(sessionID).waveform.ID_neg(:,1), allWaveforms(sessionID).repWidth);
    allRepWidth = [allRepWidth; repWidth];

    [layerId_L56, layerId_L56IDs, ~, ~] = extractarray(allWaveforms(sessionID).avg_waveformID, allWaveforms(sessionID).waveform.ID_neg(:,1), allWaveforms(sessionID).layerId_L56);
    alllayerId_L56 = [alllayerId_L56; layerId_L56];

end



%% 16 layer counts
cluster_layercount = zeros(9,7);
for clusterID = 1:9
for layerID = 1:7
matches = clusterFn==clusterID & depth_bins_L56Fn==layerID;
cluster_layercount(clusterID,layerID) = sum(matches);
end
end
  
layercount = [];
for layerID = 1:7
    
    matches = depth_bins_L56Fn==layerID;
    layercount(layerID) = sum(matches);
end

