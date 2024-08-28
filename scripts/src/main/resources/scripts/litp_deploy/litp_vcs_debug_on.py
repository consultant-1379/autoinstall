#!/usr/bin/env python

"""
COPYRIGHT Ericsson 2019
The copyright to the computer program(s) herein is the property of
Ericsson Inc. The programs may be used and/or copied only with written
permission from Ericsson Inc. or in accordance with the terms and
conditions stipulated in the agreement/contract under which the
program(s) have been supplied.

@since:     September 2016
@author:    Aileen Henry
@summary:   Initiate vcs debug level logging after install.
"""

import time
from common_platform_files.common_methods import NodeConnect
import common_platform_files.constants as constants


class InitiateVCSDebug():
    """
    Class to run commands on the Managed Nodes of a system to add VCS debugging
    after successful install.
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

    def initiate_debug_logging(self):
        """
        Initiate vcs debug logging after successfull LITP install.
        """
        print ""
        print "#########################################################"
        print ">> INFO: Initiating Debug level logging for VCS"
        print "#########################################################"
        print ""

        print "Node ips: ", self.ai_params["SANITY_CHECK_IPS"]
        if not self.ai_params["SANITY_CHECK_IPS"]:
            print "No sanity ips found, skipping initiation of vcs debugging."
            return True

        print "Node ips: ", self.ai_params["SANITY_CHECK_IPS"]

        # List of commands to run to initiate vcs debug level logging
        cmd_list = ['haconf -makerw',
                    'halog -addtags DBG_POLICY',
                    'halog -addtags DBG_TRACE',
                    'halog -addtags DBG_AGTRACE',
                    'halog -addtags DBG_AGINFO',
                    'halog -addtags DBG_AGDEBUG',
                    'haconf -dump -makero']

        #Specific agent commands only need to be executed on one node
        agent_cmds = ['haconf -makerw',
                      'hatype -modify DiskGroup LogDbg -add DBG_1 DBG_2 DBG_3 '
                      'DBG_4 DBG_5 DBG_AGDEBUG DBG_AGINFO DBG_AGTRACE',
                      'hatype -modify Mount LogDbg -add DBG_1 DBG_2 DBG_3 '
                      'DBG_4 DBG_5 DBG_AGDEBUG DBG_AGINFO DBG_AGTRACE',
                      'haconf -dump -makero']

        agent_cmds_executed = False

        # Run the list of commands on each peer node
        for ip_addr in self.ai_params["SANITY_CHECK_IPS"]:

            node = NodeConnect(ip_addr,
                               constants.LITP_USER,
                               constants.LITP_USER_PEERNODE_PASSWD,
                               rootpw=constants.ROOT_PEERNODE_PASSWD)

            for cmd in cmd_list:
                stdout, stderr, retc = node.run_su_root_cmd(cmd)
                if retc != 0:
                    print ">> ERROR: UNSUCCESSFUL COMMAND", cmd
                    return False

            # Run the agent_cmds if they haven't been executed on a node already
            if not agent_cmds_executed:
                for agent_cmd in agent_cmds:
                    stdout, stderr, retc = node.run_su_root_cmd(agent_cmd)
                    if retc != 0:
                        print ">> ERROR: UNSUCCESSFUL COMMAND", agent_cmd
                        return False
                agent_cmds_executed = True

        print "Commands to switch on vcs debug level logging have completed."
        return True

