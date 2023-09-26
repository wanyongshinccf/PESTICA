# edit the hard-coded base directory containing the matlab code and the averaged volumes
#export PESTICA_DIR=/tools/pestica_afni_v5.5    # set the one you use pestica5.5 
#export PESTICA_DIR=/mnt/netScratch/wyshin/SWdevelopment/pestica_afni_v5.5/   
export PESTICA_DIR=/Users/wanyongshin/SWdevelopment/pestica_afni_v5.5/   

# no need to modify the below
export PESTICA_VOL_DIR=$PESTICA_DIR/template
export MATLAB_AFNI_DIR=$PESTICA_DIR/afni_matlab
export MATLAB_PESTICA_DIR=$PESTICA_DIR/pestica_matlab
export MATLAB_EEGLAB_DIR=$PESTICA_DIR/eeglab
export DYLD_LIBRARY_PATH=/opt/X11/lib/flat_namespace
export PATH=$PESTICA_DIR:$PATH

# if running AFNI in MacOS; MacOS version is needed to be complied and added here. 
#export AFNI_PESTICA_DIR=$PESTICA_DIR/afni_mac                                       

# set this to the number of processors/cores you're willing to give to PESTICA at the same time
# bash
#export PESTICA_MATLAB_POOLSIZE=4
# tcsh
#setenv PESTICA_MATLAB_POOLSIZE 4

# default code is to take all but one - reserve one core for non-PESTICA work, otherwise comment these lines out and set it above
#a=`cat /proc/cpuinfo  | grep processor | nl | tail -n 1 | gawk '{print $1}'`
#a=`expr $a \- 1`
#export PESTICA_MATLAB_POOLSIZE=$a

# add anything you need to add to the matlab command line here
# this first line seeds the random number generator by a function of the current time
#export MATLABLINE='-nojvm -nosplash -r "c=clock; c=c(3:6); c=round(10*sum(reshape(c(randperm(4)), 2, 2))); normrnd(0,1,c); clear c;"'
# this is if you need a custom matlab license file (use the snippets you need)
#export MATLABLINE="-nojvm -nosplash -c /etc/matlab_license.dat"
#export MATLABLINE="-nojvm -nosplash"
# for recent versions (e.g. R2015a definitely needs this), switch -nojvm to -nodesktop, as you need java to use matlab's Handle Graphics functionality
export MATLABLINE="-nodesktop -nosplash "





