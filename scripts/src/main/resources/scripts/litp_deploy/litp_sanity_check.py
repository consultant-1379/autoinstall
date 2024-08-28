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
@summary:   Sanity check deployment
'''

import sys
import os
from common_platform_files.common_methods import NodeConnect
import common_platform_files.constants as constants
import time


class LitpSanityCheck():
    """
    Class  to run a sanity check
    """
    def __init__(self, ai_params):
        """
        Initialise variables
        """

        self.ai_params = ai_params
        self.node = NodeConnect(self.ai_params["MS_IP"], "root", constants.ROOT_MS_PASSWD)
        # If sanity ips are of type list then they have already been split.
        if not type(self.ai_params["SANITY_CHECK_IPS"]) == list:
            #if set to no sanity or if malformed, less than the length of a single ip
            if self.ai_params["SANITY_CHECK_IPS"] == "no_sanity" or \
               len(self.ai_params["SANITY_CHECK_IPS"]) < 5:
                self.ai_params["SANITY_CHECK_IPS"] = []
            else:
                self.ai_params["SANITY_CHECK_IPS"] = \
                    self.ai_params["SANITY_CHECK_IPS"].split(",")
        self.root_script_path = "/tmp/run_root_cmd_v2.exp"
        self.ai_params["NODE_HOSTNAMES"] = self.ai_params["NODE_HOSTNAMES"].split(",")
    def sanity_check(self):
        """
        Run a sanity check after an install is complete
        """

        print ""
        print "#########################################################"
        print ">> INFO: LITP SANITY CHECK"
        print "#########################################################"
        print ""

        if self.ai_params["MS_BLADE_TYPE"] == "cloud":
            print "UUID PRINTOUTS:"
            iplist = []
            for node_name in self.ai_params["NODE_HOSTNAMES"]:
                if not node_name:
                    continue
                cmd = "/bin/cat /etc/hosts | grep '%s'" % node_name
                stdout, stderr, retc = self.node.run_command(cmd, logs=True)
                if retc != 0 or stderr != [] or stdout == []:
                    print ">> ERROR: Cannot cat /etc/hosts"
                    return False
                for line in stdout:
                    if node_name in line:
                        print "IP added: {0}".format(node_name)
                        iplist.append(stdout[0].split()[0])
                
            for ipaddr in iplist:
                self.node = NodeConnect(ipaddr, "litp-admin", constants.LITP_USER_PEERNODE_PASSWD)
                cmd = "ls /dev/disk/by-id/ | grep scsi"
                self.node.run_command(cmd, logs=True)

        failed_count = 0

        print ""
        print "---------------------------"
        print "MS NODE SERVICE CHECKS"
        print "---------------------------"
        print ""
        self.node = NodeConnect(self.ai_params["MS_IP"], constants.LITP_USER, constants.LITP_USER_MS_PASSWD)
        if not self.node.check_service("litpd"):
            failed_count += 1
        self.node = NodeConnect(self.ai_params["MS_IP"], "root", constants.ROOT_MS_PASSWD)
        if not self.node.check_service("puppet"):
            failed_count += 1
        if not self.node.check_service("mcollective"):
            failed_count += 1
        if not self.node.check_service("cobblerd"):
            failed_count += 1
        if not self.node.check_service("iptables"):
            failed_count += 1
        if not self.node.check_service("httpd"):
            failed_count += 1
        if not self.node.check_service("rsyslog"):
            failed_count += 1
        if not self.node.check_service("ntpd"):
            failed_count += 1

        cmd = 'grep "Could not request certificate: The certificate retrieved from the master does not match the" /var/log/messages'
        stdout, stderr, retc = self.node.run_command(cmd)
        if retc == 0:
            print ">> ERROR: PUPPET CERT ISSUE"
            failed_count += 1

        print ""
        print "---------------------------"
        print "PEER NODE SERVICE CHECKS"
        print "---------------------------"
        print ""
	
        print "--------------------"
        print self.ai_params["SANITY_CHECK_IPS"]
        print "--------------------"

        print "SANITY IPS ARE: ", self.ai_params["SANITY_CHECK_IPS"]
        if self.ai_params["SANITY_CHECK_IPS"] == []:
            print "Skipping services sanity check, sanity ips not found"

        else:
                service_list = ["mcollective", "puppet", "iptables", "rsyslog"]
                services_not_running_list = list()
                missing_services = False
                node_index = 0

                print "SANITY IPS ARE BEFORE LOOP: ", self.ai_params["SANITY_CHECK_IPS"]
                for ipaddr in self.ai_params["SANITY_CHECK_IPS"]:
                    print "SANITY IPS ARE IN LOOP: ", self.ai_params["SANITY_CHECK_IPS"]
                    ipaddr = ipaddr.replace('"', '')
                    print "---Checking node {0}---".format(ipaddr)
                    print "-----------------------"
                    services_not_running_list = list()

                ##Throw a warning if we are going to hit a key error
                #when attempting to supply hostname to NodeConnect
                    if len(self.ai_params["NODE_HOSTNAMES"]) < node_index - 1:
                        print ">> WARNING: Cannot match hostname/ip address unable to " +\
                            "check services for node {0}".format(ipaddr)
                        continue
                    print self.ai_params["NODE_HOSTNAMES"][node_index]
                    node_item = NodeConnect(ipaddr, constants.LITP_USER,
                                            constants.LITP_USER_PEERNODE_PASSWD,
                                            hostname=self.ai_params["NODE_HOSTNAMES"][node_index],
                                            rootpw=constants.ROOT_PEERNODE_PASSWD)

                    for service in service_list:
                        status_cmd = "/bin/systemctl status {0}.service".format(service)
                        _, _, rc = node_item.run_su_root_cmd(status_cmd)

                        if rc != 0:
                            services_not_running_list.append(service)

                    cmd = 'grep "Could not request certificate: The certificate retrieved from the master does not match the" /var/log/messages'
                    stdout, stderr, retc = node_item.run_su_root_cmd(cmd)
                    if retc == 0:
                        print ">> ERROR: PUPPET CERT ISSUE ON: ", ipaddr
                        failed_count += 1

                    if services_not_running_list != []:
                        print ">> ERROR: Expected services not running on node {0}: {1}"\
                            .format(ipaddr, " ".join(services_not_running_list))
                        missing_services = True


                    node_index = node_index + 1

                if missing_services:
                    print ">> ERROR: Expected services not running on one or " +\
                        "more peer nodes"
                    return False

        print ""
        print "---------------------------"
        print "MS TO PEER NODE SSH PASSWORD CHECKS"
        print "---------------------------"
        print ""

        print "...SKIPPED UNTIL NEW PASSWORD SETTINGS ARE COMPLETE..."

        if failed_count > 0:
            print "\nThere are failed services on the MS!!\n"
            return False

        print ""
        print "#########################################################"
        print ">> INFO: LITP VERSION"
        print "#########################################################"
        print ""

        # PRINT LITP VERSION
        print "\nLITP VERSION:\n"
        cmd = "/usr/bin/litp version -a"
        if not self.node.handle_run_command(cmd, expected_stdout=""):
            print ">> ERROR: PRINTING LITP VERSION"
            return False

        return True

def main():
    """
    main function
    """

    # Disable output buffering to receive the output instantly
    sys.stdout = os.fdopen(sys.stdout.fileno(), "w", 0)
    sys.stderr = os.fdopen(sys.stderr.fileno(), "w", 0)
    if len(sys.argv) != 5:
        print ">> ERROR: Not all required arguments supplied: %s" % sys.argv
        return False

    run = LitpSanityCheck(sys.argv[1], sys.argv[2], "G8", sys.argv[4])
    run.sanity_check()

if  __name__ == '__main__':main()
