%%
%Last edited by Amir Dakhili on September 3rd, 2024
%%

%ROI PSC with confound - image sets
%TURN OFF BLUETOOTH IF ON
% Please use Backslash for file and folder names in WINDOWS!

% Hemodynamic lag needs to be considered implicitly by participant

% 1st is target ROI and 2nd is confound
warning off;
sca;
clear all
global TR window scr_rect centreX centreY escapeKey start_time current_TBV_tr ROI_PSC ROI_vals PSC_thresh port_issue imageTextures imageTextures2 psc_data FB_timings;


%% Needs Change

TR = 1

%Note: Folder\File names here should not have any numbers because it interferes
%with the rt_load_BOLD function

feedback_dir = ['C:\Users\NFB-user\Desktop\NFB_new']; %Needs Change
feedback_file_name = 'NFB'; %Needs Change
%also location to any lines related to the participant_ folder needs change
run_no = 1 %Needs Change


%% Optional to change
block_dur_TR = 50; % in TRs - at least 20
rest_dur_TR = 20; % in TRs - at least 15
cue_dur_TR = 5; % in TRs - Use 5

%% Needs change 

pp_no = 0;
pp_name = 'Pilot';
num_blocks = 2; % Use 1
input('Press Enter to start >>> ','s'); %printing to command window

block_init = 0.5;
block = block_init;
%current_TBV_tr = 1; %initializing

%For craving and MW blocks
MW_blocks = 0;
craving_blocks = 0;

craving_block_timings = [];
rest_block_timings = [];
VAS_block_timings = [];
cue_timings = [];
FB_timings = [];
rest_blocks_mean = [];
rest_blocks_TRs = [];
psc_data = [];
FB_timings = []; % Initialize FB_timings
ROI_PSC = [];
port_issue = [];
%PSC_thresh = -2; %starting with a default value
PSC_thresh = 2; %lower craving results in lower scale 

