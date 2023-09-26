PESTICA uses AFNI, Matlab and bash commands.
AFNI commands and matlab should be path-defined.
- In your bash shell, type "afni" and "matlab". They should work to run PESTICA. 

PESTICA is the cardiac and respiratory noise estimation and its correction tool without the external physio data
If you use PESTICA in your work, please cite

Shin W, Koenig KA, Lowe MJ. A comprehensive investigation of physiologic noise modeling in resting state fMRI; time shifted cardiac noise in EPI and its removal without external physiologic signal measures. Neuroimage. 2022 Jul 1;254:119136. doi: 10.1016/j.neuroimage.2022.119136. Epub 2022 Mar 26. PMID: 35346840.

###############################
## PLEASE READ IT CAREFULLY ###
###############################
Two important factors strongly rely on PESTICA performance.

##########################################
1. correct slice acquisition timing info
##########################################
PESTICA estimates physio component in each slice and concatenates them in slice aquisition time.
IF slice acquisition timing is not corrrect, PESTICA DOES NOT WORK.

Default is, single band ascending interleaved order (Siemens convention)
e.g. 1-3-5-2-4 in case of 5 slices, 2-4-6-1-3-5 in case of 6 slices,
Otherwise, you have to provide the correct slice acquisiiton information.

Provide tshiftfile.1D (row vector)or tshiftfile_sec.1D (column vector) in the same location as input file
Example of tshiftfile.1D (single band, 31 slices, TR=2.8)
0          1.445           0.09          1.535          0.181          1.626          0.271          1.716          0.361          1.806          0.452          1.897          0.542          1.987          0.632          2.077          0.723          2.168          0.813          2.258          0.903          2.348          0.994          2.439          1.084          2.529          1.174          2.619          1.265           2.71          1.355

Example of tshiftfile_sec.1D (single band, 31 slices, TR=2.8)
0
1.445
0.09
1.535
0.181
...

You can generate slice acq timing file using genSMStimeshiftfile.m in pestica_matlab directory
Other option would be to create tshiftfile_sec.1D and copy and past "SliceTiming" vector from json file. 

SMS (MB) slice acquisition should be provided correctly
If your SMS data is ascending interleaved order following Siemens convntion, 
you can use "-m" option. (see the below)

#################
2. Brain coverage
#################
PESTICA concatenates the slicewise physiologic noise component.
If your data has non-brain tissue in many slices, e.g. top or bottom slices,
PESTICA does not work or the perforance is very limited.
SMS (multi-band) acquisition does not matter 
 
Please report it in NITRC website (www.nitrc.org/projects/pestica) and share your solution 

#############
### Usage ###
#############
1. Modify setup_pestica.sh; define your own PESTICA_DIR variable.
2. type "source <<PESTICA_DIR>>/setup_pestica.sh"
2. Go to working directory where your EPI data is stored
3. Provide tshiftfile.1D or tshiftfile_sec.1D in your study directory, if necessary.
4.a run_pestica.sh -d <<EPI>> -b
4.b run_pestica.sh -d <<EPI>> -m <<SMS acceleration number>> -b

Output 

PESTICA5/<<EPI>>.retroicor_pestica+orig
  4 cardiac components, 1 respiratory component are regressoud out with polynomial detrending
  Tissue contrast still reserves.

PESTICA5/<<EPI>>.retroicor_pestica.bucket+orig
  F value of full model, and each cardiac and respiratory models
  coefficients and student t-score of each regressor
  check retroicor_pestica.m

PESTICA5/Coupling_retroicor_pestica_CARD(RESP).png
  the colored area indicates PESTICA reduces the physio logic noise with less than p < 0.01 
  Colored areas are expected to be arteries/veins in CARD.png and 
  PE directional brain tissue boundary/edge in RESP.png
  No color area means that PESTICA does not work well with your data
  More detailed statistica information can be found in <<EPI>>.retroicor_pestica.bucket+orig  

PESTICA5/RetroTS.PESTICA5.slibase.1D
  AFNI pipeline compatible 1D regressor
  snip of the header 
  ...
  # ColumnLabels = " s0.Resp s0.Card0 ; s0.Card1 ; s0.Card2 ; s0.Card3 ; s1.Resp s1.Card0 ; s1.Card1 ; s1.Card2 ; s1.Card3 ; ... "
  each slice has 1 respiratory and 4 cardiac regressors.

PESETICA package includes RETROICOR pipeline with PMU data
RVT is turn off. You can modify it, if necessary. 
RVHR option is provided. You can modify it, if necessary. (see retroicor_pmu.m)

#############
### Usage ###
#############
run_pestica.sh -d <<EPI>> -p <physio> 

Output 
PHYSIO/<<EPI>>.retroicor_pmu+orig
  4 cardiac and respiratory components (total 8) are regressoud out with polynomial detrending
  Tissue contrast still reserves.

PHYSIO/<<EPI>>.retroicor_pmu.bucket+orig
  F value of full model, and each cardiac and respiratory models
  coefficients and student t-score of each regressor

RetroTS.PMU.slibase.1D
  AFNI pipeline compatible 1D regressor

######################################################
The below is the evaluation of PESTICA with your data.
######################################################

DO NOT compare with PESTICA regressor with PMU DATA.
PESTICA5 regressor is the signal fluctuation reflected on image.
The (relatively) fair comparison between PMU and PESETIC regressor would be
to generate single cardiac and respiratory components using RETROICOR and
to compared them, which is presented in the paper above.

Otherwise, residual sum of square of the regress-out model would be fair. 

1. run_retroicor.sh -d <EPI> -p <PMU>
It will generate PHYSIO/RetroTS.PMU.slibase.1D
2. run_pestica.sh -d <EPI> -b
It will generate PHYSIO/RetroTS.PESTICA5.slibase.1D

input=<your EPI>
3dDeconvolve -polort 3 -input $input+orig.HEAD \
     -x1D rm.polort.xmat.1D -prefix $input.det+orig

3dDetrend -polort 3 -prefix rm.det+orig $input+orig

3dREMLfit -input $input+orig -matrix rm.polort.xmat.1D    \
    -Obeta rm.ricor.betas -Oerrts rm.ricor.errts                               \
    -slibase_sm PHYSIO/RetroTS.PMU.slibase.1D

3dREMLfit -input $input+orig -matrix rm.polort.xmat.1D    \
    -Obeta rm.pestica.betas -Oerrts rm.pestica.errts                               \
    -slibase_sm PESTICA5/RetroTS.PESTICA5.slibase.1D

3dTstat -sos -prefix RSOS.polort rm.det+orig
3dTstat -sos -prefix RSOS.ricor rm.ricor.errts+orig
3dTstat -sos -prefix RSOS.pestica5 rm.pestica.errts+orig

3dcalc -a RSOS.polort+orig -b RSOS.ricor+orig -c PESTICA5/$input.brain+orig \
  -expr '100*b/a*step(c)' -prefix RSOSreduction.ricor+orig
3dcalc -a RSOS.polort+orig -b RSOS.pestica5+orig -c PESTICA5/$input.brain+orig \
  -expr '100*b/a*step(c)' -prefix RSOSreduction.pestica5+orig

# compare with RSOS reduction ratio between RETROICOR and PESTICA5.





