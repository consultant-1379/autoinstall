#!/bin/bash

# COPYRIGHT Ericsson 2020
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.

# @since:     May 2020
# @author:    Laurence Canny
# @summary:   Build the litp_iso from the RHEL7_7 branch
#             You will be prompted for the vapp to which you want
#             to copy the iso to and it will be tagged as 'latest'
#             Copy and install the iso on to the vapp specified in the
#             -n option when invoking the script.
#             Run the regression tests and check for install errors

# Prerequisites:
# Tests must be called from gateway and gateway must have ssh access
# to ms. Script will setup passwordless ssh access.
# autoinstall and utils repos must be cloned

# Call the script as follows where 1803 has rhel7 iso installed but not litp
# Note we now use RHEL7_9 OS - but the branch name has not been changed
# rhel7_install/build_install_latestlitpiso.sh -n 1803 -b RHEL7_7

# For an overview of how the script works, read the following confluence page:
# https://confluence-oss.seli.wh.rnd.internal.ericsson.com/pages/
# viewpage.action?spaceKey=E1I&title=Running+build_install_latestlitpiso.sh+script

BASENAME=/bin/basename
VAPP_HOST=.athtem.eei.ericsson.se
MIN_SPACE_REQUIRED=2
SCRIPTNAME=$("${BASENAME}" "${0}")
GIT=/usr/bin/git
SED=/bin/sed
ECHO=/bin/echo
REG_TESTS_PATH=/root/installer_rhel7_test
INSTALL_ISO_OUTPUT=/root/iso_installer_output.txt
SSH_CMD="ssh -q"
installer_tests_path=autoinstall/scripts/src/main/resources/scripts/rhel7_install
pass=@dm1nS3rv3r

log_msg()
{
    MSG=$1
    CALLER="${FUNCNAME[1]}"
    NOW=$(date +%H.%M.%S)

    if [ "${CALLER}" = 'exit_on_error' ]
    then
        MKR='****'
    else
        MKR='----'
    fi
    ${ECHO} "${MKR} ${SCRIPTNAME}: ${NOW}: ${CALLER}: ${MSG} ${MKR}"
}

exit_on_error()
{
  ERROR_MSG=$1

  log_msg "Failure: ${ERROR_MSG}"
  exit 1
}

if [ "$#" -lt "1" ]; then
    log_msg "Must provide vapp number e.g. 1800 and optionally 'build_iso' $(
    )if you want to build the iso"
    exit_on_error ' usage : Must provide vapp number -n <ATVTS-NUMBER>'
fi

usage_msg()
{
   ${ECHO} "
   Usage: ${SCRIPTNAME}  { -hnb }

   Options:
      -h  : Display usage information.
      -n  : Host number e.g. 1803 - required
      -b  : build branch e.g. RHEL7_7 - optional

   "
   exit 0
}

copy_keys_to_vapp() {

    host=$1

    #copying ssh key
    log_msg "Copying ssh key to ${host}"
    ${SSH_CMD} root@"${ATVTS_VAPP}" -C  "/usr/bin/expect << EOD
spawn ssh-copy-id -i /root/.ssh/id_rsa.pub root@${host}
expect {
\"*assword: \"
}
send \"${pass}\r\"
sleep 1
EOD
"
}

check_ssh_access() {

    host=$1
    pub_key_path="${HOME}/.ssh/id_rsa"
    if [[ "${host}" != "ms1" ]]; then
        ${SSH_CMD} -o Batchmode=yes -o ConnectTimeout=5 -i "${pub_key_path}" root@"${host}" exit
        if [ $? -eq 0 ]; then
            log_msg "ssh keys already added for ${host}"
            return 0
        else
            exit_on_error "Couldn't ssh to host ${host}. run: ssh-copy-id root@${host}"
        fi
    else
        # Check passwordless ssh access to ms-1 from gateway
        response=$(${SSH_CMD} root@"${ATVTS_VAPP}" -C "${SSH_CMD} -o BatchMode=yes -o ConnectTimeout=5 root@ms-1 -C 'hostname' 2>&1")

        if [[ $response == *"ms1"* ]]; then
            log_msg "iso will be copied to ms on ${ATVTS_VAPP}"
        else
            log_msg "Couldn't ssh to ms-1 from gateway. running: ssh-copy-id ms-1"
            #copy_keys_to_vapp "${ATVTS_VAPP}"
            copy_keys_to_vapp "ms-1"
        fi
    fi
}

