%% mt5_discrimination_magnitude_effect
% Analyzes the magnitude effect on discrimination accuracy, and plots the
% percent correct in percentile bins for the whole group and for
% participants with significant correlations.
% Author: Alexis Olguin Baxman
% Date: 16.10.2026

close all; clear; clc; beep off;

paths.main     = 'C:\Users\Leonie\Documents\mt';
paths.lib = [paths.main, '\libs'];
paths.script = [paths.main, '\code\analysis'];
paths.derivatives = [paths.main, '\derivatives\mt5'];

if exist(paths.derivatives) == 0
    mkdir(paths.derivatives)
end

% knobs: used for switch-cases
knob.plot = 1; % heavy ploting
knob.distance = 3;
% 1 as before: midpoint
% 2 with task averages:block specific
% 3 mean: global
knob.deutsch = 0; % 1, changes the plots to deutsch. 0, english


% trials per condition
test.reg = 32;
test.disc = 20;

% colors
aes.orange = [0.8500 0.3250 0.0980]	;
aes.clear_orange = aes.orange * 0.7 + [1 1 1] * 0.3;
aes.green = [0.1 0.6 0.1];
aes.purple = [0.4940 0.1840 0.5560];
aes.dark_blue = [0 0.3098 0.6235];
aes.thick = 0.5;
edges = 0:0.2:1; % for normalized histograms

% to choose participants
subs = readtable([paths.main, '\participants.tsv'], "FileType","text",'Delimiter', '\t');

