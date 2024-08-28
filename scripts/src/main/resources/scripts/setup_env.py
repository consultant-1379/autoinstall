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
@summary:   Common methods for vcs commands
'''

import sys
import os
from common_platform_files.common_methods import NodeConnect

class setUpAI():
    """
    Class to setup the autoinstall job with given paramaters
    """
    def __init__(self, ai_params):
        """
        Initialise variables
        """

        self.node = NodeConnect()
        self.ai_params = ai_params

    def create_setup(self):
        """
        Create the setup
        """

        if self.ai_params["AI_OPTION"] in ["-ci", "--complete-install", "-litpms", "--litp-ms-install", "--rhel-install", "-rhel", "--complete-litp-install-upgrade", "-ciu"]:
            cmd = 'curl %s --head -k -s -S | grep "HTTP/"' % self.ai_params["RHEL_ISO"]
            stdout, stderr, retc = self.node.run_command_local(cmd, logs=False)
            if not any("OK" in line for line in stdout) or retc != 0:
                print ">> ERROR: RHEL FILE DOES NOT EXIST: %s" % self.ai_params["RHEL_ISO"]
                sys.exit(1)

        if self.ai_params["AI_OPTION"] in ["-ci", "--complete-install", "-litpms", "--litp-ms-install", "--rhel-ms-install", "-rhelms", "--rhel-litp-install", "-rhellitp", "--complete-litp-install-upgrade", "-ciu"]:
            # CHECK GIVEN LITP ISO EXISTS IN THE DESIGNATED DIRECTORY
            if not os.path.isfile(self.ai_params["LITP_ISO"]):
                print ">> ERROR: LITP ISO: %s DOES NOT EXIST" % (self.ai_params["LITP_ISO"])
                sys.exit(1)


        # CHECK GIVEN LITP UPGRADE EXISTS IN THE DESIGNATED DIRECTORY, IF OPTION GIVEN
        if self.ai_params["LITP_UPGRADE"]:
            if not os.path.isfile(self.ai_params["LITP_UPGRADE_ISO"]):
                print ">> ERROR: %s DOES NOT EXIST" % self.ai_params["LITP_UPGRADE_ISO"]
                sys.exit(1)
            print "UPGRADE ISO exists: %s" % self.ai_params["LITP_UPGRADE_ISO"]

        if self.ai_params["OS_PATCHES"]:
            if "http" in self.ai_params["OS_PATCHES_PATH"]:
                cmd = 'curl %s --head -k -s -S | grep "HTTP/"' % self.ai_params["OS_PATCHES_PATH"]
                stdout, stderr, retc = self.node.run_command_local(cmd, logs=False)
                if "OK" not in stdout[0] or retc != 0:
                    print ">> ERROR: %s DOES NOT EXIST" % self.ai_params["OS_PATCHES_PATH"]
                    sys.exit(1)
            else:
                if not os.path.isfile(self.ai_params["OS_PATCHES_PATH"]):
                    print ">> ERROR: %s DOES NOT EXIST" % self.ai_params["OS_PATCHES_PATH"]
                    sys.exit(1)
            print "OS PATCHES exists: %s" % self.ai_params["OS_PATCHES_PATH"]

        # CHECK GIVEN OS PATCHES fOR UPGRADE EXISTS IN THE DESIGNATED DIRECTORY, IF OPTION GIVEN
        if self.ai_params["OS_PATCHES_UPGRADE"]:
            if "http" in self.ai_params["OS_PATCHES_PATH_UPGRADE"]:
                cmd = 'curl %s --head -k -s -S | grep "HTTP/"' % self.ai_params["OS_PATCHES_PATH_UPGRADE"]
                stdout, stderr, retc = self.node.run_command_local(cmd, logs=False)
                if "OK" not in stdout[0] or retc != 0:
                    print ">> ERROR: %s DOES NOT EXIST" % self.ai_params["OS_PATCHES_PATH_UPGRADE"]
                    sys.exit(1)
            else:
                if not os.path.isfile(self.ai_params["OS_PATCHES_PATH_UPGRADE"]):
                    print ">> ERROR: %s DOES NOT EXIST" % self.ai_params["OS_PATCHES_PATH_UPGRADE"]
                    sys.exit(1)
            print "OS PATCHES UPGRADE exists: %s" % self.ai_params["OS_PATCHES_PATH_UPGRADE"]

        if self.ai_params["AI_OPTION"] in ["-ci", "--complete-install", "-litpms", "--litp-ms-install", "--litp-cluster-install", "-litpc", "--rhel-install", "-rhel", "--rhel-ms-install", "-rhelms", "--rhel-litp-install", "-rhellitp", "--complete-litp-install-upgrade", "-ciu", "--litp-upgrade", "-litpup", "-elc", "--expand-litp-cluster", "-lbr", "--litp-backup-and-restore"]:

            # CHECK GIVEN CLUSTER FILE EXISTS IN THE DESIGNATED DIRECTORY
            if not os.path.isfile(self.ai_params["CLUSTER_FILE"]):
                print ">> ERROR: %s DOES NOT EXIST. A cluster file is needed to complete all types of autoinstall options. See autoinstall --help for more information" % self.ai_params["CLUSTER_FILE"]
                sys.exit(1)
            print "CLUSTER FILE exists: %s" % self.ai_params["CLUSTER_FILE"]

        if self.ai_params["AI_OPTION"] in ["-ci", "--complete-install", "--litp-cluster-install", "-litpc", "--rhel-litp-install", "-rhellitp", "--complete-litp-install-upgrade", "-ciu"]:
            # CHECK GIVEN INSTALL SCRIPT EXISTS IN THE DESIGNATED DIRECTORY
            if not os.path.isfile(self.ai_params["INSTALL_SCRIPT"]):
                print ">> ERROR: %s DOES NOT EXIST" % self.ai_params["INSTALL_SCRIPT"]
                sys.exit(1)
            print "INSTALL SCRIPT exists: %s" % self.ai_params["INSTALL_SCRIPT"]

            if self.ai_params["INSTALL_SCRIPT"].endswith(".xml"):
                if self.ai_params["INSTALL_OPTION"] == "CLI":
                    print ">> ERROR: CLI deploy option chosen but no .sh file given"
                    sys.exit(1)
                if self.ai_params["PRE_XML_LOAD_SCRIPT"]:
                    if not os.path.isfile(self.ai_params["PRE_XML_LOAD_SCRIPT"]):
                        print ">> ERROR: %s DOES NOT EXIST" % self.ai_params["PRE_XML_LOAD_SCRIPT"]

        if self.ai_params["AI_OPTION"] in ["-ci", "--complete-install", "-litpms", "--litp-ms-install", "--rhel-install", "-rhel", "--complete-litp-install-upgrade", "-ciu"]:
            # CHECK HTTP DIRECTORY EXISTS OVER HTTP AND ON SERVER
            cmd = 'curl %s --head -k -s -S | grep "HTTP/"' % self.ai_params["SERVER_HTTP_LOCATION"]
            stdout, stderr, retc = self.node.run_command_local(cmd, logs=False)
            if "OK" not in stdout[0] or retc != 0:
                print ">> ERROR: SERVER LOCATION DIRECTORY DOES NOT EXIST: %s" % self.ai_params["SERVER_HTTP_LOCATION"]
                sys.exit(1)

        if not os.path.isdir(self.ai_params["SERVER_HTTP_LOCATION_PATH"]):
            print ">> ERROR: %s DOES NOT EXIST" % self.ai_params["SERVER_HTTP_LOCATION_PATH"]
            sys.exit(1)

        # CREATE A DIRECTORY SPECIFIC FOR THIS AUTOINSTALL JOB WITH JENKINS ID

        self.ai_params["AUTOINSTALL_DIR"] = self.ai_params["SERVER_HTTP_LOCATION_PATH"] + self.ai_params["JENKINS_JOB_ID"]
        if not os.path.isdir(self.ai_params["AUTOINSTALL_DIR"]):
            os.mkdir(self.ai_params["AUTOINSTALL_DIR"])
        else:
            print ">> ERROR: %s already exists" % self.ai_params["AUTOINSTALL_DIR"]
            sys.exit(1)

        # COPY LITP ISO TO THIS DIRECTORY FOR USE IN AUTOINSTALL
        if self.ai_params["AI_OPTION"] in ["-ci", "--complete-install", "-litpms", "--litp-ms-install", "--rhel-ms-install", "-rhelms", "--rhel-litp-install", "-rhellitp", "--complete-litp-install-upgrade", "-ciu"]:
            stdout, stderr, retc = self.node.run_command_local("cp %s %s" % (self.ai_params["LITP_ISO"], self.ai_params["AUTOINSTALL_DIR"]), logs=False)
            if stdout != [] or stderr != [] or retc != 0:
                print ">> ERROR: COPY OF LITP ISO FAILED %s" % stderr
                sys.exit(1)
        # COPY INSTALL SCRIPT, CLUSTER FILE AND PRE_XML_LOAD SCRIPT TO THIS DIRECTORY FOR USE IN AUTOINSTALL
        if self.ai_params["AI_OPTION"] in ["-ci", "--complete-install", "-litpms", "--litp-ms-install", "--litp-cluster-install", "-litpc", "--rhel-install", "-rhel", "--rhel-ms-install", "-rhelms", "--rhel-litp-install", "-rhellitp", "--complete-litp-install-upgrade", "-ciu", "--litp-upgrade", "-litpup", "-elc", "--expand-litp-cluster"]:
            stdout, stderr, retc = self.node.run_command_local("cp %s %s" % (self.ai_params["CLUSTER_FILE"], self.ai_params["AUTOINSTALL_DIR"]), logs=False)
            if stdout != [] or stderr != [] or retc != 0:
                print ">> ERROR: COPY OF CLUSTER FILE FAILED"
                sys.exit(1)
        if self.ai_params["AI_OPTION"] in ["-ci", "--complete-install", "--litp-cluster-install", "-litpc", "--rhel-litp-install", "-rhellitp", "--complete-litp-install-upgrade", "-ciu"]:
            stdout, stderr, retc = self.node.run_command_local("cp %s %s" % (self.ai_params["INSTALL_SCRIPT"], self.ai_params["AUTOINSTALL_DIR"]), logs=False)
            if stdout != [] or stderr != [] or retc != 0:
                print ">> ERROR: COPY OF INSTALL SCRIPT FAILED"
                sys.exit(1)
        if self.ai_params["PRE_XML_LOAD_SCRIPT"]:
            stdout, stderr, retc = self.node.run_command_local("cp %s %s" % (self.ai_params["PRE_XML_LOAD_SCRIPT"],self.ai_params["AUTOINSTALL_DIR"]), logs=False)
            if stdout != [] or stderr != [] or retc != 0:
                print ">> ERROR: COPY OF PRE_XML_LOAD SCRIPT FAILED"
                sys.exit(1)
            self.ai_params["PRE_XML_LOAD_FILE"] = self.ai_params["PRE_XML_LOAD_SCRIPT"].split("/")[-1]

        if self.ai_params["AI_OPTION"] in ["-elc", "--expand-litp-cluster"]:
            # CHECK GIVEN EXPAND SCRIPT EXISTS IN THE DESIGNATED DIRECTORY
            if not os.path.isfile(self.ai_params["EXPAND_SCRIPT"]):
                print ">> ERROR: %s DOES NOT EXIST" % self.ai_params["EXPAND_SCRIPT"]
                sys.exit(1)
            print "EXPAND SCRIPT exists: %s" % self.ai_params["EXPAND_SCRIPT"]

            # COPY EXPAND SCRIPT
            stdout, stderr, retc = self.node.run_command_local("cp %s %s" % (self.ai_params["EXPAND_SCRIPT"], self.ai_params["AUTOINSTALL_DIR"]), logs=False)
            if stdout != [] or stderr != [] or retc != 0:
                print ">> ERROR: COPY OF EXPAND SCRIPT FAILED"
                sys.exit(1)

        # CREATE A FILE WITH INFORMATION FOR USE BY AUTOINSTALL - SINGLEBLADE/MULTIBLADE/MS NETWORK INFORMATION/ etc...
        
        cmd = "cat %s | grep ms_ilo_ip" % self.ai_params["CLUSTER_FILE"]
        stdout, stderr, retc = self.node.run_command_local(cmd, logs=False)
        if stdout == [] or stderr != [] or retc != 0:
            print ">> ERROR: CAT OF CLUSTER FILE FAILED %s - No ms_ilo_ip property exists" % self.ai_params["CLUSTER_FILE"]
            print stdout
            print stderr
            sys.exit(1)
        self.ai_params["MS_ILO_IP"] = stdout[0].replace('"', "")
        self.ai_params["MS_ILO_IP"] = self.ai_params["MS_ILO_IP"].replace('ms_ilo_ip=', "")

        cmd = "cat %s | grep ms_ilo_username" % self.ai_params["CLUSTER_FILE"]
        stdout, stderr, retc = self.node.run_command_local(cmd, logs=False)
        if stdout == [] or stderr != [] or retc != 0:
            print ">> ERROR: CAT OF CLUSTER FILE FAILED %s - No ms_ilo_username property exists" % self.ai_params["CLUSTER_FILE"]
            print stdout
            print stderr	
            sys.exit(1)
        self.ai_params["MS_ILO_USER"] = stdout[0].replace('"', "")
        self.ai_params["MS_ILO_USER"] = self.ai_params["MS_ILO_USER"].replace('ms_ilo_username=', "")

        cmd = "cat %s | grep ms_ilo_password" % self.ai_params["CLUSTER_FILE"]
        stdout, stderr, retc = self.node.run_command_local(cmd, logs=False)
        if stdout == [] or stderr != [] or retc != 0:
            print ">> ERROR: CAT OF CLUSTER FILE FAILED %s - No ms_ilo_password property exists" % self.ai_params["CLUSTER_FILE"]
            print stdout
            print stderr	
            sys.exit(1)
        self.ai_params["MS_ILO_PASSWORD"] = stdout[0].replace('"', "")
        self.ai_params["MS_ILO_PASSWORD"] = self.ai_params["MS_ILO_PASSWORD"].replace("'", "")
        self.ai_params["MS_ILO_PASSWORD"] = self.ai_params["MS_ILO_PASSWORD"].replace('ms_ilo_password=', "")

        cmd = "cat %s | grep ms_ip" % self.ai_params["CLUSTER_FILE"]
        stdout, stderr, retc = self.node.run_command_local(cmd, logs=False)
        if stdout == [] or stderr != [] or retc != 0:
            print ">> ERROR: CAT OF CLUSTER FILE FAILED - No ms_ip property exists"
            sys.exit(1)
        self.ai_params["MS_IP"] = stdout[0].replace('"', "")
        self.ai_params["MS_IP"] = self.ai_params["MS_IP"].replace('ms_ip=', "")

        cmd = "cat %s | grep ms_poweroff_ip" % self.ai_params["CLUSTER_FILE"]
        stdout, stderr, retc = self.node.run_command_local(cmd, logs=False)
        if stdout == []:
            self.ai_params["MS_POWEROFF_IP"] = self.ai_params["MS_IP"]
        else:
            self.ai_params["MS_POWEROFF_IP"] = stdout[0].replace('"', "")
            self.ai_params["MS_POWEROFF_IP"] = self.ai_params["MS_POWEROFF_IP"].replace('ms_poweroff_ip=', "")

        cmd = "cat %s | grep ms_subnet" % self.ai_params["CLUSTER_FILE"]
        stdout, stderr, retc = self.node.run_command_local(cmd, logs=False)
        if stdout == [] or stderr != [] or retc != 0:
            print ">> ERROR: CAT OF CLUSTER FILE FAILED - No ms_subnet property exists"
            sys.exit(1)
        ms_subnettmp = stdout[0].replace('"', "")
        self.ai_params["MS_SUBNET"] = ms_subnettmp.replace('ms_subnet=', "")
        #ms_subnet = ms_subnettmp.split("/")[-1]

        cmd = "cat %s | grep ms_gateway" % self.ai_params["CLUSTER_FILE"]
        stdout, stderr, retc = self.node.run_command_local(cmd, logs=False)
        if stdout == [] or stderr != [] or retc != 0:
            print ">> ERROR: CAT OF CLUSTER FILE FAILED - No ms_gateway property exists"
            sys.exit(1)
        self.ai_params["MS_GATEWAY"] = stdout[0].replace('"', "")
        self.ai_params["MS_GATEWAY"] = self.ai_params["MS_GATEWAY"].replace('ms_gateway=', "")

        cmd = "cat %s | grep blade_type" % self.ai_params["CLUSTER_FILE"]
        stdout, stderr, retc = self.node.run_command_local(cmd, logs=False)
        if stdout == [] or stderr != [] or retc != 0:
            print ">> ERROR: CAT OF CLUSTER FILE FAILED - No blade_type property exists"
            sys.exit(1)
        self.ai_params["MS_BLADE_TYPE"] = stdout[0].replace('"', "")
        self.ai_params["MS_BLADE_TYPE"] = self.ai_params["MS_BLADE_TYPE"].replace('blade_type=', "")

        cmd = "cat %s | grep ms_vlan" % self.ai_params["CLUSTER_FILE"]
        stdout, stderr, retc = self.node.run_command_local(cmd, logs=False)
        if stdout == [] or stderr != [] or retc != 0:
            print ">> ERROR: CAT OF CLUSTER FILE FAILED - No ms_vlan property exists"
            sys.exit(1)
        self.ai_params["MS_VLAN"] = stdout[0].replace('"', "")
        self.ai_params["MS_VLAN"] = self.ai_params["MS_VLAN"].replace('ms_vlan=', "")

        install_nic = "eth0"
        cmd = "cat %s | grep install_with_nic" % self.ai_params["CLUSTER_FILE"]
        stdout, stderr, retc = self.node.run_command_local(cmd, logs=False)
        if stdout == [] or stderr != [] or retc != 0:
            self.ai_params["MS_INSTALL_NIC"] = "eth0"
        else:
            self.ai_params["MS_INSTALL_NIC"] = stdout[0].replace('"', "")
            self.ai_params["MS_INSTALL_NIC"] = self.ai_params["MS_INSTALL_NIC"].replace('install_with_nic=', "")

        cmd = "cat %s | grep ms_%s_mac" % (self.ai_params["CLUSTER_FILE"], install_nic)
        stdout, stderr, retc = self.node.run_command_local(cmd, logs=False)
        if stdout == [] or stderr != [] or retc != 0:
            print ">> ERROR: CAT OF CLUSTER FILE FAILED - No ms_install_mac property exists"
            sys.exit(1)
        self.ai_params["MS_INSTALL_MAC_ADDRESS"] = stdout[0].replace('"', "")
        self.ai_params["MS_INSTALL_MAC_ADDRESS"] = self.ai_params["MS_INSTALL_MAC_ADDRESS"].replace('ms_install_mac=', "")

        cmd = "cat %s | grep -vE ^'#|node_expansion_hostname' | grep hostname | cut -d = -f 2 |  tr '\n' ',' | sed 's/,\+$//'; echo ''" % self.ai_params["CLUSTER_FILE"]
        stdout, stderr, retc = self.node.run_command_local(cmd, logs=False)
        if stdout == [] or stderr != [] or retc != 0:
            print ">> ERROR: CAT OF CLUSTER FILE FAILED - No hostname properties exist"
            sys.exit(1)
        self.ai_params["NODE_HOSTNAMES"] = stdout[0].replace('"', '')

        cmd = "cat %s | grep 'node_ip\[' | cut -d = -f 2 |  tr '\n' ',' | sed 's/,\+$//'; echo ''" % self.ai_params["CLUSTER_FILE"]
        stdout, stderr, retc = self.node.run_command_local(cmd, logs=False)
        if stdout == [] or stderr != [] or retc != 0:
            print ">> ERROR: CAT OF CLUSTER FILE FAILED - No ip properties exist"
        #print stdout
            sys.exit(1)

        self.ai_params["NODE_IPS"] = stdout[0]
        self.ai_params["NODE_IPS"] = self.ai_params["NODE_IPS"].replace('"', '')

        cmd = "cat %s | grep 'sfs_cleanup_list=' | grep -v '#' | sed 's/sfs_cleanup_list=//' |  tr '\n' ',' | sed 's/,\+$//'" % self.ai_params["CLUSTER_FILE"]
        stdout, stderr, retc = self.node.run_command_local(cmd, logs=False)
        if stdout != []:
            self.ai_params["SFS_FILESYSTEM_CLEANUP"] = stdout[0]
            self.ai_params["SFS_FILESYSTEM_CLEANUP"] = self.ai_params["SFS_FILESYSTEM_CLEANUP"].replace('"', '')
        else:
            self.ai_params["SFS_FILESYSTEM_CLEANUP"] = "no_sfs_cleanup"

        cmd = "cat %s | grep 'sfs_snapshot_cleanup_list=' | grep -v '#' | sed 's/sfs_snapshot_cleanup_list=//' |  tr '\n' ',' | sed 's/,\+$//'" % self.ai_params["CLUSTER_FILE"]
        stdout, stderr, retc = self.node.run_command_local(cmd, logs=False)
        if stdout != []:
            self.ai_params["SFS_SNAPSHOT_CLEANUP"] = stdout[0]
            self.ai_params["SFS_SNAPSHOT_CLEANUP"] = self.ai_params["SFS_SNAPSHOT_CLEANUP"].replace('"', '')
        else:
            self.ai_params["SFS_SNAPSHOT_CLEANUP"] = "no_sfs_snapshot_cleanup"

        cmd = "cat %s | grep 'sfs_cleanup_list_restore=' | grep -v '#' | sed 's/sfs_cleanup_list_restore=//' |  tr '\n' ',' | sed 's/,\+$//'" % self.ai_params["CLUSTER_FILE"]
        stdout, stderr, retc = self.node.run_command_local(cmd, logs=False)
        if stdout != []:
            self.ai_params["SFS_FILESYSTEM_CLEANUP_RESTORE"] = stdout[0]
            self.ai_params["SFS_FILESYSTEM_CLEANUP_RESTORE"] = self.ai_params["SFS_FILESYSTEM_CLEANUP_RESTORE"].replace('"', '')
        else:
            self.ai_params["SFS_FILESYSTEM_CLEANUP_RESTORE"] = "no_sfs_cleanup"

        ##Optional sanity ips parameter used when main ip is not
            

        cmd = "cat %s | grep -v ^'#' | grep 'sanity_node_ip_check\[' | cut -d = -f 2 |  tr '\n' ',' | sed 's/,\+$//'" % self.ai_params["CLUSTER_FILE"]
        stdout, stderr, retc = self.node.run_command_local(cmd, logs=False)
        if stdout != []:
            self.ai_params["SANITY_CHECK_IPS"] = stdout[0]
            self.ai_params["SANITY_CHECK_IPS"] = self.ai_params["SANITY_CHECK_IPS"].replace('"', '')
        else:
            self.ai_params["SANITY_CHECK_IPS"] = "no_sanity"

        cmd = "cat %s | grep -v ^'#' | grep 'prepare_restore_shutdown_ip\[' | cut -d = -f 2 |  tr '\n' ',' | sed 's/,\+$//'" % self.ai_params["CLUSTER_FILE"]
        stdout, stderr, retc = self.node.run_command_local(cmd, logs=False)
        if stdout != []:
            self.ai_params["RESTORE_REBOOT_IPS"] = stdout[0]
            self.ai_params["RESTORE_REBOOT_IPS"] = self.ai_params["RESTORE_REBOOT_IPS"].replace('"', '')
        else:
            self.ai_params["RESTORE_REBOOT_IPS"] = "no_reboot"

        ##Optional ips for cluster expansion
        cmd = "cat %s | grep 'node_expansion_ip\[' | cut -d = -f 2 |  tr '\n' ',' | sed 's/,\+$//'" % self.ai_params["CLUSTER_FILE"]
        stdout, stderr, retc = self.node.run_command_local(cmd, logs=False)
        if stdout != []:
            self.ai_params["EXPANSION_NODE_IPS"] = stdout[0]
        else:
            self.ai_params["EXPANSION_NODE_IPS"] = "no_expansion"
        self.ai_params["EXPANSION_NODE_IPS"] = self.ai_params["EXPANSION_NODE_IPS"].replace('"', '')

        ##Optional ips for cluster hostnames
        cmd = "cat %s | grep 'node_expansion_hostname\[' | cut -d = -f 2 |  tr '\n' ',' | sed 's/,\+$//'" % self.ai_params["CLUSTER_FILE"]
        stdout, stderr, retc = self.node.run_command_local(cmd, logs=False)
        if stdout != []:
            self.ai_params["EXPANSION_HOSTNAMES"] = stdout[0]
        else:
            self.ai_params["EXPANSION_HOSTNAMES"] = "no_expansion"
        self.ai_params["EXPANSION_HOSTNAMES"] = self.ai_params["EXPANSION_HOSTNAMES"].replace('"', '')

        cmd = "cat %s | grep 'node_expansion_bmc_ip\[' | cut -d = -f 2 |  tr '\n' ',' | sed 's/,\+$//'" % self.ai_params["CLUSTER_FILE"]
        stdout, stderr, retc = self.node.run_command_local(cmd, logs=False)
        if stdout != []:
            self.ai_params["EXPANSION_NODE_ILO_IPS"] = stdout[0]
        else:
            self.ai_params["EXPANSION_NODE_ILO_IPS"] = "no_expansion"
        self.ai_params["EXPANSION_NODE_ILO_IPS"] = self.ai_params["EXPANSION_NODE_ILO_IPS"].replace('"', '')

        cmd = "cat %s | grep -v ^'#' | grep 'node_bmc_ip\[' | cut -d = -f 2 |  tr '\n' ',' | sed 's/,\+$//'" % self.ai_params["CLUSTER_FILE"]
        stdout, stderr, retc = self.node.run_command_local(cmd, logs=False)
        if stdout != []:
            self.ai_params["NODE_ILO_IPS"] = stdout[0]
        else:
            self.ai_params["NODE_ILO_IPS"] = "no_poweroff"
        self.ai_params["NODE_ILO_IPS"] = self.ai_params["NODE_ILO_IPS"].replace('"', '')

        cmd = "cat %s | grep ms_host | grep -v ms_host_short | grep -v '#'" % self.ai_params["CLUSTER_FILE"]
        stdout, stderr, retc = self.node.run_command_local(cmd, logs=False)
        if stdout == [] or stderr != [] or retc != 0:
            print ">> ERROR: CAT OF CLUSTER FILE FAILED - No ms_host property exists"
            sys.exit(1)
        self.ai_params["MS_HOSTNAME"] = stdout[0].replace('"', "")
        self.ai_params["MS_HOSTNAME"] = self.ai_params["MS_HOSTNAME"].replace('ms_host=', "")

        if self.ai_params["AI_OPTION"] in ["-ci", "--complete-install", "-litpms", "--litp-ms-install", "--rhel-install", "-rhel", "--rhel-ms-install", "-rhelms", "--rhel-litp-install", "-rhellitp", "--complete-litp-install-upgrade", "-ciu"]:
            iso_litp = self.ai_params["LITP_ISO"].split("/")
            self.ai_params["ISO_FILE"] = iso_litp[-1]
        if self.ai_params["AI_OPTION"] in ["-ci", "--complete-install", "--litp-cluster-install", "-litpc", "--rhel-litp-install", "-rhellitp", "--complete-litp-install-upgrade", "-ciu"]:
            file_install = self.ai_params["INSTALL_SCRIPT"].split("/")
            self.ai_params["INSTALL_FILE"] = file_install[-1]

        if self.ai_params["AI_OPTION"] in ["-elc", "--expand-litp-cluster"]:
            expand_install = self.ai_params["EXPAND_SCRIPT"].split("/")
            self.ai_params["EXPAND_FILE"] = expand_install[-1]

        if self.ai_params["AI_OPTION"] in ["-ci", "--complete-install", "-litpms", "--litp-ms-install", "--litp-cluster-install", "-litpc", "--rhel-install", "-rhel", "--rhel-ms-install", "-rhelms", "--rhel-litp-install", "-rhellitp", "--complete-litp-install-upgrade", "-ciu", "--litp-upgrade", "-litpup", "-elc", "--expand-litp-cluster"]:
            file_cluster = self.ai_params["CLUSTER_FILE"].split("/")
            self.ai_params["CLUSTER_FILE_NAME"] = file_cluster[-1]

        if self.ai_params["FAIL_SCRIPT"] != None:
            if not os.path.isfile(self.ai_params["FAIL_SCRIPT"]):
                print ">> ERROR: FAIL SCRIPT DOES NOT EXIST: %s" % (self.ai_params["FAIL_SCRIPT"])
                sys.exit(1)
            stdout, stderr, retc = self.node.run_command_local("cp %s %s" % (self.ai_params["FAIL_SCRIPT"], self.ai_params["AUTOINSTALL_DIR"]), logs=False)
            if stdout != [] or stderr != [] or retc != 0:
                print ">> ERROR: COPY OF FAILED PLAN SCRIPT FILE FAILED"
                sys.exit(1)
            self.ai_params["INSTALL_RUN_SECOND_SCRIPT"] = self.ai_params["FAIL_SCRIPT"].split("/")[-1]

        if self.ai_params["MONITOR_SCRIPT"]:
            if not os.path.isfile(self.ai_params["MONITOR_SCRIPT"]):
                print ">> ERROR: MONITOR SCRIPT DOES NOT EXIST: %s" % (self.ai_params["MONITOR_SCRIPT"])
                sys.exit(1)

            stdout, stderr, retc = self.node.run_command_local("cp %s %s" % (self.ai_params["MONITOR_SCRIPT"], self.ai_params["AUTOINSTALL_DIR"]), logs=False)
            if stdout != [] or stderr != [] or retc != 0:
                print ">> ERROR: COPY OF MONITOR PLAN SCRIPT FILE FAILED"
                sys.exit(1)

            file_mon = self.ai_params["MONITOR_SCRIPT"].split("/")
            self.ai_params["MONITOR_FILE_NAME"] = file_mon[-1]

        return self.ai_params

def main():
    """
    main function
    """

    # Disable output buffering to receive the output instantly
    sys.stdout = os.fdopen(sys.stdout.fileno(), "w", 0)
    sys.stderr = os.fdopen(sys.stderr.fileno(), "w", 0)
    if len(sys.argv) != 10:
        print ">> ERROR: Not all required arguments supplied: %s" % sys.argv
        sys.exit(1)

    run = setUpAI(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6], sys.argv[7], sys.argv[8], sys.argv[9])
    run.create_setup()

if  __name__ == '__main__':main()
