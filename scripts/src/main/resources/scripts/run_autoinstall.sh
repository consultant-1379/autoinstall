#! /bin/bash

#python autoinstall.py -litpms http://10.44.84.100/iso/RHEL//rhel-server-6.4-x86_64-dvd.iso /home/admin/iso_files/2.x/ERIClitp_CXP9024296-1.0.232.iso singleblade /opt/ericsson/SIT/autoinstall/autoinstall_2.1/install_scripts/singleblade/deploy_singleblade.sh /opt/ericsson/SIT/autoinstall/autoinstall_2.1/clusterfiles/singleblade/10.44.86.46.sh http://10.^C.86.30/iso/autoinstall_jobs/ /home/admin/iso_files/autoinstall_jobs/

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR

if [ $RHEL_ISO_LINK == "LATEST" ]
then
    RHEL_ISO="http://10.44.84.100/iso/RHEL//rhel-server-6.6-x86_64-dvd.iso"
else
    RHEL_ISO="http://10.44.84.100/iso/RHEL//rhel-server-6.6-x86_64-dvd.iso"
fi

LITP_ISO_DIR="/home/admin/iso_files/2.x/"
if [ $INSTALL_ISO == "LATEST" ]
then
    iso_name=( $(ls -lrt $LITP_ISO_DIR | grep ERIClitp_ | grep .iso | sed -e 's/  / /g' | cut -d ' ' -f 9 | tail -1) )
    LITP_ISO_PATH="$LITP_ISO_DIR/$iso_name"
else
    LITP_ISO_PATH="$INSTALL_ISO"
fi

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

if [ $INSTALL_SCRIPT == "DEFAULT" ]
then
    if [ $ENVIRONMENT == "singleblade" ]
    then
        LITP_INSTALL_SCRIPT=( $( find /home/admin/jenkins_litp/autoinstall/$JOB_NAME-$BUILD_NUMBER | grep installscripts/singleblade/deploy_singleblade.sh) )
    fi
    if [ $ENVIRONMENT == "multiblade_local" ]
    then
        LITP_INSTALL_SCRIPT=( $( find /home/admin/jenkins_litp/autoinstall/$JOB_NAME-$BUILD_NUMBER | grep installscripts/multiblade_local/deploy_multiblade_local.sh) )
    fi
    if [ $ENVIRONMENT == "multiblade_san" ]
    then
        LITP_INSTALL_SCRIPT=( $( find /home/admin/jenkins_litp/autoinstall/$JOB_NAME-$BUILD_NUMBER | grep installscripts/multiblade_san/deploy_multiblade_san.sh) )
    fi
    if [ $ENVIRONMENT == "cloud" ]
    then
        LITP_INSTALL_SCRIPT=( $( find /home/admin/jenkins_litp/autoinstall/$JOB_NAME-$BUILD_NUMBER | grep installscripts/cloud/deploy_cloud.sh) )
    fi
else
    LITP_INSTALL_SCRIPT=( $(find /home/admin/jenkins_litp/autoinstall/$JOB_NAME-$BUILD_NUMBER | grep $INSTALL_SCRIPT) )
fi


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

AI_HTTP_LOCATION="http://10.44.86.30/litp_ks/autoinstall_jobs/"
#AI_HTTP_LOCATION="http://10.44.84.100/iso/autoinstall_jobs/"
AI_CLI_LOCATION="/home/admin/litp_ks/autoinstall_jobs/"

#if [ DEPLOYMENT_SCRIPT_TYPE=

