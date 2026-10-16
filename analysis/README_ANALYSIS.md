This Folder contains the MATLAB script used to analyze the datasets. 

* 01_load_participant: basic loading script, it loads all variables of a given dataset (choose subject at line 10), including the .xdf file and separates the cells into different variables. It also has many of the hardcoded variables, such as the variables of the ring buffer and triggers in the Event Markers (EM).

* mt2_big_plot: it requires mt1 to be run before. It requires MATLAB2025 for the plotting. It goes through all Event Markers and identifies it. Then it plots the whole session (therefore it takes some time). You can choose whether to "focus" on a regulation or a discrimination task (knob.window). You can also run it without plotting with knob.plot.

* mt3_plot_task_with_sonification: it requires mt1 and mt2 to be run before. It plots a regulation task along with a subplot of the sonificaition values.

* mt4_run_main_analyses: it doesn't require any previous script. With the toggle knob.plot you can choose to run the analyses of the differences in the regulation task between hybrid and intermittent condition, the discrimination task between hybrid and intermittent and figure 4.


* mt5_discrimination_amplitude_extremity:  tests the magnitude effect (association between discrimination accuracy and alpha amplitude extremity). knob.distance selects which distance metric is used. Produces Figure 5.

* mt7: it analyzes the questionnaires to investigate hypothesis 4 and some exploratory Analysis (anova)
* mt8: investigate both criterions, Regulation and discrimination. It also investigates the explroatory Analysis wether regualtion Performance correlates with Amplitude difference between Trial direction.

