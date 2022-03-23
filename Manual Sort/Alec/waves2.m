function varargout = waves2(varargin)
% WAVES2 MATLAB code for waves2.fig
%      WAVES2, by itself, creates a new WAVES2 or raises the existing
%      singleton*.
%
%      H = WAVES2 returns the handle to a new WAVES2 or the handle to
%      the existing singleton*.
%
%      WAVES2('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in WAVES2.M with the given input arguments.
%
%      WAVES2('Property','Value',...) creates a new WAVES2 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before waves2_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to waves2_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help waves2

% Last Modified by GUIDE v2.5 16-Mar-2022 14:57:20

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @waves2_OpeningFcn, ...
                   'gui_OutputFcn',  @waves2_OutputFcn, ...
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

% --- Executes just before waves2 is made visible.
function waves2_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to waves2 (see VARARGIN)

global noisy2
global nogood2
  global good2
  global x
global yesflag
global k 
yesflag = 0;
good2 = [];
noisy2 = [];
nogood2 = [];
data_path = '/Users/alecperliss/Downloads';
filename = 'secondalign.mat';
full_filename = fullfile(data_path, filename);
load(full_filename);
data_path = '/Users/alecperliss/Downloads';
filename = 'S1_manualsort_normalizedwaveforms.mat';
full_filename = fullfile(data_path, filename);
load(full_filename);

for x = 1:length(secondalign)
    k = secondalign(x);
    plot(align_all(k,:))
    uiwait()
end




% Choose default command line output for waves2
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes waves2 wait for user response (see UIRESUME)
% uiwait(handles.figure1);

end
% --- Outputs from this function are returned to the command line.
function varargout = waves2_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

% --- Executes on button press in yes.
function yes_Callback(hObject, eventdata, handles)
% hObject    handle to yes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global yesflag
yesflag = 1;
uiresume()
global good2
global x
global noisy2
data_path = '/Users/alecperliss/Downloads';
filename = 'S1_manualsort_ID.mat';
full_filename = fullfile(data_path, filename);
load(full_filename);
savefile = 'good2.mat';
if yesflag == 1
    good2 = [good2; ID_all(x,:)];
end
save(savefile,'good2')
disp(ID_all(x))


end




% --- Executes on button press in noisy.
function noisy_Callback(hObject, eventdata, handles)
% hObject    handle to noisy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global yesflag
global noisy2
global x
data_path = '/Users/alecperliss/Downloads';
filename = 'S1_manualsort_ID.mat';
full_filename = fullfile(data_path, filename);
load(full_filename);
savenoisy = 'noisy2.mat';
yesflag = 2;
uiresume();
if yesflag == 2
    noisy2 = [noisy2,ID_all(x)];
end
save(savenoisy,'noisy2')
disp(ID_all(x))
end


% --- Executes on button press in artifact.
function artifact_Callback(hObject, eventdata, handles)
% hObject    handle to artifact (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global yesflag
global x
global nogood2
yesflag = 0;
data_path = '/Users/alecperliss/Downloads';
filename = 'S1_manualsort_ID.mat';
full_filename = fullfile(data_path, filename);
load(full_filename);
savenogood = 'no2.mat';
uiresume();
if yesflag == 0
    nogood2 = [nogood2,ID_all(x)];
end
save(savenogood,'nogood')
disp(ID_all(x))
uiresume()
end
