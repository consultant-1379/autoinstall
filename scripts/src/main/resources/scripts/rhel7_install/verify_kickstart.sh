#!/bin/bash

# COPYRIGHT Ericsson 2020
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.

# @since:     Jan 2020
# @author:    Laurence Canny
# @summary:   Verify ms-ks-network kickstart file
#             has been applied correctly.

# Prerequisites:
# Tests must be called from gateway and gateway must have ssh access
# to ms.
# The test framework (run_python_tests.tar.gz) must be uploaded to gateway

script=$(readlink -f "$0")
script_path=$(dirname "${script}")

. "${script_path}"/common_libs.sh

ifcfg_path_prefix="/etc/sysconfig/network-scripts/ifcfg-eth"

declare -A vol_details=(['lv_var']="10.00g" \
                        ['lv_swap']="2.00g" \
                        ['lv_var_opt_rh']="15.00g" \
                        ['lv_var_lib_puppetdb']="7.00g" \
                        ['lv_home']="12.00g" \
                        ['lv_var_log']="20.00g" \
                        ['lv_var_tmp']="35.00g" \
                        ['lv_var_www']="140.00g" \
                        ['lv_software']="150.00g" \
                        ['lv_root']="70.00g")
packages=('ruby' 'bind-chroot' 'ntp' 'dhcp' 'libpwquality' 'openssh-clients' 'policycoreutils-python' \
          'nfs-utils' 'ed' 'expect' 'pexpect' 'qemu-kvm' 'man-db' 'libxslt' 'device-mapper-multipath' \
          'device-mapper-multipath-libs' 'kpartx' 'libaio' 'ipmitool' 'bridge-utils' 'sysstat' 'procps-ng' \
          'bind-utils' 'lsof' 'ltrace' 'screen' 'strace' 'tcpdump' 'traceroute' 'vim-enhanced' 'file' 'at' \
          'util-linux' 'createrepo' 'tmpwatch' 'yum-plugin-versionlock' 'sos' 'rsyslog')

removed_packages="firewalld biosdevname chronyd NetworkManager NetworkManager-team NetworkManager-tui NetworkManager-config-server"

edit_volumes() {

    edit_vol=$1

    volume_names="${!vol_details[*]}"
    updated_vols="${volume_names//${edit_vol}/}"
    # Remove leading or trailing whitespace after filtering
    echo "${updated_vols}" | xargs echo -n

}

test_01_check_for_packages() {
    log_tc_header

    tc_name="${FUNCNAME[0]}"

    assert_packages "${package_check}" "${packages[*]}" "true" "${tc_name}"

}

test_02_check_fs_vols() {
    log_tc_header
    tc_name="${FUNCNAME[0]}"
    vol_check="lvs | grep "

    # Get the volumes from the key of the vol_details associative array
    vols="${!vol_details[*]}"
    # Get the sizes from the values of the vol_details associative array
    sizes="${vol_details[*]}"

    assert_success "${vol_check}" "${vols}" "${sizes}" "${tc_name}"

}

test_03_check_fs_types() {
    log_tc_header
    tc_name="${FUNCNAME[0]}"
    fs_types=$(printf 'xfs %.0s' {1..8}; echo)
    vol_check="df -Th | grep -w "

    vols=$(edit_volumes "lv_swap")

    assert_success "${vol_check}" "${vols}" "${fs_types}" "${tc_name}"

}

test_04_check_services() {
    log_tc_header
    tc_name="${FUNCNAME[0]}"

    testpass=true

    firewall_service_check="systemctl -a | grep firewalld.service | awk '{ print \$4 }'"
    iptables_service_check="systemctl -a | grep iptables.service | awk '{ print \$4 }'"
    ip6tables_service_check="systemctl -a | grep ip6tables.service | awk '{ print \$4 }'"
    ntpd_service_check="systemctl -a | grep ntpd.service | awk '{ print \$4 }'"
    rsyslog_service_check="systemctl -a | grep rsyslog.service | awk '{ print \$4 }'"

    # Possible return values include inactive or nothing if the service is removed
    if ! assert_value "${firewall_service_check}" "\"\" \"inactive\"" "firewalld";then
        testpass=false
    fi
    # ip(6)tables loads the firewall rules and then exits
    if ! assert_value "${iptables_service_check}" "exited"  "iptables";then
        testpass=false
    fi

    if ! assert_value "${ip6tables_service_check}" "exited" "ip6tables";then
        testpass=false
    fi
    if ! assert_value "${ntpd_service_check}" "running" "ntpd.service";then
        testpass=false
    fi
    if ! assert_value "${rsyslog_service_check}" "running" "rsyslog.service";then
        testpass=false
    fi
    log_result "${testpass}" "${tc_name}"
}

