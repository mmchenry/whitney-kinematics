function go_calibrator(threeD_path,sqsize)
% Conducts calibration for 3D kinematic experiments that use GoPro cameras
% Requires Matlab 2014b (or later), Computer Vision Toolbox and Image
% Processing Toolbox.
%
% threeD_path - path to directory containing 3 directories of video files


%% Code execution

% Determines the camera parameters (i.e. lens correction).
% Has been run for single HERO4 in 720 'Narrow' mode. Code can be used for
% other modes in the future.
lens_calibration = 0;

% Adopts an alternate approach to 3D calibaration (may be more scalable)
% Uses two or three HERO4s in 720 'narrow' mode
threeD_calibration = 1;


%% Parameter values

% Number of calibration images
numCalIm = 20;

% Size of checkerboard square (m)
%sqr_size = 8.261e-3;

% Default size of square in small checkerboard  for 3D calibration (m)
sqsize_3D = 8.145e-3;

% Difference in number of images between calibration runs  
num_increment = 10;

% Default size of square in large checkerboard for lens distortion calibration (m)
sqsize_lens = 21.7014e-3;

% Write results of calibration to disk
write_results = 1;

% Initial number of frames to be used for lens calibration
num_fr0 = 30;


%% Paths

% Matt's computer
if ~isempty(dir('/Users/mmchenry/Documents/Projects'))   
    % Directory root
    root = '/Users/mmchenry/Documents';
else
    error('This computer is not recognized')
end

% Video path
video_path = [root filesep 'Documents/GoPro Video'];

% Checkboard video file for single camera calibration (Lens correction, 720 Narrow)
check_path = [root filesep '/Projects/gopro kinematics/Lens correction, 720 Narrow/Mchero4_A'];

% Path of calibration movies for stero calibration
stereo_path = [root filesep '/Projects/gopro kinematics/stereo calibration'];

% Path of calibration movies for 3D calibration
%threeD_path = [root filesep '/Projects/gopro kinematics/threeD calibration'];
threeD_path = [root filesep '/Projects/gopro kinematics/3d pred prey trial/calibration2'];
    
% Path of files for testing the calibration
test_path = [root filesep 'Projects/gopro kinematics/calibration test'];

% Audio test path
audiotest_path = [root filesep 'Projects/gopro kinematics/audio sync test'];


%% Run Lens Calibration

if lens_calibration

% Make sure this is intended
button = questdlg(['The lens has been calibrated for 720 narrow -- ' ...
      'Are you sure you wish to proceed?'],'','Yes','No','Cancel','Yes');  
if ~strcmp(button,'Yes')
    return
end

% Number of outlier frames to removed after initial calibration
num_remove = 3;

% Minimum number of acceptable images
min_images = 10;

% Path for raw images used
raw_path = [check_path filesep 'frames'];

% Path for calibration results
results_path = [check_path filesep 'calibration data'];

% ROUND 1 -----------------------------------------------------------------

% Update status
tic; disp('Calibration: Round 1 . . .')

%  Create calibration images    
write_cal_images(num_fr0,check_path)
    
% Get listing of calibration images
a = dir([raw_path filesep 'frame*.tif']);

% Check for frame files
if isempty(a)
    error(['No calibration images in ' check_path])
end

% Store listing of files
files = cell(1, length(a));
for j = 1:length(a)
    files{j} = [check_path filesep 'frames' filesep a(j).name];
end

% Detect the checkerboard corners in the images.
[imagePoints, boardSize,imagesUsed] = detectCheckerboardPoints(files);

% Remove unused images
files = removed_unused(files,imagesUsed);

if sum(imagesUsed) < min_images
    error('Not enough usable images to complete the calibration')
end

% Generate the world coordinates of the checkerboard corners in the
% pattern-centric coordinate system, with the upper-left corner at (0,0).
worldPoints = generateCheckerboardPoints(boardSize, sqsize_lens);

% Calibrate the camera
try
    [cameraParams, imagesUsed, estimationErrors] = estimateCameraParameters(...
        imagePoints, worldPoints, ...
        'EstimateSkew', false, ...
        'EstimateTangentialDistortion', false, ...
        'NumRadialDistortionCoefficients', 3, ...
        'WorldUnits', 'm');
    
    % Remove unused images
    files = removed_unused(files,imagesUsed);
    
catch
    % Report failed result
    error('Calibration failed in round 1'); disp(' ')    
end

% Update status
disp(['               . . . done (' num2str(toc/60) ' min)']) 

