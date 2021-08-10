set -x

USER=$USER
HOMEgfs=/mnt/lfs4/HFIP/hfv3gfs/Lin.Gan/PR/global-workflow-pr
EXPDIR=/lfs4/HFIP/hfv3gfs/Lin.Gan/expdir
PSLOT=test5_c192_pr
COMROT=/lfs4/HFIP/hfv3gfs/Lin.Gan/ptmp/com
IDATE=2020090600
EDATE=2020090612
RESDET=192

ln -fs ${HOMEgfs}/parm/config/config.base.emc.dyn ${HOMEgfs}/parm/config/config.base

./setup_expt_fcstonly.py --pslot $PSLOT  \
       --gfs_cyc 1 --idate $IDATE --edate $EDATE \
       --configdir $HOMEgfs/parm/config \
       --res $RESDET --comrot $COMROT --expdir $EXPDIR

cd $EXPDIR/$PSLOT
ln -s $HOMEgfs/ush/rocoto/setup_workflow_fcstonly.py
#### Modify config.base then run 
#### ./setup_workflow_fcstonly.py --expdir $EXPDIR/$PSLOT