#OS_PATCHES_PATH="/home/admin/iso_files/RHEL_Patches/RevH/ERICrhel_CXP9022639-2.1.3.tar.gz"
if [ $OS_PATCHES_TARBALL == "LATEST" ]
then
    #OS_PATCHES_PATH="/ISO/RHEL/RHEL_Patches/6.6_RevD/ERICrhel_CXP9026826-3.0.5.tar.gz"
    #OS_PATCHES_PATH="http://10.44.86.30/iso/RHEL_Patches/6.6_RevF//ERICrhel_CXP9026826-3.0.11.tar.gz"
    #OS_PATCHES_PATH="http://10.44.86.30/iso/RHEL_Patches/6.6_RevD/ERICrhel_CXP9026826-3.0.5.tar.gz"
    #OS_PATCHES_PATH="http://10.44.86.30/iso/RHEL/RHEL_Patches/6.6_RevG/ERICrhel_CXP9026826-3.0.5-1.tar.gz"
    #OS_PATCHES_PATH="http://10.44.86.30/iso/RHEL_Patches/6.6_RevH/ERICrhel_CXP9026826-3.0.14.tar.gz"
    #OS_PATCHES_PATH="http://10.44.86.30/iso/RHEL_Patches/6.6_RevJ/ERICrhel_CXP9026826-3.0.16.tar.gz"
    #OS_PATCHES_PATH="http://10.44.86.30/iso/RHEL_Patches/6.6_RevL/RHEL_OS_Patch_Set_CXP9026826-3.0.18.tar.gz"
    #OS_PATCHES_PATH="http://10.44.86.30/iso/RHEL_Patches/6.6_RevM/RHEL_OS_Patch_Set_CXP9026826-3.0.21.tar.gz"
    #OS_PATCHES_PATH="http://10.44.86.30/iso/RHEL_Patches/6.6_RevN/RHEL_OS_Patch_Set_CXP9026826-3.0.21-1.tar.gz"
    #OS_PATCHES_PATH="http://10.44.86.30/iso/RHEL_Patches/6.6_RevS/RHEL_OS_Patch_Set_CXP9026826-1.13.3.tar.gz"
    #OS_PATCHES_PATH="http://10.44.86.30/iso/RHEL_Patches/6.6_RevT/RHEL_OS_Patch_Set_CXP9026826-1.14.1.tar.gz"
    #OS_PATCHES_PATH="http://10.44.86.30/iso/RHEL_Patches/6.6_RevV/RHEL_OS_Patch_Set_CXP9026826-1.16.2.tar.gz"
    #OS_PATCHES_PATH="http://10.44.86.30/iso/RHEL_Patches/6.6_RevY/RHEL_OS_Patch_Set_CXP9026826-1.18.3.tar.gz"
    #OS_PATCHES_PATH="http://10.44.86.30/iso/RHEL_Patches/6.6_RevAB/RHEL_OS_Patch_Set_CXP9026826-1.21.1.tar.gz"
    #OS_PATCHES_PATH="http://10.44.86.30/iso/RHEL_Patches/6.6_RevAC/RHEL_OS_Patch_Set_CXP9026826-1.22.3.tar.gz"
    #OS_PATCHES_PATH="http://10.44.86.30/iso/RHEL_Patches/6.6_RevAD/RHEL_OS_Patch_Set_CXP9026826-1.23.4.tar.gz"
    #OS_PATCHES_PATH="http://10.44.86.14:8000/iso/RHEL_Patches/6.6_RevAE/RHEL_OS_Patch_Set_CXP9026826-1.24.3.tar.gz"
    #OS_PATCHES_PATH="http://10.44.235.150/iso/RHEL_Patches/6.6_RevAG/RHEL_OS_Patch_Set_CXP9026826-1.26.1.tar.gz"
    #OS_PATCHES_PATH="http://10.44.235.150/iso/RHEL_Patches/6.6_RevAJ/RHEL_OS_Patch_Set_CXP9026826-1.28.1.tar.gz"
    OS_PATCHES_PATH="http://10.44.235.150/iso/RHEL_Patches/6.6_RevAK/RHEL_OS_Patch_Set_CXP9034997-1.4.1.iso"

else
    OS_PATCHES_PATH="$OS_PATCHES_TARBALL"
fi

if [ $RETRY_FAILED_PLAN ] && $RETRY_FAILED_PLAN
then
    retry_plan="--retry-failed-plan"
else
    retry_plan=""
fi

if [ $REBOOT_PEER_NODES ] && $REBOOT_PEER_NODES
then
    reboot_peer_nodes="--reboot_peer_nodes_after_install"
else
    reboot_peer_nodes=""
fi

if [ $VCS_DEBUG_LOGGING ] && $VCS_DEBUG_LOGGING
then
    vcs_debug_logging="--initiate_vcs_debug_level_logging"
else
    vcs_debug_logging=""
fi

if [ ! -z $RETRY_FAILED_SCRIPT ]
then
    RETRY_SCRIPT_PLAN="--retry-failed-plan-script=$RETRY_FAILED_SCRIPT"
    echo "DEBUG: retry script: $RETRY_SCRIPT_PLAN"
else
    RETRY_SCRIPT_PLAN=""
fi

if [ $SKIP_PEER_NODE_PASSWD ] && $SKIP_PEER_NODE_PASSWD
then
    skip_peer_node_passwd="--skip_peer_node_passwd_setup"
else
    skip_peer_node_passwd=""
fi

