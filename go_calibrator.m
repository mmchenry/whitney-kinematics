function go_calibrator
% Conducts calibrations for 3D kinematic experiments that use GoPro cameras
% Requires Matlab 2014b (or later) and Computer Vision Toolbox


%% Code execution

% Determines the camera parameters (i.e. lens correction) for single HERO4 
% in 720 'narrow' mode
lens_calibration = 1;

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

% Number of calibration images
numCalIm = 20;

% Size of checkerboard square (m)
%sqr_size = 8.261e-3;

% Size of square in small checkerboard  for stero calibration (m)
stereo_sqsize = 8.145e-3;

num_increment = 10;

% Size of square in large checkerboard for lens distortion calibration (m)
lens_sqsize = 21.7014e-3;

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

% Checkboard video file for single camera calibration (lens correction)
check_path = [root filesep '/Projects/gopro kinematics/lens correction/Mchero4_A'];
%check_name = 'checkerboard video1.MP4';

% Path of calibration movies for stero calibration
stereo_path = [root filesep '/Projects/gopro kinematics/stereo calibration'];

% Path of calibration movies for 3D calibration
threeD_path = [root filesep '/Projects/gopro kinematics/threeD calibration'];

% Path of files for testing the calibration
test_path = [root filesep 'Projects/gopro kinematics/calibration test'];

% Audio test path
audiotest_path = [root filesep 'Projects/gopro kinematics/audio sync test'];


%% Run Lens Calibration

if lens_calibration
    
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
worldPoints = generateCheckerboardPoints(boardSize, lens_sqsize);

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
    worldPoints = generateCheckerboardPoints(boardSize, lens_sqsize);
    
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


%% Stereo Calibration

if stereo_calibration

% Paths for calibration images
im_pathA = [stereo_path filesep 'Mchero4_A' filesep 'frames, undistorted'];    
im_pathB = [stereo_path filesep 'Mchero4_B' filesep 'frames, undistorted'];  

%  Create calibration images    
write_cal_images(numCalIm,[stereo_path filesep 'Mchero4_A'],...
                          [stereo_path filesep 'Mchero4_B']);                                                  
    
% Remove fisheye from calibration images
remove_fish([stereo_path filesep 'Mchero4_A'],check_path);

% Remove fisheye from calibration images
remove_fish([stereo_path filesep 'Mchero4_B'],check_path);

% Get listings of undistorted calibration images
aA = dir([im_pathA filesep 'frame*.tif']);                      
aB = dir([im_pathB filesep 'frame*.tif']); 

% Check for same number of images
if length(aA)~=length(aB)
    error('Need same number of calibration images from the two cameras')
end

% Gather listing of calibration images
for i = 1:length(aA)   
   % A cam
   Afiles{i} = [im_pathA filesep aA(i).name];  
   % B cam
   Bfiles{i} = [im_pathB filesep aB(i).name];  
end

% Detect the checkerboard corners in the images.
[imPoints,boardSize,imUsed] = detectCheckerboardPoints(Afiles,Bfiles);

% Visualize this step
figure
subplot(1,2,1)
warning off
imshow(imread(Afiles{1}))
warning on
if ~isempty(imPoints)
    hold on
    plot(imPoints(:, 1, 1, 1), imPoints(:, 2, 1, 1), '+g',...
        imPoints(1, 1, 1, 1), imPoints(1, 2, 1, 1), 'sy');
end
title('Left cam')

subplot(1,2,2)
warning off
imshow(imread(Bfiles{1}))
warning on
if ~isempty(imPoints)
    hold on
    plot(imPoints(:, 1, 1, 2), imPoints(:, 2, 1, 2), '+g',...
        imPoints(1, 1, 1, 2), imPoints(1, 2, 1, 2), 'sy');
end
title('Right cam')


if isempty(imPoints)
    error('Failed to detect checkboards');
end

% Report on images
disp(['   ' num2str(sum(imUsed)) ' of ' num2str(length(imUsed)) ...
    ' images were usable'])

% Generate the world coordinates of the checkerboard corners in the
% pattern-centric coordinate system, with the upper-left corner at (0,0).
worldPoints = generateCheckerboardPoints(boardSize, stereo_sqsize);

