function VideoInCustomGUI(vid_file)


%% Parameters

% Width of video frame display (pix)
% Adjust this to the size of your monitor
vidWidth = 450;

% Aspect ratio of raw video frame
AR = 1.4855;

% Create object for video files
readObj = VideoReader(vid_file);

% Check aspect ratio
if floor(AR*1000)~=floor(readObj.Width/readObj.Height*1000)
    error('Video not the expected aspect ratio');
end


%%
% Initialize the video reader.
%videoSrc = vision.VideoFileReader(vid_file, 'ImageColorSpace', 'Intensity');
videoSrc = vision.VideoFileReader(vid_file, 'ImageColorSpace', 'RGB');

%% 
% Create a figure window and two axes to display the input video and the
% processed video.
[hFig, hAxes] = createFigureAndAxes(AR, vidWidth);

%%
% Add buttons to control video playback.
insertButtons(hFig, hAxes, videoSrc, AR, vidWidth);

%% Result of Pressing the Start Button
% Now that the GUI is constructed, we trigger the play callback which
% contains the main video processing loop defined in the
% |getAndProcessFrame| function listed below. If you prefer to click on the
% |Start| button yourself, you can comment out the following line of code.
playCallback(findobj('tag','PBButton123'),[],videoSrc,hAxes, AR, vidWidth);

%%
% Note that each video frame is centered in the axis box. If the axis size
% is bigger than the frame size, video frame borders are padded with
% background color. If axis size is smaller than the frame size scroll bars
% are added.

%% Create Figure, Axes, Titles
% Create a figure window and two axes with titles to display two videos.
    function [hFig, hAxes] = createFigureAndAxes(AR, winWidth1)
        
        [bSize, winHeight1, winWidth2, winHeight2] = winDimens(AR,winWidth1);
        
        % Close figure opened by last run
        figTag = 'CVST_VideoOnAxis_9804532';
        close(findobj('tag',figTag));

        % Create new figure
        hFig = figure('numbertitle', 'off', ...
               'name', 'Video In Custom GUI', ...
               'menubar','none', ...
               'toolbar','none', ...
               'resize', 'on', ...
               'tag',figTag, ...
               'renderer','painters');
               %'position',[680 678 480 240]);
        
        % Get figure position
        fPos = get(hFig,'Position');
        
        % Create axes and titles
%          hAxes.axis1 = createPanelAxisTitle(hFig,[0.1 0.2 0.36 0.6],...
%                                             'Full frame video'); % [X Y W H]
%          hAxes.axis2 = createPanelAxisTitle(hFig,[0.5 0.2 0.36 0.6],'ROI');
%          hAxes.axis1 = createPanelAxisTitle(hFig,[50 400+((winWidth/AR)/8) ...
%                                 winWidth winWidth.*AR].*sc_fctr,...
%                                 'Full frame video'); % [X Y W H]
%          hAxes.axis2 = createPanelAxisTitle(hFig,...
%                         [winWidth+100 400 winWidth winWidth].*sc_fctr,'ROI');
         hAxes.axis1 = createPanelAxisTitle(hFig,...
             [bSize+(winWidth2-winWidth1)/2 3*bSize+winHeight2 winWidth1 winHeight1],...
                                'Full frame video'); % [X Y W H]
         hAxes.axis2 = createPanelAxisTitle(hFig,...
             [bSize 2*bSize winWidth2 winHeight2],'ROI');
    end


%% Create Axis and Title
% Axis is created on uipanel container object. This allows more control
% over the layout of the GUI. Video title is created using uicontrol.
    function hAxis = createPanelAxisTitle(hFig, pos, axisTitle)

        % Create panel
        %hPanel = uipanel('parent',hFig,'Position',pos,'Units','Normalized');
        hPanel = uipanel('parent',hFig,'Units','Pixels','Visible','on');
        
        % Set position
        hPanel.Position = pos;
        
        % Create axis   
        %hAxis = axes('position',[0 0 1 1],'Parent',hPanel); 
        hAxis = axes('Parent',hPanel,'Units','pixels'); 
        hAxis.Position = [0 0 pos(3) pos(4)];
        hAxis.XTick = [];
        hAxis.YTick = [];
        hAxis.XColor = [1 1 1];
        hAxis.YColor = [1 1 1];
        % Set video title using uicontrol. uicontrol is used so that text
        % can be positioned in the context of the figure, not the axis.
        titlePos = [pos(1)+0.02 pos(2)+pos(3)+0.3 0.3 0.07];
        uicontrol('style','text',...
            'String', axisTitle,...
            'Units','Normalized',...
            'Parent',hFig,'Position', titlePos,...
            'BackgroundColor',hFig.Color);
    end


