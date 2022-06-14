#!/bin/bash --login
set -ux

##-------------------------------------------------------------------
## Fanglin Yang,  September 2010
## E-mail: fanglin.yang@noaa.gov, Tel: 301-6833722          
## Global Weather and Climate Modeling Branch, EMC/NCEP/NOAA/
##    This package generates forecast perfomance stats in VSDB format 
##    and makes a variety of graphics to compare anomaly correlation 
##    and RMSE among different experiments. It also makes graphics of
##    CONUS precip skill scores, and fits to rawindsonde and surafce 
##    observations, forecast maps and analysis increments maps.
##    The different components can be turned on or off as desired. 
##    Graphics are sent to a web server for display (for example:  
##    http://www.emc.ncep.noaa.gov/gmb/wx24fy/vsdb/gfs2015/)
##-------------------------------------------------------------------

export NDAYS=$NDAYS
export SDATE=$PDYBEG
export EDATE=$PDYEND
export EXPDIR=$EXPDIR

##export NDAYS=14             ;#number of days (cases)

## figure out starting and ending days


#  CDATE is 00Z of current date.
#  Verification runs on a time-delayed basis.  Back up
#  48 hours = 2 days from CDATE to get ending date, EDATE,
#  for plots.  Start plots NDAYS prior to EDATE

##CDATE=`cat $COMROOTp3/date/t00z | cut -c7-16`
##export EDATE=`$NDATE -48 $CDATE | cut -c1-8`

##NHOURS=$(expr $NDAYS \* 24)
##export SDATE=`$NDATE -${NHOURS} ${EDATE}00 | cut -c1-8`

echo "SDATE $SDATE"
echo "EDATE $EDATE"


#..............
MAKEVSDBDATA=NO          ;#To create VSDB date
MAKEMAPS=YES             ;#To make AC and RMS maps
#..............

#..............
CONUSDATA=NO             ;#To generate precip verification stats
CONUSPLOTS=YES           ;#To make precip verification maps
#..............

FIT2OBS=YES              ;#To make fit-to-obs maps              

MAPS2D=YES               ;#To make forecast maps including lat-lon and zonal-mean distributions          

MAPSGDAS=YES             ;#To make analysis maps of time-mean increments

MAPSENS=NO               ;#To make maps of ENKF ensemble mean and ensemble spread

#----------------------------------------------------------------------
export machine=WCOSS_D             ;#IBM(cirrus/stratus), ZEUS, GAEA, and JET etc
export machine=$(echo $machine|tr '[a-z]' '[A-Z]')
myhome=`pwd`
cd $myhome

####
set -a;. ${myhome}/setup_envs.sh $machine 
if [ $? -ne 0 -o $rc -gt 0 ]; then exit; fi
set -ux

export tmpdir=$STMP/$LOGNAME/nwpvrfy$$               ;#temporary directory for running verification
export mapdir=$tmpdir/web                            ;#local directory to display plots and web templates
mkdir -p $tmpdir ||exit
if [ ! -d $mapdir ]; then
 mkdir -p $mapdir ; cd $mapdir ||exit
 tar xvf ${vsdbhome}/vsdb_exp_webpage.tar 
fi
cd $tmpdir ||exit
rm *.out

myarch=$GNOSCRUB/$USER/archive              ;#archive directory of experiments 
chost=$(hostname)                                    ;#current computer host name

export doftp="YES"                                   ;#whether or not to send maps to web server
export webhost=emcrzdm.ncep.noaa.gov                 ;#host for web display
export webhostid=Lin.Gan                      ;#login id on webhost
export ftpdir=/home/people/emc/www/htdocs/gmb/$webhostid/vsdb/ecfr   ;#where maps are displayed on webhost
export metpdir=/home/people/emc/www/htdocs/gmb/$webhostid/metplus/ecfr

### --------------------------------------------------------------
###   make vsdb database
      if [ $MAKEVSDBDATA = YES ] ; then
### --------------------------------------------------------------
export fcyclist="00 06 12 18"                        ;#forecast cycles to be verified
export expnlist="prhs13 fim"                   ;#experiment names 
export expdlist="$myarch $myarch"              ;#exp directories, can be different
export complist="$chost  $chost "              ;#computer names, can be different if passwordless ftp works 
export dumplist=".gfs. .fim."                  ;#file format pgb${asub}${fhr}${dump}${yyyymmdd}${cyc}
export vhrlist="00 12 "                        ;#verification hours for each day             
export DATEST=20130801                         ;#verification starting date
export DATEND=20130815                         ;#verification ending date
export vlength=240                             ;#forecast length in hour

