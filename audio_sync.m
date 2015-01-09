function aud = audio_sync(video_path, vid_path)
% Save or load structure for syncing 3 video files from audio channels

% Duration of audio for visualizing the correction
audio_dur = 0.5;

% Duration at start of audio signal to skip
skip_dur = 0.5;

% Total duration to consider (s)
read_dur = 5; 

% Plot data to verify correct sync
plot_data = 1;

% Check for number of cameras
if length(vid_path)~=3
    error('Expecting 3 cameras, 3 not given')
end

% Create 'aud' structure, if delayinfo.mat file does not exist
if isempty(dir([video_path filesep 'delayinfo.mat']))
    
    % Loop thru cameras
    for i = 1:3
        % Get video file path
        a = dir([vid_path{i} filesep '*.MP4']);
        
        % Get audioinfo
        aInfo = audioinfo([vid_path{i} filesep a(1).name]);
        
        % Extract audio
        [tmp,aud{i}.Fs] = audioread(aInfo.Filename);
        
        % Choose channel with greater signal
        if mean(abs(tmp(:,1))) > mean(abs(tmp(:,2)))
            y = tmp(:,1);
        else
            y = tmp(:,2);
        end
        
        % Time value
        t = [0:(length(y)-1)]'./aud{i}.Fs;
        
        % Values to include
        idx = (t > skip_dur) & (t < (read_dur+skip_dur));
        
        % Store values to be used
        aud{i}.path = vid_path{i};
        aud{i}.t = t(idx);
        aud{i}.y = y(idx);
        
        % Create audio player (for troubleshooting)
        aud{i}.player = audioplayer(aud{i}.y,aud{i}.Fs);
        
        clear y t idx
    end
    
    clear tmp
    
    % Check that sample rate is uniform
    if (aud{1}.Fs~=aud{2}.Fs) || (aud{1}.Fs~=aud{3}.Fs)
        error('Videos vary in their sample rate');
    end
    
    % Check signal 1
    if range(aud{1}.y) < mean([range(aud{2}.y) range(aud{3}.y)])/2
        prompt_play(aud{1},num2str(1));
    end
    
    % Check signal 2
    if range(aud{2}.y) < mean([range(aud{1}.y) range(aud{3}.y)])/2
        prompt_play(aud{2},num2str(2));
    end
    
    % Check signal 3
    if range(aud{3}.y) < mean([range(aud{1}.y) range(aud{2}.y)])/2
        prompt_play(aud{3},num2str(3));
    end
    
    % Find delays wrt camera A
    aud{1}.delay = 0;
    aud{2}.delay = finddelay(aud{1}.y,aud{2}.y)./aud{1}.Fs;
    aud{3}.delay = finddelay(aud{1}.y,aud{3}.y)./aud{1}.Fs;
    
    % Plot data to check delay
    if plot_data     
        % Plot
        figure;
        subplot(2,1,1)
        h = plot(aud{1}.t,aud{1}.y,'-',...
                 aud{2}.t,aud{2}.y,'-',...
                 aud{3}.t,aud{3}.y,'-');
        xlabel('Time (s)')
        ylabel('Audio track (V)')
        title('Before correction')
        
        xlim([skip_dur skip_dur+audio_dur])
        
        subplot(2,1,2)
        plot(aud{1}.t-aud{1}.delay,aud{1}.y,'-',...
             aud{2}.t-aud{2}.delay,aud{2}.y,'-',...
             aud{3}.t-aud{3}.delay,aud{3}.y,'-')
        xlabel('Time (s)')
        ylabel('Audio track (V)')
        title('After correction')
        
        xlim([skip_dur skip_dur+audio_dur])
        
        %xlim([0 .5])
    end

    % Save delay data
    save([video_path filesep 'delayinfo.mat'],'aud')
   
    
% Alternatively, load 'aud' structure
else
    disp('Loading audio delay data . . .')
    load([video_path filesep 'delayinfo.mat'])
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



    