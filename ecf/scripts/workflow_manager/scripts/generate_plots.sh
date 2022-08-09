#!/bin/bash --login

set -x

. $MODULESHOME/init/bash  2>/dev/null

###############################################################
#
# SET KEY VARIABLES BELOW
#
#   PSLOT      : experiment name
#   NDAYS      : number of days to plot
#   EXPDIR     : experiment directory containing plotting scripts
#   VSDBPLOT   : set YES to generate vsdb plots, default NO
#   G2OPLOT    : set YES to generate g2o plots, default NO
#   METPLOT    : set YES to generate metplus plots, default NO
#
# ASSUMPTIONS:
#   - machine=WCOSS_D
#   - plotting jobs submitted to dev
#   - transfer jobs submitted to dev_transfer
#
# Update VSDBPLOTSH and METPLOTSH to toggle on/off specific plot types
#
###############################################################
# User defined variables below

export PSLOT="retro1-v16-ecf"

#### export EDATE_BACKUP=0
#export EDATE_BACKUP=48  #Requested by RUSS on 7/1/2021
export EDATE_BACKUP=24

#### export TIME_WINDOW_HOURS=48   # width of metplus MAPSDA time window
#export TIME_WINDOW_HOURS=72   #Requested by RUSS on 7/1/2021
export TIME_WINDOW_HOURS=96

export EXPDIR="/gpfs/dell2/emc/modeling/noscrub/$USER/para_fv3gfs/$PSLOT"

export VSDBPLOT=NO
export G2OPLOT=NO
export METPLOT=YES

# Set either fixed start date of plots, $SDATE, or
# set fixed number of days, $NDAYS, to plot
export SDATE=2021081600

export SDATE=${SDATE:-""}
export NDAYS=${NDAYS:-""}

###############################################################
#
# NOTE: Most scripting below does not need to be edited
#
###############################################################


###############################################################
# Set date range to process.
#  CDATE is 00Z of current date.
#  Verification runs on a time-delayed basis.  Back up
#  48 hours = 2 days from CDATE to get ending date, EDATE,
#  for plots.  Start plots NDAYS prior to EDATE

CDATE=`cat $COMROOTp3/date/t00z | cut -c7-16`
export EDATE=`$NDATE -${EDATE_BACKUP} $CDATE`

if [[ "$NDAYS" -gt "0" ]]; then
    NHOURS=$(expr $NDAYS \* 24)
    export SDATE=`$NDATE -${NHOURS} $EDATE`
fi


###############################################################
# Set derived variables

export PDYBEG=`echo $SDATE | cut -c1-8`
export PDYEND=`echo $EDATE | cut -c1-8`

echo "PDYBEG $PDYBEG"
echo "PDYEND $PDYEND"

if [[ "$SDATE" -gt "0" ]]; then
    DAYDIF=`~emc.glopara/bin/ndays.sh $PDYEND $PDYBEG`
    export NDAYS=$(expr $DAYDIF + 1)
fi


###############################################################
# Submit VSDB plotting jobs (MAKEMAPS, CONUSPLOTS, FIT2OBS, MAPS2D, MAPSGDAS)
if [ ${VSDBPLOT:-"NO"} = "YES" ]; then
    cd $EXPDIR/scripts
    VSDBPLOTSH=$EXPDIR/scripts/vsdbjob_submit_auto.sh
    $VSDBPLOTSH
    status=$?
    [[ $status -ne 0 ]] && exit $status
fi

###############################################################
# Submit G2OPLOTS plotting jobs
if [ ${G2OPLOT:-"NO"} = "YES" ]; then
    cd $EXPDIR/scripts
    G2OPLOTSH=$EXPDIR/scripts/grid2obs_driver_auto.sh
    $G2OPLOTSH
    status=$?
    [[ $status -ne 0 ]] && exit $status
fi

###############################################################
# Submit METPLUS plotting jobs
if [ ${METPLOT:-"NO"} = "YES" ]; then
    cd $EXPDIR/scripts
    METPLOTSH=$EXPDIR/scripts/metplus_submit_auto.sh
    $METPLOTSH
    status=$?
    [[ $status -ne 0 ]] && exit $status
fi

###############################################################
# Exit cleanly

exit 0
