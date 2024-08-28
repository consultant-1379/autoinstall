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


class UpgradeLitp():
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

    def wait_for_puppet(self):
            """
            Current limitation of LITPCDS-6572.
            """
            matchtoken = "Currently applying a catalog"
            cmd = 'mco puppet status | grep "{0}"'.format(matchtoken)
            increment = 5
            total = 0
            node_counters = {}
            has_completed_catalogue = []
            time.sleep(180)
            while True:
                time.sleep(increment)
                total += increment
                stdout, stderr, retc = self.node.run_command(cmd)
                ##If grep fails it means catelog applied
                if retc == 1:

                    stdout, stderr, retc = \
                        self.node.run_command('mco puppet status')
                    return True
                else:
                    for n, tot in node_counters.iteritems():
                        print "Waiting for puppet to complete on {0} (waited {1} seconds)" \
                            .format(n, tot)

                nodes_with_puppet_running = set()
                for line in stdout:
                    node_name = line.split(matchtoken)[0].strip().strip(":").split()[-1]
                    # If node hasn't completed a catalogue track it
                    if not node_name in has_completed_catalogue:
                        nodes_with_puppet_running.add(node_name)

                # Puppet is either not running catalogues or all nodes currently running have completed one before
                if not nodes_with_puppet_running:
                    return True

                current_totals = {}
                for node_name in nodes_with_puppet_running:
                    if node_name in node_counters:
                        current_totals[node_name]=increment+node_counters[node_name]
                    else:
                        current_totals[node_name]=0

                # Find all nodes that have been checked the max number of times and still not completed
                still_running_nodes = []
                for node_name, total in current_totals.iteritems():
                    if total > 180:
                        still_running_nodes.append(node_name)

                # If at least one node has had a total of 180 attempts without finding a completed catalogue - FAIL
                if still_running_nodes:
                    for node_name in still_running_nodes:
                        print "Puppet cycle still running on {0}, exiting failure (waited {1} seconds)" \
                            .format(node_name, current_totals[node_name])
                    return False

                # Add the current counters to the overall
                for name, total in current_totals.iteritems():
                    node_counters[name] = total

                # Find nodes that have completed at least one catalogue
                for name, total in node_counters.iteritems():
                    if not name in current_totals:
                        has_completed_catalogue.append(name)


    def wait_for_restore(self):
        """
        As documented on create_snapshot page will wait until snapshots are
        fully merged after a restore before running create snapshot.
        """
        cmd = "/sbin/lvs | /bin/awk '{print $3}' | /bin/grep 'Owi'"

        max_count = 120
        count = 0
        while True:
            self.node.run_command("/sbin/lvs", logs=True)
            stdout, stderr, retc = \
                self.node.run_command(cmd, logs=True)

            if retc == 1:
                return True

            count += 1

            if count == max_count:
                return False

            time.sleep(10)
            print "Waited {0} secs".format(count * 10)

    def upgrade_litp(self):
        """
        Deploy litp
        """

        print ""
        print "#########################################################"
        print ">> INFO: UPGRADE LITP MS"
        print "#########################################################"
        print ""
        print "UPGRADE ISO: %s" % self.ai_params["LITP_UPGRADE_ISO"]
        print ""

        # CREATE AN AUTOINSTALL DIRECTORY ON THE NODE IF NOT ALREADY PRESENT

        if not self.node.handle_run_command("mkdir -p /tmp/.%s" % self.ai_params["JENKINS_JOB_ID"]):
            print ">> ERROR: MKDIR FAILED ON HOST"
            return False

        # SHOW LITP VERSION AFTER UPDATE
        cmd = "/usr/bin/litp version --all"
        if not self.node.handle_run_command(cmd, expected_stdout=""):
            print ">> ERROR: VERSION COMMAND FAILED ON HOST"
            return False

        if not self.ai_params["SKIP_UPGRADE_SNAPSHOT"]:
            cmd = "/usr/bin/litp remove_snapshot"
            if not self.node.handle_run_command(cmd):
                print ">> ERROR: RUN CREATE SNAPSHOT FAILED ON HOST"
                return False

            # Wait for remove_snapshot to complete
            if not self.node.waitfor_litp_plan(300, 2):
                return False


            cmd = "/usr/bin/litp create_snapshot"
            if not self.node.handle_run_command(cmd):
                print ">> ERROR: RUN CREATE SNAPSHOT FAILED ON HOST"
                return False

            if not self.node.waitfor_litp_plan(120, 2):
                return False

            cmd = "/usr/bin/litp remove_plan"
            if not self.node.handle_run_command(cmd):
                print ">> ERROR: CREATE SNAPSHOT COMMAND FAILED ON HOST"
                return False

        if self.ai_params["UPDATE_RSYSLOG8"]:
            cmd = "litp create -t package -p /software/items/rsyslog8 -o name=EXTRlitprsyslogelasticsearch_CXP9032173 replaces=rsyslog7"
            if not self.node.handle_run_command(cmd):
                print ">> ERROR: CREATE COMMAND FAILED ON HOST"
                return False
            cmd = "litp inherit -p /ms/items/rsyslog8 -s /software/items/rsyslog8"
            if not self.node.handle_run_command(cmd):
                print ">> ERROR: CREATE COMMAND FAILED ON HOST"
                return False
            cmd = "litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/rsyslog8 -s /software/items/rsyslog8"
            if not self.node.handle_run_command(cmd):
                print ">> ERROR: CREATE COMMAND FAILED ON HOST"
                return False
            cmd = "litp inherit -p /deployments/d1/clusters/c1/nodes/n2/items/rsyslog8 -s /software/items/rsyslog8"
            if not self.node.handle_run_command(cmd):
                print ">> ERROR: CREATE COMMAND FAILED ON HOST"
                return False

            cmd = "/usr/bin/litp create_plan"
            if self.node.handle_run_command(cmd):
                # SHOW THE PLAN

                cmd = "/usr/bin/litp show_plan"
                if not self.node.handle_run_command(cmd, expected_stdout=""):
                    print ">> ERROR: PLAN COMMAND FAILED ON HOST"
                    return False

                # RUN THE PLAN
                plan_start_time = time.time()
                cmd = "/usr/bin/litp run_plan"
                if not self.node.handle_run_command(cmd):
                    print ">> ERROR: RUN PLAN FAILED ON HOST"
                    return False

                if not self.node.waitfor_litp_plan(40, 30):
                    print ">> INFO: Plan execution took {0:.0f} seconds"\
                          .format(time.time() - plan_start_time)
                    return False
                else:
                    print ">> INFO: Plan execution took {0:.0f} seconds"\
                          .format(time.time() - plan_start_time)

                # SHOW THE PLAN

                cmd = "/usr/bin/litp show_plan"
                if not self.node.handle_run_command(cmd, expected_stdout=""):
                    print ">> ERROR: PLAN COMMAND FAILED ON HOST"
                    return False

                # REMOVE THE PLAN AND SNAPSHOTS AND CREATE A NEW SNAPSHOT BASED ON SUCCESS OF PLAN
                cmd = "/usr/bin/litp remove_plan"
                if not self.node.handle_run_command(cmd):
                    print ">> ERROR: CREATE SNAPSHOT COMMAND FAILED ON HOST"
                    return False

        # COPY THE LITP UPGRADE ISO ACROSS TO THE MS
        local_path = self.ai_params["LITP_UPGRADE_ISO"]
        pathfile = self.ai_params["LITP_UPGRADE_ISO"].split("/")
        filepath = pathfile[-1]
        remote_path = "/tmp/.%s/%s" % (self.ai_params["JENKINS_JOB_ID"], filepath)
        print "Copy of %s to %s on %s" % (local_path, remote_path, self.ai_params["MS_IP"])
        self.node.copy_file(local_path, remote_path)

        # MOUNT THE LITP ISO
        self.node = NodeConnect(self.ai_params["MS_IP"], "root", constants.ROOT_MS_PASSWD)
        cmd = "mount -o loop %s /mnt/" % remote_path
        if not self.node.handle_run_command(cmd, expected_stderr="not empty"):
            print ">> ERROR: MOUNT COMMAND FAILED"
            return False

        # IMPORT THE PACKAGES INTO LITP - INTO YUM
        #self.node = NodeConnect(self.ai_params["MS_IP"], constants.LITP_USER, constants.LITP_USER_MS_PASSWD)
        #cmd = "/usr/bin/litp import /mnt/litp/plugins litp"
        #if not self.node.handle_run_command(cmd):
        #    print ">> ERROR: LITP IMPORT COMMAND FAILED"
        #    return False

        # IMPORT THE 3PP PACKAGES INTO 3PP - INTO YUM
        #self.node = NodeConnect(self.ai_params["MS_IP"], constants.LITP_USER, constants.LITP_USER_MS_PASSWD)
        #cmd = "/usr/bin/litp import /mnt/litp/3pp/ 3pp"
        #if not self.node.handle_run_command(cmd):
        #    print ">> ERROR: LITP IMPORT COMMAND FAILED"
        #    return False

        cmd = "yum versionlock list"
        stdout, stderr, retc = self.node.run_command(cmd)
        if retc != 0:
            print ">> ERROR: YUM DID NOT RUN CORRECTLY"
            return False

        # IMPORT THE LITP COMPLIANT ISO
        self.node = NodeConnect(self.ai_params["MS_IP"], constants.LITP_USER, constants.LITP_USER_MS_PASSWD)
        cmd = "/usr/bin/litp import_iso /mnt/"
        if not self.node.handle_run_command(cmd):
            print ">> ERROR: LITP IMPORT ISO COMMAND FAILED"
            return False

        count_maintanence = 0
        failure_count = 0
        cmd = "/usr/bin/litp show -p /litp/maintenance"
        while count_maintanence < 20:
            stdout, stderr, retc = self.node.run_command(cmd)
            if retc != 0 or stderr != [] or stdout == []:
                if retc == 1 and "litp does not appear to be running/accessible" in stderr[0]:
                    print "LITP NOT RUNNING DURING MAINTANENCE MODE"
                    failure_count += 1
                elif retc == 1 and "A dependent service is unavailable" in stderr[1]:
                    print "DEPENDENT SERVICE IS UNAVAILABLE"
                    failure_count += 1
                else:
                    print ">> ERROR: MAINTANENCE MODE FAILURE"
                    print ">> retc: {0} stderr[0]: {1} stderr[1]: {2}" \
                            .format(retc, stderr[0], stderr[1])
                    return False
                if failure_count == 10:
                    print ">> ERROR: MAINTANENCE MODE FAILURE"
                    print ">> ERROR: 10 FAILURES"
                    return False
            if retc == 0 and stderr == [] and stdout != []:
                status = None
                for line in stdout:
                    if "status:" in line:
                        status = line
                if "status: Done" in status:
                    break
            count_maintanence += 1
            time.sleep(60)

        restart_timeout = 10
        found = False
        while restart_timeout > 0 and not found:
            restart_timeout -= 1
            # SLEEP TO ALLOW LITP TO RESTART SHOULD THIS RUN AS SOON AS MAINTANENCE MODE IS COMPLETE
            time.sleep(60)
            stdout, stderr, retc = self.node.run_command(cmd)
            if retc != 0 or stderr != [] or stdout == []:
                found = False
            else:
                found = True
                break
        if not found:
            print ">> ERROR: MAINTANENCE MODE FAILURE"
            return False
        status = None
        for line in stdout:
            if "status:" in line:
                status = line
        if "status: Done" not in status:
            print ">> ERROR: MAINTANENCE MODE FAILURE"
            return False

        # UMOUNT THE LITP ISO
        self.node = NodeConnect(self.ai_params["MS_IP"], "root", constants.ROOT_MS_PASSWD)
        cmd = "umount /mnt/"
        if not self.node.handle_run_command(cmd):
            print ">> ERROR: UMOUNT COMMAND FAILED"
            return False

        cmd = "yum versionlock list"
        stdout, stderr, retc = self.node.run_command(cmd)
        if retc != 0:
            print ">> ERROR: YUM DID NOT RUN CORRECTLY"
            return False

        # IF 3pp upgrade given, upgrade litp and 3pp(MS)

        #self.node = NodeConnect(self.ai_params["MS_IP"], "root", constants.ROOT_MS_PASSWD)

        #print ""
        #print "#########################################################"
        #print ">> INFO: UPGRADE LITP MS - CORE"
        #print "#########################################################"
        #print ""

        # USE YUM TO UPGRADE
        #cmd = "yum upgrade ERIClitpcore_CXP9030418 -y"
        #stdout, stderr, retc = self.node.run_command(cmd)
        #if retc != 0:
        #    print ">> ERROR: YUM DID NOT RUN CORRECTLY"
        #    return False

        #if not self.wait_for_puppet():
        #    print ">> ERROR: PUPPET CYCLE STILL RUNNING"
        #    return False

        #cmd = "/sbin/service litpd status"
        #stdout, stderr, retc = self.node.run_command(cmd)
        # TODO CHECK STDOUT
        #if retc != 0:
        #    print ">> ERROR: LITPD SERVICE IS NOT RUNNING"
        #    return False

        # SET LITP LOGGING TO DEBUG
        cmd = "litp update -p /litp/logging -o force_debug=true"
        if not self.node.handle_run_command(cmd):
            print ">> WARNING: TURN ON LITP DEBUG FAILED ON HOST"

        #cmd = "yum versionlock list"
        #stdout, stderr, retc = self.node.run_command(cmd)
        #if retc != 0:
        #    print ">> ERROR: YUM DID NOT RUN CORRECTLY"
        #    return False

        #print ""
        #print "#########################################################"
        #print ">> INFO: UPGRADE LITP MS - LITP"
        #print "#########################################################"
        #print ""

        #cmd = "yum --disablerepo=* --enablerepo=LITP upgrade -y"
        #stdout, stderr, retc = self.node.run_command(cmd)
        #if retc != 0:
        #    print ">> ERROR: YUM DID NOT RUN CORRECTLY"
        #    return False

        #if not self.wait_for_puppet():
        #    print ">> ERROR: PUPPET CYCLE STILL RUNNING"
        #    return False

        #cmd = "/sbin/service litpd status"
        #stdout, stderr, retc = self.node.run_command(cmd)
        # TODO CHECK STDOUT
        #if retc != 0:
        #    print ">> ERROR: LITPD SERVICE IS NOT RUNNING"
        #    return False

        # SET LITP LOGGING TO DEBUG
        #cmd = "litp update -p /litp/logging -o force_debug=true"
        #if not self.node.handle_run_command(cmd):
        #    print ">> WARNING: TURN ON LITP DEBUG FAILED ON HOST"

        #cmd = "yum versionlock list"
        #stdout, stderr, retc = self.node.run_command(cmd)
        #if retc != 0:
        #    print ">> ERROR: YUM DID NOT RUN CORRECTLY"
        #    return False

        # IF OS PATCHES OPTION CHOSEN, UPDATE THEM
        if self.ai_params["OS_PATCHES_UPGRADE"]:
            print ""
            print "#########################################################"
            print ">> INFO: APPLY OS PATCHES ON MS"
            print "#########################################################"
            print ""
            print "OS PATCHES: %s" % self.ai_params["OS_PATCHES_PATH_UPGRADE"]
            print ""

            # COPY THE OS PATCHES ACROSS TO THE MS
            local_path = self.ai_params["OS_PATCHES_PATH_UPGRADE"]
            pathfile = self.ai_params["OS_PATCHES_PATH_UPGRADE"].split("/")
            filepath = pathfile[-1]
            remote_path = "/tmp/.%s/%s" % (self.ai_params["JENKINS_JOB_ID"], filepath)
            if "http" in self.ai_params["OS_PATCHES_PATH_UPGRADE"]:

                cmd = 'curl %s --head -k -s -S | grep "HTTP/"' % \
                      self.ai_params["OS_PATCHES_PATH_UPGRADE"]

                # Can the Patches be accessed from the MS?
                from_ms = True
                from_gw = False
                std_out, _, ret_c = self.node.run_command(cmd)
                if not any("OK" in line for line in std_out) or ret_c != 0:
                    from_ms = False

                # Can the Patches be accessed from the GW?
                if not from_ms:
                    from_gw = True
                    std_out, _, ret_c = self.node.run_command_local(cmd)
                    if not any("OK" in line for line in std_out) or ret_c != 0:
                        from_gw = False

                if from_ms:
                    # Can get the patches from the MS, so just a direct copy
                    local_path = self.ai_params["OS_PATCHES_PATH_UPGRADE"]
                    if not self.node.wget_file(local_path, remote_path):
                            print ">> ERROR: COPY OF FILE OVER WGET FAILED"
                            return False

                elif from_gw:
                    # Can get the patches from the GW, copy to GW first then MS

                    # Step 1: Copy the patches to the GW
                    # Check if this is a vApp with /export/data/ directory
                    is_vapp = False
                    cmd = "[ -d \"/export/data/\" ]"
                    _, _, ret_c = self.node.run_command_local(cmd)
                    if ret_c == 0:
                        is_vapp = True
                        gw_remote_path = "/export/data/%s" % filepath
                    else:
                        gw_remote_path = "/var/www/html/%s" % filepath

                    retry_count = 0

                    local_path = self.ai_params["OS_PATCHES_PATH_UPGRADE"]

                    #Check if the patch has already been downloaded in a previous step
                    cmd = "[ -d {0} ]".format(gw_remote_path)
                    _, _, ret_c = self.node.run_command_local(cmd)
                    if ret_c == 0:
                        #OS Patch already exists skip Wget
                        print "OS Patch already exists on GW"
                    else:
                        if not self.node.wget_file(local_path, gw_remote_path,
                                                run_local=True):
                            print ">> ERROR: COPY OF FILE OVER WGET FAILED"
                            return False

                    # If this is a vApp then make symbolic link to patches
                    if is_vapp:
                        cmd = "ln -s /export/data/{0} /var/www/html/{0}".format(filepath)
                        _, Error, ret_c = self.node.run_command_local(cmd)
                        # If symbolic link already exists
                        if "ln: creating symbolic link `/var/www/html/{0}': File exists".format(filepath) in Error:
                            #remove symbolic link
                            cmd = "rm /var/www/html/{0}".format(filepath)
                            _, _, _ = self.node.run_command_local(cmd)
                            #Create new symbolic link
                            cmd = "ln -s /export/data/{0} /var/www/html/{0}".format(filepath)
                            _, _, ret_c = self.node.run_command_local(cmd)
                        if ret_c != 0:
                            print ">> ERROR: COULD NOT CREATE SYMLINK TO PATCHES."
                            return False

                    # Step 2: Copy the patches from the GW to the MS
                    retry_count = 0
                    cmd = 'wget -q -O - --no-check-certificate "http://{0}/{1}" -O {2}'.format(
                        self.ai_params["GW_IP"], filepath, remote_path)
                    while True:
                        if self.node.handle_run_command(cmd):
                            break

                        retry_count += 1
                        if retry_count == 5:
                            print ">> ERROR: COPY OF FILE OVER WGET FROM GW TO MS FAILED"
                            return False

                        print ">> WARNING: WGET FAILED, Retrying"
                        time.sleep(5)

                else:
                    # Patches cannot be accessed.
                    print ">> ERROR: CANNOT ACCESS OS PATCHES PATH PROVIDED: {0}".format(
                        self.ai_params["OS_PATCHES_PATH_UPGRADE"])
                    return False

            else:
                # COPY THE OS PATCHES ACROSS TO THE MS
                print "Copy of %s to %s on %s" % (local_path, remote_path, self.ai_params["MS_IP"])
                self.node.copy_file(local_path, remote_path)

            # HAS TO BE PERFORMED AS ROOT
            self.node = NodeConnect(self.ai_params["MS_IP"], "root", constants.ROOT_MS_PASSWD)

            # TEST IF PATCHES ARE ISO OR TARBALL
            if ".iso" in self.ai_params["OS_PATCHES_PATH_UPGRADE"]:

                # MOUNT ISO
                cmd = "/bin/mount -o loop %s /mnt" % (remote_path)
                if not self.node.handle_run_command(cmd, expected_stderr="not empty"):
                    print ">> ERROR: MOUNT FAILED"
                    return False

                # FIND THE "package" DIRECTORY
                cmd = "find /mnt/RHEL/ -maxdepth 5 -type d -name '*package*'| head -n1"
                stdout, stderr, retc = self.node.run_command(cmd)
                if stdout == [] or stderr != [] or retc != 0:
                    print ">> ERROR: FIND RETURNED NO DIRECTORY WITH PACKAGES"
                    return False

                packages = stdout[0]

                # IMPORT THE PACKAGES
                cmd = "/usr/bin/litp import %s %s" % (packages, constants.RHEL7_UPDATES_DIR)
                if not self.node.handle_run_command(cmd):
                    print ">> ERROR: LITP IMPORT COMMAND FAILED"
                    return False

                # UNMOUNT ISO
                cmd = "/bin/umount /mnt"
                if not self.node.handle_run_command(cmd):
                    print ">> ERROR: UMOUNT FAILED"
                    return False

            else:

                # UNPACK TARBALL
                cmd = "/bin/tar -C /tmp/.%s/ -xvzf %s >/tmp/upgrade_rhel_patches_out.txt 2>&1" % (self.ai_params["JENKINS_JOB_ID"], remote_path)
                if not self.node.handle_run_command(cmd):
                    print ">> ERROR: UNTAR FAILED ON HOST"
                    return False

                cmd = "mv /tmp/upgrade_rhel_patches_out.txt /tmp/.%s/" % self.ai_params["JENKINS_JOB_ID"]
                if not self.node.handle_run_command(cmd):
                    print ">> ERROR: MOVING OF FILE ON HOST FAILED"
                    return False

                # FIND THE "package" DIRECTORY, THIS IS TO MAKE IT GENERIC IN CASE OTHER PATCHES ARE LOADED
                cmd = "find /tmp/.%s/RHEL/ -maxdepth 5 -type d -name '*package*'| head -n1" % self.ai_params["JENKINS_JOB_ID"]
                stdout, stderr, retc = self.node.run_command(cmd)
                if stdout == [] or stderr != [] or retc != 0:
                    print ">> ERROR: FIND RETURNED NO DIRECTORY WITH PACKAGES"
                    return False

                packages = stdout[0]

                # IMPORT THE PACKAGES INTO LITP - INTO YUM
                cmd = "/usr/bin/litp import %s %s" % (packages, constants.RHEL7_UPDATES_DIR)
                if not self.node.handle_run_command(cmd):
                    print ">> ERROR: LITP IMPORT COMMAND FAILED"
                    return False

                ##Only warning while we test command
                cmd = "rm -rf /tmp/.%s/RHEL" % self.ai_params["JENKINS_JOB_ID"]
                stdout, stderr, retc = self.node.run_command(cmd)
                if stdout != [] or stderr != [] or retc != 0:
                    print ">> WARNING: Cannot remove file"
                    #return False

            # REMOVE PATCHES FILE
            cmd = "rm -rf %s" % remote_path
            stdout, stderr, retc = self.node.run_command(cmd)
            if stdout != [] or stderr != [] or retc != 0:
                print ">> ERROR: Cannot remove file"
                return False

            # USE YUM TO UPGRADE
            cmd = "yum  --disablerepo=* --enablerepo=UPDATES upgrade -y"
            stdout, stderr, retc = self.node.execute_expects(cmd, [],
                                                             timeout_param=600)
            if retc != 0:
                print ">> ERROR: YUM DID NOT RUN CORRECTLY"
                return False

            restart_needed = True
            ###CATCH error case
            if "No Packages marked for Update" in " ".join(stdout):
                print ">> WARNING: NO PACKAGES MARKED FOR UPDATE"
                restart_needed = False
                #return False

            # REBOOT THE NODE
            if restart_needed:
                cmd = "shutdown -r +1"
                stdout, stderr, retc = self.node.run_command(cmd)
                if retc != 0:
                    print ">> ERROR: REBOOT OF NODE WAS UNSUCCESSFUL"
                    return False

                print "Sleeping for 10 minutes to allow reboot to occur..."
                time.sleep(600)

                self.node = NodeConnect(self.ai_params["MS_IP"], constants.LITP_USER, constants.LITP_USER_MS_PASSWD)

            cmd = "litp update -p /litp/logging -o force_debug=true"
            if not self.node.handle_run_command(cmd):
                print ">> WARNING: TURN ON LITP DEBUG FAILED ON HOST"
                print "Sleeping for 2 minutes to give LITP time to start"
                time.sleep(120)
        print ""
        print "#########################################################"
        print ">> INFO: UPGRADE LITP PEER NODES - LITP/OS_PATCHES"
        print "#########################################################"
        print ""

        # TEMP UNTIL BUG IS FIXED
        #time.sleep(180)
        print "TURNING ON VXVM DEBUG"
        try:
            print "SANITY IPS ARE: ", self.ai_params["SANITY_CHECK_IPS"]
            if self.ai_params["SANITY_CHECK_IPS"] == []:
                print "Please set sanity IPs"
            else:
                node_index = 0
                print "SANITY IPS ARE BEFORE LOOP: ", self.ai_params["SANITY_CHECK_IPS"]
                for ipaddr in self.ai_params["SANITY_CHECK_IPS"].split(","):
                    print "SANITY IPS ARE IN LOOP: ", self.ai_params["SANITY_CHECK_IPS"]
                    ipaddr = ipaddr.replace('"', '')

                    if not (ipaddr == 'no_sanity'):
                        print "---Checking node {0}---".format(ipaddr)
                        print "-----------------------"

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

                        cmd = "/sbin/vxconfigd -k -x log"
                        _, _, rc = node_item.run_su_root_cmd(cmd)
                        if rc != 0:
                            print ">>WARNING: vxvm debug not set on node"
                        time.sleep(5)
                    else:
                        print "SANITY IPS SET TO 'no_sanity'. SKIPPING CHECKS."
        except Exception as err:
            print "Failed to turn on vxvm debug: {0}".format(err)

        self.node = NodeConnect(self.ai_params["MS_IP"], constants.LITP_USER, constants.LITP_USER_MS_PASSWD)

        cmd = "/usr/bin/litp upgrade -p /deployments/d1/"
        if not self.node.handle_run_command(cmd):
            print ">> ERROR: RUN UPGRADE COMMAND FAILED SNAPSHOT FAILED ON HOST"
            return False

        cmd = "/usr/bin/litp create_plan"
        if self.node.handle_run_command(cmd):
            # SHOW THE PLAN

            cmd = "/usr/bin/litp show_plan"
            if not self.node.handle_run_command(cmd, expected_stdout=""):
                print ">> ERROR: PLAN COMMAND FAILED ON HOST"
                return False

            # RUN THE PLAN
            plan_start_time = time.time()
            cmd = "/usr/bin/litp run_plan"
            if not self.node.handle_run_command(cmd):
                print ">> ERROR: RUN PLAN FAILED ON HOST"
                return False

            if not self.node.waitfor_litp_plan(120, 60):
                return False
            else:
                print ">> INFO: Plan execution took {0:.0f} seconds"\
                      .format(time.time() - plan_start_time)

            # SHOW THE PLAN

            cmd = "/usr/bin/litp show_plan"
            if not self.node.handle_run_command(cmd, expected_stdout=""):
                print ">> ERROR: PLAN COMMAND FAILED ON HOST"
                return False

            # REMOVE THE PLAN AND SNAPSHOTS AND CREATE A NEW SNAPSHOT BASED ON SUCCESS OF PLAN
            cmd = "/usr/bin/litp remove_plan"
            if not self.node.handle_run_command(cmd):
                print ">> ERROR: CREATE SNAPSHOT COMMAND FAILED ON HOST"
                return False

        else:

            print ">> WARNING: NO PLAN GENERATED TO UPGRADE NODES"

        ##If puppet errors found fail the install
        time.sleep(120)
        cmd = "/bin/grep 'Error 400' /var/log/messages | wc -l"
        stdout, stderr, retc = self.node.run_command(cmd)

        if stdout[0] != '0':
            print ">> WARNING: Puppet errors detected"

        # RESTORE SNAPSHOT OPTION
        if self.ai_params["RESTORE_UPGRADE"]:
            cmd = "/usr/bin/litp restore_snapshot"
            if not self.node.handle_run_command(cmd):
                print ">> ERROR: RUN RESTORE SNAPSHOT FAILED ON HOST"
                return False

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

            print "Sleeping for 2 minutes to allow shutdown to complete"
            time.sleep(120)
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

            print "Sleeping for 5 minutes to allow startup to complete"
            time.sleep(300)

            self.node = NodeConnect(self.ai_params["MS_IP"], "root", constants.ROOT_MS_PASSWD)
            self.node.run_command("/sbin/lvs", logs=True)
            self.node.run_command("/sbin/lvs -a", logs=True)
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
                print ">> ERROR: RUN CREATE SNAPSHOT FAILED ON HOST"
                return False

            if not self.node.waitfor_litp_plan(60, 2):
                return False
            ##No plan is generated in the restore snapshot case.
            ##See here: http://confluence-oss.lmera.ericsson.se/display/LITP2UC/restore_snapshot+Command
            #if not self.node.waitfor_litp_plan(30, 2):
                #return False
	    ##Sleeping due to fixed bug LITPCDS-7177 still in the upgrade source.
            self.node = NodeConnect(self.ai_params["MS_IP"], "root", constants.ROOT_MS_PASSWD)
            time.sleep(10)
            self.node.run_command("/sbin/lvs", logs=True)
            self.node.run_command("/sbin/lvs -a", logs=True)
            self.node = NodeConnect(self.ai_params["MS_IP"], constants.LITP_USER, constants.LITP_USER_MS_PASSWD)

            cmd = "/usr/bin/litp create_snapshot"
            if not self.node.handle_run_command(cmd):
                print ">> ERROR: RUN CREATE SNAPSHOT FAILED ON HOST"
                return False

            if not self.node.waitfor_litp_plan(120, 2):
                return False

            self.node = NodeConnect(self.ai_params["MS_IP"], "root", constants.ROOT_MS_PASSWD)
            self.node.run_command("/sbin/lvs", logs=True)
            self.node.run_command("/sbin/lvs -a", logs=True)
            self.node = NodeConnect(self.ai_params["MS_IP"], constants.LITP_USER, constants.LITP_USER_MS_PASSWD)
            cmd = "/usr/bin/litp remove_plan"
            if not self.node.handle_run_command(cmd):
                print ">> ERROR: CREATE SNAPSHOT COMMAND FAILED ON HOST"
                return False

        #return False

        if not self.ai_params["SKIP_UPGRADE_SNAPSHOT"]:
            cmd = "/usr/bin/litp remove_snapshot"
            if not self.node.handle_run_command(cmd):
                print ">> ERROR: RUN CREATE SNAPSHOT FAILED ON HOST"
                return False

            if not self.node.waitfor_litp_plan(60, 2):
                return False

            cmd = "/usr/bin/litp create_snapshot"
            if not self.node.handle_run_command(cmd):
                print ">> ERROR: RUN CREATE SNAPSHOT FAILED ON HOST"
                return False

            if not self.node.waitfor_litp_plan(120, 2):
                return False

            cmd = "/usr/bin/litp remove_plan"
            if not self.node.handle_run_command(cmd):
                print ">> ERROR: CREATE SNAPSHOT COMMAND FAILED ON HOST"
                return False

        # SHOW LITP VERSION AFTER UPDATE
        cmd = "/usr/bin/litp version --all"
        if not self.node.handle_run_command(cmd, expected_stdout=""):
            print ">> ERROR: VERSION COMMAND FAILED ON HOST"
            return False

        #if not self.node.handle_run_command("mkdir -p /home/litp-admin/.%s" % self.ai_params["JENKINS_JOB_ID"]):
        self.node = NodeConnect(self.ai_params["MS_IP"], "root", constants.ROOT_MS_PASSWD)
        cmd = "/bin/mv /tmp/.%s /home/litp-admin/" % self.ai_params["JENKINS_JOB_ID"]
        if not self.node.handle_run_command(cmd):
            print ">> ERROR: MOVING OF DIRECTORY ON HOST FAILED"
            return False

        return True

def main():
    """
    main function
    """

    # Disable output buffering to receive the output instantly
    sys.stdout = os.fdopen(sys.stdout.fileno(), "w", 0)
    sys.stderr = os.fdopen(sys.stderr.fileno(), "w", 0)
    if len(sys.argv) != 6:
        print ">> ERROR: Not all required arguments supplied: %s" % sys.argv
        return False

    #run = DeployLitp(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5])
    #run.deploy_litp()

if  __name__ == '__main__':main()
