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
import common_platform_files.constants as constants
import time
from litp_peer_node_reboot_restore import PeerNodeRebootRestore
from litp_deploy.litp_setup_nodes import SetupLitpNodes


class backupRestoreLitp():
    """
    Class to deploy litp using install scripts
    """
    def __init__(self, ai_params):
        """
        Initialise variables
        """

        #self.node = common_methods.NodeConnect(ms_ip, contstants.LITPUSER, constants.AITMPPASSWORD)
        self.ai_params = ai_params
        self.node = NodeConnect(self.ai_params["MS_IP"], constants.LITP_USER, constants.LITP_USER_MS_PASSWD)

    def create_named_snapshot(self):
        """
        Creates a named snapshot
        """
        cmd = "/usr/bin/litp create_snapshot -n named1"
        if not self.node.handle_run_command(cmd):
            print ">> ERROR: CREATE SNAPSHOT COMMAND FAILED ON HOST"
            return False

        if not self.node.waitfor_litp_plan(240, 2):
            return False

        return True

    def backup_restore_litp(self):
        """
        Deploy litp
        """

        print ""
        print "#########################################################"
        print ">> INFO: BACKUP AND RESTORE LITP"
        print "#########################################################"
        print ""
        print ""

        cmd = "/usr/bin/litp prepare_restore"
        if not self.node.handle_run_command(cmd):
            print ">> ERROR: PLAN COMMAND FAILED ON HOST"
            return False

        # TEMP CHANGE TO REPRODUCE A BUG
        cmd = "litp update -p /litp/logging -o force_debug=true"
        if not self.node.handle_run_command(cmd):
            print ">> WARNING: TURN ON LITP DEBUG FAILED ON HOST"

        #By this cmd working proves that snapshots were wiped
        cmd = "/usr/bin/litp create_snapshot"
        if not self.node.handle_run_command(cmd):
            print ">> ERROR: CREATE SNAPSHOT COMMAND FAILED ON HOST"
            return False

        if not self.node.waitfor_litp_plan(300, 2):
            return False

        if not self.create_named_snapshot():
            return False

        cmd = "/usr/bin/litp update -p /deployments/d1/clusters/c1 -o cs_initial_online=off"
        if not self.node.handle_run_command(cmd):
            print ">> ERROR: PLAN COMMAND FAILED ON HOST"
            return False

        cmd = "/usr/bin/litp create_plan"
        if not self.node.handle_run_command(cmd):
            print ">> ERROR: PLAN COMMAND FAILED ON HOST"
            return False

        if self.ai_params["EXPECT_LARGE_PLAN"]:
            cmd = "/usr/bin/litp show_plan &>> /tmp/.{0}/initial_litp_show_plan_{1}.txt".format(self.ai_params["JENKINS_JOB_ID"], time.strftime("%H%M%S"))
            if not self.node.run_command(cmd):
                print ">> ERROR: PLAN COMMAND FAILED ON HOST"
                return False
        else:
            cmd = "/usr/bin/litp show_plan"
            if not self.node.handle_run_command(cmd, expected_stdout=""):
                print ">> ERROR: PLAN COMMAND FAILED ON HOST"
                return False

        # RUN THE PLAN

        cmd = "/usr/bin/litp run_plan"
        if not self.node.handle_run_command(cmd):
            print ">> ERROR: RUN PLAN FAILED ON HOST"
            return False

        #if not self.node.waitfor_litp_plan(120, 60, initial_sleep=480):
            #return False

        if not self.node.waitfor_litp_plan(120, 60, initial_sleep=480,
                                           print_error=False,
                                           show_plan_file=self.ai_params["EXPECT_LARGE_PLAN"],
                                           file_dir=self.ai_params["JENKINS_JOB_ID"]):
            return False

        # REMOVE THE PLAN

        cmd = "/usr/bin/litp remove_plan"
        if not self.node.handle_run_command(cmd):
            print ">> ERROR: PLAN COMMAND FAILED ON HOST"
            return False

        # REMOVE AND CREATE NEW SNAPSHOTS FOR PEER NODES

        cmd = "/usr/bin/litp remove_snapshot"
        if not self.node.handle_run_command(cmd):
            print ">> ERROR: REMOVE SNAPSHOT COMMAND FAILED ON HOST"
            return False

        if not self.node.waitfor_litp_plan(50, 2):
            return False

        cmd = "/usr/bin/litp remove_snapshot -n named1"
        if not self.node.handle_run_command(cmd):
            print ">> ERROR: REMOVE SNAPSHOT COMMAND FAILED ON HOST"
            return False

        if not self.node.waitfor_litp_plan(50, 2):
            return False

        cmd = "/usr/bin/litp create_snapshot"
        if not self.node.handle_run_command(cmd):
            print ">> ERROR: CREATE SNAPSHOT COMMAND FAILED ON HOST"
            return False

        if not self.node.waitfor_litp_plan(50, 2):
            return False

        cmd = "/usr/bin/litp remove_plan"
        if not self.node.handle_run_command(cmd):
            print ">> ERROR: CREATE SNAPSHOT COMMAND FAILED ON HOST"
            return False

        self.node = NodeConnect(self.ai_params["MS_IP"], "root", constants.ROOT_MS_PASSWD)

        cmd = "/bin/rm -rf /home/litp-admin/.ssh/known_hosts"
        if not self.node.handle_run_command(cmd):
            print ">> ERROR: CREATE SNAPSHOT COMMAND FAILED ON HOST"
            return False

        cmd = "/bin/rm -rf /root/.ssh/known_hosts"
        if not self.node.handle_run_command(cmd):
            print ">> ERROR: CREATE SNAPSHOT COMMAND FAILED ON HOST"
            return False

        return True


def main():
    """
    main function
    """

    # Disable output buffering to receive the output instantly
    sys.stdout = os.fdopen(sys.stdout.fileno(), "w", 0)
    sys.stderr = os.fdopen(sys.stderr.fileno(), "w", 0)
    if len(sys.argv) != 11:
        print ">> ERROR: Not all required arguments supplied: %s" % sys.argv
        return False

    run = DeployLitp(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5],
                    sys.argv[6], sys.argv[7], sys.argv[8], sys.argv[9], sys.argv[10])
    run.deploy_litp()

if  __name__ == '__main__': main()
