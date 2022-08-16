#!/bin/bash
# Written by: DBStain
#AIO sh single file backup

#HARD CODED VARIABLES====================HARD CODED VARIABLES====================HARD CODED VARIABLES=====================
zfs_dataset=mainPool/home/test
backupTag=snapshot
keepLocal=64 #How many backups to keep DEF PER WEEK 57
logFile=/tmp/singleDatasetBackup.log
#using an specific backup tag allows the system to ignore
#manually taken backups with a different naming structure
#HARD CODED VARIABLES====================HARD CODED VARIABLES====================HARD CODED VARIABLES=====================

###=================================================SCHEDULE===============================================================
#Default settings are to backup Mon-Friday from 8AM-6PM and Sat-Sun once at 12PM

#1AM 02AM 03AM 04AM 05AM 06AM 07AM 08AM 09AM 10AM 11AM 12PM 01PM 02PM 03PM 04PM 05PM 06PM 07PM 08PM 09PM 10PM 11PM 12PM
Schedule="
001N 002N 003N 004N 005Y 006N 007N 008Y 009Y 010Y 011Y 012Y 013Y 014Y 015Y 016Y 017Y 018Y 019N 020N 021N 022N 023N 024N
025N 026N 027N 028N 029Y 030N 031N 032Y 033Y 034Y 035Y 036Y 037Y 038Y 039Y 040Y 041Y 042Y 043N 044N 045N 046N 047N 048N
049N 050N 051N 052N 053Y 054N 055N 056Y 057Y 058Y 059Y 060Y 061Y 062Y 063Y 064Y 065Y 066Y 067N 068N 069N 070N 071N 072N
073N 074N 075N 076N 077Y 078N 079N 080Y 081Y 082Y 083Y 084Y 085Y 086Y 087Y 088Y 089Y 090Y 091N 092N 093N 094N 095N 096N
097N 098N 099N 100N 101Y 102N 103N 104Y 105Y 106Y 107Y 108Y 109Y 110Y 111Y 112Y 113Y 114Y 115N 116N 117N 118N 119N 120N
121N 122N 123N 124N 125Y 126N 127N 128N 129N 130N 131N 132Y 133N 134N 135N 136N 137N 138N 139N 140N 141N 142N 143N 144N
145N 146N 147N 148N 149Y 150N 151N 152N 153N 154N 155N 156Y 157N 158N 159N 160N 161N 162N 163N 164N 165N 166N 167N 000N
"
###==================================================SCHEDULE=============================================================


#=========================================================================================================#
#===============================DO NOT CHANGE ANYTHING FROM THIS POINT====================================#
#===============================DO NOT CHANGE ANYTHING FROM THIS POINT====================================#
#===============================DO NOT CHANGE ANYTHING FROM THIS POINT====================================#
#=========================================================================================================#


#Define SIMPLE variables===============================================================================
red="$(tput setaf 1)"
green="$(tput setaf 2)"
green2="$(tput setaf 10)"
bold="$(tput bold)"
r="$(tput sgr0)"
titles=$green2$bold
bar="==========================="
bbar="$bar$bar$bar$bar";
egrep='egrep --color=auto'
fgrep='fgrep --color=auto'
grep='grep --color=auto'
l='ls -CF'
la='ls -A'
ll='ls -alF'
ls='ls --color=auto'
#Define SIMPLE variables==============================================================================


#AUTOMATIC VARIABLES==================================================================================
days2hoursFun () {
if [ "$(date +%a)" == "Mon" ]
then days2hours=0
elif [ "$(date +%a)" == "Tue" ]
then days2hours=24
elif [ "$(date +%a)" == "Wed" ]
then days2hours=48
elif [ "$(date +%a)" == "Thu" ]
then days2hours=72
elif [ "$(date +%a)" == "Fri" ]
then days2hours=96
elif [ "$(date +%a)" == "Sat" ]
then days2hours=120
elif [ "$(date +%a)" == "Sun" ]
then days2hours=144
fi
currentHour=$(date +%H)
totalDaysInHours=$(("10#$days2hours" + "10#$currentHour"))
}

days2hoursFun
#This gives out this info
#debug hours >> echo -n ;echo "$red hour debbuger enabled: $days2hours + $currentHour = $totalDaysInHours" $r
#AUTOMATIC VARIABLES==================================================================================


