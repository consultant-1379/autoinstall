#!/usr/bin/env python

'''
COPYRIGHT Ericsson 2019
The copyright to the computer program(s) herein is the property of
Ericsson Inc. The programs may be used and/or copied only with written
permission from Ericsson Inc. or in accordance with the terms and
conditions stipulated in the agreement/contract under which the
program(s) have been supplied.

@since:     October 2012
@author:    Bryan O'Neill
@summary:
'''

import sys
import os
from common_platform_files.common_methods import NodeConnect
import common_platform_files.constants as constants

class InstallOSPatch():
    """
    Class to install packages from the OS Patches on a vApp Ms and Peer nodes.
    """

    def __init__(self, ai_params):
        """
        Initialise variables
        """

        self.ai_params = ai_params

        self.node = NodeConnect(self.ai_params["MS_IP"], "root",
                                constants.ROOT_MS_PASSWD)

        # If sanity ips are of type list then they have already been split.
        if not type(self.ai_params["SANITY_CHECK_IPS"]) == list:
            # if set to no sanity or if malformed, less than the length of a
            # single ip
            if self.ai_params["SANITY_CHECK_IPS"] == "no_sanity" or \
                            len(self.ai_params["SANITY_CHECK_IPS"]) < 5:
                self.ai_params["SANITY_CHECK_IPS"] = []
            else:
                self.ai_params["SANITY_CHECK_IPS"] = \
                    self.ai_params["SANITY_CHECK_IPS"].split(",")

        if not type(self.ai_params["NODE_HOSTNAMES"]) == list:
            self.ai_params["NODE_HOSTNAMES"] = self.ai_params["NODE_HOSTNAMES"].split(",")

    def install_os_patch_packages(self):
        """
        Install required packages from the OS Patches.
        It is assumed these packages are in the autoinstall repo.
        """

        print ""
        print "#########################################################"
        print ">> INFO: INSTALLING PACKAGES FROM OS PATCHES"
        print "#########################################################"
        print ""

        # Get a list of all rpms in the packages dir
        workspace = os.environ["WORKSPACE"]
        find_cmd = "find {0} -name \"os_patch_packages\"".format(workspace)
        std_out, std_err, retc = self.node.run_command_local(find_cmd)
        if retc != 0 or len(std_out) != 1:
            print ">> ERROR: COULD NOT FIND PATHCES DIRECTORY"
            print std_out
            print std_err
            return False
        pkg_dir =  std_out[0] + "/"
        cmd = "ls -1 " + pkg_dir + " | grep -E \".rpm$\""
        rpm_list, std_err, retc = self.node.run_command_local(cmd)
        if retc != 0 or not rpm_list:
            print ">> ERROR: NO RPMS FOUND TO INSTALL"
            return False


        # Create a dir on the MS for the rpms
        cmd = "mkdir -p /tmp/ai_os_patch_packages"
        std_out, std_err, retc = self.node.run_command(cmd)
        if retc != 0:
            print ">> ERROR: COULD NOT CREATE DIR ON MS"
            print std_out
            print std_err
            return False

        # Copy each rpm and install on MS
        for rpm in rpm_list:
            # Copy rpm to MS
            local_rpm_path = pkg_dir + rpm
            remote_rpm_path = "/tmp/ai_os_patch_packages/" + rpm
            self.node.copy_file(local_rpm_path, remote_rpm_path)

            # Install rpm
            std_out, std_err, retc = \
                self.node.run_command("yum install -y " + remote_rpm_path)
            if retc == 1 and any("does not update installed package" in line
                                 for line in std_out):
                print ">> INFO: Package already installed on MS: " + rpm
            elif retc != 0:
                print ">> ERROR: COULD NOT INSTALL RPM ON MS"
                print std_out
                print std_err
                return False

        # For each node:
        if not self.ai_params["SANITY_CHECK_IPS"]:
            print "No Sanity IPs set for peer nodes, skipping OS Patch " \
                  "package install"
            return True

        node_index = 0
        for ipaddr in self.ai_params["SANITY_CHECK_IPS"]:
            ipaddr = ipaddr.replace('"', '')

            if len(self.ai_params["NODE_HOSTNAMES"]) < node_index - 1:
                print ">> WARNING: Cannot match hostname/ip address unable to"\
                      " install rpm for node {0}".format(ipaddr)
                continue

            node_hostname = self.ai_params["NODE_HOSTNAMES"][node_index]
            node_item = NodeConnect(ipaddr, constants.LITP_USER,
                                    constants.LITP_USER_PEERNODE_PASSWD,
                                    hostname=node_hostname,
                                    rootpw=constants.ROOT_PEERNODE_PASSWD)

            # Create the dir on the node
            std_out, std_err, retc = node_item.run_command(cmd)
            if retc != 0:
                print ">> ERROR: COULD NOT CREATE DIR ON Node: " + \
                      node_hostname
                print std_out
                print std_err
                return False

            # Copy each rpm and install on MS
            for rpm in rpm_list:
                # Copy rpm to MS
                local_rpm_path = pkg_dir + rpm
                remote_rpm_path = "/tmp/ai_os_patch_packages/" + rpm
                node_item.copy_file(local_rpm_path, remote_rpm_path)

                # Install rpm
                std_out, std_err, retc = \
                    node_item.run_su_root_cmd(
                        "yum install -y " + remote_rpm_path)
                if retc == 1 and any(
                                "does not update installed package" in line
                                for line in std_out):
                    print ">> INFO: Package " + rpm + " already installed" \
                          " on node: " + node_hostname
                elif retc != 0:
                    print ">> ERROR: COULD NOT INSTALL RPM ON NODE: " + \
                          node_hostname
                    print std_out
                    print std_err
                    return False

            node_index += 1

        return True


def main():
    """
    main function
    """

    # Disable output buffering to receive the output instantly
    sys.stdout = os.fdopen(sys.stdout.fileno(), "w", 0)
    sys.stderr = os.fdopen(sys.stderr.fileno(), "w", 0)

    run = InstallOSPatch(sys.argv[1])
    run.install_os_patch_packages()

if  __name__ == '__main__':main()