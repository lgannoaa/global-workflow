#!/bin/sh

#### This is a driver script to generate METplus stats offline, 
####   depending on what date you want to generate stat files you'll change "STAT_DATE" in this file
set -x

export PSLOT=retro1-v16-ecf
export EXPDIR=/lfs/h2/emc/global/noscrub/lin.gan/git/gfsda.v16.3.0/parm/config

export HOMEgfs=/lfs/h2/emc/global/noscrub/lin.gan/para/packages/gfs.v16.3.0
export HOMEverif_global=$HOMEgfs/sorc/verif-global.fd
runvrfysh=$HOMEgfs/ecf/scripts/workflow_manager/scripts/run_verif_global.sh

#### Modify here if you only need to rerun a list of jobs
vlist="GRID2GRID GRID2OBS PRECIP"
cd $HOMEgfs/ecf/scripts/workflow_manager/scripts
export STAT_DATE=`cat offline_metplus.dt`
#export STAT_DATE=20211210

for vtype in $vlist; do
    export OUTPUTROOT=/lfs/h2/emc/stmp/${USER}/RUNDIRS/${PSLOT}/verif_global_standalone_stats_${vtype}.$$
    RUN_GRID2GRID_STEP1=NO
    RUN_GRID2OBS_STEP1=NO
    RUN_PRECIP_STEP1=NO
    if [ "$vtype" = "GRID2GRID" ]; then
	export RUN_GRID2GRID_STEP1=YES
    elif [ "$vtype" = "GRID2OBS" ]; then
	export RUN_GRID2OBS_STEP1=YES
    elif [ "$vtype" = "PRECIP" ]; then
	export RUN_PRECIP_STEP1=YES
    fi
    $runvrfysh $HOMEgfs/ecf/scripts/workflow_manager/scripts/config.vrfy.offline.stats

done
