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
if isempty(dir([data_path filesep 'video_data.mat']))
    error(['No data files in ' data_path]); 
else
    % Load 'v' structure
    load([data_path filesep 'video_data.mat']);
end

%TODO:Check for audio data

clear tmp


%% Launch analysis GUI

% Current cam 
cCam = 1;

% Path to video
im_path = [root.snip filesep date_dir filesep seq_dir filesep snip_dir ...
           filesep v{cCam}.cam_dir];

% Start GUI
videoAcqGUI(im_path, data_path, v, cCam);







    