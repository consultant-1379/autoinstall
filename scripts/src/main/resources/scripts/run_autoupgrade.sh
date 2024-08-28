#! /bin/bash

#python autoinstall.py -litpms http://10.44.84.100/iso/RHEL//rhel-server-6.4-x86_64-dvd.iso /home/admin/iso_files/2.x/ERIClitp_CXP9024296-1.0.232.iso singleblade /opt/ericsson/SIT/autoinstall/autoinstall_2.1/install_scripts/singleblade/deploy_singleblade.sh /opt/ericsson/SIT/autoinstall/autoinstall_2.1/clusterfiles/singleblade/10.44.86.46.sh http://10.^C.86.30/iso/autoinstall_jobs/ /home/admin/iso_files/autoinstall_jobs/

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR

RHEL_ISO="http://10.44.84.100/iso/RHEL//rhel-server-6.4-x86_64-dvd.iso"
LITP_ISO_DIR="/home/admin/iso_files/2.x/"
if [ $UPGRADE_ISO == "LATEST" ]
then
    iso_name=( $(ls -lrt $LITP_ISO_DIR | grep ERIClitp_ | grep .iso | sed -e 's/  / /g' | cut -d ' ' -f 9 | tail -1) )
    LITP_ISO_PATH="$LITP_ISO_DIR/$iso_name"
else
    LITP_ISO_PATH="$UPGRADE_ISO"
fi

#iso_name=( $(ls -lrt $LITP_ISO_DIR | grep ERIClitp_ | grep .iso | sed -e 's/  / /g' | cut -d ' ' -f 9 | tail -1) )
#LITP_ISO_PATH="$LITP_ISO_DIR/$iso_name"
#LITP_ISO_PATH="/ISO/litp_2.1//SP11/ERIClitp_CXP9024296-2.10.49.iso"

