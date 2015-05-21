function aud = audio_sync(video_path)
% Save or load structure for syncing 3 video files from audio channels

%% Code execution

% Plot data to verify correct sync
plot_data = 1;

% Choose a portion of the audio
select_event = 1;


%% Parameters

% Interval for evaluating max intensity
dur_eval = 0.5;

% Duration of audio for visualizing the correction
%audio_dur = read_dur ;


%% Paths

% Get root paths
root = give_paths;

% Get date directories
aDates = dir([root.rawvid filesep '2015-*']);

if isempty(aDates)
    error('Choose new root path')
end


%% Create structure of directories

% Index 
k = 1;

% Loop thru dates
for i = 1:length(aDates)
    
    % Get experiment directories
    aExpts = dir([root.rawvid filesep aDates(i).name filesep 'expt*']);
    
    % Loop thru experiments
    for j = 1:length(aExpts)
        
        % Current data directory
        cDir = [root.proj filesep 'rawdata' filesep aDates(i).name filesep ...
                        aExpts(j).name];
                    
        % Current video directory
        vDir = [root.rawvid filesep aDates(i).name filesep aExpts(j).name];
                    
        % Make data directory
        if isempty(dir(cDir))
            mkdir(cDir);
            disp(['Making ' cDir]);
        end

        % Look for video directories
        aCams = dir([vDir filesep 'McHero4*']);
        
        % Don't store when there are fewer than 3 cams
        if length(aCams)~=3
            warning(['This expt has ' num2str(length(aCams)) ' cams:' cDir]);
            
        % Otherwise . . .
        else
            
            % Store directories
            audio{k}.date_dir = aDates(i).name;
            audio{k}.seq_dir  = aExpts(j).name;
            
            % Loop thru cams
            for L = 1:length(aCams)
                % Look for video directories
                aVid = dir([vDir filesep aCams(L).name filesep '*.MP4']);
                
                % Check number of videos
                if length(aVid)~=1
                    error('Expecting 1 video file');
                end
                
                % Store video file name
                audio{k}.vid_file{L} = [aCams(L).name filesep aVid.name];
            end
            
            % Advance index
            k = k + 1;
        end
    end
end

clear i j k L


%% Find interval with max signal

% Loop thru experiments
for i = 21:length(audio)
   
    % Current data directory
    cDir = [root.proj filesep 'rawdata' filesep audio{i}.date_dir filesep ...
                        audio{i}.seq_dir];
                    
    % Current video directory
    vDir = [root.rawvid filesep audio{i}.date_dir filesep audio{i}.seq_dir];
                                    
    % Loop thru cams & extract video
    for j = 1:length(audio{i}.vid_file)
        
        % Get audioinfo
        aInfo = audioinfo([vDir filesep audio{i}.vid_file{j}]);
        
        % Extract audio
        [tmp,Fs] = audioread(aInfo.Filename);
        
        % Choose channel with greater signal
        if mean(abs(tmp(:,1))) > mean(abs(tmp(:,2)))
            y = tmp(:,1);
        else
            y = tmp(:,2);
        end
        
        % Time value
        t = [0:(length(y)-1)]'./Fs;
        
        % Store values to be used
        cam{j}.t  = t;
        cam{j}.y  = y;
        cam{j}.Fs = Fs;
        
        clear a tmp t
    end
    
    % Index of values
    idx = 1:min([length(cam{1}.t) length(cam{2}.t) length(cam{3}.t)]); 
    
    % Audio matrix
    y = [cam{1}.y(idx) cam{2}.y(idx) cam{3}.y(idx)];
    
    % Time matrix
    if (cam{1}.Fs==cam{2}.Fs) && (cam{1}.Fs==cam{3}.Fs) 
        t = cam{1}.t(idx);
        Fs = cam{1}.Fs;
    else
        error('Unequal sample rates');
    end
 
    clear cam
    
    % Loop thru intervals to find mean values
    for j = 1:floor(max(t(:))/dur_eval)
               
        % Index of interval values
        idx = (t>=(dur_eval*(j-1))) & (t<(dur_eval*j));
        
        % Mean product of three cameras over interval
        yMean(j,1) = mean(abs(y(idx,1)).*abs(y(idx,2)).*abs(y(idx,3)));
        
        % Mean time value
        tMean(j,1) = mean(t(idx));
    end
    
    % Time index
    iTime = find(yMean==max(yMean),1,'first');
    
    % Start time 
    t_start = tMean(iTime) - 1.5*dur_eval;
    
    % End time
    t_end = tMean(iTime) + 1.5*dur_eval;
    
    % Index of values to interrogate
    idx = (t>=t_start) & (t<t_end);
    
    % Trim to duration to be considered
    y = y(idx,:);
    t = t(idx,:);
    
    % Find delays wrt first camera
    delay(1,1) = 0;
    delay(2,1) = finddelay(y(:,1),y(:,2))./Fs;
    delay(3,1) = finddelay(y(:,1),y(:,3))./Fs;
  
    % Store data
    aud.date_dir    = audio{i}.date_dir;
    aud.seq_dir     = audio{i}.seq_dir;
    aud.vid_file    = audio{i}.vid_file;
    aud.delay       = delay;
        
    % Write data
    save([cDir filesep 'audio_data'],'aud');
    
    if 0
        % Play audio (for troubleshooting)
        aud_player = audioplayer(y(:,1),Fs);
        play(aud_player)
    end
    
    % VISUALIZE RESULTS ---------------------------------------------------

    figure;
%     subplot(3,1,1)
%     plot(tMean,yMean);
%     xlabel('t (s)')
%     ylabel('Mean audio (V)');
    
    subplot(2,1,1)
    plot(t,y);
    xlabel('t (s)')
    ylabel('Audio product (V^3)');
    
    subplot(2,1,2)
    plot(t-delay(1),y(:,1),'-',...
         t-delay(2),y(:,2),'-',...
         t-delay(3),y(:,3),'-');
    xlabel('t (s)')
    ylabel('Audio (V)');
    
    pause(0.1)
    
     % Capture graphs
    I = getframe(gcf);
    close
    
    % Write frame
    imwrite(I.cdata,[cDir filesep 'Audio sync.jpeg'],'JPEG');
    close
    
    % Update status
    disp(['Completed ' num2str(i) ' of ' num2str(length(audio))])
    
    clear aud y t idx delay tMean yMean
end




function prompt_play(aud,ch_num)

buttonName = questdlg('Play weak channel?',['Channel ' ch_num],...
                      'Yes','No','Cancel','Yes');

switch buttonName
    
    case 'Cancel'
        return
    case 'No'
        % Do nothing
    case 'Yes'
        disp(['Playing audio for the following:'])
        disp(aud.path)
        play(aud.player)
        
end



    