test_05_check_repos() {
    log_tc_header

    repos="/var/www/html/7.9"
    dir_check="test -d"
    tc_name="${FUNCNAME[0]}"

    assert_success "${dir_check}" "${repos}" "${dummy}" "${tc_name}"

}

test_06_check_resources() {
    log_tc_header
    tc_name="${FUNCNAME[0]}"

    testpass=true
    LITP_conf="grep -A1 LITP /etc/security/limits.conf | grep -v LITP | awk '{print \$2, \$3, \$4}'"
    daemon_core_conf="grep DAEMON_COREFILE_LIMIT /etc/sysconfig/init | awk -F \"=\" '{ print \$2 }'"
    ulimit_conf="grep ulimit /etc/profile | awk '{ print \$4 }'"

    if ! assert_value "${LITP_conf}" "soft core unlimited"  "LITP core file dump";then
        testpass=false
    fi

    if ! assert_value "${daemon_core_conf}" "unlimited"  "DAEMON_COREFILE_LIMIT";then
        testpass=false
    fi

    if ! assert_value "${ulimit_conf}" "unlimited"  "ulimit";then
        testpass=false
    fi

    log_result "${testpass}" "${tc_name}"
}

test_07_check_network_config() {
    log_tc_header
    tc_name="${FUNCNAME[0]}"

    testpass=true
    net_conf="grep NETWORKING /etc/sysconfig/network | awk -F \"=\" '{print \$2}'"
    host_conf="cat /etc/hostname"

    if ! assert_value "${net_conf}" "yes" "NETWORK configuration";then
        testpass=false
    fi
    if ! assert_value "${host_conf}" "ms1" "HOSTNAME configuration";then
        testpass=false
    fi

    log_result "${testpass}" "${tc_name}"
}

test_08_check_udev_rules() {
    log_tc_header
    tc_name="${FUNCNAME[0]}"

    udev_rules=/etc/udev/rules.d/70-persistent-net.rules
    # Gen10 test. As we are not supporting consistent naming on RH7
    # Network interface files will be renamed to net on gen10
    # before a service invoked script will rename them back to eth
    eth_conns="net0 net1 net2 net3 net4 net5 net6 net7"
    Gen10_check="dmidecode --type system | grep \"Product Name\" | awk -F ' ' '{print \$5}'"

    if assert_value "${Gen10_check}" "Gen10" "Gen10 system";then
        assert_success "${grep_query}" "${eth_conns}" "${udev_rules}" "${tc_name}"
    else
        testpass=true
        log_result "${testpass}" "${tc_name}"
    fi
}

test_09_check_interfaces() {
    log_tc_header

    file_check="test -f"
    tc_name="${FUNCNAME[0]}"
    eth_conns=6

    for eth in $(seq 0 ${eth_conns});
    do
        ifcfg_paths+="${ifcfg_path_prefix}${eth} "
    done

    assert_success "${file_check}" "${ifcfg_paths}" "${dummy}" "${tc_name}"
}

test_10_verify_eth0_ip() {
    log_tc_header
    tc_name="${FUNCNAME[0]}"

    testpass=true
    # This test is dependent on test_09 passing.
    # If it hasn't passed this test will exit
    egrep "test_09_check_interfaces.*PASSED" "${RESULTS_FILE}"
    if [ $? -ne 0 ];then
        echo "test_09_check_interfaces must pass before test_10_verify_eth0_ip can run" >> "${RESULTS_FILE}"
        echo "END. test_10_verify_eth0_ip - NOT RUN" >> "${RESULTS_FILE}"
        return 1
    fi

    bootipaddr_check="egrep \"IPADDR=|BOOTPROTO=dhcp|BOOTPROTO=\"dhcp\"\" ${ifcfg_path_prefix}0 | awk -F '.' '{ print \$1 }'"

    if ! assert_value "${bootipaddr_check}" "\"IPADDR=192\" \"IPADDR=10\" \"IPADDR=172\" \"BOOTPROTO=dhcp\" \"BOOTPROTO=\"dhcp\"\"" "ifcfg ip address"; then
        testpass=false
    fi

    log_result "${testpass}" "${tc_name}"
}