% ROUND 2 -----------------------------------------------------------------

% Find mean errors in calibration
meanErrors = computeMeanError(cameraParams);

if (length(meanErrors)-num_remove) > min_images
    
    % Update status
    tic; disp('Calibration: Round 2 . . .')
    
    % CLear reused params
    clear imagesUsed estimationErrors worldPoints imagePoints
    
    % Find top-performing images
    [tmp,idx] = sort(meanErrors);
    idx = idx(1:(end-num_remove));
    
    % Store listing of files for top images
    files2 = cell(1, length(idx));
    for i = 1:length(idx)
        files2{i} = files{idx(i)};
    end
    
    % Detect the checkerboard corners in the images.
    [imagePoints, boardSize,imagesUsed] = detectCheckerboardPoints(files2);
    
    % Remove unused images
    files2 = removed_unused(files2,imagesUsed);
    
    % Generate the world coordinates of the checkerboard corners in the
    % pattern-centric coordinate system, with the upper-left corner at (0,0).
    worldPoints = generateCheckerboardPoints(boardSize, sqsize_lens);
    
    % Calibrate the camera again, this time with top images
    try
        [cameraParams, imagesUsed, estimationErrors] = estimateCameraParameters(...
            imagePoints, worldPoints, ...
            'EstimateSkew', false, ...
            'EstimateTangentialDistortion', false, ...
            'NumRadialDistortionCoefficients', 3, ...
            'WorldUnits', 'm');
        % Remove unused images
        files2 = removed_unused(files2,imagesUsed);
        
    catch
        % Report failed result
        error('Calibration failed in round 2'); disp(' ')    
    end
    
    % Update status
    disp(['               . . . done (' num2str(toc/60) ' min)']); disp(' '); 
else
    files2 = files;
end

% OUTPUT RESULTS ----------------------------------------------------------

if write_results
    
    % Delete image files within existing directory
    clear_dir(results_path,'images')
    
    % Write images used for calibration
    for i = 1:length(files2)
        
        % Overwrite the 
        originalImage = imread(files2{i});
        I = rgb2gray(originalImage);
        I = insertMarker(I, imagePoints(:,:,i), 'o', 'Color', 'green', 'Size', 5);
        I = insertMarker(I, imagePoints(1,:,i), 's', 'Color', 'yellow', 'Size', 8);
        
        % Frame string
        fr_str = ['0000' num2str(i)];

        % Write frame
        imwrite(I,[results_path filesep 'images' filesep 'image ' ...
            fr_str(end-3:end) '.jpeg'],'JPEG');
             
    end

    % Save data
    save([results_path filesep 'camera parameters.mat'],'cameraParams');
    save([results_path filesep 'image points.mat'],'imagePoints');
    save([results_path filesep 'board size.mat'],'boardSize');
    save([results_path filesep 'world points.mat'],'worldPoints');
    save([results_path filesep 'square size.mat'],'lens_sqsize');
    
    % Visualize pattern locations
    figure;
    subplot(1,2,1)
    showExtrinsics(cameraParams, 'CameraCentric');
    view([0 -45])
    
    % View reprojection errors
    
    subplot(1,2,2)
    showReprojectionErrors(cameraParams, 'BarGraph');
    title('Single camera calibration')
    
    % Capture graphs
    I = getframe(gcf);
    close
    
    % Write frame
    imwrite(I.cdata,[results_path filesep 'calibration graph.jpeg'],'JPEG');
end

end

 
%% ThreeD_calibration

% Directory for calibration data
if threeD_calibration %isempty(dir([threeD_path filesep 'threeD calibration.mat']))

% Select calibration directory
if nargin < 1
    disp('Note: the calibration directory should hold 3 folders starting with "McHero4"')
    threeD_path = uigetdir(video_path,'Select directory for running calibration');
end    
    
% Check number of cameras
num_cam = length(dir([threeD_path filesep 'McHero4*']));

if (num_cam < 2) || (num_cam > 3)
    error('There needs to be 2 or 3 cameras in your setup')
end

% Load camera parameters for lens distortion ('cameraParams')
load([check_path filesep 'calibration data' filesep 'camera parameters.mat'])

% Paths to 3D calibration videos
cal_path{1} = [threeD_path filesep 'Mchero4_A'];    
cal_path{2} = [threeD_path filesep 'Mchero4_B']; 
cal_path{3} = [threeD_path filesep 'Mchero4_C']; 

