#!/bin/bash

# COPYRIGHT Ericsson 2020
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.

# @since:     March 2020
# @author:    Laurence Canny
# @summary:   Verify installer.sh has been applied correctly
#             3pps and litp plugins should be installed

# Prerequisites:
# Tests must be called from gateway and gateway must have ssh access
# to ms.
# The test framework (run_python_tests.tar.gz) must be uploaded to gateway

script=$(readlink -f "$0")
script_path=$(dirname "${script}")

. "${script_path}"/common_libs.sh

# Get the list of all LITP plugin repos: ldu list_all_repos (excluding ERIClitpmnlibvirt which is modelled)
# List of 3PP repos and packages: https://gerrit.ericsson.se/#/c/6900169/7/bash-utils/3pp_repo_data excluding modelled syslog
# packages: 'EXTRlitprsyslogelasticsearch_CXP9032173' 'EXTRlitprsysloggnutls_CXP9032174' 'EXTRlitprsyslogmmanon_CXP9032175'
#           'EXTRlitprsyslogmmfields_CXP9032176' 'EXTRlitprsyslogmmjsonparse_CXP9032177' 'EXTRlitprsyslogmmutf8fix_CXP9032178'
#           'EXTRlitprsyslogmysql_CXP9032179' 'EXTRlitprsyslogommail_CXP9032180' 'EXTRlitprsyslogpgsql_CXP9032181'
#           'EXTRlitprsyslogpmciscoios_CXP9032182' 'EXTRlitprsyslogsnmp_CXP9032184' 'EXTRlitprsyslogudpspoof_CXP9032185'
#           'EXTRlitplibfastjson_CXP9037929' is not installed and 'EXTRlitprsyslog' is replaced with rsyslog-8
#           installed as part of the OS install
#           PSS document states EXTRlitprubygemjson and EXTRlitprubygems should be replaced with packages now available on the OS
THREE_PPS=( 'EXTRlitpcelery_CXP9032834' 'EXTRlitpdaemoncontroller_CXP9031033' 'EXTRlitperlang_CXP9031333' \
            'EXTRlitpcobbler_CXP9030601' 'EXTRlitpkoan_CXP9030602' 'EXTRlitpfacter_CXP9031032' \
            'EXTRlitphiera_CXP9031338' 'EXTRlitpmcollective_CXP9031034' 'EXTRlitpmcollectiveclient_CXP9031352' \
            'EXTRlitpmcollectivecommon_CXP9031353' 'EXTRlitpmcollectivepuppetagent_CXP9031035' \
            'EXTRlitpmcollectivepuppetclient_CXP9031354' 'EXTRlitpmcollectivepuppetcommon_CXP9031355' \
            'EXTRlitpmcollectiveserviceagent_CXP9031039' 'EXTRlitpmcollectiveserviceclient_CXP9031356' \
            'EXTRlitpmcollectiveservicecommon_CXP9031357' 'EXTRlitppuppet_CXP9030746' 'EXTRlitppuppetdb_CXP9032594' \
            'EXTRlitppuppetdbterminus_CXP9032595' 'EXTRlitppuppetinifile_CXP9032828' 'EXTRlitppuppetmodules_CXP9030419' \
            'EXTRlitppuppetpostgresql_CXP9032827' 'EXTRlitppuppetserver_CXP9037406' 'EXTRlitppythonalembic_CXP9032831' \
            'EXTRlitppythonamqp_CXP9032835' 'EXTRlitppythonanyjson_CXP9032836' 'EXTRlitppythonbilliard_CXP9032837' \
            'EXTRlitppython_CXP9030604' 'EXTRlitppythoneditor_CXP9032833' 'EXTRlitppythonimportlib_CXP9032838' \
            'EXTRlitppythonkombu_CXP9032839' 'EXTRlitppythonmako_CXP9032832' 'EXTRlitppythonpsycopg2_CXP9032522' \
            'EXTRlitppythonsqlalchemy_CXP9032518' 'EXTRlitprabbitmqserver_CXP9031043' 'EXTRlitprack_CXP9031044' \
            'EXTRlitprake_CXP9031045' 'EXTRlitprubyaugeas_CXP9030750' 'EXTRlitprubygemstomp_CXP9031334' \
            'EXTRlitprubyrgen_CXP9031337' 'EXTRlitprubyshadow_CXP9030747' 'EXTRlitpsentinellicensemanager_CXP9031488' \
            'EXTRserverjre_CXP9035480' 'EXTRlitppuppetpuppetdb_CXP9032830', 'EXTRlitplibfastjson_CXP9037929' \
            'EXTRlitppythonrepozelru_CXP9041762', 'EXTRlitppythonroutes_CXP9041792' )

