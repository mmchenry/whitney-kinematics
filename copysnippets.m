function copysnippets(action,raw_path,cams,time_start,time_end)
% Transfers snippets of video from organized raw files for analysis



%% Code execution

if strcmp(action,'cue job')

    % Creates a batch of sequences for creating snippets
    set_batch = 1;    
    % Runs the batch
    run_batch = 0;
    
elseif strcmp(action,'run batch')
    
    % Creates a batch of sequences for creating snippets
    set_batch = 0;   
    % Runs the batch
    run_batch = 1;
    
else
    error('action not recognized');
end

% Save video as image sequence
save_as_seq = 1;


%% Set up batch (set_batch)

% Get root paths
root = give_paths;

if set_batch
    
    % Get experiment path
    if nargin < 1
        % Get raw path
        %raw_path = root.rawvid;
        raw_path = uigetdir(root.rawvid,'Choose "exptXXX" directory');
        
        % Parse response
        if raw_path==0
            return
        end
    end
    
    % Check experiment path
    if ~strcmp(raw_path((find(raw_path==filesep,1,'last'))+1:end-4),'exp')
        error('Chosen directory needs to start with "exp"');
    end
    
    % Prompt for data
    if nargin < 4
        % Prompt for info about the sequence
        answer = inputdlg({'Cams to include(e.g."BA"), listing primary first', ...
            'Start time (mm:ss):', ...
            'End time (mm:ss)'},...
            '', 1, {'C','00:14','00:15'});
        
        % Parse responses
        for i = 1:length(answer{1})
            cams(i) = answer{1}(i);
        end
        time_start  = answer{2};
        time_end    = answer{3};
    end

    % Get colon separator
    idx1 = find(time_start == ':');
    idx2 = find(time_end == ':');
    
    % Check format
    if (length(idx1)~=1) || (length(idx2)~=1)
        error('Time needs to include a single ":"');
    end    

    % Paths to raw videos & calibration data for snippet
    for i = 1:length(cams)
        
        % Convert time to seconds
        v{i}.time_start = 60 * str2num(time_start(1:(idx1-1))) + ...
            str2num(time_start((idx1+1):end));
        
        v{i}.time_end   = 60 * str2num(time_end(1:(idx2-1))) + ...
            str2num(time_end((idx2+1):end));
        
        % Define date and sequence directories
        iSep           = raw_path==filesep;
        v{i}.date_dir  = raw_path((find(iSep,2,'last')+1):(find(iSep,1,'last')-1));
        v{i}.seq_dir   = raw_path((find(iSep,1,'last')+1):end);
        clear iSep
        
        if cams(i)=='A'
            v{i}.cam_dir = 'McHero4_A';
            v{i}.cal_path = [root.rawvid filesep 'calibration' filesep 'calibrationA'];
            
        elseif cams(i)=='B'
            v{i}.cam_dir = 'McHero4_B';
            v{i}.cal_path = [root.rawvid filesep 'calibration' filesep 'calibrationB'];
            
        elseif cams(i)=='C'
            v{i}.cam_dir = 'McHero4_C';
            v{i}.cal_path = [root.rawvid filesep 'calibration' filesep 'calibrationC'];
            
        else
            error('Camera not recognized -- enter like this "ABC", no spaces');
        end
    end
    
    clear time_start time_end
    
    % Define paths for snippets and corresponding data
    snip_path = [root.snip filesep v{i}.date_dir filesep v{i}.seq_dir];
    data_path = [root.proj filesep 'rawdata' filesep v{i}.date_dir filesep v{i}.seq_dir];
    
    % Get snippet file info
    a = dir([snip_path filesep 'Snip*']);
    
    % Number of existing snippets
    snip_num = length(a);    
    
    % Delete snippet dir and data dir, if it has no video
    % (will be recreated below)
    if (snip_num>0) && isempty(dir([snip_path filesep a(end).name filesep '*.mp4']))
        rmdir([snip_path filesep a(end).name])
        if isdir([data_path filesep a(end).name])
            delete([snip_path filesep a(snip_num).name filesep '*.mat'])
            rmdir([data_path filesep a(end).name])
        end
        snip_num = snip_num-1;
    end
    
    % If no existing
    if snip_num==0
        % Initiate new snip
        snip_num = 1;
        
        % If existing
    else
        % Prompt for what to do
        answer = questdlg([num2str(snip_num) ...
            ' snippets exists! Create new or overwrite ' ...
            a(snip_num).name '?'],'!!','Overwrite','New','Cancel','Overwrite');
        
        % Parse response
        if strcmp(answer,'New')
            snip_num = snip_num + 1;
            
        elseif strcmp(answer,'Overwrite')
            delete([snip_path filesep a(snip_num).name filesep '*.mp4'])
            rmdir([snip_path filesep a(snip_num).name])
            if isdir([data_path filesep a(snip_num).name])
                delete([snip_path filesep a(snip_num).name filesep '*.mat'])
                rmdir([data_path filesep a(snip_num).name])
            end
            
        elseif strcmp(answer,'Cancel')
            return
        end
        
    end
    
    % Define directory name
    tmp = ['0' num2str(snip_num)];
    snip_name = ['Snip' tmp(end-1:end)];
    clear tmp
    
    % Loop thru cams
    for i = 1:length(cams)       
        % Store snip info
        v{i}.snip_name = snip_name;
        v{i}.snip_num  = snip_num; 
    end
     
    % Make path for snippets
    if save_as_seq
        im_path = [snip_path filesep v{i}.snip_name filesep v{i}.cam_dir];
        if isempty(dir(im_path))
            mkdir(im_path);
        end
        clear im_path
        
    elseif isempty(dir([snip_path filesep snip_name]))
        % Make snip video directory
        mkdir([snip_path filesep snip_name])       
    end
    
    % Make data directory
    if isempty(dir([data_path filesep snip_name]))
        mkdir([data_path filesep snip_name])
    end
    
    % Define batch name
    batch_name = [v{i}.date_dir '_' v{i}.seq_dir '_' snip_name];
    
    % Save batch info
    save([root.proj filesep 'Batches' filesep 'Snippets' filesep batch_name],'v');
    
    % Update status
    disp(' ');disp(['Added ' batch_name ' to batch cue!']); disp(' ');
    
