%% mt9_amplitude_anova
% Analyzes and plots how alpha amplitude changes between directions and conditions
% Author: Alexis Olguin Baxman
% Date: 16.10.2026

clear all; close all; clc; beep off;

disp('mt9: amplitude anova AAA')

paths.main     = 'C:\Users\Leonie\Documents\mt';
paths.lib = [paths.main, '\libs']; addpath(paths.lib); 
paths.script = [paths.main, '\code\analysis'];
paths.derivatives = [paths.main, '\derivatives\mt9'];

if exist(paths.derivatives) == 0
    mkdir(paths.derivatives)
end

% cd(paths.script)

knob.division = 2; % for plotting order of the anova, just visual
% 1: hybrid --> intermittent
% 2: up --> down
knob.bracket = 1; % plot brackets in-between box and violin plots

knob.hybrid = 0; % switches hybrid for experimental and intermittent for control
% 1 yes, 0 no

knob.deutsch = 1; % 1, changes the plots to deutsch. 0, english

% trials per condition
test.reg = 32;
test.disc = 20;
test.block = 26;

% colors
aes.blue = [0.3010 0.7450 0.9330];
aes.green = [0.4660 0.6740 0.1880];
aes.purple = [0.4940 0.1840 0.5560];
aes.grey = [0.3 0.3 0.3];
aes.white = [1 1 1];
aes.clear_purple = [0.7940 0.4840 0.8560];
aes.clear_grey = [0.8 0.8 0.8];
aes.dark_blue = [0.1010 0.4450 0.6330];
aes.clear_grey = [0.8 0.8 0.8];
aes.orange = [0.8500 0.3250 0.0980]	;
aes.thick = 0.5;
edges = 0:0.2:1; % for normalized histograms

% to store all tables
T = struct();
R = struct();



% to choose participants
subs = readtable([paths.main, '\participants.tsv'], "FileType","text",'Delimiter', '\t');

counter = 1;