test_11_check_firmware_hw_OS_version() {
    log_tc_header
    tc_name="${FUNCNAME[0]}"

    testpass=true

    check_hw="dmidecode | grep \"Product Name\" | grep -i virtual | awk -F \" \" '{print \$3}'"
    hw_version="dmidecode | grep \"Product Name\" | awk '{print \$5}' | uniq"
    firmware_rev="dmidecode | grep \"Firmware Revision\" | awk -F ': ' '{print \$2}'"
    OS_version="awk '{print \$7}' /etc/redhat-release"

    # If running on a vApp (VMware) skip the check for h/w and Firmware version
    vm_check=$(${SSH_CMD} "${ms}" "${check_hw}")
    if [ "${vm_check}" == "VMware" ]; then
        testpass=true
        echo "Configuration: VMware - skip h/w and firmware checks" >> "${RESULTS_FILE}"
    else
        if ! assert_value "${hw_version}" "\"Gen8\" \"Gen9\" \"Gen10\"" "current h/w version ";then
            testpass=false
        fi
        if ! assert_value "${firmware_rev}" "\"2.55\" \"2.70\" \"1.43\"" "Firmware Revision";then
            testpass=false
        fi
    fi
    if ! assert_value "${OS_version}" "7.9" "Supported OS Version";then
        testpass=false
    fi
    log_result "${testpass}" "${tc_name}"
}

test_12_verify_package_removal() {
    log_tc_header

    tc_name="${FUNCNAME[0]}"

    assert_packages "${package_check}" "${removed_packages}" "false" "${tc_name}"
}

test_13_check_kernel_parameters() {
    log_tc_header

    tc_name="${FUNCNAME[0]}"

    sysctl="/etc/sysctl.conf"
    # The grep in assert_success() needs to ignore whitespace so we include the regex \s in each string
    sysctlSetting=("'net.ipv4.conf.default.rp_filter\s=\s0'" "'net.ipv4.conf.default.accept_source_route\s=\s0'" "'kernel.sysrq\s=\s0'" "'net.ipv4.conf.default.accept_source_route\s=\s0'" "'net.ipv4.tcp_syncookies\s=\s1'" "'net.bridge.bridge-nf-call-ip6tables\s=\s0'" "'net.bridge.bridge-nf-call-iptables\s=\s0'" "'net.bridge.bridge-nf-call-arptables\s=\s0'" "'kernel.msgmnb\s=\s65536'" "'kernel.msgmax\s=\s65536'" "'kernel.shmmax\s=\s68719476736'" "'kernel.shmall\s=\s4294967296'" "'net.ipv4.ip_forward\s=\s1'" "'kernel.exec-shield\s=\s1'" "'kernel.randomize_va_space\s=\s1'" "'kernel.core_uses_pid\s=\s1'" "'kernel.core_pattern\s=\score.%e.pid%p.usr%u.sig%s.tim%t'" "'fs.suid_dumpable\s=\s2'")

    assert_success "${grep_query}" "${sysctlSetting[*]}" "${sysctl}" "${tc_name}"
}

test_14_newvols_rw_check_torf156537() {

    log_tc_header
    tc_name="${FUNCNAME[0]}"
    data_file="test.log"
    new_vols="/var /var/opt/rh /var/lib/puppetdb /var/tmp"
    write_file="echo test_data > "

    ${SSH_CMD} "${ms}" "for vol in ${new_vols};do ${write_file} \${vol}/${data_file} || echo ${tc_name} Cannot write to \${vol}/${data_file}; done" >> "${RESULTS_FILE}"

    update_results "${tc_name}"

}

