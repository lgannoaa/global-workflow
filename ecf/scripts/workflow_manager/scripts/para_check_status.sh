#!/bin/ksh
set +x

source $EXPDIR/config.base

#Script control variables
CHECK_ERR=${CHECK_ERR:-NO}
CHECK_HPSS1=${CHECK_HPSS1:-NO}
CHECK_HPSS2=${CHECK_HPSS2:-YES}
CHECK_QUOTA=${CHECK_QUOTA:-YES}
CHECK_FCST_POST=${CHECK_FCST_POST:-NO}
CHECK_NCO=${CHECK_NCO:-NO}
CHECK_GFS_MOS=${CHECK_GFS_MOS:-NO}

export DATAMAIL=$STMP/${PSLOT}${CDATE}check
export TMPDIR=$DATAMAIL
if [ ! -d $DATAMAIL ]; then mkdir $DATAMAIL; fi

cd $DATAMAIL
ln -s ${HOMEgfs}/ecf/scripts/workflow_manager/scripts/perl
ln -s ${HOMEgfs}/ecf/scripts/workflow_manager/scripts/lfs
ln -s ${HOMEgfs}/ecf/scripts/workflow_manager/scripts/mailx
ln -s ${HOMEgfs}/ecf/scripts/workflow_manager/scripts/qstat
echo `date`
echo "GROUP EMC usage for PTMP is -" `perl /apps/local/scripts/lsquota|grep ptmp|awk '{print $2"%"}'`
echo "GROUP EMC usage for STMP is -" `perl /apps/local/scripts/lsquota|grep stmp|awk '{print $2"%"}'`
echo "User $USER PTMP usage in TB is -" `lfs quota -u $USER /lfs/h2/emc/ptmp/|grep "0       -"|awk '{print $1/1073741824}'` "TB"
echo "Current job in running stat count is -" `qstat -u $USER -s -xu $USER |grep ' R '|wc -l`
echo ""

#Default empty warning message
warn=""

#Configure fit2obs file requirement
count_fits_max=60
count_fits_min=60
if [ $gfs_cyc -eq 1 ]; then
    count_fits_max=35
    count_fits_min=10
fi

# Define local variables
export ARCDIR=${ARCDIR:-$NOSCRUB/archive/$PSLOT}
export COMROT=${ROTDIR:-$PTMP/$LOGNAME/pr$PSLOT}
export NDATE=${NDATE:-/apps/ops/prod/nco/core/prod_util.v2.0.12/exec/ndate}
export vsdbsave=${vsdbsave:-$NOSCRUB/archive/vsdb_data}
export metplusdir=${metplus:-$NOSCRUB/archive/metplus_data/by_VSDB}
export FIT_DIR=${FIT_DIR:-$ARCDIR/fits}
export VBACKUP_FITS=${VBACKUP_FITS:-0}
export PARA_CHECK_BACKUP=${PARA_CHECK_BACKUP:-72}
#export QSTAT=${QSTAT:-/opt/pbs/bin/qstat}
export QSTAT="qstat -f -u $USER -w"


