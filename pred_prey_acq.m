function pred_prey_acq(vPath,skip_prey)

% Acquire kinematics of predator and prey fish


%% Parameter values

% Header for image filenames
nameHead = 'day';

% Extension for image files
nameSuffix = 'TIF';

% Number of digits for frame number in filename
num_digit = 5;

% Initial visualizing predator acquisition
visSteps = 1;

% Number of predtaor frames to visualize at start of acquisition
numVis = 50;

% Max number of frames for creating the mean image
maxFrames = 1000;

% Whether to invert the image
invert = 1;

% Radius of prey roi (in pixels)
py_roi = 30;

if nargin < 2
    skip_prey = 0;
end

%% Get path of data file, load data

if nargin < 1
    vPath = uigetdir(pwd,'Select directory');
    if vPath==0
        return
    end
end

% Load filenames for frames
a = dir([vPath filesep  '*' nameHead '*.' nameSuffix]);


%% Define roi

% Look for roi data
a2 = dir([vPath filesep 'roi.mat']);

if isempty(a2)
    
    % Read first frame
    im = imread([vPath filesep a(1).name]);
    
    % Select dimensions of circular roi
    txt = 'Select vertical axis of roi';
    figure;
    [p.roi_v.x,p.roi_v.y]   = choosePoints(im,1,txt);
    
    txt = 'Select horizontal axis of roi';
    [p.roi_h.x,p.roi_h.y]   = choosePoints(im,1,txt);
    
    % Overlay roi
    [x_roi,y_roi] = roiCoords(p);
    hold on
    h = plot(x_roi,y_roi,'r');
    hold off
    
    % Save roi data
    save([vPath filesep 'roi.mat'],'p')
    
    % Clear variables
    clear h x y xVals yVals im a2 roi

end


%% Prompt for sequence info

% Look for mean image
a2 = dir([vPath filesep 'start_point.mat']);

if isempty(a2)
    
    % Load p for defined for roi
    load([vPath filesep 'roi.mat'])
    
    warning off all
    
    % Prompt for parameters
    prompt={'Frame rate (per sec)', ...
        'Start frame number',...
        'Last frame number',...
        'Frame numbers (separated by spaces) where predator strikes',...
        'Frame where prey is captured (0, if never)'};
    name='Parameters';
    numlines=1;
    defaultanswer={'10','1',a(end).name(end-num_digit-length(nameSuffix):...
                            end-length(nameSuffix)-1),'',''};
    answer      = inputdlg(prompt,name,numlines,defaultanswer);
    if isempty(answer)
        return
    end
    
    p.framerate = str2num(answer{1});
    startFrame = str2num(answer{2});
    endFrame = str2num(answer{3}); 
    p.strikeFrames = str2num(answer{4});
    p.captureFrame = str2num(answer{5});
    
    % Get indicies for video frames
    idx = 1;
    for i = 1:length(a)
        frNum = str2num(a(i).name(end-num_digit-length(nameSuffix):...
            end-length(nameSuffix)-1));     
        if (frNum >= startFrame) && (frNum <= endFrame) 
            p.frNums(idx) = frNum;
            p.filename{idx} = a(i).name;
            idx = idx + 1;
        end 
    end
    
    % Measure body length, initial position & orientation
    txt = 'Select nose, then caudal peduncle';
    img = imread([vPath filesep p.filename{1}]);
    [xT,yT]   = choosePoints(img,1,txt);
    p.bLength = ((xT(2)-xT(1))^2 + (yT(2)-yT(1))^2)^0.5;
    p.xHead = xT(1);
    p.yHead = yT(1);
    p.xTail = xT(2);
    p.yTail = yT(2);
    p.x = mean(xT);
    p.y = mean(yT);
    clear xT yT txt
    close

    warning on all

    save([vPath filesep 'start_point.mat'],'p');
    
    clear startFrame endFrame prompt name numlines defaultanswer a
    
