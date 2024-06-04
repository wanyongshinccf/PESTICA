#!/bin/tcsh

set version   = "0.0";  set rev_dat   = "Jun 3, 2024"
# + tcsh version of Wanyong Shin's PESTICA program
#
# ----------------------------------------------------------------

# -------------------- set environment vars -----------------------

setenv AFNI_MESSAGE_COLORIZE     NO         # so all text is simple b/w

# ----------------------- set defaults --------------------------

set this_prog = "run_pestica"
set here      = $PWD

set prefix    = ""
set odir      = $here
set opref     = ""
set wdir      = ""

# --------------------- slomoco-specific inputs --------------------

# all allowed slice acquisition keywords
set epi        = ""   # base 3D+time EPI dataset to use to perform corrections
set epi_mask   = ""   # (opt) mask dset name
set jsonfile   = ""   # json file
set tfile      = ""      # tshiftfile (sec)
set physiofile = "" # physio file (pmu) for RETROICOR 
set batchflag  = 0 # default 
set icaflag    = "matlab" # MATLAB or fsl
set fastpmucorflag = 0 # just for option

set DO_CLEAN     = 0                       # default: keep working dir

set histfile = log_pestica.txt
set do_echo  = ""

set fullcommand 		= "$0"
set PESTICA_DIR 		= `dirname $fullcommand`
set MATLAB_AFNI_DIR    	= $PESTICA_DIR/afni_matlab
set MATLAB_PESTICA_DIR 	= $PESTICA_DIR/pestica_matlab
set MATLAB_EEGLAB_DIR  	= $PESTICA_DIR/eeglab
set PESTICA_VOL_DIR  	= $PESTICA_DIR/template


# ------------------- process options, a la rr ----------------------

