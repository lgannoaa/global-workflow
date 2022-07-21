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
configs="base arch"
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
#export CDATE=${CDATE:-${PDY}${cyc}}
#PDY=$(echo $CDATE | cut -c1-8)
#cyc=$(echo $CDATE | cut -c9-10)
export CDUMP=${CDUMP:-${RUN:-"gfs"}}
export COMPONENT=${COMPONENT:-atmos}


##############################################
# Begin JOB SPECIFIC work
##############################################
COMIN_OBS=${COMIN_OBS:-$(compath.py prod/obsproc/${obsproc_ver})/$RUN.$PDY/$cyc/atmos}
#COMIN=${COMIN:-$ROTDIR/$RUN.$PDY/$cyc/atmos}
#cd $COMIN

# CURRENT CYCLE
APREFIX="${CDUMP}.t${cyc}z."
ASUFFIX=${ASUFFIX:-$SUFFIX}

if [ $ASUFFIX = ".nc" ]; then
   format="netcdf"
else
   format="nemsio"
fi

###############################################################
# Clean up previous cycles; various depths
# PRIOR CYCLE: Leave the prior cycle alone
# Required input: CDATE
###############################################################

# GDATE=$($NDATE -$assim_freq $CDATE)

# PREVIOUS to the PRIOR CYCLE
GDATE=$($NDATE -$assim_freq $GDATE)
gPDY=$(echo $GDATE | cut -c1-8)
gcyc=$(echo $GDATE | cut -c9-10)

# Remove the TMPDIR directory
COMIN="$RUNDIR/$GDATE"
[[ -d $COMIN ]] && rm -rf $COMIN

if [[ "${DELETE_COM_IN_ARCHIVE_JOB:-YES}" == NO ]] ; then
    exit 0
fi

###############################################################
# Step back every assim_freq hours and remove old rotating directories
# for successful cycles (defaults from 24h to 120h).  If GLDAS is
# active, retain files needed by GLDAS update.  Independent of GLDAS,
# retain files needed by Fit2Obs
DO_GLDAS=${DO_GLDAS:-"NO"}
GDATEEND=$($NDATE -${RMOLDEND:-24}  $CDATE)
GDATE=$($NDATE -${RMOLDSTD:-120} $CDATE)
GLDAS_DATE=$($NDATE -96 $CDATE)
RTOFS_DATE=$($NDATE -48 $CDATE)
while [ $GDATE -le $GDATEEND ]; do
    gPDY=$(echo $GDATE | cut -c1-8)
    gcyc=$(echo $GDATE | cut -c9-10)
    COMIN="$ROTDIR/${CDUMP}.$gPDY/$gcyc/atmos"
    COMINwave="$ROTDIR/${CDUMP}.$gPDY/$gcyc/wave"
    COMINrtofs="$ROTDIR/rtofs.$gPDY"
    if [ -d $COMIN ]; then
        rocotolog="$EXPDIR/logs/${GDATE}.log"
        if [ -f $rocotolog ]; then
            testend=$(tail -n 1 $rocotolog | grep "This cycle is complete: Success")
            rc=$?
            if [ $rc -eq 0 ]; then
                if [ -d $COMINwave ]; then rm -rf $COMINwave ; fi
                if [ -d $COMINrtofs -a $GDATE -lt $RTOFS_DATE ]; then rm -rf $COMINrtofs ; fi
                if [ $CDUMP != "gdas" -o $DO_GLDAS = "NO" -o $GDATE -lt $GLDAS_DATE ]; then
                    if [ $CDUMP = "gdas" ]; then
                        for file in `ls $COMIN |grep -v prepbufr |grep -v cnvstat |grep -v atmanl.nc`; do
                            rm -rf $COMIN/$file
                        done
                    else
                        rm -rf $COMIN
                    fi
                else
                    if [ $DO_GLDAS = "YES" ]; then
                        for file in `ls $COMIN |grep -v sflux |grep -v RESTART |grep -v prepbufr |grep -v cnvstat |grep -v atmanl.nc`; do
                            rm -rf $COMIN/$file
                        done
                        for file in `ls $COMIN/RESTART |grep -v sfcanl `; do
                            rm -rf $COMIN/RESTART/$file
                        done
                    else
                        for file in `ls $COMIN |grep -v prepbufr |grep -v cnvstat |grep -v atmanl.nc`; do
                            rm -rf $COMIN/$file
                        done
                    fi
                fi
            fi
        fi
    fi
    # Remove any empty directories
    if [ -d $COMIN ]; then
        [[ ! "$(ls -A $COMIN)" ]] && rm -rf $COMIN
    fi
    if [ -d $COMINwave ]; then
        [[ ! "$(ls -A $COMINwave)" ]] && rm -rf $COMINwave
    fi

    GDATE=$($NDATE +$assim_freq $GDATE)
done
# Remove archived gaussian files used for Fit2Obs in $VFYARC that are
# $FHMAX_FITS plus a delta before $CDATE.  Touch existing archived
# gaussian files to prevent the files from being removed by automatic
# scrubber present on some machines.
VFYARC=${VFYARC:-$ROTDIR/vrfyarch}
if [ $CDUMP = "gfs" ]; then
    fhmax=$((FHMAX_FITS+36))
    RDATE=$($NDATE -$fhmax $CDATE)
    rPDY=$(echo $RDATE | cut -c1-8)
    COMIN="$VFYARC/$CDUMP.$rPDY"
    [[ -d $COMIN ]] && rm -rf $COMIN

    TDATE=$($NDATE -$FHMAX_FITS $CDATE)
    while [ $TDATE -lt $CDATE ]; do
        tPDY=$(echo $TDATE | cut -c1-8)
        tcyc=$(echo $TDATE | cut -c9-10)
        TDIR=$VFYARC/$CDUMP.$tPDY/$tcyc
        [[ -d $TDIR ]] && touch $TDIR/*
        TDATE=$($NDATE +6 $TDATE)
    done
fi

# Remove $CDUMP.$rPDY for the older of GDATE or RDATE
GDATE=$($NDATE -${RMOLDSTD:-120} $CDATE)
fhmax=$FHMAX_GFS
RDATE=$($NDATE -$fhmax $CDATE)
if [ $GDATE -lt $RDATE ]; then
    RDATE=$GDATE
fi
rPDY=$(echo $RDATE | cut -c1-8)
COMIN="$ROTDIR/$CDUMP.$rPDY"
[[ -d $COMIN ]] && rm -rf $COMIN

echo "ENDED NORMALLY."

##########################################
# Remove the Temporary working directory
##########################################
cd $DATAROOT
[[ $KEEPDATA = "NO" ]] && rm -rf $DATA

date
exit 0