LITP_PLUGINS=( 'ERIClitpcfg_CXP9030421' 'ERIClitpcore_CXP9030418' 'ERIClitpcli_CXP9030420' 'ERIClitpvolmgrapi_CXP9030947' \
               'ERIClitpvolmgr_CXP9030946' 'ERIClitpbootmgrapi_CXP9030523' 'ERIClitpbootmgr_CXP9030515' 'ERIClitpnetworkapi_CXP9030514' \
               'ERIClitpnetwork_CXP9030513' 'ERIClitplibvirtapi_CXP9030548' 'ERIClitplibvirt_CXP9030547' \
               'ERIClitphosts_CXP9030589' 'ERIClitphostsapi_CXP9031075' 'ERIClitpbmcapi_CXP9030611' 'ERIClitpipmi_CXP9030612' \
               'ERIClitppackageapi_CXP9030582' 'ERIClitppackage_CXP9030581' 'ERIClitpyumapi_CXP9030586' 'ERIClitpyum_CXP9030585' \
               'ERIClitpcbaapi_CXP9030830' 'ERIClitpntpapi_CXP9030588' 'ERIClitpntp_CXP9030587' 'ERIClitpnas_CXP9030874' \
               'ERIClitpnasapi_CXP9030875' 'ERIClitpvcsapi_CXP9030871' 'ERIClitpvcs_CXP9030870' 'ERIClitplinuxfirewall_CXP9031105' \
               'ERIClitplinuxfirewallapi_CXP9031106' 'ERIClitplogrotate_CXP9030583' 'ERIClitplogrotateapi_CXP9030584' \
               'ERIClitpsysparams_CXP9031229' 'ERIClitpsysparamsapi_CXP9031230' 'ERIClitpdnsclient_CXP9031073' \
               'ERIClitpdnsclientapi_CXP9031074' 'ERIClitpdhcpservice_CXP9031640' 'ERIClitpdhcpserviceapi_CXP9031641' \
               'ERIClitplsbservice_CXP9031655' 'ERIClitpnassfs_CXP9030876' 'ERIClitpfilemanager_CXP9036910' \
               'ERIClitpfilemanagerapi_CXP9036916' )

removed_packages="python-virtinst chronyd"
get_acls="getfacl -p"

systemctl_start_cmd="systemctl start"
systemctl_stop_cmd="systemctl stop"
systemctl_restart_cmd="systemctl restart"
systemctl_condrestart_cmd="systemctl condrestart"
systemctl_disable_cmd="systemctl disable"
systemctl_enable_cmd="systemctl enable"

test_01_check_threepp_repo() {
    log_tc_header

    repo_path="/var/www/html"
    repos=("'${repo_path}/3pp_rhel7'" "'${repo_path}/litp'" "'${repo_path}/litp_plugins'")

    dir_check="test -d"
    tc_name="${FUNCNAME[0]}"

    assert_success "${dir_check}" "${repos[*]}" "${dummy}" "${tc_name}"

}

test_02_check_for_third_party_packages() {

    log_tc_header

    tc_name="${FUNCNAME[0]}"

    assert_packages "${package_check}" "${THREE_PPS[*]}" "true" "${tc_name}"
}

test_03_check_for_litp_plugins() {

    log_tc_header

    tc_name="${FUNCNAME[0]}"

    assert_packages "${package_check}" "${LITP_PLUGINS[*]}" "true" "${tc_name}"
}

test_04_check_for_litp_admin_user() {

    log_tc_header

    tc_name="${FUNCNAME[0]}"
    testpass=true
    user_check="getent passwd litp-admin | awk -F ':' '{ print \$1 }'"
    syslog_permissions_check="${get_acls} /var/log/messages | grep litp | awk -F \":\" '{print \$3}'"

    if ! assert_value "${user_check}" "litp-admin" "check for litp-admin user"; then
        testpass=false
    fi
    if ! assert_value "${syslog_permissions_check}" "r--" "litp-admin read access to syslog"; then
        testpass=false
    fi

    log_result "${testpass}" "${tc_name}"
}

