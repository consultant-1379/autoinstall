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
import re
from common_platform_files.common_methods import NodeConnect
import common_platform_files.constants as constants
import time


class ExpandLitp(object):
    """
    Class to deploy litp using install scripts
    """
    def __init__(self, ai_params):
        """
        Initialise variables
        """

        self.ai_params = ai_params
        self.node = NodeConnect(self.ai_params["MS_IP"], constants.LITP_USER, constants.LITP_USER_MS_PASSWD)
        self.expanded_nodes = []

    def get_expanded_nodes(self):
        """
        Returns the list of expanded nodes
        """
        return self.expanded_nodes

    def get_nodes_from_model(self):
        """
        Looks in the tree to get existing nodes.
        """
        cmd = "litp show -rp /deployments | grep -B1 'type: node' | grep ^'/'"

        nodes, stderr, returnc = self.node.run_command(cmd)

        node_list = list()
        node_dict = dict()

        for node in nodes:
            node_dict = dict()

            node_show = "litp show -rp {0}".format(node)

            ##Get ilo addr
            ip_show = "{0} | grep 'reference-to-bmc' -A5 | grep 'ipaddress' | sed 's/ //g' | cut -d ':'  -f 2 | sed 's/*//g' | sed 's/\[\]//g'".format(node_show)
            ilo_ip, stderr, returnc = self.node.run_command(ip_show)
            print ">>> DEBUG: ", ilo_ip
            print ">>> DEBUG: ", ilo_ip[0]
            node_dict['ilo'] = ilo_ip[0]

            ##Get node hostname
            hostname_show = "litp show -p {0} | grep 'hostname' | sed 's/ //g' | cut -d ':'  -f 2 | sed 's/*//g' | sed 's/\[\]//g'".format(node)
            hostname, stderr, returnc = self.node.run_command(hostname_show)
            print ">>> DEBUG: ", hostname
            print ">>> DEBUG: ", hostname[0]
            node_dict['hostname'] = hostname[0]

            ##Get node ip
            ip_show = "{0} | grep 'network_name: mgmt' -B9 -A9 | grep 'ipaddress' | sed 's/ //g' | cut -d ':'  -f 2 | sed 's/*//g' | sed 's/\[\]//g'".format(node_show)
            ip_addr, stderr, returnc = self.node.run_command(ip_show)
            print ">>> DEBUG: ", ip_addr
            print ">>> DEBUG: ", ip_addr[0]
            node_dict['ip'] = ip_addr[0]

            print ">>> DEBUG: node_dict: ", node_dict

            node_list.append(node_dict)

        print ">>> DEBUG: ", node_list
        return node_list

    @staticmethod
    def __find_expanded_nodes(before_expand, after_expand):
        """
        Compares two nodes lists and returns the extra nodes.
        """
        expanded_nodes = list()

        for node_a in after_expand:
            found = False
            for node_b in before_expand:
                if node_a['ilo'] == node_b['ilo']:
                    found = True

            already_found = False
            for node in expanded_nodes:
                if node['ilo'] == node_a['ilo']:
                    already_found = True
                    break

            if not found and not already_found:
                node_dict = dict()
                node_dict["ilo"] = node_a['ilo']
                node_dict["hostname"] = node_a['hostname']
                node_dict["ip"] = node_a['ip']
                expanded_nodes.append(node_dict)

        return expanded_nodes

    def wait_for_restore(self):
        """
        As documented on create_snapshot page will wait until snapshots are
        fully merged after a restore before running create snapshot.
        """
        cmd = "/sbin/lvs | /bin/awk '{print $3}' | /bin/grep 'owi'"

        max_count = 120
        count = 0
        while True:
            stdout, stderr, retc = \
                self.node.run_command(cmd, logs=True)

            if retc == 1 and stderr == []:
                return True

            count += 1

            if count == max_count:
                return False

            time.sleep(10)

    def expand_litp(self):
        """
        Expand the litp cluster.
        """
        cmd = "mkdir -p /tmp/.%s" % self.ai_params["JENKINS_JOB_ID"]
        # CREATE AN AUTOINSTALL DIRECTORY ON THE NODE
        if not self.node.handle_run_command(cmd):
            print ">> ERROR: MKDIR FAILED ON HOST"
            return False

        print ""
        print "#########################################################"
        print ">> INFO: EXPAND LITP"
        print "#########################################################"
        print ""
        print "EXPAND SCRIPT: %s" % self.ai_params["EXPAND_FILE"]
        print "CLUSTER SCRIPT: %s" % self.ai_params["CLUSTER_FILE_NAME"]
        print ""

        nodes_before = self.get_nodes_from_model()

        ##REMOVE SNAPSHOT
        cmd = "/usr/bin/litp remove_snapshot"
        if not self.node.handle_run_command(cmd):
            print ">> ERROR: REMOVE SNAPSHOT COMMAND FAILED ON HOST"
            return False

        if not self.node.waitfor_litp_plan(60, 2):
            return False

        # CREATE A SNAPSHOT
        cmd = "/usr/bin/litp create_snapshot"
        if not self.node.handle_run_command(cmd):
            print ">> ERROR: CREATE SNAPSHOT COMMAND FAILED ON HOST"
            return False

        if not self.node.waitfor_litp_plan(120, 2):
            return False

        # RUN THE DEPLOYMENT SCRIPT

        # COPY DEPLOYMENT SCRIPT AND CLUSTER FILE TO AI DIRECTORY
        local_path = "%s/%s" % (self.ai_params["AUTOINSTALL_DIR"], self.ai_params["EXPAND_FILE"])

        remote_path = "/tmp/.%s/%s" % (self.ai_params["JENKINS_JOB_ID"], "expand_script.sh")

        print "Copy of %s to %s on %s" % (local_path, remote_path, self.ai_params["MS_IP"])
        self.node.copy_file(local_path, remote_path)
        local_path = "%s/%s" % (self.ai_params["AUTOINSTALL_DIR"], self.ai_params["CLUSTER_FILE_NAME"])
        remote_path = "/tmp/.%s/%s" % (self.ai_params["JENKINS_JOB_ID"], self.ai_params["CLUSTER_FILE_NAME"])
        print "Copy of %s to %s on %s" % (local_path, remote_path, self.ai_params["MS_IP"])
        self.node.copy_file(local_path, remote_path)

        self.node = NodeConnect(self.ai_params["MS_IP"], constants.LITP_USER,
                                constants.LITP_USER_MS_PASSWD)

        # LOAD CLI AS NORMAL
        cmd = "sh /tmp/.%s/expand_script.sh /tmp/.%s/%s" %\
            (self.ai_params["JENKINS_JOB_ID"], self.ai_params["JENKINS_JOB_ID"], self.ai_params["CLUSTER_FILE_NAME"])
        stdout, stderr, retc = self.node.run_command(cmd)

        if retc != 0:
            print ">> ERROR: RUNNING OF DEPLOYMENT SCRIPT FAILED ON HOST"
            return False

        # CREATE THE PLAN
        cmd = "/usr/bin/litp create_plan"
        if not self.node.handle_run_command(cmd):
            print ">> ERROR: PLAN COMMAND FAILED ON HOST"
            return False

        cmd = "/usr/bin/litp show_plan"
        if not self.node.handle_run_command(cmd, expected_stdout=""):
            print ">> ERROR: PLAN COMMAND FAILED ON HOST"
            return False

        monitor_script_path = None
        if self.ai_params["MONITOR_SCRIPT"]:
            local_path = "%s/%s" % (self.ai_params["AUTOINSTALL_DIR"],
                                    self.ai_params["MONITOR_FILE_NAME"])
            remote_path = "/tmp/.%s/%s" % (self.ai_params["JENKINS_JOB_ID"],
                                           self.ai_params["MONITOR_FILE_NAME"])
            monitor_script_path = remote_path
            print "Copy of %s to %s on %s" % (local_path,
                                              remote_path,
                                              self.ai_params["MS_IP"])
            self.node.copy_file(local_path, remote_path)

        # RUN THE PLAN
        cmd = "/usr/bin/litp run_plan"
        if not self.node.handle_run_command(cmd):
            print ">> ERROR: RUN PLAN FAILED ON HOST"
            return False

        if not self.node.waitfor_litp_plan(120, 60, initial_sleep=480,
                                           print_error=False,
                                           monitor_script_path=monitor_script_path):
            print ">> ERROR: EXPANSION PLAN FAILED"
            return False

        # REMOVE THE PLAN

        cmd = "/usr/bin/litp remove_plan"
        if not self.node.handle_run_command(cmd):
            print ">> ERROR: PLAN COMMAND FAILED ON HOST"
            return False

        nodes_after = self.get_nodes_from_model()

        self.expanded_nodes = self.__find_expanded_nodes(nodes_before,
                                                         nodes_after)
        if self.ai_params["RESTORE_EXPAND"]:

            print ""
            print "#########################################################"
            print ">> INFO: RESTORE EXPANDED CLUSTER"
            print "#########################################################"
            print ""

            self.node = NodeConnect(self.ai_params["MS_IP"], "root", constants.ROOT_MS_PASSWD)
            print "Calling RedFish rest API to powerdown nodes"

            poweroff_node_cmd = "curl -H \"Content-Type: application/json\" -X POST " \
                                "--data \"{{\\\"ResetType\\\": \\\"ForceOff\\\"}}\" " \
                                "https://%s/redfish/v1/Systems/1/Actions/ComputerSystem.Reset/ " \
                                "-u {ilo_user}:{ilo_pass} --insecure".format(ilo_user=constants.ILO_USER,
                                                                            ilo_pass=re.escape(constants.ILO_PASSWD))

            for ipaddr in self.expanded_nodes:
                stdout, stderr, retc = self.node.run_command(poweroff_node_cmd % ipaddr['ilo'], logs=True)

            self.node = NodeConnect(self.ai_params["MS_IP"], constants.LITP_USER, constants.LITP_USER_MS_PASSWD)

            cmd = "/usr/bin/litp restore_snapshot"
            if not self.node.handle_run_command(cmd):
                print "Failed as expected, now trying -f option"

            cmd = "/usr/bin/litp show_plan"
            if not self.node.handle_run_command(cmd, expected_stdout=""):
                print ">> ERROR: PLAN COMMAND FAILED ON HOST"
                return False

            ##Wait for node down
            increment_secs = 10
            count = 0
            while True:
                pingable = self.node.is_node_pingable()

                if not pingable:
                    break

                time.sleep(10)
                count += increment_secs
                print "Waited {0} seconds for node down".format(count)

                if count > 1200:
                    print "Node has not gone down after 20 minutes"
                    break

            print "Waiting for node to come up"
            ##Wait for node up
            increment_secs = 10
            count = 0
            while True:
                time.sleep(10)
                pingable = self.node.is_node_pingable()

                if pingable:
                    break

                count += increment_secs
                print "Waited {0} seconds for node up".format(count)

                if count > 1200:
                    print "Node has not come up after 20 minutes"
                    break

            print "Node is now up"

            print "Sleeping for 10 minutes to allow startup to complete"
            time.sleep(600)

            self.node = NodeConnect(self.ai_params["MS_IP"], "root", constants.ROOT_MS_PASSWD)
            if not self.wait_for_restore():
                print ">> WARNING: Restore snapshot did not complete"

            self.node = NodeConnect(self.ai_params["MS_IP"], constants.LITP_USER, constants.LITP_USER_MS_PASSWD)
            # SET LITP LOGGING TO DEBUG
            cmd = "litp update -p /litp/logging -o force_debug=true"
            if not self.node.handle_run_command(cmd):
                print ">> WARNING: TURN ON LITP DEBUG FAILED ON HOST"

            cmd = "/usr/bin/litp show_plan"
            if not self.node.handle_run_command(cmd, expected_stdout=""):
                print ">> ERROR: PLAN COMMAND FAILED ON HOST"
                return False

            cmd = "/usr/bin/litp remove_plan"
            if not self.node.handle_run_command(cmd):
                print ">> ERROR: CREATE SNAPSHOT COMMAND FAILED ON HOST"
                return False

            cmd = "/usr/bin/litp remove_snapshot"
            if not self.node.handle_run_command(cmd):
                print ">> ERROR: REMOVE SNAPSHOT COMMAND FAILED ON HOST"
                return False

        # REMOVE AND CREATE NEW SNAPSHOTS FOR PEER NODES

        else:
            cmd = "/usr/bin/litp remove_snapshot"
            if not self.node.handle_run_command(cmd):
                print ">> ERROR: REMOVE SNAPSHOT COMMAND FAILED ON HOST"
                return False

        if not self.node.waitfor_litp_plan(60, 2):
            return False

        cmd = "/usr/bin/litp create_snapshot"
        if not self.node.handle_run_command(cmd):
            print ">> ERROR: CREATE SNAPSHOT COMMAND FAILED ON HOST"
            return False

        if not self.node.waitfor_litp_plan(120, 2):
            print ">> ERROR: SNAPSHOT COMMAND FAILED ON HOST"
            return False

        cmd = "/usr/bin/litp remove_plan"
        if not self.node.handle_run_command(cmd):
            print ">> ERROR: PLAN COMMAND FAILED ON HOST"
            return False

        cmd = "/bin/mv /tmp/.%s /home/litp-admin/" % self.ai_params["JENKINS_JOB_ID"]
        if not self.node.handle_run_command(cmd):
            print ">> ERROR: MOVING AI DIRECTORY FAILED"
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

    run = ExpandLitp(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4],
                     sys.argv[5], sys.argv[6], sys.argv[7], sys.argv[8],
                     sys.argv[9], sys.argv[10])
    run.expand_litp()

if  __name__ == '__main__': main()