if [ $SKIP_INSTALL_SNAPSHOT ] && $SKIP_INSTALL_SNAPSHOT
then
    skip_install_snapshot="--skip_install_snapshot"
else
    skip_install_snapshot=""
fi

if [ $SKIP_POST_DEPLOY_SNAPSHOT ] && $SKIP_POST_DEPLOY_SNAPSHOT
then
    skip_post_deploy_snapshot="--skip_post_deploy_snapshot"
else
    skip_post_deploy_snapshot=""
fi

if [ $EXPECT_LARGE_PLAN ] && $EXPECT_LARGE_PLAN
then
    expect_large_plan="--expect_large_plan"
else
    expect_large_plan=""
fi

if [ $PRE_XML_LOAD_SCRIPT ]
then
    pre_xml_load_script="--pre_xml_load_script=$PRE_XML_LOAD_SCRIPT"
else
    pre_xml_load_script=""
fi

if [ $LOCAL_TRUST_AUTH ] && $LOCAL_TRUST_AUTH
then
    local_trust_auth="--local_trust_auth"
else
    local_trust_auth=""
fi

echo ""
echo ""
echo "RUNNING AUTOINSTALL..."
echo ""
echo ""

if [ $INSTALL_METHOD == "full_install" ]
then
    if $OS_PATCHES
    then
        python autoinstall.py -ci --rheliso=$RHEL_ISO --litpiso=$LITP_ISO_PATH --install_type=$ENVIRONMENT --install_script=$LITP_INSTALL_SCRIPT --cluster_file=$LITP_DATAREG --server_http_location=$AI_HTTP_LOCATION --server_http_full_path_location=$AI_CLI_LOCATION --install_option=$DEPLOYMENT_SCRIPT_TYPE --with_os_patches=$OS_PATCHES_PATH $retry_plan $RETRY_SCRIPT_PLAN $reboot_peer_nodes $vcs_debug_logging $skip_peer_node_passwd $skip_install_snapshot $expect_large_plan $pre_xml_load_script $local_trust_auth $skip_post_deploy_snapshot
    else
        python autoinstall.py -ci --rheliso=$RHEL_ISO --litpiso=$LITP_ISO_PATH --install_type=$ENVIRONMENT --install_script=$LITP_INSTALL_SCRIPT --cluster_file=$LITP_DATAREG --server_http_location=$AI_HTTP_LOCATION --server_http_full_path_location=$AI_CLI_LOCATION --install_option=$DEPLOYMENT_SCRIPT_TYPE $retry_plan $RETRY_SCRIPT_PLAN $reboot_peer_nodes $vcs_debug_logging $skip_peer_node_passwd $skip_install_snapshot $expect_large_plan $pre_xml_load_script $local_trust_auth $skip_post_deploy_snapshot
    fi
    retval=( $(echo "$?") )
    if [ $retval -ne 0 ]
    then
        echo ""
        echo "!!!AUTOINSTALL FAILED!!!"
        rm -rf /tmp/autoinstall_lock/$NODEIP.lock
        echo ""
        exit 1
    fi
fi
if [ $INSTALL_METHOD == "litp_ms" ]
then
    if $OS_PATCHES
    then
        python autoinstall.py -litpms --rheliso=$RHEL_ISO --litpiso=$LITP_ISO_PATH --install_type=$ENVIRONMENT --install_script=$LITP_INSTALL_SCRIPT --cluster_file=$LITP_DATAREG --server_http_location=$AI_HTTP_LOCATION --server_http_full_path_location=$AI_CLI_LOCATION --install_option=$DEPLOYMENT_SCRIPT_TYPE --with_os_patches=$OS_PATCHES_PATH $retry_plan $RETRY_SCRIPT_PLAN $local_trust_auth
    else
        python autoinstall.py -litpms --rheliso=$RHEL_ISO --litpiso=$LITP_ISO_PATH --install_type=$ENVIRONMENT --install_script=$LITP_INSTALL_SCRIPT --cluster_file=$LITP_DATAREG --server_http_location=$AI_HTTP_LOCATION --server_http_full_path_location=$AI_CLI_LOCATION --install_option=$DEPLOYMENT_SCRIPT_TYPE $retry_plan $RETRY_SCRIPT_PLAN $local_trust_auth
    fi
    retval=( $(echo "$?") )
    if [ $retval -ne 0 ]
    then
        echo ""
        echo "!!!AUTOINSTALL FAILED!!!"
        rm -rf /tmp/autoinstall_lock/$NODEIP.lock
        echo ""
        exit 1
    fi
