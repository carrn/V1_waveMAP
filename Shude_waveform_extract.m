clc;
close all;
clear all;  % Erase all existing variables
workspace;  % Make sure the workspace panel is showing

% This program requires: 
% - folder containing data structures
% - function reshape_min_waveforms()

%% Parsing for data structures folder
% Open folder with data structures
[myFolder] = uigetdir(['MATLAB/', 'Pick a Folder']); 

 if myFolder == 0
    %User clicked the Cancel button.
   return;
 end

% Parse through folder for waveform templates and associated data
% Creates struct containing this information
matFiles = dir('*.mat');


% Initialize
count = 1;
allWaveforms = struct([]);
%nowaveforms = [];
%totwaveforms = [];
%t = -1;

%% Parsing through folder for waveforms
for j = 1%:length(matFiles)
    % Load current datastructure
    matFilename = fullfile(myFolder, matFiles(j).name);
    s = load(matFilename); 
    
    fprintf('\n %d:',j);
    
    allWaveforms(j).template = s.templates.template_waves;
    allWaveforms(j).snr = s.templates.template_snr;
    allWaveforms(j).depth = s.templates.template_depth_relativetolayer4;
    allWaveforms(j).layerId = s.templates.template_layerID;
    
 end

%% Plotting waveforms

[~,idx] = sort(allWaveforms.snr,'descend');
validChans = [1:384];
figure
align = [];
for i = 1:size(idx,1)
X = squeeze(allWaveforms.template(idx(i),validChans,:));
X = X - repmat(nanmean(X,2),[1 size(X,2)]);
%figure
%imagesc(X);
ampls = max(X,[],2)-min(X,[],2);
[~,maxLoc] = max(ampls);

temp = reshape_waveform(X(maxLoc,:));
align = [align; temp];

hold on
%figure
plot(X(maxLoc,:));
end

% for i = 1:
allWaveforms(count).align = align;
