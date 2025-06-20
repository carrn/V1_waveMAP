
function [gooda,noisya] = Waves1(varargin)
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
global noisya
global nogood
  global gooda
  global x
global yesflag
yesflag = 0;
gooda = [];
noisya = [];
nogood = [];
%data_path = '/Users/ncarr/Github/Shude_waveforms/Manual Sort';
filename = 'S1_manualsort_normalizedwaveforms.mat';
%full_filename = fullfile(data_path, filename);
load(filename);
for x = 1:6
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
function gooda = Waves1_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure

% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
good{1} = handles.output;
end

% --- Executes on button press in Yes.
function gooda =Yes_Callback(hObject, eventdata, handles)
% hObject    handle to Yes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global yesflag
yesflag = 1;
uiresume()
global gooda
global x
global noisya
%data_path = '/Users/ncarr/Github/Shude_waveforms/Manual Sort';
filename = 'S1_manualsort_ID.mat';
%full_filename = fullfile(data_path, filename);
load(filename);
savefile = 'waveform.mat';
if yesflag == 1
    gooda = [gooda; ID_all(x,:)];
end
save(savefile,'gooda')
disp(ID_all(x))


end
%C:\Users\ncarr\Documents\GitHub\Shude_waveforms\Manual Sort



% --- Executes on button press in No.
function nogood = No_Callback(hObject, eventdata, handles)
% hObject    handle to No (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global yesflag
global x
global nogood
yesflag = 0;
data_path = '/Users/ncarr/Github/Shude_waveforms/Manual Sort';
filename = 'S1_manualsort_ID.mat';
full_filename = fullfile(data_path, filename);
load(full_filename);
savenogood = 'no.mat';
uiresume();
if yesflag == 0
    nogood = [nogood,ID_all(x)];
end
save(savenogood,'nogood')
disp(ID_all(x))
uiresume()
end

% --- Executes on button press in save.
function [gooda,noisya] = save_Callback(hObject, eventdata, handles)
% hObject    handle to save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global good
global noisya
global x
global yesflag
data_path = 'Users/ncarr/Github/Shude_waveforms/Manual Sort';
filename = 'S1_manualsort_ID.mat';
full_filename = fullfile(data_path, filename);
load(full_filename);
savefile = 'waveform.mat';
savenoisy = 'noisy.mat';
if yesflag == 1
    good = [good; ID_all(x,:)];
   
end
if yesflag == 2
    noisya = [noisya;ID_all(x,:)];
end
save(savefile,'good')
save(savenoisy,'noisya')
disp(good)
disp(noisya)
end


% --- Executes on button press in pushbutton4.
function noisya = pushbutton4_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global yesflag
global noisya
global x
data_path ='/Users/ncarr/Github/Shude_waveforms/Manual Sort';
filename = 'S1_manualsort_ID.mat';
full_filename = fullfile(data_path, filename);
load(full_filename);
savenoisy = 'noisya.mat';
yesflag = 2;
uiresume();
if yesflag == 2
    noisya = [noisya;ID_all(x,:)];
end
save(savenoisy,'noisya')
disp(ID_all(x))
end
