function varargout = untitled1(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @untitled1_OpeningFcn, ...
                   'gui_OutputFcn',  @untitled1_OutputFcn, ...
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

% --- Executes just before untitled1 is made visible.
function untitled1_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to untitled1 (see VARARGIN)

% Choose default command line output for untitled1
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes untitled1 wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = untitled1_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

function chooseimgButton_Callback(hObject, eventdata, handles)
[filename, pathname] = uigetfile({'*.jpg;*.jpeg;*.png;*.bmp;*.tif', ...
                                  'Image Files (*.jpg, *.jpeg, *.png, *.bmp, *.tif)'}, ...
                                  'Select an Image');
if isequal(filename,0)
    disp('canceled image selection.');
else
    fullpath = fullfile(pathname, filename);
    img = imread(fullpath);
    if ndims(img) == 3
        img = rgb2gray(img);
    end

    axes(handles.axes1);
    imshow(img,'Parent', handles.axes1);
    handles.selectedImage = img;
    guidata(hObject, handles);

    set(handles.chooseimgButton, 'Visible', 'off');
    set(handles.GaussianButton, 'Visible', 'on');
    set(handles.saltButton, 'Visible', 'on');
    set(handles.PeriodicButton, 'Visible', 'on');
    set(handles.UniformButton, 'Visible', 'on');
    set(handles.RayleighButton, 'Visible', 'on');
    set(handles.ExButton, 'Visible', 'on');
    set(handles.TryAgainButton, 'Visible', 'on');
    set(handles.De, 'Visible', 'off');
    set(handles.Dr, 'Visible', 'off');
    set(handles.Dg, 'Visible', 'off');
    set(handles.Dp, 'Visible', 'off');
    set(handles.Ds, 'Visible', 'off');
    set(handles.Du, 'Visible', 'off');
end

function GaussianButton_Callback(hObject, eventdata, handles)
set(handles.DenoiseButton, 'Visible', 'on');
set(handles.TryAgainButton, 'Visible', 'on');
set(handles.Guassiantxt, 'Visible', 'on');
set(handles.salttxt, 'Visible', 'off');
set(handles.UniFormtxt, 'Visible', 'off');
set(handles.Rayleightxt, 'Visible', 'off');
set(handles.Extxt, 'Visible', 'off');
set(handles.Periodictxt, 'Visible', 'off');
set(handles.De, 'Visible', 'off');
set(handles.Dr, 'Visible', 'off');
set(handles.Dg, 'Visible', 'off');
set(handles.Dp, 'Visible', 'off');
set(handles.Ds, 'Visible', 'off');
set(handles.Du, 'Visible', 'off');

noisyImg = imnoise(handles.selectedImage, 'gaussian', 0, 0.02);
imshow(noisyImg,'Parent', handles.axes1);
handles.noisyImage = noisyImg;
handles.noiseType  = 'gaussian';
guidata(hObject, handles);

function saltButton_Callback(hObject, eventdata, handles)
set(handles.DenoiseButton, 'Visible', 'on');
set(handles.TryAgainButton, 'Visible', 'on');
set(handles.salttxt, 'Visible', 'on');
set(handles.Guassiantxt, 'Visible', 'off');
set(handles.UniFormtxt, 'Visible', 'off');
set(handles.Rayleightxt, 'Visible', 'off');
set(handles.Extxt, 'Visible', 'off');
set(handles.Periodictxt, 'Visible', 'off');
set(handles.De, 'Visible', 'off');
set(handles.Dr, 'Visible', 'off');
set(handles.Dg, 'Visible', 'off');
set(handles.Dp, 'Visible', 'off');
set(handles.Ds, 'Visible', 'off');
set(handles.Du, 'Visible', 'off');

noisyImg = imnoise(handles.selectedImage, 'salt & pepper', 0.15);
imshow(noisyImg,'Parent', handles.axes1);
handles.noisyImage = noisyImg;
handles.noiseType  = 'salt & pepper';
guidata(hObject, handles);

function PeriodicButton_Callback(hObject, eventdata, handles)
set(handles.DenoiseButton, 'Visible', 'on');
set(handles.TryAgainButton, 'Visible', 'on');
set(handles.Periodictxt, 'Visible', 'on');
set(handles.salttxt, 'Visible', 'on');
set(handles.Guassiantxt, 'Visible', 'off');
set(handles.UniFormtxt, 'Visible', 'off');
set(handles.Rayleightxt, 'Visible', 'off');
set(handles.Extxt, 'Visible', 'off');
set(handles.De, 'Visible', 'off');
set(handles.Dr, 'Visible', 'off');
set(handles.Dg, 'Visible', 'off');
set(handles.Dp, 'Visible', 'off');
set(handles.Ds, 'Visible', 'off');
set(handles.Du, 'Visible', 'off');
            
s = size(handles.selectedImage);                           
[x,y] = meshgrid(1:s(2), 1:s(1));      
p = sin(x/3 + y/6) + 1;                
noisyImg = (im2double(handles.selectedImage) + p/2) / 2;        
imshow(noisyImg,'Parent', handles.axes1);
handles.noisyImage = noisyImg;
handles.noiseType  = 'periodic';
guidata(hObject, handles);

function UniformButton_Callback(hObject, eventdata, handles)
set(handles.DenoiseButton, 'Visible', 'on');
set(handles.TryAgainButton, 'Visible', 'on');
set(handles.UniFormtxt, 'Visible', 'on');
set(handles.Guassiantxt, 'Visible', 'off');
set(handles.salttxt, 'Visible', 'off');
set(handles.Rayleightxt, 'Visible', 'off');
set(handles.Extxt, 'Visible', 'off');
set(handles.Periodictxt, 'Visible', 'off');
set(handles.De, 'Visible', 'off');
set(handles.Dr, 'Visible', 'off');
set(handles.Dg, 'Visible', 'off');
set(handles.Dp, 'Visible', 'off');
set(handles.Ds, 'Visible', 'off');
set(handles.Du, 'Visible', 'off');

a = 0;        
b = 0.5;       
noiseStrength = 0.6;   
M = size(handles.selectedImage,1);    
N = size(handles.selectedImage,2);    
R = a + (b - a) * rand (M , N);
noisyImg = im2double(handles.selectedImage) + noiseStrength * R;
imshow(noisyImg, 'Parent', handles.axes1);
handles.noisyImage = noisyImg;
handles.noiseType  = 'uniform';
guidata(hObject, handles);

function RayleighButton_Callback(hObject, eventdata, handles)
set(handles.DenoiseButton, 'Visible', 'on');
set(handles.TryAgainButton, 'Visible', 'on');
set(handles.Rayleightxt, 'Visible', 'on');
set(handles.Guassiantxt, 'Visible', 'off');
set(handles.salttxt, 'Visible', 'off');
set(handles.UniFormtxt, 'Visible', 'off');
set(handles.Extxt, 'Visible', 'off');
set(handles.Periodictxt, 'Visible', 'off');
set(handles.De, 'Visible', 'off');
set(handles.Dr, 'Visible', 'off');
set(handles.Dg, 'Visible', 'off');
set(handles.Dp, 'Visible', 'off');
set(handles.Ds, 'Visible', 'off');
set(handles.Du, 'Visible', 'off');

a = 0;          
b = 0.2;        
noiseStrength = 0.5;  
M = size(handles.selectedImage,1); 
N = size(handles.selectedImage,2);  
R = a + sqrt(-b * log(1 - rand(M, N)));
noisyImg = im2double(handles.selectedImage) + noiseStrength * R;
imshow(noisyImg,'Parent', handles.axes1);
handles.noisyImage = noisyImg;
handles.noiseType  = 'rayleigh';
guidata(hObject, handles);

function ExButton_Callback(hObject, eventdata, handles)
set(handles.DenoiseButton, 'Visible', 'on');
set(handles.TryAgainButton, 'Visible', 'on');
set(handles.Extxt, 'Visible', 'on');
set(handles.Guassiantxt, 'Visible', 'off');
set(handles.salttxt, 'Visible', 'off');
set(handles.UniFormtxt, 'Visible', 'off');
set(handles.Rayleightxt, 'Visible', 'off');
set(handles.Periodictxt, 'Visible', 'off');
set(handles.De, 'Visible', 'off');
set(handles.Dr, 'Visible', 'off');
set(handles.Dg, 'Visible', 'off');
set(handles.Dp, 'Visible', 'off');
set(handles.Ds, 'Visible', 'off');
set(handles.Du, 'Visible', 'off');

a = 0.3;
M = size(handles.selectedImage,1);
N = size(handles.selectedImage,2);
noiseStrength = 0.6;  
R = -a * log(1 - rand(M, N));
noisyImg = im2double(handles.selectedImage) + noiseStrength * R;
imshow(noisyImg,'Parent', handles.axes1);
handles.noisyImage = noisyImg;
handles.noiseType  = 'exponential';
guidata(hObject, handles);

function TryAgainButton_Callback(hObject, eventdata, handles)
set(handles.chooseimgButton, 'Visible', 'on');
set(handles.GaussianButton, 'Visible', 'off');
set(handles.saltButton, 'Visible', 'off');
set(handles.PeriodicButton, 'Visible', 'off');
set(handles.UniformButton, 'Visible', 'off');
set(handles.RayleighButton, 'Visible', 'off');
set(handles.ExButton, 'Visible', 'off');
set(handles.DenoiseButton, 'Visible', 'off');
set(handles.TryAgainButton, 'Visible', 'off');
set(handles.Guassiantxt, 'Visible', 'off');
set(handles.salttxt, 'Visible', 'off');
set(handles.UniFormtxt, 'Visible', 'off');
set(handles.Rayleightxt, 'Visible', 'off');
set(handles.Extxt, 'Visible', 'off');
set(handles.Periodictxt, 'Visible', 'off');
set(handles.De, 'Visible', 'off');
set(handles.Dr, 'Visible', 'off');
set(handles.Dg, 'Visible', 'off');
set(handles.Dp, 'Visible', 'off');
set(handles.Ds, 'Visible', 'off');
set(handles.Du, 'Visible', 'off');
cla(handles.axes1, 'reset');  

function DenoiseButton_Callback(hObject, eventdata, handles)
set(handles.DenoiseButton, 'Visible', 'off');
set(handles.TryAgainButton, 'Visible', 'on');
set(handles.Guassiantxt, 'Visible', 'off');
set(handles.salttxt, 'Visible', 'off');
set(handles.UniFormtxt, 'Visible', 'off');
set(handles.Rayleightxt, 'Visible', 'off');
set(handles.Extxt, 'Visible', 'off');
set(handles.Periodictxt, 'Visible', 'off');
set(handles.De, 'Visible', 'off');
set(handles.Dr, 'Visible', 'off');
set(handles.Dg, 'Visible', 'off');
set(handles.Dp, 'Visible', 'off');
set(handles.Ds, 'Visible', 'off');
set(handles.Du, 'Visible', 'off');

noisyImg = handles.noisyImage;

    switch handles.noiseType
        case 'gaussian'
            denoisedImg = imnlmfilt(noisyImg, ...
                                    'SearchWindowSize', 15, ...
                                    'ComparisonWindowSize', 3, ...
                                    'DegreeOfSmoothing', 25);
            set(handles.Dg, 'Visible', 'on');

        case 'salt & pepper'
            denoisedImg = medfilt2(noisyImg,[3 3]);
            set(handles.Ds, 'Visible', 'on');

        case 'uniform'
            m = 3; n = 3;
            f1 = ordfilt2(noisyImg, 1, ones(m,n), 'symmetric');
            f2 = ordfilt2(noisyImg, m*n, ones(m,n), 'symmetric');
            denoisedImg = imlincomb(0.5, f1, 0.5, f2);
            set(handles.Du, 'Visible', 'on');

        case 'rayleigh'
            denoisedImg = wiener2(noisyImg, [3 3]);
            set(handles.Dr, 'Visible', 'on');

        case 'exponential'
            denoisedImg = imgaussfilt(noisyImg, 1.0, 'FilterSize', 5);
            set(handles.De, 'Visible', 'on');

        case 'periodic'
            F = fft2(noisyImg);
            Fshift = fftshift(F);

            figure;
            imshow(log(1+abs(Fshift)),[]);
            title('Choose points, press Enter to finish');
            impixelinfo;

            [col,row] = ginput;  

            if ~isempty(row)
                for k = 1:length(row)
                    fprintf('point%d: row=%d, col=%d\n', k, round(row(k)), round(col(k)));
                    Fshift(round(row(k)),:) = 0;
                    Fshift(:,round(col(k))) = 0;
                end
            end

            Ff = ifftshift(Fshift);
            denoisedImg = real(ifft2(Ff));
            set(handles.Dp, 'Visible', 'on');

        otherwise
            denoisedImg = noisyImg;
    end

imshow(denoisedImg, 'Parent', handles.axes1);
handles.denoisedImage = denoisedImg;
guidata(hObject, handles);


