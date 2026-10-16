%% mt1_load_participant
% Basic loading script, it loads all variables of a given dataset (choose
% subject at line 10), including the .xdf file and separates the cells into
% different variables. It also has many of the hardcoded variables, such as
% the variables of the ring buffer and triggers in the Event Markers (EM).
% Author: Alexis Olguin Baxman
% Date: 16.10.2026

close all; clear; clc; beep off;
disp('starting loading')

% PATHS
paths.main     = 'C:\Users\Leonie\Documents\mt';
paths.lib = [paths.main, '\libs'];
paths.save = [paths.main, '\figure'];
paths.script = [paths.main, '\code\analysis'];

subject = 'sub-31'; % choose which participant
paths.in = fullfile(paths.main, subject, 'eeg')

% LIBS
% addpath(genpath([paths.lib, '\liblsl-Matlab'])); % for lsl
% lib = lsl_loadlib();
% %javaaddpath([paths.lib, '\netutil-1.0.0.jar']); % outlet
% addpath([paths.lib]) % for send_osc and load_xdf


if ~exist('ALLEEG', 'var')
    eeglab;
end

%% channel variables
channel{1} = 'O2';
channel{2} = 10; % O2 channel is 10
disp(['Channel ', channel{1}, '. Index: ', num2str(channel{2})])

% ring buffer structure
ring.srate = 250; % sampling rate
ring.chunksize = 100; % desired amount of samples per chunk
ring.stability = ring.chunksize / ring.srate; % for pauses
ring.window = 4; % seconds for sliding window; fredercik = 150
ring.buffsize = ring.window* ring.srate; % number of chunks per buffer for the window
tdex = 1; % THE counter
ring.nhb = round(4 / ring.stability); % neighbours for the moving average
ring.weights = linspace(1,2, ring.nhb); % create a linear weight vector
ring.weights = ring.weights/sum(ring.weights); % normalize the weights


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

%% LOADING SESSION
files = dir(fullfile(paths.in, '*.xdf'));
disp(['loading session... ', files.name])
demo = load_xdf(fullfile(paths.in, files.name));


%% ORGANIZATION 
% search for the name of the streams in the xdf file and separates the
% content in different variables
disp('organizing streams')
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

%% LOADING DATA

name.chunks = [files.name(1:end-7), 'chunksize.mat'];
name.bl = [files.name(1:end-7), 'bl.mat'];
name.score = [files.name(1:end-7), 'score_fixed.mat'];
name.storage = [files.name(1:end-7), 'storage.mat'];
name.task = [files.name(1:end-7), 'task.mat'];
name.thres = [files.name(1:end-7), 'thres.mat'];
name.trial = [files.name(1:end-7), 'trial.mat'];

% load chunksize

if exist([paths.in, '\', name.chunks ], 'file')
    disp(['loading... ', name.chunks ])
    load([paths.in, '\', name.chunks ])
end

% load baseline
if exist([paths.in, '\', name.bl ], 'file')
disp(['loading... ', name.bl ])
load([paths.in, '\', name.bl ])
end

if exist([paths.in, '\', name.score ], 'file')
disp(['loading score... ', name.score ])
load([paths.in, '\', name.score ])
end

if exist([paths.in, '\', name.storage ], 'file')
disp(['loading storage... ', name.storage ])
load([paths.in, '\', name.storage ])
end

if exist([paths.in, '\', name.task ], 'file')
disp(['loading task... ', name.task ])
load([paths.in, '\', name.task ])
end

if exist([paths.in, '\', name.thres ], 'file')
disp(['loading thres... ', name.thres ])
load([paths.in, '\', name.thres ])
end

if exist([paths.in, '\', name.trial ], 'file')
disp(['loading trial... ', name.trial ])
load([paths.in, '\', name.trial ])
end

disp(' ')
disp('mt0 fertig')