% Calibrate the camera
try
    stereoParams = estimateCameraParameters(imPoints,worldPoints, ...
        'EstimateSkew', true, 'EstimateTangentialDistortion', true, ...
        'NumRadialDistortionCoefficients', 3, 'WorldUnits', 'm');
    
    
    trying = 0;
   
catch
    % Report results
    beep;beep;
    disp('Calibration failed'); disp(' ')
    
    numCalIm = numCalIm + num_increment;
    
    if numCalIm > 50
        disp(' ')
        disp('All attempts failed');
        disp(' ')
        return
    else
        disp(['Trying again with ' num2str(numCalIm) ' frames . . .'])
    end
    stereoParams = [];
    
end

% Show results
figure;
showReprojectionErrors(stereoParams);

% Report results
disp('Calibration completed !'); disp(' ')

% Save data
cal.Bfiles = Bfiles;
cal.Afiles = Afiles;
cal.sqSize = stereo_sqsize;
cal.stereoParam = stereoParams;
cal.imPoints = imPoints;
cal.boardSize = boardSize;
cal.imUsed = imUsed;
cal.worldPoints = worldPoints;

save([stereo_path filesep 'stereo calibration.mat'],'cal');

end
   
 
%% threeD_calibration

% Directory for calibration data
if threeD_calibration % ~isempty(dir([threeD_path filesep 'threeD calibration.mat']))

% Load camera parameters for lens distortion ('cameraParams')
load([check_path filesep 'calibration data' filesep 'camera parameters.mat'])

% Paths to 3D calibration videos
cal_pathA = [threeD_path filesep 'Mchero4_A'];    
cal_pathB = [threeD_path filesep 'Mchero4_B']; 

% Get filename
aA = dir([cal_pathA filesep '*.MP4']);
aB = dir([cal_pathB filesep '*.MP4']);

% Check for video
if length(aA)~=1
    error(['Expecting one video file in ' cal_pathA])
elseif length(aB)~=1
    error(['Expecting one video file in ' cal_pathB])
end

% Create objects for video files
vid_objA = VideoReader([cal_pathA filesep aA(1).name]);
vid_objB = VideoReader([cal_pathB filesep aB(1).name]);

% Get frames of movie
nFramesA = vid_objA.NumberOfFrames;
nFramesB = vid_objB.NumberOfFrames;

% Define vectors of frame numbers
fr_numA = round(linspace(nFramesA.*.1,nFramesA.*.8,numCalIm));
fr_numB = round(linspace(nFramesB.*.1,nFramesB.*.8,numCalIm));

% Make directories
[success,message,id] = mkdir(cal_pathA,'frames');
[success,message,id] = mkdir(cal_pathB,'frames');

% Loop thru calibration images
for i = 1:numCalIm

    % Read frames
    imA = read(vid_objA,fr_numA(i));
    imB = read(vid_objB,fr_numB(i));

    % Convert to gray
    IA = rgb2gray(imA);
    IB = rgb2gray(imB);

    % Undistorted image
    [unA, newOriginA] = undistortImage(IA, cameraParams);
    [unB, newOriginB] = undistortImage(IB, cameraParams);

    % Frame string
    fr_str = ['000000' num2str(fr_numA(i))];

    % Paths
    pathA = [cal_pathA filesep 'frames' filesep 'frame ' ...
                 fr_str(end-5:end) '.tif'];
    pathB = [cal_pathB filesep 'frames' filesep 'frame ' ...
                 fr_str(end-5:end) '.tif'];

    % Write image files
    imwrite(unA,pathA,'TIFF');
    imwrite(unB,pathB,'TIFF');  

    % Save paths
    Afiles{i} = pathA;
    Bfiles{i} = pathB;
end

% Update status
disp('Done step 1')

% Detect the checkerboard corners in the images.
[imPtsA,brdSizeA,imUsedA] = detectCheckerboardPoints(Afiles);
[imPtsB,brdSizeB,imUsedB] = detectCheckerboardPoints(Bfiles);

% Remove unused images
Afiles = removed_unused(Afiles,imUsedA);
Bfiles = removed_unused(Bfiles,imUsedB);

% Create checkerboard points
worldPoints = generateCheckerboardPoints(brdSizeA, stereo_sqsize);

