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


Different keyboard steps:

Esc:        \x1b
Tab:        \t
Enter:      \r
Up Key:     \x1b[A
Down Key:   \x1b[B
'''

import sys
import os
from common_platform_files.common_methods import NodeConnect
import common_platform_files.constants as constants
import time
import datetime
from common_platform_files.SystemHPiLO import SystemHPiLO
#import subproccess
import socket

# GLOBAL VARIABLES
KS_FILE_STATIC = 'http://10.44.235.150/iso/litp/6.6_ks/ms-ks-network.cfg'

class InsertIso():
    """
    CLASS TO INSERT ISO TO BLADE
    """
    def __init__(self, ai_params):
        """
        Initialise variables
        """

        #self.node = NodeConnect(ilo_ip, constants.ILO_USER, constants.ILO_PASSWD)
        ##Passing False to turn off ssh key checking
        self.ai_params = ai_params
        self.node = NodeConnect(self.ai_params["MS_ILO_IP"], self.ai_params["MS_ILO_USER"], self.ai_params["MS_ILO_PASSWORD"], False)


    def insert_iso(self):
        """
        INSERT THE ISO
        """

        print ""
        print "#########################################################"
        print ">> INFO: INSERT ISO"
        print "#########################################################"
        print ""
        print "ILO_IP: %s" % self.ai_params["MS_ILO_IP"]
        print ""

        # INCOMPLETE!!! NEEDS TO CHECK OUTPUTS FOR DIFFERENT TYPE NODES

        self.node.run_command("vm cdrom insert %s" % self.ai_params["RHEL_ISO"])
        self.node.run_command("vm cdrom set boot_once")
        self.node.run_command("vm cdrom get")
        self.node.run_command("power reset")
        return True


class InstallIso():
    """
    Class to install a RHEL ISO with a LITP Kickstart
    """
    def __init__(self, ai_params):
        """
        Initialise variables
        """

        #self.node = NodeConnect(ilo_ip, constants.ILO_USER, constants.ILO_PASSWD,

        #Pass False so we don't use SSH keys to authenticate
        self.ai_params = ai_params
        self.node = NodeConnect(self.ai_params["MS_ILO_IP"], self.ai_params["MS_ILO_USER"], self.ai_params["MS_ILO_PASSWORD"], False)
        self.timeout = None
        if self.ai_params["MS_BLADE_TYPE"] == "G8":
            self.timeout = {
                "ISOLINUX": 250,
                "boot prompt": 25,
                "running install": 800,
                "Networking Device": 1000,
                "Configure TCP/IP": 800,
                "Manual TCP/IP": 800,
                "Keyboard": 800,
                "Time Zone": 800,
                "Partitioning Type": 600,
                "Formatting": 100,
                "Installation Progress": 300,
                "Installation Starting": 300,
                "Package Installation": 300,
                "Post-Installation": 2700,
                "Hostname": 9600,
                "rebooting system": 4500,
                "ms1 login": 1200,
                "cmd respond": 15
            }
        if self.ai_params["MS_BLADE_TYPE"] == "G9":
            self.timeout = {
                "ISOLINUX": 350,
                "boot prompt": 25,
                "running install": 800,
                "Networking Device": 1000,
                "Configure TCP/IP": 800,
                "Manual TCP/IP": 800,
                "Keyboard": 800,
                "Time Zone": 800,
                "Partitioning Type": 600,
                "Formatting": 100,
                "Installation Progress": 300,
                "Installation Starting": 300,
                "Package Installation": 300,
                "Post-Installation": 2700,
                "Hostname": 9600,
                "rebooting system": 4500,
                "ms1 login": 1200,
                "cmd respond": 15
            }
        if self.ai_params["MS_BLADE_TYPE"] == "DL380" or self.ai_params["MS_BLADE_TYPE"] == "DL380-G5" or self.ai_params["MS_BLADE_TYPE"] == "DL380-G9":
            self.timeout = {
                "ISOLINUX": 400,
                "boot prompt": 600,
                "running install": 1000,
                "Networking Device": 1400,
                "Configure TCP/IP": 1100,
                "Manual TCP/IP": 1200,
                "Keyboard": 1100,
                "Time Zone": 1100,
                "Partitioning Type": 1200,
                "Formatting": 200,
                "Installation Progress": 500,
                "Installation Starting": 500,
                "Package Installation": 500,
                "Post-Installation": 5400,
                "Hostname": 9600,
                "rebooting system": 6000,
                "ms1 login": 2400,
                "cmd respond": 25
            }

        if self.timeout is None:
            print "Blade type passed through is not supported, Default set:"
            self.timeout = {
                "ISOLINUX": 400,
                "boot prompt": 600,
                "running install": 1000,
                "Networking Device": 1400,
                "Configure TCP/IP": 1100,
                "Manual TCP/IP": 1200,
                "Keyboard": 1100,
                "Time Zone": 1100,
                "Partitioning Type": 1200,
                "Formatting": 200,
                "Installation Progress": 500,
                "Installation Starting": 500,
                "Package Installation": 500,
                "Post-Installation": 5400,
                "Hostname": 9600,
                "rebooting system": 6000,
                "ms1 login": 2400,
                "cmd respond": 25
            }
        self.ilo = None
        self.vsp_shell = None
        stdout, _, _ = self.node.run_command_local("/bin/ipcalc -m %s" % self.ai_params["MS_SUBNET"], logs=False)
        self.mask = stdout[0].replace("NETMASK=", "")
        if len(self.ai_params["MS_VLAN"]) == 0 and self.ai_params["MS_BLADE_TYPE"] == "DL380-G5":
            self.node.run_command_local("sed -i s/ondrive=sda/ondrive=\\\/dev\\\/cciss\\\/c0d0/g  %s" % self.ai_params["KS_FILE_PATH"], logs=True)
            #self.node.run_command_local("sed -i s/drives=sda/drives=\\\/dev\\\/cciss\\\/c0d0/g %s" % self.ai_params["KS_FILE_PATH"], logs=True)

        ##In new redhat 6.6 the the dublin timezone in listed one position lower than previous redhat
        self.tz_count = 39

        if 'rhel-server-6.6' in self.ai_params["RHEL_ISO"]:
            self.tz_count = 40

        #If we reset the ilo and rerun the install we set this to True so
        #we don't get caught in an infinite loop.
        self.ilo_reset = False

    def check_output_reset_ilo(self, wanted_output):
        """
        This will automatically reset the ilo if a problem is found and then
        restart autoinstall.
        If it is not a suspected ilo issue it will fail the build.
        """

        if self.ilo_reset:
            print "#########################################################"
            print "ERROR: Aborting install. Ilo restart already attempted but has " +\
                "not fixed the problem"
            print "#########################################################"
            exit(1)

        print "#########################################################"
        print "WARNING: ILO Problem detected - Resetting ILO"
        print "#########################################################"
        self.node.run_command('reset /map1')
        print "Waiting 2 minutes for ilo reset to complete"
        time.sleep(120)
        print "#########################################################"
        print "Restarting install"
        print "#########################################################"
        self.ilo_reset = True
        self.ai_params["KS_FILE"] = KS_FILE_STATIC

    def wait_for_output(self, wanted_output, time_out, dev_status_response=True, resend='', print_ok=False, fail_on_timeout=True):
        """
        Method to wait for ILO output
        """

        count = 0
        time_count = 0
        self.vsp_shell.settimeout(1)
        output = ''
        message = ''
        while output.find(wanted_output) == -1:
            try:
                time_count += 1
                if time_count > time_out:
                    if fail_on_timeout:
                        print ""
                        print 'Failed waiting for expected output: %s' % wanted_output
                        print 'Waited: %s' % str(time_count)
                        print ""
                        print '--------------------------------------------------'
                        print "Messages:"
                        print '--------------------------------------------------'
                        print message
                        print '--------------------------------------------------'
                        print "Output:"
                        print '--------------------------------------------------'
                        print output
                        print '--------------------------------------------------'
                        self.check_output_reset_ilo(wanted_output)
                        return False
                    else:
                        print "Timeout! Continuing anyway..."
                        return True
                response = self.vsp_shell.recv(99999)
                if response.find('\x1b[5n') > -1 and dev_status_response:
                    #print '----  wait_for_output(' + wanted_output + ') - Received Device Status Request...  Responding'
                    self.vsp_shell.send('\x1b[0n')
                if resend != '':
                    message += '#' + str(count) + 'Resending: ' + resend
                    self.vsp_shell.send(resend)
                #print "----> Expected: {0}, Received: {1}.".format(str(wanted_output), str(response))
                output += response
                time.sleep(1)
            except socket.timeout:
                count += 1
                if count > time_out:
                    if fail_on_timeout:
                        print ""
                        print 'Failed waiting for expected output: %s' % wanted_output
                        print 'Waited: %s' % str(time_count)
                        print ""
                        print '--------------------------------------------------'
                        print "Messages:"
                        print '--------------------------------------------------'
                        print message
                        print '--------------------------------------------------'
                        print "Output:"
                        print '--------------------------------------------------'
                        print output
                        print '--------------------------------------------------'
                        self.check_output_reset_ilo(wanted_output)
                        return False
                    else:
                        print "Timeout! Continuing anyway..."
                        return True
            except:
                print ""
                print 'Unknown Exception while waiting for output'
                print ""
                exit(1)
        #print '----> Found: "' + wanted_output + '" , count = ' + str(count) + ' -------------------------'
        if print_ok == True:
            print ''
            print "Expected output: %s" % wanted_output
            print "Found after time: %s" % str(count)
            print '--------------------------------------------------'
            print "Output:"
            print '--------------------------------------------------'
            print output
            print '--------------------------------------------------'
            print

        return True

    def slow_send_vsp(self, string_to_send, wait_time):
        """
        This is required to send stuff to "boot:" prompt as it can't take a big string all at once
        """
        #print '\n----> SlowSending "' + string_to_send + '"'
        for con in string_to_send:
            self.vsp_shell.send(con)
            time.sleep(wait_time)
        return

    def send_key_press(self, to_send, printable, wait_time):
        """
        After waiting 'waitTime' seconds send the 'toSend' string and print 'printable' to the log
        """
        time.sleep(wait_time)
        #print '\n----> Sending "' + printable + '"'
        self.vsp_shell.send(to_send)
        return

    def run_vsp_install(self):
        """
        method that does the RHEL install and interaction with ILO using VSP
        Assumption is the ISO is attached to the ILO and the blade has been rebooted
        to install from cdrom
        """

        print ""
        print "#########################################################"
        print ">> INFO: INSTALL ISO"
        print "#########################################################"
        print ""

        print "MS IP: %s" % self.ai_params["MS_IP"]
        print "MS MASK: %s" % self.mask
        print "MS GATEWAY: %s" % self.ai_params["MS_GATEWAY"]
        print "KICKSTART FILE: %s" % self.ai_params["KS_FILE"]
        print "BLADE TYPE IS: %s" % self.ai_params["MS_BLADE_TYPE"]

        # MAKE CONNECTION TO THE GIVEN ILO
        if self.ai_params["MS_BLADE_TYPE"] == "G9" or \
                self.ai_params["MS_BLADE_TYPE"] == "DL380-G9":
            time.sleep(70)
        self.ilo = SystemHPiLO()
        self.ilo.setHost(self.ai_params["MS_ILO_IP"])
        self.ilo.setUser(self.ai_params["MS_ILO_USER"])
        self.ilo.setPassword(self.ai_params["MS_ILO_PASSWORD"])
        #self.ilo.setUser(constants.ILO_USER)
        #self.ilo.setPassword(constants.ILO_PASSWD)

        # TRY 10 times TO CONNECT TO VSP SESSION

        max_tries = 10
        for num in range(0, max_tries):

            print 'Connecting to VSP Console via ILO %s' % self.ai_params["MS_ILO_IP"]
            self.vsp_shell = self.ilo.getVSPShell()

            if self.vsp_shell != None:
                break
            else:
                print '>> ERROR: VSP shell connect #%d / %d failed' % (num + 1, max_tries)
                print ""
                print 'ACTION: Restarting node ' + self.ai_params["MS_ILO_IP"] + ' to retry VSP connect...'
                print ""
                self.ilo.iLOPowerReset()
                self.ilo.closeShell()

        if self.vsp_shell == None:
            print '>> ERROR: All attempts to connect to VSP shell failed'
            return False

        # ASSUMING THE RHEL HAS BEEN ATTACHED TO THE ILO AND THE NODE HAS BEEN REBOOTED
        # MIMICS THE MANUAL INSTALL PROCESS
        print "Waiting for grub menu...."
        # WORKAROUND FOR G9, "ISOLINUX" DOES NOT APPEAR IN THE CONSOLE
        if self.ai_params["MS_BLADE_TYPE"] == "G9" or self.ai_params["MS_BLADE_TYPE"] == "DL380-G9":
            self.wait_for_output('Attempting Boot From', self.timeout["ISOLINUX"])
            time.sleep(20)
        else:
            self.wait_for_output('ISOLINUX', self.timeout["ISOLINUX"])

        print "Grub menu found, Esc entered to enter grub CLI"
        self.vsp_shell.send('\x1b')
        self.wait_for_output(':', self.timeout["boot prompt"], True, '\x1b')
        time.sleep(20)
        # FOLLOWING WILL NEED UPDATING AS IT IS DIFFERENT FOR DIFFERENT BLADES
        if self.ai_params["MS_BLADE_TYPE"] == "G8" or self.ai_params["MS_BLADE_TYPE"] == "G9":
            boot_cmd = "vmlinuz initrd=initrd.img ks=%s asknetwork text serial" % self.ai_params["KS_FILE"]
        else:
            if len(self.ai_params["MS_VLAN"]) > 0:
                boot_cmd = "vmlinuz initrd=initrd.img ksdevice=%s ip=%s netmask=%s gateway=%s ifname=%s:%s vlanid=%s ks=%s text console=ttyS1 serial" % (self.ai_params["MS_INSTALL_NIC"], self.ai_params["MS_IP"], self.mask, self.ai_params["MS_GATEWAY"], self.ai_params["MS_INSTALL_NIC"], self.ai_params["MS_INSTALL_MAC_ADDRESS"], self.ai_params["MS_VLAN"], self.ai_params["KS_FILE"])
            else:
                boot_cmd = "vmlinuz initrd=initrd.img ksdevice=%s ip=%s netmask=%s gateway=%s ifname=%s:%s ks=%s text console=ttyS1 serial" % (self.ai_params["MS_INSTALL_NIC"], self.ai_params["MS_IP"], self.mask, self.ai_params["MS_GATEWAY"], self.ai_params["MS_INSTALL_NIC"], self.ai_params["MS_INSTALL_MAC_ADDRESS"], self.ai_params["KS_FILE"])
        print "Entering boot command for kickstart: %s" % boot_cmd
        self.slow_send_vsp(boot_cmd, 0.5)
        self.vsp_shell.send("\r")
        if self.ai_params["MS_BLADE_TYPE"] == "G8" or self.ai_params["MS_BLADE_TYPE"] == "G9":

            if not self.wait_for_output('Networking Device', self.timeout["Networking Device"]):
                return False

            print "Configuring network to %s" % self.ai_params["MS_INSTALL_NIC"]
            nic_count = None
            if self.ai_params["MS_INSTALL_NIC"] == "eth0":
                nic_count = 0
            if self.ai_params["MS_INSTALL_NIC"] == "eth1":
                nic_count = 1
            if self.ai_params["MS_INSTALL_NIC"] == "eth2":
                nic_count = 2
            if self.ai_params["MS_INSTALL_NIC"] == "eth3":
                nic_count = 3
            if self.ai_params["MS_INSTALL_NIC"] == "eth4":
                nic_count = 4
            if self.ai_params["MS_INSTALL_NIC"] == "eth5":
                nic_count = 5
            if self.ai_params["MS_INSTALL_NIC"] == "eth6":
                nic_count = 6
            if self.ai_params["MS_INSTALL_NIC"] == "eth7":
                nic_count = 7
            if self.ai_params["MS_INSTALL_NIC"] == "eth8":
                nic_count = 8
            if self.ai_params["MS_INSTALL_NIC"] == "eth9":
                nic_count = 9
            # GO UP TO THE TOP NIC IN THE LIST
            for num in range(0, 10):
                self.send_key_press('\x1b[A', 'UP_ARROW_KEY for %s !!!' % self.ai_params["MS_INSTALL_NIC"], 1)
            # NOW GO DOWN TO THE REQUIRED NIC IN THE LIST
            for num in range(0, nic_count):
                self.send_key_press('\x1b[B', 'UP_ARROW_KEY for %s !!!' % self.ai_params["MS_INSTALL_NIC"], 1)
            # FUTURE STEP TO SELECT ETH DEVICE
            #self.send_key_press('\x1b[A', 'UP_ARROW_KEY for eth1 !!!', 1)
            self.send_key_press('\t', 'TAB', 0.5)
            self.send_key_press('\r', 'ENTER', 0.5)
            self.wait_for_output('Configure TCP/IP', self.timeout["Configure TCP/IP"])
            self.send_key_press('\t', 'TAB', 1)
            self.send_key_press('\t', 'TAB', 1)
            self.send_key_press('\x20', 'SPACE', 1)
            self.send_key_press('\t', 'TAB', 1)
            self.send_key_press('\t', 'TAB', 1)
            self.send_key_press('\t', 'TAB', 1)
            self.send_key_press('\t', 'TAB', 1)
            self.send_key_press('\t', 'TAB', 1)
            self.send_key_press('\r', 'ENTER', 1)
            self.wait_for_output('Manual TCP/IP Configuration', self.timeout["Manual TCP/IP"])
            print "Setting MS ip to %s" % self.ai_params["MS_IP"]
            self.slow_send_vsp(self.ai_params["MS_IP"], 0.5)
            self.send_key_press('\t', 'TAB', 1)
            print "Setting MS mask to %s" % self.mask
            self.slow_send_vsp(self.mask, 0.5)
            self.send_key_press('\t', 'TAB', 1)
            print "Setting MS gateway to %s" % self.ai_params["MS_GATEWAY"]
            self.slow_send_vsp(self.ai_params["MS_GATEWAY"], 0.5)
            self.send_key_press('\t', 'TAB', 1)
            self.send_key_press('\t', 'TAB', 1)
            self.send_key_press('\r', 'ENTER', 1)
            if not self.wait_for_output('Language Selection', time_out=180):
                return False
        else:
            if not self.wait_for_output('Language Selection', time_out=700):
                return False

        print "Selecting Language"
        self.send_key_press('\r', 'ENTER', 1)
        self.wait_for_output('Time Zone Selection', self.timeout["Time Zone"])
        print "Selecting timezone: Europe/Dublin"
        self.send_key_press('\x20', 'SPACE', 1)
        self.send_key_press('\t', 'TAB', 1)
        self.send_key_press('E', 'E', 1)
        for num in range(0, self.tz_count):
            self.send_key_press('\x1b[B', 'DOWN_ARROW_KEY for Europe/Dublin !!!', 1)
        self.send_key_press('\t', 'TAB', 1)
        self.send_key_press('\r', 'ENTER', 1)
        self.wait_for_output('Installation Starting', self.timeout["Installation Starting"])
        print "Installation starting..."
        self.wait_for_output('Package Installation', self.timeout["Package Installation"])
        print "Packages installing..."
        self.wait_for_output('Post-Installation', self.timeout["Post-Installation"])
        print "Post-Installation..."
        self.wait_for_output('hostname:', self.timeout["Hostname"])
        print "Entering hostname: %s" % self.ai_params["MS_HOSTNAME"]
        self.slow_send_vsp(self.ai_params["MS_HOSTNAME"], 0.5)
        self.send_key_press('\r', 'ENTER', 1)
        self.wait_for_output('Is this correct', time_out=30)
        self.slow_send_vsp("y", 0.5)
        self.send_key_press('\r', 'ENTER', 1)
        self.wait_for_output('rebooting system', self.timeout["rebooting system"], fail_on_timeout=False)
        print "System rebooting"

        # NOW DISCONNECT AND LET NODE REBOOT, LEAVING % MINUTES FOR IT TO REBOOT

        self.ilo.closeShell()
        print "Sleeping for 5 minutes to allow reboot to occur..."
        time.sleep(300)

        # RECONNECT

        self.ilo = SystemHPiLO()
        self.ilo.setHost(self.ai_params["MS_ILO_IP"])
        self.ilo.setUser(self.ai_params["MS_ILO_USER"])
        self.ilo.setPassword(self.ai_params["MS_ILO_PASSWORD"])
        #self.ilo.setUser(constants.ILO_USER)
        #self.ilo.setPassword(constants.ILO_PASSWD)
        max_tries = 10
        for num in range(0, max_tries):

            print 'Connecting to VSP Console via ILO...'
            self.vsp_shell = self.ilo.getVSPShell()

            if self.vsp_shell != None:
                break
            else:
                print '>> ERROR: VSP shell connect #%d / %d failed' % (num + 1, max_tries)
                print ""
                print 'ACTION: Restarting node ' + self.ai_params["MS_ILO_IP"] + ' to retry VSP connect...'
                print ""
                self.ilo.iLOPowerReset()
                self.ilo.closeShell()

        if self.vsp_shell == None:
            print '>> ERROR: All attempts to connect to VSP shell failed'
            return False

        # UPDATE ROOT DEFAULT PASSWORD CREDENTIALS AND SETUP NETWORKING FOR NODE SSH ACCESS

        print "Updating MS password..."
        fqdn_hostn = self.ai_params["MS_HOSTNAME"].split(".")
        fqdn_host = fqdn_hostn[0]
        self.wait_for_output('%s login:' % fqdn_host, self.timeout["ms1 login"])
        self.slow_send_vsp('root', 0.2)
        self.send_key_press('\r', 'ENTER', 0.5)
        self.wait_for_output('Password:', self.timeout["cmd respond"])
        self.slow_send_vsp(constants.MS_DEFAULT_PASSWD, 0.2)
        self.send_key_press('\r', 'ENTER', 0.5)
        self.wait_for_output('(current) UNIX password:', self.timeout["cmd respond"])
        self.slow_send_vsp(constants.MS_DEFAULT_PASSWD, 0.2)
        self.send_key_press('\r', 'ENTER', 0.5)
        self.wait_for_output('New password:', self.timeout["cmd respond"])
        self.slow_send_vsp(constants.ROOT_MS_PASSWD, 0.2)
        self.send_key_press('\r', 'ENTER', 0.5)
        self.wait_for_output('Retype new password:', self.timeout["cmd respond"])
        self.slow_send_vsp(constants.ROOT_MS_PASSWD, 0.2)
        self.send_key_press('\r', 'ENTER', 0.5)
        print "MS password for root updated"
        #self.wait_for_output('%s login:' % self.ai_params["MS_HOSTNAME"], self.timeout["ms1 login"])
        self.wait_for_output('[root@%s ~]#' % fqdn_host, self.timeout["cmd respond"])
        if self.ai_params["MS_BLADE_TYPE"] == "G8" or self.ai_params["MS_BLADE_TYPE"] == "G9":
            print "Updating network connection on %s, setting BOOTPROTO=static" % self.ai_params["MS_INSTALL_NIC"]
            cmd = "/bin/sed -i 's/^BOOTPROTO=.*$/BOOTPROTO=\"static\"/ig' '/etc/sysconfig/network-scripts/ifcfg-%s'" % self.ai_params["MS_INSTALL_NIC"]
            self.slow_send_vsp(cmd, 0.5)
            self.send_key_press('\r', 'ENTER', 0.5)
            self.slow_send_vsp("service network restart", 0.5)
            self.send_key_press('\r', 'ENTER', 0.5)
        self.ilo.closeShell()
        time.sleep(5)
        return True

        #self.slow_send_vsp("y", 0.1)
        #self.wait_for_output()
        #self.send_key_press()
        #self.vsp_shell.send("")


def main():
    """
    main function
    """

    if len(sys.argv) != 13:
        if len(sys.argv) != 14:
            print ">> ERROR: Not all required arguments supplied: %s" % sys.argv
            return False

    # Disable output buffering to receive the output instantly
    sys.stdout = os.fdopen(sys.stdout.fileno(), "w", 0)
    sys.stderr = os.fdopen(sys.stderr.fileno(), "w", 0)
    if len(sys.argv) == 13:
        run = InstallIso(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6], sys.argv[7], "DEFAULT")
    if len(sys.argv) == 14:
        run = InstallIso(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6], sys.argv[7], sys.argv[8])
    run.run_vsp_install()

if  __name__ == '__main__': main()
