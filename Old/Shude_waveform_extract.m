clc;        % Clear Command Window
%close all;  % Close all figures
clear all;  % Erase all existing variables
workspace;  % Make sure the workspace panel is showing
% This program requires:
% - folder containing data structures
% - function reshape_min_waveforms()
% - function reshape_max_waveforms()
%% Parsing for data structures folder
% Parse through folder for waveform templates and associated data
% Creates struct containing this information
matFiles = dir('*.mat');
% Initialize
allWaveforms = struct([]);
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
%% Parsing through folder for waveforms
for j = 1:3 %length(matFiles)
    % Load current datastructure
    matFilename = fullfile(pwd, matFiles(j).name);
    s = load(matFilename);
    fprintf('\n %d:',j);
    allWaveforms(j).template = s.templates.template_waves;
    allWaveforms(j).snr = s.templates.template_snr;
    allWaveforms(j).depth = s.templates.template_depth_relativetolayer4;
    allWaveforms(j).layerId = s.templates.template_layerID;
    

    %% Plotting waveforms
    [~,idx] = sort(allWaveforms(j).snr,'descend');
    validChans = [1:384];
   figure

    for i = 1:size(idx,1)
%% For each template - extract the maximum waveform
        X = squeeze(allWaveforms(j).template(idx(i),validChans,:));
        X = X - repmat(nanmean(X,2),[1 size(X,2)]);
        ampls = max(X,[],2)-min(X,[],2);
        [~,maxLoc] = max(ampls);
        % maximum waveform from template
        X = X(maxLoc,:);

%% Sort out bad snr values, ie. low snrs or snr of -1 : too few corresponding spikes
        if allWaveforms(j).snr(i) == -1 | allWaveforms(j).snr(i) < 1 | abs(X(1)) > 45
            poor = [poor; X];
        else
            good = [good; X];
            depth = allWaveforms(j).depth(idx(i));
            %hold on
            %plot(X)

            % Sort out positive spiking
            [y1, t1] = max(X);
            [y2, t2] = min(X);
            TtP = y1-y2;
            Slope = (y1-y2)/(t1-t2);
            
            SEM = std(X)/sqrt(length(X));
            temp = X; %./abs(y1-y2);
            %temp = rescale(temp,-1,1);
            %temp = (temp-mean(temp))./std(temp);
            
            norm = [norm; temp]; 
            
%% Positive spiking 
            if t1 < t2 %if max peak occurs before min peak = pos spike
                %Reshape pos spiking waveforms
                pos = [pos; X];
                norm_pos = [norm_pos; temp];
                try
                    temp = reshape_max_waveforms(temp);
                    
                    align_pos = [align_pos; temp];
                    depth_pos = [depth_pos; depth];
                catch
                    actionmsg = sprintf('Unable to resolve %d, skipped.',i)
                end
%% Negative Spiking
            elseif t1 > t2 %if max peak occurs after min peak = neg spike
                neg = [neg; X];
                norm_neg = [norm_neg; temp];
                %Reshape neg spiking waveforms
                try
                    temp = reshape_min_waveforms(temp);
                    align_neg = [align_neg; temp];
                    depth_neg = [depth_neg; depth];
                    
                catch
                    actionmsg = sprintf('Unable to resolve %d, skipped.',i)
                end               
            end
        end      
    end
%% store reshaped waveforms
    align_all = [align_neg; align_pos]; 
    allWaveforms(j).good = [good];
    allWaveforms(j).poor = [poor];

    
%% normalized
    currTraj2=align_neg';
    normalizedwaveformsneg = bsxfun(@rdivide,currTraj2,max(abs(currTraj2)));
    
    currTraj1=align_pos';
    normalizedwaveformspos = bsxfun(@rdivide,currTraj1,max(abs(currTraj1)));
    
    currTraj3=align_all';
    normalizedwaveforms = bsxfun(@rdivide,currTraj3,max(abs(currTraj3)));
    
    allWaveforms(j).norm_neg = normalizedwaveformsneg';
    allWaveforms(j).norm_pos = normalizedwaveformspos';
    allWaveforms(j).norm_all = normalizedwaveforms';
    allWaveforms(j).depth_neg = depth_neg;
    allWaveforms(j).depth_pos = depth_pos;

    %% normalized waveform figure
    subplot(2,1,1)
    hold on
    title(sprintf(['S',num2str(j),' Waveforms']))
    ylabel('Normalized Amplitude')
    xlabel('Time samples at 30000 Hz')
    plot(normalizedwaveformspos,'color',[0.2275    0.5961    0.8392])
    plot(normalizedwaveformsneg,'color',[ 0.8902    0.5176    0.5176])
    
    %% laminar figure
    subplot(2,1,2)
    hold on
    for m = 1:size(allWaveforms(j).norm_neg,1)
        d = allWaveforms(j).norm_neg(m,:)+allWaveforms(j).depth_neg(m);
        %depth_all = [depth_all ; d];
        plot(d,'color',[ 0.8902    0.5176    0.5176])
    end
    
    for n = 1:size(allWaveforms(j).norm_pos,1)
        d = allWaveforms(j).norm_pos(n,:)+allWaveforms(j).depth_pos(n);
        plot(d,'color',[0.2275    0.5961    0.8392])
        
    end
    allWaveforms(j).depth_all = [depth_neg; depth_pos];
end
%% concatenating
align_neg = cat(1,allWaveforms(1:3).norm_neg); 
align_pos = cat(1,allWaveforms(1:3).norm_pos); 
align_all = cat(1,allWaveforms(1:3).norm_all);

depth_all = cat(1,allWaveforms(1:3).depth_all);
depth_neg = cat(1,allWaveforms(1:3).depth_neg);
depth_pos = cat(1,allWaveforms(1:3).depth_pos);
% %% aligned and normalized waveforms
% figure 
% hold on
% plot(align_neg')
% plot(align_pos')


%% Saving
save('normalizedwaveforms.mat','align_all');
save('normalizednegwaveforms.mat','align_neg');
save('normalizedposwaveforms.mat','align_pos');

save('depth.mat','depth_all');
save('depth_neg.mat','depth_neg');
save('depth_pos.mat','depth_pos');


