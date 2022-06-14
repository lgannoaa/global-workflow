#! /bin/ksh

#  This script monitors the progress of ICS jobs

set -x

icnt=1
trgfg=0
while [ $icnt -lt 1000 ]
do

  if [ -s ${COMIN}/INPUT/sfc_data.tile6.nc ]
  then
  # Reset Trigger flag
    trgfg=0
  # Start fcst job
    ecflow_client --event release_fcst
  # Does not run get ic jobs
    ecflow_client --force=complete /prod/primary/00/workflow_manager/v1.0/gfs/atmos/jgfs_getic
    ecflow_client --force=complete /prod/primary/00/workflow_manager/v1.0/gfs/atmos/jgfs_init
    break
  else
    if [ $trgfg -eq 0 ]
    then
    # Set Trigger flag
      trgfg=1
    # Start getic job
      ecflow_client --event release_getic
    fi
  fi
  sleep 10
  icnt=$((icnt + 1))

done

echo Exiting $0

exit
