%% mt6_criteria
% Analyzes Frederick et al. (2016) criterion for regulation and
% discrimination in our sample, plotting the regulation amplitude
% modulation.
% Author: Alexis Olguin Baxman
% Date: 16.10.2026

close all; clear; clc; beep off;


paths.main     = 'C:\Users\Leonie\Documents\mt';
paths.lib = [paths.main, '\libs']; addpath(paths.lib); 
paths.script = [paths.main, '\code\analysis'];
paths.derivatives = [paths.main, '\derivatives\mt8_2'];
paths.documents = [paths.main, '\documents\']; % this is unique


if exist(paths.derivatives) == 0
    mkdir(paths.derivatives)
end

cd(paths.script)


knob.debugging = 0; % to save figures and things: 0
knob.violin = 1; % do we want to plot violins?
knob.mixed = 1; % 0 divide, 4 plots


% trials per condition
test.reg = 32;
test.disc = 20;


% colors
aes.orange = [0.8500 0.3250 0.0980]	;
aes.blue = [0 0.4470 0.7410]	;
aes.dark_green = [0.1 0.6 0.1];
aes.green = [0.4660 0.6740 0.1880];
aes.purple = [0.4940 0.1840 0.5560];
aes.grey = [0.3 0.3 0.3];
aes.white = [1 1 1];
aes.clear_purple = [0.7940 0.4840 0.8560];
aes.clear_grey = [0.8 0.8 0.8];
aes.dark_blue = [0.1010 0.4450 0.6330];
aes.clear_grey = [0.8 0.8 0.8];
aes.thick = 0.5;
edges = 0:0.2:1; % for normalized histograms

% keypress code
trigger.upreg_on = 41; % evaluation starts: up-regulation
trigger.doreg_on = 42; % evaluation starts: down-regulatio
trigger.disc_on = 51; % evaluation starts: discrimination


% criterion structure
criterion.id = [];
criterion.upreg = [];
criterion.upreg_succ = [];
criterion.upreg_unsucc = [];

criterion.doreg = [];
criterion.doreg_succ = [];
criterion.doreg_unsucc = [];

criterion.exp_doreg = [];
criterion.cntrl_doreg = [];
criterion.exp_upreg = [];
criterion.cntrl_upreg = [];


% discrimination binomial calculation
bin.chance = 0.5;
bin.pVals = zeros(1, test.disc*2+1); % pre-allocation, there will be as many as n+1
for k = 0:(test.disc*2)
    % p of getting >= k correct by chance
    bin.pVals(k+1) = 1 - binocdf(k-1, test.disc*2, bin.chance);
end

% find thresholds: the smallest k so the p value
bin.f12 = find(bin.pVals < 0.01, 1, 'first');
bin.f16 = find(bin.pVals < 0.05,1 ,'first');

disp(['Criterion 2012 p<.01 = ', num2str(bin.f12-1), '/', num2str(test.disc*2), ' correc trials (', num2str(((bin.f12-1)/(test.disc*2))*100) ,'%)'])
disp(['Criterion 2016 p<.05 = ', num2str(bin.f16-1), '/', num2str(test.disc*2), ' correc trials (', num2str(((bin.f16-1)/(test.disc*2))*100) ,'%)'])


% to choose participants
subs = readtable([paths.main, '\participants.tsv'], "FileType","text",'Delimiter', '\t');

% to store all tables
T = cell(1, sum(strcmp(subs.INCLUDE, 'Yes')));


%% for loop

for p = 1:length(subs.participant_id)
    if strcmp(subs.INCLUDE{p}, 'Yes')

        %% load participants
        paths.in = fullfile(paths.main, subs.participant_id{p}, 'eeg\', [subs.participant_id{p}, '_task-neurofeedback']);

        load([paths.in, '_storage.mat']);
        load([paths.in, '_trial.mat']);
        load([paths.in, '_task.mat']);
        load([paths.in,  '_EM.mat']);
        load([paths.in,  '_score_fixed.mat']);


        %% build direction
        direction = [];

        for marker = 1:length(EM.time_series)
            if EM.time_series(marker) == trigger.upreg_on
                direction = [direction, trigger.upreg_on]; % upregulation
            elseif EM.time_series(marker) == trigger.doreg_on
                direction = [direction, trigger.doreg_on]; % downregulation
            elseif EM.time_series(marker) == trigger.disc_on
                direction = [direction, trigger.disc_on]; % discrimination
            end % if loop
        end % for loop

        %% create table
        t = table;
        t.trial = storage.trial(:);
        t.training = storage.training(:);
        t.condition  = storage.condition(:);
        t.task = storage.task(:);
        if length(storage.reward) < length(storage.trial)
            % storage.reward only keeps the regulation reward
            diff = length(storage.trial) - length(storage.reward);
            storage.reward(end:end+diff) = 0;
        end

        t.reg_reward = storage.reward(:); % only for regulation
        t.direction = direction(:); % just fixed
        t.alpha = trial.average(:);
        t.alpha_std = trial.std(:);

        %% erase training trials
        t = t(t.training == 0, :);

        %% criterion table

        criterion(end+1).id = subs.participant_id(p);
        for trial = 1:length(t.direction)
            if t.direction(trial) == trigger.upreg_on
                criterion(end).upreg = [criterion(end).upreg, t.alpha(trial)];

                % divide by success or not
                if t.reg_reward(trial) == 1
                    criterion(end).upreg_succ = [criterion(end).upreg_succ, t.alpha(trial)];
                elseif t.reg_reward(trial) == 0
                    criterion(end).upreg_unsucc = [criterion(end).upreg_unsucc, t.alpha(trial)];
                end

                % divide by condition
                if t.condition(trial) == 1
                    criterion(end).exp_upreg = [criterion(end).exp_upreg, t.alpha(trial)];
                elseif t.condition(trial) == 0
                    criterion(end).cntrl_upreg = [criterion(end).cntrl_upreg, t.alpha(trial)];
                end


                % downregulation
            elseif t.direction(trial) == trigger.doreg_on
                criterion(end).doreg = [criterion(end).doreg, t.alpha(trial)];

                % divide by success or not
                if t.reg_reward(trial) == 1
                    criterion(end).doreg_succ = [criterion(end).doreg_succ, t.alpha(trial)];
                elseif t.reg_reward(trial) == 0
                    criterion(end).doreg_unsucc = [criterion(end).doreg_unsucc, t.alpha(trial)];
                end

                % divide by condition
                if t.condition(trial) == 1
                    criterion(end).exp_doreg = [criterion(end).exp_doreg, t.alpha(trial)];
                elseif t.condition(trial) == 0
                    criterion(end).cntrl_doreg = [criterion(end).cntrl_doreg, t.alpha(trial)];
                end

            end % ifupreg_on
        end % for trial

        criterion(end).reg_perf = sum(score.up + score.down)/(test.reg*2)*100;

        % discrimination

        % how many high and low trials
        criterion(end).disc_high_trials = score.th + score.fl;
        criterion(end).disc_low_trials = score.tl + score.fh;
        criterion(end).disc_succeful = score.th+score.tl;
        criterion(end).BA = score.balanced_accuracy;


        %% binomial calculation

        criterion(end).sensitivity = score.sensitivity;
        criterion(end).specificity = score.specificity ;
        criterion(end).f12_ba = score.balanced_accuracy > ((bin.f12-1)/(test.disc*2));
        criterion(end).f16_ba = score.balanced_accuracy > ((bin.f16-1)/(test.disc*2));
        criterion(end).f12_trials = criterion(end).disc_succeful >= bin.f12-1;
        criterion(end).f16_trials = criterion(end).disc_succeful >= bin.f16-1;
        
        % which were below 50% accuracy
        criterion(end).ba_failed = score.balanced_accuracy < 0.5;




    end % if include
end

disp(['participants with accuracy below 50%: ', num2str(sum([criterion.ba_failed]))])

% fix table
criterion = criterion(2:end);
summary = struct();
%% check criterion

for c = 1:length(criterion)
   
            % descriptive stats
            criterion(c).Inc = mean(criterion(c).upreg);
            criterion(c).Dec = mean(criterion(c).doreg);

            criterion(c).Exp_Inc = mean(criterion(c).exp_upreg);
            criterion(c).Exp_Dec = mean(criterion(c).exp_doreg);
            criterion(c).Cntrl_Inc = mean(criterion(c).cntrl_upreg);
            criterion(c).Cntrl_Dec = mean(criterion(c).cntrl_doreg);

            criterion(c).Inc_median = median(criterion(c).upreg);
            criterion(c).Inc_std = std(criterion(c).upreg);
            criterion(c).Dec_median = median(criterion(c).doreg);
            criterion(c).Dec_std = std(criterion(c).doreg);


    % criterion check
    criterion(c).pct = 100 * (criterion(c).Inc - criterion(c).Dec) ./ ((criterion(c).Inc + criterion(c).Dec)/2);  % percent difference
    criterion(c).Exp_pct = 100 * (criterion(c).Exp_Inc - criterion(c).Exp_Dec) ./ ((criterion(c).Exp_Inc + criterion(c).Exp_Dec)/2);  % percent difference
    criterion(c).Cntrl_pct = 100 * (criterion(c).Cntrl_Inc - criterion(c).Cntrl_Dec) ./ ((criterion(c).Cntrl_Inc + criterion(c).Cntrl_Dec)/2);  % percent difference

    criterion(c).reached = criterion(c).pct >= 10;    % boolean per segment/value

    % which participants fullfill criterion
    if criterion(c).reached == 1
        switch knob.mixed
            case 1 % 2 violin plots
                

                        data = [{criterion(c).upreg}; {criterion(c).doreg}];
                        aes.label = {'upregulation AAA','downregulation AAA'};
                aes.colors = [aes.purple; aes.grey];

            case 0 % 4 violin plots
                data = [{criterion(c).exp_upreg}; {criterion(c).exp_doreg}; {criterion(c).cntrl_upreg}; {criterion(c).cntrl_doreg}];

                aes.label = {'experimental upregulation','experimental downregulation', 'control upregulation', 'control downregulation'};
                aes.colors = [aes.purple; aes.grey; aes.clear_purple; aes.clear_grey];
        end



        message = ['Participant: ', criterion(c).id{1}, '. Percent difference: ', num2str(criterion(c).pct)];

        switch knob.violin
            case 1
                figure;
                violin(data', 'xlabel', aes.label, 'facecolor', aes.colors);
                for i = 1:length(data)
                    boxplot(data{i}, 'Position', i, 'Labels', 'none');
                end

                set(gca, 'XTick', [1:length(data)], 'XTickLabel', aes.label, 'Fontsize', 13);
                title(message)
                %grid on
                ylabel('Absolute Alpha Amplitude')

                % daniela's chunk
                ax = gca;
                set(ax, 'Box', 'off'); % removes the big box
                %axis square;
                ax.LineWidth = 2;
                set(ax, 'TickDir', 'out'); % moves the ticks out
                ax.TickLength = [0.02 0.02]; % makes them thicke
                ax.Layer = 'top';
                ax.Legend.FontSize = 11;
                af = gcf;
                af.Position = [1 1 670 445]; % for the window undock size

                switch knob.debugging
                    case 0


                        paths.save = fullfile(paths.derivatives, criterion(c).id{1});
                        if exist(paths.save) == 0
                            mkdir(paths.save);
                        end

                        print(gcf, [paths.save, '\mt8_', criterion(c).id{1}], '-dpng', '-r300');
                end

        end % knob.violin

        % anova
        switch knob.mixed
            case  0 % 4 violin plots
                tab = table(data{1}', data{2}', data{3}', data{4}', ...
                    'VariableNames', {'Exp_Up','Exp_Down','Ctrl_Up','Ctrl_Down'});
                % Define within-subject factors: 2x2
                WithinDesign = table({'Exp'; 'Exp'; 'Ctrl'; 'Ctrl'}, ...   % Condition
                    {'Up'; 'Down'; 'Up'; 'Down'}, ...   % Direction
                    'VariableNames', {'Condition','Direction'});

                % Fit repeated measures model
                %rm = fitrm(tab, 'Exp_Up-Ctrl_Down ~ 1', 'WithinDesign', WithinDesign);
                rm = fitrm(tab, 'Exp_Up,Exp_Down,Ctrl_Up,Ctrl_Down ~ 1', 'WithinDesign', WithinDesign);

                % Run repeated measures ANOVA
                ranovatbl = ranova(rm, 'WithinModel', 'Condition*Direction');%, 'Direction', 'size');
                directiontable = multcompare(rm, 'Direction')
                conditiontable = multcompare(rm, 'Condition')
                %         interactiontable =  multcompare(rm, 'Condition*Direction')
        end
        summary.criterion(c).average_up = mean(criterion(c).upreg);
        summary.criterion(c).std_up = std(criterion(c).upreg);
        summary.criterion(c).max_up = max(criterion(c).upreg);
        summary.criterion(c).min_up = min(criterion(c).upreg);

        summary.criterion(c).average_do = mean(criterion(c).doreg);
        summary.criterion(c).std_do = std(criterion(c).doreg);
        summary.criterion(c).max_do = max(criterion(c).doreg);
        summary.criterion(c).min_do = min(criterion(c).doreg);




    end % if criterion
end

%% general plot: amplitude difference

% with normaliation
Inc_norm = [];
Dec_norm = [];

for p = 1:length([criterion.Inc])
    min_edge = min(criterion(p).upreg, criterion(p).doreg);
    max_edge = max(criterion(p).upreg, criterion(p).doreg);

    Inc_norm(p) = (criterion(p).Inc - min_edge) / (max_edge - min_edge);
    Dec_norm(p) = (criterion(p).Dec - min_edge) / (max_edge - min_edge);

end

data = [{[Inc_norm]}; {[Dec_norm]}];
aes.label = {'upregulation AAA','downregulation AAA'};
aes.colors = [aes.purple; aes.grey];

switch knob.violin
    case 1
        figure;
        violin(data', 'xlabel', aes.label, 'facecolor', aes.colors);
        for i = 1:length(data)
            boxplot(data{i}, 'Position', i, 'Labels', 'none');
        end

        set(gca, 'XTick', [1:length(data)], 'XTickLabel', aes.label, 'Fontsize', 14);
        
                title(['Average percent difference (', num2str(round(mean([criterion.pct]), 2)), '%) across all participants'], 'FontSize', 16)
        %grid on
        ylabel('Normalized AAA (0-1)', 'FontSize', 13)


        % daniela's chunk
        ax = gca;
        set(ax, 'Box', 'off'); % removes the big box
        %axis square;
        ax.LineWidth = 2;
        set(ax, 'TickDir', 'out'); % moves the ticks out
        ax.TickLength = [0.02 0.02]; % makes them thicke
        ax.Layer = 'top';
        ax.Legend.FontSize = 11;
        af = gcf;
        af.Position = [1 1 700 500]; % for the window undock size


        switch knob.debugging
            case 0
                print(gcf, [paths.derivatives, '\mt8_group_amplitude_difference'], '-dpng', '-r300');
        end
end

summary.pct.average = mean([criterion.pct]);
summary.pct.median = median([criterion.pct]);
summary.pct.std = std([criterion.pct]);
summary.pct.max = max([criterion.pct]);
summary.pct.min = min([criterion.pct]);

%% plot discrimination direction

% let's modify this to get the percentages already
% old plot, we plot the percentage but we didn't have the value:
% data = [{[[criterion.disc_high_trials]/(test.disc*2)*100]}; {[[criterion.disc_low_trials]/(test.disc*2)*100]}];

trials.disc_high = [criterion.disc_high_trials]./(test.disc*2)*100;
trials.disc_low = [criterion.disc_low_trials]./(test.disc*2)*100;

data = [{trials.disc_high}; {trials.disc_low}];
aes.label = {'High Alpha State Trials','Low Alpha State Trials'};
aes.colors = [aes.clear_purple; aes.clear_grey];

% switch knob.violin
%     case 1
% 
%         figure;
%         violin(data', 'xlabel', aes.label, 'facecolor', aes.colors);
%         for i = 1:length(data)
%             boxplot(data{i}, 'Position', i, 'Labels', 'none');
%         end
% 
%         set(gca, 'XTick', [1:length(data)], 'XTickLabel', aes.label, 'Fontsize', 14);
% 
%         title(['Frequency high & low alpha state trials'])
% 
%         grid on
%         ylabel('Frequency (%)')
% 
%         switch knob.debugging
%             case 0
%                 print(gcf, [paths.derivatives, '\mt8_group_freq_high_low_trials'], '-dpng', '-r300');
%         end
% 
% end % knob.violin

summary.high_trials.average = mean([trials.disc_high]);
summary.high_trials.median = median([trials.disc_high]);
summary.high_trials.std = std([trials.disc_high]);
summary.high_trials.max = max([trials.disc_high]);
summary.high_trials.min = min([trials.disc_high]);

summary.low_trials.average = mean([trials.disc_low]);
summary.low_trials.median = median([trials.disc_low]);
summary.low_trials.std = std([trials.disc_low]);
summary.low_trials.max = max([trials.disc_low]);
summary.low_trials.min = min([trials.disc_low]);




x = [criterion.reg_perf];
y = [criterion.pct];
d = x-y;

disp(' ')
disp('correlation regulation performance and pct:')
[r,p] = corr(x', y');
disp(['r = ', num2str(r), '. p = ', num2str(p)])

% plot correlation

figure
scatter(x, y, 40, 'filled');
hold on

% fit linear regression
p = polyfit(x, y, 1);
x_fit = linspace(min(x), max(x), 100);
y_fit = polyval(p, x_fit);

plot(x_fit, y_fit, 'LineWidth', 2);
yline(10, '--', 'LineWidth', 1.5);
xlabel('Regulation Performance (%)');
ylabel('Amplitude Difference (%)');

ax = gca;
set(ax, 'FontName', 'Arial')
set(ax, 'FontSize', 16)
set(ax, 'Box', 'off'); % removes the big box
%axis square;
ax.LineWidth = 2;
set(ax, 'TickDir', 'out'); % moves the ticks out
ax.TickLength = [0.02 0.02]; % makes them thicke
ax.Layer = 'top';
af = gcf;
af.Position = [2 2 700 800]; % for the window undock size

print(gcf, [paths.derivatives, '\mt6_group_corr_reg_pct'], '-dpng', '-r300');



%% statistics: comparing alpha amplitude between experimental trials and control trials
h1 = [];
[h1.h, h1.p, h1.ci, h1.stats] = ttest([criterion.Exp_pct], [criterion.Cntrl_pct]);

h1.diff = mean([criterion.Exp_pct] - [criterion.Cntrl_pct]);
h1.cohen = h1.diff / std([criterion.Exp_pct] - [criterion.Cntrl_pct]);

pct.exp = [];
pct.cntrl= [];

for i = 1:length(criterion)
    if criterion(i).reached == 1 % only those who reached
        pct.exp(end+1) = criterion(i).Exp_pct;
        pct.cntrl(end+1) = criterion(i).Cntrl_pct;
    end
end

% only with those who reached criterion
h2 = [];
[h2.h, h2.p, h2.ci, h2.stats] = ttest([pct.exp], [pct.cntrl]);


%% correlation regulation performance and balanced accuracy
% y = [criterion.BA]*100;
% 
% 
% disp('regulation performance and balanced accuracy')
% [r,p] = corr(x', y')
% 
% c = [0.0235,    0.4392,    0.0784];
% 
% figure
% scatter(x, y, 60, c, 'filled');
% hold on
% 
% % fit linear regression
% p = polyfit(x, y, 1);
% x_fit = linspace(min(x), max(x), 100);
% y_fit = polyval(p, x_fit);
% 
% plot(x_fit, y_fit, 'LineWidth', 2);
% 
% xlabel('Regulation Performance (%)');
% ylabel('Balanced Accuracy (%)');
% title('Correlation (r = 0.12, p = 0.53)');

% ax = gca;
% set(ax, 'FontName', 'Arial')
% set(ax, 'FontSize', 16)
% set(ax, 'Box', 'off'); % removes the big box
% %axis square;
% ax.LineWidth = 2;
% set(ax, 'TickDir', 'out'); % moves the ticks out
% ax.TickLength = [0.02 0.02]; % makes them thicke
% ax.Layer = 'top';
% af = gcf;
% af.Position = [2 2 700 800]; % for the window undock size
% 
% print(gcf, [paths.derivatives, '\mt8_group_corr_reg_ba'], '-dpng', '-r300');


%%
switch knob.debugging
    case 0
        cd(paths.derivatives)

        save(['group_criterion.mat'], 'criterion', '-v7')
end

cd(paths.script)

