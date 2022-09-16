#!/bin/bash
set +x

#### This job is to check for offline archive jobs for:
####   zombie jobs: Job submitted by arch job but disappear from system queue
####   double jobs submition from system error: Hpss archive size double; same job run twice shown in log file
####   Silent failed jobs caused by system issue: Progress within a archive job stopped without any error
#### Input: CDATE
#### Processing: Using a DATA directory for temp file processing
#### Output: Echo message display as needed
#### Author: Lin Gan

CDATE=${1}

if [ $# -lt 1 ]; then
    echo '***ERROR*** must specify CDATE '
    echo ' Syntax: health_check_offline_archive.sh  ( 2022080112 )'
    exit 1
fi

qq="qstat -u ${USER} -s -xu ${USER}"
HOMEgfs=/lfs/h2/emc/global/noscrub/${USER}/para/packages/gfs.v16.3.0
EXPDIR=/lfs/h2/emc/global/noscrub/${USER}/para/packages/gfs.v16.3.0/parm/config
module load prod_util
. ${EXPDIR}/config.base
DATAROOT=/lfs/h2/emc/stmp/$USER/health_check_offline_archive
DATA=$DATAROOT/${CDATE}/$$
PDY=$(echo $CDATE | cut -c1-8)
cyc=$(echo $CDATE | cut -c9-10)
log_dir=/lfs/h2/emc/ptmp/${USER}/${PSLOT}/para/com/output/prod/today

if [ -d $DATA ]; then exit 6 ; fi
mkdir -p $DATA

cd $log_dir
pwd
echo "Start check ecflow workflow archive job log in $log_dir "

#### Find out how many job exist
job_exist_count=`ls *_HPSS_ARCHIVE*${CDATE}.sh|wc -l`
echo "Total archive job script count: ${job_exist_count}"
success_job_count=`grep "HTAR: HTAR SUCCESSFUL" *_HPSS_ARCHIVE*${CDATE}.out|wc -l`
echo "Total successful job count: ${success_job_count}"
job_hit_walltime_count=`grep "job killed: walltime " *_HPSS_ARCHIVE*${CDATE}.out|wc -l`
echo "job killed on walltime count: ${job_hit_walltime_count}"
job_with_status_error_count=`grep "status=" *_HPSS_ARCHIVE*${CDATE}.out|grep -v "=0"|grep -v "=72"|grep -v "?"|wc -l`
echo "job killed on status error count: ${job_with_status_error_count}"
job_with_system_error_count=`grep " Error -5 on last I/O operation" *_HPSS_ARCHIVE*${CDATE}.out|wc -l`
echo "job killed on system error count: ${job_with_system_error_count}"

echo "Job running filter: $DATA/rr.sh"
`${qq}|grep " R "|grep HPSS|awk -v CDATE=${CDATE} '{print "qstat -f ",$1,"|grep Job_Name|grep",CDATE}' &> $DATA/rr.sh`
sh $DATA/rr.sh &> $DATA/RR1.log
running_job_count=`cat $DATA/RR1.log|wc -l`
echo "Running job count: ${running_job_count}"

#quote_job_count=${qq}|grep " Q "|awk -v CDATE=${CDATE} '{print "qstat -f ",$1,"|grep Job_Name|grep CDATE"}'
echo "Job in queue filter: $DATA/qq.sh"
`${qq}|grep " Q "|awk -v CDATE=${CDATE} '{print "qstat -f ",$1,"|grep Job_Name|grep",CDATE}' &> $DATA/qq.sh`
sh $DATA/qq.sh &> $DATA/QQ1.log
quote_job_count=`cat $DATA/QQ1.log|wc -l`
echo "Job still in Queue count: ${quote_job_count}"

if [ $((success_job_count+running_job_count+quote_job_count-job_exist_count)) -eq 0 ]; then
  echo "Proceed without error"
  exit 0
fi

zombie_job_count=$((success_job_count+job_hit_walltime_count+job_with_status_error_count+job_with_system_error_count+running_job_count+quote_job_count-job_exist_count))
echo "zombie job count: ${zombie_job_count}"
if [ $zombie_job_count -eq 0 ]; then
  echo "Proceed without error"
  ZOMBIE_JOB_FOUND="NO"
else
  echo "Found zombie job in $CDATE"
  ZOMBIE_JOB_FOUND="YES"
  #### exit 9
fi

exit 0
