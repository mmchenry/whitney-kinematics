function VideoAcqGUI(im_dir, data_dir, v, cCam)
% GUI for acquiring kinematics manually


%% Parameter values

% Width of video frame display (pix)
% Adjust this to the size of your monitor
vidWidth = 450;

%% Info text

disp(' ')
disp('Keys to operate the GUI in PLAY mode:');
disp('   Spacebar:     start/stop the video')
disp('   Left arrow:   play video backwards')
disp('   Right arrow:  play video forwards');
disp('   Up arrow:     Step forward 1 frame');
disp('   Down arrow:   Step backward one frame');
disp('   1 - 9:        Jump to different location in video');
disp('   =:            Zoom in region of interest');
disp('   -:            Zoom out region of interest');
disp(' ')

%% Initialize data structure

% Overwrite existing values
overwrite = 0;

% Load 'v' structure
load([data_dir filesep 'video_data.mat']);

v{cCam}.im_dir = im_dir;
v{cCam}.data_dir = data_dir;

% Make preyROI field, if not present
if ~isfield(v{cCam},'preyROI') || overwrite
    v{cCam}.preyROI = nan(length(v{cCam}.frames),4);
end

% Make preyROI field, if not present
if ~isfield(v{cCam},'playROI') || overwrite
    v{cCam}.playROI = nan(1,4);
end

% Make xPrey field, if not present
if ~isfield(v{cCam},'xPrey') || overwrite
    v{cCam}.xPrey = nan(length(v{cCam}.frames),1);
end

% Make yPrey field, if not present
if ~isfield(v{cCam},'yPrey') || overwrite
    v{cCam}.yPrey = nan(length(v{cCam}.frames),1);
end

% Make xPred field, if not present
if ~isfield(v{cCam},'xPred') || overwrite
    v{cCam}.xPred = nan(length(v{cCam}.frames),1);
end

% Make yPred field, if not present
if ~isfield(v{cCam},'yPred') || overwrite
    v{cCam}.yPred = nan(length(v{cCam}.frames),1);
end

% Save 'v' structure
save([data_dir filesep 'video_data.mat'],'v');

%% Get image size

% Load first frame
im = get_image(im_dir,v{cCam}.frames(1));

% Get all relavent dimensions for GUI
pos = winDimens(vidWidth,size(im,2),size(im,1));

clear im

%% Create a figure window and two axes to display the input video and the
% processed video.
[hFig, hAxes] = createFigureAndAxes(im_dir, v, cCam, pos);

%% Add buttons to control video playback.
insertButtons(hFig, hAxes, im_dir, v, cCam, pos);

%% Add text to control video playback.
insertText(hFig, hAxes, im_dir, v, cCam, pos);

% Update ROI text
adjust_roi(v, cCam);
    
% Update window
update_fig(hFig, hAxes, im_dir, v, cCam, pos)

%% Result of Pressing the Start Button
% Now that the GUI is constructed, we trigger the play callback which
% contains the main video processing loop defined in the
% |getAndProcessFrame| function listed below. If you prefer to click on the
% |Start| button yourself, you can comment out the following line of code.
%playCallback(findobj('tag','PBButton123'),[], hAxes, im_dir, v, cCam, pos);

%% Create Figure, Axes, Titles
% Create a figure window and two axes with titles to display two videos.
    function [hFig, hAxes] = createFigureAndAxes(im_dir, v, cCam, pos)
        
        
        % Close figure opened by last run
        figTag = 'CVST_VideoOnAxis_9804532';
        close(findobj('tag',figTag));

        % Create new figure
        hFig = figure('numbertitle', 'off', ...
               'name', 'Analysis GUI', ...
               'menubar','none', ...
               'toolbar','none', ...
               'resize', 'on', ...
               'tag',figTag, ...
               'renderer','painters',...
               'Units','pixels');
               %'position',[680 678 480 240]);
        
        % Get figure position
        %fPos = get(hFig,'Position');

        % Create axes and titles
         hAxes.axis1 = createPanelAxisTitle(hFig,...
             pos.win_full, pos.title_full, 'Full frame video', 'title1'); % [X Y W H]
                            
         hAxes.axis2 = createPanelAxisTitle(hFig, ...
             pos.win_roi, pos.title_roi, 'ROI', 'title2');
         
         % Set callback to report coordinates
        set(hFig, 'WindowButtonMotionFcn', {@mouseMove, hFig, hAxes, im_dir, v, cCam, pos});
        
        % Set callback for button presses
        set(hFig, 'WindowKeyPressFcn', {@but_down, hFig, hAxes, im_dir, v, cCam, pos});
    end

%% Create Axis and Title
% Axis is created on uipanel container object. This allows more control
% over the layout of the GUI. Video title is created using uicontrol.
    function hAxis = createPanelAxisTitle(hFig, posWin, posTitle, axisTitle, textTag)

        % Create panel
        %hPanel = uipanel('parent',hFig,'Position',pos,'Units','Normalized');
        hPanel = uipanel('parent',hFig,'Units','Pixels','Visible','on');
        
        % Set position
        hPanel.Position = posWin;
        
        % Create axis   
        %hAxis = axes('position',[0 0 1 1],'Parent',hPanel); 
        hAxis = axes('Parent',hPanel,'Units','pixels'); 
        hAxis.Position = [0 0 posWin(3) posWin(4)];
        hAxis.XTick = [];
        hAxis.YTick = [];
        hAxis.XColor = [1 1 1];
        hAxis.YColor = [1 1 1];
        % Set video title using uicontrol. uicontrol is used so that text
        % can be positioned in the context of the figure, not the axis.
        titlePos = posTitle;
        hUI = uicontrol('style','text',...
            'String', axisTitle,...
            'Units','Pixels',...
            'Parent',hFig,...
            'Position', titlePos,...
            'BackgroundColor',hFig.Color, ...
            'HorizontalAlignment','left',...
            'Tag',textTag);
    end

%% Insert Buttons
% Insert buttons to play, pause the videos.
    function insertButtons(hFig, hAxes, im_dir, v, cCam, pos)
        
        
        % Button to set ROI    
        uicontrol(hFig,'unit','pixel','style','pushbutton','string','Set ROI',...
                'position',pos.but_roi, 'tag','setButton','callback', ...
                {@setCallback, hFig, hAxes, im_dir, v, cCam, pos});
            
