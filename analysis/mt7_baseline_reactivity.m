%% mt7_baseline_reactivity
% Analyzes every participant's baseline, calculate the baseline reactivity,
% plots their baseline and plots all participant's baseline reactivity
% scatterplot.
% Author: Alexis Olguin Baxman
% Date: 16.10.2026

close all; clear; clc; beep off;

% PATHS
paths.main     = 'C:\Users\Leonie\Documents\mt';
paths.lib = [paths.main, '\libs'];
paths.save = [paths.main, '\figure'];
paths.script = [paths.main, '\code\analysis'];
paths.derivatives = [paths.main, '\derivatives\mt7'];

if exist(paths.derivatives) == 0
    mkdir(paths.derivatives)
end

offset.open = 3; % seconds between instruction and open trigger
offset.close = 5; % seconds between instruction and close trigger

% read participants excel to later on choose which participants to load
subs = readtable([paths.main, '\participants.tsv'], "FileType","text",'Delimiter', '\t');
marker = []; % to build the timeline within participants
T = struct(); % to store data across particapnts
counter = 0; % across valid participants

% relevant triggers:.
trigger.blon = 14; % baseline on
trigger.open = 15;
trigger.close = 16;
trigger.bloff = 17; % baseline off


% open EEGLAB
if ~exist('ALLEEG', 'var')
    eeglab;
    clc
end

%% loading

for p = 1:length(subs.participant_id)
    if strcmp(subs.TYPE{p}, 'Participant')
