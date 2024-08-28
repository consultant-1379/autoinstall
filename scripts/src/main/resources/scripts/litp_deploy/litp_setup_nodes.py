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
@summary:   Set up peer nodes
'''

import sys
import os
from common_platform_files.common_methods import NodeConnect
import common_platform_files.constants as constants
import time
import pexpect
from datetime import datetime

class SetupLitpNodes():
    """
    Class to setup the peer nodes post install
    """
    def __init__(self, ai_params):
        """
        Initialise variables
        """

        #self.node = common_methods.NodeConnect(ms_ip, contstants.LITPUSER, constants.AITMPPASSWORD)
        self.ai_params = ai_params
        self.node = NodeConnect(self.ai_params["MS_IP"], constants.LITP_USER, constants.LITP_USER_MS_PASSWD)
        self.hostnames = self.ai_params["NODE_HOSTNAMES"].split(",")
        self.skip_passwd = self.ai_params["SKIP_PEER_NODE_PASSWD"]
        self.pw_attempts = 10
        self.cmw_cluster = False

    def mytime(self, t1, t2):
        """
        Difference between 2 times
        """
        timediff = 0
        if int(t1.minute) != int(t2.minute):
            if int(t2.minute) > int(t1.minute):
                new_t2 = int(t2.second) + 60
                timediff = new_t2 - int(t1.second)
            else:
                new_t2 = int(t2.second) + 60
                timediff = new_t2 - int(t1.second)
        else:
            timediff = int(t2.second) - int(t1.second)

        print "Time taken was: ", timediff

        return timediff

    def setup_node_passwords(self):
        """
        Set the node passwords to the current default.
        """
        ##1. Copy password setting scripts to MS
        local_path = os.path.dirname(os.path.realpath(__file__))

        #a. Script to set litp-admin password
        script = local_path + "/passwdsetup_litp_admin.exp"
        remote_path = "/tmp/passwdsetup_litp_admin.exp"
        print "Copy of %s to %s on %s" % (script, remote_path, self.ai_params["MS_IP"])
        self.node.copy_file(script, remote_path)

        #b. Script to verify root password
        script = local_path + "/check_root_pw.exp"
        remote_path = "/tmp/check_root_pw.exp"
        print "Copy of %s to %s on %s" % (script, remote_path, self.ai_params["MS_IP"])
        self.node.copy_file(script, remote_path)

        #c. Script to verify password
        script = local_path + "/check_litp_admin_pw.exp"
        remote_path = "/tmp/check_litp_admin_pw.exp"
        print "Copy of %s to %s on %s" % (script, remote_path, self.ai_params["MS_IP"])
        self.node.copy_file(script, remote_path)

        #d. If cmw cluster password will not age
        if self.cmw_cluster:
            # Script to set root password without password age
            script = local_path + "/passwdsetup_root_noage.exp"
            remote_path = "/tmp/passwdsetup_root_noage.exp"
            print "Copy of %s to %s on %s" % (script, remote_path, self.ai_params["MS_IP"])
            self.node.copy_file(script, remote_path)
        else:
            # Script to set root password with password age
            script = local_path + "/passwdsetup_root.exp"
            remote_path = "/tmp/passwdsetup_root.exp"
            print "Copy of %s to %s on %s" % (script, remote_path, self.ai_params["MS_IP"])
            self.node.copy_file(script, remote_path)

        ##2. Loop through each node
        for host in self.hostnames:
            ##########################################
            #>. SET LITP-ADMIN TO TMP PASSWORD
            password_success = False
            for attempt in range(0, self.pw_attempts):
                #Attempt to set tmp password
                cmd = "expect /tmp/passwdsetup_litp_admin.exp %s %s %s" %\
                    (host, constants.PEERNODE_LITP_USER_DEFAULT_PASSWD,
                     constants.PEERNODE_TMP_PASSWD)
                self.node.run_command(cmd)

                #2. CHECK TMP PASSWORD SET
                check_pw_cmd = "expect /tmp/check_litp_admin_pw.exp %s %s %s" %\
                    ("litp-admin", constants.PEERNODE_TMP_PASSWD, host)
                stdout, stderr, retc = self.node.run_command(check_pw_cmd)

                if retc == 0:
                    password_success=True
                    break

                #3 SLEEP AND TRY AGAIN IF PW NOT SET
                print ">>>>Attempt {0} to set password failed"\
                    .format(attempt)
                time.sleep(5)

            #IF PW SET AND ALL ATTEMPTS FAIL REPORT ERROR
            if not password_success:
                print ">> ERROR: PASSWORDS DID NOT UPDATE SUCCESSFULLY ON NODE {0}".format(host)
                return False

            #################################################
            #>. SET LITP-ADMIN AND ROOT TO FINAL PASSWORD
            password_root_success = False
            password_admin_success = False

            for attempt in range(0, self.pw_attempts):

                #5. ATTEMPT TO SET PWs
                if self.cmw_cluster:
                    cmd = "expect /tmp/passwdsetup_root_noage.exp %s %s %s %s %s" %\
                        (host, constants.PEERNODE_TMP_PASSWD,
                         constants.LITP_USER_PEERNODE_PASSWD,
                         constants.PEERNODE_ROOT_DEFAULT_PASSWD,
                         constants.ROOT_PEERNODE_PASSWD)
                    self.node.run_command(cmd)
                else:
                    cmd = "expect /tmp/passwdsetup_root.exp %s %s %s %s %s" %\
                        (host, constants.PEERNODE_TMP_PASSWD,
                         constants.LITP_USER_PEERNODE_PASSWD,
                         constants.PEERNODE_ROOT_DEFAULT_PASSWD,
                         constants.ROOT_PEERNODE_PASSWD)
                    self.node.run_command(cmd)

                ##6. CHECK LITP_ADMIN IS SET
                check_pw_cmd = "expect /tmp/check_litp_admin_pw.exp %s %s %s" %\
                    ("litp-admin", constants.LITP_USER_PEERNODE_PASSWD, host)
                stdout, stderr, retc = self.node.run_command(check_pw_cmd)
                if retc == 0:
                    password_admin_success = True

                ##7. CHECK ROOT PASSWORD IS SET
                check_pw_cmd = "expect /tmp/check_root_pw.exp %s %s %s %s" %\
                    ("litp-admin", constants.LITP_USER_PEERNODE_PASSWD, host,
                     constants.ROOT_PEERNODE_PASSWD)
                stdout, stderr, retc = self.node.run_command(check_pw_cmd)
                if password_admin_success and retc == 0:
                    password_root_success = True
                    break

		#8. Attempt to set root PW assuming no password age (cmw)
		if not password_root_success:
		   cmd = "expect /tmp/passwdsetup_root_noage.exp %s %s %s %s" %\
                    (host,
                     constants.LITP_USER_PEERNODE_PASSWD,
                     constants.PEERNODE_ROOT_DEFAULT_PASSWD,
                     constants.ROOT_PEERNODE_PASSWD)
                self.node.run_command(cmd)

                #9. SLEEP AND TRY AGAIN IF PW NOT SET
                print "Attempt {0} to set password failed".format(attempt)
                time.sleep(5)

            #10. IF PW SET AND ALL ATTEMPTS FAIL REPORT ERROR
            if not password_root_success and password_admin_success:
                print ">> ERROR: PASSWORDS DID NOT UPDATE SUCCESSFULLY ON NODE {0}".format(host)
                return False

        return True

    def setup_litp_nodes(self):
        """
        Update nodes if needed
        """

        print ""
        print "#########################################################"
        print ">> INFO: LITP MANAGED NODE SETUP"
        print "#########################################################"
        print ""
        print "Nodes to setup are: %s" % self.hostnames
        print ""

        cmd = "clust=( $(/usr/bin/litp show -p / -r | grep -B 2 'type' | grep -B 2 'cmw-cluster'$ | grep ^'/')); if [ ${#clust[@]} -ne 0 ] ;then nodes=( $(/usr/bin/litp show -p ${clust[0]} -r | grep -B 2 'type: node' | grep ^'/') ); for val in ${nodes[@]}; do litp show -p $val | grep 'hostname:' | sed 's/ //g' | sed 's/hostname://g'; done; fi"
        stdout, stderr, retc = self.node.run_command(cmd)
        if retc != 0 or stderr != []:
            print ">> ERROR: RUNNING LITP COMMANDS FAILED"
            return False

        cmw_host_list = []
        if stdout != []:
            cmw_host_list.extend(stdout)
            self.cmw_cluster = True

        if not self.skip_passwd:
            password_success = self.setup_node_passwords()

            if not password_success:
                return False

            cmd = "rm -rf /tmp/passwdsetup_litp_admin.exp /tmp/passwdsetup_root.exp /tmp/check_root_pw.exp /tmp/check_litp_admin_pw.exp /tmp/passwdsetup_root_noage.exp"
            stdout, stderr, retc = self.node.run_command(cmd)
            if retc != 0:
                print ">> ERROR: FILES NOT REMOVED SUCCESSFULLY"
                return False
        else:
            print ">> INFO: Skipping Managed Node Password Setup."

        return True

def main():
    """
    main function
    """

    # Disable output buffering to receive the output instantly
    sys.stdout = os.fdopen(sys.stdout.fileno(), "w", 0)
    sys.stderr = os.fdopen(sys.stderr.fileno(), "w", 0)
    if len(sys.argv) != 4:
        print ">> ERROR: Not all required arguments supplied: %s" % sys.argv
        return False

    run = SetupLitpNodes(sys.argv[1], sys.argv[2], sys.argv[3])
    run.setup_litp_nodes()

if  __name__ == '__main__':main()
