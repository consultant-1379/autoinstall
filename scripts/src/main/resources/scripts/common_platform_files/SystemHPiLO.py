#!/usr/bin/env python

#------------------------------------------------------------------------------
'''
Name:        SystemHPiLO
Description:

@author:     rossa.o'brien

Created:     11/09/2011
'''
#------------------------------------------------------------------------------

from iLOSSHSocket import SSHSocket
import time
import socket
#from litp_common.logger.litp_log import getLITPLogger


class SystemHPiLO:
    """
        This class provides an API to run iLO commands over SSH to the HP
        iLO interface.
    """

    def __init__(self):
        self.host = ''
        self.username = ''
        self.password = ''
        self.iLOConnection = None
        self.testMode = False
        #self.logger = getLITPLogger('SystemHPiLO')
        #self.logger.debug('Instantiate %s' % repr(self))
        self.ilo_version = 2

    def setHost(self, host):
        self.host = host

    def setUser(self, username):
        self.username = username

    def setPassword(self, password):
        self.password = password

    def _sshConnect(self):
        s = SSHSocket()
        s.setHost(self.host)
        s.setUser(self.username)
        s.setPasswd(self.password)
        if s.connect():
            self.iLOConnection = s
        else:
            self.iLOConnection = None

    def getVersion(self):
        if self.iLOConnection == None:
            self._sshConnect()
            if self.iLOConnection == None:
                #self.logger.warning('No connection to ILO')
                return
        rspList = self._runCmd('show /map1')
        for line in rspList:
            if line.find('name=iLO') > -1:
                try:
                    self.ilo_version = int(line.split()[1])
                    #self.logger.debug('ILO version: %d' % self.ilo_version)
                except:
                    #self.logger.debug('Could not get ilo version ' +\
                    #                  'from line: %s' % line)
                    pass
        #self.logger.debug('Post GetVer: %s' % repr(self.iLOConnection))
        return self.ilo_version

    def _sshDisconnect(self):
        if self.iLOConnection != None:
            self.iLOConnection.disconnect()
        self.iLOConnection = None

    def _runCmd(self, cmd, run=True):
        resultList = []
        if self.iLOConnection != None:
            #self.logger.debug("iLOCommand: %s on %s" % (cmd, self.host))
            resultList = self.iLOConnection.execute(cmd)[1].readlines()
            #self.logger.debug("Command RSP: %s" % repr(resultList))
        return resultList

    def iLOPowerReset(self):
        if self.iLOConnection == None:
            self._sshConnect()
            if self.iLOConnection == None:
                #self.logger.warning('No connection to ILO')
                return
        cmd = 'POWER'
        resultList = self._runCmd(cmd)
        for i in resultList:
            if i.find('power: server power is currently: Off') > -1:
                cmd = 'POWER ON'
        self._sshDisconnect()
        time.sleep(1)
        self._sshConnect()
        if cmd != 'POWER ON':
            cmd = 'POWER RESET'
        resultList = self._runCmd(cmd)
        #self.logger.info('POWER RESET of System %s' % self.host)
        self._sshDisconnect()

    def iLOPowerStatus(self):
        #self.logger.debug('Checking Power status')
        if self.iLOConnection == None:
            self._sshConnect()
            if self.iLOConnection == None:
                #self.logger.warning('No connection to ILO')
                return
        cmd = 'POWER'
        self._runCmd(cmd)
        self._sshDisconnect()

    def iLOPowerON(self):
        #self.logger.info('POWER ON SYSTEM %s' % self.host)
        if self.iLOConnection == None:
            self._sshConnect()
            if self.iLOConnection == None:
                #self.logger.warning('No connection to ILO')
                return
        #self.logger.info('POWER ON SYSTEM %s' % self.host)
        cmd = 'POWER ON'
        self._runCmd(cmd)
        self._sshDisconnect()

    def iLOPowerOFF(self):
        if self.iLOConnection == None:
            self._sshConnect()
            if self.iLOConnection == None:
                #self.logger.warning('No connection to ILO')
                return
        #self.logger.info('POWER OFF System %s' % self.host)
        cmd = 'POWER OFF'
        self._runCmd(cmd)
        self._sshDisconnect()

    def iLOPXEBootOrderFirst(self):
        if self.iLOConnection == None:
            self._sshConnect()
            if self.iLOConnection == None:
                #self.logger.warning('No connection to ILO')
                return
        #self.logger.info('Setting to PXE as first boot option')
        cmd = 'set /system1/bootconfig1/bootsource5 bootorder=1'
        attempts = 0
        MAXATTEMPTS = 3
        error = -1
        while error != 0 and attempts < MAXATTEMPTS:
            resultList = self._runCmd(cmd)
            for e in resultList:
                if e.startswith('status='):
                    error = int(e.split('=')[1].strip())
            time.sleep(2)
            attempts += 1
        time.sleep(2)
        #self.logger.debug(resultList)
        self._sshDisconnect()

    def iLOPXEBootOrderLast(self):
        if self.iLOConnection == None:
            self._sshConnect()
            if self.iLOConnection == None:
                #self.logger.warning('No connection to ILO')
                return
        #self.logger.info('Setting PXE as 5th boot option')
        cmd = 'set /system1/bootconfig1/bootsource5 bootorder=5'
        attempts = 0
        MAXATTEMPTS = 3
        error = -1
        while error != 0 and attempts < MAXATTEMPTS:
            resultList = self._runCmd(cmd)
            for e in resultList:
                if e.startswith('status='):
                    error = int(e.split('=')[1].strip())
            time.sleep(2)
            attempts += 1
        time.sleep(2)
        #self.logger.debug(resultList)
        self._sshDisconnect()

    def iLOPXEBootOrderShow(self):
        if self.iLOConnection == None:
            self._sshConnect()
            if self.iLOConnection == None:
                #self.logger.warning('No connection to ILO')
                return
        cmd = 'show /system1/bootconfig1/bootsource5'
        self._runCmd(cmd)
        self._sshDisconnect()

    def iLOReset(self):
        '''
        Method to programmatically reset the iLO
        Connect to the iLO and issue 2 commands.
        1) cd /map1
        2) reset
        @return: None on success, error string on failure
        @rtype: String
        '''

        klass = self.__class__.__name__

        error = None   # Optimistically expect success

        if self.iLOConnection == None:
            self._sshConnect()
            if self.iLOConnection == None:
                error = "%s.iLOReset: No connection to ILO" % klass
                #self.logger.warning(error)
                return error
            else:
                #self.logger.info("Connected to ILO on '%s'" % \
                #                 self.host)
                pass
        else:
            #self.logger.info('Reusing ILO connection')
            pass
        completedMsg = 'status_tag=COMMAND COMPLETED'

        cmd1 = 'cd /map1'
        resultList = self._runCmd(cmd1)

        cmd1Success = False    # Pessimistically predict failure

        for i in resultList:
            if i.find(completedMsg) > -1:
                cmd1Success = True
                break

        if cmd1Success:
            #self.logger.info("Successfully ran (cmd1) '%s'" % cmd1)
            time.sleep(2)

            cmd2 = 'reset'

            cmd2Success = False

            resultList = self._runCmd(cmd2)
            for i in resultList:
                if i.find(completedMsg) > -1:
                    cmd2Success = True
                    break

            if cmd2Success:
                #self.logger.info("Successfully ran (cmd2) '%s'" % cmd2)
                #self.logger.info('ILO Reset on System %s' % self.host)
                pass
            else:
                error = ("%s.iLOReset: Error (command '%s') resetting ILO " + \
                         "on System %s") % (klass, cmd2, self.host)
                #self.logger.error(error)
        else:
            error = ("%s.iLOReset: Error (command '%s') resetting ILO " + \
                     "on System %s") % (klass, cmd1, self.host)
            #self.logger.error(error)

        self._sshDisconnect()
        return error

    def vmCDROMInsert(self, url):
        if self.iLOConnection == None:
            self._sshConnect()
            if self.iLOConnection == None:
                #self.logger.warning('No connection to ILO')
                return
        #self.logger.info('Virtual Media CDROM Insert')
        cmd = 'vm cdrom insert %s' % url
        self._runCmd(cmd)
        self._sshDisconnect()

    def vmCDROMEject(self):
        if self.iLOConnection == None:
            self._sshConnect()
            if self.iLOConnection == None:
                #self.logger.warning('No connection to ILO')
                return
        #self.logger.info('Virtual Media CDROM Eject')
        cmd = 'vm cdrom eject'
        self._runCmd(cmd)
        self._sshDisconnect()

    def vmCDROMConnect(self):
        if self.iLOConnection == None:
            self._sshConnect()
            if self.iLOConnection == None:
                #self.logger.warning('No connection to ILO')
                return
        #self.logger.info('Virtual Media CDROM Connect')
        cmd = 'vm cdrom set connect'
        self._runCmd(cmd)
        self._sshDisconnect()

    def vmCDROMBootOnce(self):
        if self.iLOConnection == None:
            self._sshConnect()
            if self.iLOConnection == None:
                #self.logger.warning('No connection to ILO')
                return
        #self.logger.info('Virtual Media CDROM set Boot once')
        cmd = 'vm cdrom set boot_once'
        self._runCmd(cmd)
        self._sshDisconnect()

    def waitForILOPrompt(self, shell):
        iloprompt = 'hpiLO->'
        output = ''
        shell.settimeout(5)
        #self.logger.debug('Waiting for hpiLO prompt')
        while output.find(iloprompt) == -1:
            try:
                #self.logger.debug(repr(shell))
                output = shell.recv(9999)
                #self.logger.debug(repr(output))
            except socket.timeout:
                #self.logger.error('No prompt received .. returning')
                #self.logger.debug('No prompt received .. returning False')
                return False
            #self.logger.debug(repr(output.find(iloprompt)))
        return True

    def getVSPShell(self):
        #self.logger.debug('Attempt to return a VSP shell')
        # Do not trust any existing connections so we disconnect
        try:
            self._sshDisconnect()
        except:
            self.iLOConnection = None
        if self.iLOConnection == None:
            #self.logger.debug(' no ilo connection need to connect')
            self._sshConnect()
            if self.iLOConnection == None:
                #self.logger.warning('Still No connection to ILO')
                #self.logger.debug('Still No connection to ILO')
                return None
        else:
            #self.logger.debug('We should not get to here with conn: %s' \
            #                  % repr(self.iLOConnection))
            pass
        #self.logger.debug('CONN: %s' % repr(self.iLOConnection))
        #self.logger.debug('Get SHELL for SSH connection')
        shell = self.iLOConnection.getShell()
        #self.logger.debug('Got shell: %s' % repr(shell))
        if not self.waitForILOPrompt(shell):
            #self.logger.error('Did not get to ilo prompt')
            #self.logger.debug('Did not get to ilo prompt')
            print "SystemHPiLO: getShell() returned False !!!"
            return None
        #self.logger.debug(repr(shell))
        # Entering the Virtual Serial Port
        cmd = 'cd /system1/oemhp_vsp1/\r'
        #self.logger.debug('Sending the following: %s' % cmd)
        shell.send(cmd)
        if not self.waitForILOPrompt(shell):
            #self.logger.error('Did not get to ilo prompt')
            #self.logger.debug('Did not get to ilo prompt')
            print 'SystemHPiLO: "' + cmd + '" failed to return iLO prompt !!!'
            return None
        # Firstly stop VSP in case another user has opened it
        cmd = 'stop\r'
        #self.logger.debug('Sending the following: %s' % cmd)
        shell.send(cmd)
        self.waitForILOPrompt(shell)
        time.sleep(1)
        # Start VSP
        #cmd = 'VSP\r'
        #self.logger.debug('Sending the following: %s' % cmd)
	cmd = 'show\r'
        shell.send(cmd)
	if not self.waitForILOPrompt(shell):
            #self.logger.error('Did not get to ilo prompt')
            #self.logger.debug('Did not get to ilo prompt')
            print 'SystemHPiLO: "' + cmd + '" failed to return iLO prompt !!!'
            return None
        time.sleep(1)
        cmd = 'start\r'
        shell.send(cmd)
        time.sleep(3)
        shell.settimeout(10)
        output = ''
        while output.lower().find('virtual serial port active') == -1:
            try:
                output = shell.recv(9999)
                #self.logger.debug(repr(output))
            except socket.timeout:
                #self.logger.error('Virtiual Serial Port Not' +
                # active .. exiting')
                print "SystemHPiLO: socket.timeout Exception during wait for VSP prompt !!!"
		print '----  output:' + output
                return None
        shell.send('\r')
        return shell

    """ RB Comment out - not currently used
    def getTEXTShell(self):
        if self.iLOConnection == None:
            self._sshConnect()
            if self.iLOConnection == None:
                self.logger.warning('No connection to ILO')
                return None
        shell = self.iLOConnection.getShell()
        if not self.waitForILOPrompt(shell):
            self.logger.error('Did not get to ilo prompt')
            return None
        # Entering the Virtual Serial Port
        shell.send('cd /system1/oemhp_vsp1/\n')
        if not self.waitForILOPrompt(shell):
            self.logger.error('Did not get to ilo prompt')
            return None
        # Firstly stop VSP in case another user has opened it
        shell.send('stop\r\n')
        self.waitForILOPrompt(shell)
        # Start TEXTCONS
        shell.send('TEXTCONS\r\n')
        time.sleep(3)
        shell.settimeout(10)
        output = ''
        while output.find('Starting text console') == -1:
            try:
                output = shell.recv(9999)
            except socket.timeout:
                self.logger.error('TEXTCONS not active')
                return None
        #shell.send('\r')
        return shell
    """

    def getShell(self):
        if self.iLOConnection == None:
            self._sshConnect()
        return self.iLOConnection.getShell()

    def closeShell(self):
        if self.iLOConnection != None:
            print "iLO connection being torn down..."
            self._sshDisconnect()