vapp_disk_size_check() {

    host=$1

    disk_size_check=$(${SSH_CMD} root@"${host}" -C "df -h /export/data | grep export | awk '{print \$4}'")
    disk_size=$("${ECHO}" "${disk_size_check}" | ${SED} 's/G//')

    if [[ "${disk_size}" -lt "${MIN_SPACE_REQUIRED}" ]]; then
        exit_on_error "Need to free up space on ${host}/export/data"
    else
        log_msg "sufficient space on ${ATVTS_VAPP} to store iso"
    fi
}

copy_iso() {

    host=$1

    if [[ "${host}" == "${ATVTS_VAPP}" ]]; then
        log_msg "Copy latest iso from ${LATEST_ISO_VAPP}"

        latest_iso=$(${SSH_CMD} root@${LATEST_ISO_VAPP} -C "readlink /export/data/RHEL7_7_files/isos/latest")

        ssh root@"${LATEST_ISO_VAPP}" -C "scp /export/data/RHEL7_7_files/isos/${latest_iso} root@${ATVTS_VAPP}:/export/data"

        lsofresult=$(${SSH_CMD} root@"${ATVTS_VAPP}" -C "lsof | grep ${latest_iso} | wc -l")
        while [[ ${lsofresult} -ne 0 ]]; do
            log_msg "copying file ${latest_iso} to ${ATVTS_VAPP}..."
            sleep 5
            lsofresult=$(${SSH_CMD} root@"${ATVTS_VAPP}" -C "lsof | grep ${latest_iso} | wc -l")
        done

        log_msg "copying file ${latest_iso} is finished"

        ${SSH_CMD} root@"${ATVTS_VAPP}" -C "ls /export/data/${latest_iso}"

    # Copy to 1778 and set 'latest' to new iso
    elif [[ "${host}" == "${LATEST_ISO_VAPP}" ]]; then
        new_iso=$("${BASENAME}" "${WORKSPACE}"/litp_rhel7_7/gen_iso/*.iso)

        scp "${WORKSPACE}/litp_rhel7_7/gen_iso/${new_iso}" root@${LATEST_ISO_VAPP}:/export/data/RHEL7_7_files/isos/
        ${SSH_CMD} root@${LATEST_ISO_VAPP} -C "cd /export/data/RHEL7_7_files/isos/; yes|rm latest; ln -s ${new_iso} latest"
    else
        log_msg "Copy latest iso to ms of gateway ${ATVTS_VAPP}"

        ${SSH_CMD} root@"${ATVTS_VAPP}" -C "scp /export/data/${latest_iso} root@ms-1:."

        ms_lsofresult=$(${SSH_CMD} root@"${ATVTS_VAPP}" -C "${SSH_CMD} root@ms-1 -C 'lsof | grep ${latest_iso} | wc -l'")
        while [[ ${ms_lsofresult} -ne 0 ]]; do
            log_msg "copying file ${latest_iso} to ms-1 on gateway ${ATVTS_VAPP}..."
            sleep 5
            ms_lsofresult=$(${SSH_CMD} root@"${ATVTS_VAPP}" -C "${SSH_CMD} root@ms-1 -C 'lsof | grep ${latest_iso} | wc -l'")
        done
        log_msg "Copying ${latest_iso} to ms-1 is finished"
        ${SSH_CMD} root@"${ATVTS_VAPP}" -C "${SSH_CMD} root@ms-1 -C 'ls /root/${latest_iso}'"
    fi
}

install_iso() {

    copy_iso "ms1"

    # Create mount point on ms and install iso (clean yum repos first)
    ${SSH_CMD} root@"${ATVTS_VAPP}" -C "${SSH_CMD} root@ms-1 -C 'rm -rf /var/www/html/3pp/*; rm -rf /var/www/html/litp/*; yum clean all'"
    ${SSH_CMD} root@"${ATVTS_VAPP}" -C "${SSH_CMD} root@ms-1 -C 'cd ~; mkdir -p /media/LITP_iso; mount -o loop ${latest_iso} /media/LITP_iso'"
    ${SSH_CMD} root@"${ATVTS_VAPP}" -C "${SSH_CMD} root@ms-1 -C 'sh /media/LITP_iso/install/installer.sh 2>&1 | tee /root/iso_installer_output.txt'"
    ${SSH_CMD} root@"${ATVTS_VAPP}" -C "${SSH_CMD} root@ms-1 -C 'umount /media/LITP_iso'"

}

check_for_changes() {

    HEADHASH=$(git rev-parse HEAD)
    UPSTREAMHASH=$(git rev-parse dRHEL7_7@{upstream})

    if [ "${HEADHASH}" != "${UPSTREAMHASH}" ]; then
        log_msg "Not up to date with origin. Run git pull to get changes"
        return 0
    else
        return 1
    fi

}

build_iso() {

    BRANCH=$1
    REPO="${WORKSPACE}"/utils/bash-utils

    # Build from the RHEL7_7 branch
    cd "${REPO}"
    # Build iso script is in ${REPO}
    # There is one branch only for the build iso script - dRHEL7_7
    log_msg "Checking out ${REPO} branch dRHEL7_7"
    "${GIT}" checkout dRHEL7_7

    # Check for changes in the utils dRHEL7_7 branch
    if ! check_for_changes; then
        git pull
        if [ $? -ne 0 ];then
            exit_on_error "git pull failed on ${BRANCH}"
        fi
    fi
    # -a option indicates branch to build from
    sh build_rhel7_litp_iso.sh -a "${BRANCH}" -b "${WORKSPACE}"/litp_rhel7_7/  2>&1 | tee ~/build-iso-output.txt
    build_rhel7_iso_pid=$!

    while kill -0 "${build_rhel7_iso_pid}"; do
        log_msg "building iso ..."
        sleep 5
    done
    log_msg "iso built"
    log_msg "${WORKSPACE}"/litp_rhel7_7/gen_iso/*.iso

}

run_regression_tests() {

   ${SSH_CMD} root@"${ATVTS_VAPP}" -C "[[ -f ${REG_TESTS_PATH}/verify_installer.sh && -f ${REG_TESTS_PATH}/common_libs.sh ]]"
   if [ $? -eq 0 ]; then
       ${SSH_CMD} root@"${ATVTS_VAPP}" -C "sh ${REG_TESTS_PATH}/verify_installer.sh"
       if [ $? -ne 0 ]; then
          log_msg "Regression run failed. Try running verify_installer.sh manually"
       fi
   else
       log_msg "Check out verify_installer.sh and update common_libs with sed command for ms etc"

       ${SSH_CMD} root@"${ATVTS_VAPP}" -C "mkdir -p ${REG_TESTS_PATH}"

       scp "${WORKSPACE}"/"${installer_tests_path}"/common_libs.sh root@"${ATVTS_VAPP}":"${REG_TESTS_PATH}"
       if [ $? -ne 0 ]; then
           log_msg "Cannot scp file - is repo cloned?"
       fi
       scp "${WORKSPACE}"/"${installer_tests_path}"/verify_installer.sh root@"${ATVTS_VAPP}":"${REG_TESTS_PATH}"
       if [ $? -ne 0 ]; then
           log_msg "Cannot scp file - is repo cloned?"
       fi
       # Update name and password details in common_libs to allow regression tests to run
       ${SSH_CMD} root@"${ATVTS_VAPP}" -C "${SED} -i 's/ms=.*/ms=ms-1/' ${REG_TESTS_PATH}/common_libs.sh"
       ${SSH_CMD} root@"${ATVTS_VAPP}" -C "${SED} -i 's/^pass=.*/pass=@dm1nS3rv3r/' ${REG_TESTS_PATH}/common_libs.sh"
       ${SSH_CMD} root@"${ATVTS_VAPP}" -C "sh ${REG_TESTS_PATH}/verify_installer.sh"
       if [ $? -ne 0 ]; then
          log_msg "Regression run failed. Try running verify_installer.sh manually"
       fi

   fi
}

check_logs() {

    #Check results.log for regression test failures
    ${SSH_CMD} root@"${ATVTS_VAPP}" -C "grep -i FAIL ${REG_TESTS_PATH}/results.log"
    if [ $? -eq 0 ]; then
       log_msg "Failures in regression test run. Please check the results.log"
    fi
    # Grep the installer logs for success and any errors
    ${SSH_CMD} root@"${ATVTS_VAPP}" -C "${SSH_CMD} root@ms-1 -C 'egrep -i -w \"error|fatal\" ${INSTALL_ISO_OUTPUT}'"
    if [ $? -eq 0 ]; then
       log_msg "Errors in installer output file. Please check ${INSTALL_ISO_OUTPUT}"
    fi
    # Check the installer output for LITP install success
    ${SSH_CMD} root@"${ATVTS_VAPP}" -C "${SSH_CMD} root@ms-1 -C 'grep \"LITP has been successfully installed\" ${INSTALL_ISO_OUTPUT}'"
    if [ $? -ne 0 ]; then
       log_msg "LITP Installation failed. Please check ${INSTALL_ISO_OUTPUT} and messages logs"
    fi
    # Check the messages logs for errors and warnings
    ${SSH_CMD} root@"${ATVTS_VAPP}" -C "${SSH_CMD} root@ms-1 -C 'egrep -i -w \"error|fatal|warning\" /var/log/messages > /dev/null'"
    if [ $? -eq 0 ]; then
       log_msg "Errors or warnings found in the messages logs. Please check /var/log/messages on ms"
    fi

}

if [ -z "${BASEDIR}" ]
then
   BASEDIR="${WORKSPACE}"
fi

while getopts "hn:b:" ARG
do
    case ${ARG} in
        h) usage_msg
           ;;
        n) ATVTS_NUM="${OPTARG}"
           ;;
        b) BRANCH="${OPTARG}"
           ;;
        *) "${ECHO}" "ERROR: Invalid option ${OPTARG} supplied"
           sleep 2
           usage_msg
    esac
