%% mt4_run_main_analyses
% Compares the regulation and discrimination performance in both conditions,
% and plots the boxplots comparing performance.
% Author: Alexis Olguin Baxman
% Date: 16.10.2026

close all; clear; clc; beep off;

paths.main     = 'C:\Users\Leonie\Documents\mt';
paths.lib = [paths.main, '\libs'];
addpath(paths.lib) % for violin
paths.script = [paths.main, '\code\analysis'];
paths.derivatives = [paths.main, '\derivatives\mt4'];

if exist(paths.derivatives) == 0
    mkdir(paths.derivatives)
end


knob.plot = 3; 
% 1 - regulation performance: upregulation vs downregulation
% 2 - regulation performance: hybrid vs intermittent
% 3 - discrimination performance: hybrid vs intermittent

knob.hybrid = 1; % switches hybrid for experimental and intermittent for control
% 1 yes, 0 no

knob.deutsch = 0; % 1, changes the plots to deutsch. 0, english

% colors
aes.blue = [0.3010 0.7450 0.9330];
aes.green = [0.4660 0.6740 0.1880];
aes.purple = [0.4940 0.1840 0.5560];
aes.grey = [0.3 0.3 0.3];
aes.white = [1 1 1];
aes.clear_purple = [0.7940 0.4840 0.8560];
aes.clear_grey = [0.8 0.8 0.8];
aes.dark_blue = [0 0.3098 0.6235];
aes.clear_grey = [0.8 0.8 0.8];
aes.orange = [0.8500 0.3250 0.0980]	;
aes.thick = 0.5;
edges = 0:0.2:1; % for normalized histograms


% trials per condition
test.reg = 32;
test.disc = 20;

% participants' key press
high = 38;
low = 40;

% to store data
T = struct();

% read participants excel to later on choose which participants to load
subs = readtable([paths.main, '\participants.tsv'], "FileType","text",'Delimiter', '\t');

%%

