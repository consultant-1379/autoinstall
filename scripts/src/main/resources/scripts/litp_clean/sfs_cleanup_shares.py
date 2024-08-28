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


class CleanupSFSShares():
    """
    Class to install LITP MS ISO
    """
    def __init__(self, cleanup_shares, cleanup_sfs_snapshots):
        """
        Initialise variables
        """
        self.connected_ip = None
        self.connected_user = None
        self.node = NodeConnect()
        self.output_rollback = None
        #LANG=C
        os.environ["LANG"] = "C"
        ##If explictly turned off set sfs_snapshots to empty list
        ##else set based on BREAK split
        if  "no_sfs_snapshot_cleanup" in cleanup_sfs_snapshots:
            self.cleanup_sfs_snapshots = []
        else:
            self.cleanup_sfs_snapshots = \
                cleanup_sfs_snapshots.split("__BREAK__")

        ##If explictly turned off set sfs_shares to empty list
        ##else set based on BREAK split
        if "no_sfs_cleanup" in cleanup_shares:
            self.cleanup_shares = []
        else:
            self.cleanup_shares = cleanup_shares.split("__BREAK__")

    def cleanup_sfs(self):
        """
        Cleanup shares and filesysems
        """
        try:
            self.cleanup_sfs_ss()
            self.cleanup_sfs_shares()
            #Print info after all cleanup run
            self.get_sfs_info()
            self.get_sfs_ss_info()

        except Exception as except_msg:
            print "WARNING: SFS cleanup failed: {0}"\
                .format(except_msg)

    @staticmethod
    def print_info(message, mtype="INFO"):
        """
        Prints information out to console.
        """
        print ""
        print "#########################################################"
        print ">> {0}: {1}".format(mtype, message)
        print "#########################################################"
        print ""

    def get_sfs_ss_info(self):
        """
        Runs commands on SFS to show information of system related
        to snapshots and caches.
        """
        self.print_info("Showing SFS snapshot/cache information")
        cmd = "storage rollback list"
        output_rollback, _, _ = self.node.run_command(cmd, logs=True)
        cmd = "storage rollback cache list"
        self.node.run_command(cmd, logs=True)

        return output_rollback

    def get_sfs_info(self):
        """
        Runs commands on SFS to show information of system
        related to filesystems, shares & pools.
        """
        self.print_info("Showing SFS share/filesystem/pools information")
        cmd = "nfs share show"
        self.node.run_command(cmd, logs=True)

        cmd = "storage fs list"
        self.node.run_command(cmd, logs=True)

        cmd = "storage pool list"
        self.node.run_command(cmd, logs=True)

    def setup_sfs_connection(self, details):
        """
        Sets up connection to SFS for running commands
        """
         #Fetch connection information
        sfs_ip = details[0]
        sfs_usr = details[1]
        sfs_pw = details[2]
        if sfs_ip != self.connected_ip \
                and sfs_usr != self.connected_user:
        #connect to sfs
            self.print_info("Connecting to SFS server on IP {0} (user: {1})"\
                                .format(sfs_ip, sfs_usr))
            self.node = NodeConnect(sfs_ip, sfs_usr, sfs_pw)
            self.connected_ip = sfs_ip
            self.connected_user = sfs_usr
            ##print info when connecting
            self.get_sfs_info()
            self.output_rollback = self.get_sfs_ss_info()

    def cleanup_ss_caches(self, snapshot_details):
        """
        Cleanup cache
        """
        cache = snapshot_details[4]
        if cache != "no_cache_cleanup":
            self.print_info("Cache to delete: {0}".format(cache))
            cmd = "storage rollback cache destroy {0}".format(cache)
            self.node.run_command(cmd, logs=True)

    def cleanup_filesystems(self, share_details):
        """
        Cleanup cache
        """
        filesystem = share_details[4]
        if filesystem != "no_filesystem_cleanup":
            self.print_info("Filesystem to delete: {0}"\
                                .format(filesystem))
            cmd = "storage fs offline {0}".format(filesystem)
            self.node.run_command(cmd, logs=True)

            cmd = "storage fs destroy {0}".format(filesystem)
            self.node.run_command(cmd, logs=True)

    def cleanup_sfs_ss(self):
        """
        Process the sfs_cleanup_list parameter in the cluster file to clean up
        the SFS files
        """
        for snapshot in self.cleanup_sfs_snapshots:
            #example share value before split:
            #10.44.86.231:master:master:L_CI15-managed-fs1_=CI15-managed-fs1:
            #CI15_cache1
            snapshot_details = snapshot.split(":")

            #If the split does not yield 5 values either connection info
            #or share info is missing so we should skip this cleanup
            if len(snapshot_details) < 4:
                msg = "The snapshot {0} is ill defined in clusterfile."\
                    .format(snapshot)
                self.print_info(msg, "WARNING")
                print "Please update in cluster file to allow for cleanup"
                print "skipping cleanup of this share now"
                continue

            #Setup connection based on ips in snapshot
            self.setup_sfs_connection(snapshot_details)

            #Loop through each snapshot
            snapshot_paths = snapshot_details[3].split(",")
            for path in snapshot_paths:
                path_details = path.split("=")

                if len(path_details) != 2:
                    msg = "The filesystem {0} is ill defined in clusterfile."\
                    .format(path)
                    self.print_info(msg, "WARNING")
                    print "Skipping cleanup of filesystem"
                    print "Update clusterfile entry to #snapshot_name" \
                        + "=#filesystem_name"
                    continue

                #The snapshot name parameter path_details[0] is now
                #ignored and all snapshots attached to filesystem
                #are deleted
                filesystem = path_details[1]

                for line in self.output_rollback:
                    if ' {0} '.format(filesystem) in line:
                        snap_to_delete = line.split()[0]

                        msg = "Snapshot to delete: {0} from filesystem: {1}"\
                            .format(snap_to_delete, filesystem)
                        self.print_info(msg)

                        cmd = "storage rollback destroy {0} {1}"\
                            .format(snap_to_delete,
                                    filesystem)
                        self.node.run_command(cmd, logs=True)

            self.cleanup_ss_caches(snapshot_details)

    def cleanup_sfs_shares(self):
        """
        Process the sfs_cleanup_list parameter in the cluster file to clean up
        the SFS files
        """
        msg = "Starting share/filesystem cleanup"
        self.print_info(msg, "INFO")
        ##Loop through all the shares
        for share in self.cleanup_shares:
            #example share value before split:
            #10.44.86.231:master:master:/vx/CI15-managed-fs1=10.44.235.0/24:
            #CI15-managed-fs1
            share_details = share.split(":")

            #If the split does not yield 5 values either connection info
            #or share info is missing so we should skip this cleanup
            if len(share_details) != 5:
                msg = "The share {0} is ill defined in clusterfile"\
                    .format(share)
                self.print_info(msg, "WARNING")
                print "Please update in cluster file to allow for cleanup"
                print "Skipping cleanup of this share now"
                continue

            #Setup connection based on ips in snapshot
            self.setup_sfs_connection(share_details)

            share_list = share_details[3].split(",")
            for share_name in share_list:
                nfs_share_name = share_name.split("=")
                if len(nfs_share_name) != 2:
                    msg = "Invalid share value given format should "\
                        + "be <share=hostip>"
                    self.print_info(msg, "WARNING")
                    print "Skipping share: {0}".format(share_name)
                    continue

                msg = "Share to delete: {0} on host: {1}"\
                    .format(nfs_share_name[0],
                            nfs_share_name[1])
                self.print_info(msg)
                cmd = "nfs share delete {0} {1}".format(nfs_share_name[0],
                                                        nfs_share_name[1])
                self.node.run_command(cmd, logs=True)

            self.cleanup_filesystems(share_details)


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

    run = CleanupSFSShares(sys.argv[1], sys.argv[2])
    run.cleanup_sfs()

if  __name__ == '__main__': main()
