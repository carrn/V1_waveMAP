clc;
close all;
clear all;  % Erase all existing variables
workspace;  % Make sure the workspace panel is showing

% This program requires: 
% - folder containing data structures
% - function reshape_min_waveforms()

%% Parsing for data structures folder
% Open folder with data structures
[myFolder] = uigetdir(['matlab/', 'Pick a Folder']); 

 if myFolder == 0
    %User clicked the Cancel button.
   return;
 end

% Parse through folder for waveforms and associated data
% Creates struct containing this information
matFiles = dir('*.mat');


% Initialize
count = 1;
allWaveForms = struct([]);
nowaveforms = [];
totwaveforms = [];
t = -1;

%% Parsing through folder for waveforms
for j = 1:length(matFiles)
    % Load current datastructure
    matFilename = fullfile(myFolder, matFiles(j).name);
    s = load(matFilename); 
    
    fprintf('\n %d:',j);
    
    % Search for waveforms in values
    for i = 1:length(s.obj.eventSeriesHash.value)
        
        % Looks at waveform in current value
        currWaveforms = s.obj.eventSeriesHash.value{i}.waveforms;
        
        if ~isempty(currWaveforms) % if that value contains a waveform...
            % prints to command window
            fprintf('%d.',i);
            
            % format file name
            name = erase(matFiles(j).name,["data_structure_","-",".mat"]);
            p = num2str(i);
            name = strcat(name,'_value_',p);
            
            % store data into new structure
            allWaveForms(count).name = name;
            allWaveForms(count).data = currWaveforms;
            allWaveForms(count).quality =  s.obj.eventSeriesHash.value{i}.quality;
            allWaveForms(count).collision =  s.obj.eventSeriesHash.value{i}.collision.pass;
            
            % reshape the data into electrode waveforms
            try
                temp = reshape_min_waveforms(allWaveForms(count).data);
                % store reshaped waveforms
                allWaveForms(count).reshaped = temp;
            catch
                actionmsg = sprintf('Unable to resolve %s, skipped.',name)
                %temp = [];
                nowaveforms = [nowaveforms, temp];
            end
            
            % Store
            totwaveforms = [totwaveforms, temp];
            count = count + 1;
        else
            
        end
        
    end
    
end

count = count-1;

filtLength = size(totwaveforms);
fprintf('\n \nTotal number of waveforms: %d \n', filtLength(2))

filtLength = size(nowaveforms);
fprintf('Number of skipped waveforms: %d \n', filtLength(2))

%fprintf('\n Total number of waveforms: %d \n', count)

figure
hold on
plot(totwaveforms)
title('All Normalized Waveforms')

%% Filter
t = min(min(totwaveforms))*0.1;
threshqual1 = 'Excellent';
threshqual2 = 'Good';
threshqual3 = 'Fair';
threshqual4 = 'Poor';

filteredwaveforms = [];
PTL = [];
PTU = [];
nonTagged = [];

for k = 1:count
    temp = allWaveForms(k).reshaped;
    
    % Cell Quality
    if contains(allWaveForms(k).quality,threshqual1) ...
            | contains(allWaveForms(k).quality,threshqual2) ...
            | contains(allWaveForms(k).quality,threshqual3) ...
            | contains(allWaveForms(k).quality,threshqual4)

%          %Minimum Threshold
%         if min(temp) > t
%             temp = []; % discard if smaller than lower threshold
%             sprintf('Trough < 10% of max %s, skipped.',name);
%         else
%             % do nothing if pass threshold
%         end
        
    else
        sprintf('Quality Poor %s, skipped.',name);
        temp = []; %discard if poor quality
    end
    
    % Store
    filteredwaveforms = [filteredwaveforms, temp];
    
    
    % Optotagged
    if allWaveForms(k).collision == 1
        % 1 = optotagged
        isPTL = false;
        validPTL = {'369962','369963','369964','372974'};
        for p=1:length(validPTL)
            if ~isempty(strfind(allWaveForms(k).name, validPTL{p}))
                isPTL = true;
                break;
            end
            
        end
        
        if ~isPTL
            PTU = [PTU, temp];
        else
            PTL = [PTL, temp];
        end
                
    else
        % 0 = not optotagged
        % 0.5 = tagged but poor
        nonTagged = [nonTagged, temp];
    end
    
end
%% Normalize
% allwaveforms sorted into nontagged, PTL, PTU


% normailize all
normalizedplottedwaveforms= (bsxfun(@rdivide,filteredwaveforms,abs(min(filteredwaveforms))))';

% normailize nontagged
normalizednonTaggedwaveforms= (bsxfun(@rdivide,nonTagged,abs(min(nonTagged))))';

% normalize optotagged in PTL
normalizedPTLwaveforms= (bsxfun(@rdivide,PTL,abs(min(PTL))))';

% normalize optotagged in PTL
normalizedPTUwaveforms= (bsxfun(@rdivide,PTU,abs(min(PTU))))';


fprintf('\n --- Operation Complete --- \n')


%% Waveform Count
filtLength = size(normalizedplottedwaveforms);
fprintf('Number of plotted waveforms: %d \n', filtLength(1))

filtLength = size(normalizednonTaggedwaveforms);
fprintf('Number of nonTagged waveforms: %d \n', filtLength(1))

filtLength = size(normalizedPTLwaveforms);
fprintf('Number of PTL waveforms: %d \n', filtLength(1))

filtLength = size(normalizedPTUwaveforms);
fprintf('Number of PTU waveforms: %d \n', filtLength(1))

%% Plot
figure
hold on
plot(normalizedplottedwaveforms')
title('All Normalized Waveforms')
hold off


figure
hold on
handle1 = plot(normalizednonTaggedwaveforms','color',[0.8 0.8 0.8],'DisplayName','NonTagged');

handle2 = plot(normalizedPTUwaveforms', 'r-', 'DisplayName', 'Opto PTU');

handle3 = plot(normalizedPTLwaveforms', 'b-', 'DisplayName', 'Opto PTL');
hold off

legend([handle1(1) handle2(1) handle3(1)])
title('Sorted Normalized Waveforms')