test_05_check_for_service() {

    log_tc_header

    tc_name="${FUNCNAME[0]}"
    testpass=true
    puppet_service_check="systemctl -a | grep puppet.service | awk '{ print \$4 }'"
    puppetserver_service_check="systemctl -a | grep puppetserver.service | awk '{ print \$4 }'"
    puppetdb_service_check="systemctl -a | grep puppetdb.service | awk '{ print \$4 }'"
    httpd_service_check="systemctl -a | grep httpd.service | awk '{ print \$4 }'"

    if ! assert_value "${puppet_service_check}" "running" "puppet";then
        testpass=false
    fi
    if ! assert_value "${puppetserver_service_check}" "running" "puppetserver";then
        testpass=false
    fi
    if ! assert_value "${puppetdb_service_check}" "running" "puppetdb";then
        testpass=false
    fi
    if ! assert_value "${httpd_service_check}" "running" "httpd";then
        testpass=false
    fi
    log_result "${testpass}" "${tc_name}"

}

test_06_verify_package_removal() {

    log_tc_header

    tc_name="${FUNCNAME[0]}"

    assert_packages "${package_check}" "${removed_packages}" "false" "${tc_name}"

}

test_07_verify_rsyslog_updates() {

    log_tc_header

    tc_name="${FUNCNAME[0]}"
    syslog_conf="/etc/rsyslog.conf"
    testpass=true
    syslog_rate_interval_check="grep SystemLogRateLimitInterval ${syslog_conf} | awk '{print \$2}'"
    syslog_rate_burst_check="grep SystemLogRateLimitBurst ${syslog_conf} | awk '{print \$2}'"

    if ! assert_value "${syslog_rate_interval_check}" "0" "SystemLogRateLimitInterval"; then
        testpass=false
    fi

    if ! assert_value "${syslog_rate_burst_check}" "0" "SystemLogRateLimitInterval"; then
        testpass=false
    fi

    log_result "${testpass}" "${tc_name}"

}

test_08_verify_litp_cli() {

    log_tc_header

    tc_name="${FUNCNAME[0]}"

    testpass=true
    litp_cli_help_check="litp -h | grep \"Optional Arguments\""
    litp_cli_help_check2="litp -h | grep \"Actions:\""

    if ! assert_value "${litp_cli_help_check}" "Optional Arguments:" "LITP cli help check"; then
        testpass=false
    fi

    if ! assert_value "${litp_cli_help_check2}" "Actions:" "LITP cli help check"; then
        testpass=false
    fi
    log_result "${testpass}" "${tc_name}"

}

test_09_verify_yum_installs() {

    log_tc_header

    tc_name="${FUNCNAME[0]}"

    testpass=true
    yum_cmd="yum list all | grep "
    mesa_libGL_check="$yum_cmd mesa-libGL.x86_64 | awk '{print \$1}'"
    xorg_x11_xauth="$yum_cmd xorg-x11-xauth | awk '{print \$1}'"
    firefox="$yum_cmd firefox | awk '{print \$1}'"
    flash_plugin="$yum_cmd flash-plugin | awk '{print \$1}'"
    jre1_8="$yum_cmd jre1.8 | awk '{print \$1}'"
    dejavu_sans_fonts="$yum_cmd dejavu-sans-fonts | awk '{print \$1}'"

    if ! assert_value "${mesa_libGL_check}" "mesa-libGL.x86_64" "mesa-libGL"; then
        testpass=false
    fi

    if ! assert_value "${xorg_x11_xauth}" "xorg-x11-xauth.x86_64" "xorg-x11-xauth"; then
        testpass=false
    fi

    if ! assert_value "${firefox}" "firefox.x86_64" "firefox"; then
        testpass=false
    fi

    if ! assert_value "${flash_plugin}" "flash-plugin.x86_64" "flash-plugin"; then
        testpass=false
    fi

    if ! assert_value "${jre1_8}" "jre1.8.x86_64" "jre1.8"; then
        testpass=false
    fi

    if ! assert_value "${dejavu_sans_fonts}" "dejavu-sans-fonts.noarch" "dejavu-sans-fonts"; then
        testpass=false
    fi

    log_result "${testpass}" "${tc_name}"
}

