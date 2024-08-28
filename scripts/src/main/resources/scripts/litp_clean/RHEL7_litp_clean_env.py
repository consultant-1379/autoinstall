#!/usr/bin/env python

'''
COPYRIGHT Ericsson 2021
The copyright to the computer program(s) herein is the property of
Ericsson Inc. The programs may be used and/or copied only with written
permission from Ericsson Inc. or in accordance with the terms and
conditions stipulated in the agreement/contract under which the
program(s) have been supplied.

@since:     October 2012
@author:    Brian Kelly
@summary:   Clean LITP before MS install - copy of original scripts for RHEL7
'''

import sys
import os
import re
from common_platform_files.common_methods import NodeConnect
from sfs_cleanup_shares import CleanupSFSShares
import common_platform_files.constants as constants
import time


class CleanLitp():
    """
    Class to deploy LITP using install scripts
    """
    def __init__(self, ai_params, restore_case=False):
        """
        Initialise variables
        """
        self.ai_params = ai_params
        if restore_case:
            self.sfs_filesystem = \
                self.ai_params["SFS_FILESYSTEM_CLEANUP_RESTORE"]
        else:
            self.sfs_filesystem = self.ai_params["SFS_FILESYSTEM_CLEANUP"]

        self.node = NodeConnect(self.ai_params["MS_POWEROFF_IP"], constants.LITP_USER, constants.LITP_USER_MS_PASSWD)
        self.sfs_clean_shares = CleanupSFSShares(self.sfs_filesystem, self.ai_params["SFS_SNAPSHOT_CLEANUP"])
        self.node_ip_list = self.ai_params["NODE_IPS"].split(",")
        self.pw_attempts = 3


    def clean_litp(self):
        """
        Deploy litp
        """

        if not self.node.is_node_pingable():
            print ">> WARNING: MS IP IS DOWN, CONTINUING WITHOUT CLEANUP"
            if self.sfs_filesystem == "no_sfs_cleanup" and self.ai_params["SFS_SNAPSHOT_CLEANUP"] == "no_sfs_snapshot_cleanup":
                print "NO SFS CLEANUP, SKIPPING"
            else:
                self.sfs_clean_shares.cleanup_sfs()
            return True

        try:
            self.node.handle_run_command("mkdir -p /tmp/.%s" %
                                         self.ai_params["JENKINS_JOB_ID"])
        except Exception as except_err:
            print ">> EXCEPTION: " + str(except_err)
            print ">> WARNING: CANNOT RUN COMMAND ON MS, " \
                  "CONTINUING WITHOUT CLEANUP"
            if self.sfs_filesystem == "no_sfs_cleanup" and self.ai_params["SFS_SNAPSHOT_CLEANUP"] == "no_sfs_snapshot_cleanup":
                print "NO SFS CLEANUP, SKIPPING"
            else:
                self.sfs_clean_shares.cleanup_sfs()
            return True

        print ""
        print "#########################################################"
        print ">> INFO: POWER OFF ALL CLUSTER NODES"
        print "#########################################################"
        print ""

        self.node = NodeConnect(self.ai_params["MS_POWEROFF_IP"], "root", constants.ROOT_MS_PASSWD)
        full_bmc_list = []
        split_bmc_ips = []
        split_bmc_expand_ips = []
        print full_bmc_list
        print self.ai_params["NODE_ILO_IPS"]
        print self.ai_params["EXPANSION_NODE_ILO_IPS"]
        if self.ai_params["NODE_ILO_IPS"] != "no_poweroff":
            split_bmc_ips = self.ai_params["NODE_ILO_IPS"].split(",")
            full_bmc_list.extend(split_bmc_ips)
        print full_bmc_list
        if self.ai_params["EXPANSION_NODE_ILO_IPS"] != "no_expansion":
            split_bmc_expand_ips = self.ai_params["EXPANSION_NODE_ILO_IPS"].split(",")
            full_bmc_list.extend(split_bmc_expand_ips)
        print full_bmc_list
        print "Calling RedFish rest API to powerdown nodes"

        if full_bmc_list != []:
            poweroff_node_cmd = "curl -H \"Content-Type: application/json\" -X POST " \
                                "--data \"{{\\\"ResetType\\\": \\\"ForceOff\\\"}}\" " \
                                "https://%s/redfish/v1/Systems/1/Actions/ComputerSystem.Reset/ " \
                                "-u {ilo_user}:{ilo_pass} --insecure".format(ilo_user=constants.ILO_USER,
                                                                            ilo_pass=re.escape(constants.ILO_PASSWD))

            for ipaddr in full_bmc_list:
                stdout, stderr, retc = self.node.run_command(poweroff_node_cmd % ipaddr, logs=True)

        if self.sfs_filesystem == "no_sfs_cleanup" and self.ai_params["SFS_SNAPSHOT_CLEANUP"] == "no_sfs_snapshot_cleanup":
            print "NO SFS CLEANUP, SKIPPING"
        else:
            self.sfs_clean_shares.cleanup_sfs()

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

    run = CleanLitp(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5],
                    sys.argv[6], sys.argv[7], sys.argv[8], sys.argv[9], sys.argv[10])
    run.clean_litp()

if  __name__ == '__main__': main()
