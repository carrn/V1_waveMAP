
% Please note that in order to save properly, you must complete sorting all
% waveforms in one sitting (It is not recommended to restart midsession or multitask)
% 
% Requires:
% Step 1a. Extract waveforms for manual sorting in generateFigure1.m
% - manualsort_ID.mat
% - manualsort_normalizedwaveforms.mat
% - Waves1.fig
%
% Outputs: 
% - artifact.mat 
% - good.mat
% - noisy.mat
%
% We recommend doing 2 independent initial passes per reviewer, and have at least 2
% reviewers perform this individually.
%
% Round1 Reviewer 1:
% Per reviewer, after 2 independent passes of waveform curation:
% - Units labeled "good" AND "good" for both passes are accepted without additional
% review
% - Units labeled "good" OR "noisy" should be pooled for a 2nd pass review 
% - units labeled "good" AND "artifact" should be pooled for a 2nd pass review 
% - units labeled "noisy" AND artifact should be pooled for a 2nd pass review 
% - Units labeled with "artifact" AND "artifact" should be discarded
%
% Round 2 Reviewer 1:
% After a single 2nd pass review per reviewer:
% - Units labeled "good"are accepted without additional review and pooled
% with units labeled "good" in the first round
% - Units labeled "noisy" should be discarded
% - units labeled "artifact" should be discarded
% Cronbach's alpha can be calculated for internal consistency of labeled
% per reviewer
%
%
% Reviewer 1 & Reviewer 2 Round 3:
% Both reviewers should review the pooled "good" labeled units across both reviewers:
% - Units labeled "good" AND "good" for both reviewers are accepted for
% final manual sorted dataset
% - Units labeled "good" OR "noisy" should be discarded 
% - units labeled "good" AND "artifact" should be discarded 
% - units labeled "noisy" AND artifact should be discarded
% - Units labeled with "artifact" AND "artifact" should be discarded


function [good,noisy] = Waves1(varargin)
% WAVES1 MATLAB code for Waves1.fig
%      WAVES1, by itself, creates a new WAVES1 or raises the existing
%      singleton*.
%
%      H = WAVES1 returns the handle to a new WAVES1 or the handle to
%      the existing singleton*.
%
%      WAVES1('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in WAVES1.M with the given input arguments.
%
%      WAVES1('Property','Value',...) creates a new WAVES1 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Waves1_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Waves1_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Waves1

% Last Modified by GUIDE v2.5 11-Mar-2022 14:58:03

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Waves1_OpeningFcn, ...
                   'gui_OutputFcn',  @Waves1_OutputFcn, ...
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


% --- Executes just before Waves1 is made visible.
function Waves1_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Waves1 (see VARARGIN)

%[filename, pathname] = uigetfile('*.mat', 'S1_manualsort_normalizedwaveforms.mat');
 %   if isequal(filename,0) || isequal(pathname,0)
   %    disp('No Data')
   % else
    %   disp(['User selected ', fullfile(pathname, filename)])
  %  end
  

global noisy
global nogood
global good
global x
global yesflag
global n
yesflag = 0;
good = [];
noisy = [];
nogood = [];

data_path = [pwd '\manual_sort\'];
filename = 'manualsort_normalizedwaveforms.mat';
full_filename = fullfile(data_path, filename);
load(filename);
n = length(align_all);
for x = 1:n
        plot(align_all(x,:))
        uiwait()
end


% Choose default command line output for Waves1
handles.output = hObject;


% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Waves1 wait for user response (see UIRESUME)
% uiwait(handles.figure1);
end

% --- Outputs from this function are returned to the command line.
function good = Waves1_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure

% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
good{1} = handles.output;
end

% --- Executes on button press in Good.
function good =Yes_Callback(hObject, eventdata, handles)
% hObject    handle to Yes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global yesflag
yesflag = 1;
uiresume()
global good
global x
global noisy
global n
%data_path = '/Users/ncarr/Github/Shude_waveforms/Manual Sort';
data_path = [pwd '\manual_sort\'];
filename = 'manualsort_ID.mat';
%full_filename = fullfile(data_path, filename);
load(filename);
savefile = [data_path 'good.mat'];
if yesflag == 1 
    if x == n
        fprintf('Labeling complete, %d units labeled', x)
    else
    good = [good; ID_all(x,:)];
    disp(ID_all(x))
    end
end
save(savefile,'good')
end
%C:\Users\ncarr\Documents\GitHub\Shude_waveforms\Manual Sort



% --- Executes on button press in Artifact.
function nogood = No_Callback(hObject, eventdata, handles)
% hObject    handle to No (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global yesflag
global x
global nogood
global n
yesflag = 0;
%data_path = '/Users/ncarr/Github/Shude_waveforms/Manual Sort';
data_path = [pwd '\manual_sort\'];
filename = 'manualsort_ID.mat';
full_filename = fullfile(data_path, filename);
load(full_filename);
savenogood = [data_path 'artifact.mat'];
uiresume();
if yesflag == 0
    if x == n
        fprintf('Labeling complete, %d units labeled', x) 
    elseif x >= n
        fprintf('Labeling complete, %d units labeled', x) 
    else
        nogood = [nogood,ID_all(x,:)];
        disp(ID_all(x))
    end
end
save(savenogood,'nogood')
uiresume()
end

% --- Executes on button press in Noisy.
function noisy = pushbutton4_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global yesflag
global noisy
global x
global n
%data_path ='/Users/ncarr/Github/Shude_waveforms/Manual Sort';
data_path = [pwd '\manual_sort\'];
filename = 'manualsort_ID.mat';
full_filename = fullfile(data_path, filename);
load(full_filename);
savenoisy = [data_path 'noisy.mat'];
yesflag = 2;
uiresume();
if yesflag == 2 
    if x == n
        fprintf('Labeling complete, %d units labeled', x)
    else
    noisy = [noisy;ID_all(x,:)];
    disp(ID_all(x))
    end
end
save(savenoisy,'noisy')
end

% --- Executes on button press in save.
function [good,noisy] = save_Callback(hObject, eventdata, handles)
% hObject    handle to save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global good
global noisy
global x
global yesflag
global n
%data_path = 'Users/ncarr/Github/Shude_waveforms/Manual Sort';
% data_path = [pwd '\manual_sort\'];
% filename = 'manualsort_ID.mat';
% full_filename = fullfile(data_path, filename);
% load(full_filename);
% savefile = [data_path 'good.mat'];
% savenoisy = [data_path 'noisy.mat'];
% if yesflag == 1
%     good = [good; ID_all(x,:)];
%    
% end
% if yesflag == 2
%     noisy = [noisy;ID_all(x,:)];
% end
% save(savefile,'good')
% save(savenoisy,'noisy')
disp('These units are marked as good')
disp(good)
disp('These units are marked as noisy')
disp(noisy)
fprintf('Labeling complete, %d units labeled', x)
end