% it needs to run through all, because the include parameter was based in
% the alpha reactivity
        disp(['loading participant: ', subs.participant_id{p}])
        counter = counter+1;
        T.participant{counter} = subs.participant_id{p};


        % load
        paths.in = fullfile(paths.main, subs.participant_id{p}, 'eeg\', [subs.participant_id{p}, '_task-neurofeedback_eeg.xdf']);
        demo = load_xdf(fullfile(paths.in));

        for idx = 1:length(demo)
            if strcmp(demo{1, idx}.info.name, 'AAAStream')
                AAA = demo{1, idx};
            elseif strcmp(demo{1, idx}.info.name, 'EMStream')
                EM = demo{1,idx};

            end
        end % for loop to organize streams
    clear idx

    %% 
    AAA.timevec = AAA.time_stamps - AAA.time_stamps(1);

    marker.idx = zeros(1, length(EM.time_series));
    for m = 1:length(EM.time_series)
        [~, marker.idx(m)] = min(abs(AAA.time_stamps - EM.time_stamps(m)));
    end

    %% start and end

    marker.blon = find(EM.time_series == trigger.blon); % find begining baseline
    marker.bloff = find(EM.time_series == trigger.bloff); % find end baseline
    if length(marker.blon) > 1 || length(marker.bloff) > 1
    warning('there are more that one on or off baseline index')
    end

    % clamp_markers: start and end
    marker.start = marker.idx(marker.blon);
    marker.end = marker.idx(marker.bloff);
    marker.baseline = marker.start:marker.end;

    % save values to the the Table
    T.aaa{counter} = AAA.time_series(marker.baseline);
    T.time{counter} = AAA.timevec(marker.baseline);
    T.mean{counter} = mean(T.aaa{counter});

    %% open and close eyes
    marker.open = find(EM.time_series == trigger.open);
    marker.close = find(EM.time_series == trigger.close);
    
    % put everything together
    marker.event = [marker.blon; marker.open(:); marker.close(:); marker.bloff];
    marker.event = unique(marker.event, 'sorted'); % sort them

    event = []; % to store events
     event.synthclose = [];
      event.synthopen = [];

    for ev = 1:numel(marker.event)
        current = marker.event(ev);

        % clamp: find the event in AAA.time_stamps
        sample = marker.idx(current);

        switch EM.time_series(current)
            case trigger.blon
                event.sample = sample;
                event.type = {'baseline_start'};

            case trigger.open
                % create the opene eyes instruction event
                event.synth_time = AAA.timevec(sample) - offset.open;
                event.synth_sample = find(AAA.timevec >= event.synth_time, 1, 'first'); % this one will be rewritten in every iteration
                % error failsafe
                event.synth_sample = min(event.synth_sample, sample-1); 
                
                event.sample(end+1) = event.synth_sample;
                event.type{end+1} = 'open_instruction';
                event.synthopen(end+1) = event.synth_sample; % use for plotting later

                % open eyes event
                event.sample(end+1) = sample;
                event.type{end+1} = 'open_eyes';

            case trigger.close
                % create the close eyes instruction event
                event.synth_time = AAA.timevec(sample) - offset.close;
                event.synth_sample = find(AAA.timevec >= event.synth_time, 1, 'first'); % this one will be rewritten in every iteration
                % error failsafe
                event.synth_sample = min(event.synth_sample, sample-1);
                
                event.sample(end+1) = event.synth_sample;
                event.type{end+1} = 'close_instruction';
                event.synthclose(end+1) = event.synth_sample; % use for plotting later


                % open eyes event
                event.sample(end+1) = sample;
                event.type{end+1} = 'close_eyes';


            case trigger.bloff
                event.sample(end+1) = sample;
                event.type{end+1} = 'baseline_end';

        end % switch-case

    end % for-loop marker.event


    %% segment baseline
     windows.open = zeros(0,2);
     windows.close = zeros(0,2);

for ev = 1:numel(event.sample)-1
    segment = AAA.time_series(event.sample(ev):event.sample(ev+1)-1);
switch event.type{ev}
    case 'open_eyes'
        windows.open = [windows.open, segment];
    case 'close_eyes'
        windows.close = [windows.close, segment];
end% swtch event type
end % for loop event samples

T.mean_open(counter) = mean(windows.open);
T.mean_close(counter) = mean(windows.close);

%% normalization
denom = (T.mean_close(counter) + T.mean_open(counter)) / 2;
T.diffNorm(counter) = 100*((T.mean_close(counter)  - T.mean_open(counter) ) / denom);

%% plotting
fig = figure;
idx.start = event.sample(1);
idx.stop = event.sample(end);
idx.wind = idx.start:idx.stop;
timevec = AAA.timevec(idx.wind) - AAA.timevec(idx.start);
diff = idx.wind(end)-length(timevec);

pl.aaa = plot(timevec, AAA.time_series(idx.wind), 'Color', [0 0 0], 'LineWidth', 1.5);
hold on;

% instructions open
for e = 1:numel(event.synthopen)
    % Create the line without a label
    pl.ins = xline(timevec(event.synthopen(e)-diff), ':', ' ', ...
        'Color', [0.4 0.4 0.4], 'LabelHorizontalAlignment', 'left', 'LineWidth', 2, 'LabelOrientation', 'aligned');
end

% instructions close
for e = 1:numel(event.synthclose)
    % Create the line without a label
    pl.ins = xline(timevec(event.synthclose(e)-diff), ':', ' ', ...
        'Color', [0.4 0.4 0.4], 'LabelHorizontalAlignment', 'left', 'LineWidth', 2, 'LabelOrientation', 'aligned');
end

        % open window
        for e = 1:numel(marker.open)
            sample = marker.idx(marker.open(e));
            pl.open = xline(timevec(sample-diff), '-', ' ', ...
                'Color', [0.30 0.75 0.93], 'LabelHorizontalAlignment', 'right', 'LineWidth', 2, 'LabelOrientation', 'aligned');
        end


                % close window
        for e = 1:numel(marker.close)
                        sample = marker.idx(marker.close(e));
            pl.close = xline(timevec(sample-diff), '-', ' ', ...
                'Color', [0.85 0.53 0.10], 'LabelHorizontalAlignment', 'right', 'LineWidth', 2, 'LabelOrientation', 'aligned');
        end

        pl.end = xline(timevec(idx.stop-diff), '--k', ' ', 'LabelOrientation', 'aligned');


%% plot paremeters
        ax = gca;              % or your specific axes handle (ax1, ax2, …)
        ax.FontSize = 12;
        ax.LineWidth  = 2;        % thicker axis lines / tick marks
        ax.TickLength = [0.02 0.02]; % makes them thicke
        ax.Layer = 'top';
        ti = ax.TightInset;
        ax.Position = [ti(1) ti(2) 1 - ti(1) - ti(3) 1 - ti(2) - ti(4)];

        af = gcf;

        set(ax, 'Box', 'off'); % removes the big box
        set(ax, 'TickDir', 'out'); % moves the ticks out
        set(af,'Units','inches','Position',[1 1 16 10]);  % wide aspect


        xlabel('Time (s)', 'Fontsize', 17);
        ylabel('AAA (\muV)', 'Fontsize', 17);
        title(['Percentage difference: ', num2str(round(T.diffNorm(counter), 3)) ,'% (',T.participant{counter},')'], 'Interpreter', 'none', 'Fontsize', 19, 'FontName', 'Arial');
        %title(sprintf('Baseline %s', participantLabel, ' (', diffNorm(p),'%)'), 'Interpreter', 'none', 'Fontsize', 15);
        %grid on;
        
        %ax.TickLength = [0.015 0.015];
        %ax.TickDir    = 'out';      % or 'in'
        hold off;
        xlim([timevec(1) timevec(end)])
%         legend([pl.aaa, pl.ins(1), pl.open(1), pl.close(1)], ...
%             {'AAA', 'Voice Instructions', 'Eyes-Open', 'Eyes-Closed'}, ...
%             'FontSize', 13, 'Location', 'eastoutside')

        %% save figure
        paths.save = [paths.derivatives,'\' ,T.participant{counter}];
        print(gcf, paths.save, '-dpng', '-r300' )


     end % if loop strcmp include participants
end % for loop all participaticpants


%% scatter plot with all reactivities
fig = figure;

T.low = T.diffNorm < 20;
%T.low = [];
% for p = 1:numel(T.participant)
%     if T.diffNorm(p) < 20
%         T.low(p) = 1;
%     else
%         T.low(p) = 0;
%     end
% end

% scatter all but low values
scatter(find(~T.low), T.diffNorm(~T.low), 60, 'filled', 'blue');
hold on
% scatter the low values
scatter(find(T.low), T.diffNorm(T.low), 60, 'filled', 'red');
yline(20, '--k');

% plot paremeters

ylabel('Percentage difference (%)', 'Fontsize', 13); %, 'FontName', 'Arial', 'FontSmoothing','off')
xlabel('Participant', 'Fontsize', 13)
title('Baseline: Eyes Closed vs Eyes Open', 'Fontsize', 15)

xlim([0.5, numel(T.diffNorm)+0.5]);


% ax settings
ax = gca;              % or your specific axes handle (ax1, ax2, …)
ax.FontSize = 12;
ax.LineWidth  = 2;        % thicker axis lines / tick marks
set(ax, 'Box', 'off'); % removes the big box

% ticks
set(ax, 'TickDir', 'out'); % moves the ticks out
xticks(1:numel(T.participant));
xticklabels(T.participant);
ax.TickLength = [0.02 0.02]; % makes them thicke


% adjust position at the end
ti = ax.TightInset;
ax.Position = [ti(1) ti(2) 1 - ti(1) - ti(3) 1 - ti(2) - ti(4)];

%ax.Layer = 'top';

af = gcf;

set(af,'Units','inches','Position',[1 1 8 5]);  % wide aspect (adjust as you like)


        print(gcf, [paths.derivatives, '/all'], '-dpng', '-r300' )

