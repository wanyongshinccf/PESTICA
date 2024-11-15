#!/bin/tcsh

#set version   = "0.0";  set rev_dat   = "Nov 13, 2024"
# + Regerssion with vol-/sli-/voxel-wise nuisance'
#
# ----------------------------------------------------------------

set this_prog_full = "run_regreout_nuisance.tcsh"
set this_prog = "adj_regout"
#set tpname    = "${this_prog:gas///}"
set here      = $PWD

# ----------------------- set defaults --------------------------

set prefix  = ""

set odir    = $here
set opref   = ""

set wdir    = ""

# --------------------- inputs --------------------

set epi      = ""   # base 3D+time EPI dataset to use to perform corrections
set epi_mask = ""   # mask 3D+time images
set epi_mean = ""   # mask 3D+time images
set volreg1D = ""
set slireg1D = ""
set voxpvreg = ""
set npolort  = "A"   # nth polynomial detrending or "A"      

set sliregstr = ""
set voxregstr = ""

set DO_CLEAN = 0    # default: keep working dir
set errts    = 0    # 0 (tissue contrast back) or 1 (the residual only) 

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

    # --------- required

    else if ( "$argv[$ac]" == "-dset_epi" ) then
        if ( $ac >= $#argv ) goto FAIL_MISSING_ARG
        @ ac += 1
        set epi = "$argv[$ac]"

    else if ( "$argv[$ac]" == "-dset_mask" ) then
        if ( $ac >= $#argv ) goto FAIL_MISSING_ARG
        @ ac += 1
        set epi_mask = "$argv[$ac]"

    else if ( "$argv[$ac]" == "-prefix" ) then
        if ( $ac >= $#argv ) goto FAIL_MISSING_ARG
        @ ac += 1
        set prefix = "$argv[$ac]"

    # --------- one of them required
    else if ( "$argv[$ac]" == "-volreg" ) then
        if ( $ac >= $#argv ) goto FAIL_MISSING_ARG
        @ ac += 1
        set volreg1D = "$argv[$ac]"

    else if ( "$argv[$ac]" == "-slireg" ) then
        if ( $ac >= $#argv ) goto FAIL_MISSING_ARG
        @ ac += 1
        set slireg1D = "$argv[$ac]"

    else if ( "$argv[$ac]" == "-voxreg" ) then
        if ( $ac >= $#argv ) goto FAIL_MISSING_ARG
        @ ac += 1
        set voxpvreg = "$argv[$ac]"

    # --------- opt

    else if ( "$argv[$ac]" == "-polort" ) then
        if ( $ac >= $#argv ) goto FAIL_MISSING_ARG
        @ ac += 1
        set npolort = "$argv[$ac]"

    else if ( "$argv[$ac]" == "-errts" ) then
        set errts     = 1

    else if ( "$argv[$ac]" == "-do_clean" ) then
        set DO_CLEAN     = 1
        
        
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

# ----- find AFNI 

# find AFNI binaries directory
set adir      = ""
which afni >& /dev/null
if ( ${status} ) then
    echo "** ERROR: Cannot find 'afni'"
    goto BAD_EXIT
else
    set aa   = `which afni`
    set adir = $aa:h
endif

# ----- in/output prefix
if ( "${epi}" == "" ) then
    echo "** ERROR: need to provide EPI dataset with '-dset_epi ..'"
    goto BAD_EXIT

endif

# ----- mask is required input
# new update - 3D+t mask improves the result better, required. (W.S)
if ( "${epi_mask}" == "" ) then
    echo "** ERROR: must input a mask with '-dset_mask ..'"
    goto BAD_EXIT

endif

# ----- prefix is required input
if ( "${prefix}" == "" ) then
    echo "** ERROR: must provide output name with '-prefix ..'"
    goto BAD_EXIT

endif

# =======================================================================
# =========================== ** Main work ** ===========================

cat <<EOF

++ Start main ${this_prog} work

EOF

# define PESTICA directory for python
set fullcommand = "$0"
set fullcommandlines = "$argv"
setenv PESTICA_DIR `dirname "${fullcommand}"`


# polynomial detrending matrix only
3dDeconvolve                    \
    -polort     $npolort        \
    -input      $epi 	        \
    -x1D_stop                   \
    -x1D        rm.polort.1D   \
    -overwrite

set volregstr = "-matrix rm.polort.1D "

# demean nuisance regressors
if ( $volreg1D != "" ) then 
    echo "++ volume-wise  regressors are prepared with detrending regressor(s). "
    1d_tool.py                  \
        -infile $volreg1D       \
        -demean                 \
        -write rm.mopa6.demean.1D  \
        -overwrite
    
    # volmopa includues the polinominal (linear) detrending 
    3dDeconvolve                                                            \
        -input  ${epi}                                                      \
        -mask   ${epi_mask}                                                 \
        -polort $npolort                                                    \
        -num_stimts 6                                                       \
        -stim_file 1 rm.mopa6.demean.1D'[0]' -stim_label 1 mopa1 -stim_base 1 	\
        -stim_file 2 rm.mopa6.demean.1D'[1]' -stim_label 2 mopa2 -stim_base 2 	\
        -stim_file 3 rm.mopa6.demean.1D'[2]' -stim_label 3 mopa3 -stim_base 3 	\
        -stim_file 4 rm.mopa6.demean.1D'[3]' -stim_label 4 mopa4 -stim_base 4 	\
        -stim_file 5 rm.mopa6.demean.1D'[4]' -stim_label 5 mopa5 -stim_base 5 	\
        -stim_file 6 rm.mopa6.demean.1D'[5]' -stim_label 6 mopa6 -stim_base 6 	\
        -x1D        rm.volreg.1D                                           \
        -x1D_stop                                                           \
  	    -overwrite

    # update 
    set volregstr = "-matrix rm.volreg.1D "
endif
  

# slicewise regressor includes zero vectors when in/out-of-plane motion
# is not trustable. Since slibase option does not support zero vector,
# zero vector is replaced with one vector.

# demean nuisance regressors
if ( $slireg1D != "" ) then
    echo "++ Sliwise regressors are prepared. "
    # demean first
    1d_tool.py                  \
        -infile $slireg1D       \
        -demean                 \
        -write rm.slireg.demean.1D  \
        -overwrite

    # replace zero vectors with linear one
    \rm -f rem.sliregslireg_zp.1D 
python $PESTICA_DIR/patch_zeros.py           \
        -infile rm.slireg.demean.1D \
        -write rm.slireg.1D  

    set sliregstr = "-slibase_sm rm.slireg.1D " 
endif

if ( $voxpvreg != "" ) then
    echo "++ Voxelwise regressor is defined. "
    set voxregstr = "-dsort ${voxpvreg}   " 
endif


# regress out all nuisances here
3dREMLfit               \
    -input  ${epi}      \
    -mask   ${epi_mask} \
    $volregstr          \
    $sliregstr          \
    $voxregstr          \
    -Oerrts rm.errts    \
    -GOFORIT            \
    -overwrite              

if ( $errts == 1 ) then
    3dcopy rm.errts+orig $prefix -overwrite

else
    # calculate mean
    3dTstat -mean -prefix rm.mean ${epi} -overwrite \

    # put the tissue contrast back to the residual signal  
    3dcalc                      \
        -a rm.errts+orig        \
        -b rm.mean+orig         \
        -c ${epi_mask}          \
        -expr '(a+b)*step(c)'   \
        -prefix $prefix         \
        -overwrite

endif

\rm -f rm.*


echo ""
echo "++ DONE.  Finished Nuisance regress-out:"
echo ""


goto GOOD_EXIT

# ========================================================================
# ========================================================================

SHOW_HELP:
cat << EOF
-------------------------------------------------------------------------

This adjuct_regout_nuisance.tcsh script is replaced with gen_regout.m
3dREMLfit runs with volume-/slice-/voxel-wise regressors.
Since slicewise regressor inclues zero vectors at a certain slice where
the measured slice motion is not trustable, the zero vector is replaced
with linear line vector. 3dMREMLfit complains the multiple identical 
vectors in slicewise regressors, which is ignored with "-GOFORIT" option.

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
