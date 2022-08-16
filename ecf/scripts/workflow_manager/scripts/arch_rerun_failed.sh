set -x

cd $PBS_O_WORKDIR
Failed_ARCHIVE_fcount1=`grep "+status=" *_HPSS_ARCHIVE_*.out|grep -v "=0"|grep -v "=72"|wc -l`
echo "Current found failed OFFLINE ARCHIVE jobs count is: $Failed_ARCHIVE_fcount1"
Failed_ARCHIVE_fcount2=`grep "job killed: walltime " *_HPSS_ARCHIVE_*.out|wc -l`
echo "Current OFFLINE ARCHIVE jobs exceeded clock limit count is: $Failed_ARCHIVE_fcount2"

FAILED_ARCHIVE_RERUN=${FAILED_ARCHIVE_RERUN:-YES}
#FAILED_ARCHIVE_RERUN="NO"
#### Rerun failed archive job as needed
if [ $Failed_ARCHIVE_fcount1 -gt 0 -o $Failed_ARCHIVE_fcount2 -gt 0 ]; then
  [[ -f remove_failed_archive.sh ]] && rm -f remove_failed_archive.sh
  [[ -f rerun_archive.sh ]] && rm -f rerun_archive.sh
  echo "set -x" >> rerun_archive.sh
  # create a list of cleanout from failed jobs
  grep "job killed: walltime " *_HPSS_ARCHIVE_*.out |awk 'BEGIN { FS = ":=" } ; { print "mv",$1,"./BAD" }' &> remove_failed_archive.sh
  sleep 5
  grep "+status=" *_HPSS_ARCHIVE_*.out|grep -v "=0"|grep -v "=72"|awk 'BEGIN { FS = ":" } ; { print "mv",$1,"./BAD" }' &>> remove_failed_archive.sh
  # create a list of rerun from failed jobs
  grep "PBS: job killed" *_HPSS_ARCHIVE_*.out |awk 'BEGIN { FS = ":=" } ; { print "qsub <",$1 }' &>> rerun_archive.sh
  grep "+status=" *_HPSS_ARCHIVE_*.out|grep -v "=0"|grep -v "=72"|awk 'BEGIN { FS = ":" } ; { print "qsub <",$1 }' &>> rerun_archive.sh
  #sed -i 's/:+//g' remove_failed_archive.sh
  sed -i 's/out/sh/g' rerun_archive.sh
  sleep 2
  if [ "$FAILED_ARCHIVE_RERUN" = "YES" ]; then
    sh remove_failed_archive.sh
    sh rerun_archive.sh &> rerun_archive.log
    echo "Rerun is executed"
    sleep 3
    cat rerun_archive.log
  fi
  ls -alrt remove_failed_archive.sh rerun_archive.sh
fi
