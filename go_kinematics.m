function go_kinematics(video_path)
% Conducts calibration for 3D kinematic experiments that use GoPro cameras
% Requires Matlab 2014b (or later), Computer Vision Toolbox and Image
% Processing Toolbox.


%% Code execution


% Determines the camera parameters (i.e. lens correction) for single HERO4 
% in 720 'narrow' mode
lens_calibration = 0;

% Determines all parameters for a stero calibration that uses two HERO4s in
% 720 'narrow' mode
stereo_calibration = 0;

% Test calibration with known landmarks
test_calibration = 0;

% Adopts an alternate approach to 3D calibaration (may be more scalable)
threeD_calibration = 0;

% Toy with 3D calibration
threeD_play = 0;

% Tests using the audio channel to synchronize two cameras
test_sync = 0;


%% Parameter values

% Write results of calibration to disk
write_results = 1;

% Maximum number of frames permited in the delay
max_frames = 5;


%% Paths

% Find root on Matt's computer
if ~isempty(dir('/Users/mmchenry'))    
    % Directory root
    root_data   = '/Users/mmchenry/Dropbox/Projects/JimmyJacob'; 
    root_check  = '/Users/mmchenry/Documents/Projects/gopro kinematics';
    root_video  = '/Volumes/WD MACPART/Video/Liao pred-prey/organized files';
else
    error('This computer is not recognized')
end

% Checkboard video file for single camera calibration (Lens correction, 720 Narrow)
check_path720 = [root_check filesep '/Lens correction, 720 Narrow/Mchero4_A'];

% Checkboard video file for single camera calibration (Lens correction, 1080 Narrow)
check_path1080 = [root_check filesep '/Lens correction, 1080 Narrow/Mchero4_A'];

% Check for external drive
if isempty(dir(root_video))
    error('If does not look like your external drive is plugged in');
end

% Get sequence path
if nargin < 1
    video_path = uigetdir(root_video,'Choose sequence directory');
end

% Check path
if ~strcmp(root_video,video_path(1:length(root_video)))
    error('Video files must be on root_video path')
end

% Create date and sequence paths in data directory
tmp   = video_path(length(root_video)+2:end);
idx   = find(tmp==filesep,1,'first');
date_path = tmp(1:(idx-1));
seq_path  = tmp((idx+1):end);
data_path = [root_data filesep 'rawdata' filesep date_path filesep seq_path];
clear tmp idx

% Make date directory, if needed
if isempty(dir([root_data filesep 'rawdata' filesep date_path]))
    [success,message,messageid] = mkdir([root_data filesep 'rawdata' ...
                                         filesep date_path]);
    clear success message messageid
end

% Make sequence directory, if needed
if isempty(dir(data_path))
    [success,message,messageid] = mkdir(data_path);
    clear success message messageid
end


%% Video player





ttt=4
    
% Path to calibration data
%cal_path = [root_data filesep 'Projects/gopro kinematics/3d pred prey trial/calibration2'];

%p
%data_path = [root filesep 'rawdata'];





%% Load data

% Load camera parameters for lens distortion ('cameraParams')
load([check_path1080 filesep 'calibration data' filesep 'camera parameters.mat'])

lensParams = cameraParams;
clear cameraParams

% Load calibration ('cal')
%load([cal_path filesep 'threeD calibration.mat']);

% Load roi data ('roi')
%load([cal_path filesep 'roi data.mat'])


%TODO: Organize 





%% Save modified movie


if 0
    
% Check number of cameras
num_cam = length(dir([video_path filesep 'McHero4*']));

if (num_cam ~= 3) || (length(cal)~=num_cam)
    error('There needs to be 3 cameras in your setup')
end

% Paths to videos
vid_path{1} = [video_path filesep 'McHero4_A'];
vid_path{2} = [video_path filesep 'McHero4_B'];
vid_path{3} = [video_path filesep 'McHero4_C'];

 % Get video path
a = dir([vid_path{1} filesep '*.MP4']);
obj = VideoReader([vid_path{1} filesep a(1).name]);   

% Prompt for recording duration
prompt        = {'Starting frame number:','Ending frame number:'};
name          = 'Video duration';
numlines      = 1;
defaultanswer = {'1',num2str(obj.NumberOfFrames)};
answer        = inputdlg(prompt,name,numlines,defaultanswer);

% Store answers
startFrame = str2num(answer{1});
endFrame   = str2num(answer{2});

% Step thru each cam
for i = 1:num_cam

    % Update status
    disp(['Starting cam ' num2str(i) ' . . .'])
    
    % Get video path
    a = dir([vid_path{i} filesep 'GO*.MP4']);
    
    % Check for video
    if length(a)~=1
        error(['Expecting one "GO" video file in ' vid_path{i}])
    end 
    
    % Create object for video files
    readObj = VideoReader([vid_path{i} filesep a(1).name]);
    
    % Extract number of frames
    nFrames = readObj.NumberOfFrames;
    
