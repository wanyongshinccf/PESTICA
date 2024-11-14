PESETICA: physsiologoc noise esitmator using temporal ICA

Requirement
AFNI and MATLAB should be installed and included in a PATH.
For example, type "afni" and "matlab" in your shell terminal. 
They should bring the program properly.

How to install
1) Download the PESTICA package in your local directory 
2) Set path in your enviroment.
   For example, if you download the package in /Users/CCF/PESTICA
   export PATH=$PATH:/Users/CCF/PESTICA in a bash/zsh shell
   set (or setevn) PATH = $PATH::/Users/CCF/PESTICA in csh/zcsh

How to use PESTICA (See a help in run_pestica.tcsh)

run_pestica.tcsh \
  -dset_epi <no motion corrected epi data, e.g. "epi.nii or epi+orig"> \
  -dset_mask <your own mask, e.g. "epi_mask.nii or epi_mask+orig"> \
  -tfile <slice acquisition timiming file, see "example_tfile.1D" > \
    or
  -json <"a json file from dcm2niix" > \
  -workdir <your working directory e,g. "PESTICA" > \
  -prefix <output file name> \
  -auto -do_clean

While the output file is the cardiac and respiratory noise corrected datset,
we recommend using "PESTICA/RetroTS.PESTICA.slibase.1D" instead of the output image.
You might delete a output file after run_pestica.tcsh to save the local space.

RetroTS.PESTICA.slibase.1D is a slicewise regressor 1D file, which is used in 
3dREMLfit with other motion nuisance regressor AFTER motion correction. 

We suggest using SLOMOCO after run_pestica.tcsh

run_slomoco.tcsh \
  -dset_epi <no motion corrected epi data, e.g. "epi.nii or epi+orig"> \
  -dset_mask <your own mask, e.g. "epi_mask.nii or epi_mask+orig"> \
  -tfile <slice acquisition timiming file, see "example_tfile.1D" > \
    or
  -json <a json file from dcm2niix > \
  -workdir <your working directory e,g. "SLOMOCO" > \
  -prefix <output file name, e.g. "epi.slomoco" > \
  -physio <slicewise regresor file, e.g. "RetroTS.PESTICA.slibase.1D" > \
  -do_clean

Finally, run_pestica.tcsh runs RETROICOR with the external physiologogic 
signal files, e,g. -pmu option, and generates RetroTS.PMU.slibase.1D, 
which is also an input for 3dRELMfit.

Citation
Shin W, Koenig KA, Lowe MJ. A comprehensive investigation of physiologic noise modeling in resting state fMRI; 
time shifted cardiac noise in EPI and its removal without external physiologic signal measures. 
Neuroimage. 2022 Jul 1;254:119136. doi: 10.1016/j.neuroimage.2022.119136. Epub 2022 Mar 26. PMID: 35346840.

Beall EB, Lowe MJ. Isolating physiologic noise sources with independently determined spatial measures. 
Neuroimage. 2007 Oct 1;37(4):1286-300. doi: 10.1016/j.neuroimage.2007.07.004. Epub 2007 Jul 13. PMID: 17689982.

+++++++++++++++++++++++++++++

Included the software packages
EEGLAB developed by SCCN/UCSD

Cite As
Arnaud Delorme (2024). EEGLAB (https://github.com/sccn/eeglab), GitHub. Retrieved June 4, 2024.

Delorme A, Makeig S. EEGLAB: an open-source toolbox for analysis of single-trial EEG dynamics 
including independent component analysis. J Neurosci Methods. 2004 Mar 15;134(1):9-21. 
doi: 10.1016/j.jneumeth.2003.10.009. PMID: 15102499.

Matlab codes genernated by Ziad Saad SSCC/NIMH/NIH.
See a README file in afni_matlab directory

PESTICA is a free research tool (not for clinical usage).
Feel free to modify it and cite the literatures if it is used for your research.



