#! /bin/bash

function Usage () {
  cat <<EOF
  PESTICA_v5.5
  PESTICA is an open source software package, running on bash window. Please feel free to modify it. 
  If you use PESTICA in your work, please cite

  Shin W, Koenig KA, Lowe MJ. A comprehensive investigation of physiologic noise modeling in resting state fMRI; time shifted cardiac noise in EPI and its removal without external physiologic signal measures. Neuroimage. 2022 Jul 1;254:119136. doi: 10.1016/j.neuroimage.2022.119136. Epub 2022 Mar 26. PMID: 35346840.

  Beall, E. B., and Lowe, M. J. (2014). SimPACE: Generating simulated motion corrupted BOLD data with synthetic-navigated acquisition for the development and evaluation of SLOMOCO: a new, highly effective slicewise motion correction. NeuroImage 101, 21–34. doi: 10.1016/j.neuroimage.2014.06.038
 
  PESTICA software requires Matlab & AFNI installation
  PESTICA generates 4 cardiac and 1 respiratory regressors and AFNI stat file (bucket)
    to show where/how the estimated physiologic regressors are correlated to
  You could regress out the generatated physiologic regressors with 3d volreg motion parameters 
    as AFNI pipeline suggests (see output file) while we suggest applying slicewise motion correction 
    and their regression-out using SLOMOCO (Beall & Lowe 2014)
  PESTICA package also provides RETROICOR (Glover et al, 2000) tool, generating various output file.(See readme.txt) 

  === General information of PESTICA ===
  PESTICA is a software to estimate physiologic noise regressor in the imaging domain. 
  PESTICIA employs slicewise ICA, selects cardiac and respiratory components in each slice,
    and concatenates them to high sampling rate (N slices / TR, > 10Hz) physiologic components.  
  In this reason, 3D acquisition, e.g. 3D single shot/segmented EPI does not work with PESTICA
    due to the poor temporal (slice wise) resolution
  ASL does not work with PESTICA since images are collected during tagging period (>1s). 
  
  DO NOT apply SLICE TIMING SHIFT CORRECTION, e.g. 3dTshift, BEFORE PESTICA
  
  Slice acquisition timing file is required.
    The default is Single band Siemens' alternative ascending slice acquisition. 
    No input is required. genSMStimeshiftfile.m will generate the following based on total slice number
      In case of odd total slice number,  e.g. 31: 1-3-5-...-31-2-4-6-...-30
      In case of even total slice number, e.g. 30: 2-4-6-...-30-1-3-5-...-31
    We provides Siemens Multiband alternative ascending acquisition timing info with "-m" option  
      In case of MB factor 5 & total 30 slices: (2,8,14,20,26)-(4,10,16,22,28)-...
      In case of MB factor 6 & total 30 slices: (1,6,11,16,21,26)-(3,8,13,18,23,28)-...
      run_pestica.sh -d XXX -m <MB acceleration factor>
    In case of other than SB and MB Siemens' alternative ascending acquisition, 
      tshiftfile_sec.1D file should be provided in the directory of input file
      The simple way is to type your acquisition timing as a column in sec unit. 
      Also, you can modify genSMStimeshiftfile.m
  

  == output files ==
  The following output files will be generated under "PESTICA5" directory
    <input>.brain+orig
      : skull-stripped image, used as a mask
    <input>.retroicor_pestica+orig
	: EPI data set after removing the estimated physiologic noise 
    <input>.retroicor_pestica.bucket+orig
	: Statistical result of the estimated physiologic noise fitting (see retroicor_pestica.m)
    tshiftfile_sec.1D
    	: slice acquisition timing shift file. If the file exists in input file directory, it will be copied 
    card/resp_raw_PESTICA5.dat
        : concatenated cardiac/respiratory noise signals from each slice (sampling rate = (Slices/MB)/TR)
    card/resp_PESTICA5.dat
        : temporal filtered card/resp_raw_PESTICA5.dat (see PESTICA step 3)
    RetroTS.PESTICA5.mat
	: CARD.phz_slc_reg (4 regressros) and RESP.slc_reg (1 regressor) are used for regression 
        : 5 regresors are saved in 1d file for AFNI pipeline (see the below)
    RetroTS.PESTICA5.slibase.1D
        : AFNI pipeline compatible 1D regressor

    If RETROICOR is used, the following output files will be generated under "PHYSIO" directory
      <input>.brain+orig (see the above)
      tshiftfile_sec.1D (see the above)
      <input>.retroicor_PMU+orig
	: EPI data set after removing physiologic noise and detrending using RETROICOR
        : Note that tissue contrast is still there.
      <input>.retroicor_PMU.bucket+orig
	: Statistical result of the estimated physiologic noise fitting (see retroicor_pmu.m)
      RetroTS.PMU.slicebase.1D 
        : slicewise regressor file, used in AFNI pipe line. 

  5. Quality assurance output
  
    If PESTICA is used, the following image files will be generated.
    Coupling_retroicor_pestica_Card/Resp.png
    	: colored areas indicates the significant regressed out area with the cardiac and 
          respiratory noise model (p<0.01). 
          you can generate the same result using <input>.retroicor_pestica.bucket+orig
          (see PESTICA/PMU step 5)

    If PMU is used, the following image files will be generated.
    Coupling_retroicor_pestica_Card/Resp.png (see the above)
    pmu_qualtiycheck.png
 	: see the description of PESTICA_HRFcheck.png above
    pmu_M2_HRFcheck.png
	: (1st column)the coefficient of the first harmonic Fourier Series of noise model
          the circular and anitostropic distributions are expected for the cardiac and respiratory
          noise fitting. Otherwise, something bad, e.g. bad time synchronizing between EPI and PMU,
          head motion, bad qaulity of PMU data... see the paper (Shin, Koening & Lowe)
          (2nd to 4th coluns) hemodynamic phase function within the measured (defined) phases.
          2nd phase function is expected to be the large error with a strange banding pattern
          3rd phase function is expected to be the small error after the polarity correction.
          Otherwise, PMU data might be corrupted. 

    We suggested not to use PMU data with 
         SD of the cardiac and respiratory response function > 0.6
         COV of the cardiac periodic cycle     > 0.2
	 COV of the respiratory periodic cycle > 0.3
         It is recommended to run PESTICA if PMU data is not collected properly 
           (number varys upon the study. See Shin and Lowe, 2018 ISMRM abstract #2876)
  
  Additional comments

  === RETROICOR correction in PESTICA ===
  Note that PMU correction (with -p option) is RETROICOR, NOT PESTICA. 
  We have used and provided matlab based RETROICOR process in PESTICA for our own research purpose. 
  Our RETROICOR generates physiological noise resfunse function result (pmu_M2_HRFcheck.png) and 
  correlation maps (Coupling_retroicor_pmu_Card(RESP).png) with cardiac or respiratory signals. 
  However, it takes some time to run it through. If you do not need them, you can set fastpmucorflag=1, 
  then, RETROICOR process suggested in afni_proc.py, e.g. 3dREMLfit, 3dSynthesize will be called.

  === Usage help ===
  Usage:  run_pestica.sh -d <epi_filename> -m <MB acceleration here (default = 1)>
 	     -d=dataset: <epi_filename> is the file prefix of EPI data
                Note: this script will detect suffix
	     -m=MB acceleration factor
                if MB acceleration factor is not provided, single band is assumed.

  Opt :  run_pestica.sh -d <epi_filename> -b
             -b=Auto selection mode: turns off interactive popup at stage 3
             Frequency pass filter (bpm); [48 85] in card & [10 24] for resp

  Opt :  run_pestica.sh -d <epi_filename> -e <mask_filename>
             You can use own non-skull brain image. Then skull striping is skipped.
             Your mask brain image is copied/renamed to <epi_filenmae>.brain and used.

  Opt :  run_pestica.sh -d <epi_filename> -s "1 2"
	     -s=stages: Run stages, from 1-5.  Allows you to run or re-run parts
	     of PESTICA. Give the stages (in increasing order) that you want to
             run. Otherwise, this script will run all stages in order
         stage 1: ICA decomposition
         stage 2: template coregistration and estimation)
         stage 3: cardiac and respiratory phase function regressor frequency pass filtering
         stage 4: Regress-out with 5 physio-regressors with polynomial detrending regressors
         stage 5: QA

  Opt :  run_pestica.sh -d <epi_filename>  -f N
         In case that input data includes unsaturated signals, the first N volume will
         be truncated and used as an input, e.g. <input> -> <input>.trunc<N>
         This will generated the exact same output when you run with the first N volume 
         truncated input file, e.g.
         3dcalc -a <epi_filename>+orig[N..$] -expr 'a' -prefix <epi_filename>.trunc<N>
         run_pestica.sh -d <epi_filename>.trunc<N>

         if you have un-equilibrated volumes at the start, you have to remove them 
         before running PESTICA. Most scanners take "dummy" volumes, where the ADCs are 
         turned off but the RF and gradients are running as normal, for the first ~3 seconds 
         (modulo TR), but in some scanners this is not so and you can see contrast change 
         from the 1st to few volumes. Also SMS (MB) acquisition has the single band reference
         scan as the first parts, which has the effective TR of actual TR x MB factor. 
         
         Since PESTICA runs temporal ICA, un-equilibrated signals generate bias on estimated PMU

         You can test first volumes for spin saturation with: 
           3dToutcount <epi_filename> | 1dplot -stdin -one
         Is the first volume much higher than rest? If so, you may need to remove first 
         several volumes first. If you don't know what this means, consult someone who does know, 
         this is very important, regression corrections (and analyses) perform poorly 
         when the data has unsaturated volumes at the start

         The recommendation for SB acquisition 
         3T TR>2s:  the first 4 volumes to be removed.
         3T TR ~<1s the first 6 volumes 
         7T TR>2s:  the first 6 volumes 
         7T TR ~<1s the first 8 volumes   

  Opt :  run_pestica.sh -d <epi_filename>  -p <physiofile>
         PESTICA provides RETROICOR tools, mainly inserting "RetroTS.m" file, found in AFNI website
         (However, it is not accessed recently. Please claim the credit!!)
         Also, CMRR physio reading file, readCMRRPhysio.m (E. Auerbach, CMRR, 2015)is used to read HCP physio-data
         In addition, Catie Chang (Vanderbilt)'s RVHR code are snipped to retroicor_pmu.m file. - optional
         Output file includes the bucket file to shows F maps of cardiac and respiratory models 
         as well as physiologic noise corrected (regressed out) data.


EOF
  exit 1
}