test_10_verify_latest_jdk() {

    log_tc_header

    tc_name="${FUNCNAME[0]}"
    testpass=true
    latest_check_cmd="readlink -f /usr/java/latest | awk -F '\"' '{print \$1}' | awk -F '/' '{print \$4}'"
    java_version_check="java -version 2>&1 | head -n 1 | awk -F '\"' '{print \$2}'"

    jdk=$(${SSH_CMD} "${ms}" "${latest_check_cmd}")
    latest_version="${jdk:3}"

    if ! assert_value "${java_version_check}" "${latest_version}" "latest jre"; then
        testpass=false
    fi

    log_result "${testpass}" "${tc_name}"
}

test_11_check_selinux(){

    log_tc_header

    tc_name="${FUNCNAME[0]}"
    testpass=true

    selinux_status="sestatus | grep \"Current mode\" | awk '{print \$3}'"

    if ! assert_value "${selinux_status}" "enforcing" "selinux status"; then
        testpass=false
    fi

    log_result "${testpass}" "${tc_name}"

}

test_12_check_puppetdb_filesystems_acl(){

    log_tc_header

    tc_name="${FUNCNAME[0]}"
    testpass=true

    puppetdb_fs_acl_owner="${get_acls} /var/log/puppetdb | grep group | awk '{print \$3}'"
    puppetdb_fs_acl_permission="${get_acls} /var/log/puppetdb | grep user | awk -F \":\" '{print \$3}'"

    if ! assert_value "${puppetdb_fs_acl_owner}" "puppetdb" "ownership of puppet logs"; then
        testpass=false
    fi
    if ! assert_value "${puppetdb_fs_acl_permission}" "rwx" "puppetdb write permission for puppet logs"; then
        testpass=false
    fi
    log_result "${testpass}" "${tc_name}"

}


test_13_check_postgres_filesystems_acl(){

    log_tc_header

    tc_name="${FUNCNAME[0]}"
    testpass=true

    postgres_fs_acl_owner="${get_acls} /var/opt/rh | grep group | awk '{print \$3}'"
    postgres_fs_acl_permission="${get_acls} /var/opt/rh | grep user | awk -F \":\" '{print \$3}'"

    if ! assert_value "${postgres_fs_acl_owner}" "root" "ownership of postgres logs"; then
        testpass=false
    fi
    if ! assert_value "${postgres_fs_acl_permission}" "rwx" "postgres write permission for postgres logs"; then
        testpass=false
    fi

    log_result "${testpass}" "${tc_name}"

}


test_14_check_puppet_service_unit_files() {

    log_tc_header

    tc_name="${FUNCNAME[0]}"
    testpass=true
    systemd_path="/usr/lib/systemd/system/"
    local_bin_path="/usr/local/bin/"
    # NOTE: $1 returns permissions - $3 returns owner - $9 returns file path
    puppet_service_unit_file="ls -l ${systemd_path}puppet.service | awk '{print \$1 \$3 \$9}'"
    puppetserver_service_unit_file="ls -l ${systemd_path}puppetserver.service | awk '{print \$1 \$3 \$9}'"
    puppetdb_service_unit_file="ls -l ${systemd_path}puppetdb.service| awk '{print \$1 \$3 \$9}'"
    puppetctl_file="ls -l ${local_bin_path}puppetctl.sh | awk '{print \$1 \$3 \$9}'"

    if ! assert_value "${puppet_service_unit_file}" "-rw-r--r--.root${systemd_path}puppet.service" "puppet";then
        testpass=false
    fi
    if ! assert_value "${puppetserver_service_unit_file}" "-rw-r--r--.root${systemd_path}puppetserver.service" "puppetserver";then
        testpass=false
    fi
    if ! assert_value "${puppetdb_service_unit_file}" "-rw-r--r--.root${systemd_path}puppetdb.service" "puppetdb";then
        testpass=false
    fi
    if ! assert_value "${puppetctl_file}" "-rwxr-xr-x.root${local_bin_path}puppetctl.sh" "puppetctl";then
        testpass=false
    fi

    log_result "${testpass}" "${tc_name}"

}


