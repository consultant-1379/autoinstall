#!/usr/bin/env python

"""
COPYRIGHT Ericsson 2019
The copyright to the computer program(s) herein is the property of
Ericsson Inc. The programs may be used and/or copied only with written
permission from Ericsson Inc. or in accordance with the terms and
conditions stipulated in the agreement/contract under which the
program(s) have been supplied.

@since:     October 2012
@author:    Brian Kelly
@summary:   Set up user
"""

import sys
import os
import time
from common_platform_files.common_methods import NodeConnect
import common_platform_files.constants as constants


class LITPMsUserUpdate():
    """
    Class to complete litp setup by updating user previlages
    """
    def __init__(self, ai_params):
        """
        Initialise variables
        """

        self.ai_params = ai_params
        self.node = NodeConnect(self.ai_params["MS_IP"], "root", constants.ROOT_MS_PASSWD)

    def update_users(self):
        """
        Update litp user privilages
        """

        print ""
        print "#########################################################"
        print ">> INFO: USER SETUP"
        print "#########################################################"
        print ""

        # SET UP litp-admin as a litp user
        cmd = "/usr/sbin/usermod -a -G litp-access {0}".format(constants.LITP_USER)
        if not self.node.handle_run_command(cmd):
            print ">> ERROR: COULD NOT ADD USER TO litp-access GROUP. FAILED TO SET LITP TRUST AUTHENTICATION."
            return False

        cmd = "/usr/bin/passwd --stdin %s <<< '%s'" % (constants.LITP_USER, constants.LITP_USER_MS_PASSWD)
        stdout, stderr, retc = self.node.run_command(cmd)
        if stderr != [] or retc != 0:
            print ">> ERROR: PASSWORD UPDATE FAILED ON HOST"
            return False

        # UPDATE IPTABLES
        cmd = "/sbin/iptables -F FORWARD"
        if not self.node.handle_run_command(cmd):
            print ">> ERROR: IPTABLES UPDATE FAILED ON HOST"
            return False
        cmd = "/sbin/service iptables save"
        stdout, stderr, retc = self.node.run_command(cmd)
        if stderr != [] or retc != 0:
            print ">> ERROR: IPTABLES SAVE FAILED ON HOST"
            return False

        # SET LITP LOGGING TO DEBUG
        cmd = "litp update -p /litp/logging -o force_debug=true"
        if not self.node.handle_run_command(cmd):
            print ">> WARNING: TURN ON LITP DEBUG FAILED ON HOST"

        # NOW LITP USER IS SETUP, CHANGE THE OWNERSHIP OF AUTOINSTALL FILE, REST OF INSTALL WILL BE LITP USER
        cmd = "/bin/chown %s:%s /tmp/.%s" % (constants.LITP_USER, constants.LITP_USER, self.ai_params["JENKINS_JOB_ID"])
        if not self.node.handle_run_command(cmd):
            print ">> ERROR: CHANGING OWNERSHIP OF DIRECTORY FAILED"
            return False

        self.node = NodeConnect(self.ai_params["MS_IP"], constants.LITP_USER, constants.LITP_USER_MS_PASSWD)
        cmd = "/bin/systemctl status litpd.service"
        stdout, stderr, retc = self.node.run_command(cmd)
        if retc != 0:
            print ">> ERROR: LITPD SERVICE IS NOT RUNNING"
            return False

        # IF OS PATCHES OPTION CHOSEN, UPDATE THEM
        if self.ai_params["OS_PATCHES"]:
            print ""
            print "#########################################################"
            print ">> INFO: APPLY OS PATCHES ON MS"
            print "#########################################################"
            print ""
            print "OS PATCHES: %s" % self.ai_params["OS_PATCHES_PATH"]
            print ""

            hostname_ms = self.ai_params["MS_HOSTNAME"].split(".")[0]
            cmd = "litp update -p /ms -o hostname=%s" % hostname_ms
            if not self.node.handle_run_command(cmd):
                print ">> ERROR: RUN LITP UPDATE FAILED ON HOST"
                return False

            cmd = "/usr/bin/litp create_snapshot"
            if not self.node.handle_run_command(cmd):
                print ">> ERROR: RUN CREATE SNAPSHOT FAILED ON HOST"
                return False

            if not self.node.waitfor_litp_plan(50, 2):
                return False

            local_path = self.ai_params["OS_PATCHES_PATH"]
            pathfile = self.ai_params["OS_PATCHES_PATH"].split("/")
            filepath = pathfile[-1]
            remote_path = "/tmp/.%s/%s" % (self.ai_params["JENKINS_JOB_ID"], filepath)
            if "http" in self.ai_params["OS_PATCHES_PATH"]:

                cmd = 'curl %s --head -k -s -S | grep "HTTP/"' % self.ai_params["OS_PATCHES_PATH"]

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
                    cmd = 'wget -q -O - --no-check-certificate "%s" -O %s' % (self.ai_params["OS_PATCHES_PATH"], remote_path)
                    retry_count = 0
                    while True:
                        if self.node.handle_run_command(cmd):
                            break

                        retry_count += 1
                        if retry_count == 5:
                            print ">> ERROR: COPY OF FILE OVER WGET TO MS FAILED"
                            return False

                        print ">> WARNING: WGET FAILED, Retrying"
                        time.sleep(5)

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
                        gw_remote_path = "{0}/{1}".format(self.ai_params["SERVER_HTTP_LOCATION_PATH"], filepath)

                    retry_count = 0
                    cmd = 'wget -q -O - --no-check-certificate "%s" -O %s' % (self.ai_params["OS_PATCHES_PATH"], gw_remote_path)
                    while True:

                        _, _, ret_c = self.node.run_command_local(cmd)
                        if ret_c == 0:
                            break

                        retry_count += 1
                        if retry_count == 5:
                            print ">> ERROR: COPY OF FILE OVER WGET TO GW FAILED"
                            return False

                        print ">> WARNING: WGET FAILED, Retrying"
                        time.sleep(5)

                    # If this is a vApp then make symbolic link to patches
                    if is_vapp:
                        cmd = "ln -s /export/data/{0} /var/www/html/{0}".format(filepath)
                        _, _, ret_c = self.node.run_command_local(cmd)
                        if ret_c != 0:
                            print ">> ERROR: COULD NOT CREATE SYMLINK TO PATCHES."
                            return False

                    # Step 2: Copy the patches from the GW to the MS
                    retry_count = 0
                    cmd = 'wget -q -O - --no-check-certificate "{0}/{1}" -O {2}'.format(self.ai_params["SERVER_HTTP_LOCATION"], filepath, remote_path)
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
                    print ">> ERROR: CANNOT ACCESS OS PATCHES PATH PROVIDED: {0}".format(self.ai_params["OS_PATCHES_PATH"])
                    return False

            else:
                # COPY THE OS PATCHES ACROSS TO THE MS
                print "Copy of %s to %s on %s" % (local_path, remote_path, self.ai_params["MS_IP"])
                self.node.copy_file(local_path, remote_path)

            # HAS TO BE PERFORMED AS ROOT
            self.node = NodeConnect(self.ai_params["MS_IP"], "root", constants.ROOT_MS_PASSWD)

            # TEST IF PATCHES ARE ISO OR TARBALL
            if ".iso" in self.ai_params["OS_PATCHES_PATH"]:

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
                cmd = "/bin/tar -C /tmp/.%s/ -xvzf %s >/tmp/rhel_patches_out.txt 2>&1" % (self.ai_params["JENKINS_JOB_ID"], remote_path)
                if not self.node.handle_run_command(cmd):
                    print ">> ERROR: UNTAR FAILED ON HOST"
                    return False

                cmd = "mv /tmp/rhel_patches_out.txt /tmp/.%s/" % self.ai_params["JENKINS_JOB_ID"]
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
            stdout, stderr, retc = self.node.run_command(cmd)

            if retc != 0:
                print ">> ERROR: YUM DID NOT RUN CORRECTLY"
                return False

            # REBOOT THE NODE
            cmd = "shutdown -r +1"
            stdout, stderr, retc = self.node.run_command(cmd)
            if retc != 0:
                print ">> ERROR: REBOOT OF NODE WAS UNSUCCESSFUL"
                return False

            if self.ai_params["MS_BLADE_TYPE"] == "DL380-G9":
                print "Sleeping for 15 minutes to allow reboot to occur..."
                time.sleep(900)
            elif self.ai_params["MS_BLADE_TYPE"] == "G9":
                print "Sleeping for 15 minutes to allow reboot to occur..."
                time.sleep(900)
            else:
                print "Sleeping for 15 minutes to allow reboot to occur..."
                time.sleep(900)

            self.node = NodeConnect(self.ai_params["MS_IP"], constants.LITP_USER, constants.LITP_USER_MS_PASSWD)

            cmd = "/usr/bin/litp remove_snapshot"
            if not self.node.handle_run_command(cmd):
                print ">> ERROR: RUN CREATE SNAPSHOT FAILED ON HOST"
                return False

            # NOW MONITOR THE PLA RUN FROM REMOVE SNAPSHOT
            if not self.node.waitfor_litp_plan(50, 2):
                return False

            cmd = "litp update -p /litp/logging -o force_debug=true"
            if not self.node.handle_run_command(cmd):
                print ">> WARNING: TURN ON LITP DEBUG FAILED ON HOST"

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
    if len(sys.argv) != 3:
        print ">> ERROR: Not all required arguments supplied: %s" % sys.argv
        return False

    run = LITPMsUserUpdate(sys.argv[1])
    run.update_users()

if  __name__ == '__main__':main()
