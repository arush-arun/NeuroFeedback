function copy_rtps_with_delay
%good old days
% Open a dialog to select the input folder
input_folder_path = uigetdir(pwd, 'Select the input folder containing RTP files'); 

% Check if a folder was selected
if isequal(input_folder_path,0)
   disp('No folder was selected. Exiting...');
   return;
else
   disp(['Selected input folder: ', input_folder_path]);
end

% Open a dialog to select the output folder
output_folder_path = uigetdir(pwd, 'Select the output folder');

% Check if a folder was selected
if isequal(output_folder_path,0)
   disp('No folder was selected. Exiting...');
   return;
else
   disp(['Selected output folder: ', output_folder_path]);
end

% Get delay from user input
delay = input('Enter the delay in seconds between copy operations (default is 1): ');

% If no delay is provided, set it to 1 second
if isempty(delay)
    delay = 1;
end

% Get a list of all RTP files in the input folder
rtp_files = dir(fullfile(input_folder_path, '*.rtp')); 

% Extract numeric parts from filenames and sort
[~, file_order] = sort(cellfun(@(x) str2double(regexp(x, '\d+', 'match')), {rtp_files.name}));

% Iterate through sorted RTP files and copy with delay
for i = 1:length(file_order)
    source_file = fullfile(input_folder_path, rtp_files(file_order(i)).name);
    destination_file = fullfile(output_folder_path, rtp_files(file_order(i)).name);
    copyfile(source_file, destination_file);
    fprintf('Copied %s to %s\n', source_file, destination_file);
    pause(delay); 
end

end