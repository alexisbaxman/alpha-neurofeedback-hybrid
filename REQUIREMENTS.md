**Requirements**

This document lists the dependencies required to run the neurofeedback experiment and analyze its results. Some dependencies must be placed in the libs/ directory, while others require separate installation. Most third-party dependencies are not redistributed in this repository and must be obtained separately.

**1. Software requiring separate installation**
* **MATLAB R2022b:** The experiment and analysis scripts were developed for this version. It also requires the Signal Processing and Statistics Toolboxes.
* **Psychtoolbox 3.0.18:** Requires installation. It also requires separately installation of **GStreamer**.
* **Purr Data 2.20.1:** It generates the red noise.
 
**2. Dependencies in libs/**
* **EEGLAB 2025.0.0:** Required for experiment and analysis scripts. Additionally, requires the **XDF import plugin (version 1.2)**.
* **Lab Streaming Layer 1.14.0 [liblsl-Matlab](https://github.com/labstreaminglayer/liblsl-Matlab/)** 
* OSC communication files: **sendosc v1.0.2** and **NetUtil 1.0.0**.
* **violin_half.m**: Included in this repository. It creates the violin plots. It is a modified version of violin.m by Hoffmann (2015).

