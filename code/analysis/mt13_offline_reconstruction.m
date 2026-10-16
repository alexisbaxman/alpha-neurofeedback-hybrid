%% mt13_offline_reconstruction
% Offfline reconstruction of the online pipeline without the 4-second ring
% buffer structure to calculate the delay and amplitude difference with
% plotting.
% Author: Alexis Olguin Baxman
% Date: 16.10.2026

clear all; close all; clc; beep off

disp('start offline reconstruction')


paths.main     = 'C:\Users\Leonie\Documents\mt';
paths.lib = [paths.main, '\libs']; addpath(paths.lib);
paths.script = [paths.main, '\code\analysis'];
paths.derivatives = [paths.main, '\derivatives\mt13'];
paths.preprocessed = [paths.main, '\derivatives\mt12'];
cd(paths.script)

if exist(paths.derivatives) == 0
    mkdir(paths.derivatives)
end



knob.debugging = 0; % 0 = not debugging
knob.plot = 0;
minutes = 5; % window of time for the cross-correlation and normalized plot
knob.raw = 1; % 0 preprocessed ; 1 raw
knob.weight = 0; % applies weighted average as in the ring buffer

% ring variables
ring.srate = 250; % 512 debugging data, in lab no clue
ring.chunksize = 100; % desired amount of samples per chunk
ring.stability = ring.chunksize / ring.srate; % for pauses
ring.window = 4; % seconds for sliding window; fredercik = 150
ring.buffsize = ring.window* ring.srate; % number of chunks per buffer for the window
ring.nhb = round(4 / ring.stability); % neighbours for the moving average
ring.weights = linspace(1,2, ring.nhb); % create a linear weight vector
ring.weights = ring.weights/sum(ring.weights); % normalize the weights

% filter design
filtro.hco = 12; % 12
filtro.lco = 8; % 8
filtro.order = 104;
filtro.causal = 1;

% aesthetic
aes.orange = [0.8500 0.3250 0.0980]	;
aes.blue = [0 0.4470 0.7410]	;
aes.thick = 1.5;

% to choose participants
subs = readtable([paths.main, '\participants.tsv'], "FileType","text",'Delimiter', '\t');

% to store data across scripts
VAULT  = cell(1,length(subs.participant_id));