export rundir=$tmpdir/stats
export listvar1=fcyclist,expnlist,expdlist,complist,dumplist,vhrlist,DATEST,DATEND,vlength,rundir,APRUN
export listvar2=machine,anl_type,iauf00,scppgb,sfcvsdb,canldir,ecmanldir,vsdbsave,vsdbhome,gd,NWPROD,batch
export listvar="$listvar1,$listvar2"

## pgb files must be saved as $expdlist/$expnlist/pgbf${fhr}${cdump}${yyyymmdd}${cyc}
if [ $batch = YES ]; then
  $SUBJOB -e $listvar -a $ACCOUNT  -q $CUE2RUN -g $GROUP -p 1/1/N -r 2048/1 -t 6:00:00 \
     -j vstep1 -o $tmpdir/vstep1.out  ${vsdbhome}/verify_exp_step1.sh
else
     ${vsdbhome}/verify_exp_step1.sh 1>${tmpdir}/vstep1.out 2>&1
fi

### --------------------------------------------------------------
      fi                                       
### --------------------------------------------------------------


 
### --------------------------------------------------------------
###   make AC and RMSE maps            
      if [ $MAKEMAPS = YES ] ; then
### --------------------------------------------------------------
#
export fcycle="00"                         ;#forecast cycles to be verified
export mdlist="gfs ecfr"             ;#experiment names, up to 10, to compare on maps
export caplist="gfs ecfr"            ;#captions of experiments shown in plots      
export vsdblist="$gfsvsdb $vsdbsave"       ;#vsdb stats directories 
export vhrlist="00"                        ;#verification hours for each day to show on map
export DATEST=$SDATE                       ;#verification starting date to show on map
export DATEND=$EDATE                       ;#verification ending date to show on map
export vlength=240                         ;#forecast length in hour to show on map
export maptop=10                           ;#can be set to 10, 50 or 100 hPa for cross-section maps
export maskmiss=1                          ;#remove missing data from all models to unify sample size, 0-->NO, 1-->Yes
export rundir=$tmpdir/acrms$$
export scoredir=$rundir/score
export scorecard=YES
export day4card="1 3 5 6 8 10"             ;#fcst days shown on scorecard
export waitscore=0300

  ${vsdbhome}/verify_exp_step2.sh  1>${tmpdir}/vstep2.out 2>&1 


##--wait 3 hours for all stats to be created and then generate scorecard 
if [ ${scorecard:-NO} = YES ]; then
 if [ $batch = YES ]; then
   listvar=DATEST,DATEND,mdlist,caplist,webhostid,webhost,ftpdir,doftp,rundir,scoredir,vsdbhome,mapdir,day4card
##   $SUBJOB -e $listvar -a $ACCOUNT  -q $CUE2FTP -g $GROUP -p 1/1/S -r 1024/1 -t 1:00:00 -w +${waitscore} \
##      -j scorecard -o $rundir/score.out  ${vsdbhome}/run_scorecard.sh   
   $SUBJOB -e $listvar -a $ACCOUNT  -q $CUE2FTP -g $GROUP -p 1/1/S -r 1024/1 -t 1:00:00 -w +${waitscore} \
      -j scorecard -o $rundir/score.out $EXPDIR/scripts/run_scorecard.sh
 else
    sleep 10800
    ${vsdbhome}/run_scorecard.sh  1>$rundir/score.out 2>&1 
 fi
fi


### --------------------------------------------------------------
    fi
### --------------------------------------------------------------

### --------------------------------------------------------------
###   compute precip threat score stats over CONUS   
      if [ $CONUSDATA = YES ] ; then
