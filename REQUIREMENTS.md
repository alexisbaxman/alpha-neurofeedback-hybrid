**Requirements**

This document lists the dependencies required to run the neurofeedback experiment and analyze its results. Some dependencies must be placed in the libs/ directory, while others require separate installation. Most third-party dependencies are not redistributed in this repository and must be obtained separately.

**1. Software requiring separate installation**
* **MATLAB R2022b:** The experiment and analysis scripts were developed for this version.
* * **Psychtoolbox 3.0.19:** Requires installation. It also requires separatedly installation of **GStreamer**.
* **Purr Data:** It generates the red noise.
 
**2. Dependencies in libs/**
* **EEGLAB 2025.0.0:** Required for experiment and analysis scripts. Additionally, requires the **XDF import plugin (version 1.2)**.
* **Lab Streaming Layer [liblsl-Matlab](https://github.com/labstreaminglayer/liblsl-Matlab/)** 
* OSC communation files: **[send_osc.m](https://github.com/yoggy/sendosc)** and **[netutil-1.0.0.jar](https://jar-download.com/artifact-search/netutil)**.
* **violin_half.m**: Included in this repository. It creates the violin plots. It is a modified version of violin.m by Hoffmann (2015).

