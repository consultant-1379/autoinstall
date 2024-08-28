#!/usr/bin/env python

'''
COPYRIGHT Ericsson 2019
The copyright to the computer program(s) herein is the property of
Ericsson Inc. The programs may be used and/or copied only with written
permission from Ericsson Inc. or in accordance with the terms and
conditions stipulated in the agreement/contract under which the
program(s) have been supplied.

@since:     October 2012
@author:    Brian Kelly
@summary:   Install script
'''

import signal
import sys
import time
import os
import setup_env
from litp_deploy.litp_setup_nodes import SetupLitpNodes
from litp_deploy.litp_sanity_check import LitpSanityCheck
from litp_deploy.litp_deploy import DeployLitp
from litp_clean.litp_clean_env import CleanLitp
from litp_deploy.litp_peer_node_reboot import PeerNodeReboot
from litp_expand.litp_expand import ExpandLitp
from litp_backup_restore.litp_backup_restore import backupRestoreLitp
from create_restore_snapshot.create_restore_snapshot import CreateRestoreSnapshot
from litp_upgrade.litp_upgrade import UpgradeLitp
from litp_install.install_litp_iso import InstallLitpMs
from litp_install.litp_user_setup import LITPMsUserUpdate
from ilo_install.ilo_install_rhel import InsertIso, InstallIso
from litp_install_os_patch.litp_install_os_patch import InstallOSPatch
from common_platform_files.common_methods import NodeConnect
import common_platform_files.constants as constants
from litp_backup_restore.litp_peer_node_reboot_restore import PeerNodeRebootRestore
from litp_deploy.litp_vcs_debug_on import InitiateVCSDebug
from collect_logs.collect_logs import CollectLogs

