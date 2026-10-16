%% mt10_time_estimates
% It calculates the time that all participants need to fullfill the
% different parts of the experiment
% Author: Alexis Olguin Baxman
% Date: 16.10.2026

close all; clear; clc; beep off;

paths.main     = 'C:\Users\Leonie\Documents\mt';
paths.lib = [paths.main, '\libs'];
addpath(paths.lib) % for violin
paths.script = [paths.main, '\code\analysis'];
paths.derivatives = [paths.main, '\derivatives\mt8'];

% to store all tables
T = struct();
counter = 0;

subs = readtable([paths.main, '\participants.tsv'], "FileType","text",'Delimiter', '\t');

eeglab;


%% EM triggers
trigger.issues = 9;

trigger.screen = 11; % everytime there's something on the screen
trigger.next = 12; % everytime the participant press space
trigger.end = 13; % end of the experiment

trigger.blon = 14; % baseline on
trigger.open = 15;
trigger.close = 16;
trigger.bloff = 17; % baseline off

trigger.exploration = 18; % start of alpha training
trigger.exploratioff = 19; % end of alpha traing

trigger.trial = 20; % new trial
trigger.experimental = 21; % experimental condition
trigger.control = 22; % control condition
trigger.break = 23; % signals the break
trigger.trainingon = 24; % starts the training
trigger.trainingoff = 25; % the training ends
trigger.refractoff = 29; % refractory time is over

trigger.son_on = 30;  % sonfication starts
trigger.son_off = 31; % sonification ends
trigger.mini_on = 33; % mini baseline activated
trigger.mini_off = 34; % mini baseline deactivated

trigger.reg = 40; % regulation task
trigger.upreg_on = 41; % evaluation starts: up-regulation
trigger.doreg_on = 42; % evaluation starts: down-regulation
trigger.upreg_off = 43; %   threshold reached: upregulation
trigger.doreg_off = 44; %   threshold reached: downregulation
trigger.reg_timeout = 45; % timeout regulation task, not specialized
trigger.reg_off = 46; % end of regulation task

trigger.disc = 50; % discrimination task
trigger.disc_on = 51; % evaluation starts: discrimination
trigger.disc_high = 52; % threshold reached: high alpha state
trigger.disc_low = 53; % threshold reached: low alpha state
trigger.disc_timeout = 54; % timeout discrimination task
trigger.disc_off = 55; % end of discrimination task

trigger.prompt = 60; % prompt jumps
trigger.response = 65; % participant press a key

trigger.th = 61; % correct answer: true high
trigger.tl = 62; % correct answer: true low
trigger.fh = 63; %incorrect answer: false high
trigger.fl = 64; %incorrect answer: false low
%%


for p = 1:length(subs.participant_id)
    if strcmp(subs.INCLUDE{p}, 'Yes')
        disp(['loading participant: ', subs.participant_id{p}])

        counter = counter+1;
        T.participants{counter} = subs.participant_id{p};

        paths.in = fullfile(paths.main, subs.participant_id{p}, 'eeg\', [subs.participant_id{p}, '_task-neurofeedback']);
        paths.file = '_eeg.xdf';
        demo = load_xdf([paths.in, paths.file]);

        % organize streams
        for idx = 1:length(demo)
            if strcmp(demo{1, idx}.info.name, 'AAAStream')
                AAA = demo{1, idx};
            elseif strcmp(demo{1, idx}.info.name, 'EMStream')
                EM = demo{1,idx};
            elseif strcmp(demo{1, idx}.info.name,  'EEG')
                EEG = demo{1,idx};
            elseif strcmp(demo{1, idx}.info.name, 'NFBStream')
                SONIC = demo{1,idx};
            end
        end
        clear idx

        %% from the beginning till the end
        sample.trainingoff = find(EM.time_series == trigger.trainingoff);
        sample.trials = find(EM.time_series == trigger.trial);
        sample.trials = sample.trials((sample.trials - sample.trainingoff) > 0);
        time.first_trial = EM.time_stamps(sample.trials(1));
        time.end = EM.time_stamps(EM.time_series == trigger.end);
        time.whole = time.end - time.first_trial;
        time.whole_minutes = time.whole / 60;
        T.whole(counter) = time.whole_minutes;

        %% block to block
        % trigger.reg --> trigger.reg

        sample.regs = find(EM.time_series == trigger.reg);
        sample.block1 = [sample.regs(1), sample.regs(2)-2]; % -2 is hardcoded to actually index the last participant answer 
        sample.block2 = [sample.regs(2), sample.regs(3)-2];
        sample.block3 = [sample.regs(3), sample.regs(4)-2];
        sample.block4 = [sample.regs(4), find(EM.time_series == trigger.end)];

        time.block1 = (EM.time_stamps(sample.block1(2)) - EM.time_stamps(sample.block1(1)))/60;
        time.block2 = (EM.time_stamps(sample.block2(2)) - EM.time_stamps(sample.block2(1)))/60;
        time.block3 = (EM.time_stamps(sample.block3(2)) - EM.time_stamps(sample.block3(1)))/60;
        time.block4 = (EM.time_stamps(sample.block4(2)) - EM.time_stamps(sample.block4(1)))/60;
        
        T.block1(counter) = time.block1;
        T.block2(counter) = time.block2;
        T.block3(counter) = time.block3;
        T.block4(counter) = time.block4;


    end % if-loop include participants
end % big for loop

%% final calculations

average.whole = mean(T.whole);
average.block1 = mean(T.block1);
average.block2 = mean(T.block2);
average.block3 = mean(T.block3);
average.block4 = mean(T.block4);
average.blocks = mean([average.block1, average.block2, average.block3, average.block4]);

dev.whole = std([T.whole]);
dev.block1 = std(T.block1);
dev.block2 = std(T.block2);
dev.block3 = std(T.block3);
dev.block4 = std(T.block4);
dev.blocks = mean([dev.block1,dev.block2, dev.block3, dev.block4 ]);