% Initialize for each cam
for i = 1:num_cam   
    
    % Get video path
    a = dir([cal_path{i} filesep '*.MP4']);
    
    % Check for video
    if length(a)~=1
        error(['Expecting one video file in ' cal_path{i}])
    end
    
    % Create objects for video files
    vid_obj{i} = VideoReader([cal_path{i} filesep a(1).name]);
    
    % Get frames of movie
    nFrames{i} = vid_obj{i}.NumberOfFrames;
    
    % Define vectors of frame numbers
    fr_num{i} = round(linspace(nFrames{i}.*.1,nFrames{i}.*.8,numCalIm));
    
end


% STEP 1: GET ROI ---------------------------------------------------------

if isempty(dir([threeD_path filesep 'roi data.mat']));
    
    figure; warning off; beep; beep
    
    for i = 1:num_cam
        
        % Current frame
        c_frame = round(length(fr_num{i})/2);
        
        % Read frame
        im = read(vid_obj{i},fr_num{i}(c_frame));
        
        % Convert to gray
        im = rgb2gray(im);
        
        % Undistorted image
        [im, newOrigin] = undistortImage(im, cameraParams);
        
        % Show
        imshow(im);
        title(['Select region of interest, cam ' num2str(i) ' of ' ...
               num2str(num_cam)])
        
        % Interactively find ellipse
        disp('Drag ellipse shape to choose elliptical ROI, press RETURN')
        h = imellipse; pause
        
        % Get roi coordinates, create binary mask
        roi{i} = getVertices(h);
        
        % Return image within roi
        im = give_roi(im,roi{i});
        
        % Desplay, for verification
        imshow(im)
        pause(1)
    end

    warning on
    
    % Save data
    save([threeD_path filesep 'roi data.mat'],'roi')
    
    % Clear variables
    clear newOrigin im c_frame h 
    
else
    % Load roi data ('roi')
    load([threeD_path filesep 'roi data.mat'])
end



% STEP 1: CREATE CALIBRATION IMAGES ---------------------------------------

disp(' Creating calibration images . . .')

% Loop thru for each cam
for i = 1:num_cam

    % Make directories
    [success,message,id] = mkdir(cal_path{i},'frames');
    
    % Loop thru calibration images
    for j = 1:numCalIm

        % Read frame
        im = read(vid_obj{i},fr_num{i}(j));
    
        % Convert to gray
        I = rgb2gray(im);
        
        % Undistorted image
        [unI, newOrigin{i}(j,:)] = undistortImage(I, cameraParams);
        
        % Return image within roi
        unI = give_roi(unI,roi{i});
        
        % Frame string
        fr_str = ['000000' num2str(fr_num{i}(j))];
        
        % Paths
        im_path = [cal_path{i} filesep 'frames' filesep 'frame ' ...
            fr_str(end-5:end) '.tif'];
        
        % Write image files
        imwrite(unI,im_path,'TIFF');
        
        % Save paths
        im_file{i}.path{j} = im_path;
    end
    
    % Update status
    disp(['          . . . done cam ' num2str(i) ' of ' num2str(num_cam)])
end


% STEP 3: RUN CALIBRATION -------------------------------------------------

% Update status
disp(' Running calibration . . .')

% Loop thru cameras
for i = 1:num_cam
    
    % Detect the checkerboard corners in the images.
    [imPts,brdSize,imUsed] = detectCheckerboardPoints(im_file{i}.path);
    
    % Remove unused images
    im_file{i}.path = removed_unused(im_file{i}.path,imUsed);
  
    % Create checkerboard points
    worldPoints = generateCheckerboardPoints(brdSize, sqsize);
    
    % Find camera parameters
    [cameraParam, imUsed, estErrors] = estimateCameraParameters(...
        imPts, worldPoints, ...
        'EstimateSkew', false, ...
        'EstimateTangentialDistortion', true, ...
        'NumRadialDistortionCoefficients', 3, ...
        'WorldUnits', 'm');

    % Remove unused images
    im_file{i}.path = removed_unused(im_file{i}.path,imUsed);
    
    % Translate detected points back into the original image coordinates
    refPts = bsxfun(@plus, imPts, mean(newOrigin{i},2));
    
    % Calcualte mean extrinsic propterties of cameras
    [R, t] = calc_extrinsics(imPts, worldPoints, imUsed, cameraParam);
    
    % Calculate camera matrices from mean extrinsics
    camMatrix = cameraMatrix(cameraParam, R, t);
    
    % Write results of indivudal cameras to disk
    write_cal_results(cal_path{i}, im_file{i}.path, imUsed, imPts, cameraParam);
    
    % Save calibration data for camera A
    cal{i}.cameraParams  = cameraParam;
    cal{i}.R             = R;
    cal{i}.t             = t;
    cal{i}.camMatrix     = camMatrix;
    cal{i}.imPts         = imPts;

    % Update status
    disp(['          . . . done cam ' num2str(i) ' of ' num2str(num_cam)])