%% for loop
for p = 1:length(subs.participant_id)
    if strcmp(subs.INCLUDE{p}, 'Yes')
        paths.in = fullfile(paths.main, subs.participant_id{p}, 'eeg\', [subs.participant_id{p}, '_task-neurofeedback']);

        %% load participants
        %cd(fullfile(paths.main, subs.participant_id{p}, 'eeg\'));
        load([paths.in, '_score_fixed.mat']);
        load([paths.in, '_trial.mat']);
        load([paths.in, '_task.mat']);
        load([paths.in, '_storage.mat']);


        %% now let's make a study of regulation trials:
        % is percent difference across session (collapse conditon)
        % is upregulation higher in exp vs contrl
        % in downregulation lower in exp vs cotnrol
        % is percent difference higher in exp vs control

        R(counter).ID = subs.participant_id(p);
        % rename it to make it easier
        trials = trial.average(22:end);
        norm_trials = (trials - mean(trials))/std(trials);

        directions = storage.direction(22:end);
        conditions = storage.condition(22:end);
        tasks = storage.task(22:end);

        R(counter).exp_upreg = [];
        R(counter).cntrl_upreg = [];
        R(counter).exp_doreg = [];
        R(counter).cntrl_doreg = [];

        R(counter).norm_exp_upreg = [];
        R(counter).norm_cntrl_upreg = [];
        R(counter).norm_exp_doreg = [];
        R(counter).norm_cntrl_doreg = [];


        for t = 1:length(trials)
            if tasks(t) == 1 % regulation task
                if conditions(t) == 1 % xperimental
                    if directions(t) == 1 % upregulation
                        R(counter).exp_upreg = [R(counter).exp_upreg, trials(t)];
                        R(counter).norm_exp_upreg = [R(counter).norm_exp_upreg, norm_trials(t)];

                    elseif directions(t) == 0 % downregulation
                        R(counter).exp_doreg = [R(counter).exp_doreg, trials(t)];
                        R(counter).norm_exp_doreg = [R(counter).norm_exp_doreg, norm_trials(t)];

                    end % direction

                elseif conditions(t) == 0 % control
                    if directions(t) == 1 % upregulation
                        R(counter).cntrl_upreg = [R(counter).cntrl_upreg, trials(t)];
                        R(counter).norm_cntrl_upreg = [R(counter).norm_cntrl_upreg, norm_trials(t)];

                    elseif directions(t) == 0 % downregulation
                        R(counter).cntrl_doreg = [R(counter).cntrl_doreg, trials(t)];
                        R(counter).norm_cntrl_doreg = [R(counter).norm_cntrl_doreg, norm_trials(t)];

                    end % direction
                end % condition
            end
        end

        clear trials directions conditions tasks



        counter = counter+1;


    end % if loop: selection criteria
end % big for loop


%% trial-wise
trial_wise = [];
all_fields =fields(R);
for f = 6:length(all_fields)
    trial_wise.(all_fields{f}).mean = mean([R.(all_fields{f})]);
    trial_wise.(all_fields{f}).median = median([R.(all_fields{f})]);
    trial_wise.(all_fields{f}).std = std([R.(all_fields{f})]);
    trial_wise.(all_fields{f}).max = max([R.(all_fields{f})]);
    trial_wise.(all_fields{f}).min = min([R.(all_fields{f})]);
end

r.neu = []; % norm_exp_upreg
r.ncu = [];
r.ned = [];
r.ncd = [];
for s = 1:length(R) % subject
    r.neu(end+1) = mean(R(s).norm_exp_upreg);  
    r.ncu(end+1) = mean(R(s).norm_cntrl_upreg);
    r.ned(end+1) = mean(R(s).norm_exp_doreg);
    r.ncd(end+1) = mean(R(s).norm_cntrl_doreg);
end



%% normality check: it worked once, i don't need to double check
% cd('C:\Users\jofo2989\AppData\Roaming\MathWorks\MATLAB Add-Ons\Functions\Shapiro-Wilk and Shapiro-Francia normality tests')
% x = r.neu;
% y = r.ncu;
% d = x-y;
% 
% [H,p,W] = swtest(d);
% if H == 1
%     disp('normalcy failed: exper up vs cntrl up')
% else
%     disp('normalcy check')
% end
% 
% x = r.ned;
% y = r.ncd;
% d = x-y;
% 
% [H,p,W] = swtest(d);
% if H == 1
%     disp('normalcy failed: exper down vs cntrl down')
% else
%     disp('normalcy check')
% end


%% let's do an anova
ano.tab = table(r.neu', r.ned', r.ncu', r.ncd', ...
    'VariableNames', {'Exp_Up','Exp_Down','Ctrl_Up','Ctrl_Down'});
ano.WithinDesign = table({'Exp'; 'Exp'; 'Ctrl'; 'Ctrl'}, ...   % Condition
    {'Up'; 'Down'; 'Up'; 'Down'}, ...   % Direction
    'VariableNames', {'Condition','Direction'});

ano.rm = fitrm(ano.tab, 'Exp_Up,Exp_Down,Ctrl_Up,Ctrl_Down ~ 1', 'WithinDesign', ano.WithinDesign);
ano.ranovatbl = ranova(ano.rm, 'WithinModel', 'Condition*Direction');%, 'Direction', 'size');
ano.directiontable = multcompare(ano.rm, 'Direction');
ano.conditiontable = multcompare(ano.rm, 'Condition');

ano.eta_condition = ano.ranovatbl{3,1} / (ano.ranovatbl{3,1} + ano.ranovatbl{4,1});
ano.eta_direction = ano.ranovatbl{5,1} / (ano.ranovatbl{5,1} + ano.ranovatbl{6,1});
ano.eta_inter = ano.ranovatbl{7,1} / (ano.ranovatbl{7,1} + ano.ranovatbl{8,1});

%% let's plot this
disp(['mean up-exp: ', num2str(mean(r.neu))])
disp(['mean down-exp: ', num2str(mean(r.ned))])
disp(['mean up-cntrl: ', num2str(mean(r.ncu))])
disp(['mean down-cntrl: ', num2str(mean(r.ncd))])




switch knob.division
    case 1
        aes.colors = [aes.blue; aes.blue; aes.white; aes.white];
        switch knob.hybrid
            case 1
                aes.label = {'Up-Hyb','Down-Hyb', 'Up-Int', 'Down-Int'};
            case 0
                aes.label = {'Up-Exp','Down-Exp', 'Up-Cntrl', 'Down-Cntrl'};
        end
        data = [{[r.neu]}; {[r.ned]}; {[r.ncu]}; {[r.ncd]}];


    case 2
        aes.colors = [aes.blue; aes.white; aes.blue; aes.white];
     switch knob.hybrid
            case 1
                aes.label = {'Up-Hyb','Up-Int','Down-Hyb', 'Down-Int'};
            case 0
                switch knob.deutsch
                    case 0
                aes.label = {'Up-Exp','Up-Cntrl','Down-Exp', 'Down-Cntrl'};
                    case 1
                        aes.label = {'Up-Exp','Up-Kntrl','Down-Exp', 'Down-Kntrl'};
                end % knob.deutsch
     end % knob.hybrid
     data = [{[r.neu]}; {[r.ncu]}; {[r.ned]}; {[r.ncd]}]; 

end % knob.division




figure;
violin_half(data', 'xlabel', aes.label, 'facecolor', aes.colors);
boxplot(data{1}, 'Position', 1, 'Labels', 'none');
set(findobj(gca, 'type', 'line'), 'LineWidth', 1.2);

boxplot(data{2}, 'Position', 2, 'Labels', 'none');
set(findobj(gca, 'type', 'line'), 'LineWidth', 1.2);

boxplot(data{3}, 'Position', 3, 'Labels', 'none');
set(findobj(gca, 'type', 'line'), 'LineWidth', 1.2);

boxplot(data{4}, 'Position', 4, 'Labels', 'none');
set(findobj(gca, 'type', 'line'), 'LineWidth', 1.2);

hold on

%% draw brackets
switch knob.bracket
    case 1
        switch knob.division
            case 2
                jump = 0.1; 

% % bracket small hyb vs int - 1
% br.y = max(max(data{1}), max(data{2})) + jump;
% plot([1 1 2 2], [br.y br.y+0.1 br.y+0.1 br.y], 'k--', 'LineWidth', 1)
% text(1.5, br.y+0.2,  {'*'}, 'FontSize', 15, 'Interpreter', 'tex', 'HorizontalAlignment','center')
% hold on
% 
% % bracket small hyb vs int - 2
% br.y = max(max(data{3}), max(data{4})) + jump;
% plot([3 3 4 4], [br.y br.y+0.1 br.y+0.1 br.y], 'k--', 'LineWidth', 1)
% text(3.5, br.y+0.2,  {'*'}, 'FontSize', 15, 'Interpreter', 'tex', 'HorizontalAlignment','center')
% hold on

% bracket big up vs down - 2
br.y = max([max(data{1}), max(data{2}), max(data{3}), max(data{4})]) + jump*3;
plot([1.5 1.5 3.5 3.5], [br.y+0.1 br.y+0.3 br.y+0.3 br.y+0.1], 'k', 'LineWidth', 1)
text(2.5, br.y+0.4,  {'**'}, 'FontSize', 15, 'Interpreter', 'tex')



%legend_str = {'** direction effect: \it{p} < .01', '* condition effect: \it{p} = .04 ', 'interaction effect: \it{p} = n.s.'};
switch knob.deutsch
    case 0
legend_str = {'** \rm{direction:} \it{p} \rm{< .01}', ...
    '* \rm{condition:} \it{p}\rm{ = .04}', ...
    '\rm{interaction: n.s.}'};
    case 1
legend_str = {'** \rm{Richtung:} \it{p} \rm{< .01}', ...
    '* \rm{Bedingung:} \it{p}\rm{ = .04}', ...
    '\rm{Interaktion: n.s.}'};
end

xlim([0.5 4.5])              % adjust to fit your 4 violins comfortably
ylim([-1.3 1.8]) 

% e.g., place in top-left inside the plot, with a little padding
legend_x = 3.8;
legend_y = 1.6;

text(legend_x, legend_y, legend_str, ...
    'FontSize', 15, ...
    'Interpreter', 'tex')

        end
end

%% finish plot

set(gca, 'XTick', [1:length(data)], 'XTickLabel', aes.label, 'Fontsize', 16);


% choose y label
switch knob.deutsch
    case 0
ylabel('Normalized AAA (z-score)', 'Fontsize', 17)
    case 1
ylabel('Normierte AAA (z-Wert)', 'Fontsize', 17)
end

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
af.Position = [1 1 860 430]; % for the window undock size

print(gcf, [paths.derivatives, '\mt9_anova'], '-dpng', '-r300');


%% closing
cd(paths.script)
disp('done')
