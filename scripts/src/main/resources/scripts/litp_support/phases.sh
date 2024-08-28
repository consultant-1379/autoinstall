#!/bin/bash
#title		:phases.sh
#version	:1.0
#date		:2019/02/22
#author		:Piotr Kakol
#description 	:This scripts suppose to help when dealing with timing issues during the upgrade, particulary exports details about start/end time of the each phase sorted by phase number (not the time!), eventually the output can exported to the csv file that can be open directly in the spreadsheet.
 

#Make sure that /var/log/messages has been filtered already and covers only the period of the upgrade

#getting path to the messages log file
read -p "$(echo -e "Please type path to the file that contains filtered details from /var/log/messages from the ms server:\n\b")" plik

#looking for number of phases in the upgrade plan
phases=$(grep "PlanState: successful" $plik | awk '{print $11}')


#confirm number of phases with user and then find start/finish time for the each phase
read -p  "$(echo -e 'The data will be printed on the screen, you can run following command if you want also write the output to the file:  "./phases.sh | tee -a file_name".\n\bAs per information from the /var/log/messages we had' $phases 'phases in the upgrade, if this is correct please type y)?\n\b')" -n 1 -r

if [[ $REPLY =~ ^[Yy]$ ]] 

then

	printf "%s\n"
	for ((i=1;i<=phases;i++)); do

          Poczatek=$(printf %s "$(grep "Running phase $i$" $plik | awk '{print $3}')")
          Koniec=$(printf %s "$(grep "Phase $i successful" $plik | awk '{print $3}')")
          StartTime=$(date -u -d "$Poczatek" +"%s")
          EndTime=$(date -u -d "$Koniec" +"%s")
          Roznica=$(date -u -d "0 $EndTime sec - $StartTime sec" +"%H:%M:%S")
       		printf  "It took, $Roznica, to finish this phase $i - details:, " && printf %s "$(grep "Running phase $i$" $plik | awk '{print $1, $2"," $3"," $7, $8, $9 ","}')" && grep "Phase $i successful" $plik | awk '{print $3"," $7, $8, $9}'
	done
else
	printf "\033c"  && printf "%s\n" "Something is wrong, canceling action" && printf "%s\n" "Bye"

fi

