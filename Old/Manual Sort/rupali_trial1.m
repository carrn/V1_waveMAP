function varargout = rupali_trial1(varargin)

load('allWaveforms.mat')
load('AmpPerCluster.mat')
load('n_waveform.mat')
load('n_no.mat')
load('n_noisy.mat')

A = readmatrix('/cluster_data_final.csv');
%Clusters = struct
session = A(:,4);
%cluster = A(:,1)+1; % 2.5 res
cluster = A(:,15)+1;
ID = A(:,3);
vis_resp = A(:,12);

% RUPALI_TRIAL1 MATLAB code for rupali_trial1.fig
%      RUPALI_TRIAL1, by itself, creates a new RUPALI_TRIAL1 or raises the existing
%      singleton*.
%
%      H = RUPALI_TRIAL1 returns the handle to a new RUPALI_TRIAL1 or the handle to
%      the existing singleton*.
%
%      RUPALI_TRIAL1('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RUPALI_TRIAL1.M with the given input arguments.
%
%      RUPALI_TRIAL1('Property','Value',...) creates a new RUPALI_TRIAL1 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before rupali_trial1_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to rupali_trial1_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help rupali_trial1

% Last Modified by GUIDE v2.5 21-Apr-2023 09:24:25

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @rupali_trial1_OpeningFcn, ...
                   'gui_OutputFcn',  @rupali_trial1_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
end  

% --- Executes just before rupali_trial1 is made visible.
function rupali_trial1_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to rupali_trial1 (see VARARGIN)

global noisy
global nogood
global good
global x
global yesflag
global clusterID 
global sessionID
yesflag = 0;
good = [];
noisy = [];
nogood = [];

data_path = 'Shude_Waveforms/Shude_waveforms/Manual Sort/Shude/Spatial Profiles';
filename = 'allWaveforms.mat';
full_filename = fullfile(data_path, filename);
load(full_filename); 

for clusterID = 1:9
    for sessionID = 1:5
        unitID = 2;
        uId = allWaveforms(sessionID).clusters(clusterID).ID(unitID)+1;
        depth = allWaveforms(sessionID).clusters(clusterID).depth(unitID);
        trajectory = allWaveforms(sessionID).trajectory;
        numChannels = size(trajectory,1);
        
        if sessionID == 4 || sessionID == 5
            currSpread = flipud(squeeze(trajectory(1:2:numChannels,:,uId)));
        else
            currSpread = squeeze(trajectory(1:2:numChannels,:,uId));
        end  %currSpread = squeeze(trajectory(1:2:numChannels,:,uId));
        
        
        distFromSoma = [-0.1:0.02:0.1];
        %channels = [1:2:numChannels];
        time = linspace(0,82/30000*1000);
        colormap turbo
        subplot(2,1,1)
        imagesc(time(11:50),distFromSoma,currSpread(:,11:50,:))
        colorbar
        
    title(sprintf(['Cluster ',num2str(clusterID),' Session ',num2str(sessionID),' Unit ',num2str(uId-1),' Depth ',num2str(depth)])) 
    %caxis([-60 60])
    set(gca,'box','off','TickDir','out') 
    set(gca,'YDir','normal')
    ylabel('Distance from Soma (mm)')
    
    
    subplot(2,1,2)
     
    for channels = 1:11
        plot(time(11:50), currSpread(channels,11:50)+channels*25,'k')
        hold on
    end
    ylabel('Channels')
        set(gca,'box','off','TickDir','out') 
    set(gca,'YDir','normal')
    
    uiwait()
    hold off 
    end
    
 uiwait()
end


%[filename, pathname] = uigetfile('*.mat', 'S1_manualsort_normalizedwaveforms.mat');
 %   if isequal(filename,0) || isequal(pathname,0)
   %    disp('No Data')
   % else
    %   disp(['User selected ', fullfile(pathname, filename)])
  %  end
  
% Choose default command line output for Waves1
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);


% UIWAIT makes Waves1 wait for user response (see UIRESUME)
% uiwait(handles.figure1);
end 



% --- Outputs from this function are returned to the command line.
function rupali_trial1_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Get default command line output from handles structure
end 

% --- Executes on button press in save_pushbutton.
function save_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to save_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end 

% --- Executes on button press in Yes.
function good = yes_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to yes_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global yesflag 
global good  
global x 
global noisy 
global clusterID
global sessionID

yesflag = 1;  
uiresume()
data_path = 'Shude_Waveforms/Shude_waveforms/Manual Sort/Shude/Spatial Profiles';
filename = 'AmpPerCluster.mat';
full_filename = fullfile(data_path, filename);

load(full_filename); 
savefile = 'n_waveform.mat';

if yesflag == 1 
    good = [good; clusterID, sessionID];
end 

save(savefile,'good')
end 

% --- Executes on button press in Noisy.
function noisy = noisy_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global yesflag
global noisy
global x
global clusterID
global sessionID

data_path = 'Shude_Waveforms/Shude_waveforms/Manual Sort/Shude/Spatial Profiles';
filename = 'AmpPerCluster.mat';
full_filename = fullfile(data_path, filename);

load(full_filename);
savenoisy = 'n_noisy.mat';
yesflag = 2;
uiresume(); 

if yesflag == 2
    noisy = [noisy; clusterID, sessionID];
end

save(savenoisy,'noisy')
uiresume()
end 

% --- Executes on button press in Artifact.
function nogood = artifact_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to No (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global yesflag
global x
global nogood
global clusterID
global sessionID 

yesflag = 0;
uiresume()
data_path = 'Shude_Waveforms/Shude_waveforms/Manual Sort/Shude/Spatial Profiles';
filename = 'AmpPerCluster.mat';
full_filename = fullfile(data_path, filename);

load(full_filename);
saveartifact = 'n_no.mat';

if yesflag == 0
    nogood = [nogood; clusterID, sessionID]; 
end

save(saveartifact,'nogood')
end 