%     % Create video writer object
%     writerObj = VideoWriter([vid_path{i} filesep 'Processed video'],'MPEG-4');
%     writerObj.FrameRate = readObj.FrameRate;
%     open(writerObj)
    
    % Frame index
    frIdx = 1:nFrames;
    frIdx = find((frIdx >= startFrame) & (frIdx <= min([endFrame nFrames])));
    
    % Initialize wait bar
    h = waitbar(0,'','Name',['Cam ' num2str(i)],...
            'CreateCancelBtn',...
            'setappdata(gcbf,''canceling'',1)');    
    setappdata(h,'canceling',0)
    
    for j = 1:length(frIdx)
        
        % Acquire frame
        frame = give_frame(readObj,frIdx(j),roi{i},lensParams,cal{i}.cameraParams);
        
        % Write to video file
        %writeVideo(writerObj,frame)
        
        imwrite(frame,[vid_path{i} filesep 'processed frames' filesep 'f' num2str(j) '.tiff'],'TIFF')
        
        % Check for Cancel button press
        if getappdata(h,'canceling')
            break
        end
        
        % Report current estimate in the waitbar's message field
        waitbar(j/length(frIdx),h)     
        
        %disp(num2str(j))
    end
    
    close(writerObj)
    
    
    
    
    %h = implay([vid_path{i} filesep a(1).name])
    %title('test')
    %pause
    
    
    
     % Create objects for video files
    %vid{i}.obj.reader = vision.VideoFileReader([vid_path{i} filesep a(1).name]);
    %vid{i}.obj.videoPlayer = vision.VideoPlayer('Position', [20, 30, 1350, 800]);
    %vid{i}.obj.videoPlayer.show;
    %frame = vid{i}.obj.reader.step();
    %vid{i}.obj.videoPlayer.step(frame);
end

end


%% Get video information
   
% Check number of cameras
num_cam = length(dir([video_path filesep 'McHero4*']));

if (num_cam < 1) 
    error('No movie directories found on requested path')
end

% if (num_cam ~= 3) %|| (length(cal)~=num_cam)
%     error('There needs to be 3 cameras in your setup')
% end

% Paths to 3D calibration videos
vid_path{1} = [video_path filesep 'McHero4_A'];
vid_path{2} = [video_path filesep 'McHero4_B'];
vid_path{3} = [video_path filesep 'McHero4_C'];

% Step thru each cam
for i = 1:num_cam
    
    % Get video path
    a = dir([vid_path{i} filesep 'G*.MP4']);
    %a = dir([vid_path{i} filesep 'GOPR0043.mov']);
    
    % Check for video
    if length(a)~=1
        error(['Expecting one "GO" video file in ' vid_path{i}])
    end 
    
    % Create object for video files
    vid{i}.obj = VideoReader([vid_path{i} filesep a(1).name]);
    
    % Extract number of frames
    vid{i}.nFrames = vid{i}.obj.NumberOfFrames;
end


%% Determine relative timing of video from audio signal


aud = audio_sync(video_path, vid_path);

ttt=4;

% if isempty(dir([video_path filesep 'delayinfo.mat']))
%     
%     for i = 1:num_cam
%         % Get video path
%         a = dir([vid_path{i} filesep '*.MP4']);
%         
%         % Get audioinfo
%         aInfo = audioinfo([vid_path{i} filesep a(1).name]);
%         
%         % Extract audio
%         [tmp,aud{i}.Fs] = audioread(aInfo.Filename);
%         
%         % Choose channel with greater signal
%         if mean(abs(tmp(:,1))) > mean(abs(tmp(:,2)))
%             aud{i}.y = tmp(:,1);
%         else
%             aud{i}.y = tmp(:,2);
%         end
%         
%         % Time value
%         aud{i}.t = [0:(length(aud{i}.y)-1)]'./aud{i}.Fs;
%                
%         % Create audio player (for troubleshooting)
%         aud{i}.player = audioplayer(aud{i}.y,aud{i}.Fs);
%     end
%     
%     clear tmp
%     
%     % Check that sample rate is uniform
%     if (aud{1}.Fs~=aud{2}.Fs) || (aud{1}.Fs~=aud{3}.Fs)
%         error('Videos vary in their sample rate');
%     end
%     
%     % Index of values to include
%     i1 = aud{1}.t > skip_dur;
%     i2 = aud{2}.t > skip_dur;
%     i3 = aud{3}.t > skip_dur;
%     
%     % Find delays wrt camera A
%     aud{1}.delay = 0;
%     aud{2}.delay = finddelay(aud{1}.y(i1),aud{2}.y(i2))./aud{1}.Fs;
%     aud{3}.delay = finddelay(aud{1}.y(i1),aud{3}.y(i3))./aud{1}.Fs;
%     
%     % Plot data
%     if 1
% 
%         
%         % Plot
%         figure;
%         subplot(2,1,1)
%         h = plot(aud{1}.t(i1),aud{1}.y(i1),'-',...
%              aud{2}.t(i2),aud{2}.y(i2),'-',...
%              aud{3}.t(i3),aud{3}.y(i3),'-');
%         xlabel('Time (s)')
%         ylabel('Audio track (V)')
%         title('Before correction')
%         
%         xlim([skip_dur skip_dur+audio_dur])
%         
%         subplot(2,1,2)
%         plot(aud{1}.t(i1)-aud{1}.delay,aud{1}.y(i1),'-',...
%              aud{2}.t(i2)-aud{2}.delay,aud{2}.y(i2),'-',...
%              aud{3}.t(i3)-aud{3}.delay,aud{3}.y(i3),'-')
%         xlabel('Time (s)')
%         ylabel('Audio track (V)')
%         title('After correction')
%         
%         xlim([skip_dur skip_dur+audio_dur])
%         
%         %xlim([0 .5])
%     end
%     
%     % Save delay data
%     save([video_path filesep 'delayinfo.mat'],'aud')
%     
% else
%     disp('Loading audio delay data . . .')
%     load([video_path filesep 'delayinfo.mat'])
% end
 

