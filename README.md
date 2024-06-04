PESETICA: physsiologoc noise esitmator using temporal ICA

How to install
Download the PESTICA package in your local and set path in your enviroment.
For example, if you download the package in /Users/wyshin/SLOMOCO
export PATH=$PATH:/Users/wyshin/SLOMOCO in bash/zsh
set (or setevn) PATH = $PATH::/Users/wyshin/SLOMOCO in csh/zcsh

AFNI and MATLAB should be installed and included in PATH
Type "afni" and "matlab" in your terminal. They should bring the program properly.

Included the software packages
EEGLAB developed by SCCN/UCSD

Cite As
Arnaud Delorme (2024). EEGLAB (https://github.com/sccn/eeglab), GitHub. Retrieved June 4, 2024.

Delorme A, Makeig S. EEGLAB: an open-source toolbox for analysis of single-trial EEG dynamics 
including independent component analysis. J Neurosci Methods. 2004 Mar 15;134(1):9-21. 
doi: 10.1016/j.jneumeth.2003.10.009. PMID: 15102499.

Matlab codes genernated by Ziad Saad SSCC/NIMH/NIH.
See a README file in afni_matlab directory

Example 
run_pestica.tcsh <options>

Required options:
 -dset_epi input     = input data is non-motion corrected 4D EPI images. 
                       DO NOT apply any motion correction on input data.
                       It is not recommended to apply physiologic noise correction on the input data
                       Physiologoc noise components can be regressed out with -phyio option 
 -tfile 1Dfile       = 1D file is slice acquisition timing info.
                       For example, 5 slices, 1s of TR, ascending interleaved acquisition
                       [0 0.4 0.8 0.2 0.6]
      or 
 -jsonfile jsonfile  = json file from dicom2nii(x) is given
 -prefix output      = output filename
 
Optional:
 -dset_mask			     = skull stripped mask 
 -physio		 	       = pmu file prefix for RETROICOR (NOT PESTICA)  
 -workdir  directory = intermediate output data will be generated in the defined directory.
 -do_clean           = this option will delete the large size of files in working directory 

PESTICA is a free research tool (not for clinical usage).
Feel free to modify it and cite the literatures if it is used for your research.

Citation
Shin W, Koenig KA, Lowe MJ. A comprehensive investigation of physiologic noise modeling in resting state fMRI; 
time shifted cardiac noise in EPI and its removal without external physiologic signal measures. 
Neuroimage. 2022 Jul 1;254:119136. doi: 10.1016/j.neuroimage.2022.119136. Epub 2022 Mar 26. PMID: 35346840.

Beall EB, Lowe MJ. Isolating physiologic noise sources with independently determined spatial measures. 
Neuroimage. 2007 Oct 1;37(4):1286-300. doi: 10.1016/j.neuroimage.2007.07.004. Epub 2007 Jul 13. PMID: 17689982.

