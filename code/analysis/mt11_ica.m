%% mt11_ica
% This script includes the following steps: importing rawdata, reading
% chanlocs, filtering (1, 40), screening for bad channels, creating "fake
% epochs", epoching to fake epochs, running ICA, reloading the raw data and
% saving it with the icaweights.
% Author: Alexis Olguin Baxman
% Date: 16.10.2026
% Reference: Stropahl et al. (2018). Source-Modeling Auditory Processes of EEG Data
% Using EEGLAB and Brainstorm 

clear all; close all; clc; beep off;

disp('mt11: running ica script')

paths.main     = 'C:\Users\Leonie\Documents\mt';
paths.lib = [paths.main, '\libs']; addpath(paths.lib);
paths.script = [paths.main, '\code\analysis'];
paths.derivatives = [paths.main, '\derivatives\mt11'];

if exist(paths.derivatives) == 0
    mkdir(paths.derivatives)
end

% paste here the path to your channel locaton
paths.chanlocs = [paths.lib, '\eeglab_current\eeglab2025.0.0\plugins\dipfit\standard_BEM\elec\standard_1020.elc'];

knob.plot = 0; % to plot or not optional figures

% bad channels
channel.thres = 2.5; %% criteria to find badchannels automatically
channel.num = 32; % i guess
channel.O2 = 10;

% filters and so on
filtro.low = 1; % high pass, removes below 1hz
filtro.high =40; % low üass, removes about 40Hz
filtro.low_order = 100;
filtro.high_order = 500;
filtro.causal = 1;

% to choose participants
subs = readtable([paths.main, '\participants.tsv'], "FileType","text",'Delimiter', '\t');