# Lists for checking tarballs on HPSS
export PARA_CHECK_HPSS_LIST_ENKF=${PARA_CHECK_HPSS_LIST_ENKF:-"enkfgdas enkfgdas_grp01 enkfgdas_grp02 enkfgdas_grp03 enkfgdas_grp04 enkfgdas_grp05 enkfgdas_grp06 enkfgdas_grp07 enkfgdas_grp08"}
export PARA_CHECK_HPSS_LIST_ENKF_RESTARTA=${PARA_CHECK_HPSS_LIST_ENKF_RESTARTA:-"enkfgdas_restarta_grp01 enkfgdas_restarta_grp02 enkfgdas_restarta_grp03 enkfgdas_restarta_grp04 enkfgdas_restarta_grp05 enkfgdas_r
estarta_grp06 enkfgdas_restarta_grp07 enkfgdas_restarta_grp08"}
export PARA_CHECK_HPSS_LIST_ENKF_RESTARTB=${PARA_CHECK_HPSS_LIST_ENKF_RESTARTB:-"enkfgdas_restartb_grp01 enkfgdas_restartb_grp02 enkfgdas_restartb_grp03 enkfgdas_restartb_grp04 enkfgdas_restartb_grp05 enkfgdas_r
estartb_grp06 enkfgdas_restartb_grp07 enkfgdas_restartb_grp08"}
export PARA_CHECK_HPSS_LIST_GDAS=${PARA_CHECK_HPSS_LIST_GDAS:-"gdas gdas_restarta gdas_restartb"}
export PARA_CHECK_HPSS_LIST_GFS=${PARA_CHECK_HPSS_LIST_GFS:-"gfs_flux gfs_${OUTPUT_FILE}a gfs_${OUTPUT_FILE}b gfs_restarta gfsa gfsb"}

#export DATAMAIL=$STMP/${PSLOT}${CDATE}check
#export TMPDIR=$DATAMAIL
#if [ ! -d $DATAMAIL ]; then mkdir $DATAMAIL; fi

# Back up PARA_CHECK_BACKUP from CDATE.
export BDATE=`$NDATE -${PARA_CHECK_BACKUP} $CDATE`
#export BHDATE=`$NDATE -${PARA_CHECK_BACKUP} $HDATE`
#export BDATE_HPSS=`$NDATE -0 $HDATE`
export BHDATE=`$NDATE -${PARA_CHECK_BACKUP} $CDATE`
export BDATE_HPSS=`$NDATE -0 $CDATE`
export EDATE=$CDATE
export EDATE_FIT=`$NDATE -${VBACKUP_FITS:-00} $EDATE`

# Check $COMROT/logs for most recent fit2obs log file.  get cdate for this log file
#### cd $ROTDIR/logs
cd $PBS_O_WORKDIR
COUNT_FITLOGS=`ls -lt FITS* | wc -l`
if [ $COUNT_FITLOGS -gt 0 ]; then
    CDATE_FIT_LOG=`ls -1t FITS* | head -1 | awk 'BEGIN { FS = "." } ; { print $3 }'`
    if [[ "$CDATE_FIT_LOG" -lt "$EDATE_FIT" ]]; then
        EDATE_FIT=$CDATE_FIT_LOG
    fi
fi

# Check if any fit2obs jobs running
# CDATE_FIT_RUN=`/u/emc.glopara/bin/qjob |grep $PSLOT |grep FITS |cut -d"." -f3 |cut -c1-10`

# Get subset of CDATE
day=`expr $CDATE | cut -c1-8`
cyc=`expr $CDATE | cut -c9-10`

# Check parallel status
#echo "Check $PSLOT for $BDATE to $EDATE at `date`"
echo "Check $PSLOT for $EDATE at `date`"

echo " "
echo "-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-"
echo " Check metplus grid2grid"
echo "--------------------------------"
cd $metplusdir/grid2grid/anom/00Z/$PSLOT
pwd
echo " "
ls -l | tail -5

echo " "
echo "-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-"
echo " Check metplus grid2obs"
echo "--------------------------------"
cd $metplusdir/grid2obs/upper_air/00Z/$PSLOT
pwd
echo " "
ls -l | tail -5

echo " "
echo "-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-"
echo " Check metplus precip"
echo "--------------------------------"
cd $metplusdir/precip/ccpa_accum24hr/00Z/$PSLOT
pwd
echo " "
ls -l | tail -5


if [ $COUNT_FITLOGS -gt 0 ]; then
  echo " "
  echo "-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-"
  echo " Check fits"
  echo "--------------------------------"
  cd $FIT_DIR
  pwd
  echo " "
  date=$BDATE
  while [[ $date -le $EDATE_FIT ]]; do
     count=`ls *${date}* |wc -l`
     warn=" "
     cyc=$(echo $date | cut -c9-10)
     if [ $gfs_cyc -eq 4 ]; then
         count_fits=$count_fits_max
     elif [ $gfs_cyc -eq 1 ]; then
         if [ $cyc -eq "00" -o $cyc -eq "12" ]; then
             count_fits=$count_fits_max
         else
             count_fits=$count_fits_min
         fi
     fi
     if [ $count -lt $count_fits ]; then warn="**** LOW COUNT WARNING ****"; fi
     string=" "
##   if [ $date -eq $CDATE_FIT_RUN ]; then string=" *** JOB RUNNING ***"; fi
     echo "$date $count $warn $string"
     ADATE=`$NDATE +06 $date`
     date=$ADATE
  done
fi

echo " "
echo "-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-"
echo " Check ARCDIR"
echo "--------------------------------"
cd $ARCDIR
pwd
echo " "
if [ -f $TMPDIR/temp.disk ]; then rm -rf $TMPDIR/temp.disk; fi
ls > $TMPDIR/temp.disk
date=$BHDATE
while [[ $date -le $CDATE ]]; do
   echo "$date `grep $date $TMPDIR/temp.disk | wc -l`"
   ADATE=`$NDATE +06 $date`
   date=$ADATE
done

if [ $CHECK_HPSS1 = YES ]; then
 echo " "
 echo "Check HPSS jobs"
 cd $COMROT
 date=$BDATE_HPSS
 while [ $date -le $EDATE ] ; do
   for file in `ls *${date}*ARC*dayfile`; do
      count=`grep "HTAR: HTAR FAIL" $file | wc -l`
      if [ $count -gt 0 ]; then
         echo `grep "HTAR: HTAR FAIL" $file` $file
      else
         count=`grep "HTAR: HTAR SUCC" $file | wc -l`
         if [ $count -gt 0 ]; then
# check on htar verification
            count_vy=`grep "HTAR: Verify complete" $file | wc -l`
            if [ $count_vy -gt 0 ]; then
              rate=`grep "MB/s"  $file |awk '{print "HPSS transfer rate:", $20, $21}'`
              echo `grep "HTAR: HTAR SUCC" $file` $file " verified $rate"
            else
              echo "HTAR FAILED to verify $file"
            fi
         else
            count=`grep "defined signal" $file | wc -l`
            if [ $count -gt 0 ]; then
               echo `grep "HTAR: HTAR signal FAIL" $file` $file
            else
               echo "$file RUNNING"
            fi
         fi
      fi
   done
   adate=`$NDATE +06 $date`
   date=$adate
 done
fi

if [ $CHECK_HPSS2 = YES ]; then
    CDATE_HPSS=$BDATE_HPSS
    hcyc=$(echo $CDATE_HPSS | cut -c9-10)
    mm=`echo $CDATE_HPSS|cut -c 5-6`
    dd=`echo $CDATE_HPSS|cut -c 7-8`
    nday=$(( (mm-1)*30+dd ))
    nday_b=$(( (mm-1)*30+dd+1 ))
    mod=$(($nday % $ARCH_WARMICFREQ))
    mod_b=$(($nday_b % $ARCH_WARMICFREQ))

    echo " "
    echo "-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-"
    echo " Check ATARDIR"
    echo "--------------------------------"
    if [ $HPSSARCH = YES ]; then
        mkdir -p $TMPDIR
        rm -f $TMPDIR/temp.hpss
        echo "$ATARDIR/$CDATE_HPSS"
        echo "------------------------------------------------------------------------"
        hsi -P "ls -l ${ATARDIR}/${CDATE_HPSS}" > $TMPDIR/temp.hpss
        for type in $PARA_CHECK_HPSS_LIST_ENKF; do
            grep "$type.tar" $TMPDIR/temp.hpss
            rc=$?
            if [ $rc != 0 ]; then echo "****** WARNING: $type for $CDATE_HPSS is missing! ******"; fi
        done
        echo " "
        if [[ $mod -eq "0" ]]; then
            if [[ $hcyc -eq "00" ]]; then
                PARA_CHECK_HPSS_LIST_ENKF_RESTART=$PARA_CHECK_HPSS_LIST_ENKF_RESTARTA
            else # enkf restart only available at 00 and 18Z
                PARA_CHECK_HPSS_LIST_ENKF_RESTART=""
            fi
            for type in $PARA_CHECK_HPSS_LIST_ENKF_RESTART; do
                grep "$type.tar" $TMPDIR/temp.hpss
                rc=$?
                if [ $rc != 0 ]; then echo "****** WARNING: $type for $CDATE_HPSS is missing! ******"; fi
            done
            echo " "
        fi

        if [[ $mod_b -eq "0" ]]; then
            if [[ $hcyc -eq "18" ]]; then
                PARA_CHECK_HPSS_LIST_ENKF_RESTART=$PARA_CHECK_HPSS_LIST_ENKF_RESTARTB
            else # enkf restart only available at 00 and 18Z
                PARA_CHECK_HPSS_LIST_ENKF_RESTART=""
            fi
            for type in $PARA_CHECK_HPSS_LIST_ENKF_RESTART; do
                grep "$type.tar" $TMPDIR/temp.hpss
                rc=$?
                if [ $rc != 0 ]; then echo "****** WARNING: $type for $CDATE_HPSS is missing! ******"; fi
            done
            echo " "
        fi
        for type in $PARA_CHECK_HPSS_LIST_GDAS; do
            grep "$type.tar" $TMPDIR/temp.hpss | grep -v enkf
            rc=$?
            if [ $rc != 0 ]; then echo "****** WARNING: $type for $CDATE_HPSS is missing! ******"; fi
        done
        CHECK_GFS=NO
        if [ $gfs_cyc = 4 ] ; then
            CHECK_GFS=YES
        elif [ $gfs_cyc = 2 ] ; then
            if [[ $hcyc -eq "00" || $hcyc -eq "12" ]]; then
                CHECK_GFS=YES
            fi
        elif [ $gfs_cyc = 1 ]; then
            if [[ $hcyc -eq "00" ]]; then
                CHECK_GFS=YES
            fi
        fi
        if [ $CHECK_GFS = YES ] ; then
            echo " "
            for type in $PARA_CHECK_HPSS_LIST_GFS; do
                grep "$type.tar" $TMPDIR/temp.hpss
                rc=$?
                if [ $rc != 0 ]; then echo "****** WARNING: $type for $CDATE_HPSS is missing! ******"; fi
            done
            echo " "
        fi
    else
        echo " "
        echo "HPSSARCH= $HPSSARCH  Nothing to check."
        echo " "
    fi
fi

rm -rf $TMPDIR

exit