nVolEndCutOff=0;   # no EPI volumes at the end were truncated as default
nVolFirstCutOff=0; # truncate the first few points, which is mendatory for PESTICA
MBfactor=1 	   # 
maskflag=0
epi_mask=0
fastpmucorflag=0;
  
allstagesflag=1; batchflag=0; pmuflag=0;  pesticaflag=0; stagepmu1234flag=0;
stage1flag=0; stage2flag=0; stage3flag=0; stage4flag=0; stage5flag=0; 
while getopts hd:p:bt:u:f:s:m:e: opt; do
  case $opt in
    h)
       Usage
       exit 1
       ;;
    d) # base 3D+time EPI dataset to use to perform all ICA decomposition and alignment
       epi=$OPTARG
       ;;
    u) # unsaturated EPI image, usually Scout_gdc.nii.gz
       unsatepi=$OPTARG
      ;;
    s) # option to run stages manually
       allstagesflag=0
       stages=$OPTARG
       # loop over numbers listed
       for i in $stages ; do
         if [ $i -eq 1 ] ; then
           stage1flag=1
	 elif [ $i -eq 2 ] ; then
           stage2flag=1
	 elif [ $i -eq 3 ] ; then
           stage3flag=1
	 elif [ $i -eq 4 ] ; then
           stage4flag=1
	 elif [ $i -eq 5 ] ; then
           stage5flag=1
	 else
	   echo "incorrect syntax for stages input: $i"
	   Usage
	   exit 1
	 fi
       done
      ;;
    b) # flag for batch mode (non-interactive)
       batchflag=1
       ;;
    p) # load monitored pulse ox and respiratory bellows from Siemens PMU system
       pmufileprefix=$OPTARG
       pmuflag=1
       ;;
    f) # the number of volumes truncted at the first of the EPI acquisitions
       nVolFirstCutOff=$OPTARG
       ;;
    t) # the number of volumes truncted at the end of the EPI acquisitions
       nVolEndCutOff=$OPTARG
       echo nVolEndCutOff=$nVolEndCutOff
       ;;
    m) # mb factor
       MBfactor=$OPTARG
       ;;
    e) # mask
       epi_mask=$OPTARG
       maskflag=1
       ;;
    :)
      echo "option requires input"
      exit 1
      ;;
  esac
