#! /bin/bash

#python autoinstall.py -litpms http://10.44.84.100/iso/RHEL//rhel-server-6.4-x86_64-dvd.iso /home/admin/iso_files/2.x/ERIClitp_CXP9024296-1.0.232.iso singleblade /opt/ericsson/SIT/autoinstall/autoinstall_2.1/install_scripts/singleblade/deploy_singleblade.sh /opt/ericsson/SIT/autoinstall/autoinstall_2.1/clusterfiles/singleblade/10.44.86.46.sh http://10.^C.86.30/iso/autoinstall_jobs/ /home/admin/iso_files/autoinstall_jobs/

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR


ENV_PROP=( $(echo "$SYSTEM_ID" | sed -n 1'p' | tr ',' '\n') )

NODEIP="${ENV_PROP[0]}"
ENVIRONMENT="${ENV_PROP[1]}"


function ctrl_c() {
    echo "Job has been cancelled!!"
    echo "Removing lock file: /tmp/autoinstall_lock/$NODEIP.lock"
    rm -rf /tmp/autoinstall_lock/$NODEIP.lock
    rm -rf /opt/ericsson/SIT/CORRUPT/corrupt_environment_$FLAG_REMOVAL.flag
    rm -rf  /home/admin/jenkins_litp/autoinstall/$JOB_NAME-$BUILD_NUMBER/
}

if [ -f "/tmp/autoinstall_lock/$NODEIP.lock" ]
then
    echo ""
    echo ""
    echo "----------------------"
    echo "-----------------------------------------------"
    echo "ERROR: $NODEIP is already in use by autoinstall"
    echo "ssh to admin@10.44.86.30 and remove the lock file: /tmp/autoinstall_lock/$NODEIP.lock if it is not already in use by another autoinstall job"
    echo "-----------------------------------------------"
    echo "----------------------"
    echo ""
    echo ""
    exit 1
else
    echo "Creating lock file: /tmp/autoinstall_lock/$NODEIP.lock"
    touch /tmp/autoinstall_lock/$NODEIP.lock
fi

trap ctrl_c SIGINT

if [ $DATA_REG == "DEFAULT" ]
then
    if [ $ENVIRONMENT == "singleblade" ]
    then
        LITP_DATAREG=( $(find /home/admin/jenkins_litp/autoinstall/$JOB_NAME-$BUILD_NUMBER | grep clusterfiles/singleblade/$NODEIP.sh) )
    fi
    if [ $ENVIRONMENT == "multiblade_local" ]
    then
        LITP_DATAREG=( $(find /home/admin/jenkins_litp/autoinstall/$JOB_NAME-$BUILD_NUMBER | grep clusterfiles/multiblade_local/$NODEIP.sh) )
    fi
    if [ $ENVIRONMENT == "multiblade_san" ]
    then
        LITP_DATAREG=( $(find /home/admin/jenkins_litp/autoinstall/$JOB_NAME-$BUILD_NUMBER | grep clusterfiles/multiblade_san/$NODEIP.sh) )
    fi
    if [ $ENVIRONMENT == "cloud" ]
    then
        LITP_DATAREG=( $(find /home/admin/jenkins_litp/autoinstall/$JOB_NAME-$BUILD_NUMBER | grep clusterfiles/cloud/$NODEIP.sh) )
    fi
else
    LITP_DATAREG=( $(find /home/admin/jenkins_litp/autoinstall/$JOB_NAME-$BUILD_NUMBER $DATA_REG | grep $DATA_REG) )
fi

AI_CLI_LOCATION="/home/admin/litp_ks/autoinstall_jobs/"

echo ""
echo ""
echo "RUNNING BACKUP RESTORE..."
echo ""
echo ""

python autoinstall.py -lbr --cluster_file=$LITP_DATAREG --server_http_full_path_location=$AI_CLI_LOCATION
retval=( $(echo "$?") )
if [ $retval -ne 0 ]
then
    echo ""
    echo "!!!AUTOINSTALL FAILED!!!"
    rm -rf /tmp/autoinstall_lock/$NODEIP.lock
    echo ""
    exit 1
fi

echo "Removing lock file: /tmp/autoinstall_lock/$NODEIP.lock"
rm -rf /tmp/autoinstall_lock/$NODEIP.lock
rm -rf /opt/ericsson/SIT/CORRUPT/corrupt_environment_$FLAG_REMOVAL.flag
rm -rf  /home/admin/jenkins_litp/autoinstall/$JOB_NAME-$BUILD_NUMBER/


exit 0