%         % Play button with text Start/Pause/Continue
%         uicontrol(hFig,'unit','pixel','style','pushbutton','string','Play',...
%                 'position',pos.but_start, 'tag','PBButton123','callback',...
%                 {@playCallback, hFig, hAxes, im_dir, v, cCam, pos});
        
    
%         % Button to track prey    
%         uicontrol(hFig,'unit','pixel','style','pushbutton',...
%                        'string','Track prey',...
%                        'position',pos.but_prey, ...
%                        'tag','preyButton','callback', ...
%                        {@preyCallback, hFig, hAxes, im_dir, v, cCam, pos});
            
        % Exit button with text Exit
        uicontrol(hFig,'unit','pixel','style','pushbutton','string','Exit',...
                'position',pos.but_exit,'callback', ...
                {@exitCallback,hFig});
    end 

%% Insert Text & Menus
% Insert buttons to play, pause the videos.
function insertText(hFig, hAxes, im_dir, v, cCam, pos)


   % ROI Coordinates     
   uicontrol(hFig,'unit','pixel','Style','text','String','Press space to play',...
       'Position',pos.text_roi(1,:),'tag','roi_title','BackgroundColor','w'); 
    uicontrol(hFig,'unit','pixel','Style','text','String','0',...
        'Position',pos.text_roi(2,:),'tag','xRect');
    uicontrol(hFig,'unit','pixel','Style','text','String','0',...
        'Position',pos.text_roi(3,:),'tag','yRect');
    uicontrol(hFig,'unit','pixel','Style','text','String','0',...
        'Position',pos.text_roi(4,:),'tag','wRect');
    uicontrol(hFig,'unit','pixel','Style','text','String','0',...
        'Position',pos.text_roi(5,:),'tag','hRect');

   % Mouse Coordinates     
   uicontrol(hFig,'unit','pixel','Style','text','String','Cursor',...
       'Position',pos.text_mouse(1,:),'tag','mouse_title','BackgroundColor','w'); 
    uicontrol(hFig,'unit','pixel','Style','text','String','0',...
        'Position',pos.text_mouse(2,:),'tag','xMouse');
    uicontrol(hFig,'unit','pixel','Style','text','String','0',...
        'Position',pos.text_mouse(3,:),'tag','yMouse');      

   % Key Coordinates     
   uicontrol(hFig,'unit','pixel','Style','text','String','Key',...
       'Position',pos.text_key(1,:),'tag','key_title','BackgroundColor','w'); 
   uicontrol(hFig,'unit','pixel','Style','text','String','0',...
        'Position',pos.text_key(2,:),'tag','key');

   % Frame Coordinates     
   uicontrol(hFig,'unit','pixel','Style','text','String','Frame',...
       'Position',pos.text_frame(1,:),'tag','frame_title','BackgroundColor','w'); 
   uicontrol(hFig,'unit','pixel','Style','edit','String','0',...
        'Position',pos.text_frame(2,:),'tag','edit_frame','callback', ...
                {@frameCallback, hFig, hAxes, im_dir, v, cCam, pos});
   uicontrol(hFig,'unit','pixel','Style','text','String','Start:',...
       'Position',pos.text_frame(3,:),'tag','startframe_text'); 
   uicontrol(hFig,'unit','pixel','Style','text','String','End:',...
       'Position',pos.text_frame(4,:),'tag','endframe_text'); 
   
   % Pause     
   uicontrol(hFig,'unit','pixel','Style','text','String','Frame pause (s)',...
       'Position',pos.pause_frame(1,:),'tag','pause_title','BackgroundColor','w'); 
   uicontrol(hFig,'unit','pixel','Style','edit','String','0.2',...
        'Position',pos.pause_frame(2,:),'tag','pause');
    
   % Direction     
   uicontrol(hFig,'unit','pixel','Style','text','String','Direction',...
       'Position',pos.dir_frame(1,:),'tag','dir_title','BackgroundColor','w'); 
   uicontrol(hFig,'unit','pixel','Style','text','String','->',...
       'Position',pos.dir_frame(2,:),'tag','dir');
   
   % Status     
   uicontrol(hFig,'unit','pixel','Style','text','String','Status',...
       'Position',pos.status_frame(1,:),'tag','status_title','BackgroundColor','w'); 
   uicontrol(hFig,'unit','pixel','Style','text','String','Paused',...
       'Position',pos.status_frame(2,:),'tag','status');
   
   % Mode     
   uicontrol(hFig,'unit','pixel','Style','text','String','Mode',...
       'Position',pos.mode_frame(1,:),'tag','mode_title','BackgroundColor','w'); 
   uicontrol(hFig,'unit','pixel','Style','popup',...
       'String',{'Play','Prey'},...
       'Position',pos.mode_frame(2,:),'tag','mode',...
       'Callback',{@setMode, hFig, hAxes, im_dir, v, cCam, pos},...
       'ForegroundColor',[0 .5 .5]); 
   
   
   % View mode     
   uicontrol(hFig,'unit','pixel','Style','text','String','View mode',...
       'Position',pos.viewmode_frame(1,:),'tag','viewmode_title','BackgroundColor','w'); 
   uicontrol(hFig,'unit','pixel','Style','popup',...
       'String',{'Normal','Back sub'},...
       'Position',pos.viewmode_frame(2,:),'tag','viewmode',...
       'Callback',{@setViewMode, hFig, hAxes, im_dir, v, cCam, pos}); 
end 

