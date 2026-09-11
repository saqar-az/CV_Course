function varargout = hw41(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @hw41_OpeningFcn, ...
                   'gui_OutputFcn',  @hw41_OutputFcn, ...
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

function hw41_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
set(handles.Cbutton,'Visible','on');   
set(handles.Abutton,'Visible','off');
set(handles.Tbutton,'Visible','off');  
guidata(hObject, handles);

function varargout = hw41_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;

function Cbutton_Callback(hObject, eventdata, handles)
    [file,path] = uigetfile({'*.png;*.jpg;*.bmp','Image Files'});
    if isequal(file,0)
        return;
    end
    handles.imgPath = fullfile(path,file);
    axes(handles.axes1);
    img = imread(handles.imgPath);
    imshow(img,[]);
    
    set(handles.Cbutton,'Visible','off');
    set(handles.Abutton,'Visible','on');
    set(handles.Tbutton,'Visible','off');
    guidata(hObject, handles);

function Tbutton_Callback(hObject, eventdata, handles)
    cla(handles.axes1,'reset');
    set(handles.axes1,'Visible','on'); 
    cla(handles.axes2,'reset');
    set(handles.axes2,'Visible','off'); 
    cla(handles.axes3,'reset');
    set(handles.axes3,'Visible','off'); 
    set(handles.Cbutton,'Visible','on'); 
    set(handles.Abutton,'Visible','off'); 
    set(handles.Tbutton,'Visible','off'); 
    
    if isfield(handles,'imgPath')
        handles = rmfield(handles,'imgPath');
    end  
    
    
function Abutton_Callback(hObject, eventdata, handles)
    load('digitMLP.mat','net');
    imSize = [90 140];
    img = imread(handles.imgPath);
    imgGray = im2gray(img);

    BW = imbinarize(imgGray);
    if mean(imgGray(BW)) > mean(imgGray(~BW))
        BW = ~BW;
    end
    BW = imfill(BW,'holes');
    imgArea = numel(BW);
    BW = bwareaopen(BW, max(50, round(0.002 * imgArea)));
    BW = imdilate(BW, strel('rectangle',[1 3]));
    BW = imopen(BW, strel('rectangle',[2 2]));

    CC = bwconncomp(BW);
    stats = regionprops(CC,'BoundingBox','Area');
    filtered = [];
    for s = stats'
        bb = s.BoundingBox;
        w = bb(3);
        h = bb(4);
        aspect = w / max(h,1);
        if s.Area >= max(50, round(0.002 * imgArea)) && aspect >= 0.15 && aspect <= 2.5
            filtered = [filtered; s]; 
        end
    end
    if isempty(filtered)
        [~, idxMax] = max([stats.Area]);
        filtered = stats(idxMax);
    end

    boxes = cat(1, filtered.BoundingBox);
    if numel(filtered) == 1
        WH = boxes(3) / max(boxes(4),1);
        if WH > 1.2
            [~, subBoxes] = segment(BW, boxes);
            if ~isempty(subBoxes)
                boxes = subBoxes;
            end
        end
    end

    [~, order] = sort(boxes(:,1));
    boxes = boxes(order,:);


    cla(handles.axes1,'reset');
    set(handles.axes1,'Visible','off');
    axes(handles.axes2);
    cla(handles.axes2,'reset');
    plot(net);  
    title('MLP Network');
    axes(handles.axes3);
    cla(handles.axes3,'reset');
    imshow(img,[]);
    hold on;
    
    predictions = strings(size(boxes,1),1);

    for k = 1:size(boxes,1)
        box = boxes(k,:);
        pad = 4;
        x1 = max(floor(box(1))-pad,1);
        y1 = max(floor(box(2))-pad,1);
        x2 = min(ceil(box(1)+box(3))+pad, size(imgGray,2));
        y2 = min(ceil(box(2)+box(4))+pad, size(imgGray,1));
        digitCrop = imgGray(y1:y2, x1:x2);

        [h,w] = size(digitCrop);
        m = max(h,w);
        padTop = floor((m-h)/2); padBottom = m-h-padTop;
        padLeft = floor((m-w)/2); padRight = m-w-padLeft;
        digitSquare = padarray(digitCrop,[padTop padLeft],255,'pre');
        digitSquare = padarray(digitSquare,[padBottom padRight],255,'post');

        digitResized = imresize(digitSquare, imSize);
        digitDouble = im2double(digitResized);
        X = single(digitDouble(:)');

        pred = classify(net,X);
        predictions(k) = string(pred);

        rectangle('Position',[x1 y1 x2-x1+1 y2-y1+1],'EdgeColor','r','LineWidth',2);
        text(x1,max(y1-10,5),char(pred),'Color','Blue','FontSize',14,'FontWeight','bold');
    end
    hold off;

    if ~isempty(predictions)
        title(['Predicted Number: ', strjoin(predictions,'')]);
    else
        title('No digits detected');
    end
    
    set(handles.Abutton,'Visible','off'); 
    set(handles.Cbutton,'Visible','off'); 
    set(handles.Tbutton,'Visible','on'); 
    guidata(hObject, handles);

function [cuts, subBoxes] = segment(BW, box)
    x1 = max(floor(box(1)),1);
    y1 = max(floor(box(2)),1);
    x2 = min(ceil(box(1)+box(3)), size(BW,2));
    y2 = min(ceil(box(2)+box(4)), size(BW,1));
    region = BW(y1:y2, x1:x2);

    colSum = sum(region,1);
    thr = 0.05 * max(colSum);
    gaps = colSum <= thr;
    d = diff([0 gaps 0]);
    starts = find(d==1);
    ends = find(d==-1)-1;

    cuts = starts;
    subBoxes = [];
    prev = 1;
    for i=1:numel(starts)
        stop = starts(i)-1;
        if stop-prev+1 >= 3
            subBoxes(end+1,:) = [x1+prev-1, y1, (stop-prev+1), (y2-y1+1)];
        end
        prev = ends(i)+1;
    end
    if size(region,2)-prev+1 >= 3
        subBoxes(end+1,:) = [x1+prev-1, y1, (size(region,2)-prev+1), (y2-y1+1)];
    end
    keep = true(1,size(subBoxes,1));
    for i=1:size(subBoxes,1)
        w = subBoxes(i,3); h = subBoxes(i,4);
        aspect = w/max(h,1);
        if aspect < 0.12, keep(i)=false; end
    end
    subBoxes = subBoxes(keep,:);