test_15_check_puppet_sysV_files_are_not_present() {

    log_tc_header

    tc_name="${FUNCNAME[0]}"
    testpass=true
    sysV_path="/etc/rc.d/init.d/"
    puppet_sysV_file="[ -f ${sysV_path}puppet ] && echo 'Present' || echo 'Not present'"
    puppetserver_sysV_file="[ -f ${sysV_path}puppetserver ] && echo 'Present' || echo 'Not present'"
    puppetdb_sysV_file="[ -f ${sysV_path}puppetdb ] && echo 'Present' || echo 'Not present'"
    puppetmaster_sysV_file="[ -f ${sysV_path}puppetmaster ] && echo 'Present' || echo 'Not present'"

    if ! assert_value "${puppet_sysV_file}" "Not present" "puppet";then
        testpass=false
    fi
    if ! assert_value "${puppetserver_sysV_file}" "Not present" "puppetserver";then
        testpass=false
    fi
    if ! assert_value "${puppetdb_sysV_file}" "Not present" "puppetdb";then
        testpass=false
    fi
    if ! assert_value "${puppetmaster_sysV_file}" "Not present" "puppetdb";then
        testpass=false
    fi

    log_result "${testpass}" "${tc_name}"

}


test_16_check_puppet_services_start_correctly() {

    log_tc_header

    tc_name="${FUNCNAME[0]}"
    testpass=true
    puppet_service_check="${systemctl_start_cmd} puppet && systemctl -a | grep puppet.service | awk '{ print \$4 }'"
    puppetserver_service_check="${systemctl_start_cmd} puppetserver && systemctl -a | grep puppetserver.service | awk '{ print \$4 }'"
    puppetdb_service_check="${systemctl_start_cmd} puppetdb && systemctl -a | grep puppetdb.service | awk '{ print \$4 }'"

    if ! assert_value "${puppet_service_check}" "running" "puppet";then
        testpass=false
    fi
    if ! assert_value "${puppetserver_service_check}" "running" "puppetserver";then
        testpass=false
    fi
    if ! assert_value "${puppetdb_service_check}" "running" "puppetdb";then
        testpass=false
    fi
    log_result "${testpass}" "${tc_name}"

}


test_17_check_puppet_services_stop_correctly() {

    log_tc_header

    tc_name="${FUNCNAME[0]}"
    testpass=true
    puppet_service_check="${systemctl_stop_cmd} puppet && systemctl -a | grep puppet.service | awk '{ print \$4 }'"
    puppetserver_service_check="${systemctl_stop_cmd} puppetserver && systemctl -a | grep puppetserver.service | awk '{ print \$4 }'"
    puppetdb_service_check="${systemctl_stop_cmd} puppetdb && systemctl -a | grep puppetdb.service | awk '{ print \$4 }'"

    if ! assert_value "${puppet_service_check}" "dead" "puppet";then
        testpass=false
    fi
    if ! assert_value "${puppetserver_service_check}" "dead" "puppetserver";then
        testpass=false
    fi
    if ! assert_value "${puppetdb_service_check}" "failed" "puppetdb";then
        testpass=false
    fi
    log_result "${testpass}" "${tc_name}"

}


test_18_check_puppet_services_status_is_successful() {
    #To check if the status command works correctly - we first check the state of the given puppet services
    # then either start or stop the service - and check the output of status
    # if it changed from active to inactive (or vise versa) then status works correctly.

    log_tc_header

    tc_name="${FUNCNAME[0]}"
    testpass=true

    for service in "puppet" "puppetserver" "puppetdb"
    do
      puppet_service=$(${SSH_CMD} "${ms}" systemctl status $service | grep Active | awk '{print $2}')
      if [ "${puppet_service}" != "active" ]; then
        puppet_service_start="${systemctl_start_cmd} $service; sleep 10; systemctl status $service | grep Active | awk '{print \$2}'"
        if ! assert_value "${puppet_service_start}" "active" "${service}";then
          testpass=false
          break
        fi
      else
        puppet_service_stop="${systemctl_stop_cmd} $service; sleep 10; systemctl status $service | grep Active | awk '{print \$2}'"
        if ! assert_value "${puppet_service_stop}" "\"inactive\" \"failed\"" "${service}";then
          testpass=false
          break
        fi
      fi
    done

    log_result "${testpass}" "${tc_name}"

}


