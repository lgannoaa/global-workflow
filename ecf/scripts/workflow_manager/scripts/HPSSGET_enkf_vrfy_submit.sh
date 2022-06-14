'''
Program Name: HPSSGET_enkf_vrfy_submit.py
Contact(s): Lin Gan
Abstract: This script is run by ecflow
          It download missing gdas.t*z.*f006.ens*.nc files for a CDATE from HPSS
'''

import os

print("BEGIN: "+os.path.basename(__file__))

COMIN_HPSSGET = os.environ['COMIN_HPSSGET']
TARGET_ENKF_TAR = os.environ['TARGET_ENKF_TAR']
QUEUE = os.environ['QUEUE']
ACCOUNT = os.environ['ACCOUNT']
nproc = os.environ['nproc']
cwd = os.getcwd()
batch_job_dir = os.path.join(cwd, 'batch_jobs')
job_name = hpssget_enkf_vrfy
job_card_filename = os.path.join(batch_job_dir,'HPSSGET_enkf_vrfy_job.sh')
job_output_filename = os.path.join(batch_job_dir,'HPSSGET_enkf_vrfy_job.out')
script = = os.path.join(EXPDIR/script/HPSSGET_enkf_vrfy_submit.sh)
print("Writing job card to "+job_card_filename)
with open(job_card_filename, 'a') as job_card:
job_card.write('#!/bin/sh\n')
job_card.write('#BSUB -q '+QUEUE+'\n')
job_card.write('#BSUB -P '+ACCOUNT+'\n')
job_card.write('#BSUB -J '+job_name+'\n')
job_card.write('#BSUB -o '+job_output_filename+'\n')
job_card.write('#BSUB -e '+job_output_filename+'\n')
job_card.write('#BSUB -W 6:00\n')
job_card.write('#BSUB -M 3000\n')
job_card.write('#BSUB -n '+nproc+'\n')
job_card.write('#BSUB -R "span[ptile='+nproc+']"\n')
job_card.write('#BSUB -R affinity[core(1):distribute=balance]\n')
job_card.write('\n')
job_card.write('/bin/sh '+script)

print("Submitting "+job_card_filename+" to "+QUEUE)
print("Output sent to "+job_output_filename)
os.system('bsub < '+job_card_filename)
print("END: "+os.path.basename(__file__))
