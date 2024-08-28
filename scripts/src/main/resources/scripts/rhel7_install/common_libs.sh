#!/bin/bash

# COPYRIGHT Ericsson 2020
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.

# @since:     March 2020
# @author:    Laurence Canny
# @summary:   Common libraries for verification scripts including
#             verify installer.sh and verify_kickstart.sh

HOST_PROP_PATH=/home/lciadm100/run_python_tests
ms=$(grep '^host.ms1.ip' "${HOST_PROP_PATH}"/host.properties | awk -F '=' '{print $2}')
pass=$(grep 'ms1.user.root.pass' "${HOST_PROP_PATH}"/host.properties | awk -F '=' '{print $2}')
peerpass=$(grep 'node1.user.litp-admin.pass' "${HOST_PROP_PATH}"/host.properties | awk -F '=' '{print $2}')
node1=$(grep 'node1.ip' "${HOST_PROP_PATH}"/host.properties | awk -F '=' '{print $2}')
node2=$(grep 'node2.ip' "${HOST_PROP_PATH}"/host.properties | awk -F '=' '{print $2}')
nodes="${node1} ${node2}"
RESULTS_FILE="${script_path}"/results.log
SSH_CMD="ssh -q"
testcase=$1
package_check="rpm -q"
grep_query="grep -s"
dummy=""

check_for_results_file() {
    now_timestamp=$(date +%s)

    if [ -f ${RESULTS_FILE} ];then
        mv ${RESULTS_FILE} ${RESULTS_FILE}_"${now_timestamp}"
    fi
}

run_tests() {
    # Run all tests
    if [ -z "$@" ]; then
        # -F display info about a func but only the name attributes
        test_funcs=$(declare -F | grep 'test_')
        IFS=$'\n'
        # IFS must be reset to default on call to function
        # as failing to restore the original value means any/all
        # subsequent text/string parsing & tokenising & iterating will fail
        # as IFS is a global variable - so needs to be unset after use
        for func in ${test_funcs}; do
            # "bash substring expansion" - strip 'declare test_'
            funcname="${func:11}"
            IFS=$' \t\n' $funcname
        done
        unset IFS
    # Run individual test
    else
        for test in "$@"
        do
            $test
        done
    fi
}

# Copy public key to ms to allow for passwordless ssh access
copy_id_to_ms() {
    pub_key_path="${HOME}/.ssh/id_rsa"

    ${SSH_CMD} -o Batchmode=yes -i "${pub_key_path}" root@"${ms}" exit
    if [ $? -eq 0 ]
    then
        echo "ssh keys already added"
        return 0
    else
        #copying ssh key
        echo ">>>>> Copying ssh key to $ms"
        /usr/bin/expect << EOD
spawn ssh-copy-id -i ${HOME}/.ssh/id_rsa.pub root@${ms}
expect {
"*assword: "
}
send "${pass}\r"
sleep 1
EOD

        echo "Testing the new key towards ${ms}"
        ssh -o Batchmode=yes -i "${pub_key_path}" root@"${ms}" exit
        res=$?
        if [ ${res} -eq 0 ]
        then
            echo "Successfully connected to ${ms}"
        else
            echo "Error: could not connect to ${ms}"
            exit 1
        fi
    fi
}

log_tc_header(){
    # FUNCNAME in bash returns name of function. [0] will give name of
    # function it's called in. [1] will give name of function that called it
    #echo ${FUNCNAME[0]}
    tc_name="${FUNCNAME[1]}"
    cardinal_number=${tc_name:5:+2}
    {
        echo "*****"
        echo "${cardinal_number}. ${tc_name}"
        echo "*****"
    } >> "${RESULTS_FILE}"
}

log_result() {
    RESULT=$1
    tc=$2

    if $RESULT; then
        echo "END. ${tc} - PASSED" >> "${RESULTS_FILE}"
    else
        echo "END. ${tc} - FAILED" >> "${RESULTS_FILE}"
    fi
}

update_results() {
    tc=$1

    grep -w "^${tc}" "${RESULTS_FILE}"
    if [ $? -eq 0 ];then
        testpass=false
    else
        testpass=true
    fi
    log_result "${testpass}" "${tc}"

}