%% Load video, correct for timing

% % Number of frames 
% num_delay = abs(delay) / (1/vid{1}.obj.Framerate);
% 
% % Check delay, zero out if failed
% if max(num_delay > max_frames)
%     warning(['Audio sync failed, delay up to ' num2str(num_delay) ' frames']) 
%     disp('Setting delays to zero')
%     delay = delay.*0;
% end

startFrame = 1 %200

%TODO: convert video images to remove distortion, apply mask, trim in time.

% for i = 1 %:num_cam
%     
%     % Stpe thru video frames
%     for j = 1:vid{i}.nFrames
%         vid_path = [vid{i}.obj.Path filesep vid{i}.obj.Name];
%         
%         % Read frame, correct for distortion
%         %im = give_frame(vid{i}.obj,j,roi{i},lensParams,cal{i}.cameraParams);
%         roi{i} = [];
%         %TODO: fix roi
%         %multiObjectTracking(vid_path, roi{i}, lensParams, cal{i}.cameraParams, startFrame)
%         
%         multiObjectTracking(vid_path, [], [], [], startFrame)
%         
%         ttt=3;
%     end
% end


%% Audio sync test

if test_sync
   
% Duration to analyze for the audio delay (s)
test_dur = 5;

% Limit for viewing the sync data (s)
xview = 2;

% Get paths for three video files
[vid_pathA,vid_pathB,vid_pathC] = get_videofiles(video_path);

% Extract audio
[yA,FsA] = audioread(vid_pathA);
[yB,FsB] = audioread(vid_pathB);
[yC,FsC] = audioread(vid_pathC);

idx = 1:min([size(yA,1) round(test_dur.*FsA)]);

yA = yA(idx,1);
yB = yB(idx,1);
yC = yC(idx,1);

tA = [0:(length(yA)-1)]./FsA;
tB = [0:(length(yB)-1)]./FsB;
tC = [0:(length(yB)-1)]./FsC;

delay1 = finddelay(yA,yB)./FsA;
delay2 = finddelay(yA,yC)./FsA;

figure;
subplot(2,2,1)
plot(tA,yA,'-',tB,yB,'-')
title('Before correction')
xlim([0 xview])

subplot(2,2,3)
plot(tA,yA,'-',tB-delay1,yB,'-')
title('After correction')
xlim([0 xview])

subplot(2,2,2)
plot(tA,yA,'-',tC,yC,'-')
title('Before correction')
xlim([0 xview])

subplot(2,2,4)
plot(tA,yA,'-',tC-delay2,yC,'-')
title('After correction')
xlim([0 xview])

end



function  im = give_roi(im,roi)
% Return image in roi, with adjusted contrast

% Define mask
BW = poly2mask(roi(:,1),roi(:,2),size(im,1),size(im,2)); 

% Update image, for verification
im(~BW) = 0;

% Adjust contrast
im = imadjust(im);


function im = give_frame(vid_obj,fr_num,roi,lensParams,cameraParams)
% Reads and corrects video frames.

% Read frame
im = read(vid_obj,fr_num);

% Convert to gray
im = rgb2gray(im);

% Undistort for lens
[im, newOrigin] = undistortImage(im, lensParams);

% Check for change in origin
if sum(newOrigin) ~= 0
    error('Origin displaced')
end

% Undistort again with 3D calibration correction
[im, newOrigin] = undistortImage(im, cameraParams);

% Check for change in origin
if sum(newOrigin) ~= 0
    error('Origin displaced')
end

% Return image within roi
im = give_roi(im,roi);

function varargout = get_videofiles(dir_path)

% Directory names with video files
dirname{1} = 'Mchero4_A';
dirname{2} = 'Mchero4_B';
dirname{3} = 'Mchero4_C';

j = 1;

for i = 1:length(dirname)
    
    % Current path
    cPath = [dir_path filesep dirname{i}];
    
    if ~isempty(dir(cPath))

        % Get video filenames
        a = dir([cPath filesep '*.MP4']);
        
        % Check for video
        if length(a)~=1
            error(['Expecting one video file in ' cal_pathA])
        end
        
        % Add to output
        varargout{j} = [cPath filesep a(1).name];
        j = j + 1;
    end
end