% Find camera parameters 
[cameraParamA, imUsedA, estErrorsA] = estimateCameraParameters(...
                            imPtsA, worldPoints, ...
                            'EstimateSkew', false, ...
                            'EstimateTangentialDistortion', true, ...
                            'NumRadialDistortionCoefficients', 3, ...
                            'WorldUnits', 'm');
[cameraParamB, imUsedB, estErrorsB] = estimateCameraParameters(...
                            imPtsB, worldPoints, ...
                            'EstimateSkew', false, ...
                            'EstimateTangentialDistortion', true, ...
                            'NumRadialDistortionCoefficients', 3, ...
                            'WorldUnits', 'm');

% Update status
disp('Done step 2')

% Remove unused images
Afiles = removed_unused(Afiles,imUsedA);
Bfiles = removed_unused(Bfiles,imUsedB);

% Translate detected points back into the original image coordinates
refPtsA = bsxfun(@plus, imPtsA, newOriginA);
refPtsB = bsxfun(@plus, imPtsB, newOriginB);

% Calcualte mean extrinsic propterties of cameras
[RA, tA] = calc_extrinsics(imPtsA, worldPoints, imUsedA, cameraParamA);
[RB, tB] = calc_extrinsics(imPtsB, worldPoints, imUsedB, cameraParamB);

% Calculate camera matrices from mean extrinsics
camMatrixA = cameraMatrix(cameraParamA, RA, tA);
camMatrixB = cameraMatrix(cameraParamB, RB, tB);

% Write results of indivudal cameras to disk
write_cal_results(cal_pathA, Afiles, imUsedA, imPtsA, cameraParamA);
write_cal_results(cal_pathB, Bfiles, imUsedB, imPtsB, cameraParamB);

% Save calibration data for camera A
cal.A.cameraParams  = cameraParamA;
cal.A.R             = RA;
cal.A.t             = tA;
cal.A.camMatrix     = camMatrixA;
cal.A.imPts         = imPtsA;

% Save calibration data for camera B
cal.B.cameraParams  = cameraParamB;
cal.B.R             = RB;
cal.B.t             = tB;
cal.B.camMatrix     = camMatrixB;
cal.B.imPts          = imPtsB;

% Save calibration data 
save([threeD_path filesep 'threeD calibration.mat'],'cal');  

% Update status
disp('Finished')
end


%% Audio sync test

if test_sync
    
% Get paths for two video files
[vid_pathA,vid_pathB] = get_videofiles(audiotest_path);

% Extract audio
[yA,FsA] = audioread(vid_pathA);
[yB,FsB] = audioread(vid_pathB);

yA = yA(:,1);
yB = yB(:,1);

tA = [0:(length(yA)-1)]./FsA;
tB = [0:(length(yB)-1)]./FsB;

delay = finddelay(yA,yB)./FsA;

figure;
subplot(2,1,1)
plot(tA,yA,'-',tB,yB,'-')
title('Before correction')

subplot(2,1,2)
plot(tA,yA,'-',tB-delay,yB,'-')
title('After correction')

end


%% Play with calibration


%TODO: 
% 1. Fuse the two calibrations to generate common coordinate system
% This is a start: Use the following code to display the checkboard used
% in the calibration in 3D space.  Try to figure out how it defines the origin
% Code:  [worldPoints,reprojErrors] = triangulate(imPtsA,imPtsB,camMatrixA,camMatrixB);

% 2. Define a voxal spatial domain -- define coordinates 



return 


if threeD_play

% Load 'cal' structure for 3D calibration
load([threeD_path filesep 'threeD calibration.mat'])
 
% Frame number to analyze
fr_num = 1;

% Paths videos
%pathA = [test_path filesep 'Mchero4_A'];    
%pathB = [test_path filesep 'Mchero4_B']; 
% Paths to 3D calibration videos
pathA = [threeD_path filesep 'Mchero4_A'];    
pathB = [threeD_path filesep 'Mchero4_B']; 


% Get filenames
aA = dir([pathA filesep '*.MP4']);
aB = dir([pathB filesep '*.MP4']);

% Check for single video
if length(aA)~=1
    error(['Expecting one video file in ' pathA])