test_19_check_puppet_services_restart_correctly_from_inactive_state() {

    log_tc_header

    tc_name="${FUNCNAME[0]}"
    testpass=true
    puppet_service_check="${systemctl_restart_cmd} puppet && systemctl -a | grep puppet.service | awk '{ print \$4 }'"
    puppetserver_service_check="${systemctl_restart_cmd} puppetserver && systemctl -a | grep puppetserver.service | awk '{ print \$4 }'"
    puppetdb_service_check="${systemctl_restart_cmd} puppetdb && systemctl -a | grep puppetdb.service | awk '{ print \$4 }'"

    if ! assert_value "${puppet_service_check}" "running" "puppet";then
        testpass=false
    fi
    if ! assert_value "${puppetserver_service_check}" "running" "puppetserver";then
        testpass=false
    fi
    if ! assert_value "${puppetdb_service_check}" "running" "puppetdb";then
        testpass=false
    fi
    log_result "${testpass}" "${tc_name}"

}


test_20_check_puppet_services_condrestart_correctly_from_active_state() {

    log_tc_header

    tc_name="${FUNCNAME[0]}"
    testpass=true

    #The following gets PIDs from the already running services
    puppet_service_pid=$(${SSH_CMD} "${ms}" systemctl status puppet | grep -i 'Main PID' | awk '{print $3}')
    puppetserver_service_pid=$(${SSH_CMD} "${ms}" systemctl status puppetserver | grep -i 'Main PID' | awk '{print $3}')
    puppetdb_service_pid=$(${SSH_CMD} "${ms}" systemctl status puppetdb | grep -i 'Main PID' | awk '{print $3}')

    #The following condrestarts the services and get the ne PIDs
    ${SSH_CMD} "${ms}" ${systemctl_condrestart_cmd} puppet
    ${SSH_CMD} "${ms}" ${systemctl_condrestart_cmd} puppetserver
    ${SSH_CMD} "${ms}" ${systemctl_condrestart_cmd} puppetdb
    puppet_service_pid_after_condrestart="systemctl status puppet | grep -i 'Main PID' | awk '{print \$3}'"
    puppetserver_service_pid_after_condrestart="systemctl status puppetserver | grep -i 'Main PID' | awk '{print \$3}'"
    puppetdb_service_pid_after_condrestart="systemctl status puppetdb | grep -i 'Main PID' | awk '{print \$3}'"

    #We compare the old PIDs to the new ones - they should not be equal if the services restarted correctly
    if ! assert_value_not_equal "${puppet_service_pid_after_condrestart}" "${puppet_service_pid}" "puppet";then
        testpass=false
    fi

    if ! assert_value_not_equal "${puppetserver_service_pid_after_condrestart}" "${puppetserver_service_pid}" "puppetserver";then
       testpass=false
    fi

    if ! assert_value_not_equal "${puppetdb_service_pid_after_condrestart}" "${puppetdb_service_pid}" "puppetdb";then
        testpass=false
    fi

    log_result "${testpass}" "${tc_name}"

}


test_21_check_puppet_services_disable_correctly() {

    log_tc_header

    tc_name="${FUNCNAME[0]}"
    testpass=true
    puppet_service_check="${systemctl_disable_cmd} puppet && systemctl list-unit-files | grep puppet.service | awk '{print \$2}'"
    puppetserver_service_check="${systemctl_disable_cmd} puppetserver && systemctl list-unit-files | grep puppetserver.service | awk '{print \$2}'"
    puppetdb_service_check="${systemctl_disable_cmd} puppetdb && systemctl list-unit-files | grep puppetdb.service | awk '{print \$2}'"

    if ! assert_value "${puppet_service_check}" "disabled" "puppet";then
        testpass=false
    fi
    if ! assert_value "${puppetserver_service_check}" "disabled" "puppetserver";then
        testpass=false
    fi
    if ! assert_value "${puppetdb_service_check}" "disabled" "puppetdb";then
        testpass=false
    fi
    log_result "${testpass}" "${tc_name}"

}