### --------------------------------------------------------------
export expnlist="prfv3rt1"                               ;#experiment names
export expdlist="myarch $myarch"                         ;#fcst data directories, can be different
export hpsslist="/NCEPDEV/hpssuser/g01/wx24fy/WCOSS /NCEPDEV/hpssuser/g01/wx24fy/WCOSS"  ;#hpss archive directory                  
export complist="$chost  $chost "                        ;#computer names, can be different if passwordless ftp works 
export ftyplist="pgbq pgbq"                              ;#file types: pgbq or flxf
export dumplist=".gfs. .gfs."                            ;#file format ${ftyp}f${fhr}${dump}${yyyymmdd}${cyc}
export ptyplist="PRATE PRATE"                            ;#precip types in GRIB: PRATE or APCP
export bucket=6                        ;#accumulation bucket in hours. bucket=0 -- continuous accumulation
export fhout=6                                           ;#forecast output frequency in hours
export cycle="00"                                        ;#forecast cycle to verify, give only one
export DATEST=20170824                                   ;#forecast starting date 
export DATEND=20170824                                   ;#forecast ending date 
export vhour=180                                         ;#verification length in hour
export ARCDIR=$GNOSCRUB/$USER/archive           ;#directory to save stats data
export rundir=$tmpdir/mkup_precip                        ;#temporary running directory
export scrdir=${vsdbhome}/precip                  
                                                                                                                           
export listvar1=expnlist,expdlist,hpsslist,complist,ftyplist,dumplist,ptyplist,bucket,fhout,cycle
export listvar2=machine,DATEST,DATEND,ARCDIR,rundir,scrdir,OBSPCP,mapdir,scppgb,NWPROD,APRUN,batch
export listvar="$listvar1,$listvar2"

batch=NO
if [ $batch = YES ]; then
  $SUBJOB -e $listvar -a $ACCOUNT  -q $CUE2FTP -g $GROUP -p 1/1/N -r 2048/1 -t 06:00:00  \
    -j mkup_rain_stat.sh -o $tmpdir/mkup_rain_stat.out ${scrdir}/mkup_rain_stat.sh
else
    ${scrdir}/mkup_rain_stat.sh  1>${tmpdir}/mkup_rain_stat.out 2>&1       
fi
### --------------------------------------------------------------
      fi
### --------------------------------------------------------------


### --------------------------------------------------------------
###   make CONUS precip skill score maps 
      if [ $CONUSPLOTS = YES ] ; then
### --------------------------------------------------------------
export expnlist="gfs ecfr"                ;#experiment names, up to 6 , gfs is operational GFS
export caplist="gfs ecfr"                 ;#captions of experiments shown in plots      
export expdlist="$gfswgnedir $myarch"           ;#fcst data directories, can be different
export complist="$chost $chost"                 ;#computer names, can be different if passwordless ftp works 
export cyclist="00"                             ;#forecast cycles for making QPF maps, 00Z and/or 12Z 
export vhour="180"                              ;#forecast length for making QPF maps
export DATEST=$SDATE                            ;#forecast starting date to show on map
export DATEND=$EDATE                            ;#forecast ending date to show on map
export rundir=$tmpdir/plot_pcp
export scrdir=${vsdbhome}/precip                  
                                                                                                                           
export listvar1=expnlist,expdlist,complist,cyclist,DATEST,DATEND,rundir,scrdir,vhour
export listvar2=doftp,webhost,webhostid,ftpdir,scppgb,gstat,NWPROD,mapdir,GRADSBIN
export listvar3=vsdbhome,SUBJOB,ACCOUNT,GROUP,CUE2RUN,CUE2FTP
export listvar="$listvar1,$listvar2,$listvar3"

if [ $batch = YES ]; then
  $SUBJOB -e $listvar -a $ACCOUNT  -q $CUE2RUN -g $GROUP -p 1/1/S -r 2048/1 -t 01:00:00  \
    -j plot_pcp -o $tmpdir/plot_pcp.out ${scrdir}/plot_pcp.sh
else
    ${scrdir}/plot_pcp.sh 1>${tmpdir}/plot_pcp.out 2>&1 
fi
### --------------------------------------------------------------
      fi
### --------------------------------------------------------------
                                                                                                                           

### --------------------------------------------------------------
###   make fit-to-obs plots
      if [ $FIT2OBS = YES ] ; then
### --------------------------------------------------------------
export expnlist="fnl ecfr"        ;#experiment names, only two allowed, fnl is operatinal GFS
export expdlist="$gfsfitdir $myarch"    ;#fcst data directories, can be different
export complist="$chost $chost"         ;#computer names, can be different if passwordless ftp works
export endianlist="little little"       ;#big_endian or little_endian of fits data, CCS-big, Zeus-little
export cycle="00"                       ;#forecast cycle to verify, only one cycle allowed
export oinc_f2o=24                      ;#increment (hours) between observation verify times for timeout plots
export finc_f2o=12                      ;#increment (hours) between forecast lengths for timeout plots
export fmax_f2o=120                     ;#max forecast length to show for timeout plots
export DATEST=$SDATE                    ;#forecast starting date to show on map
export DATEND=$EDATE                    ;#forecast ending date to show on map
export rundir=$tmpdir/fit
export scrdir=${vsdbhome}/fit2obs
export waitfits=0300

