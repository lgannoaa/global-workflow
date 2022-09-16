set -x

cd $PBS_O_WORKDIR
Failed_ARCHIVE_fcount2=`grep "job killed: walltime " *_HPSS_ARCHIVE_*.out|wc -l`
echo "Current OFFLINE ARCHIVE jobs exceeded clock limit count is: $Failed_ARCHIVE_fcount2"
Failed_ARCHIVE_fcount3=`grep " - aborting" *_HPSS_ARCHIVE_*.out|wc -l`
echo "Current OFFLINE ARCHIVE jobs failed with aborting status count is: $Failed_ARCHIVE_fcount3"
Failed_ARCHIVE_fcount4=`grep " Error -5 on last I/O operation" *_HPSS_ARCHIVE_*.out|wc -l`
echo "Current OFFLINE ARCHIVE jobs failed system error count is: $Failed_ARCHIVE_fcount4"


FAILED_ARCHIVE_RERUN=${FAILED_ARCHIVE_RERUN:-YES}
if [ "$FAILED_ARCHIVE_RERUN" = "NO" ]; then
  exit 0
fi
#### Rerun failed archive job as needed
if [ $Failed_ARCHIVE_fcount2 -gt 0 -o $Failed_ARCHIVE_fcount3 -gt 0 -o $Failed_ARCHIVE_fcount4 -gt 0 ]; then
  [[ -f remove_failed_archive.sh ]] && rm -f remove_failed_archive.sh
  [[ -f rerun_archive.sh ]] && rm -f rerun_archive.sh
  echo "set -x" >> rerun_archive.sh
  # create a list of cleanout from failed jobs
  # jobs failed cause of hit walltime
  grep "job killed: walltime " *_HPSS_ARCHIVE_*.out |awk 'BEGIN { FS = ":=" } ; { print "qsub <",$1 }' &>> rerun_archive.sh
  grep "job killed: walltime " *_HPSS_ARCHIVE_*.out |awk 'BEGIN { FS = ":=" } ; { print "mv",$1,"./BAD" }' &> remove_failed_archive.sh
  awk '!seen[$0]++' remove_failed_archive.sh &> remove_failed_archive_uniq.sh
  sh remove_failed_archive_uniq.sh
  # jobs failed cause of aborting error
  grep " - aborting" *_HPSS_ARCHIVE_*.out|awk 'BEGIN { FS = ":" } ; { print "qsub <",$1 }' &>> rerun_archive.sh
  grep " - aborting" *_HPSS_ARCHIVE_*.out|awk 'BEGIN { FS = ":" } ; { print "mv",$1,"./BAD" }' &> remove_failed_archive.sh
  awk '!seen[$0]++' remove_failed_archive.sh &> remove_failed_archive_uniq.sh
  sh remove_failed_archive_uniq.sh
  # jobs failed cause of system error
  grep " Error -5 on last I/O operation" *_HPSS_ARCHIVE_*.out|awk 'BEGIN { FS = ":" } ; { print "qsub <",$1 }' &>> rerun_archive.sh
  grep " Error -5 on last I/O operation" *_HPSS_ARCHIVE_*.out|awk 'BEGIN { FS = ":" } ; { print "mv",$1,"./BAD" }' &> remove_failed_archive.sh
  awk '!seen[$0]++' remove_failed_archive.sh &> remove_failed_archive_uniq.sh
  sh remove_failed_archive_uniq.sh
  awk '!seen[$0]++' rerun_archive.sh &> rerun_archive_uniq.sh
  sed -i 's/out/sh/g' rerun_archive_uniq.sh
  sh rerun_archive_uniq.sh &> rerun_archive_uniq.log
  echo "Rerun is executed"
  sleep 3
  cat rerun_archive.log
  ls -alrt remove_failed_archive.sh rerun_archive.sh
else
  echo "Nothing to rerun for this cycle"
fi