class AIRunner():
    def __init__(
            self, ai_option, rhel_iso, litp_iso, install_type,
            install_script, cluster_file, server_http_location,
            server_http_full_path_location, jenkins_job_id, install_option,
            ipmi_tool_location, redfish_tool_location, os_patches,
            os_patches_path, litp_upgrade, litp_upgrade_iso,
            os_patches_upgrade, os_patches_path_upgrade, restore_upgrade,
            expand_script, restore_expand, retry_plan, fail_script,
            update_rsyslog8, reboot_peer_nodes, vcs_debug_logging,
            run_old_cleanup, skip_peer_node_passwd, skip_install_snapshot,
            skip_upgrade_snapshot, expect_large_plan, pre_xml_script,
            local_trust_auth, monitor_script_path, skip_post_deploy_snapshot):
        """
        CLASS TO GET KS FILE FROM ISO
        """
        #By default connect NodeConnect connects to local machine
        self.utilfile = NodeConnect()

        ##This block finds out where it is running
        stdout, stderr, retc = self.utilfile.run_command_local("ip route get 1 | awk '{print $7;exit}'", logs=False)
        if stdout == [] or stderr != [] or retc != 0:
            print ">> ERROR: CANNOT GET HOST IPADDRESS"
        gateway_ip = stdout[0]
        print "Host ip address is %s" % gateway_ip

        ##If on .30 use .30 password otherwise use cloud password setting
        if stdout[0] == "10.44.86.30":
            self.utilfile = NodeConnect(constants.SERVERIP, constants.SERVERUSER, \
                        constants.SERVERPASSWD)
        else:
            self.utilfile = NodeConnect(constants.SERVERIP, constants.SERVERUSER, \
                        constants.SERVERPASSWD_CDB)

        # NEW OBJECT
        self.ai_params = dict()
        self.ai_params["AI_OPTION"] = ai_option
        self.ai_params["RHEL_ISO"] = rhel_iso
        self.ai_params["LITP_ISO"] = litp_iso
        self.ai_params["INSTALL_TYPE"] = install_type
        self.ai_params["INSTALL_SCRIPT"] = install_script
        self.ai_params["CLUSTER_FILE"] = cluster_file
        self.ai_params["SERVER_HTTP_LOCATION"] = server_http_location
        self.ai_params["SERVER_HTTP_LOCATION_PATH"] = server_http_full_path_location
        self.ai_params["JENKINS_JOB_ID"] = jenkins_job_id
        self.ai_params["INSTALL_OPTION"] = install_option
        self.ai_params["UPDATE_RSYSLOG8"] = update_rsyslog8
        self.ai_params["OS_PATCHES"] = os_patches
        self.ai_params["OS_PATCHES_PATH"] = os_patches_path
        self.ai_params["OS_PATCHES_UPGRADE"] = os_patches_upgrade
        self.ai_params["OS_PATCHES_PATH_UPGRADE"] = os_patches_path_upgrade
        self.ai_params["LITP_UPGRADE"] = litp_upgrade
        self.ai_params["LITP_UPGRADE_ISO"] = litp_upgrade_iso
        self.ai_params["IPMI_TOOL_LOCATION"] = ipmi_tool_location
        self.ai_params["REDFISH_TOOL_LOCATION"] = redfish_tool_location
        self.ai_params["RESTORE_UPGRADE"] = restore_upgrade
        self.ai_params["EXPAND_SCRIPT"] = expand_script
        self.ai_params["RESTORE_EXPAND"] = restore_expand
        self.ai_params["RETRY_PLAN"] = retry_plan
        self.ai_params["FAIL_SCRIPT"] = fail_script
        self.ai_params["REBOOT_PEER_NODES"] = reboot_peer_nodes
        self.ai_params["VCS_DEBUG_LOGGING"] = vcs_debug_logging
        self.ai_params["RUN_OLD_CLEANUP"] = run_old_cleanup
        self.ai_params["SKIP_PEER_NODE_PASSWD"] = skip_peer_node_passwd
        self.ai_params["SKIP_INSTALL_SNAPSHOT"] = skip_install_snapshot
        self.ai_params["SKIP_UPGRADE_SNAPSHOT"] = skip_upgrade_snapshot
        self.ai_params["SKIP_POST_DEPLOY_SNAPSHOT"] = skip_post_deploy_snapshot
        self.ai_params["EXPECT_LARGE_PLAN"] = expect_large_plan
        self.ai_params["PRE_XML_LOAD_SCRIPT"] = pre_xml_script
        self.ai_params["GW_IP"] = gateway_ip
        self.ai_params["MS_ILO_IP"] = None
        self.ai_params["MS_ILO_USER"] = None
        self.ai_params["MS_ILO_PASSWORD"] = None
        self.ai_params["MS_IP"] = None
        self.ai_params["MS_POWEROFF_IP"] = None
        self.ai_params["MS_SUBNET"] = None
        self.ai_params["MS_GATEWAY"] = None
        self.ai_params["ISO_FILE"] = None
        self.ai_params["INSTALL_FILE"] = None
        self.ai_params["CLUSTER_FILE_NAME"] = None
        self.ai_params["EXPAND_FILE"] = None
        self.ai_params["PRE_XML_LOAD_FILE"] = None
        self.ai_params["NODE_HOSTNAMES"] = None
        self.ai_params["NODE_IPS"] = None
        self.ai_params["NODE_ILO_IPS"] = None
        self.ai_params["MS_BLADE_TYPE"] = None
        self.ai_params["MS_VLAN"] = None
        self.ai_params["MS_HOSTNAME"] = None
        self.ai_params["MS_INSTALL_MAC_ADDRESS"] = None
        self.ai_params["MS_INSTALL_NIC"] = None
        self.ai_params["LOCK_FILE"] = None
        self.ai_params["KS_FILE"] = None
        self.ai_params["KS_FILE_PATH"] = None
        self.ai_params["AUTOINSTALL_DIR"] = None
        self.ai_params["SANITY_CHECK_IPS"] = None
        self.ai_params["SFS_FILESYSTEM_CLEANUP"] = None
        self.ai_params["SFS_SNAPSHOT_CLEANUP"] = None
        self.ai_params["EXPANSION_HOSTNAMES"] = None
        self.ai_params["EXPANSION_NODE_IPS"] = None
        self.ai_params["EXPANSION_NODE_ILO_IPS"] = None
        self.ai_params["INSTALL_RUN_SECOND_SCRIPT"] = None
        self.ai_params["LOCAL_TRUST_AUTH"] = local_trust_auth
        self.ai_params["MONITOR_SCRIPT"] = monitor_script_path

        self.ai_status_file = 'ai_status.txt'

    def print_ai_info(self):
        """
        FUNCTION THAT PERFORMS THE MOUNT TO RETREIVE THE KS FILE
        """
        print "#########################################################"
        print ">> INFO: ARGUMENTS SUPPLIED TO AUTOINSTALL"
        print "#########################################################"
        print ""
        print "RHEL ISO: ", self.ai_params["RHEL_ISO"]
        print "LITP ISO: ", self.ai_params["LITP_ISO"]
        if self.ai_params["OS_PATCHES"]:
            print "OS PATCHES: ", self.ai_params["OS_PATCHES_PATH"]
        print "INSTALL TYPE: ", self.ai_params["INSTALL_TYPE"]
        print "CLUSTER FILE: ", self.ai_params["CLUSTER_FILE"]
        print "INSTALL SCRIPT: ", self.ai_params["INSTALL_SCRIPT"]
        print "SERVER HTTP LOCATION: ", self.ai_params["SERVER_HTTP_LOCATION"]
        print "SERVER HTTP PATH LOCATION: ", self.ai_params["SERVER_HTTP_LOCATION_PATH"]
        print "INSTALL OPTION: ", self.ai_params["INSTALL_OPTION"]
        print "USING LOCAL TRUST AUTHENTICATION: ", self.ai_params["LOCAL_TRUST_AUTH"]

        ##If the same patches are on the upgraded system to the base install
        ##don't upgrade patches post install
        if self.ai_params["OS_PATCHES_PATH"] == self.ai_params["OS_PATCHES_PATH_UPGRADE"]:
            self.ai_params["OS_PATCHES_UPGRADE"] = False

        if self.ai_params["LITP_UPGRADE"]:
            print "LITP ISO TO UPGRADE TO: ", self.ai_params["LITP_UPGRADE_ISO"]
        if self.ai_params["OS_PATCHES_UPGRADE"]:
            print "OS PATCHES TO UPGRADE TO: ", self.ai_params["OS_PATCHES_PATH_UPGRADE"]
        if self.ai_params["PRE_XML_LOAD_SCRIPT"]:
            print "PRE XML LOAD SCRIPT: ", self.ai_params["PRE_XML_LOAD_SCRIPT"]
        if self.ai_params["UPDATE_RSYSLOG8"]:
            print "RSYSLOG8 OPTION CHOSEN TO BE INSTALLED BEFORE UPGRADE"
        if self.ai_params["EXPAND_SCRIPT"] != None:
            print "EXPAND SCRIPT: ", self.ai_params["EXPAND_SCRIPT"]
        if self.ai_params["RESTORE_UPGRADE"]:
            print "RESTORE UPGRADE OPTION CHOSEN"
        if self.ai_params["RESTORE_EXPAND"]:
            print "RESTORE EXPAND OPTION CHOSEN"
        if self.ai_params["RETRY_PLAN"]:
            print "FAILED PLAN RETRY CHOSEN"
        if self.ai_params["FAIL_SCRIPT"] != None:
            print "ON FAILURE OF PLAN, THE FOLLOWING SCRIPT WILL BE EXECUTED: ", self.ai_params["FAIL_SCRIPT"]
        if self.ai_params["REBOOT_PEER_NODES"]:
            print "REBOOT PEER NODES AFTER SUCCESSFUL INSTALL OPTION SELECTED"
        if self.ai_params["VCS_DEBUG_LOGGING"]:
            print "INITIATE VCS DEBUG LEVEL LOGGING AFTER INSTALL OPTION SELECTED"
        if self.ai_params["SKIP_PEER_NODE_PASSWD"]:
            print "SKIP PEER NODE PASSWORD SETUP OPTION SELECTED"
        if self.ai_params["SKIP_INSTALL_SNAPSHOT"]:
            print "SKIP CREATION OF INSTALL SNAPSHOT OPTION GIVEN"
        if self.ai_params["SKIP_UPGRADE_SNAPSHOT"]:
            print "SKIP CREATION OF UPGRADE SNAPSHOT OPTION GIVEN"
        if self.ai_params["SKIP_POST_DEPLOY_SNAPSHOT"]:
            print "SKIP CREATION OF POST DEPLOY SNAPSHOT OPTION GIVEN"
        if self.ai_params["EXPECT_LARGE_PLAN"]:
            print "EXPECT LARGE INSTALL PLAN OPTION GIVEN"
        print ""

    def setupai(self):
        """
        Setup autoinstall paramaters
        """
        print ""
        print "#########################################################"
        print ">> INFO: RUNNING CHECKS ON SUPPLIED ARGUMENTS"
        print "#########################################################"
        print ""
        # CHECK ALL SETUP VARIABLES ARE CORRECT
        envsetup = setup_env.setUpAI(self.ai_params)
        self.ai_params = envsetup.create_setup()

    def create_lockfile(self):
        """
        Create a lockfile so same node is not autoinstalled at the same time
        """
        ##create lock file at start of ai so same node cannot be installed again
        # THIS IS AIMED AT .30 JENKINS ISSUES
        print ""
        self.ai_params["LOCK_FILE"] = "%s/%s.lock" % (constants.LOCK_FILE_PATH, self.ai_params["MS_IP"])

    def cleanupai(self, collect_logs=True):
        """
        cleanup AI after itself
        """
        print ""
        print "#########################################################"
        print ">> INFO: AUTOINSTALL CLEANUP"
        print "#########################################################"
        print ""
        if collect_logs:
            print "Sleeping 120 seconds to collect more logs related to failure event"
            time.sleep(120)
            self.collect_logs()

        print "Debug..... Removing lock file for %s" % self.ai_params["MS_IP"]
        cmd = "rm -rf %s" % self.ai_params["LOCK_FILE"]
        stdout, stderr, retc = self.utilfile.run_command_local(cmd, logs=False)
        if stdout != [] or stderr != [] or retc != 0:
            print ">> ERROR: CANNOT REMOVE LOCK FILE"
        print "Removing autoinstall directory: %s" % self.ai_params["AUTOINSTALL_DIR"]
        cmd = "rm -rf %s" % self.ai_params["AUTOINSTALL_DIR"]
        stdout, stderr, retc = self.utilfile.run_command_local(cmd, logs=False)
        if stdout != [] or stderr != [] or retc != 0:
            print ">> ERROR: CANNOT REMOVE AI DIRECTORY"
        print ""

        ##Fail any in progress task
        self.set_current_task_failed()

    def collect_logs(self):
        print "Collecting logs from MS at {0} and all nodes".format(self.ai_params["MS_IP"])
        try:
            CollectLogs(self.ai_params["MS_IP"],
                        constants.ROOT_MS_PASSWD,
                        constants.LITP_USER,
                        constants.LITP_USER_PEERNODE_PASSWD,
                        constants.ROOT_PEERNODE_PASSWD).collect_logs()
        except:
                print("Unexpected error collecting logs:", sys.exc_info()[0])

    @staticmethod
    def get_time_str():
        """
        Return the local time now as a str
        """
        time_now = time.localtime()

        time_str = "{0}:{1}:{2}".format(time_now.tm_hour,
                                        time_now.tm_min,
                                        time_now.tm_sec)

        return time_str

    def output_to_task_status_file(self, test_id, test_area, desc):
        """
        Outputs the test area and description to the status file, this will be
        used later in generating a report.
        """
        ##Get AI Arguments
        ai_params = ""
        for key in self.ai_params.keys():
            #if not none
            if self.ai_params[key]:
                key_pair = "{0}={1}".format(key,
                                            self.ai_params[key])

                ai_params += "##{0}".format(key_pair)

        cmd = "/bin/echo {0},#,{1},#,{2},#,{3},#,{4},#,--TIME_END--,#,--PROGRESS-- >> {5}"\
            .format(test_id,
                    test_area,
                    desc,
                    ai_params,
                    self.get_time_str(),
                    self.ai_status_file)

        self.utilfile.run_command_local(cmd, logs=False)

    def set_current_task_passed(self):
        """
        Sets the currently running AI task to pass.
        """
        cmd = "/bin/sed -i s/--PROGRESS--/PASSED/g {0}"\
            .format(self.ai_status_file)

        self.utilfile.run_command_local(cmd, logs=False)

        cmd = "/bin/sed -i s/--TIME_END--/{0}/g {1}"\
            .format(self.get_time_str(),
                    self.ai_status_file)

        self.utilfile.run_command_local(cmd, logs=False)

    def set_current_task_failed(self):
        """
        Sets the currently running AI task to pass.
        """
        cmd = "/bin/sed -i s/--PROGRESS--/FAILED/g {0}"\
            .format(self.ai_status_file)

        self.utilfile.run_command_local(cmd, logs=False)

        cmd = "/bin/sed -i s/--TIME_END--/{0}/g {1}"\
            .format(self.get_time_str(),
                    self.ai_status_file)
        self.utilfile.run_command_local(cmd, logs=False)

    def signal_handler(self, signal, frame):
        """
        If Ctrl+C is pressed make sure cleanup ai is called
        """
        print "Ctrl+C was pressed"
        self.cleanupai()
        sys.exit(0)

    def complete_install(self):
        """
        Complete install option
        """
        if not self.ai_params["RUN_OLD_CLEANUP"]:
            self.clean_litp()
        self.install_rhel()
        self.install_litp()
        if self.ai_params["RUN_OLD_CLEANUP"]:
            self.clean_litp()
        self.deploy_litp()

    def complete_installupgrade(self):
        """
        Complete install + upgrade option
        """
        self.clean_litp()
        self.install_rhel()
        self.install_litp()
        self.deploy_litp()
        self.upgrade_litp()

    def litpupgrade(self):
        """
        Upgrade only option
        """
        self.upgrade_litp()

    def litpms_install(self):
        """
        Install LITP MS only
        """
        self.clean_litp()
        self.install_rhel()
        self.install_litp()

    def litp_deploy_install(self):
        """
        Deploy litp only
        """
        self.deploy_litp()

    def litp_install_os_patch_packages(self):
        """
        Install required package from the OS Patches for cloud vApps.
        """

    def litp_backup_restore(self):
        """
        Deploy litp only
        """
        print ""
        print "#########################################################"
        print ">> INFO: CREATE NAMED SNAPSHOT BEFORE RESTORE"
        print "#########################################################"
        print ""
        print ""
        if not backupRestoreLitp(self.ai_params).create_named_snapshot():
            self.cleanupai()
            sys.exit(1)

        self.clean_litp(True)
        self.backup_restore()

    def restore_snapshot(self):
        """
        Run a script to restore to the last unnamed snapshot
        """
        print ""
        print "#########################################################"
        print ">> INFO: RESTORING TO LAST UNNAMED SNAPSHOT"
        print "#########################################################"
        print ""
        print ""
        if not CreateRestoreSnapshot(self.ai_params).restore_snapshot():
            self.cleanupai()
            sys.exit(1)

    def rhel_complete(self):
        """
        Install and Deploy litp from RHEL state
        """
        self.install_litp()
        self.deploy_litp()

    def expand_litp_cluster(self):
        """
        Run a script to expand the current LITP cluster.
        """
        self.expand_litp()

    def install_rhel(self, no_litp=False):
        """
        Install a rhel ISO with LITP KS
        """
        self.output_to_task_status_file(1,
                                        "Install",
                                        "Install RHEL on the MS using the kickstart provided on the LITP ISO")
        # SETUP KS FILE FOR INSTALL
        if no_litp:
            self.ai_params["KS_FILE"] = "http://10.44.235.150/iso/litp/latest_RHEL7_ks/ms-ks-network.cfg"
        else:
            self.setup_ksfile()

        #INSERT ISO
        if not InsertIso(self.ai_params).insert_iso():
            self.cleanupai()
            sys.exit(1)

        print "Sleeping for 30 seconds while blade reboots..."
        time.sleep(30)

        #INSTALL ISO
        install = InstallIso(self.ai_params)
        install_success = install.run_vsp_install()

        #If install reports failure
        if not install_success:
            #If ilo has been reset try install again
            if install.ilo_reset == True:
                if not InsertIso(self.ai_params).insert_iso():
                    self.cleanupai()
                    sys.exit(1)

                print "Sleeping for 30 seconds while blade reboots..."
                time.sleep(30)

                #INSTALL ISO
                install = InstallIso(self.ai_params)
                install_success = install.run_vsp_install()

                if not install_success:
                    self.cleanupai()
                    sys.exit(1)
            #if ilo not reset exit with failure
            else:
                self.cleanupai()
                sys.exit(1)

        self.set_current_task_passed()

    def install_litp(self):
        """
        Install LITP ISO on RHEL
        """
        # INSTALL LITP ISO AND TARBALL
        self.output_to_task_status_file(2,
                                        "Install",
                                        "Install LITP on the MS using the installer.sh script")
        if not InstallLitpMs(self.ai_params).install_litp():
            self.cleanupai()
            sys.exit(1)

        # POST LITP USER SETUP

        if not LITPMsUserUpdate(self.ai_params).update_users():
            self.cleanupai()
            sys.exit(1)

        self.set_current_task_passed()

    def upgrade_litp(self):
        """
        Install LITP ISO on RHEL
        """
        # INSTALL LITP ISO AND TARBALL
        self.output_to_task_status_file(4,
                                        "Upgrade",
                                        "Upgrade to a new LITP version using the documented import_iso functionality")
        if not UpgradeLitp(self.ai_params).upgrade_litp():
            self.cleanupai()
            sys.exit(1)
        # SANITY CHECK FOR LITP UPGRADe
        if not LitpSanityCheck(self.ai_params).sanity_check():
            self.cleanupai()
            sys.exit(1)

        self.set_current_task_passed()


    def backup_restore(self):
        """
        Deploy the litp cluster using scripts
        """
        self.output_to_task_status_file(5,
                                        "Restore",
                                        "Perform a litp prepare_restore command and then run the plan to check the model can be reapplied")
        # DEPLOY LITP USING CLI SCRIPT
        if not backupRestoreLitp(self.ai_params).backup_restore_litp():
            self.cleanupai()
            sys.exit(1)
        # SET UP PASSWORDS ON NODES AND CHECK NODES ARE INSTALLED
        #tmp workaround to set all passwords incl expanded nodes
        self.ai_params["NODE_HOSTNAMES"] = "node1,node2,node3,node4"

        if not SetupLitpNodes(self.ai_params).setup_litp_nodes():
            self.cleanupai()
            sys.exit(1)
        # SANITY CHECK FOR LITP INSTALL

        ##If set use special ip addreses that are contactable

        #Check for vcs debug logging flag and turn on logging on the peer nodes
        if self.ai_params["VCS_DEBUG_LOGGING"]:
            if not InitiateVCSDebug(self.ai_params).initiate_debug_logging():
                print 'Unable to turn on VCS debug level logging on peer nodes.'

        #Reboot peer nodes
        if not PeerNodeRebootRestore(self.ai_params).reboot_peer_nodes():
            self.cleanupai()
            sys.exit(1)

        if not LitpSanityCheck(self.ai_params).sanity_check():
            self.cleanupai()
            sys.exit(1)

        self.set_current_task_passed()

    def clean_litp(self, restore_case=False):
        """
        Clean up litp env before install
        """
        # DEPLOY LITP USING CLI SCRIPT
        if not CleanLitp(self.ai_params, restore_case).clean_litp():
            self.cleanupai()
            sys.exit(1)

    def deploy_litp(self):
        """
        Deploy the litp cluster using scripts
        """
        self.output_to_task_status_file(3,
                                        "Install",
                                        "Run a deployment script to deploy new peer nodes")
        # DEPLOY LITP USING CLI SCRIPT
        if not DeployLitp(self.ai_params).deploy_litp():
            self.cleanupai()
            sys.exit(1)
        # SET UP PASSWORDS ON NODES AND CHECK NODES ARE INSTALLED
        if not SetupLitpNodes(self.ai_params).setup_litp_nodes():
            self.cleanupai()
            sys.exit(1)

        #Check for vcs debug logging flag and turn on logging on the peer nodes
        if self.ai_params["VCS_DEBUG_LOGGING"]:
            if not InitiateVCSDebug(self.ai_params).initiate_debug_logging():
                print 'Unable to turn on VCS debug level logging on peer nodes.'

        # Check for reboot flag here and run peer node reboot if needed.
        if self.ai_params["REBOOT_PEER_NODES"]:
            if not PeerNodeReboot(self.ai_params).reboot_peer_nodes():
                self.cleanupai()
                sys.exit(1)

        # SANITY CHECK FOR LITP INSTALL

        ##If set use special ip addreses that are contactable

        if not LitpSanityCheck(self.ai_params).sanity_check():
            self.cleanupai()
            sys.exit(1)

        self.set_current_task_passed()

    def expand_litp(self):
        """
        Expand an existing LITP cluster
        """
        # EXPAND LITP USING CLI SCRIPT
        self.output_to_task_status_file(6,
                                        "Expand",
                                        "Expand the number of nodes in the LITP cluster\(s\)")
        #Initialise the expand object
        expand = ExpandLitp(self.ai_params)

        ##RUN EXPANSION.
        if not expand.expand_litp():
            self.cleanupai()
            sys.exit(1)

        ##IF NOT RESTORED SETUP EXPANDED NODES PW
        if not self.ai_params["RESTORE_EXPAND"]:
            expanded_nodes = expand.get_expanded_nodes()
            print "DEBUG: EXPANDED NODES: ", expanded_nodes

            expanded_hostnames = list()
            expanded_ips = list()

            for node in expanded_nodes:
                print "DEBUG: node: ", node
                expanded_hostnames.append(node['hostname'])
                expanded_ips.append(node['ip'])

            expand_h_str = ",".join(expanded_hostnames)
            expand_ip_str = ",".join(expanded_ips)
            # BACKUP ORIGINAL LIST SO SETUP OF PASSWORD CAN REMAIN GENERIC
            original_hostname_list = self.ai_params["NODE_HOSTNAMES"]
            self.ai_params["NODE_HOSTNAMES"] = expand_h_str
            # SET UP PASSWORDS ON NEW EXPANDED NODES
            if not SetupLitpNodes(self.ai_params).setup_litp_nodes():
                self.cleanupai()
                sys.exit(1)
            # NOW RETURN TO ITS ORIGINAL VALUE
            self.ai_params["NODE_HOSTNAMES"] = original_hostname_list

            ##IF WE HAVE SANITY IPS AND EXPANDED IPS APPEND LISTS
            if self.ai_params["SANITY_CHECK_IPS"] != 'no_sanity':
                self.ai_params["NODE_HOSTNAMES"] = "{0},{1}".format(self.ai_params["NODE_HOSTNAMES"],
                                                 expand_h_str)

                self.ai_params["SANITY_CHECK_IPS"] = "{0},{1}".format(self.ai_params["SANITY_CHECK_IPS"],
                                           expand_ip_str)
            #IF ONLY EXPAND IPS SET EXPAND IPS TO LIST FOR SANITY
            else:
                #ADD EXPANDED NODES TO STR OF NODES TO PERFORM SANITY CHECK
                self.ai_params["NODE_HOSTNAMES"] = expand_h_str
                self.ai_params["SANITY_CHECK_IPS"] = expand_ip_str

        #RUN SANITY CHECK ON ALL NODES IN LIST
        if not LitpSanityCheck(self.ai_params).sanity_check():
            self.cleanupai()
            sys.exit(1)

        self.set_current_task_passed()

    def setup_ksfile(self):
        """
        Get kickstart file from the litp ISO
        """

        print ""
        print "#########################################################"
        print ">> INFO: SETUP ISO INSTALL"
        print "#########################################################"
        print ""
        ###Make folder to mount LITP ISO
        cmd = "mkdir %s/2.0_mount/" % self.ai_params["AUTOINSTALL_DIR"]
        stdout, stderr, retc = self.utilfile.run_command_local(cmd, logs=False)
        if stdout != [] or stderr != [] or retc != 0:
            print ">> ERROR: MKDIR %s/2.0_mount/ failed: %s" \
                % (self.ai_params["AUTOINSTALL_DIR"], stderr)
            self.cleanupai()
            sys.exit(1)
        print "Created %s/2.0_mount/" % self.ai_params["AUTOINSTALL_DIR"]

        ###Mount LITP ISO
        cmd = "mount %s/%s %s/2.0_mount/ -o loop" \
            % (self.ai_params["AUTOINSTALL_DIR"], self.ai_params["ISO_FILE"], \
                        self.ai_params["AUTOINSTALL_DIR"])
        # The below command requires the gateway to be able to ssh to the server provided for autoinstall's server_http_location parameter without a password. In practice we always use the gateway itself to host the kickstart, so the gateway will need to be able to ssh to itself without a password.
        stdout, stderr, retc = self.utilfile.run_command(cmd, logs=False)
        if retc != 0:
            print stdout
            print stderr
            print retc
            print ">> ERROR: MOUNT OF ISO FAILED: %s" % stderr
            self.cleanupai()
            sys.exit(1)
        print "ISO %s mounted to %s/2.0_mount/" \
                % (self.ai_params["LITP_ISO"], self.ai_params["AUTOINSTALL_DIR"])

        ##Copy kickstart file from mounted ISO
        cmd = "cp %s/2.0_mount/install/ms-ks-network.cfg %s" \
            % (self.ai_params["AUTOINSTALL_DIR"], self.ai_params["AUTOINSTALL_DIR"])
        stdout, stderr, retc = self.utilfile.run_command(cmd, logs=False)
        if stdout != [] or stderr != [] or retc != 0:
            print stdout
            print stderr
            print retc
            print ">> ERROR: COPY OF KS FILE FAILED"
            self.cleanupai()
            sys.exit(1)
        print "Copied %s/2.0_mount/install/ms-ks-network.cfg to %s" \
            % (self.ai_params["AUTOINSTALL_DIR"], self.ai_params["AUTOINSTALL_DIR"])
        self.ai_params["KS_FILE"] = self.ai_params["SERVER_HTTP_LOCATION"] + "/" \
                + self.ai_params["JENKINS_JOB_ID"] + "/ms-ks-network.cfg"
        self.ai_params["KS_FILE_PATH"] = self.ai_params["AUTOINSTALL_DIR"] + "/ms-ks-network.cfg"

        ##Unmount LITP ISO
        cmd = "umount %s/2.0_mount/" % self.ai_params["AUTOINSTALL_DIR"]
        stdout, stderr, retc = self.utilfile.run_command(cmd, logs=False)
        if stdout != [] or stderr != [] or retc != 0:
            print stdout
            print stderr
            print retc
            print ">> ERROR: UMOUNT FAILED"
            self.cleanupai()
            sys.exit(1)
        print "umount %s/2.0_mount/" % self.ai_params["AUTOINSTALL_DIR"]

        # REMOVE THE MOUNT DIRECTORY
        ##Remove mount directory
        cmd = "rm -rf %s/2.0_mount/" % self.ai_params["AUTOINSTALL_DIR"]
        stdout, stderr, retc = self.utilfile.run_command_local(cmd, logs=False)
        if stdout != [] or stderr != [] or retc != 0:
            print ">> ERROR: REMOVAL OF DIRECTORY FAILED"
            self.cleanupai()
            sys.exit(1)
        print "Removed %s/2.0_mount/" % self.ai_params["AUTOINSTALL_DIR"]