${scrdir}/fit2obs.sh 1>${tmpdir}/fit2obs.out 2>&1 

### --------------------------------------------------------------
      fi
### --------------------------------------------------------------


### --------------------------------------------------------------
### make forecast maps including lat-lon and zonal-mean distributions          
      if [ $MAPS2D = YES ] ; then
### --------------------------------------------------------------
export expnlist="gfs ecfr"        ;#experiments, up to 8; gfs will point to ops data
export expdlist="$gstat $myarch"        ;#fcst data directories, can be different
export complist="mars mars"             ;#computer names, can be different if passwordless ftp works
export dumplist=".gfs. .gfs."           ;#file format pgb${asub}${fhr}${dump}${yyyymmdd}${cyc}

export fdlist="anl 1 5 10"              ;#fcst day to verify, e.g., d-5 uses f120 f114 f108 and f102; anl-->analysis; -1->skip
                                         #note: these maps take a long time to make. be patient or set fewer cases
# export fhlist1="f06 f06 f06 f06"      ;#may specify exact fcst hours to compare for a specific day, must be four
# export fhlist5="f120 f120 f120 f120"  ;#may specify exact fcst hours to compare for a specific day, must be four
# export fhlist10="f240 f240 f240 f240"
export cycle="00"                       ;#forecast cycle to verify, given only one
export DATEST=$SDATE                    ;#starting verifying date
export ndays=$NDAYS                     ;#number of days (cases)
export nlev=31                          ;#pgb file vertical layers
export grid=G2                          ;#pgb file resolution, G2-> 2.5deg;   G3-> 1deg
export pbtm=1000                        ;#bottom pressure for zonal mean maps
export ptop=1                           ;#top pressure for zonal mean maps
export latlon="-90 90 0 360"            ;#map area lat1, lat2, lon1 and lon2
export rundir=$tmpdir/2dmaps
export batch=YES

export listvara=machine,gstat,expnlist,expdlist,complist,dumplist,cycle,DATEST,ndays,nlev,grid,pbtm,ptop,latlon
export listvarb=rundir,mapdir,obdata,webhost,webhostid,ftpdir,doftp,NWPROD,APRUN,vsdbhome,GRADSBIN,batch
export listvarc=SUBJOB,ACCOUNT,GROUP,CUE2RUN,CUE2FTP

export odir=0
for fcstday in $fdlist ; do
 export odir=`expr $odir + 1 `
 export fcst_day=$fcstday
 export listvar=$listvara,$listvarb,$listvarc,odir,fcst_day,fhlist$fcst_day
 if [ $batch = YES ]; then
  $SUBJOB -e $listvar -a $ACCOUNT  -q $CUE2RUN -g $GROUP -p 1/1/N -r 2048/1 -t 6:00:00 \
       -j map2d$odir -o $tmpdir/2dmaps${odir}.out  ${vsdbhome}/plot2d/maps2d_new.sh
 else
  ${vsdbhome}/plot2d/maps2d_new.sh  1>${tmpdir}/2dmaps${odir}.out 2>&1 &
 fi
done
### --------------------------------------------------------------
      fi                                       
### --------------------------------------------------------------


### --------------------------------------------------------------
### make analysis maps of time-mean increments
      if [ $MAPSGDAS = YES ] ; then
### --------------------------------------------------------------
export expnlist="gfs ecfr"          ;#experiments, up to 8
export expdlist="$gstat $myarch"          ;#data archive
export hpsslist="/NCEPPROD/hpssprod/runhistory /NCEPDEV/emc-global/1year/Lin.Gan/WCOSS_DELL_P3/scratch"  ;#hpss arch
export dumplist=".gdas. .gdas."           ;#file format siganl${dum}${cdate} and sigges${dump}$cdate
export complist="mars mars"               ;#computers where data are archived  
export cyclist="00 06 12 18"              ;#forecast cycles to verify, can include one to four
##export DATEST=20150604                  ;#starting verifying date for siganl
##export DATEND=20150614                  ;#starting verifying date for siganl