previous_isos="/ISO/litp_2.1/LITP-ISO-2.1/"
sprint=( $(ls -lrt $previous_isos | grep -v total | awk '{print $9}') );
last_sprint="${sprint[${#sprint[@]}-1]}"
last_iso=( $(ls $previous_isos/$last_sprint | grep iso) )
LITP_ISO_SP_LAST1=(${last_iso[${#last_iso[@]}-1]})
LITP_ISO_SP_LAST="$previous_isos/$last_sprint/$LITP_ISO_SP_LAST1"
TARBALL_PATH="$previous_isos/$last_sprint/$TARBALL_PATH1"
#LITP_ISO_SP_LAST="/home/admin/iso_files/LITP-ISO-2.1/SP7/ERIClitp_CXP9024296-2.6.43.iso"


ENV_PROP=( $(echo "$SYSTEM_ID" | sed -n 1'p' | tr ',' '\n') )

NODEIP="${ENV_PROP[0]}"
ENVIRONMENT="${ENV_PROP[1]}"

function ctrl_c() {
    echo "Job has been cancelled!!"
    echo "Removing lock file: /tmp/autoinstall_lock/$NODEIP.lock"
    rm -rf /tmp/autoinstall_lock/$NODEIP.lock
    rm -rf /opt/ericsson/SIT/CORRUPT/corrupt_environment_$FLAG_REMOVAL.flag
    rm -rf /home/admin/jenkins_litp/autoinstall/$JOB_NAME-$BUILD_NUMBER/
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

LITP_INSTALL_SCRIPT="$previous_isos/$last_sprint/deploy_$ENVIRONMENT.sh"
#LITP_DATAREG="/opt/ericsson/SIT/autoinstall/autoinstall_2.1/clusterfiles/$ENVIRONMENT/$NODEIP.sh"
LITP_DATAREG=( $(find /home/admin/jenkins_litp/autoinstall/$JOB_NAME-$BUILD_NUMBER | grep clusterfiles/$ENVIRONMENT/$NODEIP.sh) )
AI_HTTP_LOCATION="http://10.44.86.30/litp_ks/autoinstall_jobs/"
AI_CLI_LOCATION="/home/admin/litp_ks/autoinstall_jobs/"
#REV H was last used in Sp11 release
#OS_PATCHES_PATH="/home/admin/iso_files/RHEL_Patches/RevH/ERICrhel_CXP9022639-2.1.3.tar.gz"
#OS_PATCHES_PATH="/ISO/RHEL/RHEL_Patches/6.6_RevA/ERICrhel_CXP9026826-2.2.1.tar.gz"
#OS_PATCHES_PATH="/ISO/RHEL/RHEL_Patches/6.6_RevD/ERICrhel_CXP9026826-3.0.5.tar.gz"
#OS_PATCHES_PATH="http://10.44.86.30/iso/RHEL_Patches/6.6_RevD/ERICrhel_CXP9026826-3.0.5.tar.gz"
#OS_PATCHES_PATH="http://10.44.86.30/iso/RHEL_Patches/6.6_RevG/ERICrhel_CXP9026826-3.0.5-1.tar.gz"
#OS_PATCHES_PATH="http://10.44.86.30/iso/RHEL_Patches/6.6_RevH/ERICrhel_CXP9026826-3.0.14.tar.gz"
#OS_PATCHES_PATH="http://10.44.86.30/iso/RHEL_Patches/6.6_RevJ/ERICrhel_CXP9026826-3.0.16.tar.gz"
#OS_PATCHES_PATH="http://10.44.86.30/iso/RHEL_Patches/6.6_RevK/RHEL_OS_Patch_Set_CXP9026826-3.0.17.tar.gz"
#OS_PATCHES_PATH="http://10.44.86.30/iso/RHEL_Patches/6.6_RevL/RHEL_OS_Patch_Set_CXP9026826-3.0.18.tar.gz"
#OS_PATCHES_PATH="http://10.44.86.30/iso/RHEL_Patches/6.6_RevM/RHEL_OS_Patch_Set_CXP9026826-3.0.21.tar.gz"
#OS_PATCHES_PATH="http://10.44.86.30/iso/RHEL_Patches/6.6_RevV/RHEL_OS_Patch_Set_CXP9026826-1.16.2.tar.gz"
#OS_PATCHES_PATH="http://10.44.86.30/iso/RHEL_Patches/6.6_RevY/RHEL_OS_Patch_Set_CXP9026826-1.18.3.tar.gz"
#OS_PATCHES_PATH="http://10.44.86.30/iso/RHEL_Patches/6.6_RevAB/RHEL_OS_Patch_Set_CXP9026826-1.21.1.tar.gz"
#OS_PATCHES_PATH="http://10.44.86.30/iso/RHEL_Patches/6.6_RevAC/RHEL_OS_Patch_Set_CXP9026826-1.22.3.tar.gz"
#OS_PATCHES_PATH="http://10.44.86.14:8000/iso/RHEL_Patches/6.6_RevAD/RHEL_OS_Patch_Set_CXP9026826-1.23.4.tar.gz"
#OS_PATCHES_PATH="http://10.44.86.14:8000/iso/RHEL_Patches/6.6_RevAE/RHEL_OS_Patch_Set_CXP9026826-1.24.3.tar.gz"
#OS_PATCHES_PATH="http://10.44.235.150/iso/RHEL_Patches/6.6_RevAG/RHEL_OS_Patch_Set_CXP9026826-1.26.1.tar.gz"
OS_PATCHES_PATH="http://10.44.235.150/iso/RHEL_Patches/6.6_RevAJ/RHEL_OS_Patch_Set_CXP9026826-1.28.1.tar.gz"

#OS_PATCHES_PATH_UPGRADE="/ISO/RHEL/RHEL_Patches/6.6_RevG/ERICrhel_CXP9026826-3.0.5-1.tar.gz"
#OS_PATCHES_PATH_UPGRADE="/ISO/RHEL/RHEL_Patches/6.6_RevF/ERICrhel_CXP9026826-3.0.11.tar.gz"
#OS_PATCHES_PATH_UPGRADE="/ISO/RHEL/RHEL_Patches/6.6_RevH/ERICrhel_CXP9026826-3.0.14.tar.gz"
#OS_PATCHES_PATH_UPGRADE="http://10.44.86.30/iso/RHEL_Patches/6.6_RevD//ERICrhel_CXP9026826-3.0.5.tar.gz"
#OS_PATCHES_PATH_UPGRADE="http://10.44.86.30/iso/RHEL_Patches/6.6_RevH/ERICrhel_CXP9026826-3.0.14.tar.gz"
#OS_PATCHES_PATH_UPGRADE="http://10.44.86.30/iso/RHEL_Patches/6.6_RevJ/ERICrhel_CXP9026826-3.0.16.tar.gz"
#OS_PATCHES_PATH_UPGRADE="http://10.44.86.30/iso/RHEL_Patches/6.6_RevL/RHEL_OS_Patch_Set_CXP9026826-3.0.18.tar.gz"
#OS_PATCHES_PATH_UPGRADE="http://10.44.86.30/iso/RHEL_Patches/6.6_RevM/RHEL_OS_Patch_Set_CXP9026826-3.0.21.tar.gz"
#OS_PATCHES_PATH_UPGRADE="http://10.44.86.30/iso/RHEL_Patches/6.6_RevN/RHEL_OS_Patch_Set_CXP9026826-3.0.21-1.tar.gz"
#OS_PATCHES_PATH_UPGRADE="http://10.44.86.30/iso/RHEL_Patches/6.6_RevS/RHEL_OS_Patch_Set_CXP9026826-1.13.3.tar.gz"
#OS_PATCHES_PATH_UPGRADE="http://10.44.86.30/iso/RHEL_Patches/6.6_RevT/RHEL_OS_Patch_Set_CXP9026826-1.14.1.tar.gz"
#OS_PATCHES_PATH_UPGRADE="http://10.44.86.30/iso/RHEL_Patches/6.6_RevV/RHEL_OS_Patch_Set_CXP9026826-1.16.2.tar.gz"
#OS_PATCHES_PATH_UPGRADE="http://10.44.86.30/iso/RHEL_Patches/6.6_RevY/RHEL_OS_Patch_Set_CXP9026826-1.18.3.tar.gz"
#OS_PATCHES_PATH_UPGRADE="http://10.44.86.30/iso/RHEL_Patches/6.6_RevAB/RHEL_OS_Patch_Set_CXP9026826-1.21.1.tar.gz"
#OS_PATCHES_PATH_UPGRADE="http://10.44.86.30/iso/RHEL_Patches/6.6_RevAC/RHEL_OS_Patch_Set_CXP9026826-1.22.3.tar.gz"
#OS_PATCHES_PATH_UPGRADE="http://10.44.86.30/iso/RHEL_Patches/6.6_RevAD/RHEL_OS_Patch_Set_CXP9026826-1.24.4.tar.gz"
#OS_PATCHES_PATH_UPGRADE="http://10.44.86.14:8000/iso/RHEL_Patches/6.6_RevAE/RHEL_OS_Patch_Set_CXP9026826-1.24.3.tar.gz"
#OS_PATCHES_PATH_UPGRADE="http://10.44.235.150/iso/RHEL_Patches/6.6_RevAJ/RHEL_OS_Patch_Set_CXP9026826-1.28.1.tar.gz"
OS_PATCHES_PATH_UPGRADE="http://10.44.235.150/iso/RHEL_Patches/6.6_RevAK/RHEL_OS_Patch_Set_CXP9034997-1.4.1.iso"

echo ""
echo ""
echo "RUNNING AUTOINSTALL..."
echo ""
echo ""

if $OS_PATCHES
then
    os_patches="--with_os_patches=$OS_PATCHES_PATH"
    os_patches_upgrade="--with_os_patches_upgrade=$OS_PATCHES_PATH_UPGRADE"
else
    os_patches=""
    os_patches_upgrade=""
fi

if [ $RESTORE_OPTION ] && $RESTORE_OPTION
then
    restore_option="--restore-from-upgrade"
else
    restore_option=""
fi

if [ $RSYSLOG_UPDATE ] && $RSYSLOG_UPDATE
then
    rsyslog_option="--update-rsyslog8"
else
    rsyslog_option=""
fi

option_int=""
UPGRADE_OPTION=$AI_OPTION
if [ $UPGRADE_OPTION == "complete-install-upgrade" ]
then
    option_int="-ciu"
fi
if [ $UPGRADE_OPTION == "upgrade_only" ]
then
    option_int="-litpup"
fi
if [ $UPGRADE_OPTION == "install_no_upgrade" ]
then
    option_int="-ci"
fi
if [ $UPGRADE_OPTION == "litp_deploy" ]
then
    option_int="-litpc"
fi

echo "######################################"
echo "python autoinstall.py $option_int --rheliso=$RHEL_ISO --litpiso=$LITP_ISO_SP_LAST --install_type=$ENVIRONMENT --install_script=$LITP_INSTALL_SCRIPT --cluster_file=$LITP_DATAREG --server_http_location=$AI_HTTP_LOCATION --server_http_full_path_location=$AI_CLI_LOCATION --install_option=CLI --litp_upgrade=$LITP_ISO_PATH $os_patches $os_patches_upgrade $restore_option $rsyslog_option"
echo "######################################"
python autoinstall.py $option_int --rheliso=$RHEL_ISO --litpiso=$LITP_ISO_SP_LAST --install_type=$ENVIRONMENT --install_script=$LITP_INSTALL_SCRIPT --cluster_file=$LITP_DATAREG --server_http_location=$AI_HTTP_LOCATION --server_http_full_path_location=$AI_CLI_LOCATION --install_option=CLI --litp_upgrade=$LITP_ISO_PATH $os_patches $os_patches_upgrade $restore_option $rsyslog_option
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
rm -rf /home/admin/jenkins_litp/autoinstall/$JOB_NAME-$BUILD_NUMBER/

exit 0
