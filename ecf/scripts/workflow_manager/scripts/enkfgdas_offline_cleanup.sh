#!/bin/ksh -x

export RUN_ENVIR=${RUN_ENVIR:-"nco"}
export PS4='$SECONDS + '
date


#############################
# Source relevant config files
#############################
export CDATE=${CDATE:-${PDY}${cyc}}
PDY=$(echo $CDATE | cut -c1-8)
cyc=$(echo $CDATE | cut -c9-10)

export EXPDIR=${EXPDIR:-$HOMEgfs/parm/config}
configs="base earc"
config_path=${EXPDIR:-$NWROOT/gfs.${gfs_ver}/parm/config}
for config in $configs; do
    . $config_path/config.$config
    status=$?
    [[ $status -ne 0 ]] && exit $status
done


##############################################
# Obtain unique process id (pid) and make temp directory
##############################################
export pid=${pid:-$$}
export outid=${outid:-"LL$job"}

export DATA=${DATA:-${DATAROOT}/${jobid:?}}
mkdir -p $DATA
cd $DATA


##############################################
# Run setpdy and initialize PDY variables
##############################################
export cycle="t${cyc}z"
setpdy.sh
. ./PDY


##############################################
# Determine Job Output Name on System
##############################################
export pgmout="OUTPUT.${pid}"
export pgmerr=errfile


##############################################
# Set variables used in the script
##############################################
export CDATE=${CDATE:-${PDY}${cyc}}
export CDUMP=${CDUMP:-${RUN:-"gfs"}}
export COMPONENT=${COMPONENT:-atmos}
n=$((ENSGRP))

##############################################
# Begin JOB SPECIFIC work
##############################################

# EnKF update in GFS, GDAS or both
CDUMP_ENKF=$(echo ${EUPD_CYC:-"gdas"} | tr a-z A-Z)
cd $ROTDIR

if [[ "${DELETE_COM_IN_ARCHIVE_JOB:-YES}" == NO ]] ; then
    exit 0
fi

###############################################################
# ENSGRP 0 also does clean-up
ENSGRP=0
if [ $ENSGRP -eq 0 ]; then

    # Start start and end dates to remove
    GDATEEND=$($NDATE -${RMOLDEND_ENKF:-24}  $CDATE)
    GDATE=$($NDATE -${RMOLDSTD_ENKF:-120} $CDATE)
    while [ $GDATE -le $GDATEEND ]; do

        gPDY=$(echo $GDATE | cut -c1-8)
        gcyc=$(echo $GDATE | cut -c9-10)

        # Loop over GDAS and GFS EnKF directories separately.
        clist="gdas gfs"
        for ctype in $clist; do
            COMIN_ENS="$ROTDIR/enkf$ctype.$gPDY/$gcyc/$COMPONENT"
            if [ -d $COMIN_ENS ]; then
                rocotolog="$EXPDIR/logs/${GDATE}.log"
                if [ -f $rocotolog ]; then
                    testend=$(tail -n 1 $rocotolog | grep "This cycle should be removed")
                    rc=$?
                    if [ $rc -eq 0 ]; then
                        # Retain f006.ens files.  Remove everything else
                        for file in `ls $COMIN_ENS | grep -v f006.ens`; do
                            rm -rf $COMIN_ENS/$file
                        done
                    fi
                fi
            fi

            # Remove empty directories
            if [ -d $COMIN_ENS ] ; then
                [[ ! "$(ls -A $COMIN_ENS)" ]] && rm -rf $COMIN_ENS
            fi
        done

        # Advance to next cycle
        GDATE=$($NDATE +$assim_freq $GDATE)

    done

fi

# Remove enkf*.$rPDY for the older of GDATE or RDATE
GDATE=$($NDATE -${RMOLDSTD_ENKF:-120} $CDATE)
fhmax=$FHMAX_GFS
RDATE=$($NDATE -$fhmax $CDATE)
if [ $GDATE -lt $RDATE ]; then
    RDATE=$GDATE
fi
rPDY=$(echo $RDATE | cut -c1-8)
clist="gdas gfs"
for ctype in $clist; do
    COMIN="$ROTDIR/enkf$ctype.$rPDY"
    [[ -d $COMIN ]] && rm -rf $COMIN
done

echo "ENDED NORMALLY."

##########################################
# Remove the Temporary working directory
##########################################
cd $DATAROOT
[[ $KEEPDATA = "NO" ]] && rm -rf $DATA

date
exit 0

