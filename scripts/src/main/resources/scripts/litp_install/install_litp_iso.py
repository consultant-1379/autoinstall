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
@summary:   Install LITP ISO
'''

import sys
import os
import time
from common_platform_files.common_methods import NodeConnect
import common_platform_files.constants as constants


class InstallLitpMs():
    """
    Class to install LITP MS ISO
    """
    def __init__(self, ai_params):
        """
        Initialise variables
        """

        self.ai_params = ai_params
        self.node = NodeConnect(self.ai_params["MS_IP"], "root", constants.ROOT_MS_PASSWD)

    def install_litp(self):
        """
        Install LITP on RHEL
        """

        print ""
        print "#########################################################"
        print ">> INFO: INSTALL LITP"
        print "#########################################################"
        print ""

        # CREATE AN AUTOINSTALL DIRECTORY ON THE NODE
        if not self.node.handle_run_command("mkdir /tmp/.%s" % self.ai_params["JENKINS_JOB_ID"]):
            print ">> ERROR: MKDIR FAILED ON HOST"
            return False

        if not self.node.handle_run_command("chmod 775 /tmp/.%s" % self.ai_params["JENKINS_JOB_ID"]):
            print ">> ERROR: CHANGING PERMISSIONS OF DIRECTORY FAILED ON HOST"
            return False

        # COPY UP THE LITP ISO TO THIS DIRECTORY

        local_path = "%s/%s" % (self.ai_params["AUTOINSTALL_DIR"], self.ai_params["ISO_FILE"])
        remote_path = "/tmp/.%s/%s" % (self.ai_params["JENKINS_JOB_ID"], self.ai_params["ISO_FILE"])
        print "Copy of %s to %s on %s" % (local_path, remote_path, self.ai_params["MS_IP"])
        self.node.copy_file(local_path, remote_path)


        # MOUNT THE LITP ISO

        cmd = "mkdir -p /media/litp/"
        if not self.node.handle_run_command(cmd):
            print ">> ERROR: MKDIR FAILED ON HOST"
            return False
        cmd = "/bin/mount /tmp/.%s/%s /media/litp/ -o loop" % (self.ai_params["JENKINS_JOB_ID"], self.ai_params["ISO_FILE"])
        if not self.node.handle_run_command(cmd, expected_stderr="not empty"):
            print ">> ERROR: MOUNT FAILED ON HOST"
            return False

        # RUN THE INSTALLER SCRIPT
        cmd = "sh /media/litp/install/installer.sh > " \
              "/tmp/.%s/iso_installer_output.log 2>&1" \
              % (self.ai_params["JENKINS_JOB_ID"])
        if not self.node.handle_run_command(cmd):
            self.node.run_command("/bin/cat /tmp/.%s/iso_installer_output.log" % self.ai_params["JENKINS_JOB_ID"])
            print ">> ERROR: RUNNING OF INSTALLER SCRIPT FAILED"
            return False

        self.node.run_command("/bin/rpm -qa > /tmp/.%s/installed_rpms_ms.log" % self.ai_params["JENKINS_JOB_ID"])

        cmd = "/bin/umount /tmp/.%s/%s" % (self.ai_params["JENKINS_JOB_ID"], self.ai_params["ISO_FILE"])
        if not self.node.handle_run_command(cmd):
            print ">> ERROR: UMOUNT FAILED ON HOST"
            return False

        cmd = "/bin/systemctl status litpd.service"
        stdout, stderr, retc = self.node.run_command(cmd)
        # TODO CHECK STDOUT
        if retc != 0:
            print ">> ERROR: LITPD SERVICE IS NOT RUNNING"
            return False

        if self.ai_params["MS_BLADE_TYPE"] == "cloud":

            # Install cloud redfish tool
            local_path = self.ai_params["REDFISH_TOOL_LOCATION"]
            local_path1 = self.ai_params["REDFISH_TOOL_LOCATION"].split("/")
            rpm_name = local_path1[-1]
            remote_path = "/tmp/.%s/%s" % (self.ai_params["JENKINS_JOB_ID"], rpm_name)
            print "Copy of %s to %s on %s" % (local_path, remote_path, self.ai_params["MS_IP"])
            self.node.copy_file(local_path, remote_path)
            cmd = "/usr/bin/yum localinstall -y %s" % remote_path
            stdout, stderr, retc = self.node.run_command(cmd)
            if retc != 0:
                print ">> ERROR: Install of redfish tool failed..."
                return False

            # Copy RHEL7 ipmi tool to expected location
            # This is just temporary - RHEL7 will use redfish
            cmd = "cp /software/ipmitool.cloud /opt/ericsson/nms/litp/bin/"
            stdout, stderr, retc = self.node.run_command(cmd)
            if retc != 0:
                print ">> ERROR: Copy of RHEL7 impitool failed"
                return False

            # Copy ssl.py
            cmd = "\cp /software/ssl.py /usr/lib64/python2.7/ssl.py"
            stdout, stderr, retc = self.node.run_command(cmd)
            if retc != 0:
                print ">> ERROR: Copy of ssl.py failed"
                return False

            # Restart celery
            cmd = "/bin/systemctl restart celery"
            stdout, stderr, retc = self.node.run_command(cmd)
            if retc != 0:
                print ">> ERROR: Restart of celery failed"
                return False

            # Restart litpd
            cmd = "/bin/systemctl restart litpd.service"
            stdout, stderr, retc = self.node.run_command(cmd)
            if retc != 0:
                print ">> ERROR: Restart of litpd.service failed"
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

    run = InstallLitpMs(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5])
    run.install_litp()

if  __name__ == '__main__':main()
