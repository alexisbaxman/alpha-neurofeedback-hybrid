This Folder contains the MATLAB script used to analyze the datasets. 
* **mt1_load_participant**: Basic loading script. It loads all variables of a given dataset (choose the subject at line 10), including the .xdf file, and separates the cells into different variables. It also contains many of the hardcoded variables, such as the ring buffer variables and the triggers in the Event Markers (EM).

* **mt2_plot_task_events**: Requires mt1 to be run first. It goes through all Event Markers and identifies them, then plots the whole session (so it takes some time, close to a minute). You can choose whether to focus on a regulation or a discrimination task (`knob.window`).

* **mt3_plot_task_with_sonification**: Requires mt1 and mt2 to be run first. It plots one regulation task along with a subplot of the sonification values. For completeness, run mt2 with the refractory windows enabled (`knob.refractory = 1`).

* **mt4_run_main_analyses**: Compares regulation and discrimination performance in both conditions, and plots boxplots comparing performance.

* **mt5_discrimination_magnitude_effect**: Analyzes the magnitude effect on discrimination accuracy, and plots the percent correct in percentile bins for the whole group and for participants with significant correlations.

* **mt6_criteria**: Analyzes the Frederick et al. (2016) criteria for regulation and discrimination in our sample, and plots the regulation amplitude modulation.

* **mt7_baseline_reactivity**: Analyzes every participant's baseline and calculates the baseline reactivity. Plots each participant's baseline and a scatterplot of all participants' baseline reactivity.

* **mt8_alpha_across_blocks**: Analyzes and plots how alpha amplitude changes across blocks for all participants.

* **mt9_amplitude_anova**: Analyzes and plots how alpha amplitude changes between directions and conditions.

* **mt10_time_estimates**: Calculates the time that all participants need to complete the different parts of the experiment.

* **mt11_ica**: Imports the raw data, reads the channel locations, filters (1-40 Hz), screens for bad channels, creates "fake epochs" and epochs the data into them, runs ICA, reloads the raw data, and saves it with the ICA weights.

* **mt12_reject_ica_components**: Removes artifact components from the ICA decomposition computed in mt11, using ICLabel-based automatic rejection.

* **mt13_offline_reconstruction**: Offline reconstruction of the online pipeline, without the 4-second ring buffer structure, to calculate the delay and amplitude difference, with plotting.
  