export DATEEND=${EDATE}00
export DATEBEG=`$NDATE -120 $DATEEND`
if [[ "$DATEBEG" -lt "${PDYBEG}00" ]]; then
    export DATEBEG=${PDYBEG}00
fi
export DATEST=`echo $DATEBEG | cut -c1-8`
export DATEND=`echo $DATEEND | cut -c1-8`

export pbtm=1000                     ;#bottom model layer number (or pressure if using pgb files) for zonal mean maps
export ptop=1                        ;#top model layer number (or pressure if using pgb files) for zonal mean maps
export nlev=31                       ;#vertical layers for sigma file (64 for gfs) or pgb file (31 for gfs)
export latlon="-90 90 0 360"         ;#map area lat1, lat2, lon1 and lon2
export rundir=$tmpdir/gdasmaps
export batch=YES                     ;#to run job in batch mode

export listvara=machine,gstat,expnlist,expdlist,hpsslist,complist,dumplist,cyclist,DATEST,DATEND,nlev,pbtm,ptop,latlon,levsig
export listvarb=rundir,mapdir,webhost,webhostid,ftpdir,doftp,NWPROD,APRUN,vsdbhome,GRADSBIN
export listvarc=SUBJOB,ACCOUNT,GROUP,CUE2RUN,CUE2FTP,batch
export listvar=$listvara,$listvarb,$listvarc

if [ $batch = YES ]; then
 $SUBJOB -e $listvar -a $ACCOUNT  -q $CUE2RUN -g $GROUP -p 1/1/N -r 2048/1 -t 6:00:00 \
    -j mapgdas -o $tmpdir/mapsgdas.out  ${vsdbhome}/plot2d/maps2d_gdas_pgb.sh
else
 ${vsdbhome}/plot2d/maps2d_gdas_sig.sh  1>${tmpdir}/mapsgdas.out 2>&1 &
fi
### --------------------------------------------------------------
      fi                                       
### --------------------------------------------------------------


### --------------------------------------------------------------
### make maps of ENKF ensemble mean and ensemble spread, which must
##  be precomputed outside of this program.
      if [ $MAPSENS = YES ] ; then
### --------------------------------------------------------------
export expnlist="test5 test6"        ;#experiments, up to 8
export expdlist="/stmpd2/Fanglin.Yang /stmpd2/Fanglin.Yang"    ;#data archive
export cyclist="00 06 12 18"         ;#analysis cycles to be included 
export geshour="06"                  ;#enkf forecast hours to be verified
export DATEST=20140401               ;#starting verifying date
export DATEND=20140401               ;#endding verifying date

export JCAP_bin=254                  ;#binary file resolution, linear T254->512x256 etc
export pbtm=1                        ;#bottom model layer number for zonal mean maps
export ptop=64                       ;#top model layer number for zonal mean maps
export nlev=64                       ;#sigma file vertical layers, fix to 64 for gfs
export latlon="-90 90 0 360"         ;#map area lat1, lat2, lon1 and lon2
export levsig="1 7 11 14 20 25 31 35 41 46 49 55 58 61" ;#sigma layers for lat-lon maps,up to 14
export rundir=$tmpdir/ensmaps 
export batch=NO                      ;#to run job in batch mode

export listvara=machine,expnlist,expdlist,cyclist,geshour,DATEST,DATEND,nlev,pbtm,ptop,latlon,levsig
export listvarb=rundir,mapdir,webhost,webhostid,ftpdir,doftp,NWPROD,APRUN,vsdbhome,GRADSBIN
export listvarc=SUBJOB,ACCOUNT,GROUP,CUE2RUN,CUE2FTP,batch
export listvar=$listvara,$listvarb,$listvarc

if [ $batch = YES ]; then
 $SUBJOB -e $listvar -a $ACCOUNT  -q $CUE2RUN -g $GROUP -p 1/1/N -r 2048/1 -t 6:00:00 \
    -j mapens -o $tmpdir/mapens.out  ${vsdbhome}/plot2d/maps2d_ensspread.sh
else
 ${vsdbhome}/plot2d/maps2d_ensspread.sh 1>${tmpdir}/mapens.out 2>&1 &
fi
### --------------------------------------------------------------
      fi                                       
### --------------------------------------------------------------


exit