assert_success() {

    cmd=$1
    values=$2
    conf_value=$3
    tc_name=$4

    values_array=($values)
    conf_value_array=($conf_value)
    # If there are is a list of values to be checked against
    # a list of provided configured values
    if [ ${#conf_value_array[@]} -gt 1 ]; then
        for ((val=0; val<${#values_array[@]};val++));
        do
            value=${values_array[${val}]}
            config_set=${conf_value_array[${val}]}

            ${SSH_CMD} "${ms}" "${cmd} ${value}.*${config_set} &>/dev/null || echo ${tc_name} ${value} is not configured as expected" >> "${RESULTS_FILE}"
        done
    # No configured value to check e.g. in the case of a service check
    elif [ -z "${conf_value}" ]; then
        ${SSH_CMD} "${ms}" "for value in ${values[*]};do ${cmd} \${value} &>/dev/null || echo ${tc_name} \${value} is not configured correctly; done" >> "${RESULTS_FILE}"
    else
        ${SSH_CMD} "${ms}" "for value in ${values[*]};do ${cmd} \${value} ${conf_value} &>/dev/null || echo ${tc_name} \${value} is not configured as expected in ${conf_value}; done" >> "${RESULTS_FILE}"
    fi
    update_results "${tc_name}"

}

assert_packages() {
    cmd=$1
    packages=$2
    installed=$3
    tc_name=$4

    if ! ${installed};then
        message="should be uninstalled"
        ${SSH_CMD} "${ms}" "for package in ${packages};do ${cmd} \${package} | grep -e \"not installed\" &>/dev/null || echo ${tc_name} \${package} package ${message}; done" >> "${RESULTS_FILE}"
    else
        message="should be on system"
        ${SSH_CMD} "${ms}" "for package in ${packages};do ${cmd} \${package} | grep -e \"not installed\" &>/dev/null && echo ${tc_name} \${package} package ${message}; done" >> "${RESULTS_FILE}"
    fi
    update_results "${tc_name}"
}

assert_value() {

    cmd=$1
    expected_results=$2
    config_element=$3

    # Check how many expected_results need to be checked
    # by checking number of strings provided
    expected_results_count=${expected_results//[^\"]/}

    # If more than one expected result to check
    if [ ${#expected_results_count} -gt 2 ];then
        for exp in ${expected_results};
        do
            result=$(${SSH_CMD} "${ms}" "${cmd}")
            #Remove quotes from result and expected results for string check
            result_format=$(echo "${result}" | tr -d '"')
            exp_format=$(echo "${exp}" | tr -d '"')

            if [[ "${result_format}" == "${exp_format}" ]]; then
                return 0
            fi
        done
        echo "Configuration: ${result} is incorrect for ${config_element}" >> "${RESULTS_FILE}"
        return 1
    else
        result=$(${SSH_CMD} "${ms}" "${cmd}")
        if [[ "${result}" != "${expected_results}" ]]; then
            echo "Configuration: ${result} is incorrect for ${config_element}" >> "${RESULTS_FILE}"
            return 1
        else
            return 0
        fi
    fi

}

assert_value_not_equal(){

    # This simple assertion was created for the purpose of verifying that
    # two given pids are not equal to each other
    # NOTE: assert_value could have been used for verification, however,
    # it provides misleading log output

    cmd=$1
    expected_results=$2
    config_element=$3

    result=$(${SSH_CMD} "${ms}" "${cmd}")
    if [[ "${result}" == "${expected_results}" ]]; then
        echo "Configuration: ${result} is incorrect for ${config_element}" >> "${RESULTS_FILE}"
        return 1
    else
        return 0
    fi
}


# Copy public key to peer nodes to allow for passwordless ssh access
copy_id_to_peer() {
    pub_key_path="${HOME}/.ssh/id_rsa"

    for node in ${nodes}; do

        ssh -o Batchmode=yes -i "${pub_key_path}" litp-admin@"${node}" exit
        if [ $? -eq 0 ]
        then
            echo "ssh keys already added"
        else
            echo ">>>>> Copying ssh key to $node"
            /usr/bin/expect << EOD
spawn ssh-copy-id -i ${HOME}/.ssh/id_rsa.pub litp-admin@${node}
expect {
"*assword: "
}
send "${peerpass}\r"
sleep 1
EOD

            echo "Testing the new key towards ${node}"
            ssh -o Batchmode=yes -i "${pub_key_path}" litp-admin@"${node}" exit
            res=$?
            if [ ${res} -eq 0 ]
            then
                echo "Successfully connected to ${node}"
            else
                echo "Error: could not connect to ${node}"
                exit 1
            fi
        fi
    done
}

# Check configuration on the peer nodes with the expected config value.
# If they don't match, update the results file to indicate as much.
assert_peer_value() {

    cmd=$1
    expected_results=$2
    config_element=$3

    for node in ${nodes}; do
        result=$(${SSH_CMD} litp-admin@"${node}" "${cmd}")
        if [[ "${result}" != "${expected_results}" ]]; then
            echo "Configuration: ${result} is incorrect for ${config_element} on ${node}" >> "${RESULTS_FILE}"
        fi
    done
}
