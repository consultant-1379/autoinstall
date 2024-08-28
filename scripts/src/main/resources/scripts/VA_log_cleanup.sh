#!/bin/sh

#This script performs a cleanup of old logs
#This is done by taking in the date and deleting all logs from the previous months
#It is under /opt/SYMCsnas/scripts/misc/VA_log_cleanup.sh of the VA server-10.44.235.30
#This script is intended to run on the 28th of each month at 5am.
#To do this run the crontab -e command and add the following line
#0 5 28 * * /bin/sh /opt/SYMCsnas/scripts/misc/VA_log_cleanup.sh

date=$(date +%F)
year="$(cut -d'-' -f1 <<<$date)"
month="$(cut -d'-' -f2 <<<$date)"
month_now="$(cut -d'-' -f2 <<<$date)"

declare -a month_list

while [ $month -lt 13 ] && [ $month -gt 0 ]
do
    month_list+=("$month")
    ((month--))
done

for element in "${month_list[@]}"
do 
    if [ $element -ne $month_now ]; then
        if [ $element -lt 10 ]; then
            rm /opt/SYMCsnas/log/*.log_$year'0'$element*
            rm /opt/SYMCsnas/log/*.log-$year'0'$element*
            rm /var/log/ssnas_event.log.$year'0'$element*
        else
            rm /opt/SYMCsnas/log/*.log_$year$element*
            rm /opt/SYMCsnas/log/*.log-$year$element*
            rm /var/log/ssnas_event.log.$year$element*
        fi
    fi
done