done

if [ $pmuflag -eq 1 ]; then
  if [ $allstagesflag -eq 1 ] ; then
    stagepmu1234flag=1; stage5flag=1; 
  else
    stagepmu1234flag=0;
  fi
else
  pesticaflag=1;
  if [ $allstagesflag -eq 1 ] ; then
    stage1flag=1; stage2flag=1; stage3flag=1; stage4flag=1; stage5flag=1; 
  fi
fi

# define variables
pesticav=PESTICA5
if [ $pesticaflag -eq 1 ]; then
  epi_physio="${pesticav}"
else # if defined pmuflag
  epi_physio=PHYSIO
fi

fullcommand="$0"
PESTICA_DIR=`dirname $fullcommand`

# first test if we are running run_pestica.sh from the base PESTICA_DIR
homedir=`pwd`
if [ $homedir == $PESTICA_DIR ] ; then
  echo "you cannot run PESTICA from the downloaded/extracted PESTICA_DIR"
  echo "please run this from the directory containing the data (or copy of the data)"
  echo "that you want to correct.  Exiting..."
  exit 1
fi

# remove "." if the input file name ends with "." 
nstr=$((${#epi}-1))
if [ "${epi:$nstr:1}" = "." ]; then
  epi=${epi:0:$nstr}
fi

# test for presence of input EPI file with one of the accepted formats and set suffix
epinosuffix=${epi%.*}
suffix="${epi##*.}"
if [ "$suffix" = "hdr" ] || [ "$suffix" = "nii" ]; then
  epi=$epinosuffix
  suffix=.$suffix
elif [ "$suffix" = "gz" ]; then
  epi=$epinosuffix
  epinosuffix=${epi%.*}
  suffix2="${epi##*.}"
  suffix=.$suffix2.$suffix
  epi=$epinosuffix
elif [ "$suffix" = "HEAD" ]; then
  nstr=$((${#str}-9))
  epi_org=${epi:$nstr:4}
  if [ $epi_org == tlrc ]; then
    echo "PESTICA needs original EPI data set as input, not Talarigh or MNI space data"
    exit 2 
  fi
  epi=${epinosuffix%+orig}
  suffix="+orig.HEAD"
else  # when input file is given without postfix
  if [ -f $epi.hdr ] ; then
    suffix=".hdr"
  elif [ -f $epi.HEAD ] ; then
    epi=${epi%+orig}
    suffix="+orig.HEAD"
  elif [ -f $epi+orig.HEAD ] ; then
    suffix="+orig.HEAD"
  elif [ -f $epi+tlrc.HEAD ] ; then
    echo "PESTICA needs original EPI data set as input, not Talarigh or MNI space data"
    exit 2 
  elif [ -f $epi.nii ] ; then
    suffix=".nii"
  elif [ -f $epi.nii.gz ] ; then
    suffix=".nii.gz"
  else  
    echo "3D+time EPI dataset $epi must exist, check filename "
    echo "accepted formats: hdr  +orig  nii  nii.gz"
    echo "accepted inputs: with/without <.hdr>, <.HEAD>, <+orig.HEAD>, <nii> or <nii.gz>"
    echo ""
    echo "*****   $epi does not exist, exiting ..."
    exit 2
  fi
fi

# generate directory
if [ ! -d $epi_physio ] ; then
  echo "* Creating Directory: $epi_physio"
  mkdir $epi_physio
  echo "mkdir $epi_physio" >> $epi_physio/physiocor_history.txt
  echo "" >> $epi_physio/physiocor_history.txt
fi

# write command line and PESTICA_DIR to history file
echo "`date`" >> $epi_physio/physiocor_history.txt
#echo "`svn info $PESTICA_DIR/run_pestica.sh |grep URL`" >> $epi_physio/physiocor_history.txt
#echo "`svn info $PESTICA_DIR/run_pestica.sh |grep Rev`" >> $epi_physio/physiocor_history.txt
echo "PESTICA_v5.5 command line: `basename $fullcommand` $*" >> $epi_physio/physiocor_history.txt
echo "PESTICA env:
`env | grep PESTICA`" >> $epi_physio/physiocor_history.txt
echo "" >> $epi_physio/physiocor_history.txt

cd $epi_physio
echo "cd $epi_physio" >> physiocor_history.txt
echo "" >> physiocor_history.txt

echo "*****   Using $epi+orig.HEAD as input timeseries"
if [ $nVolFirstCutOff -gt 0 ]; then
  if [ ! -f $epi.trunc"${nVolFirstCutOff}"+orig.BRIK ]; then
    echo "Removing the first "${nVolFirstCutOff}" volumes"
    echo 3dcalc -a ../$epi$suffix["${nVolFirstCutOff}"..$] -expr 'a' -prefix $epi.trunc"${nVolFirstCutOff}"+orig 
    echo 3dcalc -a ../$epi$suffix["${nVolFirstCutOff}"..$] -expr 'a' -prefix $epi.trunc"${nVolFirstCutOff}"+orig >> physiocor_history.txt
         3dcalc -a ../$epi$suffix["${nVolFirstCutOff}"..$] -expr 'a' -prefix $epi.trunc"${nVolFirstCutOff}"+orig
    epi=$epi.trunc"${nVolFirstCutOff}"
  fi
else
  if [ ! -f $epi+orig.BRIK ]; then
    echo "Copying: 3dcopy ../$epi$suffix $epi+orig"
    echo "3dcopy ../$epi$suffix $epi+orig"  >> physiocor_history.txt
          3dcopy ../$epi$suffix $epi+orig
  fi
fi

# generate slice time shift info file
if [ -f ../tshiftfile.1D ]; then
  echo "Slice acqusition timing information is read from a tshiftfile.1D file"
  echo cp ../tshiftfile.1D .
       cp ../tshiftfile.1D . >> physiocor_history.txt
       cp ../tshiftfile.1D .
elif [ -f ../tshiftfile_sec.1D ]; then
  echo "Slice acqusition timing information is read from a tshiftfile_sec.1D file"
  echo 1dtranspose ../tshiftfile_sec.1D tshiftfile.1D
       1dtranspose ../tshiftfile_sec.1D tshiftfile.1D >> physiocor_history.txt
       1dtranspose ../tshiftfile_sec.1D tshiftfile.1D
else
  echo "tshiftfile_sec.1D is not provided."
  echo "tshiftfile_sec.1D is not provided." >> physiocor_history.txt
  echo "tshiftfile.1D will be generated with MB = $MBfactor"
  echo "tshiftfile.1D will be generated with MB = $MBfactor" >> physiocor_history.txt
  
  echo "Note that new PESTICA needs MB factor as an input"
  if [ $MBfactor -eq 1 ]; then
    echo "Alternative ascending acquisition order of single band EPI is assumed."
  else
    echo "Alternative ascending acquisition order of multi band EPI is assumed." 
  fi
  echo "If any other acquisition than alternative ascending (alt+z) is used, modify genSMStimeshiftfile.m or its input."

  echo matlab $MATLABLINE <<<"addpath $MATLAB_PESTICA_DIR; addpath $MATLAB_AFNI_DIR; [err,Info] = BrikInfo('$epi+orig'); genSMStimeshiftfile($MBfactor, Info.DATASET_DIMENSIONS(3),Info.TAXIS_FLOATS(2),'alt+z'); exit;" 
  echo matlab $MATLABLINE <<<"addpath $MATLAB_PESTICA_DIR; addpath $MATLAB_AFNI_DIR; [err,Info] = BrikInfo('$epi+orig'); genSMStimeshiftfile($MBfactor, Info.DATASET_DIMENSIONS(3),Info.TAXIS_FLOATS(2),'alt+z'); exit;" >> physiocor_history.txt
       matlab $MATLABLINE <<<"addpath $MATLAB_PESTICA_DIR; addpath $MATLAB_AFNI_DIR; [err,Info] = BrikInfo('$epi+orig'); genSMStimeshiftfile($MBfactor, Info.DATASET_DIMENSIONS(3),Info.TAXIS_FLOATS(2),'alt+z'); exit;" 
  1dtranspose tshiftfile_sec.1D tshiftfile.1D -overwrite
fi
echo "The following slice acquisition timing shift is used."
echo "The following slice acquisition timing shift is used." >> physiocor_history.txt
cat tshiftfile.1D 
cat tshiftfile.1D  >> physiocor_history.txt
echo "If this shift is not correct, PESTICA will not work."
echo "If this shift is not correct, PESTICA will not work." >> physiocor_history.txt

# import or generate a mask file
if [ $maskflag -gt 0 ]; then
  # remove .
  nstr=$((${#epi_mask}-1))
  if [ "${epi_mask:$nstr:1}" = "." ]; then
    epi_mask=${epi_mask:0:$nstr}
  fi
  if [ -f ../$epi_mask.HEAD ] || [ -f ../$epi_mask ]; then
    echo "copy brain mask" 
    echo 3dcalc -a ../$epi_mask -expr 'a' -prefix $epi.brain+orig 
    echo 3dcalc -a ../$epi_mask -expr 'a' -prefix $epi.brain+orig  >> physiocor_history.txt
         3dcalc -a ../$epi_mask -expr 'a' -prefix $epi.brain+orig 
    epi_mask=$epi.brain
  else
    echo "Error: Cannot find manual mask"
    exit 2
  fi
else
  epi_mask="$epi".brain
  if [ -f $epi_mask+orig.HEAD ] ; then 
    echo SKIP: $epi_mask+orig.HEAD exists.
  else
    if [ -f ../$epi_mask$suffix ] ; then
      echo 3dcopy ../$epi_mask$suffix "$epi".brain+orig
      echo 3dcopy ../$epi_mask$suffix "$epi".brain+orig >> physiocor_history.txt
           3dcopy ../$epi_mask$suffix "$epi".brain+orig 
    else
      echo ""
      echo "*****   $epi_mask+orig.HEAD does not exist, creating mask"
      echo "note, if you wish to use your own mask/brain file, kill this script"
      echo "then generate your own mask file and use -e option"
      echo ""
      echo "running 3dSkullStrip -input  $epi+orig -prefix $epi_mask"
      echo "3dSkullStrip -input $epi+orig -prefix ___tmp_mask" >> physiocor_history.txt
            3dSkullStrip -input $epi+orig -prefix ___tmp_mask

      # dilate mask by one voxel
      3dcalc -a ___tmp_mask+orig -prefix ___tmp_mask_ones+orig -expr 'step(a)'
      3dcalc -a ___tmp_mask_ones+orig -prefix ___tmp_mask_ones_dil -b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'
      3dcalc -a "$epi+orig[0]" -b ___tmp_mask_ones_dil+orig -prefix $epi_mask -expr 'a*step(b)'
      rm ___tmp_mask*
      echo ""
      echo "done with skull-stripping - please check file and if not satisfied, I recommend running"
      echo "3dSkullStrip with different parameters to attempt to get a satisfactory brain mask."
      echo "Either way, this script looks in $epi_physio/ for $epi_mask to use as your brain mask/strip"
      sleep 1
      echo "3dcalc -a ___tmp_mask+orig -prefix ___tmp_mask_ones+orig -expr 'step(a)'" >> physiocor_history.txt
      echo "3dcalc -a ___tmp_mask_ones+orig -prefix ___tmp_mask_ones_dil -b a+i -c a-i -d a+j -e a-j -f a+k -g a-k -expr 'amongst(1,a,b,c,d,e,f,g)'" >> physiocor_history.txt
      echo "3dcalc -a "$epi+orig[0]" -b ___tmp_mask_ones_dil+orig -prefix $epi_mask -expr 'a*step(b)'" >> physiocor_history.txt
      echo "rm ___tmp_mask*" >> physiocor_history.txt
      echo "" >> physiocor_history.txt
    fi
  fi
fi
echo "*****   Using $epi_mask+orig.HEAD to mask out non-brain voxels"
echo "*****   Using $epi+orig.HEAD as input timeseries"

# always copy input file into PESTICA subdirectory in AFNI format
3dDeconvolve -polort A -input $epi+orig -x1D_stop -x1D $epi.polort.xmat.1D -overwrite
1dcat $epi.polort.xmat.1D > rm.$epi.polort.xmat.1D 

### Optional PMU data formatting
if [ $stagepmu1234flag -eq 1 ] ; then   
  echo "Using files with prefix: $pmufileprefix"
  pmufileprefix="../$pmufileprefix"
  # convert PhysioLog files into usable data
  
  # read a PhysioLog file 
  echo "matlab $MATLABLINE disp('Starting script...'); addpath $MATLAB_PESTICA_DIR; addpath $MATLAB_AFNI_DIR; addpath $MATLAB_EEGLAB_DIR; rw_pmu_siemens('$epi+orig','$pmufileprefix',$nVolEndCutOff); [SN RESP CARD] = RetroTS_CCF_adv('$epi+orig','card_raw_pmu.dat','resp_raw_pmu.dat'); exit;"
  echo "matlab $MATLABLINE disp('Starting script...'); addpath $MATLAB_PESTICA_DIR; addpath $MATLAB_AFNI_DIR; addpath $MATLAB_EEGLAB_DIR; rw_pmu_siemens('$epi+orig','$pmufileprefix',$nVolEndCutOff); [SN RESP CARD] = RetroTS_CCF_adv('$epi+orig','card_raw_pmu.dat','resp_raw_pmu.dat'); exit;"  >> physiocor_history.txt
    matlab $MATLABLINE <<<"disp('Starting script...'); addpath $MATLAB_PESTICA_DIR; addpath $MATLAB_AFNI_DIR; addpath $MATLAB_EEGLAB_DIR; rw_pmu_siemens('$epi+orig','$pmufileprefix',$nVolEndCutOff); [SN RESP CARD] = RetroTS_CCF_adv('$epi+orig','card_raw_pmu.dat','resp_raw_pmu.dat'); exit;" 

  if [ $fastpmucorflag -eq 1 ]; then
    3dDetrend -polort 1 -prefix rm.ricor.1D RetroTS.PMU.slibase.1D\'
    1dtranspose rm.ricor.1D ricor_det.1D
    3dREMLfit -input $epi+orig -matrix $epi.polort.xmat.1D -mask $epi_mask+orig \
          -Obeta $epi.polort.betas -Oerrts $epi.polort.errts.retroicor_pmu  -slibase_sm ricor_det.1D

    3dSynthesize -matrix $epi.polort.xmat.1D -cbucket $epi.polort.betas+orig -select polort -prefix temp+orig -overwrite
    3dcalc -a temp+orig -b $epi.polort.errts.retroicor_pmu+orig -expr 'a+b' -prefix $epi.retroicor_pmu+orig -overwrite

    rm temp+orig* rm.*

  else
    echo "Matlab version of RETROICOR is running now."
    echo "It provides PMU quality assurance and RETRROICOR fitting results."
    echo "If you do not need them, set fastpmucorflag to 1 in run_pestica.sh."
    echo "matlab $MATLABLINE disp('Starting script...'); addpath $MATLAB_PESTICA_DIR; addpath $MATLAB_AFNI_DIR; addpath $MATLAB_EEGLAB_DIR; load RetroTS.PMU.mat; [RESP CARD] = retroicor_pmu('$epi+orig','$epi_mask+orig',SN, CARD, RESP,'rm.$epi.polort.xmat.1D'); exit;" 
    echo "matlab $MATLABLINE disp('Starting script...'); addpath $MATLAB_PESTICA_DIR; addpath $MATLAB_AFNI_DIR; addpath $MATLAB_EEGLAB_DIR; load RetroTS.PMU.mat; [RESP CARD] = retroicor_pmu('$epi+orig','$epi_mask+orig',SN, CARD, RESP,'rm.$epi.polort.xmat.1D'); exit;" >> physiocor_history.txt
    matlab $MATLABLINE <<<"disp('Starting script...'); addpath $MATLAB_PESTICA_DIR; addpath $MATLAB_AFNI_DIR; addpath $MATLAB_EEGLAB_DIR; load RetroTS.PMU.mat; [RESP CARD] = retroicor_pmu('$epi+orig','$epi_mask+orig',SN, CARD, RESP,'rm.$epi.polort.xmat.1D'); exit;" 
  fi
  if [ "$AFNI_COMPRESSOR" = "GZIP" ]; then
    if [ -f $epi_mask+orig.BRIK ]; then
      echo gzip $epi_mask+orig.BRIK
      echo gzip $epi_mask+orig.BRIK >> physiocor_history.txt
	   gzip $epi_mask+orig.BRIK -f
    fi
    if [ -f $epi.retroicor_pmu+orig.BRIK ]; then
      echo gzip $epi.retroicor_pmu+orig.BRIK
      echo gzip $epi.retroicor_pmu+orig.BRIK >> physiocor_history.txt
	   gzip $epi.retroicor_pmu+orig.BRIK -f
    fi
    if [ -f $epi.retroicor_pmu.bucket+orig.BRIK ]; then
      echo gzip $epi.retroicor_pmu.bucket+orig.BRIK
      echo gzip $epi.retroicor_pmu.bucket+orig.BRIK >> physiocor_history.txt
	   gzip $epi.retroicor_pmu.bucket+orig.BRIK -f
    fi   
    if [ -f $epi.retroicor_pmu.Cphz.bucket+orig.BRIK ]; then
      echo gzip $epi.retroicor_pmu.Cphz.bucket+orig.BRIK
      echo gzip $epi.retroicor_pmu.Cphz.bucket+orig.BRIK >> physiocor_history.txt
	   gzip $epi.retroicor_pmu.Cphz.bucket+orig.BRIK -f
    fi
  fi
fi
########### End PMU data correction ###########

########### Start STAGE 1 ###########
if [[ $stage1flag -eq 1 ]] ; then
  echo 3dREMLfit -input $epi+orig -matrix $epi.polort.xmat.1D -mask $epi_mask+orig -Oerrts $epi.polort.errts -overwrite
       3dREMLfit -input $epi+orig -matrix $epi.polort.xmat.1D -mask $epi_mask+orig -Oerrts $epi.polort.errts -overwrite

  echo ""
  echo "Running Stage 1: slicewise temporal Infomax ICA"
  echo ""
        # Use of <<< for MATLAB input was contributed by I. Schwabacher.
  echo "matlab $MATLABLINE addpath $MATLAB_AFNI_DIR; addpath $MATLAB_PESTICA_DIR; addpath $MATLAB_EEGLAB_DIR;disp('Wait, script starting...'); prepare_ICA_decomp_polort(15,'$epi.polort.errts+orig','$epi_mask+orig'); disp('Stage 1 Done!'); exit;"
  echo "matlab $MATLABLINE addpath $MATLAB_AFNI_DIR; addpath $MATLAB_PESTICA_DIR; addpath $MATLAB_EEGLAB_DIR;disp('Wait, script starting...'); prepare_ICA_decomp_polort(15,'$epi.polort.errts+orig','$epi_mask+orig'); disp('Stage 1 Done!'); exit;" >> physiocor_history.txt
    matlab $MATLABLINE <<<"addpath $MATLAB_AFNI_DIR; addpath $MATLAB_PESTICA_DIR; addpath $MATLAB_EEGLAB_DIR;disp('Wait, script starting...'); prepare_ICA_decomp_polort(15,'$epi.polort.errts+orig','$epi_mask+orig'); disp('Stage 1 Done!'); exit;"

  rm $epi.polort.errts+orig.* 

  if [ "$AFNI_COMPRESSOR" = "GZIP" ] ; then
    echo gzip $epi_mask+orig.BRIK
    echo gzip $epi_mask+orig.BRIK >> physiocor_history.txt
       	 gzip $epi_mask+orig.BRIK     
  fi
fi
########### End STAGE 1 ###########

########### Start STAGE 2 ###########
if [[ $stage2flag -eq 1 ]] ; then
  echo ""
  echo "Running Stage 2: Coregistration of EPI to MNI space and back-transform of templates, followed by PESTICA estimation"
  echo ""
  # EPI to MNI
  if [ ! -f mni.coreg.$epi_mask.1D ] ; then
    echo "Coregistration to EPI template"
    echo  3dAllineate -prefix ./$epi_mask.crg2mni.nii -source $epi_mask+orig -base $PESTICA_VOL_DIR/meanepi_mni.brain.nii -1Dmatrix_save $epi_mask.coreg.mni.1D -overwrite
    echo "3dAllineate -prefix ./$epi_mask.crg2mni.nii -source $epi_mask+orig -base $PESTICA_VOL_DIR/meanepi_mni.brain.nii -1Dmatrix_save $epi_mask.coreg.mni.1D -overwrite" >> physiocor_history.txt
          3dAllineate -prefix ./$epi_mask.crg2mni.nii -source $epi_mask+orig -base $PESTICA_VOL_DIR/meanepi_mni.brain.nii -1Dmatrix_save $epi_mask.coreg.mni.1D -overwrite
          cat_matvec $epi_mask.coreg.mni.1D -I -ONELINE > mni.coreg.$epi_mask.1D -overwrite
  fi

  # move PESTICA template mni to EPI space
  echo "3dAllineate -prefix ./resp_${pesticav}.nii -source $PESTICA_VOL_DIR/resp_mean_mni_${pesticav}.brain.nii -base $epi_mask+orig -1Dmatrix_apply mni.coreg.$epi_mask.1D -overwrite"
  echo "3dAllineate -prefix ./resp_${pesticav}.nii -source $PESTICA_VOL_DIR/resp_mean_mni_${pesticav}.brain.nii -base $epi_mask+orig -1Dmatrix_apply mni.coreg.$epi_mask.1D -overwrite" >> physiocor_history.txt
        3dAllineate -prefix ./resp_${pesticav}.nii -source $PESTICA_VOL_DIR/resp_mean_mni_${pesticav}.brain.nii -base $epi_mask+orig -1Dmatrix_apply mni.coreg.$epi_mask.1D -overwrite
  echo "3dAllineate -prefix ./card_${pesticav}.nii -source $PESTICA_VOL_DIR/card_mean_mni_${pesticav}.brain.nii -base $epi_mask+orig -1Dmatrix_apply mni.coreg.$epi_mask.1D -overwrite"
  echo "3dAllineate -prefix ./card_${pesticav}.nii -source $PESTICA_VOL_DIR/card_mean_mni_${pesticav}.brain.nii -base $epi_mask+orig -1Dmatrix_apply mni.coreg.$epi_mask.1D -overwrite" >> physiocor_history.txt
        3dAllineate -prefix ./card_${pesticav}.nii -source $PESTICA_VOL_DIR/card_mean_mni_${pesticav}.brain.nii -base $epi_mask+orig -1Dmatrix_apply mni.coreg.$epi_mask.1D -overwrite

  # run PESTICA
  echo "Obtaining PESTICA estimators"
  echo "matlab $MATLABLINE addpath $MATLAB_AFNI_DIR; addpath $MATLAB_PESTICA_DIR; [card,resp]=apply_PESTICA(15,'$epi+orig','$epi_mask+orig','${pesticav}'); fp=fopen('card_raw_${pesticav}.dat','w'); fprintf(fp,'%g\n',card); fclose(fp); fp=fopen('resp_raw_${pesticav}.dat','w'); fprintf(fp,'%g\n',resp); fclose(fp); exit"
  echo "matlab $MATLABLINE addpath $MATLAB_AFNI_DIR; addpath $MATLAB_PESTICA_DIR; [card,resp]=apply_PESTICA(15,'$epi+orig','$epi_mask+orig','${pesticav}'); fp=fopen('card_raw_${pesticav}.dat','w'); fprintf(fp,'%g\n',card); fclose(fp); fp=fopen('resp_raw_${pesticav}.dat','w'); fprintf(fp,'%g\n',resp); fclose(fp); exit" >> physiocor_history.txt
        matlab $MATLABLINE <<<"addpath $MATLAB_AFNI_DIR; addpath $MATLAB_PESTICA_DIR; disp('Wait, script starting...'); [card,resp]=apply_PESTICA(15,'$epi+orig','$epi_mask+orig','${pesticav}'); fp=fopen('card_raw_${pesticav}.dat','w'); fprintf(fp,'%g\n',card); fclose(fp); fp=fopen('resp_raw_${pesticav}.dat','w'); fprintf(fp,'%g\n',resp); fclose(fp); disp('Stage 2 Done!'); exit;"
  
  if [ "$AFNI_COMPRESSOR" = "GZIP" ]; then
    echo gzip $epi_mask+orig.BRIK
    echo gzip $epi_mask+orig.BRIK >> physiocor_history.txt
       	 gzip $epi_mask+orig.BRIK      
  fi
fi
########### End STAGE 2 ###########

########### Start STAGE 3 ###########
if [[ $stage3flag -eq 1 ]] ; then
  echo ""
  echo "Running Stage 3: Filtering PESTICA estimators, cardiac first, then respiratory"
  echo ""
  echo "NOTE: TR must be set correctly in header for 3D+time dataset - if in doubt, check it and correct it"
  echo "Values given below:"
  echo "matlab $MATLABLINE addpath $MATLAB_PESTICA_DIR; addpath $MATLAB_AFNI_DIR; load('card_raw_${pesticav}.dat'); load('resp_raw_${pesticav}.dat'); card=view_and_correct_estimator(card_raw_${pesticav},'$epi+orig','c',$batchflag); resp=view_and_correct_estimator(resp_raw_${pesticav},'$epi+orig','r',$batchflag); fp=fopen('card_${pesticav}.dat','w'); fprintf(fp,'%g\n',card); fclose(fp); fp=fopen('resp_${pesticav}.dat','w'); fprintf(fp,'%g\n',resp); fclose(fp); exit;"
  echo "matlab $MATLABLINE -r addpath $MATLAB_PESTICA_DIR; addpath $MATLAB_AFNI_DIR; load('card_raw_${pesticav}.dat'); load('resp_raw_${pesticav}.dat'); card=view_and_correct_estimator(card_raw_${pesticav},'$epi+orig','c',$batchflag); resp=view_and_correct_estimator(resp_raw_${pesticav},'$epi+orig','r',$batchflag); fp=fopen('card_${pesticav}.dat','w'); fprintf(fp,'%g\n',card); fclose(fp); fp=fopen('resp_${pesticav}.dat','w'); fprintf(fp,'%g\n',resp); fclose(fp); exit;" >> physiocor_history.txt
        matlab $MATLABLINE -r "addpath $MATLAB_PESTICA_DIR; addpath $MATLAB_AFNI_DIR; load('card_raw_${pesticav}.dat'); load('resp_raw_${pesticav}.dat'); disp('Wait, script starting...'); card=view_and_correct_estimator(card_raw_${pesticav},'$epi+orig','c',$batchflag); resp=view_and_correct_estimator(resp_raw_${pesticav},'$epi+orig','r',$batchflag);  fp=fopen('card_${pesticav}.dat','w'); fprintf(fp,'%g\n',card); fclose(fp); fp=fopen('resp_${pesticav}.dat','w'); fprintf(fp,'%g\n',resp); fclose(fp); disp('Stage 3 Done!'); exit;"
fi
########### End STAGE 3 ##########

########### Start STAGE 4 ###########
if [[ $stage4flag -eq 1 ]] ; then
  # PESTICA convert to phase using 3dretroicor
  echo "Running MATLAB-version of RETROICOR with physiological noise fluctuation"
  echo "matlab  $MATLABLINE addpath $MATLAB_PESTICA_DIR; addpath $MATLAB_AFNI_DIR; card = load('card_${pesticav}.dat'); resp = load('resp_${pesticav}.dat'); retroicor_pestica('$epi+orig',card,resp,'$epi_mask+orig','rm.$epi.polort.xmat.1D'); exit"
  echo "matlab  $MATLABLINE addpath $MATLAB_PESTICA_DIR; addpath $MATLAB_AFNI_DIR; card = load('card_${pesticav}.dat'); resp = load('resp_${pesticav}.dat'); retroicor_pestica('$epi+orig',card,resp,'$epi_mask+orig','rm.$epi.polort.xmat.1D'); exit" >> physiocor_history.txt
          matlab  $MATLABLINE <<<"addpath $MATLAB_PESTICA_DIR; addpath $MATLAB_AFNI_DIR; retroicor_pestica('$epi+orig','card_${pesticav}.dat','resp_${pesticav}.dat','$epi_mask+orig','rm.$epi.polort.xmat.1D'); disp('Stage 4 done!'); exit;"

  if [ "$AFNI_COMPRESSOR" = "GZIP" ]; then
    echo gzip $epi_mask+orig.BRIK
    echo gzip $epi_mask+orig.BRIK >> physiocor_history.txt
       	 gzip $epi_mask+orig.BRIK -f 
    echo gzip $epi.retroicor_pestica+orig.BRIK
    echo gzip $epi.retroicor_pestica+orig.BRIK >> physiocor_history.txt
       	 gzip $epi.retroicor_pestica+orig.BRIK -f
    echo gzip $epi.retroicor_pestica.bucket+orig.BRIK
    echo gzip $epi.retroicor_pestica.bucket+orig.BRIK >> physiocor_history.txt
         gzip $epi.retroicor_pestica.bucket+orig.BRIK -f 
  fi
fi

########### End STAGE 4 ###########

########### Start STAGE 5 ###########
if [[ $stage5flag -eq 1 ]] ; then
  if [ $pmuflag -eq 1 ] ; then
    iname=$epi.retroicor_pmu.bucket+orig
    snamec=Coupling_retroicor_pmu_Card
    snamer=Coupling_retroicor_pmu_Resp
  else
    iname=$epi.retroicor_pestica.bucket
    snamec=Coupling_retroicor_pestica_Card
    snamer=Coupling_retroicor_pestica_Resp
  fi
  
  if [ -f $iname+orig.HEAD ]; then

    echo ""
    echo "Running Stage 5: Make QA maps"
    echo ""

    echo " **********************************************"
    echo " **********************************************"
    echo " AFNI IS ABOUT TO STEAL WINDOW FOCUS!!"
    echo " wait til this script ends in a few seconds, "
    echo " it will end at same time as last AFNI ends"
    echo " **********************************************"
    echo " **********************************************"
    sleep 1

    # change this if the plots always give a poor view of the slices - slice 20 in AFNI is reasonable for most acquisitions
    dims=(`3dAttribute DATASET_DIMENSIONS $epi+orig`)
    zdim=${dims[2]}
    let "zpos=zdim/2"

    if [ $zdim -gt 72 ]; then
      montstr='6x6'
    elif [ $zdim -gt 50 ]; then
      montstr='5x5'
    elif [ $zdim -gt 32 ]; then
      montstr='4x4'
    else
      montstr='3x3'
    fi 

    fname=`basename $epi_mask`
    echo $fname
    # threshold for cardiac/respiratory coupling is ideally detected from the data itself, but may have to be adjusted manually
    afni -com "OPEN_WINDOW A.axialimage mont="$montstr":2:0:none opacity=6" \
         -com "SET_UNDERLAY A.$fname+orig.HEAD"       -com 'SET_XHAIRS A.OFF' \
         -com "SET_OVERLAY A.$iname+orig.HEAD 1 1"  -com "SET_THRESHNEW A 0.01 *p" \
         -com 'SET_PBAR_NUMBER A.12'        -com 'SET_FUNC_RANGE A.10' \
         -com "SAVE_JPEG A.axialimage $snamer" \
         -com "SET_OVERLAY A.$iname+orig.HEAD 2 2"  -com "SET_THRESHNEW A 0.01 *p" \
         -com 'SET_PBAR_NUMBER A.12'        -com 'SET_FUNC_RANGE A.10' \
         -com "SAVE_JPEG A.axialimage $snamec"  -com 'QUIT' >> afnilogfile.txt 2>&1
  else
    echo SKIP Step5 $iname+orig.BRIK does not exist. 
  fi 
fi

# remove copied EPI file inside PESTICA subdir, as we should be finished and don't need to take up the extra space
rm -f $epi+orig.BRIK* $epi+orig.HEAD 
echo "rm $epi+orig.???? (temp file removal inside $epi_pestica only)" >> physiocor_history.txt
echo "" >> physiocor_history.txt

cd $homedir
echo "End of PESTICA script" >> $epi_physio/physiocor_history.txt
echo "`date`" >> $epi_physio/physiocor_history.txt
echo "" >> $epi_physio/physiocor_history.txt

# Note from Isaac:
# This is necessary because MATLAB likes to break the terminal for some reason.
# but it's commented here because it doesn't like to run in the background.
#reset