end

% Save calibration data
save([threeD_path filesep 'threeD calibration.mat'],'cal');

end




function  im = give_roi(im,roi)
% Return image in roi, with adjusted contrast

% Define mask
BW = poly2mask(roi(:,1),roi(:,2),size(im,1),size(im,2)); 

% Update image, for verification
im(~BW) = 0;

% Adjust contrast
im = imadjust(im);


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


function write_cal_results(results_path, files, imUsed, imagePoints, cameraParams)
% Writes calibrtaion results to disk

% Clear or create directory
clear_dir(results_path,'Calibration images')

% Initiate index 
j = 1;

% Write images used for calibration
for i = 1:length(imUsed)
    if imUsed(i)        
        % Read image
        originalImage = imread(files{i});
        
        % Convert to gray, if necessary
        if size(originalImage,3)>1
            I = rgb2gray(originalImage);
        else
            I = originalImage;
        end
        
        % Add markers
        I = insertMarker(I, imagePoints(:,:,i), 'o', 'Color', 'green', 'Size', 5);
        I = insertMarker(I, imagePoints(1,:,i), 's', 'Color', 'yellow', 'Size', 8);
        
        % Frame string
        fr_str = ['0000' num2str(j)];
        
        % Write frame
        imwrite(I,[results_path filesep 'Calibration images' filesep 'image ' ...
            fr_str(end-3:end) '.jpeg'],'JPEG');
        
        % Add to index
        j = j + 1;
    end
end

% Visualize pattern locations
figure;
subplot(1,2,1)
showExtrinsics(cameraParams, 'CameraCentric');
view([0 -45])

% View reprojection errors
subplot(1,2,2)
showReprojectionErrors(cameraParams, 'BarGraph');
title('Single camera calibration')

% Capture graphs
I = getframe(gcf);
close

% Write frame
imwrite(I.cdata,[results_path filesep 'calibration graph.jpeg'],'JPEG');


function  [R, t] = calc_extrinsics(imPts, worldPoints, imUsed, cameraParam)
% Calculate camera extrinsics for each frame, find mean
j = 1;

for i = 1:sum(imUsed)
    if imUsed(i)
        [R, t] = extrinsics(imPts(:,:,i), worldPoints, cameraParam);
        Rs(:,:,j)  = R;
        ts(j,:)    = t;
        j = j + 1;
    end
end

% Assuming fixed camera, take mean position
R = mean(Rs, 3);
t = mean(ts,1);


function files = removed_unused(files,imagesUsed)
% Removes unused images from cell array

k = 1;
for j = 1:length(imagesUsed)
    if imagesUsed(j)
        tmp{k} = files{j};
        k = k + 1;
    end
end
files = tmp;


function meanErrorsPerImage = computeMeanError(this)
% Code from 'showReproductionErrors' to calculate errors in calibration
errors = hypot(this.ReprojectionErrors(:, 1, :), ...
                this.ReprojectionErrors(:, 2, :));
meanErrorsPerImage = squeeze(mean(errors, 1));


function clear_dir(im_path,dir_name)
% Either removes existing images (if present), or creates empty diretory

% Delete image files within existing directory
if ~isempty(dir([im_path filesep dir_name]))
    % Delete image files within
    delete([im_path filesep dir_name filesep '*.tif'])
    delete([im_path filesep dir_name filesep '*.jpeg'])
else
    % Make directory
    [success,message,id] = mkdir(im_path,dir_name);
end


function [x,y] = choosePoints(img,link)
%Used for finding coordinate points on a static image 'img'.

warning off

imshow(img);
hold on;
set(gcf,'DoubleBuffer','on');
disp(' '); disp(' ');
disp('Left mouse button picks points.');disp(' ');
disp('Right mouse button removes last point.');disp(' ');
disp('Press return to stop.')
n = 0;
but = 1;
while 1 == 1
    [xi,yi,but] = ginput(1);
    if isempty(but)
        break
    elseif but==1
        n = n+1;
        x(n) = xi;
        y(n) = yi;
        if link
            plot(x,y,'ro-')
        else
            plot(x,y,'ro')
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
        hold on
        if link
            plot(x,y,'ro-')
        else
            plot(x,y,'ro')
        end
    end
