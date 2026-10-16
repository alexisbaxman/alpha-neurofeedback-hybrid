%% mt8_alpha_across_blocks
% Analyzes and plots how alpha amplitude changes across blocks for all
% participants.
% Author: Alexis Olguin Baxman
% Date: 16.10.2026

close all; clear; clc; beep off;

paths.main     = 'C:\Users\Leonie\Documents\mt';
paths.lib = [paths.main, '\libs'];
addpath(paths.lib) % for violin
paths.script = [paths.main, '\code\analysis'];
paths.derivatives = [paths.main, '\derivatives\mt8'];

if exist(paths.derivatives) == 0
    mkdir(paths.derivatives)
end

% colors
aes.blue = [0.3010 0.7450 0.9330];
aes.grey = [0.3 0.3 0.3];
aes.clear_grey = [0.7 0.7 0.7];
aes.dark_blue = [0 0.3098 0.6235];
aes.orange = [0.8500 0.3250 0.0980]	;
aes.rosa = [0.8470588235294118 0.10588235294117647 0.3764705882352941];
aes.black = [0 0 0];
aes.white = [1 1 1];

aes.thick = 0.5;
edges = 0:0.2:1; % for normalized histograms

test.reg = 32;
test.disc = 20;
test.block = 26;

% to store all tables
T = struct();
B = []; % to store all baselines (annoying, but needed to plot without storing the baseliens in T
subs = readtable([paths.main, '\participants.tsv'], "FileType","text",'Delimiter', '\t');


knob.ref = 1;% z normalization or from baseline
knob.baseline = 1; % to show the baseline

%%

counter = 0; % to move through the table
knob.normalization = 2;

for p = 1:length(subs.participant_id)
    if strcmp(subs.INCLUDE{p}, 'Yes')

        counter = counter+1;

        % load
        paths.in = fullfile(paths.main, subs.participant_id{p}, 'eeg\', [subs.participant_id{p}, '_task-neurofeedback']);
        load([paths.in, '_task.mat']);
        load([paths.in, '_trial.mat']);


        % normalization
        switch knob.normalization
            case 1
                trials = trial.average(22:end); % remove the practice ones


                norm.trials = (trials - mean(trials))/std(trials);
                norm.baseline = (task.average(1) - mean(trials))/std(trials);

                norm.block1 = norm.trials(1:test.block);
                norm.block2 = norm.trials(test.block+1:test.block*2);
                norm.block3 = norm.trials(test.block*2+1:test.block*3);
                norm.block4 = norm.trials(test.block*3+1:end);

                B(counter) = norm.baseline;

                T(counter).baseline = norm.baseline;
                T(counter).block1 = mean(norm.block1);
                T(counter).block2 = mean(norm.block2);
                T(counter).block3 = mean(norm.block3);
                T(counter).block4 = mean(norm.block4);

            case 2
                trials = trial.average(22:end); % remove the practice ones
                all = [task.average(1), trial.average(22:end)]; % remove the practice ones

                norm.trials = (trials - mean(all))/std(all);
                norm.baseline = (task.average(1) - mean(all))/std(all);

                norm.block1 = norm.trials(1:test.block);
                norm.block2 = norm.trials(test.block+1:test.block*2);
                norm.block3 = norm.trials(test.block*2+1:test.block*3);
                norm.block4 = norm.trials(test.block*3+1:end);

                B(counter) = norm.baseline;

                T(counter).baseline = norm.baseline;
                T(counter).block1 = mean(norm.block1);
                T(counter).block2 = mean(norm.block2);
                T(counter).block3 = mean(norm.block3);
                T(counter).block4 = mean(norm.block4);

        end % switch case normalization

    end % if loop
end % for loop

%% let's plot this




aes.colors = [aes.blue; aes.white; aes.white; aes.white; aes.white];
aes.label = {'Baseline','Block 1', 'Block 2', 'Block 3', 'Block 4'};

data = [{[T.baseline]}; {[T.block1]}; {[T.block2]}; {[T.block3]}; {[T.block4]}];





figure;




violin_half(data', 'xlabel', aes.label, 'facecolor', aes.colors);

for i = 1:numel(data)
    %boxplot(data{i}, 'Position', i, 'Labels', aes.label{i});
    boxplot(data{i}, 'Position', i, 'Labels', aes.label{i});
    set(findobj(gca, 'type', 'line'), 'LineWidth', 1.2);
end


% to cropt using the ylim, only if baseline is there
ylim([-0.85, max([T.baseline])])



for i = 1:size(T,2) % all participants
    % all at once
    % plot([1:numel(data)], struct2array([T(1, i)]));

    lines = struct2array([T(1, i)]);

    for b = 1:numel(data)-1 % block
        %plot([1:numel(data)], struct2array([T(1, i)]));
        color = [];
        width = [];
        if lines(b+1) > B(i) % if bigger than baseline
            color = aes.orange;
            width = 1;

            disp(['participant ', num2str(i), ' increased alpha over the baseline in block', num2str(b+1)])
            disp(' ')
        elseif lines(b+1) > lines(b)
            color = aes.clear_grey; 
            width = 0.7;
        else
            color = aes.clear_grey;
            width = 0.7;
        end

        plot([b, b+1], [lines(b), lines(b+1)], 'Color', color, 'LineWidth', width)
    end
end


% add x labels
xticks(1:5)
xticklabels({'Baseline', 'Block 1', 'Block 2', 'Block 3', 'Block 4'})
ylabel('Normalized AAA (z-score)')

% daniela's chunk
ax = gca;
set(ax, 'Box', 'off'); % removes the big box
%axis square;
ax.LineWidth = 2;
set(ax, 'TickDir', 'out'); % moves the ticks out
ax.TickLength = [0.02 0.02]; % makes them thicke
ax.Layer = 'top';
%ax.Legend.FontSize = 11;
af = gcf;
af.Position = [1 1 800 600]; % for the window undock size

print(gcf, [paths.derivatives, '\mt8_blocks'], '-dpng', '-r300');

%% numbers to report
clear report

report.baseline_m = mean(B);
report.baseline_sd = std(B);

report.b1_m = mean([T.block1]);
report.b1_sd = std([T.block1]);

report.b2_m = mean([T.block2]);
report.b2_sd = std([T.block2]);

report.b3_m = mean([T.block3]);
report.b3_sd = std([T.block3]);

report.b4_m = mean([T.block4]);
report.b4_sd = std([T.block4]);

% percent change, calculated for my thesis
report.pct_change_m = mean([23.55, 24.71, 18.67, 19,36]);
report.pct_change_std = mean([11.91, 15.29, 15.37, 16.75]);