%% Set Mode
function setMode(hObject,~, hFig, hAxes, im_dir, v, cCam, pos)   
    
    % Load latest data ('v')
    load([v{cCam}.data_dir filesep 'video_data.mat'])
    
    % Get current mode
    [md,dur,dir,status] = mode_status;
    
    if strcmp(md,'Play')
        set(findobj('tag','mode'),'ForegroundColor',[0 .5 .5])
        
        % Set default duration
        set(findobj('tag','pause'),'String','0.2')
         
        % Set title text
        set(findobj('tag','roi_title'),'String','Press space to play');
        
        set_status(0)
        
        % View status
        set(findobj('tag','status_title'),'Visible','on');
        set(findobj('tag','status'),'Visible','on');
        
    elseif strcmp(md,'Prey')
        set(findobj('tag','mode'),'ForegroundColor',[.3 .7 .2])
        
        % Set default duration
        set(findobj('tag','pause'),'String','1')
        
        % Set title text
        set(findobj('tag','roi_title'),'String','Press SPACE to select point');
        
        set_status(1)
        
        % View status: off
        set(findobj('tag','status_title'),'Visible','off');
        set(findobj('tag','status'),'Visible','off');
        
    elseif strcmp(md,'Pred')
        set(findobj('tag','mode'),'ForegroundColor',[.9 .5 .3])
        
        % Set default duration
        set(findobj('tag','pause'),'String','1')
        
        set_status(1)
        
        % View status: off
        set(findobj('tag','status_title'),'Visible','off');
        set(findobj('tag','status'),'Visible','off');
    end
    
    %Bold the font
    set(findobj('tag','mode'),'Fontweight','Bold')
    
    % Update ROI text
    adjust_roi(v, cCam);
    
    % Update GUI
    update_fig(hFig, hAxes, im_dir, v, cCam, pos);
    
    % Activate ROI panel
    set(hAxes.axis2,'Selected','on')
end

%% Set View Mode
function setViewMode(hObject,~, hFig, hAxes, im_dir, v, cCam, pos)   
    
    % Load latest data ('v')
    load([v{cCam}.data_dir filesep 'video_data.mat'])
    
     % Get current mode
     md = viewmode_status;
 
     % Update GUI
     update_fig(hFig, hAxes, im_dir, v, cCam, pos);
     
     % Activate ROI panel
     set(hAxes.axis2,'Selected','on')
end

%% Play Callback
% This callback function rotates input video frame and displays original
% input video frame and rotated frame on axes. The function
% |showFrameOnAxis| is responsible for displaying a frame of the video on
% user-defined axis. This function is defined in the file
% <matlab:edit(fullfile(matlabroot,'toolbox','vision','visiondemos','showFrameOnAxis.m')) showFrameOnAxis.m>
function playCallback(hFig, hAxes, im_dir, v, cCam, pos)

    % Load latest data ('v')
    load([v{cCam}.data_dir filesep 'video_data.mat'])
    
    % Get current status
    [md,dur,modedir,status] = mode_status;    
      
    % Set ROI
    if isempty(get_val) || sum(get_val)==0
        rect = [];
    else
        rect = get_val;
    end

    % Get current frame number
    obj_frame = findobj('tag','edit_frame');   
    cFrame = str2num(obj_frame.String) + modedir;

    % Loop while in play mode
    while status==1
        % Start timer
        tic        
        
        % If an ROI is stored, set the values
        if  ~isnan(v{cCam}.playROI(1))
            set_val(v{cCam}.playROI);        
        end
        
        % Get current status
        [md,dur,modedir,status] = mode_status;
        
        % Update frame number
        obj_frame.String = num2str(cFrame);
        
        % Update ROI text
        adjust_roi(v, cCam);
        
        % Upate figure window
        update_fig(hFig, hAxes, im_dir, v, cCam, pos);

        % Get delay
        tlapse = toc;
        
        % Advance frame
        if tlapse < dur
            % Advance single frame
            cFrame = cFrame + modedir;
            
            % Wait for next iteration
            pause(dur-tlapse)
            
        else
            % Advance multiple frames
            cFrame = round(cFrame + (tlapse/dur)*modedir);
            
        end
        
        % Exit, if next frame is out of bounds
        if (cFrame >= max(v{cCam}.frames)) || cFrame <= 0
            set_status(0)
        end 
    end

end

%% Set ROI Callback
% This callback function releases system objects and closes figure window.
function setCallback(~,~, hFig, hAxes, im_dir, v, cCam, pos)

    % Load latest data ('v')
    load([v{cCam}.data_dir filesep 'video_data.mat'])
    
    % Scale factor (source pixel width / rendered width) of full frame
    sc_factor = size(hAxes.axis1.Children(end).CData,2)/hAxes.axis1.Position(3);

    if length(hAxes.axis1.Children)>1
        delete(hAxes.axis1.Children(1:(end-1)))
    end

    % Find ROI values
    rect = get_val;
    
    % Center of ROI (full frame FOR)
    xCntr = rect(1) + rect(3)/2;
    yCntr = rect(2) + rect(4)/2;
    
    % If ROI is out of frame . . .
    if (xCntr<0) ||  (xCntr>size(hAxes.axis1.Children(end).CData,2)) || ...
       (yCntr<0) ||  (yCntr>size(hAxes.axis1.Children(end).CData,1))
        
        
        xCntr = hAxes.axis1.XLim(2)/2;
        yCntr = hAxes.axis1.YLim(2)/2;
   
        % Set ROI (full frame FOR)
        im_rect = [xCntr-hAxes.axis1.XLim(2)/10 yCntr-hAxes.axis1.XLim(2)/10 ...
                hAxes.axis1.XLim(2)/5 hAxes.axis1.XLim(2)/5];
            
    else
        % Scale rectangle to frame size
        %im_rect = rect .* sc_factor;
        im_rect = rect;
    end

     
    % Create interactive ROI (full frame FOR)
    h = imrect(hAxes.axis1,im_rect);
    
    % Change title text
    ttext = get(findobj('tag','title1'),'String');
    set(findobj('tag','title1'),'String','Move region-of-interest. Double-click when done');
    
    % Wait
    wait(h);
    
    % Get values of new ROI
    if isempty(h)
        rect = get_val
    else
        rect = getPosition(h);
    end

    % Make square
    rect(4) = rect(3);

    % Set value in GUI
    set_val(rect);

    if length(hAxes.axis1.Children)>1
        delete(hAxes.axis1.Children(1:(end-1)))
    end

    % Get current status
    [mode,dur,modedir,status] = mode_status;
    
    % Get current frame
    cFrame = str2num(get(findobj('tag','edit_frame'),'String'));
    
    % Index of new current frame
    iFrame = find(cFrame==v{cCam}.frames,1,'first');
    
    % Set coordinate values for Play mode
    if strcmp(mode,'Play')
        v{cCam}.playROI = rect;
    
    % Set coordinate values for prey mode & rest are nans   
    elseif strcmp(mode,'Prey') 
        
        % If all nans remain
        if sum(isnan(v{cCam}.preyROI(iFrame:end,1)))==0
            % Index of remaining frames
            idx = iFrame:length(v{cCam}.frames);
        else
            % Index of non-nans
            iNonNan = [v{cCam}.frames>iFrame]' & ~isnan(v{cCam}.preyROI(:,1));
            
            % Index of remaining frames
            idx = iFrame:find(iNonNan,1,'first');
        end
        
        % Fill with current ROI
        v{cCam}.preyROI(idx,:) = repmat(rect,length(idx),1);
    end
    
    % Save coordinates
    save([v{cCam}.data_dir filesep 'video_data.mat'],'v');
    
    % Change back title text
    set(findobj('tag','title1'),'String',ttext);
    
    % Update figure
    update_fig(hFig, hAxes, im_dir, v, cCam, pos)
    
    % Activate ROI panel
    set(hAxes.axis2,'Selected','on')
