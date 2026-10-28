**Dependencies**
This directory should contain the third-party dependencies required to run the neurofeedback experiment and analyze its results. Most third-party dependencies are not redistributed in this repository and must be obtained and installed separately. This folder must be located on the local C: drive.

**General dependencies**
* **MATLAB R2022b:** The experiment and analysis scripts were developed for MATLAB R2022b.
* **EEGLAB 2025.0.0:** Required for experiment and analysis scripts. Additionally, requires the **XDF import plugin (version 1.2)**.

**Experiment-specific dependencies**
* **Lab Straming Layer (liblsl-Matlab)** 
* **Psychtoolbox 3.0.19:** Requires installation. It also requires separatedly installation of GStreamer.
* **Purr Data:** It generates the red noise (red_noise.pd). Requires installation.
* OSC communation files: **send_osc.m** and **netutil-1.0.0.jar**.


**Analysis-specific dependencies**
* **violin_half.m**: Included in this repository. It creates the violin plots. It is a modified version of violin.m by Hoffmann (2015) for MATLAB 2025.