fi
if [ $INSTALL_METHOD == "litp_deploy" ]
then
    if $OS_PATCHES
    then
        python autoinstall.py -litpc --litpiso=$LITP_ISO_PATH --install_type=$ENVIRONMENT --install_script=$LITP_INSTALL_SCRIPT --cluster_file=$LITP_DATAREG --server_http_full_path_location=$AI_CLI_LOCATION --install_option=$DEPLOYMENT_SCRIPT_TYPE --with_os_patches=$OS_PATCHES_PATH $retry_plan $RETRY_SCRIPT_PLAN $reboot_peer_nodes $vcs_debug_logging $skip_peer_node_passwd $skip_install_snapshot $expect_large_plan $pre_xml_load_script $local_trust_auth $skip_post_deploy_snapshot
    else
        python autoinstall.py -litpc --litpiso=$LITP_ISO_PATH --install_type=$ENVIRONMENT --install_script=$LITP_INSTALL_SCRIPT --cluster_file=$LITP_DATAREG --server_http_full_path_location=$AI_CLI_LOCATION --install_option=$DEPLOYMENT_SCRIPT_TYPE $retry_plan $RETRY_SCRIPT_PLAN $reboot_peer_nodes $vcs_debug_logging $skip_peer_node_passwd $skip_install_snapshot $expect_large_plan $pre_xml_load_script $local_trust_auth $skip_post_deploy_snapshot
    fi
    retval=( $(echo "$?") )
    if [ $retval -ne 0 ]
    then
        echo ""
        echo "!!!AUTOINSTALL FAILED!!!"
        rm -rf /tmp/autoinstall_lock/$NODEIP.lock
        echo ""
        exit 1
    fi
fi
if [ $INSTALL_METHOD == "rhel_only" ]
then
    python autoinstall.py -rhel --rheliso=$RHEL_ISO --litpiso=$LITP_ISO_PATH --install_type=$ENVIRONMENT --install_script=$LITP_INSTALL_SCRIPT --cluster_file=$LITP_DATAREG --server_http_location=$AI_HTTP_LOCATION --server_http_full_path_location=$AI_CLI_LOCATION --install_option=$DEPLOYMENT_SCRIPT_TYPE $retry_plan $RETRY_SCRIPT_PLAN
    retval=( $(echo "$?") )
    if [ $retval -ne 0 ]
    then
        echo ""
        echo "!!!AUTOINSTALL FAILED!!!"
        rm -rf /tmp/autoinstall_lock/$NODEIP.lock
        echo ""
        exit 1
    fi
fi
if [ $INSTALL_METHOD == "litp_ms_deploy" ]
then
    if $OS_PATCHES
    then
        python autoinstall.py -rhellitp --litpiso=$LITP_ISO_PATH --install_type=$ENVIRONMENT --install_script=$LITP_INSTALL_SCRIPT --cluster_file=$LITP_DATAREG --server_http_full_path_location=$AI_CLI_LOCATION --install_option=$DEPLOYMENT_SCRIPT_TYPE --with_os_patches=$OS_PATCHES_PATH $retry_plan $RETRY_SCRIPT_PLAN $skip_install_snapshot $expect_large_plan $pre_xml_load_script $local_trust_auth $skip_post_deploy_snapshot
    else
        python autoinstall.py -rhellitp --litpiso=$LITP_ISO_PATH --install_type=$ENVIRONMENT --install_script=$LITP_INSTALL_SCRIPT --cluster_file=$LITP_DATAREG --server_http_full_path_location=$AI_CLI_LOCATION --install_option=$DEPLOYMENT_SCRIPT_TYPE $retry_plan $RETRY_SCRIPT_PLAN $skip_install_snapshot $expect_large_plan $pre_xml_load_script $local_trust_auth $skip_post_deploy_snapshot
    fi
    retval=( $(echo "$?") )
    if [ $retval -ne 0 ]
    then
        echo ""
        echo "!!!AUTOINSTALL FAILED!!!"
        rm -rf /tmp/autoinstall_lock/$NODEIP.lock
        echo ""
        exit 1
    fi
fi

echo "Removing lock file: /tmp/autoinstall_lock/$NODEIP.lock"
rm -rf /tmp/autoinstall_lock/$NODEIP.lock
rm -rf /opt/ericsson/SIT/CORRUPT/corrupt_environment_$FLAG_REMOVAL.flag
rm -rf  /home/admin/jenkins_litp/autoinstall/$JOB_NAME-$BUILD_NUMBER/

exit 0
