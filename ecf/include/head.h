date
hostname
set -xe  # print commands as they are executed and enable signal trapping

export PS4='+ $SECONDS + ' 

# Variables needed for communication with ecFlow
export ECF_NAME=%ECF_NAME%
export ECF_PASS=%ECF_PASS%
export ECF_RID=${ECF_RID:-${PBS_JOBID:-$(hostname -s).$$}}
export ECF_JOB=%ECF_JOB%

if [ -d /apps/ops/prod ]; then # On WCOSS2
  set +x
  echo "Running 'module reset'"
  module reset
  set -x
fi

if [ -d /scratch1/NCEPDEV ]; then # On HERA
  set +x
  export LMOD_SYSTEM_DEFAULT_MODULES=intel/2020
  module reset
  set -x
fi

modelhome=%PACKAGEHOME:%
eval "export HOME${model:?'model undefined'}=$modelhome"
eval "versionfile=\$HOME${model}/versions/run.ver"
if [ -f "$versionfile" ]; then . $versionfile ; fi
modelver=$(echo ${modelhome} | perl -pe "s:.*?/${model}\.(v[\d\.a-z]+).*:\1:")
eval "export ${model}_ver=$modelver"

export envir=%ENVIR%
export MACHINE_SITE=%MACHINE_SITE%
export RUN_ENVIR=${RUN_ENVIR:-nco}
export SENDECF=${SENDECF:-YES}
export SENDCOM=${SENDCOM:-YES}
if [ -n "%PDY:%" ]; then export PDY=${PDY:-%PDY:%}; fi
if [ -n "%PARATEST:%" ]; then export PARATEST=${PARATEST:-%PARATEST:%}; fi
if [ -n "%COMPATH:%" ]; then export COMPATH=${COMPATH:-%COMPATH:%}; fi
if [ -n "%MAILTO:%" ]; then export MAILTO=${MAILTO:-%MAILTO:%}; fi
if [ -n "%DBNLOG:%" ]; then export DBNLOG=${DBNLOG:-%DBNLOG:%}; fi

export KEEPDATA=${KEEPDATA:-%KEEPDATA:NO%}
export SENDDBN=${SENDDBN:-%SENDDBN:YES%}
export SENDDBN_NTC=${SENDDBN_NTC:-%SENDDBN_NTC:YES%}

if [ -d /apps/ops/prod ]; then # On WCOSS2
  set +x
  if [ $(whoami) == ops.para ]; then
    module use -a /apps/ops/para/nco/modulefiles/core
  fi
  echo "Running module load ecflow/$ecflow_ver"
  module load ecflow/$ecflow_ver
  echo "ecflow module location: $(module display ecflow |& head -2 | tail -1 | sed 's/:$//')"
  set -x
  . ${ECF_ROOT}/versions/run.ver
  set +x
  module load prod_util/${prod_util_ver}
  module load prod_envir/${prod_envir_ver}
  echo "Listing modules from head.h:"
  module list
  set -x
fi

if [ -d /scratch1/NCEPDEV ]; then # On HERA
  set +x
  module use -a /scratch2/NCEPDEV/nwprod/NCEPLIBS/modulefiles
  echo "Running module load ecflow"
  module load ecflow
  module load prod_util
  echo "Listing modules from head.h:"
  module list
  set -x
fi

timeout 300 ecflow_client --init=${ECF_RID}

# Define error handler
ERROR() {
  set +ex
  if [ "$1" -eq 0 ]; then
     msg="Killed by signal (likely via qdel)"
  else
     msg="Killed by signal $1"
  fi
  ecflow_client --abort="$msg"
  echo $msg
  if [[ " ops.prod ops.para " =~ " $(whoami) " ]]; then
    echo "# Trap Caught" >>$POST_OUT
  fi
  trap $1; exit $1
}

# Trap all error and exit signals
trap 'ERROR $?' ERR EXIT