end
hold off

warning on


function remove_fish(cam_path,check_path)
% Creates images with fisheye effect removed

% Load camera parameters ('cameraParams')
load([check_path filesep 'camera parameters.mat'])

% image file list
a = dir([cam_path filesep 'frames' filesep '*.tif']);

% Make directory
[success,message,id] = mkdir(cam_path,'frames, undistorted');

% Only execute if directory not present
if isempty(message)
    % Step through each image
    for i = 1:length(a)
        
        % Read file
        im = imread([cam_path filesep 'frames' filesep a(i).name]);
        
        % Convert to gray
        I = rgb2gray(im);
        
        % Undistorted image
        unI = undistortImage(I, cameraParams);
        
        % Write image file
        imwrite(unI,[cam_path filesep 'frames, undistorted' ...
                     filesep a(i).name]);
    end
end


function ims = write_cal_images(numCalIm,check_path1,check_path2)
% Create video stills, to be analyzed for calibrations
    
% Get filename
a1 = dir([check_path1 filesep '*.MP4']);

% Check for video
if length(a1)~=1
    error(['Expecting one video file in ' check_path1])
end

% If 2 paths given
if nargin > 2
    % Get filename
    a2 = dir([check_path2 filesep '*.MP4']);
    
    % Check for video
    if length(a2)~=1
        error(['Expecting one video file in ' check_path2])
    end
    
    % Set number of cameras
    num_cam = 2;
    
else
    
    % Set number of cameras
    num_cam = 1;
end

% Set first path, filename
check_path = check_path1;
check_name = a1(1).name;

% Loop thru cameras
for i = 1:num_cam
        
    % Delete image files within existing directory
    clear_dir(check_path,'frames')
   
    % Define video object
    vid_obj = VideoReader([check_path filesep check_name]);

    % Get frames of movie
    nFrames = vid_obj.NumberOfFrames;

    % Define vector of frame numbers
    fr_num = round(linspace(nFrames.*.1,nFrames.*.8,numCalIm));

    % Capture & save video frames
    for j = 1:numCalIm

        % Frame string
        fr_str = ['000000' num2str(fr_num(j))];

        % Read frame
        im = read(vid_obj,fr_num(j));

        % Write frame
        imwrite(im,[check_path filesep 'frames' filesep 'frame ' ...
            fr_str(end-5:end) '.tif'],'TIFF');

        clear im fr_str
    end

    
    % Set up for next loop, if 2 cameras
    if nargin > 2
        check_path = check_path2;
        check_name = a2(1).name;
    end
end


function pathh = exp_path(pred_sp,prey_sp,age,expt_type)
% Returns diretcory structure for certain experiments

pathh = [pred_sp ' pred' filesep ...
         prey_sp ' prey' filesep ...
         num2str(age) ' dpf' filesep ...
         expt_type];
  

function copy_file(file_source,file_dest)
% Copies files, reports results, deletes source 
[success,message,messageid] = copyfile(file_source,file_dest);
    
% Report results, check for failure
if success==1
    disp(' ');
    disp('Copy file completed:')
    disp(['From: ' file_source])
    disp(['To: ' file_dest])
else
    disp(['Failed file copy from ' file_source ' to ' file_dest]);
    disp(' ')
    disp(' ')
    error(message)
end


function cam_path = cam_check(cam1_path,cam2_path)
% Define paths, based on presence of cameras

% No cameras
if isempty(dir(cam1_path)) && isempty(dir(cam2_path))
    error('Neither camera is connected to the mac mini')
    %warning('Neither camera is connected to the mac mini')
    
% Both cameras
elseif ~isempty(dir(cam1_path)) && ~isempty(dir(cam2_path))
    buttonName = questdlg('Which camera do you want to work with?',...
            'Which cam?','McHero_1',...
            'McHero_2','Cancel','McHero_1');
        
    % Analyze results
    if strcmp(buttonName,'McHero_1')
        cam_path = cam1_path;
        
    elseif strcmp(buttonName,'McHero_2')
        cam_path = cam2_path;
    else
        return
    end
    
% Just cam1    
elseif ~isempty(dir(cam1_path))
    disp(' ');disp('Reading from McHero1 . . .');
    cam_path = cam1_path;
    
% Just cam2 
elseif ~isempty(dir(cam2_path))
    disp(' ');disp('Reading from McHero2 . . .')
    cam_path = cam2_path;
end