test_15_check_vol_group_torf156537() {

    log_tc_header
    tc_name="${FUNCNAME[0]}"
    vol_group_check="lvs | awk '{print \$1,\$2}' | grep "
    vol_group=$(printf 'vg_root %.0s' {1..9}; echo)
    # Get the volumes from the key of the vol_details associative array
    vols="${!vol_details[*]}"

    assert_success "${vol_group_check}" "${vols}" "${vol_group}" "${tc_name}"

}

test_16_check_vol_persistent_torf156537() {

    log_tc_header
    tc_name="${FUNCNAME[0]}"

    persistent_vol_check="findmnt --fstab | grep -w "

    vols=$(edit_volumes "lv_swap")

    assert_success "${persistent_vol_check}" "${vols}" "${dummy}" "${tc_name}"

}

test_17_check_total_vol_size_torf156537() {
    # This test confirms that the space allocated to volumes in the RHEL7 kickstart
    space_allocated=461.00

    # This test is dependent on test_02 passing.
    # So run test_02 and if it doesn't pass, exit test
    if [ -f "${RESULTS_FILE}" ]; then
        grep "test_02_check_fs_vols.*PASSED" "${RESULTS_FILE}"
        if [ $? -ne 0 ];then
            echo "test_02_check_fs_vols must pass before test_17 can run" >> "${RESULTS_FILE}"
            return 1
        else
            log_tc_header
            tc_name="${FUNCNAME[0]}"

            size_list="${vol_details[*]}"
            # Replace size denomination with addition
            sizes="${size_list//g/ +}"
            # Remove last addition sign
            size="${sizes%+*}"
            total_size=$(echo "${size}" | bc)

            if (( $(echo "${total_size} > ${space_allocated}" | bc -l) )); then
                testpass=false
            else
                testpass=true
            fi
            log_result "${testpass}" "${tc_name}"
        fi
    else
        # If test_02 has not already been run, call it
        test_02_check_fs_vols
        wait
        egrep "test_02_check_fs_vols.*PASSED" "${RESULTS_FILE}"
        if [ $? -ne 0 ];then
            log_tc_header
            echo "test_02_check_fs_vols must pass before test_17 can run" >> "${RESULTS_FILE}"
            echo "END. test_17_check_total_vol_size_torf156537 - NOT RUN" >> "${RESULTS_FILE}"
            return 1
        else
            log_tc_header
            tc_name="${FUNCNAME[0]}"

            size_list="${vol_details[*]}"
            # Replace size denomination with addition
            sizes="${size_list//g/ +}"
            # Remove last addition sign
            size="${sizes%+*}"
            total_size=$(echo "${size}" | bc)

            if (( $(echo "${total_size} > ${space_allocated}" | bc -l) )); then
                testpass=false
            else
                testpass=true
            fi
            log_result "${testpass}" "${tc_name}"
        fi
    fi

}

test_18_check_Gen10_ethif_updated() {

    ###############
    # TORF-415032 #
    ###############
    log_tc_header
    tc_name="${FUNCNAME[0]}"
    eth_conns=7
    hwaddr_grep="grep -s ^HWADDR="
    ifcfg_paths=""

    for (( eth=0 ; eth<="${eth_conns}" ; eth++ ))
    do
        ifcfg_paths+="${ifcfg_path_prefix}${eth} "
    done

    # Gen10 test
    Gen10_check="dmidecode --type system | grep 'Product Name' | awk '{print \$5}'"

    if assert_value "${Gen10_check}" "Gen10" "Gen10 system";then
        assert_success "${hwaddr_grep}" "${ifcfg_paths}" "${dummy}" "${tc_name}"
    else
        echo "END. test_18_check_Gen10_ethif_updated - NOT RUN" >> "${RESULTS_FILE}"
        return 1
    fi
}

test_19_verify_boot_partition_size() {

    ###############
    # TORF-481391 #
    ###############
    log_tc_header
    tc_name="${FUNCNAME[0]}"

    testpass=true

    boot_partition_check="lsblk | grep boot | awk '{ print \$4 }'"

    # Possible return values include inactive or nothing if the service is removed
    if ! assert_value "${boot_partition_check}" "1000M" "boot partition";then
        testpass=false
    fi
    log_result "${testpass}" "${tc_name}"
}

copy_id_to_ms
check_for_results_file
run_tests "${testcase}"
