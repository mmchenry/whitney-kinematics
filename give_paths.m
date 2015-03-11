function root = give_paths
% Returns the paths used by the Whitney project. 
%
% root_snip - Diretcory that contains video snippets. Should reside on
%             internal storage for fast reading necessary for analysis
% root_rawvid - raw video files (organized). This is the source for the
%               snippets, but requires a lot of storage and should
%               therefore reside on external storage.
% root_proj - Location for data files. This is kept separate from the
%             snippets so that the snippets can easily be archived 
%             separately from the data.  The data files should be a lot
%             smaller.


% Find root on Matt's computer
if ~isempty(dir([filesep 'Users' filesep 'mmchenry']))    
    % Directory root for snippets
    root.snip       = '/Users/mmchenry/Documents/Video/JimmyJacob'; 
    
    % Directory root for raw video
    root.rawvid     = '/Volumes/WD MACPART/Video/Liao pred-prey/organized files';
    
    % Directory root for data files
    root.proj      = '/Users/mmchenry/Documents/Projects/JimmyJacob';
 
    
% For another computer, add a line here that will recognize the computer, 
% like this: elseif ~isempty(dir(['C:' filesep 'Users' filesep 'jacob']))  


else
    error('This computer is not recognized')
end