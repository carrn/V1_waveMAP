% Previous steps:
%  - Shude_waveforms_extract_ID.m - Creates all waveforms and unit IDs
%  - Waves1.m - 2 Pass Manual Sort
%
% This program requires:
% - ouput from Manual Sort usually titled storage.mat (# units x 2 array)
%   with IDs that pass 2 rounds of filtering
% - reshape_min_waveforms()
% - reshape_max_waveforms()
%
% Outputs:
% - allWaveforms(sessionID).manual
%   This contains all manual passing IDs, depths and waveforms, with
%   separations of pos spiking, and neg spiking

manualWaveforms = load('manual_sort_output/storage20220516.mat');
passWaveforms = load('manual_sort_output/20220516/good2.mat');
manualWaveforms = manualWaveforms.storage;
passWaveforms = passWaveforms.good2;
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