fileID1 = fopen(fullfile([pwd '\Participant_' num2str(pp_no)],['\' date '_pp_' num2str(pp_no) '_run_' num2str(run_no) '_cue_timing.txt']), 'w');
fileID2 = fopen(fullfile([pwd '\Participant_' num2str(pp_no)],['\' date '_pp_' num2str(pp_no) '_run_' num2str(run_no) '_block_timing.txt']), 'w');


%Writing to text files
PrintGeneralInfo(fileID1,date,pp_name,run_no,num_blocks,block_dur_TR);
PrintGeneralInfo(fileID2,date,pp_name,run_no,num_blocks,block_dur_TR);

fprintf(fileID1, '\n============================================================================\n');
fprintf(fileID1, '\n\n______________________________Cue timing information:__________________________');

fprintf(fileID2, '\n============================================================================\n');
fprintf(fileID2, '\n\n______________________________Block timing information:__________________________');

saveroot = [pwd '\Participant_' num2str(pp_no) '\'];


%creating first feedback file (dummy)
dlmwrite([feedback_dir '\' feedback_file_name '-1.rtp'],[2,0,0,-1],'delimiter',' ');

try
    % Setup PTB with default value
    PsychDefaultSetup(1);
    
    % COMMENT OUT FOR ACTUAL EXPERIMENT - ONLY ON FOR TESTING
    Screen('Preference', 'SkipSyncTests', 1);
    
    % Get the screen number (primary or secondary)
    getScreens = Screen('Screens');
    ChosenScreen = min(getScreens); %choosing screen for display
    %ChosenScreen = max(getScreens); %choosing screen for display
    full_screen = [];
    
    % Getting screen luminance values
    white = WhiteIndex(ChosenScreen); %255
    black = BlackIndex(ChosenScreen); %0
    grey = white/2;
    magenta = [255 0 255];
    green = [0 255 0];
    
    %window
    TEST=1; % 1 is windows mode, zero is real test;

    % Open buffered screen window and color it black. scr_rect is a
    % rectange the size of the screen (1x4 array)
    if TEST==1
        [window, scr_rect] = PsychImaging('OpenWindow', ChosenScreen, black, [0 0 800 600]);
    else
        [window, scr_rect] = PsychImaging('OpenWindow', ChosenScreen, black, full_screen);
    % Hide the mouse cursor
    HideCursor(window);
    end

    % Get the coordinates of screen centre
    [centreX,centreY] = RectCenter(scr_rect);
    %%%%
    [windowWidth, windowHeight] = Screen('WindowSize', window); % Get window dimensions in pixels
    %%%%
% Load Images & Instructions
    numImages = 5;
    imageDurationSecs = 10;
    imageTextures = [];
    imageTextures2 = [];
    imageDir = fullfile(pwd, 'TRIGGER_A_Media');

    for i = 1:numImages
        imagePath = fullfile(imageDir, sprintf('C%d.png', i));
        if exist(imagePath, 'file') == 2
            img = imread(imagePath);
            imageTextures(i) = Screen('MakeTexture', window, img);
        else
            error('Image file not found: %s', imagePath);
        end
    end

    % Second set of images
    for i = 6:10
        imagePath = fullfile(imageDir, sprintf('C%d.png', i));
        if exist(imagePath, 'file') == 2
            img = imread(imagePath);
            imageTextures2(i) = Screen('MakeTexture', window, img);
        else
            error('Image file not found: %s', imagePath);
        end
    end
    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

    
    % Give PTB processing priority over other system and app processes
    Priority(MaxPriority(window));

    
    % Inter-frame interval
    ifi = Screen('GetFlipInterval',window);
    
    % Screen refresh rate
    hertz = FrameRate(window);
    

    
    % Define the keyboard keys that are listened for.
    
    KbName('UnifyKeyNames');
    escapeKey = KbName('ESCAPE');
    triggerKey = KbName('T'); %This is the trigger from the MRI
    
    
    
    %----------------------------------------------------------------------
    %Screen before trigger
    % FIRST CUE
    Text = 'A cross will appear now... \n \n Please look at the cross\n\n Press `t` to start.';
    Screen('TextSize', window, round(windowHeight * 0.05));  % Dynamic font size (5% of window height)
    Screen('TextFont', window, 'Arial');                    % Set font to Arial
    Screen('TextStyle', window, 0);  
    DrawFormattedText(window,Text,'center','center',magenta);
    Screen('Flip',window);
    
    %Reading Trigger
    KbTriggerWait(triggerKey);
    
    %creating second feedback file (dummy) after trigger
    dlmwrite([feedback_dir '\' feedback_file_name '-2.rtp'],[2,0,0,-1],'delimiter',' ');
    
    start_time = GetSecs();
    ROI_vals = [];
    
    fprintf(fileID1, '\nRun start time (MRI): \t\t%d \n', start_time);
    fprintf(fileID2, '\nRun start time (MRI): \t\t%d \n', start_time);
    elapsed = GetSecs()-start_time;

    while elapsed<10 %proceed at TR=11 (after 10 secs) to accomodate initial TBV lags
        elapsed = GetSecs()-start_time;
        current_TBV_tr = rt_load_BOLD(feedback_dir,feedback_file_name);
    end
    
    fprintf(fileID1, 'TBV start TR: \t\t%f ', current_TBV_tr);  
    fprintf(fileID2, 'TBV start TR: \t\t%f ', current_TBV_tr);
    
    %----------------------------------------------------------------------
    % cue start, cue end, cue duration
    fprintf(fileID1, '\n\n MRI Cue start     MRI Cue end     MRI Cue duration    TBV Cue start TR    TBV Cue end TR    TBV Cue duration TR \n\n');
    % block start, block end, block duration
    fprintf(fileID2, '\n\n MRI Block start     MRI Block end     MRI Block duration   TBV Block start TR    TBV Block end TR   TBV Block duration TR \n\n');
    %----------------------------------------------------------------------

    %% Baseline Rest period
    

    [block_start,block_end,block_dur,block_start_TR,block_end_TR,block_start_TBV_TR,block_end_TBV_TR] = DrawFixationCross(grey,rest_dur_TR+40,feedback_dir,feedback_file_name);  %dark grey
    rest_block_timings = [rest_block_timings;block_start,block_end,block_dur,block_start_TBV_TR,block_end_TBV_TR,block_end_TBV_TR-block_start_TBV_TR+1];
    fprintf(fileID2,'%f  %f  %f  %f  %f  %f\n',[block_start,block_end,block_dur,block_start_TBV_TR,block_end_TBV_TR,block_end_TBV_TR-block_start_TBV_TR+1]);
    rest_blocks_TRs = [rest_blocks_TRs;block_start_TR,block_end_TR]; %storing MRI TR for future calculation
    
    trial_history = [];
    
            
            baseline_lag_dur = 12; % all calculations to start after these many TRs at the beginning of run
            rest_calc_start_TR = rest_blocks_TRs(end,1) + 13; % considering a hemo lag of 7 TRs and additional 6 TRs buffer
            
            if current_TBV_tr > rest_calc_start_TR
                
                if current_TBV_tr < rest_blocks_TRs(end,2) %if current TBV TR has not reached the end of most recent rest block
                    calc_interval = rest_calc_start_TR:current_TBV_tr; %use whatever last TBV TR was available
                else %ideally should be this
                    calc_interval = rest_calc_start_TR:rest_blocks_TRs(end,2);
                end
                
                %ALL BOLD PSC values from dynamic ROI
                all_vals = ROI_vals(baseline_lag_dur:end,1); %Taking all the BOLD values so far, for cumulative GLM
                
                %Confound signal
                all_conf_vals = ROI_vals(baseline_lag_dur:end,2); %Taking all the midline mask values so far, for cumulative GLM
                
                %Cumulative GLM - Regressing out detrended and demeaned confound from ROI so far
                [beta,~,stats] = glmfit(all_conf_vals-mean(all_conf_vals),all_vals);
                resid_BOLD = stats.resid + beta(1);
                rest_mean = mean(resid_BOLD(calc_interval-baseline_lag_dur+1)); %required mean is the residual mean withiin the rest block
                
            else
                %Something is wrong if the current TBV TR has not even reached the starting of the block
                %At the end of the block
                rest_mean = 0;
            end
            rest_blocks_mean = [rest_blocks_mean;rest_mean];
    
    %current_TBV_tr = rt_load_BOLD(feedback_dir,feedback_file_name);
    % CUE
%     Text = '---End of restful thinking---';
%     [cue_start,~,~,cue_start_TR,~,cue_start_TBV_TR,~] = WriteInstruction(Text,magenta,cue_dur_TR-3,feedback_dir,feedback_file_name);
    Text = 'Soon, you will see an \ninstruction to upregulate your craving on screen.';
    [cue_start,cue_end,~,cue_start_TR,cue_end_TR,cue_start_TBV_TR,cue_end_TBV_TR] = WriteInstruction(Text,magenta,cue_dur_TR,feedback_dir,feedback_file_name);
    cue_dur = cue_end - cue_start;
    cue_timings = [cue_timings;cue_start,cue_end,cue_dur,cue_start_TBV_TR,cue_end_TBV_TR,cue_end_TBV_TR-cue_start_TBV_TR+1];
    fprintf(fileID1,'%f  %f  %f  %f  %f  %f\n\n',[cue_start,cue_end,cue_dur,cue_start_TBV_TR,cue_end_TBV_TR,cue_end_TBV_TR-cue_start_TBV_TR+1]);
    
    %------------------------------------------------------------------   %% Start of task
    
    %% Craving neurofeedback task
    current_TBV_tr = rt_load_BOLD(feedback_dir,feedback_file_name);
    ROI_vals;
    ROI_PSC;
    craving_blocks = craving_blocks+1;

    
    
    % craving CUE
    
    Text = 'While you view five images, \n try to increase your craving for the drug.';
    [cue_start,~,~,cue_start_TR,~,cue_start_TBV_TR,~] = WriteInstruction(Text,magenta,cue_dur_TR,feedback_dir,feedback_file_name);
    Text = 'Score bar will increase with more craving.';
    WriteInstruction(Text,magenta,cue_dur_TR-2,feedback_dir,feedback_file_name);
    
    Text = 'Start:';
    WriteInstruction(Text,magenta,cue_dur_TR-3,feedback_dir,feedback_file_name);
    for countdown=3:-1:1
        Text = num2str(countdown);
        if countdown > 1
            WriteInstruction(Text,magenta,cue_dur_TR-4,feedback_dir,feedback_file_name);
        else
            [~,cue_end,~,~,cue_end_TR,~,cue_end_TBV_TR] = WriteInstruction(Text,magenta,cue_dur_TR-4,feedback_dir,feedback_file_name);
        end
    end
    cue_dur = cue_end - cue_start;
    cue_timings = [cue_timings;cue_start,cue_end,cue_dur,cue_start_TBV_TR,cue_end_TBV_TR,cue_end_TBV_TR-cue_start_TBV_TR+1];
    fprintf(fileID1,'%f  %f  %f  %f  %f  %f\n\n',[cue_start,cue_end,cue_dur,cue_start_TBV_TR,cue_end_TBV_TR,cue_end_TBV_TR-cue_start_TBV_TR+1]);
    
    % BLANK
    BlankOut(1,feedback_dir,feedback_file_name);

    % CRAVING + feedback
    % Open file for image timings for first set of images
    fileID3 = fopen(fullfile([pwd '\Participant_' num2str(pp_no)],['\' date '_pp_' num2str(pp_no) '_run_' num2str(run_no) '_image_timing_run1.txt']), 'w');
    fprintf(fileID3, 'Image Onset     Image Offset     Image Duration \n\n');

    [block_start,block_end,block_dur,block_start_TR,block_end_TR,block_start_TBV_TR,block_end_TBV_TR, image_onsets, image_durations, image_offsets] = Craving_feedback(...
        block_dur_TR,feedback_dir,feedback_file_name, imageTextures, imageDurationSecs, fileID3);  %dark grey
    fprintf(fileID2,'%f  %f  %f  %f  %f  %f\n',[block_start,block_end,block_dur,block_start_TBV_TR,block_end_TBV_TR,block_end_TBV_TR-block_start_TBV_TR+1]);
    craving_block_timings = [craving_block_timings;[block_start,block_end,block_dur,block_start_TBV_TR,block_end_TBV_TR,block_end_TBV_TR-block_start_TBV_TR+1]];
    fclose(fileID3);
    % BLANK
    BlankOut(1,feedback_dir,feedback_file_name);
    
    % CUE
    Text = '---Good Job!---';
    [cue_start,cue_end,cue_dur,cue_start_TR,cue_end_TR,cue_start_TBV_TR,cue_end_TBV_TR] = WriteInstruction(Text,magenta,cue_dur_TR-3,feedback_dir,feedback_file_name);
    cue_timings = [cue_timings;cue_start,cue_end,cue_dur,cue_start_TBV_TR,cue_end_TBV_TR,cue_end_TBV_TR-cue_start_TBV_TR+1];
    fprintf(fileID1,'%f  %f  %f  %f  %f  %f\n\n',[cue_start,cue_end,cue_dur,cue_start_TBV_TR,cue_end_TBV_TR,cue_end_TBV_TR-cue_start_TBV_TR+1]);
   
    % Fixation point for ten seconds:

    [block_start,block_end,block_dur,block_start_TR,block_end_TR,block_start_TBV_TR,block_end_TBV_TR] = DrawFixationCross(grey,rest_dur_TR-10,feedback_dir,feedback_file_name);  %dark grey
    rest_block_timings = [rest_block_timings;block_start,block_end,block_dur,block_start_TBV_TR,block_end_TBV_TR,block_end_TBV_TR-block_start_TBV_TR+1];
    fprintf(fileID2,'%f  %f  %f  %f  %f  %f\n',[block_start,block_end,block_dur,block_start_TBV_TR,block_end_TBV_TR,block_end_TBV_TR-block_start_TBV_TR+1]);
    rest_blocks_TRs = [rest_blocks_TRs;block_start_TR,block_end_TR]; %storing MRI TR for future calculation

    % BLANK
    BlankOut(1,feedback_dir,feedback_file_name);

     % CUE

    Text = 'Soon, you will see an \ninstruction to upregulate your craving on screen.';
    [cue_start,cue_end,~,cue_start_TR,cue_end_TR,cue_start_TBV_TR,cue_end_TBV_TR] = WriteInstruction(Text,magenta,cue_dur_TR,feedback_dir,feedback_file_name);
    cue_dur = cue_end - cue_start;
    cue_timings = [cue_timings;cue_start,cue_end,cue_dur,cue_start_TBV_TR,cue_end_TBV_TR,cue_end_TBV_TR-cue_start_TBV_TR+1];
    fprintf(fileID1,'%f  %f  %f  %f  %f  %f\n\n',[cue_start,cue_end,cue_dur,cue_start_TBV_TR,cue_end_TBV_TR,cue_end_TBV_TR-cue_start_TBV_TR+1]);
    
    %------------------------------------------------------------------   %% Start of task
    
    %% Craving neurofeedback task
    current_TBV_tr = rt_load_BOLD(feedback_dir,feedback_file_name);
    ROI_vals;
    ROI_PSC;
    craving_blocks = craving_blocks+1;

    
    
    % CRAVING CUE
    
    Text = 'While you view five images, \n try to increase your craving for the drug.';
    [cue_start,~,~,cue_start_TR,~,cue_start_TBV_TR,~] = WriteInstruction(Text,magenta,cue_dur_TR,feedback_dir,feedback_file_name);
    Text = 'Score bar will increase with more craving.';
    WriteInstruction(Text,magenta,cue_dur_TR-2,feedback_dir,feedback_file_name);
    
    Text = 'Start:';
    WriteInstruction(Text,magenta,cue_dur_TR-3,feedback_dir,feedback_file_name);
    for countdown=3:-1:1
        Text = num2str(countdown);
        if countdown > 1
            WriteInstruction(Text,magenta,cue_dur_TR-4,feedback_dir,feedback_file_name);
        else
            [~,cue_end,~,~,cue_end_TR,~,cue_end_TBV_TR] = WriteInstruction(Text,magenta,cue_dur_TR-4,feedback_dir,feedback_file_name);
        end
    end
    cue_dur = cue_end - cue_start;
    cue_timings = [cue_timings;cue_start,cue_end,cue_dur,cue_start_TBV_TR,cue_end_TBV_TR,cue_end_TBV_TR-cue_start_TBV_TR+1];
    fprintf(fileID1,'%f  %f  %f  %f  %f  %f\n\n',[cue_start,cue_end,cue_dur,cue_start_TBV_TR,cue_end_TBV_TR,cue_end_TBV_TR-cue_start_TBV_TR+1]);
    
    % BLANK
    BlankOut(1,feedback_dir,feedback_file_name);

    % CRAVING + feedback
    fileID4 = fopen(fullfile([pwd '\Participant_' num2str(pp_no)],['\' date '_pp_' num2str(pp_no) '_run_' num2str(run_no) '_image_timing_run2.txt']), 'w');
    fprintf(fileID4, 'Image Onset     Image Offset     Image Duration \n\n');

    [block_start,block_end,block_dur,block_start_TR,block_end_TR,block_start_TBV_TR,block_end_TBV_TR, image_onsets2, image_durations2, image_offsets2] = Craving_feedback2(...
        block_dur_TR,feedback_dir,feedback_file_name, imageTextures2, imageDurationSecs, fileID4);  %dark grey
    fprintf(fileID2,'%f  %f  %f  %f  %f  %f\n',[block_start,block_end,block_dur,block_start_TBV_TR,block_end_TBV_TR,block_end_TBV_TR-block_start_TBV_TR+1]);
    craving_block_timings = [craving_block_timings;[block_start,block_end,block_dur,block_start_TBV_TR,block_end_TBV_TR,block_end_TBV_TR-block_start_TBV_TR+1]];
    fclose(fileID4);


        
%%%ROI_psc for imagesets

    % Retrieve image onset and offset values
    first_image_onset = image_onsets(1);
    last_image_offset = image_offsets(end);

    first_image_onset_2 = image_onsets2(1);
    last_image_offset_2 = image_offsets2(end);

    % Convert onset/offset times (in seconds) to TRs
    first_image_onset_TR = floor(first_image_onset / TR);
    last_image_offset_TR = ceil(last_image_offset / TR) + 1;

    first_image_onset_2_TR = floor(first_image_onset_2 / TR);
    last_image_offset_2_TR = ceil(last_image_offset_2 / TR);

    % Find the rows in ROI_PSC corresponding to the image presentation TRs
    image_set1_rows = find(ROI_PSC(:, 4) >= first_image_onset_TR & ROI_PSC(:, 4) <= last_image_offset_TR);
    image_set2_rows = find(ROI_PSC(:, 4) >= first_image_onset_2_TR & ROI_PSC(:, 4) <= last_image_offset_2_TR);

    % Find the unique TRs within the image presentation TR ranges
    [unique_image_set1_TRs, ia1] = unique(ROI_PSC(image_set1_rows, 4)); 
    [unique_image_set2_TRs, ia2] = unique(ROI_PSC(image_set2_rows, 4));
    
    % Extract the first occurrence of each unique TR 
    image_set1_rows = image_set1_rows(ia1);
    image_set2_rows = image_set2_rows(ia2);

    % Extract ROI_PSC values for each image set
    Deconf_ROI_PSC.ImageSet1 = ROI_PSC(image_set1_rows, :);
    Deconf_ROI_PSC.ImageSet2 = ROI_PSC(image_set2_rows, :);

    %%%%%dynamic_psc for image sets
        % Convert onset/offset times (in seconds) to TRs
    first_image_onset_TR_ = floor(first_image_onset / TR);
    last_image_offset_TR_= ceil(last_image_offset / TR);

    first_image_onset_2_TR_ = floor(first_image_onset_2 / TR);
    last_image_offset_2_TR_ = ceil(last_image_offset_2 / TR);
	% Find the rows in ROI_vals corresponding to the image presentation TRs
    roi_vals_image_set1_rows = find(ROI_vals(:, 3) >= first_image_onset_TR_ & ROI_vals(:, 3) <= last_image_offset_TR_);
    roi_vals_image_set2_rows = find(ROI_vals(:, 3) >= first_image_onset_2_TR_ & ROI_vals(:, 3) <= last_image_offset_2_TR_);
    
    % Find the unique TRs within the image presentation TR ranges from ROI_vals
    [unique_roi_vals_image_set1_TRs, ia1] = unique(ROI_vals(roi_vals_image_set1_rows, 3));
    [unique_roi_vals_image_set2_TRs, ia2] = unique(ROI_vals(roi_vals_image_set2_rows, 3));
    
    % Extract the first occurrence of each unique TR 
    roi_vals_image_set1_rows = roi_vals_image_set1_rows(ia1);
    roi_vals_image_set2_rows = roi_vals_image_set2_rows(ia2);
    
    % Extract temp2 and conf values for each image set from ROI_vals
    Raw_ROI_PSC.ImageSet1 = ROI_vals(roi_vals_image_set1_rows, [1:3]); % Assuming temp2 is in column 1 and conf is in column 2
    Raw_ROI_PSC.ImageSet2 = ROI_vals(roi_vals_image_set2_rows, [1:3]);

    % BLANK
    BlankOut(1,feedback_dir,feedback_file_name);
    
    % CUE
    Text = '---Good Job!---';
    [cue_start,cue_end,cue_dur,cue_start_TR,cue_end_TR,cue_start_TBV_TR,cue_end_TBV_TR] = WriteInstruction(Text,magenta,cue_dur_TR-3,feedback_dir,feedback_file_name);
    cue_timings = [cue_timings;cue_start,cue_end,cue_dur,cue_start_TBV_TR,cue_end_TBV_TR,cue_end_TBV_TR-cue_start_TBV_TR+1];
    fprintf(fileID1,'%f  %f  %f  %f  %f  %f\n\n',[cue_start,cue_end,cue_dur,cue_start_TBV_TR,cue_end_TBV_TR,cue_end_TBV_TR-cue_start_TBV_TR+1]);
   
    % Fixation point for three seconds:

    [block_start,block_end,block_dur,block_start_TR,block_end_TR,block_start_TBV_TR,block_end_TBV_TR] = DrawFixationCross(grey,rest_dur_TR-17,feedback_dir,feedback_file_name);  %dark grey
    rest_block_timings = [rest_block_timings;block_start,block_end,block_dur,block_start_TBV_TR,block_end_TBV_TR,block_end_TBV_TR-block_start_TBV_TR+1];
    fprintf(fileID2,'%f  %f  %f  %f  %f  %f\n',[block_start,block_end,block_dur,block_start_TBV_TR,block_end_TBV_TR,block_end_TBV_TR-block_start_TBV_TR+1]);
    rest_blocks_TRs = [rest_blocks_TRs;block_start_TR,block_end_TR]; %storing MRI TR for future calculation

    % BLANK
    BlankOut(1,feedback_dir,feedback_file_name);
    
    % VAS
   
    
    Text = sprintf(['Soon you will see a scale. Please rate your current craving from 0 to 10: \n\n', ...
                    '0 (No craving) <---> 10 (High craving) \n\n', ...
                    'Use <<LEFT>> button to DECREASE \n', ...
                    'Use <<RIGHT>> button to INCREASE \n\n', ...
                    'When finished, simply release the keys.']);
    [cue_start,cue_end,cue_dur,cue_start_TR,cue_end_TR,cue_start_TBV_TR,cue_end_TBV_TR] = WriteInstruction(Text,magenta,cue_dur_TR+10,feedback_dir,feedback_file_name);
    cue_timings = [cue_timings;cue_start,cue_end,cue_dur,cue_start_TBV_TR,cue_end_TBV_TR,cue_end_TBV_TR-cue_start_TBV_TR+1];
    fprintf(fileID1,'%f  %f  %f  %f  %f  %f\n\n',[cue_start,cue_end,cue_dur,cue_start_TBV_TR,cue_end_TBV_TR,cue_end_TBV_TR-cue_start_TBV_TR+1]);
    
    % BLANK
    BlankOut(1, feedback_dir, feedback_file_name);
    
    % Likert Scale Instruction
    instructionText = 'Please rate your current craving on the scale from 0 to 10';
    [block_start, block_end, block_dur, block_start_TR, block_end_TR, block_start_TBV_TR, block_end_TBV_TR] = likert_scale(window, scr_rect, instructionText, feedback_dir, feedback_file_name);
    
    % Store Ratings
    VAS_block_timings = [VAS_block_timings; block_start, block_end, block_dur, block_start_TBV_TR, block_end_TBV_TR, block_end_TBV_TR-block_start_TBV_TR+1];
    %fprintf(fileID2,'%f  %f  %f  %f  %f  %f\n', [block_start, block_end, block_dur, block_start_TBV_TR, block_end_TBV_TR, block_end_TBV_TR-block_start_TBV_TR+1]);
    
    % BLANK
    BlankOut(1, feedback_dir, feedback_file_name);

    %----------------------------------------------------------------------
    %% End of run
    save([saveroot 'run_' num2str(run_no) '_rest_mean_values.mat'],'rest_blocks_mean');
    save([saveroot 'run_' num2str(run_no) '_TR_PSC_values.mat'],'ROI_PSC');
    
%     Text = ['Well done! \n You have completed the session. \n \n Press `escape` to exit :)'];
%     [cue_start,cue_end,cue_dur,cue_start_TR,cue_end_TR,cue_start_TBV_TR,cue_end_TBV_TR] = WriteInstruction(Text,magenta,cue_dur_TR-2,feedback_dir,feedback_file_name);
%     cue_timings = [cue_timings;cue_start,cue_end,cue_dur,cue_start_TBV_TR,cue_end_TBV_TR,cue_end_TBV_TR-cue_start_TBV_TR+1];
%     fprintf(fileID1,'%f  %f  %f  %f  %f  %f\n\n',[cue_start,cue_end,cue_dur,cue_start_TBV_TR,cue_end_TBV_TR,cue_end_TBV_TR-cue_start_TBV_TR+1]);
    
    Total_run_duration = cue_start; %secs
    fprintf(fileID1, '\nTotal MRI run duration (s): \t\t%.2f \n', Total_run_duration); 
    fprintf(fileID2, '\nTotal MRI run duration (s): \t\t%.2f \n', Total_run_duration); 
    
    
    save([saveroot 'run_' num2str(run_no) '_workspace.mat']);
    
    %----------------------------------------------------------------------
%     % To enable exit by pressing escape
%     while(1)
%         [pressed,when,keyCode,delta] = KbCheck([-1]);
%         if pressed
%             if keyCode(1,escapeKey)  %waits for escape from experimenter to close
%                 KbQueueRelease();
%                 sca;
%                 ShowCursor; %show mouse cursor
%                 break;
%             else
%                 continue;
%             end
%         end
%     end

catch 
    sca;
    ShowCursor; %show mouse cursor
    psychrethrow(psychlasterror); %print error message to command window
end

% Close all open files 
fclose(fileID1);
fclose(fileID2);

% Close the Psychtoolbox window and show the cursor
sca;
ShowCursor;

%% FUNCTIONS

function PrintGeneralInfo(ID,d,name,rn,nb,bl)
% Writes general info for each participant session into text file
%
%ID - file ID
%d - date
%name - participant's name
%rn - run number
%nb - number of block sets (each block set = 3 meditation + 3 feedback
% + 1 rest trials
%bl - block length (in TR)

fprintf(ID, '\n============================================================================\n');
fprintf(ID, '\n______________________________General info:________________________________');
fprintf(ID, '\nDate of experiment: \t%s', d);
fprintf(ID, '\nParticipant Name: \t\t\t%s', name);
fprintf(ID, '\nRun number: \t\t%d', rn);
fprintf(ID, '\nNumber of Block sets per run: \t\t%d', nb);
fprintf(ID, '\nBlock Length [TR]: \t\t%f', bl);
end

%%%%%%%%%%%%%% Modified WriteInstruction function %%%%%%%%%%%%%%

function [co, ce, cdur, block_start_tr, block_end_tr, block_start_tbv_tr, block_end_tbv_tr] = WriteInstruction(instruction, colour, num_trs, folder_path, file_prefix)
    % Writes instructions on the screen for a specified duration, adjusting font size to fit the window.

    % Global Variables
    global window start_time current_TBV_tr TR windowHeight %%windowheight added

    % Outputs
    co = GetSecs() - start_time;           % Instruction onset time (in seconds)
    block_start_tr = round(co / TR) + 1;   % Instruction onset time (in TRs)
    block_start_tbv_tr = current_TBV_tr;   % Instruction onset TR from TheBrainVoyager
    
    % Text Properties
    Screen('TextSize', window, round(windowHeight * 0.05));  % Dynamic font size (5% of window height)
    Screen('TextFont', window, 'Arial');                    % Set font to Arial
    Screen('TextStyle', window, 0);                         % Normal text style
    
    % Text Wrapping and Display
    wrapAt = 80;                                     % Wrap text at 80 characters 
    vSpacing = 1.5;                                   % Line spacing 
    DrawFormattedText(window, instruction, 'center', 'center', colour, wrapAt, [], [], vSpacing); % Wrap and center text
    Screen('Flip', window);

    % Wait for Instruction Duration
    elapsed = (GetSecs() - start_time) - co;
    while elapsed < (num_trs * TR)
        current_TBV_tr = rt_load_BOLD(folder_path, file_prefix);
        ce = GetSecs() - start_time;                % Instruction end time (in seconds)
        elapsed = ce - co;
    end

    % Outputs
    cdur = elapsed;                            % Instruction duration (in seconds)
    block_end_tr = round(ce / TR);            % Instruction end time (in TRs)
    block_end_tbv_tr = current_TBV_tr;         % Instruction end TR from TheBrainVoyager
end


%%%%%%%%%%%%%%%%%%%%%%

function BlankOut(num_trs,folder_path,file_prefix)
% Shows a blank screen for a specified duration

%INPUTS
%num_trs - duration to display blank screen (in TR)
%folder_path - path to the feedback folder
%file_prefix - name of feedback file

global window current_TBV_tr start_time TR

starting = GetSecs() - start_time;
Screen('Flip',window);
current_TBV_tr = rt_load_BOLD(folder_path,file_prefix);
elapsed = (GetSecs() - start_time) - starting;
while elapsed < (num_trs*TR)
    current_TBV_tr = rt_load_BOLD(folder_path,file_prefix);
    elapsed = (GetSecs() - start_time) - starting;
end

end

%%%%%%%%%%%%%%%%%%%%%%

function [bo,be,bdur,block_start_tr,block_end_tr,block_start_tbv_tr,block_end_tbv_tr] = DrawFixationCross(colour,num_trs,folder_path,file_prefix)
% Draws a fixation cross for specified duration

%INPUTS
%colour - colour of fixation cross to display
%num_trs - duration to keep the cross on display (in TR)
%folder_path - path to the feedback folder
%file_prefix - name of feedback file

%OUTPUTS
%bo - onset time of fixation block (in s)
%be - end time of fixation block (in s)
%bdur - duration of fixation block (in s)
%block_start_tr - onset of cue on screen (in TR)
%block_vals - fMRI data from block (for each TR)

global TR window scr_rect centreX centreY start_time current_TBV_tr

bo = GetSecs() - start_time;
rect1_size = [0 0 scr_rect(4)/20 scr_rect(3)/4];
rect2_size = [0 0 scr_rect(3)/4 scr_rect(4)/20];
rect_color = colour;
rect1_coords = CenterRectOnPointd(rect1_size, centreX, centreY);
rect2_coords = CenterRectOnPointd(rect2_size, centreX, centreY);
Screen('FillRect',window,repmat(rect_color,[3,2]),[rect1_coords',rect2_coords']);
Screen('Flip',window);
current_TBV_tr = rt_load_BOLD(folder_path,file_prefix);
block_start_tbv_tr = current_TBV_tr;
block_start_tr = round(bo/TR)+1;
elapsed = (GetSecs() - start_time) - bo;
while elapsed < (num_trs*TR)
    current_TBV_tr = rt_load_BOLD(folder_path,file_prefix);
    be = GetSecs() - start_time;
    elapsed = be - bo;
end
bdur = elapsed;
block_end_tr = round(be/TR);
block_end_tbv_tr = current_TBV_tr;
end

%%%%%%%%%%% Modified Meditation_feedback function %%%%%%%%%%%

% % Draws feedback image for specified duration
% 
% %INPUTS
% %num_trs - duration to keep the cross on display (in TR)
% %folder_path - path to the feedback folder
% %file_prefix - name of feedback file
% 
% %OUTPUTS
% %bo - onset time of fixation block (in s)
% %be - end time of fixation block (in s)
% %bdur - duration of fixation block (in s)
% %block_start_tr - onset of cue on screen (in TR)
% %block_vals - fMRI data from block (for each TR)
 

function [bo, be, bdur, block_start_tr, block_end_tr, block_start_tbv_tr, block_end_tbv_tr, image_onsets, image_durations, image_offsets] = Craving_feedback(num_trs, folder_path, file_prefix, imageTextures, imageDurationSecs, fileID3)  
    global window start_time current_TBV_tr TR windowHeight FB_timings

    bo = GetSecs() - start_time;
    block_start_tr = round(bo / TR) + 1;
    block_start_tbv_tr = current_TBV_tr;
    image_onsets = [];
    image_durations = [];
    image_offsets = [];

    % Task loop 
    for imageIndex = 1:numel(imageTextures)
        imageStartTime = GetSecs();
        temp=0;
            while GetSecs() - imageStartTime < imageDurationSecs
               
                current_TBV_tr = rt_load_BOLD(folder_path, file_prefix);
                
                if current_TBV_tr - temp > 0

                feedback_num = calculate_feedback();  % Get feedback (0-1)
                score = round(feedback_num * 19) + 1;  % Scale to 1-20
                temp = current_TBV_tr;
                end

              
                % If FB_timings is empty, initialize it with both timestamp and score
                if isempty(FB_timings) || floor(GetSecs() - start_time) > floor(FB_timings(end, 1)) 
                        FB_timings(end+1, :) = [GetSecs() - start_time, score];
                end
                   
            
                [windowWidth, windowHeight] = Screen('WindowSize', window);
                newImageWidth = windowWidth * 0.5;  
                newImageHeight = windowHeight * 0.5;
                dstRect = CenterRectOnPoint([0 0 newImageWidth newImageHeight], windowWidth / 2, windowHeight / 2);
                % Draw Image
                DrawFeedbackImage(imageTextures, imageIndex, dstRect);
                % Draw Score Bar
                DrawFeedback(score);  % Draw the score bar 
                
        end 
        Screen('Flip', window); 
        image_offsets(end+1) = GetSecs() - start_time; % Record image offset relative to block start
        image_durations(end+1) = imageDurationSecs;
        image_onsets(end+1) = image_offsets(end) - image_durations(end);
        % Write to the image timing file
        fprintf(fileID3, '%.2f        %.2f          %.2f\n', image_onsets(end), image_offsets(end), image_durations(end));

    end 

    be = GetSecs() - start_time;
    bdur = be - bo;
    block_end_tr = round(be / TR);
    block_end_tbv_tr = current_TBV_tr;
end
%%%%%%%%%%%%%%%%%
function [bo, be, bdur, block_start_tr, block_end_tr, block_start_tbv_tr, block_end_tbv_tr, image_onsets2, image_durations2, image_offsets2] = Craving_feedback2(num_trs, folder_path, file_prefix, imageTextures2, imageDurationSecs, fileID4)  
    global window start_time current_TBV_tr TR windowHeight FB_timings
        bo = GetSecs() - start_time;
        block_start_tr = round(bo / TR) + 1;
        block_start_tbv_tr = current_TBV_tr;
        image_onsets2 = [];
        image_durations2 = [];
        image_offsets2 = [];
      
        % Task loop 
        for imageIndex2 = 6:numel(imageTextures2)
        imageStartTime = GetSecs();
        temp=0;
            while GetSecs() - imageStartTime < imageDurationSecs
               
                current_TBV_tr = rt_load_BOLD(folder_path, file_prefix);
                               
                if current_TBV_tr - temp > 0

                feedback_num = calculate_feedback();  % Get feedback (0-1)
                score = round(feedback_num * 19) + 1;  % Scale to 1-20
                temp = current_TBV_tr;
                end
               
% If FB_timings is empty, initialize it with both timestamp and score
                if isempty(FB_timings) || floor(GetSecs() - start_time) > floor(FB_timings(end, 1)) 
                        FB_timings(end+1, :) = [GetSecs() - start_time, score];
                end
                   
                [windowWidth, windowHeight] = Screen('WindowSize', window);
                newImageWidth = windowWidth * 0.5;  
                newImageHeight = windowHeight * 0.5;
                dstRect = CenterRectOnPoint([0 0 newImageWidth newImageHeight], windowWidth / 2, windowHeight / 2);
                % Draw Image
                DrawFeedbackImage2(imageTextures2, imageIndex2, dstRect);
                % Draw Score Bar

                DrawFeedback(score);  % Draw the score bar 

            end 
            Screen('Flip', window); 
            image_offsets2(end+1) = GetSecs() - start_time; % Record image offset relative to block start
            image_durations2(end+1) = imageDurationSecs;
            image_onsets2(end+1) = image_offsets2(end) - image_durations2(end);
            fprintf(fileID4, '%.2f        %.2f          %.2f\n', image_onsets2(end), image_offsets2(end), image_durations2(end));  % Use image_onsets2 and image_durations2
        end 
        be = GetSecs() - start_time;
        bdur = be - bo;
        block_end_tr = round(be / TR);
        block_end_tbv_tr = current_TBV_tr;
    end

%%%%%%%%%%%%%%%%%%%%
function DrawFeedbackImage2(imageTextures2, imageIndex2, dstRect)
    global window imageTextures2 
    % Set opacity to 0.7 (highlighted line)
    Screen('DrawTexture', window, imageTextures2(imageIndex2), [], dstRect, [], [], 0.7); 

end
%%%%%%%%%%%%%%%%%%%%

function DrawFeedbackImage(imageTextures, imageIndex, dstRect)
    global window imageTextures 
    % Set opacity to 0.7 (highlighted line)
    Screen('DrawTexture', window, imageTextures(imageIndex), [], dstRect, [], [], 0.7); 

end

%%%%%%%%%%%%%%%%%%%%
function rect_num = DrawFeedback(score)  
    global window scr_rect centreX centreY windowHeight 
    
    x_size = scr_rect(3)/15;
    y_size = scr_rect(4)/60; 
    rect_size = [0 0 x_size y_size];
    rect_color = [255 0 255]; 

    % Adjust these values to control the bar's position relative to the image
    barOffsetX = x_size*5;      % Move the bar right (+) or left (-)
    barOffsetY = 0;     % Move the bar down (+) or up (-)

    all_rect_coords = zeros(4,20);
    rect_start_pos = -10;
    for i=1:20
        rect_coords = CenterRectOnPointd(rect_size, centreX + barOffsetX, centreY + barOffsetY - ((i+rect_start_pos-1)*y_size));  % Apply offset
        all_rect_coords(:,i) = rect_coords';
    end

    centre_line_pos = [centreX + barOffsetX - (0.75*rect_size(3)), centreX + barOffsetX + (0.75*rect_size(3)); centreY + barOffsetY - ((rect_start_pos+9)*y_size)-(0.5*rect_size(4)), centreY + barOffsetY - ((rect_start_pos+9)*y_size)-(0.5*rect_size(4))];

    % Fill rectangles with green based on current feedback value
    Screen('FillRect',window,repmat(rect_color',[1,score]),all_rect_coords(:,1:score));

    % Drawing frames for all 20 rectangles
    Screen('FrameRect',window,255,all_rect_coords,ones(20,1)*1.5);

    % Drawing the centre line on the feedback frame
    Screen('DrawLines',window,centre_line_pos,2,200);

    % Writing text on screen
    Screen('TextSize',window,round(windowHeight * 0.03));
    Screen('TextFont',window,'Arial');
    Screen('TextStyle',window,0);
    TextColor = 255;
    label_1 = '  High Craving';
    label_2 = '  Low Craving';
    label_1_color = [0 255 0];
    label_2_color = [255 0 0];
    label_1_pos = [centreX + barOffsetX - x_size, centreY - ((rect_start_pos+21)*y_size)]; % Adjusted to the left
    label_2_pos = [centreX + barOffsetX - x_size, centreY - ((rect_start_pos-3)*y_size)]; % Adjusted to the right
    Screen('TextSize',window,round(windowHeight * 0.03));
    DrawFormattedText(window, label_1, label_1_pos(1), label_1_pos(2), label_1_color); 
    DrawFormattedText(window, label_2, label_2_pos(1), label_2_pos(2), label_2_color);
    % Flip the screen to display the changes
    Screen('Flip',window); 
%     FB_timings(end+1) = GetSecs() - start_time;  % Append the current time to FB_timings
%     FB_timings = FB_timings';
%     % Check if the number of filled rectangles has changed
%     if isempty(FB_timings) 
%         % If FB_timings is empty, initialize it with both timestamp and score
%         FB_timings = [GetSecs() - start_time, score];  % Initialize as a 1-by-2 row vector
%     end
%     %elseif score ~= FB_timings(end, 2)  % Check the second column for the score
%         % If the score has changed, append a new timestamp and the new score as a new row
%          FB_timings(end+1, :) = [GetSecs() - start_time, score]; 
%     %end
end

%%%%%%%%%%%%%%%%

function curr_tr = rt_load_BOLD(folder_path,file_prefix)
% Reads the most recent update in the feedback folder and updates the
% current TR (in a real-time scenario)

%For simulation, it just proceeds to the next TR

%INPUTS
%folder_path - path to the feedback folder
%file_prefix - name of feedback file

%OUTPUTS
%curr_tr - the current/present TR in TBV

global ROI_vals start_time TR port_issue baseline_lag_dur all_vals all_conf_vals

curr_time = GetSecs()-start_time;
curr_tr = round(curr_time/TR);
folder_dir = dir(folder_path);
feedback_filenames = {folder_dir(3:end).name}';
file_numbers = regexp(feedback_filenames,'[\d\.]+','match'); %getting all the numbers in filenames as cell array
TBV_tr_values = unique(sort(str2double([file_numbers{:}]'))); %sorted vector

%current TR value based on the most recent TBV feedback file that came in
curr_tbv_tr = TBV_tr_values(end);
prev_tbv_tr = size(ROI_vals,1);


% source flag --> 0 for current upload, 1 for upload from previous TBV TR, 2
% for copying from previous TBV entry (no direct upload)

if (curr_tbv_tr>prev_tbv_tr) && (curr_tbv_tr>0) && (curr_tr>0)
    tic;
    try %loading feedback info into temp1 (based on TBV output updates)
        temp1 = load([folder_path '\' file_prefix '-' num2str(curr_tbv_tr) '.rtp']);
        temp2 = temp1(1,2); %current ROI psc value in temp2
        temp3 = temp1(1,end); %condition
        conf = temp1(1,3); %confound signal PSC
        source_flag = 0;

        % Print the loaded data
            fprintf('Loaded data: temp2 = %f, temp3 = %f, conf = %f\n', temp2, temp3, conf);

        
    catch %storing previous values (based on TBV output updates) due to error in accessing most recent output file
        port_issue = [port_issue;curr_tbv_tr,curr_tr];
        try
            %Re-loading previous feedback file info into temp1
            temp1 = load([folder_path '\' file_prefix '-' num2str(prev_tbv_tr) '.rtp']);
            temp2 = temp1(1,2); %current ROI psc value in temp2
            temp3 = temp1(1,end); %condition
            conf = temp1(1,3); %confound signal PSC
            source_flag = 1;
            
            if curr_tbv_tr>1
                ROI_vals(prev_tbv_tr,1:2) = [temp2,conf]; % Updating previous entry as well
                ROI_vals(prev_tbv_tr,5) = temp3;
            end
            
        catch
            %This is in case the previous file is also not accessible
            temp2 = ROI_vals(prev_tbv_tr,1);
            temp3 = ROI_vals(prev_tbv_tr,5);
            conf = ROI_vals(prev_tbv_tr,2);
            source_flag = 2;
        end
    end
    elapsed = toc;

    % Print the final ROI_vals entry
        fprintf('ROI_vals entry: ');
        disp( [temp2, conf, curr_tbv_tr, curr_time, temp3, elapsed, curr_tr, source_flag] );

        % Print values after updating ROI_vals
        fprintf('After processing: curr_tbv_tr = %d, prev_tbv_tr = %d, size(ROI_vals, 1) = %d\n', ...
            curr_tbv_tr, prev_tbv_tr, size(ROI_vals, 1));

    %Main matrix containing PSC and other values
    ROI_vals(curr_tbv_tr,:) = [temp2,conf,curr_tbv_tr,curr_time,temp3,elapsed,curr_tr,source_flag];
    
end

end

%%%%%%%%%%%

function curr_feedback = calculate_feedback()
% Calculates and returns the feedback value

%INPUTS
%medtrial_start - onset of meditation trial (in MRI TR)

%OUTPUTS
%curr_feedback - feedback value (between 0.1 and 1) for the current TR

global ROI_PSC PSC_thresh ROI_vals current_TBV_tr temp2 conf 

baseline_lag_dur = 12; % all calculations to start after these many TRs at the beginning of run

%ALL BOLD PSC values from dynamic ROI
all_vals = ROI_vals(baseline_lag_dur:end,1); %Taking all the BOLD values so far, for cumulative GLM
%considering the initial lag

%All confound PSC from confound ROI mask
all_conf_vals = ROI_vals(baseline_lag_dur:end,2); %Taking all the confound mask values so far, for cumulative GLM

%Cumulative GLM - Regressing out detrended and demeaned confound from ROI so far
[beta,~,stats] = glmfit(all_conf_vals-mean(all_conf_vals),all_vals);
resid_BOLD = stats.resid + beta(1);

current_psc = resid_BOLD(end);
current_conf = all_conf_vals(end);

%Feedback value:
%Higher negative feedback value implies greater deactivation
%Converting negative feedback value to positive feedback value in the
%barpsc
% 0 and +ve PSC = feedback value of 1
% -ve PSC = feedback value above 1

curr_feedback = round((current_psc/PSC_thresh),2); 

%First term in ROI_PSC is unaffected by changing PSC threshold setting
%(direct from TBV)
%Second term is affected due to changing PSC threshold
ROI_PSC = [ROI_PSC;current_psc,curr_feedback,current_conf,current_TBV_tr]; %first and last TRs used for calculation


if curr_feedback<0.01
    curr_feedback=0.01;
elseif curr_feedback>1
    curr_feedback=1;
end
end

%%%%%%%%%%%%%%%%%%%%%%Likert Function%%%%%%%%%%%%%%
function [block_start, block_end, block_dur, block_start_TR, block_end_TR, block_start_TBV_TR, block_end_TBV_TR, rating] = likert_scale(window, scr_rect, instructionText, feedback_dir, feedback_file_name)
    global start_time current_TBV_tr TR

    % Parameters
    scaleMin = 0;
    scaleMax = 10;
    scaleStep = 1;
    scaleDuration = 10; % Duration in seconds before the scale closes automatically
    markerColor = [255, 0, 0]; % Red marker
    markerWidth = 20;
    scaleColor = [255, 255, 255]; % Scale color is white
    textColor = [255, 255, 255]; % Text color is white
    textSize = scr_rect(4) * 0.03; % Text size as 5% of the screen height
    smallTextSize = textSize; % Smaller text size for numbers and labels

    % Get the starting time of the block
    block_start = GetSecs() - start_time;
    block_start_TR = round(block_start / TR) + 1;
    block_start_TBV_TR = current_TBV_tr;

    % Set the text size ONCE before drawing anything (this is the fix!)
    Screen('TextSize', window, textSize); 

    % Draw the instruction text
    DrawFormattedText(window, instructionText, 'center', scr_rect(4) * 0.3, textColor);

    % Scale parameters
    scaleLength = scr_rect(3) * 0.5; % 50% of the screen width
    scaleHeight = scr_rect(4) * 0.03; % Height of the scale line as 3% of screen height
    scaleX = (scr_rect(3) - scaleLength) / 2; % Center the scale horizontally
    scaleY = scr_rect(4) * 0.6; % Y position of the scale

    % Calculate label positions
    labelOffsetX = scr_rect(3) * 0.1; % Offset for the labels from the scale
    labelOffsetY = -12; % Offset for the labels from the scale
    label1X = scaleX - labelOffsetX - 2;
    label1Y = scaleY - labelOffsetY;
    label2X = scaleX + scaleLength + 4;
    label2Y = scaleY - labelOffsetY;

    % Draw the scale
    Screen('FillRect', window, scaleColor, [scaleX, scaleY, scaleX + scaleLength, scaleY + scaleHeight]);

    for i = 0:10
        DrawFormattedText(window, num2str(i), scaleX + (i / 10) * scaleLength - 10, scaleY + scaleHeight + scr_rect(4) * 0.06, textColor);
    end

    % Draw the craving labels with smaller text size
    DrawFormattedText(window, 'No Craving', label1X, label1Y, textColor);
    DrawFormattedText(window, 'High Craving', label2X, label2Y, textColor);

    % Initial rating position
    rating = (scaleMin + scaleMax) / 2; % Start in the middle of the scale
    ratingPosition = scaleX + ((rating - scaleMin) / (scaleMax - scaleMin)) * scaleLength;

    % Display the Likert scale and capture user responses
    startTime = GetSecs();
    countdownDuration = 10; % Countdown from 10 seconds
    countdownStartTime = GetSecs();

    while GetSecs() - startTime < scaleDuration
        % Draw the scale
        current_TBV_tr = rt_load_BOLD(feedback_dir, feedback_file_name);
        %calculate_feedback();
        Screen('FillRect', window, scaleColor, [scaleX, scaleY, scaleX + scaleLength, scaleY + scaleHeight]);

        % Draw the rating marker
        Screen('FillRect', window, markerColor, [ratingPosition - markerWidth/2, scaleY - scaleHeight/2, ratingPosition + markerWidth/2, scaleY + scaleHeight * 1.5]);

        % Draw the instruction text
        DrawFormattedText(window, instructionText, 'center', scr_rect(4) * 0.3, textColor);

        % Draw the numbers and labels again
        for i = 0:10
            DrawFormattedText(window, num2str(i), scaleX + (i / 10) * scaleLength - 10, scaleY + scaleHeight + scr_rect(4) * 0.06, textColor);
        end
        DrawFormattedText(window, 'No Craving', label1X, label1Y, textColor);
        DrawFormattedText(window, 'High Craving', label2X, label2Y, textColor);

        % Display countdown if within countdownDuration
        if GetSecs() - countdownStartTime < countdownDuration
            remainingTime = ceil(countdownDuration - (GetSecs() - countdownStartTime));
            countdownText = sprintf('%d', remainingTime);
            % Adjust the vertical position of the countdown
            countdownY = scr_rect(4) * 0.45;  % Position it slightly above the center
            DrawFormattedText(window, countdownText, 'center', countdownY, textColor); % Center the countdown text
        end

        % Flip the screen
        Screen('Flip', window);

        % Check for key presses
        [keyIsDown, ~, keyCode] = KbCheck;

        if keyIsDown
            if keyCode(KbName('LeftArrow'))
                rating = max(rating - scaleStep, scaleMin);
            elseif keyCode(KbName('RightArrow'))
                rating = min(rating + scaleStep, scaleMax);
            end
            % Update rating position
            ratingPosition = scaleX + ((rating - scaleMin) / (scaleMax - scaleMin)) * scaleLength;
        end

        % Brief pause to prevent excessive CPU usage
        WaitSecs(0.1);
    end

    % Get the ending time of the block
    block_end = GetSecs() - start_time;
    block_dur = block_end - block_start;
    block_end_TR = round(block_end / TR);
    block_end_TBV_TR = current_TBV_tr;

    % Store ONLY the response time and the rating
    pp_no = 1; 
    saveroot = [pwd '\Participant_' num2str(pp_no) '\'];
    dlmwrite([saveroot '/' 'Participant_' num2str(pp_no) '-likert.txt'], [block_end, rating], '-append', 'delimiter', ' '); 
end
