%% mt2_plot_task_events
% Requires mt1 to be run first. It goes through all Event Markers and
% identifies them, then plots the whole session (so it takes some time,
% close to a minute). You can choose whether to focus on a regulation or a
% discrimination task (`knob.window`).
% Author: Alexis Olguin Baxman
% Date: 16.10.2026

paths.save = [paths.main, '\derivatives\mt2\', subject, '\'];
paths.script = [paths.main, '\code\analysis'];

if exist(paths.save) == 0
    mkdir(paths.save)
end


knob.window = 3; % 2 regulation task; 3 discrimination task
knob.plot = 1; % runs script without plotting

knob.std = 0; % plot with standard deviations (if discrimination plot, it becomes 0)
knob.refractory = 0; % plots refractory window, it's necessary for sonification plot
knob.save = 1; % save figure
knob.rectangles = 0; % let's de activate the rectangles
knob.horizontal = 1; % to plot as well the tasks and thresholds
knob.change = 0; % show or not the grey perpendicular lines showing the change of direction, interacts with know.first
knob.deutsch = 1; % 1 deutsch, 0 english

% if you don't want to show a trigger, change the color to 'none',
% if you skip a trigger, it can't be plotted
switch knob.window
    case 2 % regulation
        knob.trial = 0; % plot trials blue lines
        knob.thres = 1; % plot thrsholds
        knob.task = 0; % plot task averages
        knob.baseline_average = 0; % plots eyes closed baseline average throught the whole session as a brown horizontal line
        knob.correct = 0; % plot vertical line with correct and uncorrect answers
        % too much, unnecessary, too many elements

    case 3 % discrimination
        knob.std = 0; % plot without standard deviations
        knob.trial = 0; % plot trials blue lines
        knob.thres = 1; % plot thrsholds
        knob.task = 0; % plot task averages
        knob.baseline_average = 0; % plots eyes closed baseline average throught the whole session as a brown horizontal line
        knob.correct = 1; % plot vertical line with correct and uncorrect answers
        % too much, unnecessary, too many elements
end


training.reg = 16; % training trials: 4 up, 4 down, 4 up, 4 down
training.disc = 5;
test.reg = 32;  % it has to be an even number for the amount of scenarios
test.disc = 20;
tasks.total = 8; % total number of tasks, not counting training

% fonts & colors
aes.thin = 0.5;
aes.thick = 1.5;
aes.thickest = 2;
aes.boost = 1.8;
aes.purple = [0.4940 0.1840 0.5560]	; % purple; upreg
aes.green = [0.4660 0.6740 0.1880]; % green, doreg
aes.black = [0 0 0]; % black
aes.blue = [0.1843    0.7451    0.9373]; % light blue
aes.violet = [0.4940 0.1840 0.5560]; % soft violet
aes.gold = [0.75 0.6 0]; % dark yellow for baseline clsoe
aes.grey = [0.5 0.5 0.5]; % light grey, end of baseline
aes.pink = [1 0.8 0.85]; % pale pink
aes.brown = [0.42, 0.38, 0.22]; % brown with a slight greenish hue
aes.red = [0.8392    0.0078    0.0078];
aes.orange = [1.0000    0.4118    0.1608];

%% let's realocate
MARKER.idx = []; % index in the APS
MARKER.line.label = [];
MARKER.line = [];
MARKER.line.color = [];
MARKER.rect.position = [];
MARKER.rect.color = [];
MARKER.rect.counter = 1; % counter for rectangle
MARKER.trial.counter = 1; % counter for trials

MARKER.first = 0; % to mark first up and downregulation
knob.first = 0; % it is the change of

MARKER.line.vertical = [];
trial.change = []; % save
trial.index = [];



% timevec calculation
AAA.timevec = AAA.time_stamps-AAA.time_stamps(1);

for i = 1:length(EM.time_stamps)
    [~, MARKER.idx(i)] = min(abs(AAA.time_stamps - EM.time_stamps(i)));
    % it searches for the idx to compare with the EEG data

    if EM.time_series(i) == trigger.issues % connection issues, 9
        MARKER.line.type{i} = '--';
        MARKER.line.color{i} = 'none';
        MARKER.line.label{i} = ' ';
        MARKER.line.horizontal{i} = 'Left';
        MARKER.line.width{i} = aes.thin;
        MARKER.line.vertical{i} = 'bottom';
        MARKER.line.trigger{i} = EM.time_series(i);
        MARKER.line.name{i} = 'connection issues';

    elseif EM.time_series(i) == trigger.screen % screen with instructions, 11
        MARKER.line.type{i} = '--';
        MARKER.line.color{i} = 'none'; % black
        MARKER.line.label{i} = ' ';
        MARKER.line.horizontal{i} = 'Left';
        MARKER.line.width{i} = aes.thin;
        MARKER.line.vertical{i} = 'middle';
        MARKER.line.trigger{i} = EM.time_series(i);
        MARKER.line.name{i} = 'screen';


    elseif EM.time_series(i) == trigger.next % space press, 12
        MARKER.line.type{i} = ':';
        MARKER.line.color{i} = 'none'; % black
        MARKER.line.label{i} = ' ';
        MARKER.line.horizontal{i} = 'Left';
        MARKER.line.width{i} = aes.thick;
        MARKER.line.vertical{i} = 'bottom';
        MARKER.line.trigger{i} = EM.time_series(i);
        MARKER.line.name{i} = 'next';

    elseif EM.time_series(i) == trigger.blon % baseline start, 14
        MARKER.line.type{i} = '-';
        MARKER.line.color{i} = aes.grey; % light grey, end of baseline
        MARKER.line.label{i} =  'start of the baseline';
        MARKER.line.horizontal{i} = 'Right';
        MARKER.line.width{i} = aes.thin;
        MARKER.line.vertical{i} = 'top';
        MARKER.line.trigger{i} = EM.time_series(i);
        MARKER.line.name{i} = 'baseline on';


    elseif EM.time_series(i) == trigger.open % open eyes baseline, 15
        MARKER.line.type{i} = '-';
        MARKER.line.color{i} = aes.violet;
        MARKER.line.label{i} = 'open eyes baseline';
        MARKER.line.horizontal{i} = 'Right';
        MARKER.line.width{i} = aes.thin;
        MARKER.line.vertical{i} = 'bottom';
        MARKER.line.trigger{i} = EM.time_series(i);
        MARKER.line.name{i} = 'open';


    elseif EM.time_series(i) == trigger.close % clsoe eyes baseline, 16
        MARKER.line.type{i} = '-';
        MARKER.line.color{i} = aes.gold; % dark yellow for baseline clsoe
        MARKER.line.label{i} = 'close eyes baseline';
        MARKER.line.horizontal{i} = 'Right';
        MARKER.line.width{i} = aes.thin;
        MARKER.line.vertical{i} = 'bottom';
        MARKER.line.trigger{i} = EM.time_series(i);
        MARKER.line.name{i} = 'close';


    elseif EM.time_series(i) == trigger.bloff % end of the baseline, 17
        MARKER.line.type{i} = '-';
        MARKER.line.color{i} = aes.grey; % light grey, end of baseline
        MARKER.line.label{i} =  'end of the baseline';
        MARKER.line.horizontal{i} = 'Left';
        MARKER.line.width{i} = aes.thin;
        MARKER.line.vertical{i} = 'top';
        MARKER.line.trigger{i} = EM.time_series(i);
        MARKER.line.name{i} = 'baseline off';


    elseif EM.time_series(i) == trigger.exploration % stat alpha waves exploration 18
        MARKER.line.type{i} = '-';
        MARKER.line.color{i} = aes.pink;
        MARKER.line.label{i} =  'alpha wave exploration starts';
        MARKER.line.horizontal{i} = 'Right';
        MARKER.line.width{i} = aes.thin;
        MARKER.line.vertical{i} = 'top';
        MARKER.line.trigger{i} = EM.time_series(i);
        MARKER.line.name{i} = 'exploration on';

    elseif EM.time_series(i) == trigger.exploratioff % end alpha waves exploration 19
        MARKER.line.type{i} = '-';
        MARKER.line.color{i} = aes.pink;
        MARKER.line.label{i} =  'alpha wave exploration end';
        MARKER.line.horizontal{i} = 'Left';
        MARKER.line.width{i} = aes.thin;
        MARKER.line.vertical{i} = 'top';
        MARKER.line.trigger{i} = EM.time_series(i);
        MARKER.line.name{i} = 'exploration off';


    elseif EM.time_series(i) == trigger.trial % new trial, 20
        trial.index(end+1) = AAA.timevec(MARKER.idx(i));

        MARKER.line.type{i} = '-';
        MARKER.line.color{i} = 'none'; % black

        if MARKER.trial.counter <= training.reg + training.disc
            MARKER.line.label{i} = ['Training trial: ', num2str(MARKER.trial.counter)];
            MARKER.trial.counter = MARKER.trial.counter + 1;
            MARKER.line.name{i} = 'new trial'; % MARKER.line.label{i};
            % the first test trial will seem to be on top of the training. Is normal,
            % makes sense
        elseif MARKER.trial.counter > training.reg + training.disc
            if MARKER.trial.counter == training.reg + training.disc+1
                MARKER.trial.first_test = i;
            end

            MARKER.line.label{i} = ['Test trial: ', num2str(MARKER.trial.counter)];
            MARKER.trial.counter = MARKER.trial.counter + 1;
            MARKER.line.name{i} = 'new trial'; %MARKER.line.label{i};
        end
        MARKER.line.horizontal{i} = 'right';
        MARKER.line.width{i} = aes.thick;
        MARKER.line.vertical{i} = 'middle';
        MARKER.line.trigger{i} = EM.time_series(i);

    elseif EM.time_series(i) == trigger.experimental % experimental condition, 21
        MARKER.line.type{i} = '--';
        MARKER.line.color{i} = 'none';
        MARKER.line.label{i} = ' ';
        MARKER.line.horizontal{i} = 'Right';
        MARKER.line.width{i} = aes.thickest;
        MARKER.line.vertical{i} = 'middle';
        MARKER.line.trigger{i} = EM.time_series(i);
        MARKER.line.name{i} = 'experimental condition';

    elseif EM.time_series(i) == trigger.control % control condition, 22
        MARKER.line.type{i} = '--';
        MARKER.line.color{i} = aes.grey;
        MARKER.line.label{i} = 'control condition';
        MARKER.line.horizontal{i} = 'Right';
        MARKER.line.width{i} = aes.thickest;
        MARKER.line.vertical{i} = 'middle';
        MARKER.line.trigger{i} = EM.time_series(i);
        MARKER.line.name{i} = 'control condition';

    elseif EM.time_series(i) == trigger.break % signals the break; 23
        MARKER.line.type{i} = '--';
        MARKER.line.color{i} = aes.pink;
        MARKER.line.label{i} = 'The Break';
        MARKER.line.horizontal{i} = 'Left';
        MARKER.line.width{i} = aes.thickest;
        MARKER.line.vertical{i} = 'top';
        MARKER.line.trigger{i} = EM.time_series(i);
        MARKER.line.name{i} = 'the break';

    elseif EM.time_series(i) == trigger.son_on % sonification starts, 30
        MARKER.line.type{i} = '--';
        MARKER.line.color{i} = 'none'; % grey
        MARKER.line.label{i} = 'trial on';
        MARKER.line.horizontal{i} = 'Right';
        MARKER.line.width{i} = aes.thickest;
        MARKER.line.vertical{i} = 'top'; % not visible
        MARKER.line.trigger{i} = EM.time_series(i);
        MARKER.line.name{i} = 'sonification on';

    elseif EM.time_series(i) == trigger.son_off % sonification ends, 31
        MARKER.line.type{i} = '--';
        MARKER.line.color{i} = 'none'; % grey
        MARKER.line.label{i} = 'trial'; % sonification off
        MARKER.line.horizontal{i} = 'Right'; % not visible
        MARKER.line.width{i} = aes.thickest;
        MARKER.line.vertical{i} = 'top'; % not visible
        MARKER.line.trigger{i} = EM.time_series(i);
        MARKER.line.name{i} = 'sonification off';

        % REGULATION TASK
    elseif EM.time_series(i) == trigger.reg % regulation task, 40
        if MARKER.trial.counter > training.reg + training.disc
            knob.first = 1;
        end

        MARKER.line.type{i} = '-';
        MARKER.line.color{i} = 'none'; % invisible
        MARKER.line.label{i} = 'regulation task';
        MARKER.line.horizontal{i} = 'Right';
        MARKER.line.width{i} = aes.thickest;
        MARKER.line.vertical{i} = 'top';
        MARKER.line.trigger{i} = EM.time_series(i);
        MARKER.line.name{i} = 'regulation task';

    elseif EM.time_series(i) == trigger.upreg_on % evaluation phase: upregulation, 41
        trial.change(end+1) = AAA.timevec(MARKER.idx(i));

        switch knob.change
            case 1
                if knob.first == 1 || knob.first == 9

                    MARKER.line.type{i} = '--';
                    MARKER.line.color{i}  = aes.grey;
                    MARKER.line.label{i} = 'Upregulation trials'; % threshold calculation starts
                    MARKER.line.horizontal{i} = 'Right'; % default; not visible
                    MARKER.line.width{i} = aes.thickest*1.5;
                    MARKER.line.vertical{i} = 'top';
                    MARKER.line.trigger{i} = EM.time_series(i);
                    MARKER.line.name{i} = 'upregulation on';

                    MARKER.rect.position(end+1) = AAA.timevec(MARKER.idx(i));
                    MARKER.rect.color{end+1} = aes.purple;

                else
                    MARKER.line.type{i} = '-';
                    MARKER.line.color{i}  = 'none';
                    MARKER.line.label{i} = ' '; % threshold calculation starts
                    MARKER.line.horizontal{i} = 'Right'; % default; not visible
                    MARKER.line.width{i} = aes.thick;
                    MARKER.line.vertical{i} = 'top';
                    MARKER.line.trigger{i} = EM.time_series(i);
                    MARKER.line.name{i} = 'upregulation on';

                    MARKER.rect.position(end+1) = AAA.timevec(MARKER.idx(i));
                    MARKER.rect.color{end+1} = aes.purple;
                end

                % marker first changes after evaluation
                if knob.first ~= 0
                    knob.first = knob.first + 1;
                end
            case 0 % knob.change
                MARKER.line.type{i} = '-';
                    MARKER.line.color{i}  = 'none';
                    MARKER.line.label{i} = ' '; % threshold calculation starts
                    MARKER.line.horizontal{i} = 'Right'; % default; not visible
                    MARKER.line.width{i} = aes.thick;
                    MARKER.line.vertical{i} = 'top';
                    MARKER.line.trigger{i} = EM.time_series(i);
                    MARKER.line.name{i} = 'upregulation on';

                    MARKER.rect.position(end+1) = AAA.timevec(MARKER.idx(i));
                    MARKER.rect.color{end+1} = aes.purple;
        end % knob.change

    elseif EM.time_series(i) == trigger.upreg_off % evaluation phase end: upeg reached, 43
        trial.change(end+1) = AAA.timevec(MARKER.idx(i));

        switch knob.change
            case 1
                if knob.first == 9 || knob.first == 17

                    MARKER.line.type{i} = '--';
                    MARKER.line.color{i}  = aes.grey;
                    MARKER.line.label{i} = 'Upregulation trials'; % threshold calculation starts
                    MARKER.line.horizontal{i} = 'Right'; % default; not visible
                    MARKER.line.width{i} = aes.thickest*1.5;
                    MARKER.line.vertical{i} = 'top';
                    MARKER.line.trigger{i} = EM.time_series(i);
                    MARKER.line.name{i} = 'upregulation off';

                    MARKER.rect.position(end+1) = AAA.timevec(MARKER.idx(i));
                    MARKER.rect.color{end+1} = aes.purple;

                else
                    MARKER.line.type{i} = '-';
                    MARKER.line.color{i}  = 'none';
                    MARKER.line.label{i} = ' '; % threshold calculation starts
                    MARKER.line.horizontal{i} = 'Right'; % default; not visible
                    MARKER.line.width{i} = aes.thick;
                    MARKER.line.vertical{i} = 'top';
                    MARKER.line.trigger{i} = EM.time_series(i);
                    MARKER.line.name{i} = 'upregulation off';

                    MARKER.rect.position(end+1) = AAA.timevec(MARKER.idx(i));
                    MARKER.rect.color{end+1} = aes.purple;
                end
                            case 0 % knob.change
MARKER.line.type{i} = '-';
                    MARKER.line.color{i}  = 'none';
                    MARKER.line.label{i} = ' '; % threshold calculation starts
                    MARKER.line.horizontal{i} = 'Right'; % default; not visible
                    MARKER.line.width{i} = aes.thick;
                    MARKER.line.vertical{i} = 'top';
                    MARKER.line.trigger{i} = EM.time_series(i);
                    MARKER.line.name{i} = 'upregulation off';

                    MARKER.rect.position(end+1) = AAA.timevec(MARKER.idx(i));
                    MARKER.rect.color{end+1} = aes.purple;

        end % knob.change



        %         MARKER.line.color{i} = 'none';
        %         MARKER.line.type{i} = '--';
        %         MARKER.line.label{i} = ' ';
        %         MARKER.line.horizontal{i} = 'left'; % does not mater
        %         MARKER.line.width{i} = aes.thick;
        %         MARKER.line.vertical{i} = 'top';
        %         MARKER.line.trigger{i} = EM.time_series(i);
        %         MARKER.line.name{i} = 'upregulation off';
        %
        %         MARKER.rect.position(end+1) = AAA.timevec(MARKER.idx(i));
        %         MARKER.rect.color{end+1}  = aes.purple;

    elseif EM.time_series(i) == trigger.doreg_on % evaluation phase: downregulation, 42
        trial.change(end+1) = AAA.timevec(MARKER.idx(i));

        switch knob.change
            case 1
                if knob.first == 1 || knob.first == 9
                    MARKER.line.type{i} = '--';
                    MARKER.line.color{i}  = aes.grey;
                    MARKER.line.label{i} = 'Downregulation trials'; % threshold calculation starts
                    MARKER.line.horizontal{i} = 'Right'; % default; not visible
                    MARKER.line.width{i} = aes.thickest*1.5;
                    MARKER.line.vertical{i} = 'top';
                    MARKER.line.trigger{i} = EM.time_series(i);
                    MARKER.line.name{i} = 'downregulation on';

                    MARKER.rect.position(end+1) = AAA.timevec(MARKER.idx(i));
                    MARKER.rect.color{end+1}  = aes.grey;

                else
                    MARKER.line.type{i} = '-';
                    MARKER.line.color{i}  = 'none';
                    MARKER.line.label{i} = ' ';
                    MARKER.line.horizontal{i} = 'Right'; % default; not visible
                    MARKER.line.width{i} = aes.thick;
                    MARKER.line.vertical{i} = 'top';
                    MARKER.line.trigger{i} = EM.time_series(i);
                    MARKER.line.name{i} = 'downregulation on';

                    MARKER.rect.position(end+1) = AAA.timevec(MARKER.idx(i));
                    MARKER.rect.color{end+1}  = aes.grey;
                end

                % marker first changes after evaluation
                if knob.first ~= 0
                    knob.first = knob.first + 1;
                end
            case 0 % knob.change
                                    MARKER.line.type{i} = '-';
                    MARKER.line.color{i}  = 'none';
                    MARKER.line.label{i} = ' ';
                    MARKER.line.horizontal{i} = 'Right'; % default; not visible
                    MARKER.line.width{i} = aes.thick;
                    MARKER.line.vertical{i} = 'top';
                    MARKER.line.trigger{i} = EM.time_series(i);
                    MARKER.line.name{i} = 'downregulation on';

                    MARKER.rect.position(end+1) = AAA.timevec(MARKER.idx(i));
                    MARKER.rect.color{end+1}  = aes.grey;
        end % knob.change

    elseif EM.time_series(i) == trigger.doreg_off % evaluation phase end: downreg reached, 44
        trial.change(end+1) = AAA.timevec(MARKER.idx(i));

        switch knob.change
            case 1
                if knob.first == 9 || knob.first == 17

                    MARKER.line.type{i} = '--';
                    MARKER.line.color{i}  = aes.grey;
                    MARKER.line.label{i} = 'Downregulation trials off'; % threshold calculation starts
                    MARKER.line.horizontal{i} = 'Right'; % default; not visible
                    MARKER.line.width{i} = aes.thickest*1.5;
                    MARKER.line.vertical{i} = 'top';
                    MARKER.line.trigger{i} = EM.time_series(i);
                    MARKER.line.name{i} = 'downregulation off';

                else
                    MARKER.line.type{i} = '-';
                    MARKER.line.color{i}  = 'none';
                    MARKER.line.label{i} = ' '; % threshold calculation starts
                    MARKER.line.horizontal{i} = 'Right'; % default; not visible
                    MARKER.line.width{i} = aes.thick;
                    MARKER.line.vertical{i} = 'top';
                    MARKER.line.trigger{i} = EM.time_series(i);
                    MARKER.line.name{i} = 'downregulation off';

                end
            case 0 % knob.change
 MARKER.line.type{i} = '-';
                    MARKER.line.color{i}  = 'none';
                    MARKER.line.label{i} = ' '; % threshold calculation starts
                    MARKER.line.horizontal{i} = 'Right'; % default; not visible
                    MARKER.line.width{i} = aes.thick;
                    MARKER.line.vertical{i} = 'top';
                    MARKER.line.trigger{i} = EM.time_series(i);
                    MARKER.line.name{i} = 'downregulation off';

        end % knob.change

                MARKER.rect.position(end+1) = AAA.timevec(MARKER.idx(i));
                MARKER.rect.color{end+1}  = aes.grey;

    elseif EM.time_series(i) == trigger.reg_timeout % time out: regulation task, 45
        trial.change(end+1) = AAA.timevec(MARKER.idx(i));

        switch knob.correct
            case 1
                MARKER.line.color{i} = 'none'		;
            case 0
                MARKER.line.color{i} = 'none'; % [0 0 0]; % black lines
        end


        switch knob.change
            case 1

                if knob.first == 9 || knob.first == 17

                    MARKER.line.type{i} = '--';
                    MARKER.line.color{i}  = aes.grey;
                    MARKER.line.label{i} = 'Upregulation trials'; % threshold calculation starts
                    MARKER.line.horizontal{i} = 'Right'; % default; not visible
                    MARKER.line.width{i} = aes.thickest*1.5;
                    MARKER.line.vertical{i} = 'top';
                    MARKER.line.trigger{i} = EM.time_series(i);
                    MARKER.line.name{i} = 'reg timeout';

                    MARKER.rect.position(end+1) = AAA.timevec(MARKER.idx(i));
                    MARKER.rect.color{end+1} = aes.purple;

                else
                    MARKER.line.type{i} = '-';
                    MARKER.line.color{i}  = 'none';
                    MARKER.line.label{i} = ' '; % threshold calculation starts
                    MARKER.line.horizontal{i} = 'Right'; % default; not visible
                    MARKER.line.width{i} = aes.thick;
                    MARKER.line.vertical{i} = 'top';
                    MARKER.line.trigger{i} = EM.time_series(i);
                    MARKER.line.name{i} = 'reg timeout';
                end

            case 0 % knob.change
                       MARKER.line.type{i} = '-';
                    MARKER.line.color{i}  = 'none';
                    MARKER.line.label{i} = ' '; % threshold calculation starts
                    MARKER.line.horizontal{i} = 'Right'; % default; not visible
                    MARKER.line.width{i} = aes.thick;
                    MARKER.line.vertical{i} = 'top';
                    MARKER.line.trigger{i} = EM.time_series(i);
                    MARKER.line.name{i} = 'reg timeout';

        end % knob.change

        %
        %         MARKER.line.type{i} = '--';
        %         MARKER.line.label{i} = ' ';
        %         MARKER.line.horizontal{i} = 'Left'; % LabelHorizontalAlignment, inside evaluation rectangle
        %         MARKER.line.width{i} = aes.thickest;
        %         MARKER.line.vertical{i} = 'top';
        %         MARKER.line.trigger{i} = EM.time_series(i);
        %         MARKER.line.name{i} = 'regulation timeout';

        MARKER.rect.position(end+1) = AAA.timevec(MARKER.idx(i));
        MARKER.rect.color{end+1} = aes.black; % it's supposed to be invisible

    elseif EM.time_series(i) == trigger.reg_off % regulation ends, 46
        %trial.change(end+1) = AAA.timevec(MARKER.idx(i));
        MARKER.line.color{i} = 'none';
        MARKER.line.type{i} = '-';
        MARKER.line.label{i} = ' '; % meets condition = prompt
        MARKER.line.horizontal{i} = 'left'; % not visible
        MARKER.line.width{i} = aes.thick;
        MARKER.line.vertical{i} = 'top';
        MARKER.line.trigger{i} = EM.time_series(i);
        MARKER.line.name{i} = 'regulation ends';

    elseif  EM.time_series(i) == trigger.trainingon % 24 starts the training
        MARKER.line.color{i} = 'none'	;
        MARKER.line.type{i} = '--';
        MARKER.line.label{i} = 'training starts';
        MARKER.line.horizontal{i} = 'Left';
        MARKER.line.width{i} = 1.5;
        MARKER.line.vertical{i} = 'bottom';
        MARKER.line.trigger{i} = EM.time_series(i);
        MARKER.line.name{i} = 'training starts';

    elseif  EM.time_series(i) == trigger.trainingoff % 25 end of the training
        MARKER.line.color{i} = aes.gold	;
        MARKER.line.type{i} = '--';
        MARKER.line.label{i} = 'training ends; experiment instructions';
        MARKER.line.horizontal{i} = 'Right';
        MARKER.line.width{i} = 1.5;
        MARKER.line.vertical{i} = 'middle';
        MARKER.line.trigger{i} = EM.time_series(i);
        MARKER.line.name{i} = 'training ends';

    elseif  EM.time_series(i) == trigger.refractoff % refractory time
        switch knob.refractory
            case 1
                MARKER.line.color{i} = aes.blue;
            case 0
                MARKER.line.color{i} = 'none';
        end

        MARKER.line.type{i} = ':';
        MARKER.line.label{i} = ' ';
        MARKER.line.horizontal{i} = 'Right';
        MARKER.line.width{i} = aes.thick;
        MARKER.line.vertical{i} = 'middle';
        MARKER.line.trigger{i} = EM.time_series(i);
        MARKER.line.name{i} = 'refractory time ends';

        % manual modification?
        MARKER.idx(i) = MARKER.idx(i)-round(5*AAA.info.effective_srate);

    elseif  EM.time_series(i) == trigger.end % 13
        MARKER.line.color{i} = aes.gold	;
        MARKER.line.type{i} = '-';
        MARKER.line.label{i} = 'end';
        MARKER.line.horizontal{i} = 'Right';
        MARKER.line.width{i} = 1.5;
        MARKER.line.vertical{i} = 'middle';
        MARKER.line.trigger{i} = EM.time_series(i);
        MARKER.line.name{i} = 'end';

    elseif EM.time_series(i) == trigger.disc
        MARKER.line.type{i} = '-';
        MARKER.line.color{i} = 'none';
        MARKER.line.label{i} = ' ';
        MARKER.line.horizontal{i} = 'Right';
        MARKER.line.width{i} = aes.thick;
        MARKER.line.vertical{i} = 'top';
        MARKER.line.trigger{i} = EM.time_series(i);
        MARKER.line.name{i} = 'discrimination task';

    elseif EM.time_series(i) == trigger.disc_on
        trial.change(end+1) = AAA.timevec(MARKER.idx(i));


        MARKER.line.type{i} = '-';
        MARKER.line.color{i} = 'none';
        MARKER.line.label{i} = 'discrimination on';
        MARKER.line.horizontal{i} = 'Right';
        MARKER.line.width{i} = aes.thick;
        MARKER.line.vertical{i} = 'top';
        MARKER.line.trigger{i} = EM.time_series(i);
        MARKER.line.name{i} = 'discrimination on';


        MARKER.rect.position(end+1) = AAA.timevec(MARKER.idx(i));
        MARKER.rect.color{end+1}  = aes.green;


    elseif EM.time_series(i) == trigger.prompt
        trial.change(end+1) = AAA.timevec(MARKER.idx(i));


        MARKER.line.type{i} = '--';
        MARKER.line.color{i} = 'none';
        MARKER.line.label{i} = ' ';
        MARKER.line.horizontal{i} = 'Right';
        MARKER.line.width{i} = aes.thick;
        MARKER.line.vertical{i} = 'top';
        MARKER.line.trigger{i} = EM.time_series(i);

        MARKER.rect.position(end+1) = AAA.timevec(MARKER.idx(i));
        MARKER.rect.color{end+1}  = aes.green;

    elseif EM.time_series(i) == trigger.disc_timeout
        %trial.change(end+1) = AAA.timevec(MARKER.idx(i));

        MARKER.line.type{i} = '--';
        MARKER.line.color{i} = 'none'		; % not existant even
        MARKER.line.label{i} = 'timeout';
        MARKER.line.horizontal{i} = 'Right';
        MARKER.line.width{i} = aes.thickest;
        MARKER.line.vertical{i} = 'top';
        MARKER.line.trigger{i} = EM.time_series(i);

        % not gonna happen
        MARKER.rect.position(end+1) = AAA.timevec(MARKER.idx(i));
        MARKER.rect.color{end+1}  = aes.green;

    elseif EM.time_series(i) == trigger.th


        MARKER.line.type{i} = ':';
        switch knob.correct
            case 1
                MARKER.line.color{i} = aes.blue;
            case 0
                MARKER.line.color{i} = 'none'; % invisible

        end
        MARKER.line.label{i} = ' '; % corect answer
        MARKER.line.horizontal{i} = 'Right';
        MARKER.line.width{i} = aes.thickest*aes.boost;
        MARKER.line.vertical{i} = 'top';
        MARKER.line.trigger{i} = EM.time_series(i);

    elseif EM.time_series(i) == trigger.tl
        MARKER.line.type{i} = ':';
        switch knob.correct
            case 1
                MARKER.line.color{i} = aes.blue;
            case 0
                MARKER.line.color{i} = 'none'; % invisible
        end

        MARKER.line.label{i} = ' '; % corect answer
        MARKER.line.horizontal{i} = 'Right';
        MARKER.line.width{i} = aes.thickest*aes.boost;
        MARKER.line.vertical{i} = 'top';
        MARKER.line.trigger{i} = EM.time_series(i);

    elseif EM.time_series(i) == trigger.fh
        MARKER.line.type{i} = ':';

        switch knob.correct
            case 1
                MARKER.line.color{i} = aes.orange;
            case 0
                MARKER.line.color{i} = 'none';
        end

        MARKER.line.label{i} = ' '; % incorect answer
        MARKER.line.horizontal{i} = 'Right';
        MARKER.line.width{i} = aes.thickest*aes.boost;
        MARKER.line.vertical{i} = 'top';
        MARKER.line.trigger{i} = EM.time_series(i);

    elseif EM.time_series(i) == trigger.fl
        MARKER.line.type{i} = ':';
        switch knob.correct
            case 1
                MARKER.line.color{i} = aes.orange;
            case 0
                MARKER.line.color{i} = 'none';
        end
        MARKER.line.label{i} = ' '; % incorect answer
        MARKER.line.horizontal{i} = 'Right';
        MARKER.line.width{i} = aes.thickest*aes.boost;
        MARKER.line.vertical{i} = 'top';
        MARKER.line.trigger{i} = EM.time_series(i);

    else % ensure new markers don't breka the code
        MARKER.line.color{i} = 'none'	;
        MARKER.line.type{i} = '--';
        MARKER.line.label{i} = 'Unknown';
        MARKER.line.horizontal{i} = 'Left';
        MARKER.line.width{i} = 1.5;
        MARKER.line.vertical{i} = 'bottom';
        MARKER.line.trigger{i} = EM.time_series(i);

    end
end

MARKER.secs = AAA.timevec(MARKER.idx); % we apply the indices of the event triggers to place them over the EEG data

%% unknown triggers
unknowns.triggers = [MARKER.line.trigger{(find(strcmp([MARKER.line.label], 'Unknown')))}];
unknowns.unique = unique(unknowns.triggers);
disp(['unknown triggers: ', num2str(unique(unknowns.unique))])


%% add horizontal lines
disp('calculator')
switch knob.horizontal
    case 1

        % TASKS INDEX CALCULATOR

        tasks.trials.value = [test.reg/2 test.disc/2];
        tasks.index = zeros(1, tasks.total-1); % it creates te empty array for pre-location
        tasks.index(1) = training.reg+training.disc;
        tasks.toggle = 1;
        for i = 1:tasks.total-1
            tasks.toggle = 1-tasks.toggle;
            tasks.index(i+1) = tasks.index(i) + tasks.trials.value(tasks.toggle+1); % +2 of the training
        end
        disp('tasks index calculator')

        %% fix trial change
        x = trial.change;
        dupPos = find(diff(x)==0);
        badOrder = find(diff(x)<0);

        if ~isempty(dupPos)
            warning('Duplicate indices at positions: %s', mat2str(dupPos));
        end
        if ~isempty(badOrder)
            warning('Non-monotonic indices at positions: %s', mat2str(badOrder));
        end

        trial.change(dupPos) = [];

        %% fix rectangle
        x = MARKER.rect.position;
        dupPos = find(diff(x)==0);
        badOrder = find(diff(x)<0);

        if ~isempty(dupPos)
            warning('Duplicate indices at positions: %s', mat2str(dupPos));
        end
        if ~isempty(badOrder)
            warning('Non-monotonic indices at positions: %s', mat2str(badOrder));
        end

        MARKER.rect.position(dupPos) = [];
        MARKER.rect.color(dupPos) = [];


        %% adapting tasks averages
        %tasks.index = tasks.index+1; % to avoid a mismatch
        %trial.change = AAA.timevec(MARKER.idx(find(strcmp(MARKER.line.name, 'new trial'))));

        % somekind of timevector for the tasks

        tasks.secs = [AAA.timevec(2), MARKER.secs(find(strcmp(MARKER.line.name, 'baseline off'))), (trial.index(tasks.index(1:end)+1)),  MARKER.secs(find(strcmp(MARKER.line.name, 'end')))]; %, MARKER.secs(find(strcmp(MARKER.line.name, 'end')))];
        % AAA.timevec(2): the start of the baseline
        % event.idx(1) = bloff

        if size(task.average, 2) < 6 % hardcoded
            task.average(end+1) = mean(task.aaa);
            task.std(end+1) = std(task.aaa);
        end

        keep = true(1, length(task.average));

        % rename so it can be re-run
        tasks.averages = task.average(keep);
        tasks.stds = task.std(keep);


        %% adapthing thresholds

        % it happened bc the thresholds is rewritten several extra times:
        % at the end of every task
        % after a mini baseline

        keep = true(1, length(thres.trial)); % thanks chatgpt

        % Loop through all elements except the last one
        for i = 1:length(thres.trial)-1
            % If current trial is the same as the next, mark current as false
            if thres.trial(i) == thres.trial(i+1)
                keep(i) = false;
            end
        end

        % Now apply the mask to keep only last occurrences
        thres.trial = thres.trial(keep);
        thres.new   = thres.new(keep);
        thres.std   = thres.std(keep);









