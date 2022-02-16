# envir-p1.h

export job=${PBS_JOBNAME:-$job}
export jobid=${job}.${PBS_JOBID:-$$}

export RUN_ENVIR=emc
export envir=%ENVIR%
export MACHINE_SITE=%MACHINE_SITE%

export SIPHONROOT=${UTILROOT}/fakedbn
export DBNROOT=$SIPHONROOT

if [[ ! " prod para test " =~ " ${envir} " && " ops.prod ops.para " =~ " $(whoami) " ]]; then err_exit "ENVIR must be prod, para, or test [envir-p1.h]"; fi

export DATAROOT=/scratch1/NCEPDEV/stmp2/$USER/RUNDIRS/%PSLOT%
export COMROOT=/scratch1/NCEPDEV/stmp4/$USER/%PSLOT%/com
export ROTDIR=$COMROOT
export EXPDIR=${HOMEgfs}/parm/config

if [ -n "%PDY:%" ]; then
  export PDY=${PDY:-%PDY:%}
  export CDATE=${PDY}%CYC:%
fi

if [ -n "%COMPATH:%" ]; then export COMPATH=${COMPATH:-%COMPATH:%}; fi