%% for loop
for p = 1:length(subs.participant_id)
    if strcmp(subs.INCLUDE{p}, 'Yes')
        hyp3(p).id = subs.participant_id(p);
        paths.in = fullfile(paths.main, subs.participant_id{p}, 'eeg\', [subs.participant_id{p}, '_task-neurofeedback']);

        %% load participants
        load([paths.in, '_storage.mat']);
        load([paths.in, '_trial.mat']);
        load([paths.in, '_thres.mat']);
        load([paths.in, '_task.mat']);


        %% create table
        t = table;
        t.trial = storage.trial(:);
        t.training = storage.training(:);
        t.condition  = storage.condition(:);
        t.task = storage.task(:); % is it used?

        if length(storage.reward) < length(storage.trial)
            % storage.reward only keeps the regulation reward
            diff = length(storage.trial) - length(storage.reward);
            storage.reward(end:end+diff) = 0;
        end

        % discrimination
        t.state = storage.state(:);
        t.response = storage.response(:);

        % add discrimination performance
        for i = 1:length(storage.trial)
            if storage.task(i) == 1 % regulation task
                storage.reward_disc(i) = 0;
            elseif storage.task(i) == 2 % discrimination task
                if storage.state(i) == storage.response(i)
                    storage.reward_disc(i) = 1; % correct
                else
                    storage.reward_disc(i) = 3; % incorrect
                end

            end
        end


        t.disc_reward = storage.reward_disc(:);
        t.trial_average = trial.average(:);

        % introduce task average
        storage.task_average(1:21) = task.average(1); % hardcoded
        storage.task_average(end+1:end+test.reg/2) = task.average(2);
        storage.task_average(end+1:end+test.disc/2) = task.average(3);
        storage.task_average(end+1:end+test.reg/2) = task.average(4);
        storage.task_average(end+1:end+test.disc/2) = task.average(5);
        storage.task_average(end+1:end+test.reg/2) = task.average(6);
        storage.task_average(end+1:end+test.disc/2) = task.average(7);
        storage.task_average(end+1:end+test.reg/2) = task.average(8);
        storage.task_average(end+1:end+test.disc/2) = task.average(9);

        t.task_average = storage.task_average(:);
        %% erase training trials
        t = t(t.training == 0, :);
        t = t(t.task==2,:); % erase regulation task
        % erase columns bc we won't use them again
        t.training = [];
        t.task = [];




        %% save all participants AAA
        hyp3(p).success = [];
        hyp3(p).dist_success = [];
        hyp3(p).abs_dist_success = [];
        hyp3(p).loss = [];
        hyp3(p).dist_loss = [];
        hyp3(p).abs_dist_loss = [];


        for trial = 1:size(t, 1)
            if t.disc_reward(trial) == 1
                hyp3(p).success = [hyp3(p).success, t.trial_average(trial)];
                hyp3(p).dist_success = [hyp3(p).dist_success, t.trial_average(trial) - t.task_average(trial)];
                hyp3(p).abs_dist_success = [hyp3(p).abs_dist_success, abs(t.trial_average(trial) - t.task_average(trial))];

            elseif t.disc_reward(trial) == 3
                hyp3(p).loss = [hyp3(p).loss, t.trial_average(trial)];
                hyp3(p).dist_loss = [hyp3(p).dist_loss, t.trial_average(trial) - t.task_average(trial)];
                hyp3(p).abs_dist_loss = [hyp3(p).abs_dist_loss, abs(t.trial_average(trial) - t.task_average(trial))];

            end % if reward = 1
        end

        %% basic stats: every row is a participant
        hyp3(p).mean.success = mean(hyp3(p).success);
        hyp3(p).mean.loss = mean(hyp3(p).loss);
        hyp3(p).mean.dist_succes = mean(hyp3(p).dist_success);
        hyp3(p).mean.dist_loss= mean(hyp3(p).dist_loss);
        hyp3(p).mean.abs_dist_success = mean(hyp3(p).abs_dist_success);
        hyp3(p).mean.abs_dist_loss = mean(hyp3(p).abs_dist_loss);


    end % for if loop
end % end of the big loop

% fix hyp3
% do not re-run
hyp3_process = hyp3;
clear hyp3
counter = 1;
for i = 1:length(hyp3_process)
    if ~isempty(hyp3_process(i).success)
        hyp3(counter) = hyp3_process(i);
        counter = counter+1;
    end
end
clear hyp3_process

%% exploratory analysis
%cd('C:\Users\jofo2989\AppData\Roaming\MathWorks\MATLAB Add-Ons\Functions\Shapiro-Wilk and Shapiro-Francia normality tests')

%[sw.succ_H, sw.succ_p, sw.succ_W] = swtest([hyp3.mean_success]);
%[sw.loss_H, sw.loss_p, sw.loss_W] = swtest([hyp3.mean_loss]);

%[h3.h, h3.p, h3.ci, h3.stats] = ttest([hyp3.mean_success], [hyp3.mean_loss]);
%[h3.signrank.p, h3.signrank.h, h3.signrank.stats] = signrank([hyp3.mean_success], [hyp3.mean_loss], 'method','approximate');


%% corr
% knob.distance = 2;

bins.n = 10; % quintiles

bins.edges = linspace(0, 1, bins.n+1); % since already normalized
% before, it fails because some values might be clustered around 0 or 1,
% and creates a lot of NaN


% Example: bin and compute accuracy
for p = 1:length(hyp3)

    switch knob.distance
        case 1 % - bin 5.5
            bins.all = [hyp3(p).success(:); hyp3(p).loss(:)];
        case 2 % from the task average
            % here it's not absolute, for the plot
            bins.all = [hyp3(p).dist_success(:); hyp3(p).dist_loss(:)];
        case 3 % - mean at the end
            bins.all = [hyp3(p).success(:); hyp3(p).loss(:)];
    end

    bins.edges = linspace(min(bins.all), max(bins.all), bins.n+1);

    % performance
    bins.perf = [ones(length(hyp3(p).success), 1);
        zeros(length(hyp3(p).loss), 1)]; % 1=success, 0=loss

    % divide data
    bins.idx = discretize(bins.all, bins.edges); % Group numeric data into bins or categories.

    % creates the accuracy, it's just based on performance
    % this is for the plot
    for b = 1:bins.n
        % p = participant (27)
        % b = bin (10)
        bins.acc(p, b) = mean(bins.perf(bins.idx == b));
        bins.number(p, b) = numel(bins.perf(bins.idx == b));
    end
    % fix nan values
    %     bins.acc(isnan(bins.acc)) = 0;

    switch knob.distance
        case 1 % we calculate the distance
            % we create the bin 5.5
            bins.b5 = bins.all(find([bins.idx] == 5));
            bins.b6 = bins.all(find([bins.idx] == 6));
            if ~isempty(bins.b5) && ~isempty(bins.b6)
                bins.mid = mean([mean(bins.b5), mean(bins.b6)]);
            elseif ~isempty(bins.b5)
                bins.mid = mean(bins.b5);
            elseif ~isempty(bins.b6)
                bins.mid = mean(bins.b6);
            end
            bins.dist_from_mid = abs(bins.all - bins.mid);

        case 2 % we already calculated the distance
            bins.dist_from_mid = [hyp3(p).abs_dist_success(:); hyp3(p).abs_dist_loss(:)];
            %                         bins.all = [hyp3(p).dist_success(:); hyp3(p).dist_loss(:)];

        case 3 % average of all?
            bins.dist_from_mid = abs(bins.all - mean(bins.all));
    end

    %% check normality
    %     cd('C:\Users\jofo2989\AppData\Roaming\MathWorks\MATLAB Add-Ons\Functions\Shapiro-Wilk and Shapiro-Francia normality tests')
    %     [sw.H, sw.p, sw.W] = swtest([bins.dist_from_mid]);
    %     if sw.H == 1
    %         disp('reject normality, Shapiro–Wilk: H =', num2str(sw.H),' p = ',  num2str(sw.p))
    %     else
    %         disp('normality, Shapiro–Wilk: H =', num2str(sw.H),' p = ',  num2str(sw.p))
    %
    %     end

    % apply corr
    [hyp3(p).r, hyp3(p).p_value] = corr(bins.perf, bins.dist_from_mid, 'Type', 'Pearson');
    % corrected
    hyp3(p).corr_p_value = hyp3(p).p_value*3;

    %     hyp3(p).dist_succes = bins.dist_from_mid(1:length(hyp3(p).success));
    %     hyp3(p).dist_loss = bins.dist_from_mid(length(hyp3(p).success)+1:end);

    % uniform test
    %hyp3(p).mid = bins.mid;
    hyp3(p).summary.mean = mean(bins.all);
    hyp3(p).summary.median = median(bins.all);
    hyp3(p).summary.difference = abs(hyp3(p).summary.mean - hyp3(p).summary.median);
    hyp3(p).summary.skew = skewness(bins.all);


    if hyp3(p).corr_p_value < 0.05
        disp(['significant for participant: ', num2str(hyp3(p).id{1}), '; r = ', num2str(hyp3(p).r)])

        % septmber 8th
        figure;
        b = bar(bins.acc(p,:), '');
        b.FaceColor = 'flat';
        b.CData(:,:) = repmat(aes.dark_blue, numel(bins.acc(p,:)), 1);

        title([num2str(hyp3(p).id{1}), ' (r: ', num2str(hyp3(p).r), ')'], 'Interpreter','none')

        xlabel('Percentiles');
        ylabel('Percent Correct');
        xticks(1:length(bins.acc(p,:)));
        xticklabels({'pct10','pct20','pct30','pct40','pct50','pct60','pct70','pct80','pct90','pct100'});
        ylim([0 1]);

        paths.save = fullfile(paths.derivatives, hyp3(p).id{1});

        if exist(paths.save) == 0
            mkdir(paths.save)
        end

        switch knob.distance % 1 midpoint, 2 block specific, 3 whole mean
            case 1
                print(gcf, [paths.save, '\mt5_', num2str(hyp3(p).id{1}), '_midpoint' ], '-dpng', '-r300');
            case 2
                print(gcf, [paths.save, '\mt5_', num2str(hyp3(p).id{1}), '_block' ], '-dpng', '-r300');
            case 3
                print(gcf, [paths.save, '\mt5_', num2str(hyp3(p).id{1}), '_overall' ], '-dpng', '-r300');
        end



    end

end

%% Average over participants
% proportion of successes in that bin
bins.average = mean(bins.acc, 1, 'omitnan');
% avergae through every bin
n = sum(~isnan(bins.acc), 1); % how many observations contribute per bin
bins.std_error = std(bins.acc, 0, 1, 'omitnan') ./ sqrt(n);

% general tau: wrong, error type 1
% general.perf = [];
% general.all = [];
%
% for p = 1:length(bins.general)
%     general.perf = [general.perf, bins.general(p).perf'];
%     general.all = [general.all, bins.general(p).all'];
% end
%
% [general.tau, general.p_value] = corr(general.perf', general.all', 'Type', 'Kendall');

r.average = mean([hyp3.r]);
r.median = median([hyp3.r]);
r.std = std([hyp3.r]);
[r.p_wilcoxon, ~] = signrank([hyp3.r]);
[~, p_t] = ttest([hyp3.r]);

disp(['average r: ', num2str(r.average)])
disp(['median r: ', num2str(r.median)])
disp(['std r: ', num2str(r.std)])
disp(['Wilcoxon signed-rank test p: ', num2str(r.p_wilcoxon)])


% fisher
fish.z = atanh([hyp3.r]);
[fish.h, fish.p, fish.ci, fish.stats] = ttest(fish.z, 0);

fish.z_mean = mean(fish.z);
fish.r_mean = tanh(fish.z_mean); % transform back
fish.ci = tanh(fish.ci);


disp(['Group level mean r (via Fisher z): ', num2str(fish.r_mean)])
disp(['95%% CI for r: [', num2str(fish.ci(1)), ' & ', num2str(fish.ci(2)),']'])
fprintf('t(%d) = %.3f, p = %.3f\n', fish.stats.df, fish.stats.tstat, fish.p);

%disp(['Wilcoxon signed-rank test p: ', num2str(r.p_wilcoxon)])



%% plotting all bins
figure;
b = bar(bins.average*100);
% make all bars gray first
b.FaceColor = 'flat';
b.CData(:,:) = repmat(aes.dark_blue, numel(bins.average), 1);
hold on;
errorbar(1:length(bins.average*100), bins.average*100, bins.std_error*100, 'k.', 'LineWidth', 1.5);
hold off;

switch knob.deutsch
    case 0
        xlabel('Amplitude Percentile Bin', 'FontSize', 17);
        ylabel('Percent Correct (%)', 'FontSize', 17);
    case 1
        xlabel('Amplituden-Perzentil-Bin', 'FontSize', 17);
        ylabel('Prozent korrekt (%)', 'FontSize', 17);
end


xticks(1:length(bins.average));
xticklabels({'pct10','pct20','pct30','pct40','pct50','pct60','pct70','pct80','pct90','pct100'});
ylim([0 100]);


text(7, 95, {'\it{p}\rm = .01 (Wilcoxon)'}, ...
    'FontSize', 15, ...
    'FontName', 'Helvetica', ...
    'Interpreter', 'tex', ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', 'top', ...
    'EdgeColor', 'w', ...            % black border
    'BackgroundColor', 'w', ...      % white fill (covers any bar/gridline behind it)
    'Margin', 8);

% daniela's chunk
data = bins.average;
set(gca, 'XTick', [1:length(data)], 'Fontsize', 15);
ax = gca;
set(ax, 'Box', 'off'); % removes the big box
%axis square;
ax.LineWidth = 2;
set(ax, 'TickDir', 'out'); % moves the ticks out
ax.TickLength = [0.02 0.02]; % makes them thicke
ax.Layer = 'top';
%ax.Legend.FontSize = 11;
af = gcf;
af.Position = [1 1 800 455]; % for the window undock size



        print(gcf, [paths.derivatives, '\mt5_group'], '-dpng', '-r300');