end


%% plotting it all

tic
start = 1; %find(AAA.timevec >= 60, 1, 'first'); % first minute is out?
p.xline = {}; % to allocate all the plot elements for legends
p.rect = {};

switch knob.plot
    case 1
        disp('plotting AAA!')
        %close all
        % let's ignore the first minute because it's corrupted

        MARKER.ylim = [min(AAA.time_series(start:end)), max(AAA.time_series(start:end))];

        fig = figure;
        p.aaa = plot(AAA.timevec(start:end), AAA.time_series(start:end), 'Color', [0, 0, 0], 'LineWidth', aes.thickest);
        hold on
        % draw all vertical lines

        switch knob.rectangles
            case 1
                disp('plotting rectangles')

                % draw rectangles in steps of 2
                for i = 1:2:length(MARKER.rect.position)
                    p.rect{end+1} = rectangle('Position', [MARKER.rect.position(i) MARKER.ylim(1) MARKER.rect.position(i+1) - MARKER.rect.position(i) MARKER.ylim(2) + abs(MARKER.ylim(1))], 'FaceColor', [MARKER.rect.color{i}], 'LineStyle', 'none',  'FaceAlpha',0.3,'EdgeColor','none');
                    hold on
                end
        end


        disp('plotting xlines')
        for i = 1:length(MARKER.secs)
            % without labels
            %p.xline{end+1} = xline(MARKER.secs(i),  MARKER.line.type{i}, '', 'Color', MARKER.line.color{i}, 'LabelHorizontalAlignment', MARKER.line.horizontal{i}, 'LineWidth', MARKER.line.width{i}, 'LabelVerticalAlignment', MARKER.line.vertical{i});
            % with labels:
            p.xline{end+1} = xline(MARKER.secs(i),  MARKER.line.type{i}, char(MARKER.line.label{i}), 'Color', MARKER.line.color{i}, 'LabelHorizontalAlignment', MARKER.line.horizontal{i}, 'LineWidth', MARKER.line.width{i}, 'LabelVerticalAlignment', MARKER.line.vertical{i});

        end

        ylabel('Amplitude (µV)', 'FontSize', 20)
        switch knob.deutsch
            case 0
        xlabel('Time (s)', 'FontSize', 16)
            case 1
                        xlabel('Zeit (s)', 'FontSize', 20)
        end

        ylim([MARKER.ylim(1), MARKER.ylim(2)])
        xlim([AAA.timevec(start) AAA.timevec(end)]) % not actually used
        %title(['recorded Alpha Amplitude Stream and all ', num2str(MARKER.trial.counter), ' trials'])

        switch knob.horizontal
            case 1
                switch knob.task
                    case 1
                        % plot the tasks average
                        disp('plotting tasks averages')
                        for i = 1:length(tasks.averages)-1
                            %                             switch


                            %                                 case 1
                            %                                     %Define x and y for the shaded area
                            %                                     shade.x = [tasks.secs(i), tasks.secs(i+1), tasks.secs(i+1), tasks.secs(i)];
                            %                                     shade.y = [tasks.averages(i)+tasks.stds(i), tasks.averages(i)+tasks.stds(i), tasks.averages(i)-tasks.stds(i), tasks.averages(i)-tasks.stds(i)];
                            %                                     % Plot the shaded area
                            %                                     fill(shade.x, shade.y, aes.green, 'FaceAlpha', 0.3, 'EdgeColor', 'none');
                            %                                     hold on
                            %                             end

                            p.task = plot([tasks.secs(i), tasks.secs(i+1)], [tasks.averages(i), tasks.averages(i)], '--','Color', aes.grey, 'LineWidth', 2);
                            hold on
                        end
                end % knob.task

                switch knob.baseline_average
                    case 1
                        disp('plotting baseline average')
                        p.baseline = yline(task.average(1), ':', 'Baseline EC', 'Color', aes.brown, 'LineWidth', aes.thickest, 'LabelHorizontalAlignment','left');

                end

                switch knob.trial
                    case 1
                        % plot the trial averages
                        disp('plotting trial averages')
                        for i = 1:length(trial.average)-1
                            % switch knob.std
                            %     case 1
                            %         % Define x and y for the shaded area
                            %         shade.x = [trial.change(i), trial.change(i+1), trial.change(i+1), trial.change(i)];
                            %         shade.y = [trial.average(i)+trial.std(i), trial.average(i)+trial.std(i), trial.average(i)-trial.std(i), trial.average(i)-trial.std(i)];
                            %         % Plot the shaded area
                            %         fill(shade.x, shade.y, aes.blue, 'FaceAlpha', 0.3, 'EdgeColor', 'none');
                            %         hold on
                            % end

                            p.trial = plot([trial.change(i*2-1), trial.change(i*2)], [trial.average(i), trial.average(i)], 'Color', aes.blue, 'LineWidth', aes.thickest);
                            %plot([trial.change(i), trial.change(i+1)], [trial.average(i), trial.average(i)], 'Color', aes.blue, 'LineWidth', 1.5)

                            hold on
                        end
                end
                switch knob.thres
                    case 1
                        % plot the thresholds
                        disp('plotting the thresholds')
                        shade.x = [];
                        for i = 1:length(thres.new)-1
                            switch knob.std
                                case 1
                                    % Define x and y for the shaded area
                                    shade.x = [trial.change(i*2 - 1), trial.change(i*2), trial.change(i*2), trial.change(i*2 - 1)];
                                    shade.y = [thres.new(i)+thres.std(i), thres.new(i)+thres.std(i), thres.new(i)-thres.std(i), thres.new(i)-thres.std(i)];
                                    % Plot the shaded area
                                    fill(shade.x, shade.y, aes.gold, 'FaceAlpha', 0.4, 'EdgeColor', 'none');
                                    hold on
                            end

                            p.thres = plot([trial.change(i*2 - 1), trial.change(i*2)], [thres.new(i), thres.new(i)], 'Color', aes.gold, 'LineWidth', aes.thickest);
                            hold on
                            % trial index is created in every up_on, up_off,
                            % down_on, down_off, timeout

                        end
                end % knob.thres
        end % knob horizontal switch



        %% for the legend
        % find and choose one downreg on, downreg off, timeout, upreg on,
        % upreg off, disc on and prompt, correct & incorrect
        % p.upreg_on = find(EM.time_series == trigger.upreg_on, 1);
        % p.upreg_off = find(EM.time_series == trigger.upreg_off, 1);
        % p.doreg_on = find(EM.time_series == trigger.doreg_on, 1);
        % p.doreg_off = find(EM.time_series == trigger.doreg_off, 1);
        p.refractory = find(EM.time_series == trigger.refractoff,1);
        p.disc_on = find(EM.time_series == trigger.disc_on, 1);
        p.prompt = find(EM.time_series == trigger.prompt, 1);

        p.correct = find(EM.time_series == trigger.th, 1);
        p.incorrect = find(EM.time_series == trigger.fh, 1);

        p.upreg = plot(nan, nan, '-', 'Color', [0.5 0.2 0.6], 'LineWidth',3); % upregulation, clear purple
        hold on
        p.downreg = plot(nan, nan, '-', 'Color', [0.2 0.2 0.2], 'LineWidth',3); % downregulation, clear grey
        hold on
        p.rect_disc = plot(nan, nan, '-', 'Color', aes.green, 'LineWidth',3);
        hold on
        p.rect_correct = plot(nan, nan, ':', 'Color', aes.green, 'LineWidth',1.5);
        hold on
        p.rect_incorrect = plot(nan, nan, ':', 'Color', aes.red, 'LineWidth',1.5);
        hold on
        p.timeout = plot(nan, nan, '--', 'Color', aes.black, 'LineWidth',2);
        hold on



        % knob window

        switch knob.window
            case 1 % old; baseline
                wind.start = find(strcmp([MARKER.line.label], 'start of the baseline'));
                wind.end = find(strcmp([MARKER.line.label], 'end of the baseline'));

                xlim([MARKER.secs(wind.start(1)) MARKER.secs(wind.end(1)+2)])

            case 2 % reg task
                title(['Regulation Task (', subject, ')'], 'interpreter', 'none', 'FontSize', 17)

                paths.fig = [subject, '_reg_task.png'];

                wind.start = find(strcmp([MARKER.line.name], 'regulation task'))+3;
                wind.end = find(strcmp([MARKER.line.name], 'discrimination task'))-1; % the 6th discrimination task

                xlim([MARKER.secs(wind.start(2)) MARKER.secs(wind.end(2))])
                % 1 & 1 for reg task-1
                % 2 & 2 for reg task-2
                switch knob.correct
                    case 1
                        %                         legend([p.aaa, p.task, p.trial, p.thres, p.upreg, p.downreg, p.timeout], ...
                        %                             {'AAA', 'task average', 'trial average', 'threshold value','increase trial (shade)', 'decrease trial (shade)', 'timeout trial'} ...
                        %                             , 'Location', 'best', 'FontSize', 14);

                        %                         legend([p.aaa, p.thres, p.rect_correct, p.rec_incorrect], ...
                        %                             {'AAA', 'Dynamic threshold','Correct answer', 'Incorrect answer'} ...
                        %                             , 'Location', 'best', 'FontSize', 14);
                    case 0
                        legend([p.aaa, p.task, p.thres, p.upreg, p.downreg], ...
                            {'AAA', 'task average', 'threshold value','increase trial (shade)', 'decrease trial (shade)'} ...
                            , 'Location', 'best', 'FontSize', 14);
                end
                
            % switch knob window
            case 3 % discrimination task
                title(['Discrimination Task (', subject, ')'], 'interpreter', 'none', 'FontSize', 17)

                paths.fig = [subject, '_disc_task.png'];

                wind.start = find(strcmp([MARKER.line.name], 'discrimination task'))+2;
                wind.end = find(strcmp([MARKER.line.name], 'regulation task'))+2; % the 6th discrimination task

                xlim([MARKER.secs(wind.start(1)) MARKER.secs(wind.end(2))])
                % 1 & 2 for disc task-1

                % recalculate lims
        MARKER.ylim = [min(AAA.time_series(wind.start(1):wind.end(2))), max(AAA.time_series(wind.start(1):wind.end(2)))];

        ylim([MARKER.ylim(1), MARKER.ylim(2)])
        
        %hardcode
                ylim([MARKER.ylim(1), 25])


                switch knob.correct
                    case 1

                        p.rect_correct = plot(nan, nan, ':', 'Color', aes.blue, 'LineWidth',1.5);
                        hold on
                        p.rect_incorrect = plot(nan, nan, ':', 'Color', aes.orange, 'LineWidth',1.5);
                        hold on
                        p.rect_task = plot(nan, nan, '--', 'Color', aes.grey, 'LineWidth', 1.5);

                        switch knob.deutsch
                            case 0
                        
                        legend([p.aaa, p.rect_task, p.thres, p.rect_correct, p.rect_incorrect], ...
                            {'AAA', 'Mean task AAA' ,'Dynamic threshold','Correct answer', 'Incorrect answer'} ...
                            , 'Location', 'best', 'FontSize', 14);
                            case 1
                                legend([p.aaa, p.thres, p.rect_correct, p.rect_incorrect], ...
                            {'AAA', 'Schwellenwert','Richtige Antwort', 'Falsche Antwort'} ...
                            , 'Location', 'southoutside', 'FontSize', 17, 'NumColumns', 2);

                                   
                        end % knob.deutsch

                    case 0

                        legend([p.aaa, p.task, p.thres, p.rect_disc], ...
                            {'AAA', 'task average', 'threshold value','discrimination trial (shade)'} ...
                            , 'Location', 'best', 'FontSize', 20);
                end

        end

        set(gca, 'Box', 'off'); % removes the big box
        %axis square;
        ax = gca;
        ax.LineWidth = 2;
        set(ax, 'TickDir', 'out'); % moves the ticks out
        ax.TickLength = [0.02 0.02]; % makes them thicke
        ax.Layer = 'top';
        set(ax, 'FontSize', 15); % hopefully will improve the ticks
        ti = ax.TightInset;
        ax.Position = [ti(1) ti(2) 1 - ti(1) - ti(3) 1 - ti(2) - ti(4)];

        af = gcf;
        set(af,'Units','inches','Position',[1 1 9 5]);  % wide aspect (adjust as you like)

        %                    af.Position = [1 1 1100 600]; % for the window undock size






        %% save the figure


        switch knob.save
            case 1
                exportgraphics(fig, [paths.save, paths.fig],'Resolution',300);
        end



    case 0
        disp('without plot')
end % knob.plot
toc









