done

ATVTS_VAPP=atvts${ATVTS_NUM}${VAPP_HOST}

if [ ! -z "${BRANCH}" ]; then
    while [ x"$answer" != "xy" ] && [ x"$answer" != "xY" ] ; do
        echo "Enter vapp host for storing iso in format 1234"
        echo -n "vapp host for storing iso: ";read ISO_VAPP
        echo
        echo You entered:
        echo -e "\t vapp host: ${ISO_VAPP}"
        echo -n "Is this correct? [y/n] "; read answer
    done
    if [ ! -z ${ISO_VAPP} ]; then
        LATEST_ISO_VAPP=atvts${ISO_VAPP}${VAPP_HOST}
    fi
    check_ssh_access "${LATEST_ISO_VAPP}"
    build_iso "${BRANCH}"
    vapp_disk_size_check "${LATEST_ISO_VAPP}"
    copy_iso "${LATEST_ISO_VAPP}"
fi
check_ssh_access "${ATVTS_VAPP}"
check_ssh_access "ms1"
vapp_disk_size_check "${ATVTS_VAPP}"
# If you have build a new iso and copied it to a vapp other than 1778 then
# install that iso. Otherwise get the latest from 1778 where latest isos
# are stored
if [ -z ${ISO_VAPP} ]; then
    LATEST_ISO_VAPP=atvts1778${VAPP_HOST}
fi
copy_iso "${ATVTS_VAPP}"
install_iso
run_regression_tests
check_logs
