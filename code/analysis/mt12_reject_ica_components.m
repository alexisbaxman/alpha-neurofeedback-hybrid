%% mt12_reject_ica_components
% Removes artifact components from the ICA decomposition computed in mt11,
% using ICLabel-based automatic rejection.
% Author: Alexis Olguin Baxman
% Date: 16.10.2026

clear all; close all; clc; beep off

disp('mt12: after ica')

paths.main     = 'C:\Users\Leonie\Documents\mt';
paths.lib = [paths.main, '\libs']; addpath(paths.lib);
paths.script = [paths.main, '\code\analysis'];
paths.derivatives = [paths.main, '\derivatives\mt12'];
paths.in = [paths.main, '\derivatives\mt11']; % to upload the output from the previous script
cd(paths.script)

if exist(paths.derivatives) == 0
    mkdir(paths.derivatives)
end


knob.debugging =0; % 0 no, 1 yes

% ring buffer
ring.srate = 250; % 512 debugging data, in lab no clue
ring.chunksize = 100; % desired amount of samples per chunk
ring.stability = ring.chunksize / ring.srate; % for pauses
ring.window = 4; % seconds for sliding window; fredercik = 150
ring.buffsize = ring.window* ring.srate; % number of chunks per buffer for the window
ring.nhb = round(4 / ring.stability); % neighbours for the moving average
ring.weights = linspace(1,2, ring.nhb); % create a linear weight vector
ring.weights = ring.weights/sum(ring.weights); % normalize the weights

% aesthetic
aes.red = [1 0.4 0.4];
aes.orange = [0.8500 0.3250 0.0980]	;
aes.blue = [0 0.4470 0.7410]	;
aes.green = [0.1 0.6 0.1];
aes.purple = [0.4940 0.1840 0.5560];
aes.grey = [0.3 0.3 0.3];
aes.white = [1 1 1];
aes.clear_purple = [0.7940 0.4840 0.8560];
aes.clear_grey = [0.8 0.8 0.8];
aes.dark_blue = [0.1010 0.4450 0.6330];
aes.clear_grey = [0.8 0.8 0.8];
aes.thick = 2;
aes.thin = 1;


% to choose participants
subs = readtable([paths.main, '\participants.tsv'], "FileType","text",'Delimiter', '\t');


%% for loop
for p = 1:length(subs.participant_id) % 13
    if strcmp(subs.INCLUDE{p}, 'Yes')
        disp(' ')
        disp(' ')
        disp(' ')
        disp(subs.participant_id{p})

        % create folder for participant
        paths.out = [paths.derivatives, '\', subs.participant_id{p}];
        if ~exist(paths.out, 'dir')
            mkdir(paths.out);
        end

        [ALLEEG EEG CURRENTSET ALLCOM] = eeglab; % i guess it will open every single time

        %% loading .set/.fdt files

        % we load the file with the icaweights
        file = [paths.in, '\', subs.participant_id{p}, '\', subs.participant_id{p}, '_pre_ica.set'];
        EEG = pop_loadset(file);

        EEG.setname = 'before ICA removal';
        CURRENTSET = 1;
        [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);


        % find channel dynamicly in case some channel was rejected
        channel.O2 = find(strcmpi({EEG.chanlocs.labels}, 'O2'));

        %% remove bad components: 
        EEG = iclabel(EEG, 'default');
        EEG = pop_icflag(EEG, [NaN NaN; 0.7 1; 0.7 1; 0.7 1; 0.7 1; 0.7 1; 0.7 1]);
        % we can also remove brain < 0.2        
        EEG.badICs = find(EEG.reject.gcompreject);

        %% remove bad ICs
        EEG = pop_subcomp(EEG, EEG.badICs, 0);
        %    EEG = eeg_checkset(EEG);
        EEG = eeg_checkset(EEG, 'ica');

        EEG.setname = 'after ICA removal';
        CURRENTSET = 2;
        [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);

        % saving dataset with badcomponents removed
        switch knob.debugging
            case 0
                EEG = pop_saveset(EEG, [subs.participant_id{p},'_post_ica.set'], paths.out);
        end

        
        

    end % if-loop
end % for-loop


disp('done!')