#############################################################################################################
#staring interface ALL OF THIS COULD BE HAPPENING BEHIND THE SCENES BUT WE MADE A NICE INTERFACE FOR LOGGING
#############################################################################################################
singleDatasetBackup () {
echo;echo
echo $bold"==========================================================================="$r
echo $bold"==========================     RUNNING BACKUP     ========================="$r
echo $bold"==========================    INITIATING TASK     ========================="$r
echo $bold"====================    $(date)    ==================="$r
echo $bold"==========================================================================="$r
echo
echo

#should backup debbuger
ShouldBackup=$(echo $Schedule | cut -d ' ' -f $totalDaysInHours) ;echo -n $red"should backup debbuger (should have a Y or an N): ";echo $ShouldBackup $r

#prep work to know if agent needs to be backed up this hour,
ShouldBackup=$(echo $Schedule | cut -d ' ' -f $totalDaysInHours |cut -c '4')
echo $bold"==========================================================================="$r
echo $bold"============== verifiying if a backup is needed at this time =============="$r;sleep 1;
if [ "$(echo $ShouldBackup)" == "Y" ]

then
#Take a snapshot if needed as per schedule
zfs snapshot $zfs_dataset@"$backupTag"-$(date +%s)
echo $bold$green2"=============              SNAPSHOT COMPLETED                 ============="$r;sleep 1
echo        $bold"==========================================================================="$r
echo;echo

#check if running retention is needed
#check if the number of snapshots present for the dataset is equal or greater, echo nothing to remove if nothing
snapCount=$(zfs list -t snapshot -o name | grep $zfs_dataset@$backupTag |wc -l)
echo $bold"==========================================================================="$r
echo $bold"============= verifiying if retention should run at this time ============="$r
if [[ "$(echo $snapCount)" -gt "$(echo $keepLocal)" ]]

#Retention is needed
 then
   echo "        Settings indicate that we need to keep $keepLocal Snapshots,"
   echo "                  current snapshot count = $snapCount"
   echo $bold"==========================================================================="$r
   echo $bold$red"====================== PROCCEDING WITH RETENTION  ========================="$r
   echo     $bold"                        REMOVING `expr $snapCount - $keepLocal` SNAPSHOT/s"$r
 zfs list -t snapshot -o name | grep $zfs_dataset@$backupTag | tac | tail -n +$(($keepLocal + 1)) | xargs -n 1 zfs destroy -vr
   echo $bold$red"========================= RETENTION COMPLETED ============================="$r
   echo $bold"==========================================================================="$r
   echo
   sleep 2

#retention not needed and message about why
 else
   echo $bold"                          NO RETENTION NEEDED"$r
  echo "   The number of snapshots for dataset is less than the current retention"
  echo "     settings which indicate that we need to keep $keepLocal Snapshots,"
  echo "                   current snapshot count = $snapCount"
  echo $bold"==========================================================================="$r
  echo
 fi

#new snap count and List
echo
echo $bold"==========================================================================="$r
echo $bold"========================    CURRENT SNAPSHOTS   ==========================="$r
zfs list $zfs_dataset -t snapshot -o name,creation | grep $backupTag
echo -n "Total snapshots for this dataset = " ; zfs list -t snapshot -o name, | grep $zfs_dataset@$backupTag |wc -l
echo $bold"==========================================================================="$r

#Skip backup and retention as no snapshot is supposed to run at this time,
else
echo $bold"==========================================================================="$r
echo $bold"======== No backups scheduled to run at this time for the dataset ========="
echo $bold"==========================================================================="$r

fi

echo;echo
echo $bold"==========================================================================="$r
echo $bold"==============               ALL TASKS COMPLETED             =============="$r
echo $bold"====================    $(date)    ==================="$r
echo $bold"==========================================================================="$r
echo
}

#run the backup script and send the info to the log file /tmp/singleDatasetBackup.log
singleDatasetBackup >> $logFile

#==================================================
# Cron expression	Schedule
# * * * * *	Every minute
# 0 * * * *	Every hour
# 0 0 * * *	Every day at 12:00 AM
# 0 0 * * FRI	At 12:00 AM, only on Friday
# 0 0 1 * *	At 12:00 AM, on day 1 of the month
#==================================================
