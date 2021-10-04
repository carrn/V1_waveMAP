clc;        % Clear Command Window
close all;  % Close all figures
clear all;  % Erase all existing variables
workspace;  % Make sure the workspace panel is showing
% This program requires:
% - folder containing .mat voltage traces of 374 channels x 82 time points x __ trials
%% Parsing for data structures folder
% Parse through folder for waveform templates and associated data
matFiles = dir('*_raw_voltage.mat');

% Initialize
allWaveforms = struct([]); % Creates struct containing this information
avgWaveforms = struct([]); % Creates struct containing Trace ID and averaged voltage
allTrials = zeros(size(matFiles));
count = 0;
tic
%% Parsing through folder for waveforms
for j = 1:length(matFiles)
    % Load current datastructure
    matFilename = fullfile(pwd, matFiles(j).name);
    voltage_unit = str2num(regexprep(matFiles(j).name,'_raw_voltage.mat',''));
    s = load(matFilename);
    fprintf('\n %d:',j); % Sanity check printing the number of the matFile
    allWaveforms(j).original = s.data;
    allWaveforms(j).names = voltage_unit;
    [allChans,timePoints,trial] = size(allWaveforms(j).original);
    validChans = zeros(allChans,2);
    allTrials(j) = trial;
    %% filter out insufficient trial number
    if trial < 50 % if trial count is insufficient, based on histogram of allTrials
        allWaveforms(j).data = NaN;
        allWaveforms(j).names = NaN;
    elseif trial >= 50
        allWaveforms(j).data = s.data;
        allChans = [1:allChans];
        trial = [1:trial];
        
        %% Remove Artifacts within Channels
        for i = 1:size(allChans,2)
            X = double(squeeze(allWaveforms(j).data(allChans(i),:,trial))); % 82 x 277 trials in each channel
            Z = sum(X.^2);
            mv = mean(Z);
            sv = std(Z);
            minI = find(Z < mv - 4*sv); % exclude as artifact if absolute squared sum is less than mean squared sum - 4 std
            maxI = find(Z > mv + 4*sv); % exclude as artifact if absolute squared sum is less than mean squared sum - 4 std
            if logical(minI) == true
                allWaveforms(j).data(allChans,:,minI) = NaN; 
            elseif logical(maxI) == true
                allWaveforms(j).data(allChans,:,maxI) = NaN; 
            end            
            Y = mean(squeeze(allWaveforms(j).data(allChans(i),:,trial))'); %1 x 82 average amplitude for the channel
            tp = max(Y)-min(Y);  % trough to peak amplitude of average excluding artifacts
            validChans(i,:) =  [[allChans(i), tp]];   % stores channel t-p amplitude
            minI = 0;
            maxI = 0;
        end
        %% Find Max Channel without Artifacts
        [M I] = max(validChans(:,2)); % max channel has the max trough to peak amplitude
        bestChan = double(squeeze(allWaveforms(j).data(allChans(I),:,trial)));
        %% Filter out insufficient trials within best channel
        IDX = any(bestChan,1);  % Trials containing nonzero values
        if sum(IDX) < 50   % If the best channel has insufficient trial counts, exclude
            bestChan = NaN;
            allWaveforms(j).names = NaN;
        elseif sum(IDX) >= 50  % otherwise continue to averaging step
            %% Averaging Trials in Best channel 
            bestChan = bestChan;
            numOfTrials = size(bestChan, 2);
            finalWave = zeros(size(bestChan)); %This is the final matrix to be averaged once filled    
            for i=1:numOfTrials
                waveCurr = bestChan(:,i);
                waveSd = nanstd(waveCurr);
                waveMean = nanmean(waveCurr);
                meanMat = waveCurr-waveMean;
                if(all(meanMat))% This step removes trials containing only 0s
                    if((meanMat)<6*waveSd) % This step removes trials outside 6 std of the mean; This step can be removed if too much data is excluded
                        if(abs(nanmean(meanMat))<0.4*waveSd)
                            finalWave(:,i) = waveCurr;
                        end 
                    end
                end
                Idx = any(finalWave,1);
                avg_waveform = mean(finalWave(:,Idx),2);
            end
            %% Sanity Check
            % This step is useful to uncomment if you believe you are
            % exluding too much data
            if sum(IDX)~=sum(Idx)
                J = sprintf(' filtered %d from %d',(sum(IDX)-sum(Idx)),sum(IDX));
                disp(J)
            elseif sum(IDX)==sum(Idx)
                J = sprintf(' filtered %d from %d',(sum(IDX)-sum(Idx)),sum(IDX));
                disp(J)
            end            
            %% storing data
            count = count +1;
            allWaveforms(j).bestChan = bestChan;
            allWaveforms(j).finalWave = finalWave;
            allWaveforms(j).average = avg_waveform;
            avgWaveforms(count).ID = voltage_unit;
            avgWaveforms(count).average = avg_waveform;

         end
    end
end
toc
%% Export averages
save('averaged_voltages.mat','avgWaveforms'); %