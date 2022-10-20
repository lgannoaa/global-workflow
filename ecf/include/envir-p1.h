# envir-p1.h
export job=${job:-$PBS_JOBNAME}
export jobid=${jobid:-$job.$PBS_JOBID}

export RUN_ENVIR=emc
export envir=%ENVIR%
export MACHINE_SITE=%MACHINE_SITE%

if [ -n "%SENDCANNEDDBN:%" ]; then export SENDCANNEDDBN=${SENDCANNEDDBN:-%SENDCANNEDDBN:%}; fi
export SENDCANNEDDBN=${SENDCANNEDDBN:-"NO"}

if [[ "$envir" == prod && "$SENDDBN" == YES ]]; then
    export eval=%EVAL:NO%
    if [ $eval == YES ]; then export SIPHONROOT=${UTILROOT}/para_dbn
    else export SIPHONROOT=/lfs/h1/ops/prod/dbnet_siphon
    fi
    if [ "$PARATEST" == YES ]; then export SIPHONROOT=${UTILROOT}/fakedbn; export NODBNFCHK=YES; fi
else
    export SIPHONROOT=${UTILROOT}/fakedbn
fi
export SIPHONROOT=${UTILROOT}/fakedbn
export DBNROOT=$SIPHONROOT

if [[ ! " prod para test " =~ " ${envir} " && " ops.prod ops.para " =~ " $(whoami) " ]]; then err_exit "ENVIR must be prod, para, or test [envir-p1.h]"; fi

PTMP=/lfs/h2/emc/ptmp
PSLOT=retro1-v16-ecf
export OFFLINE_HPSS_ARCH=YES
export COMROOT=${PTMP}/${USER}/${PSLOT}/para/com
export COMPATH=${PTMP}/${USER}/${PSLOT}/para/com/gfs:${PTMP}/${USER}/${PSLOT}/para/com/obsproc
export ROTDIR="$(compath.py gfs/${gfs_ver})"
export COMOUT_PREP="$(compath.py obsproc/v1.1.0)"
if [ -n "%PDY:%" ]; then
  export PDY=${PDY:-%PDY:%}
  export CDATE=${PDY}%CYC:%
fi
export DATAROOT=/lfs/h2/emc/stmp/${USER}/RUNDIRS/${PSLOT}/${CDATE}
echo $ROTDIR/%RUN:%.${PDY}/%CYC:%/atmos
mkdir -p $DATAROOT $ROTDIR/%RUN:%.${PDY}/%CYC:%/atmos
#### export COMINobsproc=/lfs/h2/emc/global/noscrub/emc.global/dump/%RUN:%.${PDY}/%CYC:%
export COMINobsproc=/lfs/h2/emc/ptmp/${USER}/${PSLOT}/para/com/obsproc/v1.1/%RUN:%.${PDY}/%CYC:%/atmos
#### tcvital assignment
#### export COMINtcvital=$COMINobsproc

#### Emergency production switch check
####   If production is not dogwood, the production switch is in place. The parallel should ####   stop.
prod_machine_Current=`grep primary /lfs/h1/ops/prod/config/prodmachinefile|awk 'BEGIN { FS = ":" } ; { print $2 }'`
echo "Current production machine is $prod_machine_Current"
if [[ "$prod_machine_Current" == cactus ]]; then
  err_exit "Production switch is in place. All parallel jobs set to fail."
fi