elseif length(aB)~=1
    error(['Expecting one video file in ' pathB])
end

% Create objects for video files
vid_objA = VideoReader([pathA filesep aA(1).name]);
vid_objB = VideoReader([pathB filesep aB(1).name]);

% Get frames of movie
nFramesA = vid_objA.NumberOfFrames;
nFramesB = vid_objB.NumberOfFrames;

% Read frame
frA = read(vid_objA,fr_num);
frB = read(vid_objB,fr_num);

% Convert to gray
IA = rgb2gray(frA);
IB = rgb2gray(frB);

% Undistorted image
[unA, newOriginA] = undistortImage(IA, cal.A.cameraParams);
[unB, newOriginB] = undistortImage(IB, cal.B.cameraParams);

% Detect the checkerboard corners in the images.
[imPtsA,brdSizeA,imUsedA] = detectCheckerboardPoints(unA);
[imPtsB,brdSizeB,imUsedB] = detectCheckerboardPoints(unB);

% Add markers in A
imA = insertMarker(unA, imPtsA, 'o', 'Color', 'green', 'Size', 5);
imA = insertMarker(imA, imPtsA(1,:), 's', 'Color', 'yellow', 'Size', 8);

% Add markers in B
imB = insertMarker(unB, imPtsB, 'o', 'Color', 'green', 'Size', 5);
imB = insertMarker(imB, imPtsB(1,:), 's', 'Color', 'yellow', 'Size', 8);

% Detect feature points
%imPtsA = detectSURFFeatures(unA, 'MetricThreshold', 600);
%imPtsB = detectSURFFeatures(unB, 'MetricThreshold', 600);

% Extract feature descriptors
%featuresA = extractFeatures(unA,imPtsA);
%featuresB = extractFeatures(unB,imPtsB);

%indexPairs = matchFeatures(featuresA, featuresB, 'MaxRatio', 0.4);
%matchedPtsA = imPtsA(indexPairs(:, 1));
%matchedPtsB = imPtsB(indexPairs(:, 2));


% Visualize several extracted SURF features from the Globe01 image
figure;
subplot(2,2,1)
imshow(imA);
hold on
%title('1500 Strongest Feature Points from Globe01');
%plot(selectStrongest(imPtsA, 50));



subplot(2,2,2)
imshow(imB);
hold on
%plot(selectStrongest(imPtsB, 50));

subplot(2,2,3:4)
showMatchedFeatures(unA, unB, imPtsA, imPtsB);
title('Original Matched Features from Globe01 and Globe02');








% Visualize correspondences
figure;
showMatchedFeatures(frA, frB, matchedPoints1, matchedPoints2);
title('Original Matched Features from Globe01 and Globe02');

% Transform matched points to the original image's coordinates
matchedPoints1.Location = bsxfun(@plus, matchedPoints1.Location, newOriginA);
matchedPoints2.Location = bsxfun(@plus, matchedPoints2.Location, newOriginB);






end


return


%% Test the calibration

if test_calibration      
    
% Load cameraParams
load([check_path filesep 'camera parameters.mat']);

% Load stereo parameters ('cal')
load([stereo_path filesep 'stereo calibration.mat']);

% load worldPoints
load([check_path filesep 'world points.mat']);

% Paths for calibration images
aA = dir([test_path filesep 'Mchero4_A' filesep '*.MP4']);    
aB = dir([test_path filesep 'Mchero4_B' filesep '*.MP4']);  

% Check dir
if length(aA)~=1 || length(aB)~=1
    error('Expecting one video file')
end

% Define video object
vid_objA = VideoReader([test_path filesep 'Mchero4_A' filesep aA(1).name]);
vid_objB = VideoReader([test_path filesep 'Mchero4_B' filesep aB(1).name]);

% Grab last frames
frA = read(vid_objA,vid_objA.NumberOfFrames);
frB = read(vid_objB,vid_objB.NumberOfFrames);

% Undistort images (remove fisheye)
[frA,newOriginA] = undistortImage(frA,cameraParams);
[frB,newOriginB] = undistortImage(frB,cameraParams);

figure
subplot(1,2,1)
imshow(frA)
hold on

subplot(1,2,2)
imshow(frB)
hold on





end



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