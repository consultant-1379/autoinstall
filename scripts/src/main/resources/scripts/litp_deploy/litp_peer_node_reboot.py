#!/usr/bin/env python

"""
COPYRIGHT Ericsson 2019
The copyright to the computer program(s) herein is the property of
Ericsson Inc. The programs may be used and/or copied only with written
permission from Ericsson Inc. or in accordance with the terms and
conditions stipulated in the agreement/contract under which the
program(s) have been supplied.

@since:     January 2016
@author:    Bryan O'Neill
@summary:   Reboot the Managed Nodes of a system after install.
"""

import time
from common_platform_files.common_methods import NodeConnect
import common_platform_files.constants as constants


class PeerNodeReboot():
    """
    Class to reboot the Managed Nodes of a system after install.
    """
    def __init__(self, ai_params):
        """
        Initialise variables
        """
        self.ai_params = ai_params
        # If sanity ips are of type list then they have already been split.
        if not type(self.ai_params["SANITY_CHECK_IPS"]) == list:
            if self.ai_params["SANITY_CHECK_IPS"] == "no_sanity" or \
               len(self.ai_params["SANITY_CHECK_IPS"]) < 5:
                self.ai_params["SANITY_CHECK_IPS"] = []
            else:
                self.ai_params["SANITY_CHECK_IPS"] = \
                    self.ai_params["SANITY_CHECK_IPS"].split(",")

    def reboot_peer_nodes(self):
        """
        Reboot peer nodes after successfull LITP install.
        """
        print ""
        print "#########################################################"
        print ">> INFO: Reboot Managed Nodes"
        print "#########################################################"
        print ""

        print "Node ips: ", self.ai_params["SANITY_CHECK_IPS"]
        if not self.ai_params["SANITY_CHECK_IPS"]:
            print "No sanity ips found, skipping peer node reboot."
            return True

        print "Node ips: ", self.ai_params["SANITY_CHECK_IPS"]

        # Run reboot on each peer node
        for ip_addr in self.ai_params["SANITY_CHECK_IPS"]:

            node = NodeConnect(ip_addr,
                               constants.LITP_USER,
                               constants.LITP_USER_PEERNODE_PASSWD,
                               rootpw=constants.ROOT_PEERNODE_PASSWD)
            cmd = "/sbin/shutdown -r +1"
            stdout, stderr, retc = node.run_su_root_cmd(cmd)
            if retc != 0:
                print ">> ERROR: REBOOT OF NODE WAS UNSUCCESSFUL"
                return False

            retry = 0
            while node.is_node_pingable():
                if retry > 599:
                    print ">> ERROR: NODE HAS NOT SHUTDOWN IN 10 MINUTES"
                    return False
                time.sleep(1)
                retry += 1

        # Sleep to allow reboot.
        print "Sleeping for 10 minutes to allow reboots to occur..."
        time.sleep(600)

        # Check if nodes are back up. If not sleep and retry once.
        retry = 0
        nodes_up = bool
        while retry < 3:
            nodes_up = True
            for ip_addr in self.ai_params["SANITY_CHECK_IPS"]:
                node = NodeConnect(ip_addr,
                                   constants.LITP_USER,
                                   constants.LITP_USER_PEERNODE_PASSWD,
                                   rootpw=constants.ROOT_PEERNODE_PASSWD)
                if not node.is_node_pingable():
                    print "Nodes have not finished rebooting. Sleeping " \
                          "for 1 minute to allow reboots to occur..."
                    time.sleep(60)
                    retry += 1
                    nodes_up = False
                    break
            if nodes_up:
                break

        if not nodes_up:
            print "All managed nodes have not rebooted within the given time."
            return False
        print "All managed nodes have rebooted."
        return True