else % if seq_param exists, load

    disp(' '); disp('Loading existing starting point data . . .'); 
    load([vPath filesep 'start_point.mat'])

end

clear img


%% Create or load mean image

% Look for mean image
a2 = dir([vPath filesep 'meanImage.tif']);

% Calculate mean image does not exist
if isempty(a2)   
    
    % Define list of frame numbers, depending on max number of frames
    % requested
    if length(p.frNums) > maxFrames
        dframe = floor(length(p.frNums)/maxFrames);
        frIdx = 1:dframe:length(p.frNums);
        clear dframe
    else
        frIdx = 1:length(p.frNums);
    end
    
    % Create waitbar
    h = waitbar(0,...
            ['Mean image: ' num2str(1)],...
             'CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
    
    % Create sum image based on first frame
    [imCurr,tmp] = imread([vPath filesep p.filename{1}]);
    imSum = double(imCurr);
    clear imCurr tmp
    
    
    % Loop through frames 
    for i = 1:length(frIdx)
        
        % Add current frame to sum image
        [imCurr,tmp] = imread([vPath filesep p.filename{frIdx(i)}]);
        imSum        = imSum + double(imCurr);
        clear tmp imCurr
        
        % Update status bar
        h = waitbar(i/length(frIdx),h,...
            ['Mean image: ' num2str(i) ' of ' num2str(length(frIdx)) ' frames']);
        
        % Quit m-file, if cancel button pushed
        if getappdata(h,'canceling')
            close force
            return
        end
        
    end
    
    % Calculate mean from sum image
    imMean = uint8(round(imSum./length(frIdx)));
    
    imMean = imMean(:,:,1);
    
    % Write image to movie dir
    imwrite(imMean,[vPath filesep 'meanImage.tif'],'tif',...
            'Compression','none');
    
    close force
    clear frIdx h i imSum
        
    %imMean = rgb2gray(imMean);
      
    
% Load mean image, if present
else
    
    disp(' ')
    disp('Loading mean image . . .');
    imMean = imread([vPath filesep 'meanImage.tif']);
    
end


%% Select thresholds

% Look for mean image
a2 = dir([vPath filesep 'seq_params.mat']);

if isempty(a2)
    
    % Load p for defined for roi
    load([vPath filesep 'start_point.mat'])
    
    [x_roi,y_roi] = roiCoords(p);
    
    % Grab frames for threshold finding
    img = grabFrame(vPath,p.filename{1},invert,x_roi,y_roi);
    
    % Matlab guesses a threshold value
    p.tVal = graythresh(img);
    
    % Store path info in p
    p.path   = vPath;

    % Run threshFinder to find threshold values for predator and prey
    % note: threshFinder saves p in seq_params.mat
    disp(' ')
    disp('Choose threshold for the predator')
    
    waitfor(threshFinder(img,p))
    
    load([vPath filesep 'seq_params.mat'])
    p.tVal_pd = p.tVal;
    
    disp(' ')
    disp('Choose threshold for the prey')
    
    waitfor(threshFinder(img,p))
    
    load([vPath filesep 'seq_params.mat'])
    p.tVal_py = p.tVal;
    p = rmfield(p,'tVal');
    
    
    % Select starting position of prey
    disp(' ')
    disp('Choose starting position of the prey')
    
    im = imread([vPath filesep p.filename{1}]);
    figure
    imshow(im)
    title('Choose starting position of the prey')
    hold on
    
    [p.xPrey,p.yPrey,but] = ginput(1);
    
    plot(p.xPrey,p.yPrey,'+r')
    pause(1)
    close
    
    
    % Locate new postion of larva
    [p.xPrey,p.yPrey,p.areaPrey,x_roipy,y_roipy,imBW] = findLarva(img,p.xPrey, ...
                                p.yPrey,50,py_roi,p.tVal_py,'dist');
    
    
%     % Define prey roi 
%     x_py = p.xPrey + py_roi.*cos(linspace(0,2*pi,200));
%     y_py = p.yPrey + py_roi.*sin(linspace(0,2*pi,200));
%     pyROI = roipoly(img,x_py,y_py);
%     imBW  = ~im2bw(img,p.tVal_py) & pyROI;
%     
%     % Dilate im & get properties
%     se    = strel('disk',4,4);
%     imBW = imdilate(imBW,se);
%     LL    = bwlabel(imBW);
%     props = regionprops(LL,'Centroid','Area');
%     
%     % Select blob closest to selected point
%     if length(props)>1
%         dist = 10^10;
%        for i = 1:length(props)
%            cDist = sqrt((props(i).Centroid(1)-p.xPrey)^2 + ...
%                         (props(i).Centroid(2)-p.yPrey)^2);
%            if cDist < dist
%                dist = cDist;
%                py.areaPrey = props(i).Area;
%            end
%        end
%     else
%         p.areaPrey = props.Area;
%     end
    
    % Save 'p' structure
    save([vPath filesep 'seq_params'],'p')
    
    clear im img x_roi y_roi dist props LL imBW pyROI x_py y_py se i
    
else % if seq_param exists, load

    disp(' '); disp('Loading existing sequence parameters . . .'); 
    load([vPath filesep 'seq_params.mat'])
    disp(' ');

end

clear img


%% Acquire position of prey

% Color for highlighting the larva
%clr = [0.8 .6 0];
clr = [1 0 0];


% Update status    
disp(' '); disp('Acquiring prey position . . .');

% Create figure window
f = figure;
set(f,'DoubleBuffer','on')
set(f,'CurrentCharacter','1')


% Check for data file
a3 = dir([vPath filesep 'prey_coords.mat']);

% Load py, if present
if ~isempty(a3)
    disp(' ');disp('Loading prey data . . .')
    load([vPath filesep 'prey_coords.mat'])
    
    i = find(py.frDone,1,'last')+1;
    
    tVal = py.tVal(i-1);
    
% Otherwise, create py
else
    
    im = imread([vPath filesep p.filename{1}]);
    warning off
    imshow(im)
    warning on
    
    py.xlim = xlim;
    py.ylim = ylim;
    
    py.x = nan(length(p.frNums),1);
    py.y = nan(length(p.frNums),1);
    py.area = nan(length(p.frNums),1);
    py.frDone = zeros(length(p.frNums),1);
    
    py.x(1) = p.xPrey;
    py.y(1) = p.yPrey;
    py.area(1) = p.areaPrey;
    
    py.finished = 0;
    
    i = 2;
    
    tVal = p.tVal_py;
end

% Execute, if no data or not yet finished
if ~py.finished   
    
    % Loop through frames, until finished
    while ~py.finished
        
        % Define roi coordinates
        [x_roi,y_roi] = roiCoords(p);
          
        % Grab frame, threshold image & choose roi
        img = grabFrame(vPath,p.filename{i},invert,x_roi,y_roi);
        
        % Enter interactive mode, if there is a nan in prior coordinate
        if isnan(py.x(i-1)) || isnan(py.y(i-1))
            set(f,'CurrentCharacter','0');
             disp('Prior frame coordinate is a nan -- entering interactive mode')
             disp(' ')
             im = imread([vPath filesep p.filename{i}]);
             imshow(im);
             cMap = colormap('gray');
        
        % Otherwise, proceed on tracking
        else
            
            % Locate new postion of larva
            [py_x,py_y,py_a,x_roipy,y_roipy,imBW] = findLarva(img,py.x(i-1), ...
                py.y(i-1),py.area(i-1),py_roi,tVal,'area');
            
            % Store away data
            py.frame(i) = p.frNums(i);
            py.filename{i} = p.filename{i};
            py.x(i) = py_x;
            py.y(i) = py_y;
            py.area(i) = py_a;
            py.frDone(i) = 1;
            py.tVal(i) = tVal;
            
            
            % Load frame and define colormap
            warning off
            im = imread([vPath filesep p.filename{i}]);
            imshow(im)
            cMap = colormap('gray');
            im(imBW(:)) = 232;
            cMap(233,:) = clr;
            
            % Display image, plot data
            figure(f)
            imshow(im,cMap)
            hold on
            plot(py.x(i),py.y(i),'wo')
            title(['Frame ' num2str(p.frNums(i)) ' of ' ...
                num2str(p.frNums(end)) ' (press key to interrupt)'])
            plot(x_roipy,y_roipy,'w--')
            hold off
            % Set limits
            xlim(py.xlim);
            ylim(py.ylim);
            pause(.2)
            warning on
            clear im
        end
        
        % Stop and interact
        if ~strcmp(get(f,'CurrentCharacter'),'1') || ...
                (p.frNums(i) == p.captureFrame)
            
            disp(' ')
            disp('Commands:');
            disp('   Left arrow  - back up a frame')
            disp('   Right arrow - advance a frame')
            disp('   Right click - delete coordinate');
            disp('   Left click  - select new position for larva')
            disp('   "r"         - Resume tracking');
            disp('   "z"         - Zoom mode');
            disp('   "t"         - adjust threshold');
            disp('   "c"         - clear all coordinate after current frame');
            disp('   "f"         - Finished analysis & save data');
            disp('   esc         - To exit without saving data');
            disp(' ')
            
            while 1
                
                [cX,cY,cB] = ginput(1);
                
                % ESC
                if isempty(cB)
                    
                    p.frNums(i) >= p.captureFrame
                    
                elseif cB == 27
                    
                    close;
                    return
                    
                % Left arrow  
                elseif cB == 28

                    % Back up frame
                    i = max([1 i-1]);
                 
                % Right arrow
                elseif cB == 29
                    
                    % Advance frame
                    i = min([i+1 p.frNums(end)]);
                    
                % Right click
                elseif cB == 3
                    
                    % Overwrite current frame data with nans
                    py.x(i) = nan;
                    py.y(i) = nan;
                    py.area(i) = nan;
                    py.frDone(i) = 1;
                     
                    
                % "r" -- resume
                elseif cB == 114
                    
                    if isnan(py.x(i))
                        warning(['You need to select the position of '...
                            'the larva before resuming autotracking'])
                    else
                        set(f,'CurrentCharacter','1')
                        break
                    end
                    
                % Left click
                elseif cB == 1
                    
                    py.x(i) = cX;
                    py.y(i) = cY;
                    py.area(i) = p.areaPrey;
                    py.frDone(i) = 1;
                    
                   % Locate new postion of larva
%                    [py.x(i),py.y(i),py.area(i),x_roipy,y_roipy,imBW] = ...
%                                findLarva(img,cX,cY,p.areaPrey,py_roi,tVal,'dist');
                           
                % "z" -- zoom
                elseif cB == 122
                    title('Press return to exit zoom mode')
                    zoom on
                    pause
                    py.xlim = xlim;
                    py.ylim = ylim;
                    
                % "f" -- finished
                elseif cB == 102
                    py.finished = 1;
                    break
                    
                % "c" -- clear points
                elseif cB == 99
                    idx = 1:length(py.x);
                    idx = idx > i;
                    py.x(idx) = nan(length(py.x(idx)),1);
                    py.y(idx) = nan(length(py.x(idx)),1);
                    py.area(idx) = nan(length(py.x(idx)),1);
                    py.frDone(idx) = zeros(length(py.x(idx)),1);
                    
                % "t" -- threshold
                elseif cB == 116    
                    
                    disp(' ');
                    disp('Adjusting theshold:')
                    disp('   Left arrow  - back up a frame')
                    disp('   Right arrow - advance a frame')
                    disp('   Up arrow - increase threshold')
                    disp('   Down arrow - decrease threshold')
                    disp(' ')
                    
                    % Grab frame, threshold image & choose roi
                    warning off
                    img = grabFrame(vPath,p.filename{i},invert,x_roi,y_roi);
                    imshow(img)
                    cMap = colormap('gray');
                    warning on
                    
                    while 1
                        
                       imBW = ~im2bw(img,tVal);
                       
                       im = imread([vPath filesep p.filename{i}]);
                       
                       im(imBW(:)) = 232;
                       cMap(233,:) = clr;
                       
                       warning off
                       imshow(im,cMap)
                       title(['Threshold = ' num2str(tVal) ...
                              ' (return to exit)'])
                       
                       warning on 
                       
                       % Set limits
                       xlim(py.xlim);
                       ylim(py.ylim);
                
                       [xT,yT,bT] = ginput(1);
                       
                       if isempty(bT)
                           break
                           
                       % Left arrow
                       elseif cB == 28
                           
                           % Back up frame
                           i = max([1 i-1]);
                           
                       % Right arrow
                       elseif cB == 29
                           
                           % Advance frame
                           i = min([i+1 p.frNums(end)]);
                           
                           % Up arrow
                       elseif bT==30
                           tVal = min([1 tVal+0.02]);
                           
                           % Down arrow
                       elseif bT==31
                           tVal = max([0 tVal-0.02]);
                           
                       end
                       
                       clear xT yT bT im imBW
                    end
                    
                    
                end
                
%                 % Grab frame, threshold image & choose roi
%                 img = grabFrame(vPath,p.filename{i},invert,x_roi,y_roi);
%                 
%                 % Locate new postion of larva
%                 if ~isnan(py.x(i))
%                 [tmp(1),tmp(2),py.area(i),x_roipy,y_roipy,imBW] = ...
%                        findLarva(img,py.x(i),py.y(i),p.areaPrey,py_roi,tVal,'dist');
%                 end
                
                % Update image
                
                im = imread([vPath filesep p.filename{i}]);
                
                % Deinterlace image
                im = deinterlace(im);
                
                %imshow(im)
                %cMap = colormap('gray');

                figure(f)
                
                warning off all
                imshow(im,cMap)
                warning on all
                hold on
                plot(py.x(i),py.y(i),'r+')
                title(['Interactive mode: Frame ' num2str(p.frNums(i)) ' of ' ...
                    num2str(p.frNums(end)) ' ("r" to return to autotracking)'])
                %plot(x_roipy,y_roipy,'w--')
                hold off
                % Set limits
                xlim(py.xlim);
                ylim(py.ylim);

                
                clear im
                
            end
        end
        
        % Finished when capture reached
        if (i + 1 > length(p.frNums)) || ...
                ((p.captureFrame>0) && (p.frNums(i)>=p.captureFrame))
            py.finished = 1;
        end
        
        % Advance index
        i = i+1;
        
        % Clear variables for next loop
        clear img imBW imBW2 props imROI se x_roi y_roi maxB tmp
        
        % Save data
        save([vPath filesep 'prey_coords'],'py')
    end
 
end

close
disp(' '); disp('     . . . Finished collecting data on prey'); disp(' ')


%% Step through frames for position of predator

a3 = dir([vPath filesep 'pred_coords.mat']);

if isempty(a3)
    
    f = figure;
    set(f,'DoubleBuffer','on')
    
    % Loop through frames
    for i = 1:length(p.frNums)
        
        % Define roi coordinates
        [x_roi,y_roi] = roiCoords(p);
        
        % Grab frame, threshold image & choose roi
        img = grabFrame(vPath,p.filename{i},invert,x_roi,y_roi);
        imROI   = roipoly(img,x_roi,y_roi);
        imBW    = ~im2bw(img,p.tVal_pd);
        imBW    = imBW & imROI;
        clear img
        
        % Get peripheral shapes
        [B,L] = bwboundaries(imBW,'noholes');
        
        % Select blob with greatest periphery
        maxB = 0;
        idx = [];
        for j = 1:length(B)
            if length(B{j}) > maxB
                maxB = length(B{j});
                perim = B{j};
                idx = j;
            end
        end
        
        % Store away data
        pd.frame(i) = p.frNums(i);
        pd.filename{i} = p.filename{i};
        pd.xPerim{i} = perim(:,1);
        pd.yPerim{i} = perim(:,2);
        
        % Visualize frames
        if visSteps
            im = imread([vPath filesep p.filename{i}]);
            
            % Deinterlace image
            im = deinterlace(im);
            
            figure(f)
            warning off
            imshow(im)
            hold on
            plot(pd.yPerim{end},pd.xPerim{end},'r-')
            title(['Frame ' num2str(p.frNums(i)) ' of ' ...
                num2str(p.frNums(end))])
            hold off
            pause(.2)
            warning on
            clear im
        else
            disp(['Predator acquire: Frame ' num2str(p.frNums(i)) ' of ' ...
                num2str(p.frNums(end))]);
        end
        
        % Clear variables for next loop
        clear img imBW imBW2 props imROI se x_roi y_roi maxB
        
        if i > numVis
            close
            visSteps = 0;
        end
    end
    
    % Save data
    save([vPath filesep 'pred_coords'],'pd')
    
else
    
    % Load 'pd' structure of predator coordinates
    disp('Loading predator data . . .')
    load([vPath filesep 'pred_coords.mat'])
    
end



return


%TODO: postprocessing on predator to determine head


function [py_x,py_y,py_a,x_roipy,y_roipy,imBW] = ...
                findLarva(img,cX,cY,cA,py_roi,tVal,mthd)

% mthd - ('area' or 'dist') criterion for selecting blob            
            
% Define prey roi coordinates
x_roipy = cX + py_roi.*cos(linspace(0,2*pi,200));
y_roipy = cY + py_roi.*sin(linspace(0,2*pi,200));

% Binary image of the roi around the prey
pyROI = roipoly(img,x_roipy,y_roipy);

% Slice up img by the rois
imBW    = ~im2bw(img,tVal);
imBW    = imBW & pyROI;

clear img

% Dilate im & get properties
se    = strel('disk',ceil(sqrt(cA/pi)),4);
imBW = imdilate(imBW,se);
imBW = imerode(imBW,se);
LL    = bwlabel(imBW);
props = regionprops(LL,'Centroid','Area');

% Halt, if no blob
if isempty(props)
    py_x = nan;
    py_y = nan;
    py_a = nan;
    warning(['Lost larva -- try expanding the roi and/or ' ...
        'adjusting the threshold']);
    
% Store, if one blob
elseif length(props)==1
    py_x = props.Centroid(1);
    py_y = props.Centroid(2);
    py_a = props.Area;
    
    
else
    
    % Select blob with area closest to last
    if strcmp(mthd,'area')
        
        tmp = 10^10;
        for j = 1:length(props)
            if abs(cA - props(j).Area) < tmp
                tmp = abs(cA - props(j).Area);
                py_x = props(j).Centroid(1);
                py_y = props(j).Centroid(2);
                py_a = props(j).Area;
            end
        end
        
    % Select closest distance from last   
    elseif strcmp(mthd,'dist')
        
        dist = 10^10;
        for i = 1:length(props)
            cDist = sqrt((props(i).Centroid(1)-cX)^2 + ...
                (props(i).Centroid(2)-cY)^2);
            if cDist < dist
                dist = cDist;
                py_x = props(i).Centroid(1);
                py_y = props(i).Centroid(2);
                py_a = props(i).Area;
            end
        end
        
        
    else
        error('invalid entry for mthd');
        
    end
        
end



function img = grabFrame(dirPath,filename,invert,x_roi,y_roi)

% Load image
img = imread([dirPath filesep filename]);

% Deinterlace image
img = deinterlace(img);

%img = adapthisteq(img,'clipLimit',0.02,'Distribution','rayleigh');

% Load subtraction image
imSub  = imread([dirPath filesep,'meanImage.tif']);   

% Adjust grayscale values and convert to double
im     = (imadjust(img));
imSub  = (imadjust(imSub));

% Subtract background
warning off
im = imsubtract(imSub,im);
warning on

%im(find(im>255))  = 255;

if invert
    im = imcomplement(im);
end

% Use roi to crop image
if nargin > 3
    roiI = roipoly(im,x_roi,y_roi);
    img = uint8(255.*ones(size(im,1),size(im,2)));
    img(roiI(:)) = im(roiI(:));
else
    img = uint8(255.*ones(size(im,1),size(im,2)));
end


function img = deinterlace(img)
% This version uses a single field from an interlaced video frame
% Note: code could be modified to double temporal resolution

% Get coordinates for whole frame and individual fields
[X,Y] = meshgrid(1:size(img,2), 1:size(img,1));
[X1,Y1] = meshgrid(1:size(img,2), 1:2:size(img,1));
[X2,Y2] = meshgrid(1:size(img,2), 2:2:size(img,1)-2);

% Extract fields
fld1 = img(1:2:size(img,1),:);
%fld2 = img(2:2:size(img,1),:);

% Interpolate between scan lines of field 1
warning off
fr2 = uint8(interp2(X1,Y1,double(fld1),X2,Y2));
warning on

% Replace field 2 with interpolated values
for i=1:size(fr2,1)
    img(2*i,:) = fr2(i,:);
end


function [x_roi,y_roi] = roiCoords(p)
%Provides coordinates for an elliptical region of interest

numPts  = 400;
x_h     = p.roi_h.x(1:2);
y_v     = p.roi_v.y(1:2);
r_h     = abs(x_h(1)-x_h(2))/2;
r_v     = abs(y_v(1)-y_v(2))/2;
x_roi   = [];
y_roi   = [];

theta   = linspace(0,pi/2,round(numPts/4))';
x_roi   = [x_roi; r_h .* cos(theta) + mean(x_h)];
y_roi   = [y_roi; r_v .* sin(theta) + mean(y_v)];

theta   = linspace(pi/2,pi,round(numPts/4))';
x_roi   = [x_roi; r_h .* cos(theta) + mean(x_h)];
y_roi   = [y_roi; r_v .* sin(theta) + mean(y_v)];

theta   = linspace(pi,1.5*pi,round(numPts/4))';
x_roi   = [x_roi; r_h .* cos(theta) + mean(x_h)];
y_roi   = [y_roi; r_v .* sin(theta) + mean(y_v)];

theta   = linspace(1.5*pi,2*pi,round(numPts/4))';
x_roi   = [x_roi; r_h .* cos(theta) + mean(x_h)];
y_roi   = [y_roi; r_v .* sin(theta) + mean(y_v)];


function [x,y] = choosePoints(img,link,txt)
%Used for finding coordinate points on a static image 'img'.
warning off all
imshow(img);
title(txt)
hold on;
set(gcf,'DoubleBuffer','on');
disp(' '); disp(' ');
disp('Left mouse button picks points.');disp(' ');
disp('Right mouse button removes last point.');disp(' ');
disp('Press return to stop.')
n = 0;
but = 1;
while 1
    [xi,yi,but] = ginput(1);
    if isempty(but)
        break
    elseif but==1
        n = n+1;
        x(n) = xi;
        y(n) = yi;
        if link
            h = plot(x,y,'ro-');
        else
            h = plot(x,y,'ro');
        end
    elseif but==3
        if n-1 < 1
            n = 0;
            x = [];
            y = [];
        else
            n = n-1;
            x = x(1:n);
            y = y(1:n);
        end
        hold off
        imshow(img);
        title(txt)
        hold on
        if link
            h = plot(x,y,'ro-');
        else
            h = plot(x,y,'ro');
        end
    end
end

delete(h)

x = x'; y = y';
warning on all