end

%% Set Prey Callback
% This callback function releases system objects and closes figure window.
function preyCallback(hFig, hAxes, im_dir, v, cCam, pos)
    
    % Activate figure
    figure(hFig)
    
     % Activate ROI panel
    set(hAxes.axis2,'Selected','on')
    
    % Get cursor coordinates
    xCntr = str2num(get(findobj('tag','xMouse'),'String'));
    yCntr = str2num(get(findobj('tag','yMouse'),'String'));
    
    % Transform into ROI FOR
    [xCurr, yCurr] = full_to_roi(xCntr, yCntr);
    
    % Overlay point
    set(hAxes.axis2,'NextPlot','Add');
    h = plot(xCurr, yCurr,'+r','Parent',hAxes.axis2);
    set(h,'MarkerSize',5)
    set(hAxes.axis2,'NextPlot','Replace');
    pause(.5)
    
    % Load latest data ('v')
    load([v{cCam}.data_dir filesep 'video_data.mat'])
     
    % Get current frame number
    cFrame = str2num(get(findobj('tag','edit_frame'),'String'));
    
     % Index of new current frame
    iFrame = find(cFrame==v{cCam}.frames,1,'first');
    
    % Store coordinates
    v{cCam}.xPrey(iFrame)   = xCntr;
    v{cCam}.yPrey(iFrame)   = yCntr;
    
    % Handle for title text
    %htitle = findobj('tag','title2');  
    
    % Activate figure 
    %figure(hFig)
    
    % Activate ROI panel
    %set(hAxes.axis2,'Selected','on')
    
    % Get current status
    [mode,dur,modedir,status] = mode_status;
    
    % Advance single frame
    cFrame = cFrame + modedir;
    
    % Stop, if next frame is out of bounds
    if (cFrame >= max(v{cCam}.frames)) || cFrame <= 0
        beep
        return
    end
    
    % Set text for next frame number
    set(findobj('tag','edit_frame'),'String',num2str(cFrame));
    
    % Get current ROI
    rect = get_val;
    
    % Specify ROI for next frame
    if modedir==1
        rect = [xCntr-rect(3)/2 yCntr-rect(4)/2 rect(3) rect(4)];
    elseif (modedir==-1) && (iFrame>1) && ~isnan(v{cCam}.preyROI(iFrame-1,1))
        rect = v{cCam}.preyROI(iFrame-1,:);
    else
        rect = get_val;
    end

    % Update ROI text
    %set_val(rect)
    
    % Set coordinate values
    v{cCam}.preyROI(iFrame+1,:) = rect;
    
    % Save latest data ('v')
    save([v{cCam}.data_dir filesep 'video_data.mat'],'v')
    
    % Update ROI text
    adjust_roi(v, cCam);
    
    % Update window
    update_fig(hFig, hAxes, im_dir, v, cCam, pos);
end

%% Exit Button Callback
% This callback function releases system objects and closes figure window.
function exitCallback(~,~,hFig)        
    % Close the figure window
    close(hFig);
end

%% Mouse position Callback
function [X,Y] = mouseMove(fig,~, hFig, hAxes, im_dir, v, cCam, pos)
% Action when the cursor is moved over the figure window
    
    % Collect current point
    C = get(hAxes.axis2, 'CurrentPoint');
    
    
    if (C(1,1)>=0) && (C(1,1)<=hAxes.axis2.XLim(2)) && ...
       (C(1,2)>=0) && (C(1,2)<=hAxes.axis2.YLim(2))     
   
        % Find ROI values
        rect = get_val;
        
        % Set cursor
        set(gcf,'Pointer','circle')
        
        % Get text handles
        objX = findobj('tag','xMouse');
        objY = findobj('tag','yMouse');
    
        % Coordinates in full frame FOR
        Xfull = C(1,1)./range(hAxes.axis2.XLim).* rect(3) + rect(1);
        Yfull = C(1,2)./range(hAxes.axis2.YLim).* rect(4) + rect(2);
        
        % Report X and Y within frame
        X = min([max([rect(1) Xfull]) rect(1)+rect(3)]);
        Y = min([max([rect(2) Yfull]) rect(2)+rect(4)]);
        
        %X = min([max([0 C(1,1)]) hAxes.axis2.XLim(2)]);
        %Y = min([max([0 C(1,2)]) hAxes.axis2.YLim(2)]);
        
        objX.String = num2str(X);
        objY.String = num2str(Y);
    else
        set(gcf,'Pointer','arrow')
    end
end

