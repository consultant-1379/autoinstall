#!/bin/bash

name=$1
os_path=/var/www/html/6/updates/x86_64/Packages/

function check_litp_availability() {

  show_item=$(litp show -p /ms)
  ready=$?
}

set -x

echo "### Import an ISO ###"
  
# make a mount dirctory 
newdir="mkdir /mnt3"
echo $newdir
out=$($newdir)

# mount the iso into this directory
mount="mount $name /mnt3 -o loop"
  echo $mount
  out=$($mount)

  # Run import_iso
  cmd="litp import_iso /mnt3"

echo $cmd
d=$(date +%T)
echo "Start Time : $d"
import=$(time ($cmd)  2>&1 1>/dev/null)
rc=$?

# wait for at least 4 mins before checking if litp is out of maintenance mode
# expected time for completion is over 4 mins
sleep 240
check_litp_availability
while [ $ready -ne 0 ] 
do
check_litp_availability
sleep 20
done

# Check messages log for the completion time and measure against the start time 
check_messages=$(tail -300 /var/log/messages |grep 'INFO: ISO Importer is finished, exiting with 0')
echo "Log indicating end of operation: $check_messages"
completed=$(echo $check_messages | awk '{print $3}')
echo "Completion Time: $completed"

begin=$(date -d "$d" +"%s")
end=$(date -d "$completed" +"%s")

duration=$(date -d "0 $end sec - $begin sec" +"%M:%S")
echo "Import ISO operation took $duration"
echo "IMport ISO operation done"


echo $import
importtime=$(echo $import | awk '{print $2}')
echo "Time for importing of $1 is $importtime"

# Unmount ISO
echo "Unmounting the ENM ISO"
mount="umount /mnt3"
  echo $mount
  out=$($mount)

