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
import time
from common_platform_files.common_methods import NodeConnect
import common_platform_files.constants as constants


class CleanupSFSShares():
    """
    Class to install LITP MS ISO
    """
    def __init__(self, cleanup_shares, cleanup_sfs_snapshots):
        """
        Initialise variables
        """

        self.node = NodeConnect()
        
        self.do_snap = False
        self.do_share = False
        if cleanup_sfs_snapshots != "no_sfs_snapshot_cleanup":
            self.do_snap = True
        if cleanup_shares != "no_sfs_cleanup":
            self.do_share = True
        self.cleanup_shares = cleanup_shares.split("__BREAK__")
        print "\n CLEANUP_SHARES LIST: \n"
        print self.cleanup_shares
        self.cleanup_sfs_snapshots = cleanup_sfs_snapshots.split("__BREAK__")
        print " \n CLEANUP_SFS_SNAPS LIST: \n"
        print self.cleanup_sfs_snapshots

    def cleanup_sfs(self):
        """
        Cleanup shares and filesystems on given SFS
        """

        print ""
        print "#########################################################"
        print ">> INFO: CLEANUP SFS SHARES AND SNAPSHOTS"
        print "#########################################################"
        print ""

        #LANG=C
        os.environ["LANG"] = "C"
        if self.do_snap:
            connsnlist = []
            print "\nSHOWING SFS SNAPSHOT INFORMATION BEFORE DELETION\n"
            print "CACHE DETAILS SHOULD BE IN THIS LINE :\n"
            print self.cleanup_sfs_snapshots
            for sfssnap in self.cleanup_sfs_snapshots:
                snap_info = sfssnap.split(":")
                print "SNAP_INFO:\n"
                print snap_info
                if len(snap_info) == 5:
                    self.node = NodeConnect(snap_info[0], snap_info[1], snap_info[2])
                    conndet="{0}-{1}-{2}".format(snap_info[0], snap_info[1], snap_info[2])
                    if conndet not in connsnlist:
                        connsnlist.append(conndet)
            for line in connsnlist:
                conne = line.split("-")
                self.node = NodeConnect(conne[0], conne[1], conne[2])
                cmd = "storage rollback list"
                self.node.run_command(cmd, logs=True)
                cmd = "storage rollback cache list"
                self.node.run_command(cmd, logs=True)
            snap_found = False
            for sfssnap in self.cleanup_sfs_snapshots:
                snap_info = sfssnap.split(":")
                if len(snap_info) == 5:
                    snap_found = True
                    self.node = NodeConnect(snap_info[0], snap_info[1], snap_info[2])
                    snap_list = snap_info[3].split(",")
                    for snaps in snap_list:
                    	print "DEL_SNAP:\n"
                    	print del_snap
                        del_snap = snaps.split("=")
                        if len(del_snap) == 2:
                            print "Snapshot to delete:", del_snap[0], " from filesystem: ",del_snap[1]
                            cmd = "storage rollback destroy %s %s" % (del_snap[0], del_snap[1])
                            self.node.run_command(cmd, logs=True)
                        else:
                            print "Invalid snapshot value given, format should be <share=hostip>"
                    if snap_info[4] != "no_cache_cleanup":
                        print "Cache to delete: ", snap_info[4]
                        cmd = "storage rollback cache destroy %s" % (snap_info[4])
                        self.node.run_command(cmd, logs=True)

            print "\nSHOWING SFS SNAPSHOT INFORMATION AFTER DELETION\n"
            for line in connsnlist:
                conne = line.split("-")
                self.node = NodeConnect(conne[0], conne[1], conne[2])
                cmd = "storage rollback list"
                self.node.run_command(cmd, logs=True)
                cmd = "storage rollback cache list"
                self.node.run_command(cmd, logs=True)
                        

        if self.do_share:
            condetlist = []
            print "\nSHOWING SFS INFORMATION BEFORE DELETION\n"
            for sfssh in self.cleanup_shares:
                sfs_info = sfssh.split(":")
                if len(sfs_info) == 5:
                    self.node = NodeConnect(sfs_info[0], sfs_info[1], sfs_info[2])
                    conndet="{0}-{1}-{2}".format(sfs_info[0], sfs_info[1], sfs_info[2])
                    if conndet not in condetlist:
                        condetlist.append(conndet)
            for line in condetlist:
                conne = line.split("-")
                self.node = NodeConnect(conne[0], conne[1], conne[2])
                cmd = "nfs share show"
                self.node.run_command(cmd, logs=True)
                cmd = "storage fs list"
                self.node.run_command(cmd, logs=True)
                cmd = "storage pool list"
                self.node.run_command(cmd, logs=True)

            sfs_found = False
            for sfssh in self.cleanup_shares:
                sfs_info = sfssh.split(":")
                if len(sfs_info) == 5:
                    sfs_found = True
                    self.node = NodeConnect(sfs_info[0], sfs_info[1], sfs_info[2])
                    share_list = sfs_info[3].split(",")
                    for share_name in share_list:
                        nfs_share_name = share_name.split("=")
                        if len(nfs_share_name) == 2:
                            print "Share to delete:", nfs_share_name[0], " on host: ",nfs_share_name[1]
                            cmd = "nfs share delete %s %s" % (nfs_share_name[0], nfs_share_name[1])
                            self.node.run_command(cmd, logs=True)
                        else:
                            print "Invalid share value given, format should be <share=hostip>"
                    if sfs_info[4] != "no_filesystem_cleanup":
                        print "Filesystem to delete: ", sfs_info[4]
                        cmd = "storage fs offline %s" % (sfs_info[4])
                        self.node.run_command(cmd, logs=True)
                        cmd = "storage fs destroy %s" % (sfs_info[4])
                        self.node.run_command(cmd, logs=True)
                else:
                    print "Not enough arguments given to delete shares/filesystem"

            print "\nSHOWING SFS INFORMATION AFTER DELETION\n"

            if sfs_found:
                for line in condetlist:
                    conne = line.split("-")
                    self.node = NodeConnect(conne[0], conne[1], conne[2])
                    cmd = "nfs share show"
                    self.node.run_command(cmd, logs=True)
                    cmd = "storage fs list"
                    self.node.run_command(cmd, logs=True)
                    cmd = "storage pool list"
                    self.node.run_command(cmd, logs=True)

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

    #run = CleanupSFSShares(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5])
    run = CleanupSFSShares(sys.argv[1], sys.argv[2])
    run.cleanup_sfs()

if  __name__ == '__main__':main()
