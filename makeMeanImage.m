function makeMeanImage(dPath,vPath,frames)

% Max number of frames to analyze
maxFrames = 1000;

% Proportion of video duration to exclude, from the beginning
exclude_prop = 0.2;

% Get dimensions of frames
img = get_image(vPath,frames(1));  
p.roi_x = [1 size(img,2) size(img,2) 1 1];
p.roi_y = [1 size(img,1) 1 1 size(img,1)];

% Define list of frame numbers, depending on max number of frames
% requested
if (1-exclude_prop)*length(frames) > maxFrames
    dframe = floor(length(frames)/maxFrames);
    frame1 = round(exclude_prop*length(frames));
    frIdx = frame1:dframe:length(frames);
    clear dframe frame1
else
    frIdx = 1:length(frames);
end

% Create waitbar
h = waitbar(0,...
    ['Mean image: ' num2str(1)],...
    'CreateCancelBtn','setappdata(gcbf,''canceling'',1)');

% Create sum image based on first frame
imCurr = get_image(vPath,frames(1));  
%[imCurr,tmp] = imread([vPath filesep filesep p.filename{1}]);
imSum = double(imCurr);
clear imCurr tmp

% Loop through frames
for i = 1:length(frIdx)
    
    % Add current frame to sum image
    %[imCurr,tmp] = imread([vPath filesep filesep p.filename{frIdx(i)}]);
    imCurr = get_image(vPath,frames(i));  
    imSum        = imSum + double(imCurr);
    clear tmp imCurr
    
    % Update status bar
    h = waitbar(i/length(frIdx),h,...
        ['Mean image: ' num2str(i) ' of ' num2str(length(frIdx)) ' frames']);
    
    % Quit m-file, if cancel button pushed
    if getappdata(h,'canceling')
        close force
        return
    end
    
end

% Calculate mean from sum image
imMean = uint8(round(imSum./length(frIdx)));

imMean = imMean(:,:,1);

% Write image to movie dir
imwrite(imMean,[dPath filesep 'meanImage.tif'],'tif',...
    'Compression','none');

close(h)

end


function im = get_image(im_dir,fr_num)  
% Returns requested image data
    tmp = ['0000000' num2str(fr_num)];
    tmp = tmp(end-6:end);
    im_name = ['frame_' tmp '.jpeg'];
    im = imread([im_dir filesep im_name]);
    
    % Convert to grayscale
    if size(im,3)>1
        im = rgb2gray(im);
    end
end