%% for loop
for p = 1:length(subs.participant_id) 
    if strcmp(subs.INCLUDE{p}, 'Yes')
        disp(' ')
        disp(' ')
        disp(' ')
        disp(subs.participant_id{p})

        % paths
        paths.in = fullfile(paths.main, subs.participant_id{p}, 'eeg\'); 
        paths.out = [paths.derivatives, '\', subs.participant_id{p}];
        if ~exist(paths.out, 'dir')
            mkdir(paths.out);
        end


        [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
        %files = [list(p).folder, '\', list(p).name, '\sub-P001_ses-S001_task-Default_run-001_eeg.xdf'];
        % [subs.participant_id{p}, '_task-neurofeedback_eeg.xdf']);
        files = [paths.in, subs.participant_id{p}, '_task-neurofeedback_eeg.xdf'];
        EEG = pop_loadxdf(files);

        switch knob.plot
            case 1
                figure;
                plot(EEG.data(10,:))
                title(subs.participant_id{p})
        end

        % channel location info
        %EEG.chanlocs= readlocs(fullfile(paths.lib, '32chan_locs.ced'));
        % EEG.chanlocs= readlocs('\\daten.w2kroot.uni-oldenburg.de\home\jofo2989\Documents\MATLAB\eeglab_current\eeglab2025.0.0\plugins\dipfit\standard_BEM\elec\standard_1020.ced')
        %EEG.chanlocs=pop_chanedit(EEG.chanlocs,  'load', {[MAIN,'config/elec_96ch.elp']});
        EEG = pop_chanedit(EEG,  'lookup', paths.chanlocs);


        EEG = eeg_checkset(EEG); % sanity check
        [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

        % apply low and high pass filter: 1 and 40 Hz
        EEG = pop_eegfiltnew(EEG, 'locutoff',filtro.low,'hicutoff',filtro.high, 'minphase',filtro.causal,'plotfreqz',0);

        [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

        switch knob.plot
            case 1
                figure;
                plot(EEG.data(10,:))
                title(subs.participant_id{p})
        end

        % screening for bad channels - Stefan's criteria
        channel.vari = std(EEG.data(1:channel.num,:),0,2); % calcualte std of every channel
        channel.crit = mean(channel.vari)+std(channel.vari)*channel.thres; % calculate critical variance
        channel.badc = find(channel.vari > channel.crit)'; % find the bad channels
        if ~isempty(channel.badc)
            EEG.badchannels = channel.badc;
        else
            EEG.badchannels=[];
        end

        % save original channels for interpolation
        % orig_chans = EEG.chanlocs;

        % remove badchannels
        EEG = pop_select(EEG, 'nochannel', EEG.badchannels);
        EEG = eeg_checkset(EEG);

        % interpolate missing channels
        % EEG = pop_interp(EEG, orig_chans, 'spherical');

        % Re-reference
        EEG = pop_reref(EEG, []);

        disp(' ')
        disp(' ')
        disp(' ')
        %% for epoching
        % create dummy events and epoch data to these dummy events
        EEG = eeg_regepochs(EEG, 'recurrence', 1, 'eventtype', '999');

        switch knob.plot
            case 1
                figure;
                plot(EEG.data(10,:,1))
                title(subs.participant_id{p})
        end

        EEG = eeg_checkset(EEG, 'eventconsistency');

        % flags strange epochs
        EEG = pop_jointprob(EEG, 1,[1:size(EEG.data,1)], 3, 3, 0, 1, 0);
        % EEG = pop_jointprob(EEG, typerej, elec_array, threshold_single, threshold_all, superpose, reject, display_flag)
        EEG = eeg_checkset(EEG);

        % make it double just to improve
        EEG.data = double(EEG.data);

        % running ICA with PCA
        EEG = pop_runica(EEG, 'icatype', 'runica', 'extended', 1, 'pca',size(EEG.data, 1));

        % saving ICA weigths in temporary variables
        icawinv=EEG.icawinv;
        icas=EEG.icasphere;
        icaw=EEG.icaweights;

        disp(' ')
        disp(' ')
        disp(' ')
        disp('ica done')


        %% re-load EEG original dataset
        disp(['re-loading raw dataset'])
        EEG = pop_loadxdf(files);
        eeglab redraw

        % channel location info
        % EEG.chanlocs= readlocs(fullfile(paths.lib, '32chan_locs.ced'));
        % EEG.chanlocs= readlocs('\\daten.w2kroot.uni-oldenburg.de\home\jofo2989\Documents\MATLAB\eeglab_current\eeglab2025.0.0\plugins\dipfit\standard_BEM\elec\standard_1005.ced')
        EEG =pop_chanedit(EEG,  'lookup', paths.chanlocs);

        % removing bad channels (again)
        if ~isempty(channel.badc)
            EEG.badchannels = channel.badc;
            EEG = pop_select(EEG, 'nochannel',EEG.badchannels); %removing badchannels
        end
        EEG = eeg_checkset(EEG);

        %     % filtering the data
        EEG = pop_eegfiltnew(EEG, 'locutoff',filtro.low,'hicutoff',filtro.high, 'minphase',filtro.causal,'plotfreqz',0);

        % apply low and high pass filter
        % EEG = pop_firws(EEG, 'fcutoff', filtro.low, 'ftype', 'lowpass', 'wtype', 'hann', 'forder', filtro.low_order);
        % EEG = pop_firws(EEG, 'fcutoff', filtro.high, 'ftype', 'highpass', 'wtype','hann', 'forder', filtro.high_order);


        % Re-reference
        EEG = pop_reref(EEG, []);

        % interpolate missing channels
        % EEG = pop_interp(EEG, orig_chans, 'spherical');

        %% exporting ica weights to filtered dataset
        EEG.icawinv=icawinv;
        EEG.icasphere=icas;
        EEG.icaweights=icaw;


        EEG = pop_saveset(EEG, [subs.participant_id{p},'_pre_ica.set'], paths.out);


        disp(' ')
        disp(' ')
        disp(' ')

    end % if-loop
end % for-loop
disp('mt11 fertig')
