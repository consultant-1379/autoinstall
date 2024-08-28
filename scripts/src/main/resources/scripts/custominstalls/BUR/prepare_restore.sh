#!/bin/bash
#
# Default script used for prepare restore
#
# Usage:
#   prepare_restore.sh <CLUSTER_SPEC_FILE>
#

if [ "$#" -lt 1 ]; then
    echo -e "Usage:\n  $0 <CLUSTER_SPEC_FILE>" >&2
    exit 1
fi

cluster_file="$1"
source "$cluster_file"

set -x

# Run prepare_restore
litp prepare_restore

# Update the clusters to not bring the SGs online
if [ ${num_clusters} -ne 0 ]; then

   for (( i=1; i<=${num_clusters} ; i++ )); do

      litp update -p /deployments/d1/clusters/c${i} -o cs_initial_online=off

   done

fi

# Add an update on the MS for MS only systems - 210 and 28
litp create -t alias -p /ms/configs/alias_config/aliases/prepres_alias -o alias_names=prepare,restore address=aaaa:aaaa:aaaa:aaaa::bbbb

# #Clean the Known Hosts file on the MS
echo '' > /home/litp-admin/.ssh/known_hosts

# Create the plan
litp create_plan

#num = $(litp show_plan |grep Tasks | awk '{print $2}')
#echo "The amount of tasks in the plan is $num"


# Check for the expected number of tasks in the litp plan after prepare_restore
if [ ${num_prepare_restore_tasks} -ne $(litp show_plan |grep Tasks | awk '{print $2}') ]; then

 echo "The plan does not have the expected number of tasks"
 exit 1

fi