end


%% Copy snippet

if run_batch
    
    % Get directory info
    aB = dir([root.proj filesep 'Batches' filesep 'Snippets' filesep '*.mat']);
    
    % Check for jobs
    if isempty(aB)
        disp('No jobs cued for the batch');
        return
    end
    
    % Load camera parameters for lens distortion ('cameraParams')
    load([root.proj filesep 'Lens correction, 1080 Narrow' filesep 'camera parameters.mat'])
    lensParams = cameraParams;
    clear cameraParams
    
    % Loop thru jobs 
    for bNum = 1:length(aB)
        
        % Status update
        disp(' ');disp(['Starting ' num2str(bNum) ' of ' num2str(length(aB)) ' jobs'])
         
        % Load job data ('v')
        load([root.proj filesep 'Batches' filesep 'Snippets' filesep aB(bNum).name]) 
        
        % Loop thru cams
        for i = 1:length(v)
            
            % Load calibration ('cal')
            load([v{i}.cal_path filesep 'threeD calibration.mat']);
            v{i}.cameraParams = cal{1}.cameraParams;
            clear cal
            
            % Get video path
            a = dir([root.rawvid filesep v{i}.date_dir filesep v{i}.seq_dir ...
                filesep v{i}.cam_dir filesep '*.MP4']);
            if isempty(a)
                error('No video file present')
            elseif length(a)>1
                error('Too many video files present')
            end
            
            % Create video reading object
            readObj = VideoReader([root.rawvid filesep v{i}.date_dir filesep ...
                v{i}.seq_dir filesep v{i}.cam_dir filesep a(1).name]);
            
            % Check time request
            if v{i}.time_end>readObj.Duration
                error('End time for snippet exceeds video duration');
            end
            
            % Extract video stats
            v{i}.fname_raw = a(1).name;
            v{i}.framerate = readObj.FrameRate;
            v{i}.numFrames = readObj.NumberOfFrames;
            v{i}.height    = readObj.Height;
            v{i}.width     = readObj.Width;
            
            % Define frame numbers
            v{i}.frames = floor(v{i}.time_start*v{i}.framerate):ceil(v{i}.time_end*v{i}.framerate);
            
            % Snippet path
            snip_path = [root.snip filesep v{i}.date_dir filesep v{i}.seq_dir];
            
            if ~save_as_seq
                % Create snippet object
                snipObj = VideoWriter([snip_path filesep v{i}.snip_name filesep ...
                    v{i}.cam_dir], 'MPEG-4');
                snipObj.FrameRate = readObj.FrameRate;              
                
                % Open object (for writing)
                open(snipObj)
            end
            
            % Loop thru frames
            for j = 1:length(v{i}.frames)
                
                % Read frame
                im = read(readObj,v{i}.frames(j));
                
                % Convert to gray
                %im = rgb2gray(im);
                
                % Undistort for lens
                [im, newOrigin] = undistortImage(im, lensParams,'OutputView','full');
                
                % Save origin
                v{i}.originA(j,:) = newOrigin;
                
                % Undistort again with 3D calibration correction
                [im, newOrigin] = undistortImage(im, v{i}.cameraParams,'OutputView','full');
                
                % Save origin
                v{i}.originB(j,:) = newOrigin;
                
                if sum(im(:))==0
                    error('The undistortion made a black image')
                end
                
                % Path to images
                im_path = [snip_path filesep v{i}.snip_name filesep v{i}.cam_dir];
                
                if save_as_seq
                    tmp = ['0000000' num2str(v{i}.frames(j))];
                    tmp = tmp(end-6:end);
                    im_name = ['frame_' tmp '.jpeg'];
                    
                    imwrite(im,[im_path filesep im_name],'JPEG',...
                        'Quality',65,'BitDepth',8);
                    clear tmp
                else
                    writeVideo(snipObj,im);
                end
                
                clear im newOrigin
                
                % Update status
                disp(['      Done ' num2str((i-1)*length(v{i}.frames) + j) ...
                      ' of ' num2str(length(v)*length(v{i}.frames))])
            end
            
            if ~save_as_seq
                % Close the video file written
                close(snipObj)
            end
            
            % Clean up old data file
            if ~isempty(dir([root.proj filesep 'rawdata' filesep v{i}.date_dir ...
                    filesep v{i}.seq_dir filesep v{i}.snip_name filesep v{i}.cam_dir '.mat']))
                delete([root.proj filesep 'rawdata' filesep v{i}.date_dir ...
                    filesep v{i}.seq_dir filesep v{i}.snip_name filesep v{i}.cam_dir '.mat']);
            end   
        end
        
        % Define paths for snippets and corresponding data
        save([root.proj filesep 'rawdata' filesep v{i}.date_dir ...
              filesep v{i}.seq_dir filesep 'video_data.mat'],'v')

        % Remove job file
        delete([root.proj filesep 'Batches' filesep 'Snippets' ...
                 filesep aB(bNum).name]);
        
        % Status update
        disp(['        Done ' num2str(bNum) ' of ' num2str(length(aB)) ' jobs'])
    end
    
end