%% Insert Buttons
% Insert buttons to play, pause the videos.
    function insertButtons(hFig,hAxes,videoSrc, AR, winWidth1)

        [bSize, winHeight1, winWidth2, winHeight2] = winDimens(AR,winWidth1);
        
        butWidth  = 50;
        butHeight = 25;
        
        b1x = (winWidth2-winWidth1)/2 + winWidth1/2 ;
        b1y = 3*bSize+winHeight2  - bSize/2;
        
        roiy = bSize;
        
        % Play button with text Start/Pause/Continue
        uicontrol(hFig,'unit','pixel','style','pushbutton','string','Start',...
                'position',[b1x+butWidth/2 b1y 1.25*butWidth butHeight], 'tag','PBButton123','callback',...
                {@playCallback,videoSrc,hAxes, AR, winWidth1});
        
        uicontrol(hFig,'unit','pixel','style','pushbutton','string','Set ROI',...
                'position',[b1x-winHeight1*.6 b1y butWidth butHeight], 'tag','setButton','callback', ...
                {@setCallback,hAxes});
            
        % Exit button with text Exit
        uicontrol(hFig,'unit','pixel','style','pushbutton','string','Exit',...
                'position',[b1x+winHeight1*.6+butWidth b1y butWidth butHeight],'callback', ...
                {@exitCallback,videoSrc,hFig});
            
       % ROI Coordinates     
       uicontrol(hFig,'unit','pixel','Style','text','String','ROI',...
           'Position',[b1x+butWidth/2 roiy butWidth butHeight/2],'tag','rou_title'); 
       uicontrol(hFig,'unit','pixel','Style','text','String','0',...
           'Position',[b1x+butWidth/2-1.5*butWidth roiy-butHeight/2 ...
           butWidth butHeight/2],'tag','xRect');
       uicontrol(hFig,'unit','pixel','Style','text','String','0',...
           'Position',[b1x+butWidth/2-butWidth/2 roiy-butHeight/2 ...
           butWidth butHeight/2],'tag','yRect');
       uicontrol(hFig,'unit','pixel','Style','text','String','0',...
           'Position',[b1x+butWidth/2+butWidth/2 roiy-butHeight/2 ...
           butWidth butHeight/2],'tag','wRect');
       uicontrol(hFig,'unit','pixel','Style','text','String','0',...
           'Position',[b1x+butWidth/2+1.5*butWidth roiy-butHeight/2 ...
           butWidth butHeight/2],'tag','hRect');
       
    end     


%% Play Button Callback
% This callback function rotates input video frame and displays original
% input video frame and rotated frame on axes. The function
% |showFrameOnAxis| is responsible for displaying a frame of the video on
% user-defined axis. This function is defined in the file
% <matlab:edit(fullfile(matlabroot,'toolbox','vision','visiondemos','showFrameOnAxis.m')) showFrameOnAxis.m>
    function playCallback(hObject,~,videoSrc,hAxes, AR, winWidth1)

        % Get dimensions
        [bSize, winHeight1, winWidth2, winHeight2] = winDimens(AR,winWidth1);
        
       %try
            % Check the status of play button
            isTextStart = strcmp(hObject.String,'Start');
            isTextCont  = strcmp(hObject.String,'Continue');
            if isTextStart
               % Two cases: (1) starting first time, or (2) restarting 
               % Start from first frame
               if isDone(videoSrc)
                  reset(videoSrc);
               end
            end
            
            if isTextStart
                rect = [];
            end
            
            if (isTextStart || isTextCont)
                hObject.String = 'Pause';
            else
                hObject.String = 'Continue';
            end

            
            while strcmp(hObject.String, 'Pause') && ~isDone(videoSrc)  
                % Get input video frame and rotated frame
                %[frame,rotatedImg,angle] = getAndProcessFrame(videoSrc,angle);     
                
                rect(1,1) = get_val('xRect');
                rect(1,2) = get_val('yRect');
                rect(1,3) = get_val('wRect');
                rect(1,4) = get_val('hRect');
                
                % Read input video frame
                frame = step(videoSrc);                
        
                % If 'rect' is undefined . . .                 
                if sum(rect)==0 || isempty(rect)
                    
                    % Set rect values to center of frame
                    rect(1,1) = winWidth1/2-winWidth1/10;
                    rect(1,2) = winHeight1/2-winWidth1/10;
                    rect(1,3) = winWidth1/12;
                    rect(1,4) = winWidth1/12;
                    
                    % Update roi boxes
                    set_val('xRect',rect(1));
                    set_val('yRect',rect(2));
                    set_val('wRect',rect(3));
                    set_val('hRect',rect(4));
                end
                
                % Display input video frame on axis
                showFrameOnAxis(hAxes.axis1, frame, 0);
                
                % Scale rectangle to frame size
                im_rect = rect .* size(frame,2)/hAxes.axis1.Position(3);
                
                
                h = imrect(hAxes.axis1,im_rect);
                

                set_val('xRect',rect(1));
                set_val('yRect',rect(2));
                set_val('wRect',rect(3));
                set_val('hRect',rect(4));

                
                % Display cropped video frame on axis
                im2= imcrop(frame, im_rect);
                showFrameOnAxis(hAxes.axis2, im2, 0);  
                
                %hIm = displayImage(hAxes.axis2, im2);
                
                %TODO: replace showFrameOnAxis and just use displayImage
              
                if isTextStart
                    hObject.String = 'Continue';
                end
               
            end

            % When video reaches the end of file, display "Start" on the
            % play button.
            if isDone(videoSrc)
               hObject.String = 'Start';
            end
            
            
