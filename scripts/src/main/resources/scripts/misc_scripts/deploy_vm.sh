#!/bin/bash

# COPYRIGHT Ericsson 2020
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.

# @since:     June 2020
# @author:    Diarmuid Leahy
# @summary:   Deploy a VM on a LITP vApp
# @result:    VM named fmmed1 is deployed on node1 and node2 as a parallel
#             clustered service across 192.168.1.100 and 192.168.1.200

# Prerequisites:
# This script must be called from the vApp gateway

ECHO='/bin/echo'
WGET='/usr/bin/wget'
SSH='/usr/bin/ssh'
SCP='/usr/bin/scp'
CHMOD='/bin/chmod'
CAT='/bin/cat'
RM='/bin/rm'
MKDIR='/bin/mkdir'
MD5SUM='/usr/bin/md5sum'
AWK='/bin/awk'
TR='/usr/bin/tr'
DIFF='/usr/bin/diff'
HEADING='\033[1;40m'
NC='\033[0m'
MODEL_SETUP_SCRIPT='/tmp/setup_model.sh'
BASE_IMAGE='https://arm1s11-eiffel004.eiffel.gic.ericsson.se:8443/nexus/content/groups/public/com/ericsson/nms/litp/taf/vm_test_image-1/1.0.1/vm_test_image-1-1.0.1.qcow2'
PATH_TO_TEST_IMAGE='/var/www/html/vm_test_image-1-1.0.1.qcow2'
IMAGES_PATH_ON_MS='/var/www/html/images/'
GENERATED_HASH_FILE='/tmp/generated_hash.md5'
USER='root'
MS='ms-1'

declare -a steps=(  create_ssh_key
                    get_base_image_and_checksum
                    check_base_image_integrity
                    create_image_host_directory
                    copy_base_image_and_checksum
                    create_setup_model_script
                    run_setup_model_script
                    create_vm_ssh_key
                    create_and_run_plan
                    wait_for_plan_complete
                    cleanup )
declare -a temp_files=( "${MODEL_SETUP_SCRIPT}" "${GENERATED_HASH_FILE}" )


function log {
    ${ECHO} -e "${HEADING}------------------------\n$*\n------------------------${NC}"
}

function create_ssh_key {
    log "Creating SSH Key for LMS ...."
    /usr/bin/expect << EOD
spawn ssh-copy-id root@ms-1
expect {
"*assword: "
}
send "@dm1nS3rv3r\r"
sleep 1
EOD
}

function get_base_image_and_checksum {
    log "Fetching base image and checksum ...."
    ${WGET} -O - --no-check-certificate "${BASE_IMAGE}" -O "${PATH_TO_TEST_IMAGE}"
    ${WGET} -O - --no-check-certificate "${BASE_IMAGE}.md5" -O "${PATH_TO_TEST_IMAGE}.md5"
}

function check_base_image_integrity {
    log "Checking md5 checksum of ${PATH_TO_TEST_IMAGE} ...."
    ${MD5SUM} "${PATH_TO_TEST_IMAGE}" | ${AWK} '{print $1;}' | ${TR} -d \\n > "${GENERATED_HASH_FILE}"
    if ! ${DIFF} "${PATH_TO_TEST_IMAGE}.md5" "${GENERATED_HASH_FILE}"; then
        log "Corruption detected in ${PATH_TO_TEST_IMAGE}. Exiting ...."
        exit 1
    fi
}

function create_image_host_directory {
    log "Creating /var/www/html/images directory on the LMS ...."
    ${SSH} -q -t "${USER}@${MS}" "${MKDIR} -p ${IMAGES_PATH_ON_MS}"
}

function copy_base_image_and_checksum {
    log "Copying base image and checksum to the LMS ...."
    ${SCP} "${PATH_TO_TEST_IMAGE}" "${USER}@${MS}:${IMAGES_PATH_ON_MS}"
    ${SCP} "${PATH_TO_TEST_IMAGE}.md5" "${USER}@${MS}:${IMAGES_PATH_ON_MS}"
}

function create_setup_model_script {
    log "Creating setup_model script ...."
    ${CAT} << EOF > "${MODEL_SETUP_SCRIPT}"
litp create -t vm-image -p /software/images/image1 -o name=fmmed source_uri="http://ms1/images/vm_test_image-1-1.0.1.qcow2"
litp create -t vm-service -p /software/services/fmmed1 -o service_name=fmmed1 image_name=fmmed cpus=2 ram=256M internal_status_check=on cleanup_command="/sbin/service fmmed1 force-stop"
litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/fmmed1 -o name=fmmed1 active=2 standby=0 node_list=n1,n2 online_timeout=600 offline_timeout=200
litp inherit -p /deployments/d1/clusters/c1/services/fmmed1/applications/fmmed -s /software/services/fmmed1
litp update -p /deployments/d1/clusters/c1/services/fmmed1/applications/fmmed -o hostnames=fmmed-node1,fmmed-node2
litp create -t vm-network-interface -p /software/services/fmmed1/vm_network_interfaces/net1 -o network_name=mgmt device_name=eth0 host_device=br0 ipaddresses=dhcp
litp update -p /deployments/d1/clusters/c1/services/fmmed1/applications/fmmed/vm_network_interfaces/net1 -o ipaddresses=192.168.1.100,192.168.1.200
litp create -t vm-alias -p /software/services/fmmed1/vm_aliases/ms-1_alias -o alias_names="ms-1" address=192.168.0.42
if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
fi
EOF
    ${CHMOD} 755 "${MODEL_SETUP_SCRIPT}"
}

function run_setup_model_script {
    log "Run setup_model script ...."
    ${SSH} -q "${USER}@${MS}" 'bash -s' < "${MODEL_SETUP_SCRIPT}"
}

function create_vm_ssh_key {
    log "Creating VM SSH Key ...."
    ${SSH} -q -t "${USER}@${MS}" 'litp create -t vm-ssh-key -p /software/services/fmmed1/vm_ssh_keys/vm_ssh_key1 -o ssh_key="$(cat ~/.ssh/id_rsa.pub)"'
}

function create_and_run_plan {
    log "Creating and running LITP Plan ...."
    ${SSH} -q -t "${USER}@${MS}" "litp create_plan && litp run_plan"
}

function wait_for_plan_complete {
    log "Waiting for LITP Plan to complete ...."
    sleep 5
    ${SSH} -q -t "${USER}@${MS}" 'plan_state=$(litp show -p /plans/plan -o state); while [ "${plan_state}" != "successful" ]; do sleep 5; litp show_plan --active; plan_state=$(litp show -p /plans/plan -o state); done'
}

function cleanup {
    log "Cleaning up ${temp_files[*]} ...."
    ${RM} -f "${temp_files[@]}"
}

function deploy_fmmed {
    for step in "${steps[@]}"; do
        $step || exit 1
    done
    log "fmmed1 now deployed on node1 and node2 at 192.168.1.100 & 192.168.1.200"
}

deploy_fmmed && exit 0
