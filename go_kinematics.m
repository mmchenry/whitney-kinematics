function go_kinematics(video_path)
% Conducts calibration for 3D kinematic experiments that use GoPro cameras
% Requires Matlab 2014b (or later), Computer Vision Toolbox and Image
% Processing Toolbox.


%% Code execution

% Copy over sets of video files into directories
organize_files = 1;

view_video

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
    root = '/Users/mmchenry/Dropbox/Projects/JimmyJacob'; 
else
    error('This computer is not recognized')
end

% Checkboard video file for single camera calibration (Lens correction, 720 Narrow)
check_path720 = [root filesep '/Projects/gopro kinematics/Lens correction, 720 Narrow/Mchero4_A'];

% Checkboard video file for single camera calibration (Lens correction, 1080 Narrow)
check_path1080 = [root filesep '/Projects/gopro kinematics/Lens correction, 1080 Narrow/Mchero4_A'];

% Path to video recordings
video_root = '/Volumes/WD MACPART/Video/Liao pred-prey/organized files';

% Check for external drive
if isempty(dir(video_root))
    error('If does not look like your external drive is plugged in');
end

% Get sequence path
if nargin < 1
    video_path = uigetdir(video_root,'Choose sequence directory');
end

% Path to calibration data
cal_path = [root filesep 'Projects/gopro kinematics/3d pred prey trial/calibration2'];

%
data_path = [root filesep 'rawdata'];


%% Organize files
if organize_files
   
    % Check for video directories 
    if isempty([video_path filesep 'expt_raw']) || ...
       isempty([video_path filesep 'expt_raw' filesep 'McHero4*'])     
        error(['You need to store video directories in a directory called "expt_raw"'])      
    end
    
    % Inventory video files
    aA = dir([video_path filesep 'expt_raw' filesep 'McHero4_A' filesep '*.MP4']);
    aB = dir([video_path filesep 'expt_raw' filesep 'McHero4_B' filesep '*.MP4']);
    aC = dir([video_path filesep 'expt_raw' filesep 'McHero4_C' filesep '*.MP4']);
    
    % Check for equal number of files
    if (length(aA)~=length(aB)) || (length(aA)~=length(aC))
        error('You need to have an equal number of files in each video directory')
    end
    
    if isempty(aA)
        error('No video files')
    end
    
    % Make directories, copy files
    
    for i = 1:length(aA)
        % Current experiment directory name
        exp_num = ['00' num2str(i)];
        dir_name = ['expt' exp_num(end-2:end)];
        
        % Make directories
        if isempty(dir([video_path filesep dir_name filesep 'McHero4_A']))
            mkdir([video_path filesep dir_name], 'McHero4_A');
        end
        
        if isempty(dir([video_path filesep dir_name filesep 'McHero4_B']))
            mkdir([video_path filesep dir_name], 'McHero4_B')
        end
        
        if isempty(dir([video_path filesep dir_name filesep 'McHero4_C']))
            mkdir([video_path filesep dir_name], 'McHero4_C')
        end
        
        % Copy over video files
        if isempty(dir([video_path filesep dir_name filesep 'McHero4_A' filesep aA(i).name]))
            copyfile([video_path filesep 'expt_raw' filesep 'McHero4_A' filesep aA(i).name], ...
                     [video_path filesep dir_name filesep 'McHero4_A' filesep aA(i).name]);
        end
            
        if isempty(dir([video_path filesep dir_name filesep 'McHero4_B' filesep aB(i).name]))
            copyfile([video_path filesep 'expt_raw' filesep 'McHero4_B' filesep aB(i).name], ...
                     [video_path filesep dir_name filesep 'McHero4_B' filesep aB(i).name]);
        end
            
        if isempty(dir([video_path filesep dir_name filesep 'McHero4_C' filesep aC(i).name]))
            copyfile([video_path filesep 'expt_raw' filesep 'McHero4_C' filesep aC(i).name], ...
                     [video_path filesep dir_name filesep 'McHero4_C' filesep aC(i).name]);
        end
        
        % Report status
        disp(['Done ' num2str(i) ' of ' num2str(length(aA))])
    end
end




%% Load data

% Load camera parameters for lens distortion ('cameraParams')
load([check_path filesep 'calibration data' filesep 'camera parameters.mat'])

lensParams = cameraParams;
clear cameraParams

% Load calibration ('cal')
%load([cal_path filesep 'threeD calibration.mat']);

% Load roi data ('roi')
%load([cal_path filesep 'roi data.mat'])


%% Save modified movie


if 0
    
% Check number of cameras
num_cam = length(dir([video_path filesep 'McHero4*']));

if (num_cam ~= 3) || (length(cal)~=num_cam)
    error('There needs to be 3 cameras in your setup')
end

% Paths to 3D calibration videos
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