%        catch ME
%            % Re-throw error message if it is not related to invalid handle 
%            if ~strcmp(ME.identifier, 'MATLAB:class:InvalidHandle')
%                rethrow(ME);
%            end
%        end
    end

%% Video Processing Algorithm
% This function defines the main algorithm that is invoked when play button
% is activated.
    function [frame,rotatedImg,angle] = getAndProcessFrame(videoSrc,angle)
        
        % Read input video frame
        frame = step(videoSrc);
        
        % Pad and rotate input video frame
        paddedFrame = padarray(frame, [30 30], 0, 'both');
        rotatedImg  = imrotate(paddedFrame, angle, 'bilinear', 'crop');
        angle       = angle + 1;
    end

%% Set ROI Callback
% This callback function releases system objects and closes figure window.
    function setCallback(~,~,hAxes)
        
        % Scale factor
        sc_factor = size(hAxes.axis1.Children(end).CData,2)/hAxes.axis1.Position(3);
        
        if length(hAxes.axis1.Children)>1
            delete(hAxes.axis1.Children(1:(end-1)))
        end
        
        rect(1,1) = get_val('xRect');
        rect(1,2) = get_val('yRect');
        rect(1,3) = get_val('wRect');
        rect(1,4) = get_val('hRect');
        
        % Scale rectangle to frame size
        im_rect = rect .* sc_factor;
        
        h = imrect(hAxes.axis1,im_rect);
        disp('Move region-of-interest. Double-click when done');
        wait(h);
        
        rect = getPosition(h);
        
        % Make square
        rect(4) = rect(3);
        
        
        
         % Display cropped video frame on axis
         %im2= imcrop(frame, im_rect);
         %showFrameOnAxis(hAxes.axis2, im2, 0); 
                
        % Rescale
        rect = rect ./ sc_factor;
        
        set_val('xRect',rect(1));
        set_val('yRect',rect(2));
        set_val('wRect',rect(3));
        set_val('hRect',rect(4));
        
        if length(hAxes.axis1.Children)>1
            delete(hAxes.axis1.Children(1:(end-1)))
        end
        
        hObject = findobj('tag','PBButton123');
        hObject.String = 'Start';
        playCallback(hObject,[],videoSrc,hAxes, AR, vidWidth);
    end

%% Exit Button Callback
% This callback function releases system objects and closes figure window.
    function exitCallback(~,~,videoSrc,hFig)
        
        % Close the video file
        release(videoSrc); 
        % Close the figure window
        close(hFig);
    end



    function hIm = displayImage(hAxis, frame)
    % Display image in the specified axis
    frameSize = size(frame);
    xdata = [1 frameSize(2)];
    ydata = [1 frameSize(1)];
    cdata = frame;
    cdatamapping = 'direct';

    hIm = image(xdata,ydata,cdata, ...
               'BusyAction', 'cancel', ...
               'Parent', hAxis, ...
               'CDataMapping', cdatamapping, ...
               'Interruptible', 'off');
    set(hAxis, ...
        'YDir','reverse',...
        'TickDir', 'out', ...
        'XGrid', 'off', ...
        'YGrid', 'off', ...
        'PlotBoxAspectRatioMode', 'auto', ...
        'Visible', 'off');

    end

function val = get_val(obj_str)

    obj = findobj('tag',obj_str);
    val = str2num(obj.String);
end

function set_val(obj_str,val)
    obj = findobj('tag',obj_str);
    obj.String = num2str(round(val));
end

function [bSize, winHeight1, winWidth2, winHeight2] = winDimens(AR,winWidth1)

    % Border size
    bSize = winWidth1/8;

    % Width of second window
    winWidth2 = 1.25*winWidth1;

    % Height of windows
    winHeight1 = winWidth1 / AR;
    winHeight2 = winWidth2;
end

end