%% Button down callback
function but_down(fig, key, hFig, hAxes, im_dir, v, cCam, pos)
% Actions when a key is pressed    

    % Set figure to current
    figure(hFig);
    
    % Get keystroke, display in key textbox
    obj = findobj('tag','key');
    obj.String = key.Key;

    % Cursor coordinates
    C1 = get(hAxes.axis1, 'CurrentPoint');
    C2 = get(hAxes.axis2, 'CurrentPoint'); 
    
    % If cursor is within axis frame . . .
    if ((C2(1,1)>0) && (C2(1,1)<hAxes.axis2.XLim(2)) && ...
            (C2(1,2)>0) && (C2(1,2)<hAxes.axis2.YLim(2))) || ...
            ((C1(1,1)>0) && (C1(1,1)<hAxes.axis1.XLim(2)) && ...
            (C1(1,2)>0) && (C1(1,2)<hAxes.axis1.YLim(2)))
        
        % Load latest data ('v')
        load([v{cCam}.data_dir filesep 'video_data.mat'])
 
        % Update window 
        %update_fig(hFig, hAxes, im_dir, v, cCam, pos);
        
        % Get handles for prey and play buttons
        preyButton = findobj('tag','preyButton');
        playButton = findobj('tag','PBButton123');
        preyTitle  = findobj('tag','title2');
        
        % Get mode status
        [mode,dur,modedir,status] = mode_status;
        
        % NUMBER ---------------------------------------------------------- 
        if sum(obj.String(1)==num2str([1:9]))==1
            % Set relative frame number
            rel_frame = round((str2num(obj.String)-1)/9*range(v{cCam}.frames) + ...
                v{cCam}.frames(1));
            set(findobj('tag','edit_frame'),'String',num2str(rel_frame));
            update_fig(hFig, hAxes, im_dir, v, cCam, pos);
            
        % LEFT ARROW ------------------------------------------------------
        elseif strcmp(obj.String,'leftarrow')
            set(findobj('tag','dir'),'String','<-');
            
        % RIGHT ARROW -----------------------------------------------------
        elseif strcmp(obj.String,'rightarrow')
            set(findobj('tag','dir'),'String','->');
            
        % UPARROW --------------------------------------------------------- 
        elseif strcmp(obj.String,'uparrow')
            % Handle of frame edit box
            hFrame = findobj('tag','edit_frame');
            
            % Get current frame number
            cFrame = str2num(get(hFrame,'String'));
            
            % Update frame number
            cFrame = min([cFrame+1 v{cCam}.frames(end)]);
            
            % Update box
            set(hFrame,'String',num2str(cFrame));
            
            % Update ROI text
            %adjust_roi(v, cCam);
        
            % Update GUI
            update_fig(hFig, hAxes, im_dir, v, cCam, pos);
            
        % DOWNARROW -------------------------------------------------------
        elseif strcmp(obj.String,'downarrow')
            % Handle of frame edit box
            hFrame = findobj('tag','edit_frame');
            
            % Get current frame number
            cFrame = str2num(get(hFrame,'String'));
            
            % Update frame number
            cFrame = max([cFrame-1 v{cCam}.frames(1)]);
            
            % Update box
            set(hFrame,'String',num2str(cFrame));
            
            % Update GUI
            update_fig(hFig, hAxes, im_dir, v, cCam, pos);
        
            
        % EQUAL/HYPHEN ---------------------------------------------------- 
        elseif strcmp(obj.String,'equal') || strcmp(obj.String,'hyphen')
            
            if strcmp(obj.String,'equal')
                sc_val = 0.75;
            else
                sc_val = 1.25;
            end
            
            % Get ROI values
            rect = get_val;
            
            % Find center
            xCntr = rect(1) + rect(3)/2;
            yCntr = rect(2) + rect(4)/2;
            
            % Rescale ROI dimensions
            rect(3) = rect(3)*sc_val;
            rect(4) = rect(4)*sc_val;
            
            % Define whole ROI
            rect = [xCntr-rect(3)/2 yCntr-rect(4)/2 rect(3) rect(4)];
            
            % Set ROI text
            set_val(rect);
            
            if strcmp(mode,'Prey')
                % Get current frame number
                cFrame = str2num(get(findobj('tag','edit_frame'),'String'));
            
                % Index of new current frame
                iFrame = find(cFrame==v{cCam}.frames,1,'first');
    
                % Set coordinate values
                v{cCam}.preyROI(iFrame,:) = rect;
                
                % Save latest data ('v')
                save([v{cCam}.data_dir filesep 'video_data.mat'],'v')
            end
            
            % Update window 
            update_fig(hFig, hAxes, im_dir, v, cCam, pos);
            
            
        % SPACEBAR --------------------------------------------------------    
        elseif strcmp(obj.String,'space')
            
            if strcmp(mode,'Play')
                if status==1
                    set_status(0)
                    set(findobj('tag','title2'),'String','Paused [space to restart]')
                    
                elseif (status==0) 
                    set_status(1)
                    set(findobj('tag','title2'),'String','Playing [space to stop]')
                    playCallback(hFig, hAxes, im_dir, v, cCam, pos);
                end
                
            elseif strcmp(mode,'Prey')
                set_status(1)
                preyCallback(hFig, hAxes, im_dir, v, cCam, pos);          
            end
        
        end
    end 
end

