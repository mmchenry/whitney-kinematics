function go_acquire(snip_path)
% Tracks the position of predator and prey fish from snippets of video.
% Requires that copysnippets.m and audio_sync.m be run first.



%% Paths

% Get root paths
root = give_paths;

% Get experiment path
if nargin < 1
    % Get raw path
    snip_path = uigetdir(root.snip,'Choose "SnipXX" directory');
    
    % Parse response
    if snip_path==0
        return
    end
end

% Define date and sequence directories
iSep        = snip_path==filesep;
snip_dir    = snip_path((find(iSep,1,'last')+1):end);
seq_dir     = snip_path((find(iSep,2,'last')+1):(find(iSep,1,'last')-1));
date_dir    = snip_path((find(iSep,3,'last')+1):(find(iSep,2,'last')-1));

% Check directory name
if ~strcmp(snip_dir(1:4),'Snip')
    error('Chosen directory needs to start with "Snip"')
end

% Check root path
tmp = snip_path(1:(find(iSep,3,'last')-1));
if ~strcmp(tmp,root.snip)
    error('Root path for snips not what was expected');
end

% Look for data
data_path = [root.proj filesep 'rawdata' filesep date_dir filesep ...
             seq_dir];       

% Check for data data
if isempty(dir([data_path filesep 'video_data.mp4']))
    error(['No data files in ' data_path]); 
else
    % Load 'v' structure
    load([data_path filesep 'video_data.mp4']);
end

%TODO:Check for audio data


clear tmp


%% Display video

% Current frame in snippet
cFrame = 1;

% Current cam 
cCam = 1;








% % Create System objects for foreground detection and blob analysis
% 
% % The foreground detector is used to segment moving objects from
% % the background. It outputs a binary mask, where the pixel value
% % of 1 corresponds to the foreground and the value of 0 corresponds
% % to the background.
% 
% obj.detector = vision.ForegroundDetector('NumGaussians', 3, ...
%     'NumTrainingFrames', 40, 'MinimumBackgroundRatio', 0.7);
% 
% % Connected groups of foreground pixels are likely to correspond to moving
% % objects.  The blob analysis System object is used to find such groups
% % (called 'blobs' or 'connected components'), and compute their
% % characteristics, such as area, centroid, and the bounding box.
% 
% obj.blobAnalyser = vision.BlobAnalysis('BoundingBoxOutputPort', true, ...
%     'AreaOutputPort', true, 'CentroidOutputPort', true, ...
%     'MinimumBlobArea', 400);
% 

for i = 1:length(v)
    vid_file{i} = [root.snip filesep v{i}.date_dir filesep ...
                v{i}.seq_dir filesep v{i}.snip_name filesep ...
                v{i}.cam_dir '.mp4'];
     readObj{i} = VideoReader(vid_file{i});   
end

VideoInCustomGUI(vid_file{1})

return

multiObjectTracking(vid_file{1},cFrame)

figure('DoubleBuffer','on')

while true
    
    tic
    
    % Read frame
    im = read(readObj{cCam},cFrame);
    
    warning off
    imshow(im)
    title([v{cCam} ': Frame ' num2str(cFrame)])
    warning on
    
    pause(0.1)
    
    cFrame = min([length(v{cCam}.frames) (cFrame + 1)]);
    
    toc
end


    function tracks = initializeTracks()
        % create an empty array of tracks
        tracks = struct(...
            'id', {}, ...
            'bbox', {}, ...
            'kalmanFilter', {}, ...
            'age', {}, ...
            'totalVisibleCount', {}, ...
            'consecutiveInvisibleCount', {});
    end




end




    