test_22_check_puppet_services_enable_correctly() {

    log_tc_header

    tc_name="${FUNCNAME[0]}"
    testpass=true
    puppet_service_check="${systemctl_enable_cmd} puppet && systemctl list-unit-files | grep puppet.service | awk '{print \$2}'"
    puppetserver_service_check="${systemctl_enable_cmd} puppetserver && systemctl list-unit-files | grep puppetserver.service | awk '{print \$2}'"
    puppetdb_service_check="${systemctl_enable_cmd} puppetdb && systemctl list-unit-files | grep puppetdb.service | awk '{print \$2}'"

    if ! assert_value "${puppet_service_check}" "enabled" "puppet";then
        testpass=false
    fi
    if ! assert_value "${puppetserver_service_check}" "enabled" "puppetserver";then
        testpass=false
    fi
    if ! assert_value "${puppetdb_service_check}" "enabled" "puppetdb";then
        testpass=false
    fi
    log_result "${testpass}" "${tc_name}"

}


test_23_check_puppet_services_restart_correctly_from_active(){

    log_tc_header

    tc_name="${FUNCNAME[0]}"
    testpass=true

    #The following gets PIDs from the already running services
    puppet_service_pid=$(${SSH_CMD} "${ms}" systemctl status puppet | grep -i 'Main PID' | awk '{print $3}')
    puppetserver_service_pid=$(${SSH_CMD} "${ms}" systemctl status puppetserver | grep -i 'Main PID' | awk '{print $3}')
    puppetdb_service_pid=$(${SSH_CMD} "${ms}" systemctl status puppetdb | grep -i 'Main PID' | awk '{print $3}')

    #The following restarts the services and get the ne PIDs
    ${SSH_CMD} "${ms}" ${systemctl_restart_cmd} puppet
    ${SSH_CMD} "${ms}" ${systemctl_restart_cmd} puppetserver
    ${SSH_CMD} "${ms}" ${systemctl_restart_cmd} puppetdb
    puppet_service_pid_after_restart="systemctl status puppet | grep -i 'Main PID' | awk '{print \$3}'"
    puppetserver_service_pid_after_restart="systemctl status puppetserver | grep -i 'Main PID' | awk '{print \$3}'"
    puppetdb_service_pid_after_restart="systemctl status puppetdb | grep -i 'Main PID' | awk '{print \$3}'"

    #We compare the old PIDs to the new ones - they should not be equal if the services restarted correctly
    if ! assert_value_not_equal "${puppet_service_pid_after_restart}" "${puppet_service_pid}" "puppet";then
        testpass=false
    fi

    if ! assert_value_not_equal "${puppetserver_service_pid_after_restart}" "${puppetserver_service_pid}" "puppetserver";then
       testpass=false
    fi

    if ! assert_value_not_equal "${puppetdb_service_pid_after_restart}" "${puppetdb_service_pid}" "puppetdb";then
        testpass=false
    fi

    log_result "${testpass}" "${tc_name}"

}


test_24_check_for_service_on_peer_nodes() {

    log_tc_header
    copy_id_to_peer

    tc_name="${FUNCNAME[0]}"
    testpass=true
    puppet_service_check="systemctl -a | grep puppet.service | awk '{ print \$4 }'"

    if ! assert_peer_value "${puppet_service_check}" "running" "puppet";then
        testpass=false
    fi
    log_result "${testpass}" "${tc_name}"

}


test_25_check_no_child_processes_running_after_puppet_stop(){

    log_tc_header

    tc_name="${FUNCNAME[0]}"
    testpass=true
    ${SSH_CMD} "${ms}" ${systemctl_stop_cmd} puppet
    ${SSH_CMD} "${ms}" mco puppet runonce; sleep 3
    puppet_service_pid=$(${SSH_CMD} "${ms}" cat /var/run/puppet/agent.pid)

    if [ ! -z "${puppet_service_pid}" ]; then
        puppet_service_child_process_pid=$(${SSH_CMD} "${ms}" pgrep -P "${puppet_service_pid}")

        if [ ! -z "${puppet_service_child_process_pid}" ]; then
            ${SSH_CMD} "${ms}" ${systemctl_stop_cmd}; sleep 2
            puppet_service_child_process_pid_after_stop=$(${SSH_CMD} "${ms}" pgrep -P "${puppet_service_pid}")

            if [ -z "${puppet_service_child_process_pid_after_stop}" ];then
                testpass=false
            fi
        fi
    fi

    ${SSH_CMD} "${ms}" ${systemctl_start_cmd} puppet

    log_result "${testpass}" "${tc_name}"

}


copy_id_to_ms
check_for_results_file
run_tests "${testcase}"