if ( $#argv == 0 ) goto SHOW_HELP

set ac = 1
while ( $ac <= $#argv )
    # terminal options
    if ( ("$argv[$ac]" == "-h" ) || ("$argv[$ac]" == "-help" )) then
        goto SHOW_HELP
    endif
    if ( "$argv[$ac]" == "-ver" ) then
        goto SHOW_VERSION
    endif

    if ( "$argv[$ac]" == "-echo" ) then
        set echo
        set do_echo = "-echo"

    # --------- required

    else if ( "$argv[$ac]" == "-dset_epi" ) then
        if ( $ac >= $#argv ) goto FAIL_MISSING_ARG
        @ ac += 1
        set epi = "$argv[$ac]"

    else if ( "$argv[$ac]" == "-prefix" ) then
        if ( $ac >= $#argv ) goto FAIL_MISSING_ARG
        @ ac += 1
        set prefix = "$argv[$ac]"
        set opref  = `basename "$argv[$ac]"`
        set odir   = `dirname  "$argv[$ac]"`

    # --------- required either of tfile or json option
    else if ( "$argv[$ac]" == "-tfile" ) then
        if ( $ac >= $#argv ) goto FAIL_MISSING_ARG
        @ ac += 1
        set tfile = "$argv[$ac]"

    else if ( "$argv[$ac]" == "-json" ) then
        if ( $ac >= $#argv ) goto FAIL_MISSING_ARG
        @ ac += 1
        set jsonfile = "$argv[$ac]"

    # --------- opt
    else if ( "$argv[$ac]" == "-dset_mask" ) then
        if ( $ac >= $#argv ) goto FAIL_MISSING_ARG
        @ ac += 1
        set epi_mask = "$argv[$ac]"

    else if ( "$argv[$ac]" == "-pmu" ) then
        if ( $ac >= $#argv ) goto FAIL_MISSING_ARG
        @ ac += 1
        set physiofile = "$argv[$ac]"

    # below, checked that only allowed keyword is used
    else if ( "$argv[$ac]" == "-dset_unsat_epi" ) then
        if ( $ac >= $#argv ) goto FAIL_MISSING_ARG
        @ ac += 1
        set unsatepi = "$argv[$ac]"

    else if ( "$argv[$ac]" == "-workdir" ) then
        if ( $ac >= $#argv ) goto FAIL_MISSING_ARG
        @ ac += 1
        set wdir = "$argv[$ac]"

        set tf = `python -c "print('/' in '${wdir}')"`
        if ( "${tf}" == "True" ) then
            echo "** ERROR: '-workdir ..' is a name only, no '/' allowed"
            goto BAD_EXIT
        endif

    else if ( "$argv[$ac]" == "-do_clean" ) then
        set DO_CLEAN     = 1
        
    else if ( "$argv[$ac]" == "-auto" ) then
        set batchflag     = 1
        
    else
        echo ""
        echo "** ERROR: unexpected option #$ac = '$argv[$ac]'"
        echo ""
        goto BAD_EXIT
        
    endif
    @ ac += 1
end

# =======================================================================
# ======================== ** Verify + setup ** =========================

# define SLOMOCO directory
set fullcommand = "$0"
setenv PESTICA_DIR `dirname "${fullcommand}"`

# initialize a log file
echo "" >> $histfile
date >> $histfile
echo "" >> $histfile


# ----- find AFNI 

# find AFNI binaries directory
set adir      = ""
which afni >& /dev/null
if ( ${status} ) then
    echo "** ERROR: Cannot find 'afni'" |& tee -a ${histfile}
    goto BAD_EXIT
else
    set aa   = `which afni`
    set adir = $aa:h
endif

# ----- output prefix/odir/wdir

echo "++ Work on output naming"

if ( "${prefix}" == "" ) then
    echo "** ERROR: need to provide output name with '-prefix ..'" |& tee -a ${histfile}
    goto BAD_EXIT
endif

# check output directory, use input one if nothing given
if ( ! -e "${odir}" ) then
    echo "++ Making new output directory: $odir" |& tee -a ${histfile}
    \mkdir -p "${odir}"
endif

# make workdir name, if nec
if ( "${wdir}" == "" ) then
    set tmp_code = `3dnewid -fun11`  # should be essentially unique hash
    set wdir     = __workdir_${this_prog}_${tmp_code}
endif

# simplify path to wdir
set owdir = "${odir}/${wdir}"

# make the working directory
if ( ! -e "${owdir}" ) then
    echo "++ Making working directory: ${owdir}" |& tee -a ${histfile}
    \mkdir -p "${owdir}"
else
    echo "+* WARNING:  Somehow found a premade working directory:" |& tee -a ${histfile}
    echo "      ${owdir}" |& tee -a ${histfile}
endif

# find slice acquisition timing
if ( "${jsonfile}" == "" && "${tfile}" == "" ) then
    echo "** ERROR: slice acquisition timing info should be given with -json or -tfile option" |& tee -a ${histfile}
    goto BAD_EXIT
else
  if ( ! -e "${jsonfile}" && "${jsonfile}" != "" ) then
    echo "** ERROR: Json file does not exist" |& tee -a ${histfile}
    goto BAD_EXIT
  endif
  if ( ! -e "${tfile}" && "${tfile}" != "" ) then
    echo "** ERROR: tshift file does not exist" |& tee -a ${histfile}
    goto BAD_EXIT
  endif
endif

# ----- find required dsets, and any properties

if ( "${epi}" == "" ) then
    echo "** ERROR: need to provide EPI dataset with '-dset_epi ..'" |& tee -a ${histfile}
    goto BAD_EXIT
else
    # verify dset is OK to read
    3dinfo "${epi}"  >& /dev/null
    if ( ${status} ) then
        echo "** ERROR: cannot read/open dset: ${epi}" |& tee -a ${histfile}
        goto BAD_EXIT
    endif

    # must have +orig space for input EPI
    set av_space = `3dinfo -av_space "${epi}" `
    if ( "${av_space}" != "+orig" ) then
        echo "** ERROR: input EPI must have +orig av_space, not: ${av_space}" |& tee -a ${histfile}
        goto BAD_EXIT
    endif

    # copy to wdir
    3dcalc 							\
        -a "${epi}"               	\
        -expr 'a'                 	\
        -prefix "${owdir}/epi_00" 	\
        -overwrite					
endif


# ---- check dsets that are optional, to verify (if present)
# unsaturated EPI image might be useful for high SMS accelrated dataset, e.g. HCP
# the below is commmented (out 20231208, W.S)
# these lists must have same length: input filenames and wdir
# filenames, respectively
# set all_dset = ( "${unsatepi}" "${epi_mask}" )
# set all_wlab = ( unsatepi_00.nii.gz epi_mask )

# if ( ${#all_dset} != ${#all_wlab} ) then
    
#    echo "** ERROR in script: all_set and all_wlab must have same len"
#    goto BAD_EXIT
# endif

# finally go through list and verify+copy any that are present
# foreach ii ( `seq 1 1 ${#all_dset}` )
    # must keep :q here, to keep quotes, in case fname is empty
#     set dset = "${all_dset[$ii]:q}"
#     set wlab = "${all_wlab[$ii]:q}"
#     if ( "${dset}" != "" ) then
#         # verify dset is OK to read
#         3dinfo "${dset}"  >& /dev/null
#         if ( ${status} ) then
#             echo "** ERROR: cannot read/open dset: ${dset}"
#             goto BAD_EXIT
#         endif
# 
        # # must have same grid as input EPI
#         set same_grid = `3dinfo -same_grid "${epi}" "${dset}"`
#         if ( "${same_grid}" != "1 1" ) then
#             echo "** ERROR: grid mismatch between input EPI and: ${dset}"
#             goto BAD_EXIT
#         endif

#         # at this point, copy to wdir
#         3dcalc                                \
#             -a "${dset}"                      \
#             -expr 'a'                         \
#             -prefix "${owdir}/${wlab}" 
#     endif
# end

# ----- make automask, if one is not provided

if ( "${epi_mask}" == "" ) then
    echo "++ No mask provided, will make one" |& tee -a ${histfile}
    # remove skull (PT: could use 3dAutomask)
    3dSkullStrip                            \
        -input "${owdir}"/epi_00+orig       \
        -prefix "${owdir}/___tmp_mask0" 	\
        -overwrite							

    # binarize
    3dcalc                              \
        -a "${owdir}/___tmp_mask0+orig" \
        -expr 'step(a)'                 \
        -prefix "${owdir}/___tmp_mask1"	\
        -datum byte -nscale             \
        -overwrite						

    # inflate mask; name must match wlab name for user mask, above
    3dcalc \
        -a "${owdir}/___tmp_mask1+orig"				\
        -b a+i -c a-i -d a+j -e a-j -f a+k -g a-k 	\
        -expr 'amongst(1,a,b,c,d,e,f,g)'          	\
        -prefix "${owdir}/epi_base_mask"        	\
        -overwrite									

    # clean a bit
    rm ${owdir}/___tmp*
else
    echo "** Brain mask file is provided. " |& tee -a ${histfile}
    3dcalc -a "${epi_mask}"                 \
           -expr 'step(a)'                  \
           -prefix "${owdir}/epi_base_mask" \
           -nscale                          \
           -overwrite						
endif

# ----- save name to apply
set epi_mask = "${owdir}/epi_base_mask+orig"

# ----- slice timing file info
if ( "$jsonfile" != "" && "$tfile" != "")  then
  echo " ** ERROR:  Both jsonfile and tfile options should not be used." |& tee -a ${histfile}
  goto BAD_EXIT
else if ( "$jsonfile" != "")  then
  abids_json_info.py -json $jsonfile -field SliceTiming | sed "s/[][]//g" | sed "s/,//g" | xargs printf "%s\n" > ${owdir}/tshiftfile.1D
else if ( "$tfile" != "")  then
  cp $tfile ${owdir}/tshiftfile.1D
endif

# =======================================================================
# =========================== ** Main work ** ===========================

# move to wdir to do work
cd "${owdir}"

# tissue masked brain
3dcalc -a epi_00+orig'[0]' 	\
	-b epi_base_mask+orig 	\
	-expr 'a*step(b)' 		\
	-prefix epi_00_brain	\
	-overwrite				

# polynomial detrending matrix
3dDeconvolve 			\
	-polort A 			\
	-input epi_00+orig 	\
	-x1D_stop 			\
	-x1D polort_xmat.1D	
	
# detrending	
3dREMLfit						\
 	-input epi_00+orig			\
	-matrix polort_xmat.1D 		\
	-mask epi_base_mask+orig 	\
    -Oerrts epi_01_errts 		\
    -overwrite					
    
1dcat polort_xmat.1D > rm.polort_xmat.1D 

if ( $physiofile != "" ) then
  	set physiofile = "../$physiofile"
  	echo "Reading PMU files of $physiofile " |& tee -a ../${histfile}
  	matlab -nodesktop -nosplash -r "disp('Starting script...'); addpath $MATLAB_PESTICA_DIR; addpath $MATLAB_AFNI_DIR; addpath $MATLAB_EEGLAB_DIR; rw_pmu_siemens('epi_01_errts+orig','$physiofile'); [SN RESP CARD] = RetroTS_CCF_adv('epi_01_errts+orig','card_raw_pmu.dat','resp_raw_pmu.dat'); exit;" |& tee     $histfile
  	if ( $fastpmucorflag -eq 1 ) then # afni RETROICOR
    	echo "AFNI RETROICOR is running now." |& tee -a ../${histfile}
    	3dDetrend \
    		-polort 1 \
    		-prefix rm.ricor.1D \
    		RetroTS.PMU.slibase.1D\'
    		
    	1dtranspose rm.ricor.1D ricor_det.1D
    
    	3dREMLfit \
    		-input epi_01_errts+orig \
    		-matrix rm.polort.xmat.1D \
    		-mask epi_base_mask+orig \
        	-Obeta epi_01_polort_betas \
        	-Oerrts epi_02_retroicor_pmu  \
        	-slibase_sm ricor_det.1D

    	3dSynthesize \
    		-matrix epi_01_polort.xmat.1D \
    		-cbucket epi_01_polort_betas+orig \
    		-select polort \
    		-prefix temp+orig \
    		-overwrite
    	3dcalc \
    		-a temp+orig \
    		-b epi_01_polort_errts_retroicor_pmu+orig \
    		-expr 'a+b' \
    		-prefix epi_02_retroicor_pmu+orig \
    		-overwrite

    	rm temp+orig* rm.*

  	else
    	echo "Matlab version of RETROICOR is running now." |& tee -a ../${histfile}
    	echo "It provides PMU quality assurance and RETRROICOR fitting results." |& tee -a ../${histfile}
    	echo "If you do not need them, set fastpmucorflag to 1 in run_pestica.tcsh." |& tee -a ../${histfile}
    	matlab -nosplash -r "disp('Starting script...'); addpath $MATLAB_PESTICA_DIR; addpath $MATLAB_AFNI_DIR; addpath $MATLAB_EEGLAB_DIR; load RetroTS.PMU.mat; [RESP CARD] = retroicor_pmu('$epi+orig','$epi_mask+orig',SN, CARD, RESP,'rm.$epi.polort.xmat.1D'); exit;" 
  	endif

else
	# PESTICA starts
	if ( $icaflag == "matlab" ) then
    	echo "Running Stage 1: slicewise temporal Infomax ICA" |& tee -a ../${histfile}
    	matlab -nodesktop -nosplash -r "addpath $MATLAB_AFNI_DIR; addpath $MATLAB_PESTICA_DIR; addpath $MATLAB_EEGLAB_DIR;disp('Wait, script starting...'); prepare_ICA_decomp_polort(15,'epi_01_errts+orig','epi_base_mask+orig'); disp('Stage 1 Done!'); exit;" 
	
	# Under development, not working yet
  	else if ( $icaflag == "fsl" ) then
    	echo there1
		set dims = `3dAttribute DATASET_DIMENSIONS epi_00.nii`
		set zdim = ${dims[3]}                           # tcsh uses 1-based counting
		@   zcount  = ${zdim} - 1

		foreach z ( `seq 0 1 ${zcount}` )
  			3dZcutup -keep $z $z -prefix epi_01.sli."${z}".nii epi_01.nii 
  			3dZcutup -keep $z $z -prefix epi_mask.sli."${z}".nii epi_mask.nii 
  
  			# ICA here
  			melodic -i epi_01.sli."${z}".nii -m epi_mask.sli."${z}".nii --report
  
		end  # end of t loop 
  
  	endif

	echo "Running Stage 2: Coregistration of EPI to MNI space and back-transform of templates, followed by PESTICA estimation" |& tee -a ../${histfile}
  	# EPI to MNI
  	if ( ! -f mni.coreg.1D ) then
    	3dAllineate 										\
    		-prefix epi_01_brain.crg2mni.nii 				\
    		-source epi_00_brain+orig 						\
    		-base $PESTICA_VOL_DIR/meanepi_mni.brain.nii 	\
    		-1Dmatrix_save epi_01_brain.coreg.mni.1D 		\
    		-overwrite										
    		
        cat_matvec epi_01_brain.coreg.mni.1D -I -ONELINE > mni.coreg.1D -overwrite
        
  	endif

  	# move PESTICA template mni to EPI space
  	3dAllineate 													\
  		-prefix ./resp_pestica5.nii 									\
  		-source $PESTICA_VOL_DIR/resp_mean_mni_PESTICA5.brain.nii 	\
  		-base epi_00_brain+orig 									\
  		-1Dmatrix_apply mni.coreg.1D 								\
  		-overwrite													
  
  	3dAllineate 													\
  		-prefix ./card_pestica5.nii 									\
  		-source $PESTICA_VOL_DIR/card_mean_mni_PESTICA5.brain.nii 	\
  		-base epi_00_brain+orig 									\
  		-1Dmatrix_apply mni.coreg.1D 								\
  		-overwrite													

 	# run PESTICA
  	matlab -nodesktop -nosplash -r "addpath $MATLAB_AFNI_DIR; addpath $MATLAB_PESTICA_DIR; disp('Wait, script starting...'); [card,resp]=apply_PESTICA(15,'epi_01_errts+orig','epi_base_mask+orig'); fp=fopen('card_raw_pestica5.dat','w'); fprintf(fp,'%g\n',card); fclose(fp); fp=fopen('resp_raw_pestica5.dat','w'); fprintf(fp,'%g\n',resp); fclose(fp); disp('Stage 2 Done!'); exit;" 
	
  	echo "Running Stage 3: Filtering PESTICA estimators, cardiac first, then respiratory" |& tee -a ../$histfile
  	matlab -nodesktop -nosplash -r "addpath $MATLAB_PESTICA_DIR; addpath $MATLAB_AFNI_DIR; load('card_raw_pestica5.dat'); load('resp_raw_pestica5.dat'); disp('Wait, script starting...'); card=view_and_correct_estimator(card_raw_pestica5,'epi_00+orig','c',$batchflag); resp=view_and_correct_estimator(resp_raw_pestica5,'epi_00+orig','r',$batchflag);  fp=fopen('card_pestica5.dat','w'); fprintf(fp,'%g\n',card); fclose(fp); fp=fopen('resp_pestica5.dat','w'); fprintf(fp,'%g\n',resp); fclose(fp); disp('Stage 3 Done!'); exit;" 

	echo "Running Stage 4: Running MATLAB-version of RETROICOR with physiological noise fluctuation" |& tee -a ../$histfile
  	matlab -nodesktop -nosplash -r "addpath $MATLAB_PESTICA_DIR; addpath $MATLAB_AFNI_DIR; retroicor_pestica('epi_01_errts+orig','card_pestica5.dat','resp_pestica5.dat','epi_base_mask+orig','rm.polort_xmat.1D'); disp('Stage 4 done!'); exit;" 

endif


if ( $physiofile == "" ) then
    set iname  = epi_01_errts.retroicor_pestica.bucket
    set snamec = Coupling_retroicor_pestica_Card
    set snamer = Coupling_retroicor_pestica_Resp
    
else
    set iname  = epi_01_errts.retroicor_pmu.bucket
    set snamec = Coupling_retroicor_pmu_Card
    set snamer = Coupling_retroicor_pmu_Resp
    
endif
  
if ( -f $iname+orig.HEAD ) then

    echo "" 
    echo "Running Stage 5: Make QA maps" |& tee -a ../$histfile
    echo "" 
    echo " **********************************************" 
    echo " **********************************************" 
    echo " AFNI IS ABOUT TO STEAL WINDOW FOCUS "
    echo " wait til this script ends in a few seconds " 
    echo " it will end at same time as last AFNI ends "
    echo " **********************************************"
    echo " **********************************************"
    
    # change this if the plots always give a poor view of the slices - slice 20 in AFNI is reasonable for most acquisitions
    set dims = `3dAttribute DATASET_DIMENSIONS epi_00+orig`
    set zdim = ${dims[3]}
    set zpos = `echo "scale=0; $zdim/2" | bc`

    if ( $zdim  > 72 ) then
      set montstr = "6x6"
    else if ( $zdim > 50 ) then
      set montstr = "5x5"
    else if ( $zdim > 32 ) then
      set montstr = "4x4"
    else
      set montstr = "3x3"
    endif
      
    set fname = `basename epi_00_brain`
    echo $fname
    # threshold for cardiac/respiratory coupling is ideally detected from the data itself, but may have to be adjusted manually
    afni -com "OPEN_WINDOW A.axialimage mont="$montstr":2:0:none opacity=6" 		\
         -com "SET_UNDERLAY A.$fname+orig.HEAD"       								\
         -com 'SET_XHAIRS A.OFF' 													\
         -com "SET_OVERLAY A.$iname+orig.HEAD 1 1"  								\
         -com "SET_THRESHNEW A 0.01 *p" 											\
         -com 'SET_PBAR_NUMBER A.12'        										\
         -com 'SET_FUNC_RANGE A.10' 												\
         -com "SAVE_JPEG A.axialimage $snamer" 										\
         -com "SET_OVERLAY A.$iname+orig.HEAD 2 2"  								\
         -com "SET_THRESHNEW A 0.01 *p" 											\
         -com 'SET_PBAR_NUMBER A.12'        										\
         -com 'SET_FUNC_RANGE A.10' 												\
         -com "SAVE_JPEG A.axialimage $snamec"  									\
         -com 'QUIT' 																

else
    echo SKIP Step5 $iname+orig.BRIK does not exist. |& tee -a ../$histfile
endif
  
  
# move out of wdir to the odir
cd ..
set whereout = $PWD

# copy the final result
echo "++ saving physiologic noise corrected EPI dataset as $prefix " |& tee -a $histfile
if ( $physiofile == "" ) then
	3dcopy 	"${owdir}"/epi_01_errts.retroicor_pestica+orig	\
			./"${prefix}" 									\
			-overwrite 		
	echo "++ however, you might not need $prefix file but $owdir/RetroTS.PESTICA5.slibase.1D " |& tee -a $histfile								
else
	3dcopy 	"${owdir}"/epi_01_errts.retroicor_pmu+orig 		\
			./"${prefix}" 									\
			-overwrite 
	echo "++ however, you might not need $prefix file but $owdir/RetroTS.PMU.slibase.1D " |& tee -a $histfile										
endif
echo "++ Physio nuisance regressors are recommended to remove out with motion nuisance regressors " |& tee -a $histfile		
echo "++ all together after motion correction " |& tee -a $histfile
echo "++ Check run_slomoco/volmoco.tcsh in SLOMOCO package "		|& tee -a $histfile	

if ( $DO_CLEAN == 1 ) then
    echo "++ Removing the large size of temporary files in working dir: '$wdirn" |& tee -a $histfile
    echo "++ DO NOT DELETE working directory. " |& tee -a $histfile
    echo "++ Generated physio nuisance regressors are used with motion nuisance. " |& tee -a $histfile
    echo "++ Removing the large size of temporary files in working dir: '$wdirn" |& tee -a $histfile
    
  	rm -f 	"${owdir}"/epi_00+orig.* 		\
  			"${owdir}"/epi_01_errts+orig.* 	
    
endif

echo ""
echo "++ DONE.  View the finished, axialized product:" |& tee -a $histfile
echo "     $whereout"
echo ""

goto GOOD_EXIT

# ========================================================================
# ========================================================================

SHOW_HELP:
cat << EOF
-------------------------------------------------------------------------

PESETICA: physsiologoc noise esitmator using temporal ICA

run_pestica.tcsh [option] 

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
 -dset_mask			 = skull stripped mask 
 -physio		 	 = pmu file prefix for RETROICOR (NOT PESTICA)  
 -workdir  directory = intermediate output data will be generated in the defined directory.
 -do_clean           = this option will delete the large size of files in working directory 

EOF

# ----------------------------------------------------------------------

    goto GOOD_EXIT

SHOW_VERSION:
   echo "version  $version (${rev_dat})"
   goto GOOD_EXIT

FAIL_MISSING_ARG:
    echo "** ERROR: Missing an argument after option flag: '$argv[$ac]'"
    goto BAD_EXIT

BAD_EXIT:
    exit 1

GOOD_EXIT:
    exit 0