%% Set Window position and dimensions
function pos = winDimens(winWidth1,imWidth,imHeight)
% Coordinates and dimensions for objects in the GUI

    % Aspect ratio of source image
    AR = imWidth/imHeight;
    
    % Default button dimensions
    butWidth  = 50;
    butHeight = 25;
    
    % Window height of full frame
    winHeight1 = winWidth1/AR;
    
    % Window dimensions of ROI frame
    winWidth2 = 1.25*winWidth1;
    winHeight2 = winWidth2;
    
    
    
    % Border size (Around windows)
    bSize = winWidth1/15;
    
    % Position of full video frame
    pos.win_full = [bSize+(winWidth2-winWidth1)/2 ...
                    2*bSize+winHeight2 ...
                    winWidth1 ...
                    winHeight1];
                
    % Position of ROI frame            
    pos.win_roi = [bSize bSize winWidth2 winHeight2];
      
    % Position of full frame title
    pos.title_full = [pos.win_full(1) pos.win_full(2)+winHeight1 ...
                      10*butWidth butHeight/2];
                  
    % Position of ROI frame title
    pos.title_roi = [pos.win_roi(1) pos.win_roi(2)+winHeight2 ...
                      6*butWidth butHeight/2];
    % ROI button
    pos.but_roi = [pos.win_full(1)+butWidth/4 ...
                   pos.win_full(2)+butHeight/2 ...
                   butWidth butHeight];
    
    pos.but_start = [pos.win_full(1)+winWidth1/2-butWidth/2 ...
                     pos.win_full(2)+butHeight/2 ...
                     butWidth butHeight];
    
    pos.but_exit = [pos.win_full(1)+winWidth1-1*butWidth ...
                     pos.win_full(2)+butHeight/2 ...
                     butWidth butHeight];
    
    pos.but_prey = [pos.win_full(1)+1.5*butWidth ...
                   pos.win_full(2)+butHeight/2 ...
                   1.25*butWidth butHeight];
               
     % Top edge of full frame window          
     yEdge2 = pos.win_full(2) + pos.win_full(4);
     xEdge2 = pos.win_full(1) + pos.win_full(3);
     yEdge1 = pos.win_roi(2) + pos.win_roi(4);
     xEdge1 = pos.win_roi(1) + pos.win_roi(3);
               
    % Position of ROI coordinates           
    pos.text_roi(1,:) = [winWidth2+1.5*bSize winHeight2 butWidth butHeight/2];
    pos.text_roi(2,:) = [winWidth2+1.5*bSize winHeight2-butHeight/2 ...
                         butWidth butHeight/2];
    pos.text_roi(3,:) = [winWidth2+1.5*bSize winHeight2-2*butHeight/2 ...
                         butWidth butHeight/2];  
    pos.text_roi(4,:) = [winWidth2+1.5*bSize winHeight2-3*butHeight/2 ...
                         butWidth butHeight/2];  
    pos.text_roi(5,:) = [winWidth2+1.5*bSize winHeight2-4*butHeight/2 ...
                         butWidth butHeight/2];  
    % Logged prey coordinates   
    pos.text_coordPrey(1,:) = [winWidth2+1.5*bSize+butWidth*1.75 bSize+winHeight2...
                           butWidth butHeight/2];
    pos.text_coordPrey(2,:) = [winWidth2+1.5*bSize+butWidth*1.25 bSize ...
                           butWidth winHeight2];
    pos.text_coordPrey(3,:) = [winWidth2+1.5*bSize+butWidth*1.25+butWidth bSize ...
                           butWidth winHeight2];  
      
    % Logged predator coordinates   
    pos.text_coordPred(1,:) = [winWidth2+1.5*bSize+butWidth*3.8 bSize+winHeight2...
                           butWidth butHeight/2];
    pos.text_coordPred(2,:) = [winWidth2+1.5*bSize+butWidth*3.3 bSize ...
                           butWidth winHeight2];
    pos.text_coordPred(3,:) = [winWidth2+1.5*bSize+butWidth*3.3+butWidth bSize ...
                           butWidth winHeight2];  
                       
    % Position of cursor coordinates           
    pos.text_mouse(1,:) = [winWidth2+1.5*bSize winHeight2-butHeight*3 ...
                           butWidth butHeight/2];
    pos.text_mouse(2,:) = [winWidth2+1.5*bSize winHeight2-butHeight*3-butHeight/2 ...
                         butWidth butHeight/2];
    pos.text_mouse(3,:) = [winWidth2+1.5*bSize winHeight2-butHeight*3-2*butHeight/2 ...
                         butWidth butHeight/2];           
                 
    % Position of key press coordinates           
    pos.text_key(1,:) = [winWidth2+1.5*bSize winHeight2-butHeight*5 ...
                           butWidth butHeight/2];
    pos.text_key(2,:) = [winWidth2+1.5*bSize winHeight2-butHeight*5-butHeight/2 ...
                         butWidth butHeight/2];
                     
    % Position of frame number  
    pos.text_frame(1,:) = [xEdge2+0.5*bSize yEdge2-butHeight ...
                           1.5*butWidth butHeight/2];
    pos.text_frame(2,:) = [xEdge2+0.5*bSize yEdge2-2*butHeight ...
                           1.5*butWidth 0.75*butHeight];  
    pos.text_frame(3,:) = [xEdge2+0.5*bSize yEdge2-2.75*butHeight ...
                           1.5*butWidth 0.75*butHeight];  
    pos.text_frame(4,:) = [xEdge2+0.5*bSize yEdge2-3.5*butHeight ...
                           1.5*butWidth 0.75*butHeight];   
                       
    % mode
    pos.mode_frame(1,:) = [xEdge2+0.5*bSize yEdge2-4.5*butHeight ...
                           1.5*butWidth butHeight/2];
    pos.mode_frame(2,:) = [xEdge2+0.4*bSize yEdge2-5.75*butHeight ...
                           1.75*butWidth 1.2*butHeight]; 
                       
    % pause
    pos.pause_frame(1,:) = [xEdge2+0.5*bSize yEdge2-6.50*butHeight ...
                           1.5*butWidth butHeight/2];
    pos.pause_frame(2,:) = [xEdge2+0.5*bSize yEdge2-7.25*butHeight ...
                           1.5*butWidth 0.75*butHeight]; 
                       
    % direction
    pos.dir_frame(1,:) = [xEdge2+0.5*bSize yEdge2-8*butHeight ...
                           1.5*butWidth butHeight/2];
    pos.dir_frame(2,:) = [xEdge2+0.5*bSize yEdge2-8.75*butHeight ...
                           1.5*butWidth 0.75*butHeight];     
                       
    % status
    pos.status_frame(1,:) = [xEdge2+0.5*bSize yEdge2-9.75*butHeight ...
                           1.5*butWidth butHeight/2];
    pos.status_frame(2,:) = [xEdge2+0.5*bSize yEdge2-10.5*butHeight ...
                           1.5*butWidth 0.75*butHeight];  
                       
    % View mode
    pos.viewmode_frame(1,:) = [xEdge2+0.5*bSize yEdge2-11.5*butHeight ...
                           1.5*butWidth butHeight/2];
    pos.viewmode_frame(2,:) = [xEdge2+0.3*bSize yEdge2-12.25*butHeight ...
                           2*butWidth 0.75*butHeight];                     
end


% Edit frame callback
function frameCallback(~,~, hFig, hAxes, im_dir, v, cCam, pos)
    update_fig(hFig, hAxes, im_dir, v, cCam, pos)
end

