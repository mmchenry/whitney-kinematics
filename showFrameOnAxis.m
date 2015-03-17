function showFrameOnAxis(hAxis, frame, includeScroll)
% This helper function is provided in support of the example 'Video Display
% in a Custom User Interface'. It displays a frame of video on a
% user-defined axis.
% Modifed by MJM (added includeScroll)

%   Copyright 2004-2010 The MathWorks, Inc.

%checkAxes(hAxis);
%checkFrame(frame);
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
    %checkHandles(hIm, hAxis);
    %checkFrameSize(hIm, size(frame));
    %
    try 
      set(hIm,'cdata',frame); drawnow;
      
    catch  %#ok<CTCH>
        % figure closed
      return;  
    end
end



%--------------------------------------------------------------------------
function checkAxes(hAxis)
% Check if the axis exists.
if ~isHandleType(hAxis, 'axes')
    % Figure was closed
    return;
end

%--------------------------------------------------------------------------
function checkHandles(hIm, hAxis)
% Check handles
if ~isHandleType(hIm, 'image')
    return;
end
if ~isequal(hAxis, get(hIm,'parent'))
    error('Parent of image handle, hIm, must be the axis, hAxis');
end
 
%--------------------------------------------------------------------------
function checkFrame(frame)
% Validate input image
validateattributes(frame, ...
    {'uint8', 'uint16', 'int16', 'double', 'single','logical'}, ...
    {'real','nonsparse'}, 'insertShape', 'I', 1)

% Input image must be grayscale or truecolor RGB.
errCond=(ndims(frame) >3) || ((size(frame,3) ~= 1) && (size(frame,3) ~=3));
if (errCond)
    error('Input image must be grayscale or truecolor RGB');
end

%--------------------------------------------------------------------------
function frame = convertToUint8RGB(frame)
% Convert input data type to uint8
if ~isa(class(frame), 'uint8')
    frame = im2uint8(frame);
end

% If the input is grayscale, turn it into an RGB image
if (size(frame,3) ~= 3) % must be 2d
    frame = cat(3,frame, frame, frame);
end

%--------------------------------------------------------------------------
function flag = isHandleType(h, hType)
% Check if handle, h, is of type hType
if isempty(h)
    flag = false;
else
    flag = (ishandle(h)==1) & (strcmpi(get(h,'type'), hType)==1);
end
 
%--------------------------------------------------------------------------
function checkFrameSize(hIm, frame_size)
% Check frame size
prev_size = size(get(hIm, 'cdata'));
if ~isequal(prev_size, frame_size)
    error('Frame size must remain the same');
end

%--------------------------------------------------------------------------
function addScrollPanel(hAxis, hIm)
% Add scroll panel. Note that image is centered in the axis box. If the
% axis size is bigger than the frame size, image borders are padded with
% background color. If axis size is smaller than the image size scroll bars
% are added.
hPanel = get(hAxis,'parent');
pos = get(hAxis,'position');

hSP = imscrollpanel(hPanel,hIm);
set(hSP,'Units','normalized', 'Position',pos);

%--------------------------------------------------------------------------
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