%% for loop
for p = 1:length(subs.participant_id) % 13
    if strcmp(subs.INCLUDE{p}, 'Yes')
        [ALLEEG EEG CURRENTSET ALLCOM] = eeglab; % i guess it will open every single time
        disp(' ')
        disp(' ')
        disp(' ')

        %% create paths
        paths.in = [paths.main, '\', subs.participant_id{p}, '\eeg\', subs.participant_id{p}, '_task-neurofeedback_'];
        paths.in_clean = [paths.preprocessed, '\', subs.participant_id{p}, '\'];
        paths.out = [paths.derivatives, '\', subs.participant_id{p}];

        if ~exist(paths.out, 'dir')
            mkdir(paths.out)
        end

        %% loading data
        % load raw xdf
        files = [paths.in, 'eeg.xdf'];
        demo = load_xdf(files);
        disp('organizing streams')
        for idx = 1:length(demo)
            if strcmp(demo{1, idx}.info.name, 'AAAStream')
                AAA = demo{1, idx};
                AAA.timevec = AAA.time_stamps - AAA.time_stamps(1);
                disp(['AAA duration: ', num2str(AAA.timevec(end)/60), ' minutes'])
            elseif strcmp(demo{1, idx}.info.name, 'EMStream')
                EM = demo{1,idx};
            elseif strcmp(demo{1, idx}.info.name, 'EEG')
                EEG_raw = demo{1,idx};
                EEG_raw.timevec = EEG_raw.time_stamps - EEG_raw.time_stamps(1);
                disp(['raw EEG duration: ', num2str(EEG_raw.timevec(end)/60), ' minutes'])
            end
        end
        clear idx

        VAULT{p}.srate = AAA.info.effective_srate;

        % load chunks
        load([paths.in, 'chunksize.mat'])

        % load preprocessed EEG data
        files = [paths.in_clean, subs.participant_id{p}, '_post_ica.set'];
        EEG = pop_loadset(files);

        % find channel dynamicly in case some channel was rejected
        channel.O2 = find(strcmpi({EEG.chanlocs.labels}, 'O2'));

        disp(' ')
        disp(' ')
        disp(' ')
        disp(['clean EEG duration: ', num2str(EEG.times(end)), ' ms'])
        disp(['clean EEG duration: ', num2str(EEG.times(end)/1000/60), ' minutes'])


        %% adapt the EEG structure
        switch knob.raw
            case 0
                EEG.temporal = EEG.data; % we save the real EEG data somewhere else
                % it was called time_series; now (monday 8th) we'll call it something different to
                % be able to re-run code
            case 1
                EEG.temporal = EEG_raw.time_series;
        end

        EEG.data = []; % and we empty the one we have
        EEG.nbchan = 1; % we'll analyze only 1 channel
        EEG.pnts = ring.buffsize; % we'll just analyze buffers
        % EEG.trials = 1;
        % EEG.xmin = 0;
        EEG.xmax = (EEG.pnts) /  ring.buffsize; % EEG.srate
        EEG.times = linspace(EEG.xmin * 1000, EEG.xmax * 1000, EEG.pnts);
        EEG.chanlocs = struct('labels', 'Alpha');  % Minimal chanlocs
        EEG.event = struct('type', 'dummy', 'latency', 1);

        %% chunk thing
        % let's force an overshoot, and then we use the
        % sum(ring.chunksize) to trim the EEG DATA
        %EEG.temporal
        ring.diffs = cumsum(flip(chunks)) - (length(EEG.temporal));
        ring.idx = find(ring.diffs>0); % all positive values
        ring.chunksize = chunks(end-ring.idx(1)+2:end);

        ring.leftovers = length(EEG.temporal) - sum(ring.chunksize);

        EEG.time_series = EEG.temporal(:, ring.leftovers+1:end);
        EEG_raw.time_stamps = EEG_raw.time_stamps(:, ring.leftovers+1:end);


        % failsafe
        if length(EEG.time_series) ~= sum(ring.chunksize)
            error('wtf')
        end

        VAULT{p}.chunks = ring.chunksize;

        %% ring buffer recreation
        rAAA.time_series = []; % to store th recreated AAA
        rAAA.time_stamps = [];
        time_counter = 0;

        tdex = 1; % the main index
        weight_counter = 1;
        ring.weight = []; % for the moving average
        ring.weight_final = [];

        %% filling the buffer once
        while size(EEG.data,2) < ring.chunksize(1)
            if tdex == 1
                EEG.data = EEG.time_series(channel.O2, 1:ring.chunksize(tdex));
                rAAA.time_series(tdex) = mean(EEG.data);
                rAAA.time_stamps(tdex) = EEG_raw.time_stamps(ring.chunksize(tdex));
                time_counter = ring.chunksize(tdex);

                tdex = tdex+1;
            else
                disp('we shall not see this')
                EEG.data = [EEG.data, EEG.time_series(channel.O2, sum(ring.chunksize(1:tdex-1)) +1 : sum(ring.chunksize(1:tdex)))];
                rAAA.time_series(tdex) = mean(EEG.data);
                rAAA.time_stamps(tdex) = EEG_raw.time_stamps(time_counter+ring.chunksize(tdex));
                time_counter = time_counter+ring.chunksize(tdex);

                tdex = tdex+1;

            end
        end

        ring.first_index = tdex;
        % we save the last index that fills up the buffer once
        % for the moving average calculation
        %     ring.remove = size(EEG.data,2) - ring.buffsize+1;
        %     % we trim the buffer as in the online analysis
        %     switch ring.remove > 0
        %         case 1
        %             EEG.data = EEG.data(:, ring.remove:end);
        %     end

        %% run ring buffer:
        disp('starting ring buffer')

        for tdex = tdex : length(ring.chunksize)
            % this index moves within the recording chunksize. From the one just
            % above the buffsize (bc we already filled it once) till the last
            % chunksize

            %% step 1: ring buffer moves
            % empty out EEG data
            EEG.data = [];

            % we apply those samples of that chunk
            EEG.chunk = EEG.time_series(channel.O2, sum(ring.chunksize(1:tdex-1))+1 : sum(ring.chunksize(1:tdex)));
            % we index within the EEG data, the indices are:
            % 1. sum(ring.chunksize(1:idx-1)) +1 = this is the amount of samples from the start (1:) until the previous (idx-1) chunk, + 1
            % 2. sum(ring.chunksize(1:idx) = until the current one
            % 3. channel selection

            % the EEG.data is just the chunk
            EEG.data = [EEG.chunk];

            % reupdate this things
            EEG.pnts = length(EEG.data); % we'll just analyze buffers
            % EEG.trials = 1;
            % EEG.xmin = 0;
            EEG.xmax = (EEG.pnts) /  ring.srate; % EEG.srate
            EEG.times = linspace(EEG.xmin * 1000, EEG.xmax * 1000, EEG.pnts);


            %% step 2: the online analysis
            % filtering
            alpha.filtered = pop_eegfiltnew(EEG, 'locutoff',filtro.lco,'hicutoff',filtro.hco,'filtorder',filtro.order,'minphase',filtro.causal,'plotfreqz',0);

            % envelope and average: alpha
            alpha.envelope = abs(hilbert(alpha.filtered.data));
            alpha.state = mean(alpha.envelope);

            %% Weighted average
            % no weighted average
            switch knob.weight
                case 1
                    if tdex- (ring.first_index+ring.nhb) < 0 % fill wonder weight once
                        ring.weight(weight_counter) = alpha.state;
                        weight_counter = weight_counter+1;
                    elseif tdex- (ring.first_index+ring.nhb) >= 0 % run wonder weight when tdex = ring.nhb+1
                        ring.weight = [ring.weight(2:ring.nhb), alpha.state]; % ring buffer structure
                        ring.weight_final = sum(ring.weight .* ring.weights); % apply wieghted average
                        alpha.state = ring.weight_final;
                    end
            end
            %% reconstruction

            rAAA.time_series(tdex) = alpha.state;
            rAAA.time_stamps(tdex) = EEG_raw.time_stamps(time_counter+ring.chunksize(tdex));
            time_counter = time_counter+ring.chunksize(tdex);


        end 

        %% end of the ring buffer
        disp('reconstruction done!')

        %% adjust AAA & rAAA
        % let's save things
        temporal.AAA = AAA;
        temporal.rAAA = rAAA;

        VAULT{p}.mismatch_samples = length(AAA.time_series) - length(rAAA.time_series);

        ring.remove = ring.first_index+1;
        % VAULT{p}.mismatch_samples: we got rid of the first AAA
        % first_index+nhb: in the reconstruction they look bad

        %AAA.time_series = AAA.time_series(ring.remove:end-VAULT{p}.mismatch_samples);
        %AAA.time_stamps = AAA.time_stamps(ring.remove:end-VAULT{p}.mismatch_samples);
        AAA.time_series = AAA.time_series(ring.remove + VAULT{p}.mismatch_samples:end);
        AAA.time_stamps = AAA.time_stamps(ring.remove + VAULT{p}.mismatch_samples:end);

        AAA.timevec = AAA.time_stamps - AAA.time_stamps(1);

        rAAA.time_series = rAAA.time_series(ring.remove:end);
        rAAA.time_stamps = rAAA.time_stamps(ring.remove:end);
        rAAA.timevec = rAAA.time_stamps - rAAA.time_stamps(1);

        if length(AAA.time_series) - length(rAAA.time_series) ~= 0
            error('AAA and rAAA adjusted are not equal')
        end


        %% plotting online and offline output
        switch knob.plot
            case 1
                fig1 = figure;
                plot(AAA.timevec, AAA.time_series, 'Color', aes.orange	)
                hold on

                plot(rAAA.timevec, rAAA.time_series, 'Color', aes.blue	)
                hold off

                title(['Online Analysis vs Offline Reconstruction (', subs.participant_id{p}, ')'], 'Interpreter', 'none', 'Fontsize', 15)
                ylabel('Amplitude (µV)' , 'Fontsize', 13)
                xlabel('Time (s)' , 'Fontsize', 13)
                xlim([AAA.timevec(1), AAA.timevec(end)])
                legend('online analysis', 'offline reconstruction', 'Fontsize', 11)

                savepath = [paths.out, '\rec_vs_online'];
                print(fig1, [savepath], '-dpng', '-r300');

        end % switch knob plot

        disp(' ')

        %% cross-correlation
        duration = int16(minutes*60*VAULT{p}.srate);

        % whole signal
        [x.c, x.lags] = xcorr(rAAA.time_series, AAA.time_series, 'coeff');
        [x.max_corr, x.max_idx] = max(x.c);

        x.lag_at_max_corr = x.lags(x.max_idx);
        x.max_lag_seconds = x.lag_at_max_corr  / VAULT{p}.srate;

        VAULT{p}.corr_gen.c = x.c;
        VAULT{p}.corr_gen.lags = x.lags;
        VAULT{p}.corr_gen.max_corr = x.max_corr;
        VAULT{p}.corr_gen.lag_at_max_corr = x.lag_at_max_corr;
        VAULT{p}.corr_gen.max_lag_seconds = x.max_lag_seconds;

        % for the first 5 minutes
        [x.c_start, x.lags_start] = xcorr( rAAA.time_series(1:duration), AAA.time_series(1:duration), 'coeff');
        [x.max_corr_start, x.max_idx_start] = max(x.c_start);

        x.lag_at_max_corr_start = x.lags_start(x.max_idx_start);
        x.max_lag_seconds_start = x.lag_at_max_corr_start  / VAULT{p}.srate;
        disp(['START: Max corr = ', num2str(x.max_corr_start), ' at lag = ', num2str(x.lag_at_max_corr_start), ' samples (', num2str(x.max_lag_seconds_start), ')'])

        % store
        VAULT{p}.corr_start.c = x.c_start;
        VAULT{p}.corr_start.lags = x.lags_start;
        VAULT{p}.corr_start.max_corr = x.max_corr_start;
        VAULT{p}.corr_start.lag_at_max_corr = x.lag_at_max_corr_start;
        VAULT{p}.corr_start.max_lag_seconds = x.max_lag_seconds_start;

        % for the last 5 minutes
        [x.c_end, x.lags_end] = xcorr(rAAA.time_series(end-duration+1:end), AAA.time_series(end-duration+1:end),  'coeff');
        [x.max_corr_end, x.max_idx_end] = max(x.c_end);

        x.lag_at_max_corr_end = x.lags_end(x.max_idx_end);
        x.max_lag_seconds_end = x.lag_at_max_corr_end  / VAULT{p}.srate;
        disp(['END: Max corr = ', num2str(x.max_corr_end), ' at lag = ', num2str(x.lag_at_max_corr_end), ' samples (', num2str(x.max_lag_seconds_end), ')'])

        % store
        VAULT{p}.corr_end.c = x.c_end;
        VAULT{p}.corr_end.lags = x.lags_end;
        VAULT{p}.corr_end.max_corr = x.max_corr_end;
        VAULT{p}.corr_end.lag_at_max_corr = x.lag_at_max_corr_end;
        VAULT{p}.corr_end.max_lag_seconds = x.max_lag_seconds_end;

        %% plot windows of time that we will xcorrelate
        % FIRST 5 MINUTES
        switch knob.plot

            case 1 % knob.plot
                % FIRST 5 MINUTES
                fig1 = figure;
                switch knob.raw
                    case 0 % preprocssed
                        plot(AAA.timevec(1:duration), normalize(AAA.time_series(1:duration)), 'Color', aes.orange, 'LineWidth', aes.thick	)
                        hold on
                        plot(rAAA.timevec(1:duration), normalize(rAAA.time_series(1:duration)), 'Color', aes.blue, 'LineWidth', aes.thick	)
                        hold off
                        title(['First ', num2str(minutes), ' minutes - preprocessed EEG (', subs.participant_id{p},')'], 'Interpreter', 'none', 'Fontsize', 14)

                    case 1 % raw data
                        plot(AAA.timevec(1:duration), AAA.time_series(1:duration), 'Color', aes.orange, 'LineWidth', aes.thick	)
                        hold on
                        plot(rAAA.timevec(1:duration), rAAA.time_series(1:duration), 'Color', aes.blue, 'LineWidth', aes.thick	)
                        hold off
                        title(['First ', num2str(minutes), ' minutes - raw EEG (', subs.participant_id{p},')'], 'Interpreter', 'none', 'Fontsize', 14)

                end
                subtitle(['Max corr = ', num2str(round(x.max_corr_start, 3)), ' at lag = ', num2str(x.lag_at_max_corr_start), ' samples (', num2str(round(x.max_lag_seconds_start, 2)), ' s)'], 'Interpreter', 'none', 'Fontsize', 15)

                ylabel('Amplitude (µV)' , 'Fontsize', 13)
                %xlabel('Time (s)' , 'Fontsize', 13)
                xlim([AAA.timevec(1), AAA.timevec(duration)])
                legend('online analysis', 'offline reconstruction', 'Fontsize', 11, 'Location', 'northwest')

                % daniela's chunk
                set(gca, 'Box', 'off'); % removes the big box
                %axis square;
                ax = gca;
                ax.LineWidth = 2;
                set(ax, 'TickDir', 'out'); % moves the ticks out
                ax.TickLength = [0.02 0.02]; % makes them thicke
                ax.Layer = 'top';
                af = gcf;
                af.Position = [1 1 670 445]; % for the window undock size

                % save
                switch knob.debugging
                    case 0
                        switch knob.raw
                            case 1
                                savepath = [paths.out, '\xcross_raw_1'];
                            case 0
                                savepath = [paths.out, '\xcross_preprocessed_1'];
                        end
                        print(fig1, [savepath], '-dpng', '-r300');
                        %saveas(fig1, savepath)
                end

                % LAST 5 MINUTES - XCROSS
                fig2 = figure;
                switch knob.raw
                    case 0 % preprocessed - we normalize to imrpove visibility, for amplitude comparison we don't normalize
                        plot(AAA.timevec(end-duration:end), normalize(AAA.time_series(end-duration:end)), 'Color', aes.orange, 'LineWidth', aes.thick	)
                        hold on
                        plot(rAAA.timevec(end-duration:end), normalize(rAAA.time_series(end-duration:end)), 'Color', aes.blue, 'LineWidth', aes.thick	)
                        hold off
                        %title(['Normalized last ', num2str(minutes), ' minutes - Max corr = ', num2str(round(x.max_corr_end, 3)), ' at lag = ', num2str(x.lag_at_max_corr_end), ' samples (', num2str(round(x.max_lag_seconds_end,2)), ' s)'], 'Interpreter', 'none', 'Fontsize', 16)
                        title(['Last ', num2str(minutes), ' minutes - preprocessed EEG (', subs.participant_id{p},')'], 'Interpreter', 'none', 'Fontsize', 14)

                    case 1 % raw
                        plot(AAA.timevec(end-duration:end), AAA.time_series(end-duration:end), 'Color', aes.orange, 'LineWidth', aes.thick	)
                        hold on
                        plot(rAAA.timevec(end-duration:end), rAAA.time_series(end-duration:end), 'Color', aes.blue, 'LineWidth', aes.thick	)
                        hold off
                        %title(['Normalized last ', num2str(minutes), ' minutes - Max corr = ', num2str(round(x.max_corr_end, 3)), ' at lag = ', num2str(x.lag_at_max_corr_end), ' samples (', num2str(round(x.max_lag_seconds_end,2)), ' s)'], 'Interpreter', 'none', 'Fontsize', 16)
                        title(['Last ', num2str(minutes), ' minutes - raw EEG (', subs.participant_id{p},')'], 'Interpreter', 'none', 'Fontsize', 14)
                
                end
                
                subtitle(['Max corr = ', num2str(round(x.max_corr_end, 3)), ' at lag = ', num2str(x.lag_at_max_corr_end), ' samples (', num2str(round(x.max_lag_seconds_end,2)), ' s)'], 'Interpreter', 'none', 'Fontsize', 15)

                ylabel('Amplitude (µV)' , 'Fontsize', 13)
                xlabel('Time (s)' , 'Fontsize', 13)
                xlim([AAA.timevec(end-duration), AAA.timevec(end)])
                % legend('online analysis', 'offline reconstruction', 'Fontsize', 11)

                % daniela's chunk
                set(gca, 'Box', 'off'); % removes the big box
                %axis square;
                ax = gca;
                ax.LineWidth = 2;
                set(ax, 'TickDir', 'out'); % moves the ticks out
                ax.TickLength = [0.02 0.02]; % makes them thicke
                ax.Layer = 'top';
                af = gcf;
                af.Position = [1 1 670 445]; % for the window undock size

                % save
                switch knob.debugging
                    case 0
                        switch knob.raw
                            case 1
                                savepath = [paths.out, '\xcross_raw_2'];
                            case 0
                                savepath = [paths.out, '\xcross_preprocessed_2'];
                        end
                        print(fig2, [savepath], '-dpng', '-r300');
                        %saveas(fig2, savepath)
                end
        end % knob plot

        %% comparing amplitude: general
        % online
        VAULT{p}.online.average = mean(AAA.time_series);
        VAULT{p}.online.std = std(AAA.time_series);
        VAULT{p}.online.median = median(AAA.time_series);
        VAULT{p}.online.min = min(AAA.time_series);
        VAULT{p}.online.max = max(AAA.time_series);

        % offline
        VAULT{p}.offline.average = mean(rAAA.time_series);
        VAULT{p}.offline.std = std(rAAA.time_series);
        VAULT{p}.offline.median = median(rAAA.time_series);
        VAULT{p}.offline.min = min(rAAA.time_series);
        VAULT{p}.offline.max = max(rAAA.time_series);

        % amplitude comparison
        VAULT{p}.diff.average = VAULT{p}.online.average - VAULT{p}.offline.average;
        VAULT{p}.diff.std = VAULT{p}.online.std - VAULT{p}.offline.std;
        VAULT{p}.diff.median = VAULT{p}.online.median - VAULT{p}.offline.median;
        VAULT{p}.diff.min = VAULT{p}.online.min - VAULT{p}.offline.min;
        VAULT{p}.diff.max = VAULT{p}.online.max - VAULT{p}.offline.max;

        % relative change
        VAULT{p}.rel.average = VAULT{p}.diff.average / VAULT{p}.offline.average;
        VAULT{p}.rel.std = VAULT{p}.diff.std / VAULT{p}.offline.std;
        VAULT{p}.rel.median = VAULT{p}.diff.median / VAULT{p}.offline.median;
        VAULT{p}.rel.min = VAULT{p}.diff.min / VAULT{p}.offline.min;
        VAULT{p}.rel.max = VAULT{p}.diff.max / VAULT{p}.offline.max;

        % rms
        VAULT{p}.rms.online = rms(AAA.time_series);
        VAULT{p}.rms.offline = rms(rAAA.time_series);
        VAULT{p}.rms.ratio = 100*(VAULT{p}.rms.online / VAULT{p}.rms.offline-1);


        %% comparing amplitude: start
        % online
        VAULT{p}.online_start.average = mean(AAA.time_series(1:duration));
        VAULT{p}.online_start.std = std(AAA.time_series(1:duration));
        VAULT{p}.online_start.median = median(AAA.time_series(1:duration));
        VAULT{p}.online_start.min = min(AAA.time_series(1:duration));
        VAULT{p}.online_start.max = max(AAA.time_series(1:duration));

        % offline
        VAULT{p}.offline_start.average = mean(rAAA.time_series(1:duration));
        VAULT{p}.offline_start.std = std(rAAA.time_series(1:duration));
        VAULT{p}.offline_start.median = median(rAAA.time_series(1:duration));
        VAULT{p}.offline_start.min = min(rAAA.time_series(1:duration));
        VAULT{p}.offline_start.max = max(rAAA.time_series(1:duration));

        % amplitude comparison
        VAULT{p}.diff_start.average = VAULT{p}.online_start.average - VAULT{p}.offline_start.average;
        VAULT{p}.diff_start.std = VAULT{p}.online_start.std - VAULT{p}.offline_start.std;
        VAULT{p}.diff_start.median = VAULT{p}.online_start.median - VAULT{p}.offline_start.median;
        VAULT{p}.diff_start.min = VAULT{p}.online_start.min - VAULT{p}.offline_start.min;
        VAULT{p}.diff_start.max = VAULT{p}.online_start.max - VAULT{p}.offline_start.max;

        % relative change
        VAULT{p}.rel_start.average = VAULT{p}.diff_start.average / VAULT{p}.offline_start.average;
        VAULT{p}.rel_start.std = VAULT{p}.diff_start.std / VAULT{p}.offline_start.std;
        VAULT{p}.rel_start.median = VAULT{p}.diff_start.median / VAULT{p}.offline_start.median;
        VAULT{p}.rel_start.min = VAULT{p}.diff_start.min / VAULT{p}.offline_start.min;
        VAULT{p}.rel_start.max = VAULT{p}.diff_start.max / VAULT{p}.offline_start.max;

        % rms start
        VAULT{p}.rms_start.online = rms(AAA.time_series(1:duration));
        VAULT{p}.rms_start.offline = rms(rAAA.time_series(1:duration));
        VAULT{p}.rms_start.ratio = 100*(VAULT{p}.rms_start.online / VAULT{p}.rms_start.offline-1);


        %% comparing amplitude: last 5 minutes
        % online
        VAULT{p}.online_end.average = mean(AAA.time_series(end-duration:end));
        VAULT{p}.online_end.std = std(AAA.time_series(end-duration:end));
        VAULT{p}.online_end.median = median(AAA.time_series(end-duration:end));
        VAULT{p}.online_end.min = min(AAA.time_series(end-duration:end));
        VAULT{p}.online_end.max = max(AAA.time_series(end-duration:end));

        % offline
        VAULT{p}.offline_end.average = mean(rAAA.time_series(end-duration:end));
        VAULT{p}.offline_end.std = std(rAAA.time_series(end-duration:end));
        VAULT{p}.offline_end.median = median(rAAA.time_series(end-duration:end));
        VAULT{p}.offline_end.min = min(rAAA.time_series(end-duration:end));
        VAULT{p}.offline_end.max = max(rAAA.time_series(end-duration:end));

        % amplitude comparison
        VAULT{p}.diff_end.average = VAULT{p}.online_end.average - VAULT{p}.offline_end.average;
        VAULT{p}.diff_end.std = VAULT{p}.online_end.std - VAULT{p}.offline_end.std;
        VAULT{p}.diff_end.median = VAULT{p}.online_end.median - VAULT{p}.offline_end.median;
        VAULT{p}.diff_end.min = VAULT{p}.online_end.min - VAULT{p}.offline_end.min;
        VAULT{p}.diff_end.max = VAULT{p}.online_end.max - VAULT{p}.offline_end.max;

        % relative change
        VAULT{p}.rel_end.average = VAULT{p}.diff_end.average / VAULT{p}.offline_end.average;
        VAULT{p}.rel_end.std = VAULT{p}.diff_end.std / VAULT{p}.offline_end.std;
        VAULT{p}.rel_end.median = VAULT{p}.diff_end.median / VAULT{p}.offline_end.median;
        VAULT{p}.rel_end.min = VAULT{p}.diff_end.min / VAULT{p}.offline_end.min;
        VAULT{p}.rel_end.max = VAULT{p}.diff_end.max / VAULT{p}.offline_end.max;

        % rms end
        VAULT{p}.rms_end.online = rms(AAA.time_series(end-duration:end));
        VAULT{p}.rms_end.offline = rms(rAAA.time_series(end-duration:end));
        VAULT{p}.rms_end.ratio = 100*(VAULT{p}.rms_end.online / VAULT{p}.rms_end.offline-1);

        %% plot windows for amplitude comparison: not normalized
        switch knob.plot
            case 1
                % first 5 mins
                fig3 = figure;
                plot(AAA.timevec(1:duration), AAA.time_series(1:duration), 'Color', aes.orange, 'LineWidth', aes.thick	)
                hold on

                plot(rAAA.timevec(1:duration), rAAA.time_series(1:duration), 'Color', aes.blue, 'LineWidth', aes.thick	)
                hold off

                switch knob.raw
                    case 0
                        title(['First ', num2str(minutes), ' minutes - preprocessed EEG (', subs.participant_id{p},')'], 'Interpreter', 'none', 'Fontsize', 14)
                        subtitle(['amplitude difference = ', num2str(round(VAULT{p}.diff_start.average, 2)),  ' µV (', num2str(round(VAULT{p}.rel_start.average*100, 2))  ,'%)'], 'Interpreter', 'none', 'Fontsize', 15)
                    case 1
                        title(['First ', num2str(minutes), ' minutes - raw EEG (', subs.participant_id{p},')'], 'Interpreter', 'none', 'Fontsize', 14)
                        subtitle(['amplitude difference = ', num2str(round(VAULT{p}.diff_start.average, 2)),  ' µV (', num2str(round(VAULT{p}.rel_start.average*100, 2))  ,'%)'], 'Interpreter', 'none', 'Fontsize', 15)
                end
                ylabel('Amplitude (µV)' , 'Fontsize', 13)
                %label('Time (s)' , 'Fontsize', 13)
                xlim([AAA.timevec(1), AAA.timevec(duration)])
                legend('online analysis', 'offline reconstruction', 'Fontsize', 11, 'Location', 'northwest')

                set(gca, 'Box', 'off'); % removes the big box
                %axis square;
                ax = gca;
                ax.LineWidth = 2;
                set(ax, 'TickDir', 'out'); % moves the ticks out
                ax.TickLength = [0.02 0.02]; % makes them thicke
                ax.Layer = 'top';
                af = gcf;
                af.Position = [1 1 670 445]; % for the window undock size

                switch knob.debugging
                    case 0
                        switch knob.raw
                            case 1
                        savepath = [paths.out, '\amplitude_raw_1'];
                            case 0
                                savepath = [paths.out, '\amplitude_preprocessed_1'];
                        end
                        print(fig3, [savepath], '-dpng', '-r300');
                        %saveas(fig3, savepath)
                end

                % end
                fig4 = figure;
                plot(AAA.timevec(end-duration:end), AAA.time_series(end-duration:end), 'Color', aes.orange, 'LineWidth', aes.thick	)
                hold on
                plot(rAAA.timevec(end-duration:end), rAAA.time_series(end-duration:end), 'Color', aes.blue, 'LineWidth', aes.thick	)
                hold off

                switch knob.raw
                    case 0
                        title(['Last ', num2str(minutes), ' minutes - preprocessed EEG (', subs.participant_id{p},')'], 'Interpreter', 'none', 'Fontsize', 14)
                        subtitle(['amplitude difference = ', num2str(round(VAULT{p}.diff_end.average, 2)),  ' µV (', num2str(round(VAULT{p}.rel_end.average*100, 2))  ,'%)'], 'Interpreter', 'none', 'Fontsize', 15)
                    case 1
                        %    title(['Last ', num2str(minutes), ' minutes - raw EEG - amplitude difference = ', num2str(round(VAULT{p}.diff_end.average, 2)) ...
                        % ,  ' µV (+', num2str(round(VAULT{p}.rel_end.average*100, 2))  ,'%)'], 'Interpreter', 'none', 'Fontsize', 16)

                        title(['Last ', num2str(minutes), ' minutes - raw EEG (', subs.participant_id{p},')'], 'Interpreter', 'none', 'Fontsize', 14)
                        subtitle(['amplitude difference = ', num2str(round(VAULT{p}.diff_end.average, 2)),  ' µV (', num2str(round(VAULT{p}.rel_end.average*100, 2))  ,'%)'], 'Interpreter', 'none', 'Fontsize', 15)
                end

                ylabel('Amplitude (µV)' , 'Fontsize', 13)
                xlabel('Time (s)' , 'Fontsize', 13)
                xlim([AAA.timevec(end-duration), AAA.timevec(end)])
                % legend('online analysis', 'offline reconstruction', 'Fontsize', 11)

                set(gca, 'Box', 'off'); % removes the big box
                %axis square;
                ax = gca;
                ax.LineWidth = 2;
                set(ax, 'TickDir', 'out'); % moves the ticks out
                ax.TickLength = [0.02 0.02]; % makes them thicke
                ax.Layer = 'top';
                af = gcf;
                af.Position = [1 1 670 445]; % for the window undock size

                switch knob.debugging
                    case 0
                        switch knob.raw
                            case 0
                        savepath = [paths.out, '\amplitude_preprocessed_2'];
                            case 1
                                savepath = [paths.out, '\amplitude_raw_2'];
                        end
                        print(fig4, [savepath], '-dpng', '-r300');
%                         saveas(fig4, savepath)
                end
        end % knob plot

        %% report disconnections
        VAULT{p}.issues = find(EM.time_series == 9);


        %% save
        switch knob.debugging
            case 0
                switch knob.raw
                    case 1
                cd([paths.out])
                save('rAAA_raw.mat', 'rAAA', '-v7')
                    case 0
                        save('rAAA_preprocessed.mat', 'rAAA', '-v7')
                end
        end
        cd(paths.script)
    end % if-loop
end % for-loop


%% Delay Calculation


timetable = struct;

for p = 1:length(VAULT)

    timetable(p).max_corr_gen = VAULT{p}.corr_gen.max_corr;
    timetable(p).lag_at_max_corr_gen = VAULT{p}.corr_gen.lag_at_max_corr;
    timetable(p).max_lag_seconds_gen = VAULT{p}.corr_gen.max_lag_seconds;

    % timetable(p).drift_secs = VAULT{p}.corr_start.drift_secs;
    % timetable(p).ms_min = VAULT{p}.corr_start.drift_ms_per_min  ;
    timetable(p).max_corr_start = VAULT{p}.corr_start.max_corr;
    timetable(p).lag_at_max_corr_start = VAULT{p}.corr_start.lag_at_max_corr;
    timetable(p).max_lag_seconds_start = VAULT{p}.corr_start.max_lag_seconds;

    % timetable(p).drift_secs = VAULT{p}.corr_end.drift_secs;
    % timetable(p).ms_min = VAULT{p}.corr_end.drift_ms_per_min  ;
    timetable(p).max_corr_end = VAULT{p}.corr_end.max_corr;
    timetable(p).lag_at_max_corr_end = VAULT{p}.corr_end.lag_at_max_corr;
    timetable(p).max_lag_seconds_end = VAULT{p}.corr_end.max_lag_seconds;
end

% summary table
timetable_fields = fields(timetable);
summary = struct;
for i = 1: length(timetable_fields)
    summary.(timetable_fields{i}).mean = mean([timetable.(timetable_fields{i})]);
    summary.(timetable_fields{i}).std = std([timetable.(timetable_fields{i})]);
    summary.(timetable_fields{i}).median = median([timetable.(timetable_fields{i})]);
    summary.(timetable_fields{i}).min = min([timetable.(timetable_fields{i})]);
    summary.(timetable_fields{i}).max = max([timetable.(timetable_fields{i})]);


end



fprintf('General: Max corr = %.3f at lag = %d samples (%.3g s)\n', summary.max_corr_gen.mean, summary.lag_at_max_corr_gen.mean, summary.max_lag_seconds_gen.mean);
disp([' (± ', num2str(summary.max_lag_seconds_start.std), ')'])
disp(' ')

[r.lag_at_max_corr_gen, ~] = signrank([timetable.lag_at_max_corr_gen]);
[r.max_lag_seconds_gen, ~] = signrank([timetable.max_lag_seconds_gen]);

fprintf('First 5 minutes: Max corr = %.3f at lag = %d samples (%.3g s)\n', summary.max_corr_start.mean, summary.lag_at_max_corr_start.mean, summary.max_lag_seconds_start.mean);
disp([' (± ', num2str(summary.max_lag_seconds_start.std), ')'])
disp(' ')

[r.lag_at_max_corr_start, ~] = signrank([timetable.lag_at_max_corr_start]);
[r.max_lag_seconds_start, ~] = signrank([timetable.max_lag_seconds_start]);

fprintf('Last 5 minutes: Max corr = %.3f at lag = %d samples (%.3g s)\n', summary.max_corr_end.mean, summary.lag_at_max_corr_end.mean, summary.max_lag_seconds_end.mean);
disp([' (± ', num2str(summary.max_lag_seconds_end.std), ')'])
disp(' ')

[r.lag_at_max_corr_end, ~] = signrank([timetable.lag_at_max_corr_end]);
[r.max_lag_seconds_end, ~] = signrank([timetable.max_lag_seconds_end]);
disp(' ')





%% amplitude comparison
disp(' ')
amplitudes.average = [];
amplitudes.std = [];
amplitudes.relative2 = [];
amplitudes.ratio = [];

for p = 1:length(VAULT)
    amplitudes.average(end+1) = VAULT{p}.diff.average;
    amplitudes.std(end+1) = VAULT{p}.diff.std;
    amplitudes.relative2(end+1) = VAULT{p}.rel.average;
    amplitudes.ratio(end+1) = VAULT{p}.rms.ratio;
end

disp(['average difference of amplitude (all): ', num2str(mean(amplitudes.average))]);
disp(['median difference of amplitude:(all) ', num2str(median(amplitudes.average))]);

disp(['std of the difference of amplitude (all): ', num2str(std(amplitudes.average))])
disp(['average through all relatives (all): ', num2str(mean(amplitudes.relative2*100))]);
disp(['median through all relatives (all): ', num2str(median(amplitudes.relative2*100))]);
disp(['std through all relatives (all): ', num2str(std(amplitudes.relative2*100))]);


disp(' ')







disp('mt16 fertig')

switch knob.debugging
    case 0
        switch knob.raw
            case 1
                cd(paths.derivatives)
                save(['VAULT_raw.mat'], 'VAULT', '-v7')
            case 0
                % update subjects
                cd(paths.derivatives)
                save(['VAULT_preprocessed.mat'], 'VAULT', '-v7')
        end % knob.raw
end