for p = 1:length(subs.participant_id)
    if strcmp(subs.INCLUDE{p}, 'Yes')

        % load
        paths.in = fullfile(paths.main, subs.participant_id{p}, 'eeg\', [subs.participant_id{p}, '_task-neurofeedback']);

        load([paths.in, '_score_fixed.mat']);
    

            %% regulation task
            T(p).id = subs.participant_id(p);
            T(p).total_up = score.up;
            T(p).exper_up = score.exp.up;
            T(p).cntrl_up = score.cntrl.up;
            T(p).total_down = score.down;
            T(p).exper_down = score.exp.down;
            T(p).cntrl_down = score.cntrl.down;
            T(p).total_exp = score.exp.up+score.exp.down;
            T(p).total_cntrl = score.cntrl.up + score.cntrl.down;

            %% performance rates
            T(p).perf = round((sum(score.up + score.down)/(test.reg*2)*100), 2);
            T(p).perf_exp = round((sum(score.exp.up + score.exp.down)/(test.reg)*100), 2);
            T(p).perf_cntrl = round((sum(score.cntrl.up + score.cntrl.down)/(test.reg)*100), 2);
            T(p).perf_up = round((sum(score.exp.up + score.cntrl.up)/(test.reg)*100), 2);
            T(p).perf_down = round((sum(score.exp.down + score.cntrl.down)/(test.reg)*100), 2);

            T(p).perf_exp_up = score.exp.up / (test.reg/2)*100;
            T(p).perf_exp_down = score.exp.down / (test.reg/2)*100;
            T(p).perf_cntrl_up = score.cntrl.up / (test.reg/2)*100;
            T(p).perf_cntrl_down = score.cntrl.down / (test.reg/2)*100;

            %% discrimination task

            T(p).balanced_accuracy = score.balanced_accuracy;
            T(p).re_balanced_accuracy = ((score.sensitivity + score.specificity)/2)*100;
            T(p).exp_sensitivity = score.exp.th / (score.exp.th + score.exp.fl);
            T(p).exp_specificity = score.exp.tl / (score.exp.tl + score.exp.fh); % they were in low state
            T(p).exp_balanced_accuracy = (T(p).exp_sensitivity + T(p).exp_specificity)/2;
            T(p).exp_balanced_accuracy = (round(T(p).exp_balanced_accuracy*100,2));


            T(p).cntrl_sensitivity = score.cntrl.th / (score.cntrl.th + score.cntrl.fl);
            T(p).cntrl_specificity = score.cntrl.tl / (score.cntrl.tl + score.cntrl.fh); % they were in low state
            T(p).cntrl_balanced_accuracy = (T(p).cntrl_sensitivity  + T(p).cntrl_specificity)/2;
            T(p).cntrl_balanced_accuracy = (round(T(p).cntrl_balanced_accuracy*100,2));

            % true
            T(p).exp_true_high = score.exp.th;
            T(p).exp_true_low = score.exp.tl;
            T(p).cntrl_true_high = score.cntrl.th;
            T(p).cntrl_true_low = score.cntrl.tl;

            T(p).disc_true_high = score.exp.th + score.cntrl.th;
            T(p).disc_true_low = score.exp.tl + score.cntrl.tl;

            % false
            T(p).exp_false_high = score.exp.fh;
            T(p).exp_false_low = score.exp.fl;
            T(p).cntrl_false_high = score.cntrl.fh;
            T(p).cntrl_false_low = score.cntrl.fl;

            T(p).disc_false_high = score.exp.fh + score.cntrl.fh;
            T(p).disc_false_low = score.exp.fl + score.cntrl.fl;

            T(p).false_high = (score.exp.fh + score.cntrl.fh)/(test.disc*2)*100;
            T(p).false_low = (score.exp.fl + score.cntrl.fl)/(test.disc*2)*100;

            T(p).true_high = (score.exp.th + score.cntrl.th)/(test.disc*2)*100;
            T(p).true_low = (score.exp.tl + score.cntrl.tl)/(test.disc*2)*100;



    end


end


%% fix tables
keep = [];
for i = 1:length(T)
    if isempty(T(i).id)
        keep(i) = 0;
    elseif ~isempty(T(i).id)
        keep(i) = 1;
    end
end

T = T(logical(keep));








%% summary tables
% alpha

labels = fields(T);
TT = struct();

for i = 2:length(labels)
    data = [T.(labels{i})];
    TT(1).(labels{i}) = mean([data]);
    TT(2).(labels{i}) = median([data]);
    TT(3).(labels{i}) = std([data]);
    TT(4).(labels{i}) = min([data]);
    TT(5).(labels{i}) = max([data]);
end



%% violin plots


% 4 - anova: condition x direction
% 6 - regulation performance hybrid vs intermittent
% 7 - discrimination accuracy hybrid vs intermittent
% 3 upreg vs doreg
% 8 true high vs low; 10 false high vs low

switch knob.plot
    case 1 % regulation performance: upregulation vs downregulation
%         aes.colors = [aes.purple; aes.grey];
%         aes.label = {'Upregulation','Downregulation'};
%         data = [{[T.perf_up]}; {[T.perf_down]}];
%         message = 'Regulation Task';
%         messagey = 'Succesful Trials (%)';

    case 2 % regulation performance: hybrid vs intermittent
        aes.colors = [aes.blue; aes.white];

        switch knob.hybrid
            case 1
        aes.label = {'Hybrid','Intermittent'};
            case 0
                switch knob.deutsch
                    case 0
                        aes.label = {'Experimental','Control'};
                    case 1
                        aes.label = {'Experimentell','Kontrolle'};
                end % knob.deutsch
        end % knob.hybrid

        data = [{[T.perf_exp]}; {[T.perf_cntrl]}];

        switch knob.deutsch
            case 0
                message = 'Regulation Task';
                messagey = 'Succesful Trials (%)';
            case 1
                message = 'Regulationsaufgabe';
                messagey = 'Erfolgreiche Regulationstrials (%)'
        end

    case 3 % discrimination performance: hybrid vs intermittent
        aes.colors = [aes.blue; aes.white];

        switch knob.hybrid
            case 1
        aes.label = {'Hybrid','Intermittent'};
            case 0
                switch knob.deutsch
                    case 0
                        aes.label = {'Experimental','Control'};
                    case 1
                        aes.label = {'Experimentell','Kontrolle'};
                end % knob.deutsch
        end % knob.hybrid

        data = [{[T.exp_balanced_accuracy]}; {[T.cntrl_balanced_accuracy]}];

        switch knob.deutsch
            case 0 
        message = 'Discrimination Task';
        messagey = 'Balanced Accuracy (%)';
            case 1
        message = 'Diskriminationsaufgabe';
        messagey = 'Balanced Accuracy (%)';
        end
end


%% test normalcy

%         x = data{1};
%         y = data{2};
%         d = x-y;
%         [hL,pL]   = lillietest(d);
%         if hL == 1
%             disp('normalcy failed')
%         end
% 
%         cd('C:\Users\jofo2989\AppData\Roaming\MathWorks\MATLAB Add-Ons\Functions\Shapiro-Wilk and Shapiro-Francia normality tests')
% 
%         [H,p,W] = swtest(d);
%         if H == 1
%             disp('normalcy failed')
%         end



% statistics
switch knob.plot
    case {1, 2,3, 6, 7, 8, 10, 12}
        [h1.h, h1.p, h1.ci, h1.stats] = ttest(data{1}, data{2});

        if h1.h == 1
            disp('hypothesis is significative!')
        else
            disp('hypothesis is not significant')
        end

        h1.diff = mean(data{1} - data{2});
        h1.cohen = h1.diff / std(data{1} - data{2});
        disp(['Cohens d: ', num2str(h1.cohen)])
end


%% plot

figure;




violin_half(data', 'xlabel', aes.label, 'facecolor', aes.colors);
boxplot(data{1}, 'Position', 1, 'Labels', 'none');
set(findobj(gca, 'type', 'line'), 'LineWidth', 1.2);

boxplot(data{2}, 'Position', 2, 'Labels', 'none');
set(findobj(gca, 'type', 'line'), 'LineWidth', 1.2);

% draw brackets
br.y = max(max(data{1}), max(data{2})) + 5;
plot([1 1 2 2], [br.y br.y+2 br.y+2 br.y], 'k', 'LineWidth', 1)
%br.text = num2str(round(h1.p, 3));
%text(1.5, br.y+3.5, ['{\it p} = ', br.text], 'FontSize', 12)
text(1.5, br.y+4.5, 'n.s.', 'FontSize', 15)


set(gca, 'XTick', [1:length(data)], 'XTickLabel', aes.label, 'Fontsize', 17);


title(message, 'FontSize', 19)
% choose y label
ylabel(messagey, 'FontSize', 17)

ax = gca;
yticks(ax, 20:10:100)

set(ax, 'Box', 'off'); % removes the big box
%axis square;
ax.LineWidth = 2;
set(ax, 'TickDir', 'out'); % moves the ticks out
ax.TickLength = [0.02 0.02]; % makes them thicke
ax.Layer = 'top';
%ax.Legend.FontSize = 11;
af = gcf;
af.Position = [1 1 500 550]; % for the window undock size

%% save
paths.save = paths.derivatives;

switch knob.plot
     case 1 % regulation performance: upregulation vs downregulation
        print(gcf, [paths.save, '\mt4_upreg_vs_doreg'], '-dpng', '-r300');

    case 2 % regulation performance: hybrid vs intermittent
        print(gcf, [paths.save, '\mt4_reg_task_hyp1'], '-dpng', '-r300');
  
    case 3 % discrimination performance: hybrid vs intermittent
        print(gcf, [paths.save, '\mt4_disc_task_hyp2'], '-dpng', '-r300');
end


%% exploratory analysis 01.12
upreg = [T.perf_up]';
doreg = [T.perf_down]';
d = upreg-doreg;

% cd('C:\Users\jofo2989\AppData\Roaming\MathWorks\MATLAB Add-Ons\Functions\Shapiro-Wilk and Shapiro-Francia normality tests')
% [H,p,W] = swtest(d);
% if H == 1
%     disp('normalcy failed: Performance: Upregulation vs Downregulation')
% end


[r, p] = corr(upreg, doreg, 'Type', 'Pearson');

disp(' ')
disp('correlation up-regulation and downregulation')
fprintf('Pearson r = %.3f, p = %.3f\n', r, p);

%% paper

% regulation
paper.regulation_mean = mean([T.perf]);
paper.regulation_std = std([T.perf]);
paper.reg_exp_mean = mean([T.perf_exp]);
paper.reg_exp_std = std([T.perf_exp]);
paper.reg_ctrl_mean = mean([T.perf_cntrl]);
paper.reg_ctrl_std = std([T.perf_cntrl]);

% discrimination
paper.ba_mean = mean([T.re_balanced_accuracy]);
paper.ba_std = std([T.re_balanced_accuracy]);
paper.ba_exp_mean = mean([T.exp_balanced_accuracy]);
paper.ba_exp_std = std([T.exp_balanced_accuracy]);
paper.ba_ctrl_mean = mean([T.cntrl_balanced_accuracy]);
paper.ba_ctrl_std = std([T.cntrl_balanced_accuracy]);


cd(paths.script)

