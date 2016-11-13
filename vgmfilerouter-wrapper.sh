#!/usr/bin/ksh
#
# Description: 
# Runs perpetually until stopped via vgmfilerouter.sh. Calls vgmfilerouter.pl
# every 30 seconds or as specified by the DELAY variable in the ini file.
#
# Input    : vgmfilerouter.ini
# Called by: vgmfilerouter.sh
# Calls    : vgmfilerouter.pl
#
#
# Version Date     Description                       By
# ------- -------- --------------------------------- ------
# 1.0     20160926 Current working version           ACG001
# 1.1     20161108 Moved out the if-then-else        ACG001
#                  statement from the while loop
#

#INI_FILE=/devedi/bin/scripts/vgm/vgmfilerouter.ini

INI_FILE=./vgmfilerouter.ini

if [[ ! -f $INI_FILE ]]; then
cat <<EOF

Script Name: $0
Error: Unable to find the ini file $INI_FILE in the current directory

EOF
exit 1
fi

. $INI_FILE

OUT_FILE=/"$ENVIRON"edi/bin/scripts/vgm/log/vgmfilerouter-wrapper-`date +%Y%m%d`.out

THIS_PID=$$

echo $THIS_PID > $SCRIPT_PID

if [[ $ROUTE_APERAK == 1 && $ROUTE_VGM == 1 ]]; then
   SCRIPT_MAIN="$SCRIPT_MAIN -av"
elif [[ $ROUTE_APERAK == 1 && $ROUTE_VGM == 0 ]]; then
   SCRIPT_MAIN="$SCRIPT_MAIN -a"
else
   SCRIPT_MAIN="$SCRIPT_MAIN -v"
fi


while true
do
   if [[ -f $STOP_FLAG ]]; then
      echo $(date +%Y%m%d-%H:%M:%S)" [$THIS_PID] Stopping filerouter script." >> $OUT_FILE
      break
   fi
   if [[ -f $ ]]; then
      echo $(date +%Y%m%d-%H:%M:%S)" [$THIS_PID] VGM PID exists." >> $OUT_FILE
      echo $(date +%Y%m%d-%H:%M:%S)" [$THIS_PID] Delaying for 10 seconds..." >> $OUT_FILE
      sleep 10
      continue
   fi
   echo $(date +%Y%m%d-%H:%M:%S)" [$THIS_PID] Running vgm filerouter script." >> $OUT_FILE;
   echo "Calling $SCRIPT_MAIN" >> $OUT_FILE

   ###############################
   `$SCRIPT_MAIN > /dev/null 2>&1`
   ###############################

   echo $(date +%Y%m%d-%H:%M:%S)" [$THIS_PID] vgm filerouter script completed." >> $OUT_FILE;
   echo $(date +%Y%m%d-%H:%M:%S)" [$THIS_PID] Sleeping for $DELAY seconds." >> $OUT_FILE
   sleep $DELAY
done
rm -f $SCRIPT_PID