class AIUtil():
    """
    Setup the LITP ISO for install
    """
    def __init__(self):
        """
        CLASS TO GET KS FILE FROM ISO
        """

    def print_usage(self):
        usage = "USAGE:\npython autoinstall.py [--help|-h]\t\t\t\t" \
        + "Autoinstall Help\n" \
        + "python autoinstall.py [--complete-install|-ci]\t\t\tComplete LITP install - RHEL + LITP + LITP DEPLOYMENT\n" \
        + "python autoinstall.py [--litp-ms-install|-litpms]\t\tLITP MS install only - RHEL + LITP\n" \
        + "python autoinstall.py [--litp-cluster-install|-litpc]\t\tLITP cluster deployment only - LITP DEPLOYMENT\n" \
        + "python autoinstall.py [--rhel-install|-rhel]\t\t\tRed Hat Install Only\n" \
        + "python autoinstall.py [--rhel-ms-install|-rhelms]\t\tInstall LITP MS from RHEL install state\n" \
        + "python autoinstall.py [--rhel-litp-install|-rhellitp]\t\tInstall full LITP from RHEL INSTALL STATE\n" \
        + "python autoinstall.py [--complete-litp-install-upgrade|-ciu]\tInstall a version of LITP and upgrade it to another version\n" \
        + "python autoinstall.py [--litp-upgrade|-litpup]\t\t\tUpgrade litp from an install state\n" \
        + "python autoinstall.py [--expand-litp-cluster|-elc]\t\tExpand the litp cluster\n" \
        + "python autoinstall.py [--litp-backup-and-restore|-lbr]\t\tOption to run litp backup and restore, for disaster recovery testing\n\n" \
        + "OPTIONS:\n" \
        + "--rheliso=<PATH TO RHEL ISO>\n" \
        + "--litpiso=<PATH TO LITP ISO>\n" \
        + "--install_type=<INSTALL TYPE> - [multiblade_san|multiblade_local|cloud]>\n" \
        + "--install_script=<PATH TO INSTALL SCRIPT> - The install script can be either a bash script (.sh) or an .xml script\n" \
        + "--pre_xml_load_script=<PATH TO PRE_XML_LOAD SCRIPT> - A bash script (.sh) when provided will be executed before an xml file is loaded to litp\n" \
        + "--expand_script=<PATH TO EXPAND SCRIPT> - The expand script to expand the cluster. Must be a bash script (.sh)\n" \
        + "--install_option=<INSTALL OPTION> [CLI|XML_merge|XML_replace] - Default is CLI - NOTE If CLI is chosen and a .xml script is given then autoinstall will fail\n" \
        + "--cluster_file=<PATH TO CLUSTER FILE>\n" \
        + "--server_http_location=<SERVER HTTP LOCATION> - i.e. local http location for autoinstall to put the kickstart file: http://<url>/directory/\n" \
        + "--server_http_full_path_location=<SERVER HTTP LOCATION LOCAL> - The full linux path that points to the same location for --server_http_location.\n\tIf --server_http_location is not given this option is still needed to create a directory for use in autoinstall \n" \
        + "--with_os_patches=<PATH TO OS PATCHES TARBALL>\n" \
        + "--litp_upgrade=<PATH TO LITP UPGRADE ISO>\n" \
        + "--with_os_patches_upgrade=<PATH TO OS PATCHES UPGRADE TARBALL> -OR- --with_os_patches_upgrade=<http://<server-host>/<PATH-TO-FILE> - If a linux path exists it assumes\n" \
        + "\tit is on the same server as autoinstall is being run, if a http path is given the os patches will be taken from the http location directly to the MS.\n" \
        + "\tTaking from http location is quicker than from path on local server if possible. 'http://' must be in the path if done over http\n" \
        + "--restore-from-upgrade - If this is selected, after an upgrade is complete it will perform a restore to the original state before upgrade took place\n" \
        + "--update-rsyslog8 - If this is selected, Before an upgrade takes place, rsyslog will be updated to rsyslog8\n" \
        + "--restore-from-expand - If this is selected, after an expand is complete it will perform a restore to the original state before expand took place\n" \
        + "--ipmi_tool_location=<PATH TO IPMI TOOL> - Only to be used in cloud installations\n" \
        + "--redfish_tool_location=<PATH TO REDFISH TOOL> - Only to be used in cloud installations\n" \
        + "--skip_peer_node_passwd_setup - This option can be used for MS only deployments to skip all peer node password setup\n" \
        + "--reboot_peer_nodes_after_install - If this is selected then all peer nodes in the system will be rebooted after install. Note: Sanity IPs must be provided in order to reboot peer nodes.\n"\
        + "--initiate_vcs_debug_level_logging - If this is selected then vcs debug level logging will be on all peer nodes after successful install.\n"\
        + "--expect_large_plan - Writes the output of 'litp show_plan' to a file.\n\n" \
        + "--plan_monitor_script - Runs the provided script during the running of a deployment or expansion plan.\n\n" \
        + "Autoinstall has a validation in at the start of the process, the options above must be given as follows:\n\n" \
        + "python autoinstall.py [--complete-install|-ci] --rheliso= --litpiso= --install_type= --install_script= --cluster_file= --server_http_location= --server_http_full_path_location= [OPTIONAL: --with_os_patches= --install_option= --pre_xml_load_script= --reboot_peer_nodes_after_install --skip_peer_node_passwd_setup --expect_large_plan]\n" \
        + "python autoinstall.py [--litp-ms-install|-litpms] --rheliso= --litpiso= --install_type=  --cluster_file= --server_http_location= --server_http_full_path_location= [OPTIONAL: --with_os_patches=]\n" \
        + "python autoinstall.py [--litp-cluster-install|-litpc] --install_type=  --cluster_file= --install_script= --server_http_full_path_location= [OPTIONAL: --with_os_patches= --install_option= --pre_xml_load_script= --reboot_peer_nodes_after_install --skip_peer_node_passwd_setup --expect_large_plan]\n" \
        + "python autoinstall.py [--rhel-install|-rhel] --rheliso= --litpiso= --cluster_file= --server_http_location= --server_http_full_path_location=\n" \
        + "python autoinstall.py [--rhel-ms-install|-rhelms] --litpiso= ---cluster_file= --server_http_full_path_location= [OPTIONAL: --with_os_patches= --ipmi_tool_location= --redfish_tool_location=]\n" \
        + "python autoinstall.py [--rhel-litp-install|-rhellitp] --litpiso= --install_type= --install_script= --cluster_file= --server_http_full_path_location= [OPTIONAL: --with_os_patches= --install_option= --pre_xml_load_script= --ipmi_tool_location= --redfish_tool_location= --expect_large_plan]\n" \
        + "python autoinstall.py [--complete-litp-install-upgrade|-ciu] --rheliso= --litpiso= --install_type= --install_script= --cluster_file= --server_http_location= --server_http_full_path_location= --litp_upgrade= [OPTIONAL: --with_os_patches= --install_option= --pre_xml_load_script= --restore-from-upgrade --with_os_patches_upgrade= --update-rsyslog8 --reboot_peer_nodes_after_install --skip_peer_node_passwd_setup --expect_large_plan]\n" \
        + "python autoinstall.py [--litp-upgrade|-litpup] --install_type=  --litp_upgrade= --cluster_file= --server_http_full_path_location= [OPTIONAL: --install_option= --restore-from-upgrade --with_os_patches_upgrade= --update-rsyslog8]\n" \
        + "python autoinstall.py [--expand-litp-cluster|-elc] --cluster_file= --expand_script= --server_http_full_path_location= [OPTIONAL: --restore-from-expand]\n" \
        + "python autoinstall.py [--litp-backup-and-restore|-lbr] --cluster_file= --server_http_full_path_location= --expect_large_plan]\n\n" \
        + "CLUSTERFILE:\n" \
        + "The clusterfile is an important part of the installation as it contains specific information about the environment that being installed.\nSo the autoinstallation code assumes certain properties are part of the cluster file for the installation, these are as follows:\n\n" \
        + 'blade_type="G8" - Other option is "cloud" or "DL380"\n' \
        + 'ms_ilo_ip="<node ilo ip address>"\n' \
        + 'ms_ilo_username="<username>"\n' \
        + 'ms_ilo_password="<password>"\n' \
        + 'ms_ip="<ms ip address>"\n' \
        + 'ms_subnet="<ms subnet address>" - for example 10.44.86.64/26\n' \
        + 'ms_gateway="<ms gateway address>"\n' \
        + 'ms_vlan="<vlan>" - Only for DL380 systems, Leave as ms_vlan="" if it is not a DL380 blade\n' \
        + 'ms_host="<hostname to be given during the installation process>"\n' \
        + 'ms_eth0_mac="<MAC address of eth0 on the MS>"\n' \
        + 'node_hostname[0]="node1"\n' \
        + 'node_hostname[1]="node2"\n' \
        + 'node_hostname[N]="nodeN"\n' \
        + 'node_ip[0]="<node ip address>"\n' \
        + 'node_ip[1]="<node ip address>"\n' \
        + 'node_ip[N]="<node ip address>"\n' \
        + "If any one of these properties are not set then the autoinstallation validation will throw an error. \n\n" \
        + "The following parameters are optional: \n\n" \
        + 'install_with_nic="<nic name>" - If you wish to install the system with a different nic than default of eth0, then specify here. Note For this you will need ms_ethX_mac in the cluster file set for this nic.\n\n' \
        + 'Cleanup of SFS shares and filesystems is as follows:\n\n' \
        + 'Where <sfs-share> is the share on the SFS itself, (e,g /vx/ST200_managedshare1) and <filesystem> is the filesystem on the SFS itself (e.g. ST200_managedshare1)\n\n' \
        + 'One filesystem with one share:\n' \
        + 'sfs_cleanup_list="<sfs-server-ip>:<sfs-user>:<sfs-password>:<sfs-share>=<shared-host>:<filesystem>"\n' \
        + 'One filesystem with two shares:"\n' \
        + 'sfs_cleanup_list="<sfs-server-ip>:<sfs-user>:<sfs-password>:<sfs-share>=<shared-host>,<sfs-share>=<shared-host>:<filesystem>"\n' \
        + 'One filesystem with multiple shares:"\n' \
        + 'sfs_cleanup_list="<sfs-server-ip>:<sfs-user>:<sfs-password>:<sfs-share>=<shared-host>,<sfs-share>=<shared-host>:<filesystem>"\n' \
        + 'Multiple filesystems with mixed number of shares:"\n' \
        + 'sfs_cleanup_list="<sfs-server-ip>:<sfs-user>:<sfs-password>:<sfs-share>=<shared-host>,<sfs-share>=<shared-host>:<filesystem>__BREAK__<sfs-server-ip>:<sfs-user>:<sfs-password>:<sfs-share>=<shared-host>:<filesystem>"\n' \
        + 'Clean shares but not filesystem:"\n' \
        + 'sfs_cleanup_list="<sfs-server-ip>:<sfs-user>:<sfs-password>:<sfs-share>=<shared-host>,<sfs-share>=<shared-host>:no_filesystem_cleanup"\n\n' \
        + 'Cleanup of SFS cache and snapshots are follows:\n\n' \
        + 'Where <sfs-snapshot> is the snapshot on the SFS itself, (e,g L_CI15-managed-fs1_), <filesystem> is the filesystem on the SFS itself (e.g. ST200_managedshare1) and <sfs-cache> is the cache on the SFS itself (e.g. ST200_cache)\n\n' \
        + 'One snapshot, one filesystem, one cache:\n' \
        + 'sfs_snapshot_cleanup_list="<sfs-server-ip>:<sfs-user>:<sfs-password>:<sfs-snapshot>=<filesystem>:<sfs-cache>"\n' \
        + 'Two snapshots, two filesystems, two cache:\n' \
        + 'sfs_snapshot_cleanup_list="<sfs-server-ip>:<sfs-user>:<sfs-password>:<sfs-snapshot>=<filesystem>:<sfs-cache>__BREAK__<sfs-server-ip>:<sfs-user>:<sfs-password>:<sfs-snapshot>=<filesystem>:<sfs-cache>"\n' \
        + 'Multiple snapshots on one filesystem, one cache:"\n' \
        + 'sfs_snapshot_cleanup_list="<sfs-server-ip>:<sfs-user>:<sfs-password>:<sfs-snapshot>=<filesystem>,<sfs-snapshot>=<filesystem>,<sfs-snapshot>=<filesystem>:<sfs-cache>"\n' \
        + 'The SFS cleanup scripts will read these in and connect to the SFS and run as the values are presented in the cluster file, all commands run on the SFS are executed, whether successful or not autoinstall will just continue on"\n\n' \
        + 'sanity_check_node_ip[0]="ip address to use to perform node 1 sanity checks after install"\n' \
        + 'sanity_check_node_ip[1]="ip address to use to perform node 2 sanity checks after install"\n' \
        + 'sanity_check_node_ip[N]="ip address to use to perform node N sanity checks after install"\n' \
        + 'node_expansion_ip[0]="ip address of node 1 to use to expand the cluster" \n' \
        + 'node_expansion_ip[N]="ip address of node N to use to expand the cluster" \n' \
        + 'node_expansion_hostname[0]="hostname of node 1 to use to expand the cluster" \n' \
        + 'node_expansion_hostname[N]="hostname of node N to use to expand the cluster" \n' \
        + 'node_expansion_bmc_ip[0]="ilo ip of node 1 required to power off the node before expansion" \n' \
        + 'node_expansion_bmc_ip[N]="ilo ip of node N required to power off the node before expansion" \n' \
        + 'If any properties named as for example:\n\n' \
        + 'copytestfile1="<localpathtofile>/<file>:<remotemspath>/<file>"\n' \
        + 'copytestfile2="<localpathtofile>/<file>:<remotemspath>/<file>"\n\n' \
        + "They will be copied over to that remote location on the MS. The file given in the localpathtofile must exist on the same machine as the autoinstall job is running\n\n" \
        + "NOTES:\n" \
        + "- If the --with_os_patches= option is given, then os patches will be updated to the version passed through to autoinstall, both on the MS and on the peer nodes as per user documentation\n" \
        + "- Autoinstall is written to work with Jenkins, if running outside of a Jenkins server, then the following two environment variables need to be exported with dummy values: export JOB_NAME=DUMMYJOB; export BUILD_NUMBER=0001\n\n"

        print usage