%% Update GUI 
function update_fig(hFig, hAxes, im_dir, v, cCam, pos)
    
    % Load latest data ('v')
    load([v{cCam}.data_dir filesep 'video_data.mat'])
    
    % Activate figure window
    figure(hFig)
    
    % Update ROI text
    adjust_roi(v, cCam);
            
    % Scale factor (source pixel width / rendered width) of full frame
    %sc_factor = size(hAxes.axis1.Children(end).CData,2)/hAxes.axis1.Position(3);
    
    % Handle for frame edit box
    edit_frame = findobj('tag','edit_frame');
    
    % Get current status
    [mode,dur,modedir,status] = mode_status;
    
    % Get view mode status
    viewmode = viewmode_status;
    
    % If background subtraction requested . . .
    if strcmp(viewmode,'Back sub')
        % Look for mean image
        a2 = dir([v{cCam}.data_dir filesep 'meanImage.tif']);
        
        % Calculate mean image, if it does not exist
        if isempty(a2)
           makeMeanImage(v{cCam}.data_dir,im_dir,v{cCam}.frames);
           
        % Otherwise, load it
        else
            imSub = imread([v{cCam}.data_dir filesep 'meanImage.tif']);
        end
    end
    
    % Set text show start & end frames
    set(findobj('tag','startframe_text'),'String',...
                   ['Start: ' num2str(v{cCam}.frames(1))]);
    set(findobj('tag','endframe_text'),'String',...
                   ['End: ' num2str(v{cCam}.frames(end))]);
               
    % Get current frame number
    frame_num = str2num(edit_frame.String);
               
    % Set limits on frame numbers
    if frame_num<v{cCam}.frames(1)
        edit_frame.String = num2str(v{cCam}.frames(1));
        
    elseif frame_num>v{cCam}.frames(end)
        edit_frame.String = num2str(v{cCam}.frames(end));
    end
    
    % Get current frame number
    frame_num = str2num(edit_frame.String);
    
    % Index for frame number
    iFrame = v{cCam}.frames==frame_num;

    % Read input video frame
    frame = get_image(im_dir,v{cCam}.frames(iFrame));
    
    if strcmp(viewmode,'Back sub')
        % Convert to grayscale
        frame = rgb2gray(frame);
        
        % Adjust grayscale values and convert to double
        frame     = imadjust(frame);
        imSub     = imadjust(imSub);
        
        % Subtract background
        warning off
        frame = imcomplement(imsubtract(imSub,frame));
        warning on
        
        % Enhance contrast
        frame     = imadjust(frame);
    end
    
    % Display full video frame
    delete(hAxes.axis1.Children)
    showFrameOnAxis(hAxes.axis1, frame, 0);
    pause(0.001) 
    
    % Get window dimensions (full frame FOR)
    winWidth1  = size(hAxes.axis1.Children(end).CData,2);
    winHeight1 = size(hAxes.axis1.Children(end).CData,1);    
    
    % Get coordinates for the ROI (Full frame FOR)
    rect = get_val;
   
    % Center of ROI (Full frame FOR)
    xCntr = rect(1) + rect(3)/2;
    yCntr = rect(2) + rect(4)/2;          
        
    % If rect is undefined or off frame
    if isempty(rect) || sum(rect)==0 || ...
            (xCntr<0) ||  (xCntr>winWidth1) || ...
            (yCntr<0) ||  (yCntr>winHeight1)

        % Set rect values to center of frame
        rect(1,1) = winWidth1/2-winWidth1/5/2;
        rect(1,2) = winHeight1/2-winWidth1/5/2;
        rect(1,3) = winWidth1/5;
        rect(1,4) = winWidth1/5;
    end

    % Update roi box
    set_val(rect);
    
    % Hold on Axis1
    set(hAxes.axis1,'NextPlot','Add')
    
    % Set roi square on full frame
    x1 = rect(1); x2 = rect(1)+rect(3);
    y1 = rect(2); y2 = rect(2)+rect(4);
    plot([x1 x2 x2 x1 x1], [y1 y1 y2 y2 y1], 'w-',...
         mean([x1 x2]).*[1 1],[y1 y2], 'w:', ...
         [x1 x2], mean([y1 y2]).*[1 1], 'w:',...
         'Parent',hAxes.axis1);
    
    % In Prey mode
    if strcmp(mode,'Prey') 
        % Index of prior frames
        idx = 1:find(iFrame);
        
        % Plot prior coordinates
        h = plot(v{cCam}.xPrey(idx),v{cCam}.yPrey(idx),'r', ...
            'Parent',hAxes.axis1);
        set(h,'MarkerSize',3)
    end
     
    % Hold off Axis1
    set(hAxes.axis1,'NextPlot','Replace');
    
    % Get cropped image
    im2 = imcrop(frame, rect);
    
    % Display cropped image
    delete(hAxes.axis2.Children);
    showFrameOnAxis(hAxes.axis2, im2, 0);
    
    % Limits for x and y axes
    xL = hAxes.axis2.XLim;
    yL = hAxes.axis2.YLim;
    
    % Hold on Axis 2
    set(hAxes.axis2,'NextPlot','Add');
    
    % Add cross hairs
     h = plot([mean(xL) mean(xL)],yL,'w:',xL,[mean(yL) mean(yL)],'w:',...
         'Parent',hAxes.axis2);
     
     % In Play mode . . .
     if strcmp(mode,'Play')
        [xPrey, yPrey] = full_to_roi(v{cCam}.xPrey(iFrame), ...
                                      v{cCam}.yPrey(iFrame));
         h(2) = plot(xPrey, yPrey,'+y','Parent',hAxes.axis2);
         set(h(2),'MarkerSize',5)
         
     % In Prey mode . . .
     elseif strcmp(mode,'Prey')
         
         [xPrior, yPrior] = full_to_roi(v{cCam}.xPrey, ...
                                v{cCam}.yPrey );
         [xCurr, yCurr] = full_to_roi(v{cCam}.xPrey(iFrame), ...
                                      v{cCam}.yPrey(iFrame));
       
         % Plot prior coordinates
         
         h(1) = plot(xPrior, yPrior,'w--',...
             'Parent',hAxes.axis2);
         
         h(2) = plot(xCurr, yCurr,'+r','Parent',hAxes.axis2);
         set(h(2),'MarkerSize',5)
     end
     
    % Hold off Axis 2
    set(hAxes.axis2,'NextPlot','Replace');
    
    % Activate figure
    figure(hFig)
    
     % Activate ROI panel
    set(hAxes.axis2,'Selected','on')
end

%% Misc helper functions

function adjust_roi(v, cCam)
    
    % Get status
    [md,dur,dir,status] = mode_status;
    
    % Get current roi
    rect = get_val;
    
    % Get current frame number
    cFrame = str2num(get(findobj('tag','edit_frame'),'String'));
    
     % Index of new current frame
    iFrame = find(cFrame==v{cCam}.frames,1,'first');
    
    % PLAY mode
    if strcmp(md,'Play') && ~isnan(v{cCam}.playROI(1,1))
            rect = v{cCam}.playROI;
        
        
    % PREY mode    
    elseif strcmp(md,'Prey') && ~isnan(v{cCam}.preyROI(iFrame,1))
       rect = v{cCam}.preyROI(iFrame,:);  
       
    elseif strcmp(md,'Prey') && ~isnan(v{cCam}.playROI(1,1))
        rect = v{cCam}.playROI;
    end
    
    % Update text
    set_val(rect);

