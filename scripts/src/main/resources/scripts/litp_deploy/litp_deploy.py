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
@summary:   Deploy litp
'''

import sys
import os
from common_platform_files.common_methods import NodeConnect
import common_platform_files.constants as constants
import time


class DeployLitp():
    """
    Class to deploy litp using install scripts
    """
    def __init__(self, ai_params):
        """
        Initialise variables
        """

        self.ai_params = ai_params
        self.node = NodeConnect(self.ai_params["MS_IP"], constants.LITP_USER, constants.LITP_USER_MS_PASSWD)
        self.ai_params["NODE_IPS"] = self.ai_params["NODE_IPS"].split(",")
        self.pw_attempts = 3

    def deploy_litp(self):
        """
        Deploy litp
        """

        # CREATE AN AUTOINSTALL DIRECTORY ON THE NODE IF NOT ALREADY PRESENT

        if not self.node.handle_run_command("mkdir -p /tmp/.%s" % self.ai_params["JENKINS_JOB_ID"]):
            print ">> ERROR: MKDIR FAILED ON HOST"
            return False

        print ""
        print "#########################################################"
        print ">> INFO: DEPLOY LITP"
        print "#########################################################"
        print ""
        print "INSTALL SCRIPT: %s" % self.ai_params["INSTALL_FILE"]
        print "CLUSTER SCRIPT: %s" % self.ai_params["CLUSTER_FILE_NAME"]
        if self.ai_params["PRE_XML_LOAD_FILE"]: print "PRE_XML_LOAD SCRIPT: %s" % self.ai_params["PRE_XML_LOAD_FILE"]
        print "INSTALL OPTION: %s" % self.ai_params["INSTALL_OPTION"]
        print ""

        self.node = NodeConnect(self.ai_params["MS_IP"], constants.LITP_USER, constants.LITP_USER_MS_PASSWD)

        # IF NOT SKIPPING SNAPSHOT CREATION, RUN THE SNAPSHOT CREATION
        if not self.ai_params["SKIP_INSTALL_SNAPSHOT"]:
            # CREATE A SNAPSHOT
            cmd = "/usr/bin/litp create_snapshot"
            if not self.node.handle_run_command(cmd):
                print ">> ERROR: CREATE SNAPSHOT COMMAND FAILED ON HOST"
                return False

            if not self.node.waitfor_litp_plan(120, 2):
                return False

        # RUN THE DEPLOYMENT SCRIPT
        load_xml_directly = False
        if self.ai_params["INSTALL_FILE"].endswith(".xml"):
            load_xml_directly = True

        # COPY DEPLOYMENT SCRIPT, CLUSTER FILE AND PRE_XML_LOAD SCRIPT TO AI DIRECTORY
        local_path = "%s/%s" % (self.ai_params["AUTOINSTALL_DIR"], self.ai_params["INSTALL_FILE"])
        if load_xml_directly:
            remote_path = "/tmp/.%s/%s" % (self.ai_params["JENKINS_JOB_ID"], "install_script.xml")
        else:
            remote_path = "/tmp/.%s/%s" % (self.ai_params["JENKINS_JOB_ID"], "install_script.sh")
        print "Copy of %s to %s on %s" % (local_path, remote_path, self.ai_params["MS_IP"])
        self.node.copy_file(local_path, remote_path)

        # If a pre_xml_load script was specified copy to AI directory
        if self.ai_params["PRE_XML_LOAD_FILE"]:
            local_path = "%s/%s" % (self.ai_params["AUTOINSTALL_DIR"],
                                    self.ai_params["PRE_XML_LOAD_FILE"])
            remote_path = "/tmp/.%s/%s" % (self.ai_params["JENKINS_JOB_ID"],
                                           self.ai_params["PRE_XML_LOAD_FILE"])
            print "Copy of %s to %s on %s" % (
            local_path, remote_path, self.ai_params["MS_IP"])
            self.node.copy_file(local_path, remote_path)

        local_path = "%s/%s" % (self.ai_params["AUTOINSTALL_DIR"], self.ai_params["CLUSTER_FILE_NAME"])
        remote_path = "/tmp/.%s/%s" % (self.ai_params["JENKINS_JOB_ID"], self.ai_params["CLUSTER_FILE_NAME"])
        print "Copy of %s to %s on %s" % (local_path, remote_path, self.ai_params["MS_IP"])
        self.node.copy_file(local_path, remote_path)

        # CHECK CLUSTER FILE, IF COPY SCRIPT IS PRESENT, THEN COPY, IF NOT IGNORE IT
        self.node = NodeConnect(self.ai_params["MS_IP"], "root", constants.ROOT_MS_PASSWD)
        print ""
        cmd = "cat %s | grep 'copytestfile' | grep -v '#'" % local_path
        stdout, _, _ = self.node.run_command_local(cmd, logs=False)

        #Get files which need to be joined later
        cmd = "cat %s | grep 'jointestfile' | grep -v '#'" % local_path
        join_files, _, _ = self.node.run_command_local(cmd, logs=False)
        if stdout == []:
            print "### NO FILES TO COPY FOUND IN CLUSTER FILE ###"
        else:
            for line in stdout:
                copy_paths = line.split("=")[-1]
                copy_paths = copy_paths.replace('"', "")

                if "http" in copy_paths:
                    thepath = copy_paths.rsplit(":", 1)[1]
                    nofilepath = "/".join(thepath.split("/")[:-1])

                    # DO THE COPY
                    if not self.node.handle_run_command("mkdir -p -m 777 %s" % nofilepath):
                        print ">> ERROR: MKDIR FAILED ON HOST"
                        return False
                    local_path = copy_paths.rsplit(":", 1)[0]
                    remote_path = copy_paths.rsplit(":", 1)[1]
                    print "Copy of %s to %s on %s" % (local_path, remote_path,
                                                          self.ai_params["MS_IP"])

                    if not self.node.get_file_to_node(local_path, remote_path):
                        print "Using legacy copy method"

                        cmd = 'curl %s --head -k -s -S | grep "HTTP/"' % copy_paths.rsplit(":", 1)[0]
                        stdout, stderr, retc = self.node.run_command_local(cmd, logs=False)
                        if "OK" not in stdout[0] or retc != 0:
                            print "### FILE '%s' does not exist, copy not attempted" % thepath[0]
                        else:
                            if not self.node.wget_file(local_path, remote_path):
                                print ">> ERROR: COPY OF FILE OVER WGET FAILED"
                                return False
                else:
                    if os.path.isfile(copy_paths.split(":")[0]):
                        thepath = copy_paths.split(":")[1]
                        nofilepath = "/".join(thepath.split("/")[:-1])
                        if not self.node.handle_run_command("mkdir -p -m 777 %s" % nofilepath):
                            print ">> ERROR: MKDIR FAILED ON HOST"
                            return False
                        print "Copy of %s to %s on %s" % (copy_paths.split(":")[0], copy_paths.split(":")[1], self.ai_params["MS_IP"])
                        self.node.copy_file(copy_paths.split(":")[0], copy_paths.split(":")[1])
                    else:
                        print "### FILE '%s' does not exist, copy not attempted" % copy_paths.split(":")[0]

        print ""
        ##JOIN any files if requested
        for line in join_files:
            print "JOINING FILES: {0}".format(line)
            source_files = line.split("=")[1].split(":")[0]
            source_files = source_files.replace('"', "")
            dest_file = line.split("=")[1].split(":")[1]
            dest_file = dest_file.replace('"', "")
            cmd = "cat {0} >> {1}".format(source_files,
                                          dest_file)
            self.node.handle_run_command(cmd)
            cmd = "rm -f {0}".format(source_files)
            self.node.handle_run_command(cmd)

        self.node = NodeConnect(self.ai_params["MS_IP"], constants.LITP_USER, constants.LITP_USER_MS_PASSWD)

        # LOAD CLI AS NORMAL

        if not load_xml_directly:

            cmd = "sh /tmp/.%s/install_script.sh /tmp/.%s/%s" % (self.ai_params["JENKINS_JOB_ID"], self.ai_params["JENKINS_JOB_ID"], self.ai_params["CLUSTER_FILE_NAME"])
            #stdout, stderr, retc = self.node.run_command(cmd)
            if self.ai_params["EXPECT_LARGE_PLAN"]:
                time_out = 2700
            else:
                time_out = 900
            stdout, stderr, retc = self.node.execute_expects(cmd, [], timeout_param=time_out)
            if retc != 0:
                print ">> ERROR: RUNNING OF DEPLOYMENT SCRIPT FAILED ON HOST"
                return False
        else:
            if self.ai_params["PRE_XML_LOAD_FILE"]:
                # Run the PRE_XML_LOAD SCRIPT
                cmd = "sh /tmp/.{0}/{1} /tmp/.{0}/{2}".format(self.ai_params["JENKINS_JOB_ID"], self.ai_params["PRE_XML_LOAD_FILE"], self.ai_params["CLUSTER_FILE_NAME"])
                _, std_err, rc = self.node.run_command(cmd)
                if std_err != [] or rc != 0:
                    print ">> ERROR: RUNNING OF PRE_LOAD_XML FAILED ON HOST"
                    return False

            if self.ai_params["INSTALL_OPTION"] == "XML_merge":
                # LOAD XML FILE
                cmd = "/usr/bin/litp load --merge -p / -f /tmp/.%s/install_script.xml" % self.ai_params["JENKINS_JOB_ID"]
                if not self.node.handle_run_command(cmd):
                    print ">> ERROR: LOADING OF DEPLOYMENT XML FAILED ON HOST"
                    return False

                # CREATE THE PLAN
                cmd = "/usr/bin/litp create_plan"
                if not self.node.handle_run_command(cmd):
                    print ">> ERROR: PLAN COMMAND FAILED ON HOST"
                    return False

            if self.ai_params["INSTALL_OPTION"] == "XML_replace":
                cmd = "/usr/bin/litp load --replace -p / -f /tmp/.%s/install_script.xml" % self.ai_params["JENKINS_JOB_ID"]
                if not self.node.handle_run_command(cmd):
                    print ">> ERROR: LOADING OF DEPLOYMENT XML FAILED ON HOST"
                    return False

                # CREATE THE PLAN
                cmd = "/usr/bin/litp create_plan"
                if not self.node.handle_run_command(cmd):
                    print ">> ERROR: PLAN COMMAND FAILED ON HOST"
                    return False

        if self.ai_params["INSTALL_OPTION"] == "XML_merge" or self.ai_params["INSTALL_OPTION"] == "XML_replace" and not load_xml_directly:

            print ""
            print "EXPORTING MODEL TO XML FILE TO LOAD BACK IN"
            print ""

            # SHOW THE PLAN
            if self.ai_params["EXPECT_LARGE_PLAN"]:
                cmd = "/usr/bin/litp show_plan &>> /tmp/.{0}/initial_litp_show_plan_{1}.txt".format(self.ai_params["JENKINS_JOB_ID"], time.strftime("%H%M%S"))
                if not self.node.run_command(cmd):
                    print ">> ERROR: PLAN COMMAND FAILED ON HOST"
            else:
                cmd = "/usr/bin/litp show_plan"
                if not self.node.handle_run_command(cmd, expected_stdout=""):
                    print ">> ERROR: PLAN COMMAND FAILED ON HOST"
                    return False

            if not self.ai_params["SKIP_INSTALL_SNAPSHOT"]:
                cmd = "/usr/bin/litp remove_snapshot"
                if not self.node.handle_run_command(cmd):
                    print ">> ERROR: REMOVE SNAPSHOT COMMAND FAILED ON HOST"
                    return False

                if not self.node.waitfor_litp_plan(60, 2):
                    return False

            # EXPORT XML FILE
            cmd = "/usr/bin/litp export -p / -f /tmp/.%s/deployment_script.xml" % self.ai_params["JENKINS_JOB_ID"]
            if not self.node.handle_run_command(cmd):
                print ">> ERROR: RUNNING OF DEPLOYMENT SCRIPT FAILED ON HOST"
                return False

            self.node = NodeConnect(self.ai_params["MS_IP"], "root", constants.ROOT_MS_PASSWD)
            # STOP LITPD SERVICE
            cmd = "/bin/systemctl stop litpd.service"
            stdout, stderr, retc = self.node.run_command(cmd)
            #if stdout != [] or stderr != [] or retc != 0:
            if retc != 0:
                print ">> ERROR: RUNNING OF DEPLOYMENT SCRIPT FAILED ON HOST"
                return False

            # DROP MODEL TABLE
            cmd = "/usr/local/bin/litpd.sh --purgedb"
            stdout, stderr, retc = self.node.run_command(cmd)
            if retc != 0:
                print ">> ERROR: RUNNING OF DEPLOYMENT SCRIPT FAILED ON HOST"
                return False

            # START LITPD SERVICE
            cmd = "/bin/systemctl start litpd.service"
            stdout, stderr, retc = self.node.run_command(cmd)
            #if stdout != [] or stderr != [] or retc != 0:
            if retc != 0:
                print ">> ERROR: RUNNING OF DEPLOYMENT SCRIPT FAILED ON HOST"
                return False

            cmd = "litp update -p /litp/logging -o force_debug=true"
            if not self.node.handle_run_command(cmd):
                print ">> WARNING: TURN ON LITP DEBUG FAILED ON HOST"

            self.node = NodeConnect(self.ai_params["MS_IP"], constants.LITP_USER, constants.LITP_USER_MS_PASSWD)

            if not self.ai_params["SKIP_INSTALL_SNAPSHOT"]:
                cmd = "/usr/bin/litp create_snapshot"
                if not self.node.handle_run_command(cmd):
                    print ">> ERROR: CREATE SNAPSHOT COMMAND FAILED ON HOST"
                    return False

                if not self.node.waitfor_litp_plan(120, 2):
                    return False

            if self.ai_params["INSTALL_OPTION"] == "XML_merge":
            # LOAD XML FILE
                cmd = "/usr/bin/litp load --merge -p / -f /tmp/.%s/deployment_script.xml" % self.ai_params["JENKINS_JOB_ID"]
                if not self.node.handle_run_command(cmd):
                    print ">> ERROR: RUNNING OF DEPLOYMENT SCRIPT FAILED ON HOST"
                    return False

            if self.ai_params["INSTALL_OPTION"] == "XML_replace":
                cmd = "/usr/bin/litp load --replace -p / -f /tmp/.%s/deployment_script.xml" % self.ai_params["JENKINS_JOB_ID"]
                if not self.node.handle_run_command(cmd):
                    print ">> ERROR: RUNNING OF DEPLOYMENT SCRIPT FAILED ON HOST"
                    return False

            # RE_CREATE THE PLAN
            cmd = "/usr/bin/litp create_plan"
            if not self.node.handle_run_command(cmd):
                print ">> ERROR: PLAN COMMAND FAILED ON HOST"
                return False


        if self.ai_params["EXPECT_LARGE_PLAN"]:
            cmd = "/usr/bin/litp show_plan &>> /tmp/.{0}/initial_litp_show_plan_{1}.txt".format(self.ai_params["JENKINS_JOB_ID"], time.strftime("%H%M%S"))
            if not self.node.run_command(cmd):
                print ">> ERROR: PLAN COMMAND FAILED ON HOST"
        else:
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

        if self.ai_params["EXPECT_LARGE_PLAN"]:
            sleep_seconds = 300
            try_attempts = 144
        else:
            sleep_seconds = 60
            try_attempts = 180

        monitor_script_path = None
        if self.ai_params["MONITOR_SCRIPT"]:
            local_path = "%s/%s" % (self.ai_params["AUTOINSTALL_DIR"],
                                    self.ai_params["MONITOR_FILE_NAME"])
            remote_path = "/tmp/.%s/%s" % (self.ai_params["JENKINS_JOB_ID"],
                                           self.ai_params["MONITOR_FILE_NAME"])
            monitor_script_path = remote_path
            print "Copy of %s to %s on %s" % (local_path, remote_path, self.ai_params["MS_IP"])
            self.node.copy_file(local_path, remote_path)


        if not self.node.waitfor_litp_plan(try_attempts, sleep_seconds, initial_sleep=480, print_error=False,
                                           show_plan_file=self.ai_params["EXPECT_LARGE_PLAN"],
                                           file_dir=self.ai_params["JENKINS_JOB_ID"],
                                           monitor_script_path=monitor_script_path):
            if self.ai_params["RETRY_PLAN"]:
                if self.ai_params["INSTALL_RUN_SECOND_SCRIPT"] != None:
                    local_path = "%s/%s" % (self.ai_params["AUTOINSTALL_DIR"], self.ai_params["INSTALL_RUN_SECOND_SCRIPT"])
                    remote_path = "/tmp/.%s/%s" % (self.ai_params["JENKINS_JOB_ID"], self.ai_params["INSTALL_RUN_SECOND_SCRIPT"])
                    print "Copy of %s to %s on %s" % (local_path, remote_path, self.ai_params["MS_IP"])
                    self.node.copy_file(local_path, remote_path)
                    cmd = "sh /tmp/.%s/%s /tmp/.%s/%s" % (self.ai_params["JENKINS_JOB_ID"], self.ai_params["INSTALL_RUN_SECOND_SCRIPT"], self.ai_params["JENKINS_JOB_ID"], self.ai_params["CLUSTER_FILE_NAME"])
                    stdout, stderr, retc = self.node.execute_expects(cmd, [], timeout_param=600)
                    if retc != 0:
                        print ">> ERROR: RUNNING OF DEPLOYMENT SCRIPT FAILED ON HOST"
                        return False

                # WORKAROUND FOR LITPCDS-6589
                print ">> WARNING: FAILED PLAN, PLEASE INVESTIGATE, PLAN WILL BE RE-CREATED AND RUN AGAIN"
                print "Sleeping 2 minutes before retry"
                time.sleep(120)

                cmd = "/usr/bin/litp create_plan"
                if not self.node.handle_run_command(cmd):
                    print ">> ERROR: PLAN COMMAND FAILED ON HOST"
                    return False

                if self.ai_params["EXPECT_LARGE_PLAN"]:
                    cmd = "/usr/bin/litp show_plan &>> /tmp/.{0}/retry_initial_litp_show_plan_{1}.txt".format(self.ai_params["JENKINS_JOB_ID"], time.strftime("%H%M%S"))
                    if not self.node.run_command(cmd):
                        print ">> ERROR: PLAN COMMAND FAILED ON HOST"
                cmd = "/usr/bin/litp show_plan"
                if not self.node.handle_run_command(cmd, expected_stdout=""):
                    print ">> ERROR: PLAN COMMAND FAILED ON HOST"
                    return False

                plan_start_time = time.time()
                cmd = "/usr/bin/litp run_plan"
                if not self.node.handle_run_command(cmd):
                    print ">> ERROR: RUN PLAN FAILED ON HOST"
                    return False

                if not self.node.waitfor_litp_plan(try_attempts, sleep_seconds, initial_sleep=480,
                                                   print_error=False,
                                                   show_plan_file=self.ai_params["EXPECT_LARGE_PLAN"],
                                                   file_dir=self.ai_params["JENKINS_JOB_ID"]):
                    # RUN AGAIN A THIRD TIME!! WORKAROUND FOR CLOUD PXE BOOT FAILURE
                    print ">> WARNING: FAILED PLAN, PLEASE INVESTIGATE, PLAN WILL BE RE-CREATED AND RUN AGAIN"
                    print "Sleeping 2 minutes before retry"
                    time.sleep(120)

                    cmd = "/usr/bin/litp create_plan"
                    if not self.node.handle_run_command(cmd):
                        print ">> ERROR: PLAN COMMAND FAILED ON HOST"
                        return False

                    if self.ai_params["EXPECT_LARGE_PLAN"]:
                        cmd = "/usr/bin/litp show_plan &>> /tmp/.{0}/retry_initial_litp_show_plan_{1}.txt".format(self.ai_params["JENKINS_JOB_ID"], time.strftime("%H%M%S"))
                        if not self.node.run_command(cmd):
                            print ">> ERROR: PLAN COMMAND FAILED ON HOST"
                        cmd = "/usr/bin/litp show_plan"
                    if not self.node.handle_run_command(cmd, expected_stdout=""):
                        print ">> ERROR: PLAN COMMAND FAILED ON HOST"
                        return False

                    plan_start_time = time.time()
                    cmd = "/usr/bin/litp run_plan"
                    if not self.node.handle_run_command(cmd):
                        print ">> ERROR: RUN PLAN FAILED ON HOST"
                        return False

                    if not self.node.waitfor_litp_plan(
                            try_attempts, sleep_seconds, initial_sleep=480,
                            show_plan_file=self.ai_params["EXPECT_LARGE_PLAN"],
                            file_dir=self.ai_params["JENKINS_JOB_ID"]):
                        return False
                    else:
                        print ">> INFO: Plan execution took {0:.0f} seconds"\
                              .format(time.time() - plan_start_time)
                else:
                    print ">> INFO: Plan execution took {0:.0f} seconds"\
                          .format(time.time() - plan_start_time)
            else:
                return False
        else:
            print ">> INFO: Plan execution took {0:.0f} seconds"\
                  .format(time.time() - plan_start_time)

        # REMOVE THE PLAN
        cmd = "/usr/bin/litp remove_plan"
        if not self.node.handle_run_command(cmd):
            print ">> ERROR: PLAN COMMAND FAILED ON HOST"
            return False

        # REMOVE AND CREATE NEW SNAPSHOTS FOR PEER NODES

        # ONLY REMOVE SNAPSHOT IF IT HAS BEEN CREATED
        if not self.ai_params["SKIP_INSTALL_SNAPSHOT"]:
            cmd = "/usr/bin/litp remove_snapshot"
            if not self.node.handle_run_command(cmd):
                print ">> ERROR: REMOVE SNAPSHOT COMMAND FAILED ON HOST"
                return False

            if not self.node.waitfor_litp_plan(60, 2):
                return False

        if not self.ai_params["SKIP_POST_DEPLOY_SNAPSHOT"]:
            cmd = "/usr/bin/litp create_snapshot"
            if not self.node.handle_run_command(cmd):
                print ">> ERROR: CREATE SNAPSHOT COMMAND FAILED ON HOST"
                return False

            if not self.node.waitfor_litp_plan(180, 2):
                return False

            cmd = "/usr/bin/litp remove_plan"
            if not self.node.handle_run_command(cmd):
                print ">> ERROR: CREATE SNAPSHOT COMMAND FAILED ON HOST"
                return False

        # MV AI FROM /TMP TO ANOTHER LOCATION FOR DEBUG PURPOSES
        cmd = "/bin/mv /tmp/.%s /home/litp-admin/" % self.ai_params["JENKINS_JOB_ID"]
        if not self.node.handle_run_command(cmd):
            print ">> ERROR: MOVING AI DIRECTORY FAILED"
            return False

        # Overwrite litpd_restart.sh - fix for TORF-498857
        self.node = NodeConnect(self.ai_params["MS_IP"], "root", constants.ROOT_MS_PASSWD)
        cmd = \
        """
        echo '#!/bin/bash
        if [[ ! $1 == ERIClitpmnlibvirt* ]] && [[ ! $1 == ERIClitpstory* ]] && [[ ! $1 == ERIClitpmock* ]] && [[ ! $1 == ERIClitpmcoagenttest* ]] && [[ ! $1 == ERIClitptorf* ]]; then
           /usr/bin/systemctl restart litpd.service
        fi' > /etc/yum/post-actions/litpd_restart.sh
        """
        if not self.node.handle_run_command(cmd):
            print ">> ERROR: Overwrite litpd_restart.sh failed"
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
