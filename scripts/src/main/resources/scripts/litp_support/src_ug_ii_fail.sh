#!/bin/bash

# Description: This Script is useful to find Phases/Tasks Failed in the messages/enminst log file during the II or UG as other errors also
# Author: Thiago Calomino - thiago.calomino@ammeon.com
# Version: 0.2.0

if [ ! $1 ]; then
echo -e "Please, informe the message or enminst log file when run this script.\neg.: src_ug_ii_fail.sh messages"
exit
else
logfile=$1
fi

IFS=$'\n'
key_task=0
pck=0


main_filter="enm_prechecks INFO  print_action_heading|enm_prechecks ERROR|Successfully Completed ENM Upgrade Prechecks|deploy_enm.sh|upgrade_enm.sh|Reboot is required to update the kernel|Shutting down the system|System upgrade failed|System successfully upgraded|Completed ENM Deployment at|An error occurred running ENM Deployment|enminst ERROR create_plan"
main_phc_filter="enm_prechecks INFO  print_action_heading|enm_prechecks ERROR|Successfully Completed ENM Upgrade Prechecks"

trigger_phc () {

    if [ $(echo $mf | grep -E "enm_prechecks INFO  print_action_heading") ] && [ $pck == 0 ]; then

      echo -e "\n-------------------------------\nStarting check for PRECHECKS...\n-------------------------------"
      echo -e "\nPRECHECKS Performed..."
      pck=1

    elif [ $(echo $mf | grep -E "enm_prechecks ERROR") ]; then

      echo -e "\n*************************************************\nFound prechecks ERROR before start the upgrade\n*************************************************\n"
      echo -e "\n$mf"
      echo -e "\n*************************************************\nFound prechecks ERROR before start the upgrade\n*************************************************\n"

      pck=0

    elif [ $(echo $mf | grep -E "Successfully Completed ENM Upgrade Prechecks") ]  && [ $pck == 1 ]; then

      echo -e "$mf"

    fi


}

trigger_ug_ii() {
    echo -e "\n-------------------------------------\nLooking for Upgrade or II started...\n-------------------------------------\n"
    lnug=$(echo -e "$mf" | awk -F":" '{print $1}')
    pck=0
    echo -e "\n$mf"
}

trigger_ug_ii_failed() {
    lnugfail=$(echo -e "$mf" | awk -F":" '{print $1}')
    key_task=1
    echo -e "$mf\n"
}

trigger_ug_ii_success() {
    echo -e "$mf\n\nUpgrade or II concluded with success."
    echo -e "\n-------------------------------------------------\nFinishing in looking for Upgrade or II started...\n-------------------------------------------------\n"
}

trigger_tasks_failed() {

    echo "getting task..." 

    [ -z $lnug ] && lnug=0

    task=$(awk "NR == $(expr $lnug + 1 )"',(/Task\: Running>Failed/||/The plan has failed/){ if (/Task\: Running>Failed/||/The plan has failed/) { print NR; exit} else if (/(deploy_enm\.sh|upgrade_enm\.sh)/) { exit } };' $logfile)

    #"If tasks failed, look into..."
    if [ ! -z "$task" ]; then
      #"printing running task failed..."
      awk -v lin=$task -v lnugf=$lnugfail 'NR == lin { if (/The plan has failed/) { print NR":"; while ( NR < (lnugf - 1) ) { print; getline } exit } else { print NR":"; for (i = 1; i <= 3; i++) { print; getline } exit; }} ' $logfile
      #"printing phase/task failed..."
      awk "NR == $task"',/\:   Task\: Failed/{ if (/monitorinfo.*\: Phase/) { ph=$0 } else if (/\:   Task\: Failed/) { print NR":"; print ph; for (i = 1; i <= 3; i++) { print; getline } exit} }' $logfile
	  
	    #Checking for puppet and litp tracing failed task
	    echo -e "\nLooking into for puppet and litp tracing tasks failed related...\n"

	    awk "NR == $lnug, NR == $task"'{ if (/puppet-agent.*failed/) { print NR":" $0 }}' $logfile

	    pidcelery=$( awk "NR == $lnug, NR == $task"'{ if (/litp\..*ERROR/) { print $0 | "cut -f2 -d[ | cut -f1 -d:"; exit }}' $logfile)
	
	    if [ ! -z "$pidcelery" ]; then
	      awk -v pidc=$pidcelery "NR == $lnug, NR == $task"'{ if ($0 ~ pidc":Celery") { print $0 }}' $logfile
	    fi

      echo -e "\nFinish Looking Tasks Failed.\n"
      echo -e "\n-----\n"

    # If no tasks failed, search for healthcheck or other errors
    elif [ $key_task == 1 ] && [ -z "$task" ]; then

      echo -e "\nNo failed tasks found...\n"
      echo -e "\nFinish Looking Tasks Failed.\n"

      echo -e "\nLooking for ENMhealthcheck and other errors...\n"

      awk "NR == $lnug,NR == $lnugfail"'{ if (/enmhealthcheck ERROR/||/Healthcheck errors\!/||/enminst ERROR/||/ERROR create_plan/||/ERROR error/||/ERROR.*healthcheck/) { print NR":"; print; } }' $logfile

    fi
}


echo -e "\nStarting log analyze...\n"

for mf in $(grep -E -n $main_filter $logfile); do


  if [ $(echo $mf | grep -E $main_phc_filter) ]; then

    trigger_phc

  elif [ $(echo $mf | grep -E "deploy_enm.sh|upgrade_enm.sh") ]; then

    trigger_ug_ii

  elif [ $(echo "$mf" | grep -E "System upgrade failed|An error occurred running ENM Deployment") ]; then

    trigger_ug_ii_failed

  elif [ $(echo "$mf" | grep -E "System successfully upgraded|Completed ENM Deployment at") ]; then

    trigger_ug_ii_success

  else

    echo -e "$mf"

  fi

  # If upgrade failed, search for tasks failed
  if [ $key_task == 1 ]; then

    echo -e "Looking for Tasks Failed...\n"
    
    trigger_tasks_failed
    
    echo -e "\n-------------------------------------------------\nFinishing in looking for Upgrade or II started...\n-------------------------------------------------\n"
    key_task=0
    task=""

  fi

done

echo -e "\n...Log analyze finished.\n"
