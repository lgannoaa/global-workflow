set -x

#export machine=WCOSS2
#export NET=gfs
#export RUN=gfs
#export QUEUE_ARCH=dev_transfer
#export ACCOUNT=GFS-DEV
pslot=da-dev16-ecf
#export PDY
#export cyc=18
export JOB_LOG_DIR=${JOB_LOG_DIR:-/lfs/h2/emc/ptmp/lin.gan/da-dev16-ecf/para/com/output/prod/today}
export SOURCE_DIR=${ROTDIR:-/lfs/h2/emc/ptmp/lin.gan/da-dev16-ecf/para/com/gfs/v16.3}
export ARCH_LIST=${ARCH_LIST:-${SOURCE_DIR}/${RUN}.${PDY}/${cyc}/atmos/archlist}
export HPSS_TARGET_DIR=${ATARDIR:-/NCEPDEV/emc-global/5year/lin.gan/WCOSS2/scratch/da-dev16-ecf}/${CDATE}
#export HPSS_TARGET_DIR=/NCEPDEV/emc-global/1year/Lin.Gan/WCOSS2/202205da

#### Required export TRANSFER_TARGET_FILE
echo "Archive list file name is $TRANSFER_TARGET_FILE"
#echo $TRANSFER_TARGET_FILE

python ${HOME_emc_ecf_wm}/scripts/hpss_global_archive.py
