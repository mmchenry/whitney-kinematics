function organize_data(video_path)
% Organizes the videos and photos for analysis


%% Give instructions

disp('INSTRUCTIONS -----------------------------------------------------')
disp(['Choose the dated directory that holds the McHenr4 directories for' ...
      ' three cameras.'])
disp(' ') 
disp(['Make sure to have all of your photos in a directory entitled '...
      ' "photos".'])
disp(' ')  
disp(['Each directory of videos and the photo directory must all have the ' ...
      'same number of files'])
disp(' ')
disp(' ')
  

%% Path definitions and error checking

% Get video path
if nargin < 1
    video_path = uigetdir(pwd,'Choose dated directory');
end

% Get root  and save paths
iSep      = video_path==filesep;
date_dir  = video_path((find(iSep,1,'last')+1):end);
root_path = video_path(1:(find(iSep,2,'last')-1));
save_path = [root_path filesep 'organized files'];
clear iSep

% Make save path
if isempty(dir([save_path filesep date_dir]))
    mkdir(save_path,date_dir)
end

% Check for video "A" directory
if isempty(dir([video_path filesep 'McHero4_A'])) 
    error('The dated directory must have a "McHero4_A" directory')
end

% Check for video "B" directory
if isempty(dir([video_path filesep 'McHero4_B'])) 
    error('The dated directory must have a "McHero4_B" directory')
end

% Check for video "C" directory
if isempty(dir([video_path filesep 'McHero4_C'])) 
    error('The dated directory must have a "McHero4_C" directory')
end

% Check for photo directory
if isempty(dir([video_path filesep 'photos'])) 
    error('The dated directory must have a "photos" directory')
end

% Inventory video files
aA = dir([video_path filesep 'McHero4_A' filesep '*.MP4']);
aB = dir([video_path filesep 'McHero4_B' filesep '*.MP4']);
aC = dir([video_path filesep 'McHero4_C' filesep '*.MP4']);

% Inventory photos
aD = dir([video_path filesep 'photos' filesep '*.JPG']);

% Check for equal number of video files
if (length(aA)~=length(aB)) || (length(aA)~=length(aC))
    error('You need to have an equal number of files in each video directory')
end

% Check for no video
if isempty(aA)
    error('No video files')
end

% Check number of photos
if length(aD) ~= length(aA)
    error('Number of photo files needs to match number of video files')
end


%% Copy & organize files

% Make directories, copy files
for i = 1:length(aA)
    % Current experiment directory name
    exp_num = ['00' num2str(i)];
    dir_name = ['expt' exp_num(end-2:end)];
    
    % Path for writing files
    write_path = [save_path filesep date_dir filesep dir_name];
    
    % Make "A" directory
    if isempty(dir([write_path filesep 'McHero4_A']))
        mkdir(write_path, 'McHero4_A');
    end
    
    % Make "B" directory
    if isempty(dir([write_path filesep 'McHero4_B']))
        mkdir(write_path, 'McHero4_B')
    end
    
    % Make "C" directory
    if isempty(dir([write_path filesep 'McHero4_C']))
        mkdir(write_path, 'McHero4_C')
    end
    
    % Copy over "A" video file
    if isempty(dir([write_path filesep  'McHero4_A' filesep aA(i).name]))
        copyfile([video_path filesep 'McHero4_A' filesep aA(i).name], ...
            [write_path filesep 'McHero4_A' filesep aA(i).name]);
    end
    
    % Copy over "B" video file
    if isempty(dir([write_path filesep 'McHero4_B' filesep aB(i).name]))
        copyfile([video_path filesep 'McHero4_B' filesep aB(i).name], ...
            [write_path filesep 'McHero4_B' filesep aB(i).name]);
    end
    
    % Copy over "C" video file
    if isempty(dir([write_path filesep 'McHero4_C' filesep aC(i).name]))
        copyfile([video_path filesep 'McHero4_C' filesep aC(i).name], ...
            [write_path filesep 'McHero4_C' filesep aC(i).name]);
    end
      
    % Copy over photo
    if isempty(dir([write_path filesep aD(i).name]))
        copyfile([video_path filesep 'photos' filesep aD(i).name], ...
            [write_path filesep aD(i).name]);
    end
    
    % Report status
    disp(['Done ' num2str(i) ' of ' num2str(length(aA)) ' experiments'])
end

% Alert when completed
beep;pause(0.5);beep;pause(0.5);beep