end

function [x, y] = full_to_roi(xVal,yVal)
% Converts from full frame coordinates to ROI coords    
     % Get ROI
     rect = get_val;

     % Normalize to size of rendered frame
     xNorm = (xVal-rect(1))/rect(3);
     yNorm = (yVal-rect(2))/rect(4);

     % Transform into frame coords
     x = xNorm .* range(hAxes.axis2.XLim) + hAxes.axis2.XLim(1);
     y = yNorm .* range(hAxes.axis2.YLim) + hAxes.axis2.YLim(1);
end

function [md,dur,dir,status] = mode_status
    % Get mode
    hMode = findobj('tag','mode');
    
    % Current mode
    md = hMode.String{hMode.Value};
    
    % Get pause
    dur = str2num(get(findobj('tag','pause'),'String')); 
    
    % Get direction
    dir_text = get(findobj('tag','dir'),'String');
    
    if strcmp(dir_text,'->')
        dir = 1;
    elseif strcmp(dir_text,'<-')
        dir = -1;
    else
        error('Do not recognize direction');
    end
    
    % Get status
    status_text = get(findobj('tag','status'),'String');
    
    if strcmp(status_text,'Running')
        status = 1;
    else
        status = 0;
    end
end

function md = viewmode_status
    % Get mode address
    hMode = findobj('tag','viewmode');
    
     % Current mode string
    md = hMode.String{hMode.Value};
end

function set_status(status)
    if status==1
        set(findobj('tag','status'),'String','Running');
    elseif status==0
        set(findobj('tag','status'),'String','Paused');
    end
end

function set_mode(mde)
    if strcmp(mde,'Play')
        set(findobj('tag','mode'),'String','Play');
        set(findobj('tag','mode'),'BackgroundColor',[0 .5 .5])
        % Set default duration
        set(findobj('tag','pause'),'String','0.2')
        
    elseif strcmp(mde,'Prey')
        set(findobj('tag','mode'),'String','Prey');
        set(findobj('tag','mode'),'BackgroundColor',[.1 .8 .9])
        % Set default duration
        set(findobj('tag','pause'),'String','1')
        
    elseif strcmp(mde,'Pred')
        set(findobj('tag','mode'),'String','Pred');
        set(findobj('tag','mode'),'BackgroundColor',[.9 .5 .3])
        
        % Set default duration
        set(findobj('tag','pause'),'String','1')
    
    else
        set(findobj('tag','mode'),'String','-');
        set(findobj('tag','mode'),'BackgroundColor',0.5.*[1 1 1]);
        
        % Set default duration
        set(findobj('tag','pause'),'String','1')
    end
    
    set(findobj('tag','mode'),'Fontweight','Bold')
    set(findobj('tag','mode'),'ForegroundColor','w')
end

function [xPrey, yPrey, xPred, yPred] = get_coords
    xPrey_str =  get(findobj('tag','xPrey'),'String'); 
    for i = 1:length(xPrey_str)
        xPrey(i,1) = str2num(xPrey_str{i});
    end
    yPrey_str =  get(findobj('tag','yPrey'),'String'); 
    for i = 1:length(yPrey_str)
        yPrey(i,1) = str2num(yPrey_str{i});
    end

    xPred_str =  get(findobj('tag','xPred'),'String'); 
    for i = 1:length(xPred_str)
        xPred(i,1) = str2num(xPred_str{i});
    end
    yPred_str =  get(findobj('tag','yPred'),'String'); 
    for i = 1:length(yPred_str)
        yPred(i,1) = str2num(yPred_str{i});
    end
end


function im = get_image(im_dir,fr_num)    
    tmp = ['0000000' num2str(fr_num)];
    tmp = tmp(end-6:end);
    im_name = ['frame_' tmp '.jpeg'];
    im = imread([im_dir filesep im_name]);
end

function time_str = convert_time(t)
    % Creates a time string from time in seconds
    min_val  = floor(t/60);
    sec_val  = floor(t-60*min_val);
    frac_val = floor(1000*((t-60*min_val)-sec_val));

    min_str = ['0' num2str(min_val)];
    min_str = min_str(end-1:end);
    sec_str = ['0' num2str(sec_val)];
    sec_str = sec_str(end-1:end);
    frac_str = ['00' num2str(frac_val)];
    frac_str = frac_str(end-2:end);

    time_str = [min_str ':' sec_str ':' frac_str];

end

% Get & Set rect values
function rect = get_val
% Get ROI position   
    obj         = findobj('tag','xRect');
    rect(1,1)   = str2num(obj.String);
    
    obj         = findobj('tag','yRect');
    rect(1,2)   = str2num(obj.String);
    
    obj         = findobj('tag','wRect');
    rect(1,3)   = str2num(obj.String);
    
    obj         = findobj('tag','hRect');
    rect(1,4)   = str2num(obj.String);
end

function set_val(rect)
% Set ROI position
    obj = findobj('tag','xRect');
    obj.String = num2str((rect(1)));
    
    obj = findobj('tag','yRect');
    obj.String = num2str((rect(2)));
    
    obj = findobj('tag','wRect');
    obj.String = num2str((rect(3)));
    
    obj = findobj('tag','hRect');
    obj.String = num2str((rect(4)));
end

function showFrameOnAxis(hAxis, frame, includeScroll)
    % This helper function  displays a frame of video on a user-defined axis.

    frame = convertToUint8RGB(frame);

    try
        hChild = get(hAxis, 'Children');
    catch %#ok<CTCH>
        return; % hAxis does not exist; nothing to draw
    end

    isFirstTime = isempty(hChild);

    if isFirstTime
        hIm = displayImage(hAxis, frame);
        if includeScroll
            addScrollPanel(hAxis, hIm);
        end
    else
        hIm = hChild(end);

        try
            set(hIm,'cdata',frame); drawnow;
        catch  %#ok<CTCH>
            % figure closed
            return;
        end
    end
end

function frame = convertToUint8RGB(frame)
    % Convert input data type to uint8
    if ~isa(class(frame), 'uint8')
        frame = im2uint8(frame);
    end

    % If the input is grayscale, turn it into an RGB image
    if (size(frame,3) ~= 3) % must be 2d
        frame = cat(3,frame, frame, frame);
    end
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

end