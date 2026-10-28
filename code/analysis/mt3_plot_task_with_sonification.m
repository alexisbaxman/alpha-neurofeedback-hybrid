%% mt3_plot_task_with_sonification
% Requires mt1 and mt2 to be run first. It plots 1 regulation task along
% with a subplot of the sonification values. For completeness, run mt2 with
% the refractory windows enabled (`knob.refractory = 1`).
% Author: Alexis Olguin Baxman
% Date: 16.10.2026

paths.save = [paths.main, '\derivatives\mt3\', subject, '\'];
knob.deutsch = 0; % 1 deutsch, 0 english
knob.std = 1; % plot the normalization windows around the threshold
aes.gold_light = [0.9500    0.8000         0] % for normalization widnows

if exist(paths.save) == 0
    mkdir(paths.save)
end


for idx = 1:length(SONIC.time_stamps)
    [~, SONIC.idx_time_stamps(idx)] =  min(abs(AAA.time_stamps - SONIC.time_stamps(idx)));
end
SONIC.timevec = AAA.timevec(SONIC.idx_time_stamps);


%% sonification values
fragmentNFB = [];
gaps = [];
% dividing the data
gaps.NFB = find(diff(SONIC.time_stamps) > 10);
disp(gaps.NFB)

% find the starting point of every fragment of sonification in AAA
gaps.AAA = [];
for i = 1:length(gaps.NFB)
    [~, gaps.AAA(i)] =  min(abs(AAA.time_stamps - SONIC.time_stamps(gaps.NFB(i))));

end
disp(gaps.AAA)

% alpha exploration
fragmentNFB(1).time_series = SONIC.time_series(1:gaps.NFB(1));
fragmentNFB(1).time_stamps = SONIC.time_stamps(1:gaps.NFB(1));
fragmentNFB(1).timevec = SONIC.timevec(1:gaps.NFB(1));

fragmentAAA(1).time_series = AAA.time_series(1:gaps.AAA(1));
fragmentAAA(1).time_stamps = AAA.time_stamps(1:gaps.AAA(1));
fragmentAAA(1).timevec = AAA.timevec(1:gaps.AAA(1));

% training phase
fragmentNFB(2).time_series = SONIC.time_series(gaps.NFB(1)+1 : gaps.NFB(2));
fragmentNFB(2).time_stamps = SONIC.time_stamps(gaps.NFB(1)+1 : gaps.NFB(2));
fragmentNFB(2).timevec = SONIC.timevec(gaps.NFB(1)+1 : gaps.NFB(2));

fragmentAAA(2).time_series = AAA.time_series(gaps.AAA(1)+1 : gaps.AAA(2));
fragmentAAA(2).time_stamps = AAA.time_stamps(gaps.AAA(1)+1 : gaps.AAA(2));
fragmentAAA(2).timevec = AAA.timevec(gaps.AAA(1)+1 : gaps.AAA(2));


% regulation task 1
fragmentNFB(3).time_series = SONIC.time_series(gaps.NFB(2)+1 : gaps.NFB(3));
fragmentNFB(3).time_stamps = SONIC.time_stamps(gaps.NFB(2)+1 : gaps.NFB(3));
fragmentNFB(3).timevec = SONIC.timevec(gaps.NFB(2)+1 : gaps.NFB(3));

fragmentAAA(3).time_series = AAA.time_series(gaps.AAA(2)+1 : gaps.AAA(3));
fragmentAAA(3).time_stamps = AAA.time_stamps(gaps.AAA(2)+1 : gaps.AAA(3));
fragmentAAA(3).timevec = AAA.timevec(gaps.AAA(2)+1 : gaps.AAA(3));


% regulation task 2
fragmentNFB(4).time_series = SONIC.time_series(gaps.NFB(3)+1 : end);
fragmentNFB(4).time_stamps = SONIC.time_stamps(gaps.NFB(3)+1 : end);
fragmentNFB(4).timevec = SONIC.timevec(gaps.NFB(3)+1 : end);

fragmentAAA(4).time_series = AAA.time_series(gaps.AAA(3)+1 : end);
fragmentAAA(4).time_stamps = AAA.time_stamps(gaps.AAA(3)+1 : end);
fragmentAAA(4).timevec = AAA.timevec(gaps.AAA(3)+1 : end);

%% calculate sampling rate
sonic.steps = 5; % used during the experiment
SONIC.srate = [];
difference.NFB = [];
for i = 1:length(fragmentNFB)
    difference.NFB{i} = diff(fragmentNFB(i).timevec(sonic.steps:end-sonic.steps));
    SONIC.srate(i) = 1/mean(difference.NFB{i});
end
disp(['Sonic sampling rate ≈ ', num2str(SONIC.srate)])
% figure; histogram([difference.NFB{2:4}])

% same with AAA
difference.AAA = [];
for i = 1:length(fragmentAAA)
    difference.AAA{i} = diff(fragmentAAA(i).timevec(sonic.steps:end-sonic.steps));
    AAA.srate(i) = 1/mean(difference.AAA{i});
end
disp(['AAA sampling rate ≈ ', num2str(AAA.srate)])
% figure; histogram([difference.AAA{:}])



%% try to xcorr

for i = 1:length(fragmentAAA)
    fragment_interp = interp1(fragmentNFB(i).time_stamps, fragmentNFB(i).time_series, fragmentAAA(i).time_stamps, 'linear', 'extrap');
    A = fragmentAAA(i).time_series; %- mean(fragmentAAA(i).time_series);
    S = fragment_interp; % - mean(fragment_interp);

    % cross corr
    [xc, lags] = xcorr(S, A, 'coeff');
    lag_sec = lags/AAA.srate(i);

    % find the best lag
    [~, idx] = max(xc);
    best_lag = lag_sec(idx);
    best_corr = xc(idx);

    fprintf('Fragment %d: best lag = %.3f s, corr = %.3f\n', i, best_lag, best_corr);


    % convert lags into secons
end


%% plotting
disp('plotting starts')

knob.fragmentNFB = 4;

tic
fig = figure;

% subplot AAA
ax(1) = subplot(2,1,1);
MARKER.ylim = [min(AAA.time_series(start:end)), max(AAA.time_series(start:end))];

p.aaa = plot(AAA.timevec(start:end), AAA.time_series(start:end), 'Color', [0, 0, 0], 'LineWidth', aes.thickest);
hold on

% draw rectangles in steps of 2
% switch knob.rectangles
%     case 1
%         disp('plotting rectangles')
%
%         for i = 1:2:length(MARKER.rect.position)
%             p.rect{end+1} = rectangle('Position', [MARKER.rect.position(i) MARKER.ylim(1) MARKER.rect.position(i+1) - MARKER.rect.position(i) MARKER.ylim(2) + abs(MARKER.ylim(1))], 'FaceColor', aes.green, 'LineStyle', 'none',  'FaceAlpha',0.3,'EdgeColor','none');
%             hold on
%         end
% end

% draw events xline
disp('plotting xlines')

for i = 1:length(MARKER.secs)
    % without label

    p.xline{end+1} = xline(MARKER.secs(i),  MARKER.line.type{i}, ' ', 'Color', MARKER.line.color{i}, 'LabelHorizontalAlignment', MARKER.line.horizontal{i}, 'LineWidth', MARKER.line.width{i}, 'LabelVerticalAlignment', MARKER.line.vertical{i});

    % with label
    %p.xline{end+1} = xline(MARKER.secs(i),  MARKER.line.type{i}, char(MARKER.line.label{i}), 'Color', MARKER.line.color{i}, 'LabelHorizontalAlignment', MARKER.line.horizontal{i}, 'LineWidth', MARKER.line.width{i}, 'LabelVerticalAlignment', MARKER.line.vertical{i}, 'FontSize', 17);
end




% plot the tasks average
switch knob.task
    case 1
        disp('plotting task averages')
        for i = 1:length(tasks.averages)-1
            switch knob.std % std of the task average
                case 1
                    %Define x and y for the shaded area
                    % shade.x = [tasks.secs(i), tasks.secs(i+1), tasks.secs(i+1), tasks.secs(i)];
                    % shade.y = [tasks.averages(i)+tasks.stds(i), tasks.averages(i)+tasks.stds(i), tasks.averages(i)-tasks.stds(i), tasks.averages(i)-tasks.stds(i)];
                    % % Plot the shaded area
                    % fill(shade.x, shade.y, aes.green, 'FaceAlpha', 0.3, 'EdgeColor', 'none');
                    % hold on
            end
            p.task = plot([tasks.secs(i), tasks.secs(i+1)], [tasks.averages(i), tasks.averages(i)], 'Color', aes.threshold, 'LineWidth', 2);
            hold on
        end
end


% plot the thresholds
shade.x = [];
for i = 1:length(thres.new)-1
    switch knob.std
        case 1
            % Define x and y for the shaded area
            shade.x = [trial.change(i*2 - 1), trial.change(i*2), trial.change(i*2), trial.change(i*2 - 1)];
            shade.y = [thres.new(i)+thres.std(i), thres.new(i)+thres.std(i), thres.new(i)-thres.std(i), thres.new(i)-thres.std(i)];
            % Plot the shaded area
            fill(shade.x, shade.y, aes.threshold, 'FaceAlpha', 0.4, 'EdgeColor', 'none');
            hold on
    end

    p.thres = plot([trial.change(i*2 - 1), trial.change(i*2)], [thres.new(i), thres.new(i)], 'Color', aes.threshold, 'LineWidth', aes.thickest*1.5);
    hold on
    % trial index is created in every up_on, up_off,
    % down_on, down_off, timeout

end

ylabel('AAA (µV)')
%xlabel('Time (s)', 'FontSize', 13, 'FontWeight', 'bold')
ylim([MARKER.ylim(1), MARKER.ylim(2)]) % add a bit of space above to fit the manual boxes
xlim([fragmentNFB(knob.fragmentNFB).timevec(1)-1, fragmentNFB(knob.fragmentNFB).timevec(end)+1])


title(['Regulation Task (Participant ', subject(end-1:end), ')'], 'interpreter', 'none', 'FontSize', 15)


wind.start = find(strcmp([MARKER.line.name], 'regulation task'))+3;
wind.end = find(strcmp([MARKER.line.name], 'discrimination task'))-1; % the 6th discrimination task

xlim([fragmentNFB(knob.fragmentNFB).timevec(1), fragmentNFB(knob.fragmentNFB).timevec(end)])


toc
disp(' ')


%% subplot the fragmentNFBs of sonification

disp('plotting sonification values')
tic

ax(2) = subplot(2,1,2);
aes.navy = [0 0.40 0.218];
aes.dark_red = [0.6216    0.0471    0.1333];
MARKER.ylim = [-0.1, 1.1];




for  i = 1:length(fragmentNFB)
    p.sonic = stairs(fragmentNFB(i).timevec, fragmentNFB(i).time_series, '-','Color', aes.dark_red, 'LineWidth', aes.thickest);
    hold on

    y = fragmentNFB(i).timevec;
    chg = [1 find(diff(y) > 1)+1];
    fin = [find(diff(y) > 1)];
    hold on
end


ylim([-0.1 1.1])
xlim([fragmentNFB(knob.fragmentNFB).timevec(1)-1, fragmentNFB(knob.fragmentNFB).timevec(end)+1])

switch knob.deutsch
    case 0
        ylabel('Volume (%)', 'FontSize', 15)
        xlabel('Time (s)', 'FontSize', 15)
        title(['Real-Time Sonification'], 'interpreter', 'none', 'FontSize', 15)
    case 1
        ylabel('Lautstärke (%)', 'FontSize', 15)
        xlabel('Zeit (s)', 'FontSize', 15)
        title(['Echtzeit-Sonifikation'], 'interpreter', 'none', 'FontSize', 15)
end


set(ax, 'Box', 'off'); % removes the big box
set(ax, 'LineWidth', 2); % removes the big box
set(ax, 'TickDir', 'out'); % moves the ticks out
set(ax, 'TickLength', [0.02 0.02]); % makes them thicke
set(ax, 'FontSize', 13); % hopefully will improve the ticks
set(ax, 'Layer', 'top');
set(fig,'Units','inches','Position',[1 1 9 6]);  % wide aspect (adjust as you like)
%tiledlayout(fig, 2, 1, 'TileSpacing','compact','Padding','compact');

toc

%% save

paths.fig = [subject, '_reg_task_1.png'];

switch knob.save
    case 1
        disp('saving figure')
        exportgraphics(fig, [paths.save, paths.fig], 'Resolution',300);
end

%% legend

figLegend = figure;
clf;


% legend building
p.std_thres = plot(nan, nan, '-', 'Color', aes.threshold, 'LineWidth',8);
hold on
p.thres = plot(nan, nan, '-', 'Color', aes.threshold, 'LineWidth',2);
p.aaa = plot(nan, nan, '-', 'Color', [0, 0, 0], 'LineWidth',2);
hold on
p.sonic = plot(nan, nan, '-', 'Color', aes.dark_red, 'LineWidth',2);


axis off;

% legend([p.aaa, p.thres, p.upreg, p.sonic, p.std_thres,  p.downreg], ...
%     {'AAA', 'Thresholds', 'Upregulation trials', 'Sonification values', 'Dispersion scale' , 'Downregulation trials'} ...
%     , 'Orientation', 'vertical', 'FontSize', 14, 'NumColumns', 2);




switch knob.std
    case 1
        switch knob.deutsch
            case 0
                legend([p.aaa, p.thres, p.sonic, p.std_thres], ...
                    {'AAA', 'Dynamic Thresholds', 'Sonification Volume', 'Normalization Interval'} ...
                    , 'Orientation', 'vertical', 'FontSize', 17, 'NumColumns', 2);
                set(figLegend, 'Units','inches', 'Position',[1 1 15 3]);  % width x height in inches
            case 1
                legend([p.aaa, p.thres, p.sonic, p.std_thres], ...
                    {'AAA', 'Schwellenwert', 'Sonifikation Lautstärke', 'Skalierungsbereich'} ...
                    , 'Orientation', 'vertical', 'FontSize', 17, 'NumColumns', 2);
                set(figLegend, 'Units','inches', 'Position',[1 1 15 3]);  % width x height in inches

        end % knob deutsch
    case 0
        switch knob.deutsch
            case 0
                legend([p.aaa, p.thres, p.sonic], ...
                    {'AAA', 'Schwellenwert', 'Sonifikation Lautstärke'} ...
                    , 'Orientation', 'vertical', 'FontSize', 17, 'NumColumns', 1);
            case 1
                legend([p.aaa, p.thres, p.sonic], ...
                    {'AAA', 'Schwellenwert', 'Sonifikation Lautstärke'} ...
                    , 'Orientation', 'vertical', 'FontSize', 17, 'NumColumns', 3);
        end

        set(figLegend, 'Units','inches', 'Position',[1 1 12 8]);  % width x height in inches

end





% save legend figure
paths.fig = [subject, '_reg_task_legend.png'];

switch knob.save
    case 1
        disp('saving legend')
        exportgraphics(figLegend, [paths.save, paths.fig], 'Resolution',300);
end



disp('done')