def main():
    """
    main function
    """


    util = AIUtil()
    # Disable output buffering to receive the output instantly
    sys.stdout = os.fdopen(sys.stdout.fileno(), "w", 0)
    sys.stderr = os.fdopen(sys.stderr.fileno(), "w", 0)
    """
    if len(sys.argv) == 8 or len(sys.argv) == 9 or len(sys.argv) == 10 or len(sys.argv) == 11 or sys.argv[1] == "-h" or sys.argv[1] == "--help":
        print ""
    else:
        print ">> ERROR: Not all required arguments supplied: %s" % sys.argv
        util.print_usage()
        sys.exit(1)
    """
    if len(sys.argv) == 1:
        print ""
        util.print_usage()
        sys.exit(1)

    if sys.argv[1] == "-h" or sys.argv[1] == "--help" or sys.argv[1] == "-ci" \
        or sys.argv[1] == "--complete-install" or sys.argv[1] == "-litpms" \
        or sys.argv[1] == "--litp-ms-install" or sys.argv[1] == "-litpc" \
        or sys.argv[1] == "--litp-backup-and-restore" or sys.argv[1] == "-lbr" \
        or sys.argv[1] == "--litp-cluster-install" or sys.argv[1] == "--rhel-install" \
        or sys.argv[1] == "-rhel" or sys.argv[1] == "--rhel-ms-install" or sys.argv[1] == "-rhelms" \
        or sys.argv[1] == "--rhel-litp-install" or sys.argv[1] == "-rhellitp" or sys.argv[1] == "-ciu" \
        or sys.argv[1] == "--complete-litp-install-upgrade" or sys.argv[1] == "--litp-upgrade" \
        or sys.argv[1] == "--expand-litp-cluster" or sys.argv[1] == "-elc" \
        or sys.argv[1] == "-litpup" or sys.argv[1] == "--restore_snapshot":
            print "\n%s option chosen for autoinstall\n" % sys.argv[1]
    else:
        util.print_usage()
        sys.exit(1)

    if sys.argv[1] == "-h" or sys.argv[1] == "--help":
        util.print_usage()
        sys.exit(0)

    # EXPORT PYTHONPATH FOR TEST CASES
    currdir = os.path.dirname(os.path.abspath(__file__))
    os.environ['PYTHONPATH'] = currdir + "/common_platform_files/"

    # GET JENKINS JOB ID
    jenkins_id = os.environ['JOB_NAME'] + "-" + os.environ['BUILD_NUMBER'] + "_" + time.strftime("%H%M%S")
    jenkins_id = jenkins_id.replace(" ", "_")
    #jenkins_id = "test2"

    # CHECK AND SET CMD ARGS + USAGE

    rhel_iso = None
    litp_iso = None
    install_type = None
    install_script = None
    expand_script = None
    cluster_file = None
    server_http_location = None
    server_http_full_path_location = None
    ipmi_tool_location = None
    redfish_tool_location = None
    install_option = "CLI"
    os_patches = False
    os_patches_path = None
    os_patches_upgrade = False
    os_patches_path_upgrade = None
    litp_upgrade = False
    restore_upgrade = False
    litp_upgrade_iso = None
    restore_expand = False
    retry_plan = False
    update_rsyslog8 = False
    fail_script = None
    reboot_peer_nodes = False
    vcs_debug_logging = False
    skip_peer_node_passwd = False
    skip_install_snapshot = False
    skip_upgrade_snapshot = False
    skip_post_deploy_snapshot = False
    expect_large_plan = False
    pre_xml_script = None
    run_old_cleanup = False
    local_trust_auth = True
    monitor_script_path = None

    for line in sys.argv:
        if "--rheliso=" in line:
            rhel_iso = line.split("=")[-1]
        if "--litpiso=" in line:
            litp_iso = line.split("=")[-1]
        if "--install_type=" in line:
            install_type = line.split("=")[-1]
        if "--install_script=" in line:
            install_script = line.split("=")[-1]
        if "--expand_script=" in line:
            expand_script = line.split("=")[-1]
        if "--cluster_file=" in line:
            cluster_file = line.split("=")[-1]
        if "--server_http_location=" in line:
            server_http_location = line.split("=")[-1]
        if "--server_http_full_path_location=" in line:
            server_http_full_path_location = line.split("=")[-1]
        if "--install_option=" in line:
            install_option = line.split("=")[-1]
        if "--ipmi_tool_location=" in line:
            ipmi_tool_location = line.split("=")[-1]
        if "--redfish_tool_location=" in line:
            redfish_tool_location = line.split("=")[-1]
        if "--restore-from-upgrade" in line:
            restore_upgrade = True
        if "--with_os_patches=" in line:
            os_patches = True
            os_patches_path = line.split("=")[-1]
        if "--litp_upgrade=" in line:
            litp_upgrade = True
            litp_upgrade_iso = line.split("=")[-1]
        if "--with_os_patches_upgrade=" in line:
            os_patches_upgrade = True
            os_patches_path_upgrade = line.split("=")[-1]
        if "--restore-from-expand" in line:
            restore_expand = True
        if "--retry-failed-plan" in line:
            retry_plan = True
        if "--update-rsyslog8" in line:
            update_rsyslog8 = True
        if "--retry-failed-plan-script=" in line:
            fail_script = line.split("=")[-1]
        if "--reboot_peer_nodes_after_install" in line:
            reboot_peer_nodes = True
        if "--initiate_vcs_debug_level_logging" in line:
            vcs_debug_logging = True
        if "--skip_peer_node_passwd_setup" in line:
            skip_peer_node_passwd = True
        if "--skip_install_snapshot" in line:
            skip_install_snapshot = True
        if "--skip_upgrade_snapshot" in line:
            skip_upgrade_snapshot = True
        if "--skip_post_deploy_snapshot" in line:
            skip_post_deploy_snapshot = True
        if "--expect_large_plan" in line:
            expect_large_plan = True
        if "--pre_xml_load_script=" in line:
            pre_xml_script = line.split("=")[-1]
        if "--local_trust_auth" in line:
            local_trust_auth = True

        # TEMPORARY OPTION UNTIL LITPCDS-12740 is resolved
        if "--run-old-cleanup" in line:
            run_old_cleanup = True

        if "--plan_monitor_script" in line:
            monitor_script_path = line.split("=")[-1]

    run = AIRunner(
        sys.argv[1], rhel_iso, litp_iso, install_type,
        install_script, cluster_file, server_http_location,
        server_http_full_path_location, jenkins_id, install_option,
        ipmi_tool_location, redfish_tool_location, os_patches,
        os_patches_path, litp_upgrade, litp_upgrade_iso, os_patches_upgrade,
        os_patches_path_upgrade, restore_upgrade, expand_script,
        restore_expand, retry_plan, fail_script, update_rsyslog8,
        reboot_peer_nodes, vcs_debug_logging, run_old_cleanup,
        skip_peer_node_passwd, skip_install_snapshot,
        skip_upgrade_snapshot, expect_large_plan, pre_xml_script,
        local_trust_auth, monitor_script_path, skip_post_deploy_snapshot)

    # PRINT ALL CMD ARGS FOR INFO
    run.print_ai_info()

    # RUN THE TEST SETUP AND GET REQUIRED PROPERTIES
    run.setupai()

    # SET LOCK FILE SO NODE INSTALLS DO NOT CLASH
    run.create_lockfile()

    # SET THE TRAP IN CASE CTRL C IS PRESSED
    signal.signal(signal.SIGTERM, run.signal_handler)
    #signal.signal(signal.SIGINT, run.signal_handler)

    # RUN ONE OF THE OPTIONS:
    # COMPLETE INSTALL
    if sys.argv[1] == "-ci" or sys.argv[1] == "--complete-install":
        run.complete_install()
    # LITP INSTALL
    if sys.argv[1] == "-litpms" or sys.argv[1] == "--litp-ms-install":
        run.litpms_install()
    # LITP DEPLOY
    if sys.argv[1] == "-litpc" or sys.argv[1] == "--litp-cluster-install":
        run.litp_deploy_install()
    # RHEL INSTALL ONLY
    if sys.argv[1] == "-rhel" or sys.argv[1] == "--rhel-install":
        run.install_rhel(no_litp=True)
    # LITP MS INSTALL FROM RHEL
    if sys.argv[1] == "-rhelms" or sys.argv[1] == "--rhel-ms-install":
        run.install_litp()
    # LITP FULL INSTALL FROM RHEL
    if sys.argv[1] == "-rhellitp" or sys.argv[1] == "--rhel-litp-install":
        run.rhel_complete()
    if sys.argv[1] == "-ciu" or sys.argv[1] == "--complete-litp-install-upgrade":
        run.complete_installupgrade()
    if sys.argv[1] == "-litpup" or sys.argv[1] == "--litp-upgrade":
        run.litpupgrade()
    if sys.argv[1] == "-elc" or sys.argv[1] == "--expand-litp-cluster":
        run.expand_litp_cluster()
    # LITP BACKUP AND RESTORE
    if sys.argv[1] == "-lbr" or sys.argv[1] == "--litp-backup-and-restore":
        run.litp_backup_restore()
    # LITP RESTORE SNAPSHOT
    if sys.argv[1] == "--restore_snapshot":
        run.restore_snapshot()
    # RUN CLEANUP
    run.cleanupai(collect_logs=False)
    sys.exit(0)
    #run = LITPIsoSetup(sys.argv[1], sys.argv[2])
    #run.prepare_litp_iso()


if __name__ == '__main__':
    main()
