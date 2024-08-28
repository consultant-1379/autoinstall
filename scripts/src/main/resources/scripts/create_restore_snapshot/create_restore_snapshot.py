import sys
import os
import time
from common_platform_files.common_methods import NodeConnect
import common_platform_files.constants as constants


class CreateRestoreSnapshot:
    """
    Class to create and restore LITP snapshots
    """
    def __init__(self, ai_params):
        """
        Initialise variables
        """
        self.ai_params = ai_params
        self.node = NodeConnect(self.ai_params["MS_IP"],
                                constants.LITP_USER,
                                constants.LITP_USER_MS_PASSWD)

    def wait_for_cmd(self, node, cmd, expected_rc, expected_stdout=None,
                     timeout_mins=1, su_root=False, default_time=10,
                     direct_root_login=False):
        """
        Runs a command repeatedly until the expected return code is received or
        timeout occurs.

        Args:
           node         (str): The node the command will be run on.

           cmd          (str): The command you wish to run.

           expected_rc  (int): The return code to wait for.

        Kwargs:
           expected_stdout (str): Optionally a stdout to wait for.

           timeout_mins (int): Timeout in minutes before breaking.

           su_root     (bool): Set flag to True to run the command as root.

           default_time  (int): The time to wait between each poll.
                                Defaults to 10 seconds.

           direct_root_login (bool): Set flag to True to run command as root
                                     without first logging in as a litp user

        Returns:
           bool. True if the expected return code is returned before timeout
           or False otherwise.
        """
        timeout_seconds = timeout_mins * 60
        seconds_passed = 0

        while True:
            if direct_root_login:
                stdout, _, returnc = self.run_command(node, cmd,
                                                      username="root",
                                                      password="@dm1nS3rv3r")
            else:
                stdout, _, returnc = self.run_command(node, cmd,
                                                      su_root=su_root)

            if returnc == expected_rc:
                if expected_stdout:
                    if expected_stdout in stdout:
                        return True
                else:
                    return True

            time.sleep(default_time)
            seconds_passed += default_time

            if seconds_passed > timeout_seconds:
                return False

    def wait_for_ping(self, ip_address, ping_success=True,
                      timeout_mins=15, retry_count=3):
        """
        Waits for the ip_address to either return a ping or stop returning
        a ping depending on the flag set.

        Args:
           ip_address (str) : Ip address to ping.

        KWargs:
           ping_success (str): By default will return only after ping returns
           success. If set to False will return when ping fails.

           timeout_mins (str): If the ping has not behaved as expected before
           the timeout will return with False.

           retry_count (str): The number of retries before it's known that
                              a ping fails.

        Returns:
           bool. True if ping responds in time or False otherwise.
        """
        counter = 0
        timeout_secs = 60 * timeout_mins
        increment_secs = 10

        print ">> Initial Timeout_secs: {0}".format(timeout_secs)

        # Need a retry mechanism as sometimes ping responses get lost.
        # In this scenario, we need to have several unsuccessful pings
        # before it's known for 100% sure that ping fails
        retry = retry_count

        while True:
            time.sleep(10)
            pingable = self.node.is_node_pingable()

            if ping_success and pingable:
                return True

            if not ping_success and not pingable:
                retry -= 1
                # Reduce time to enable faster execution
                increment_secs = 2
                print ">> ping retry counter: {0}".format(retry)
                if retry == 0:
                    return True

            if not ping_success and pingable:
                # Reset to initial values to cover the scenario in which
                # a failed ping is immediately followed by successful one
                retry = retry_count
                increment_secs = 10
                print ">>  reset ping retry counter: {0}".format(retry)

            time.sleep(increment_secs)
            counter += increment_secs

            if counter > timeout_secs:
                print ">> Exiting wait_for_ping due to timeout"
                return False

    def create_snapshot(self):
        """
        Creates a snapshot
        """
        cmd = "/usr/bin/litp create_snapshot"
        if not self.node.handle_run_command(cmd):
            print ">> ERROR: CREATE SNAPSHOT COMMAND FAILED ON HOST"
            return False

        if not self.node.waitfor_litp_plan(240, 2):
            return False

        return True

    def remove_snapshot(self):
        """
        Removes a snapshot
        """
        cmd = "/usr/bin/litp remove_snapshot"
        if not self.node.handle_run_command(cmd):
            print ">> ERROR: CREATE SNAPSHOT COMMAND FAILED ON HOST"
            return False

        if not self.node.waitfor_litp_plan(240, 2):
            return False

        return True

    def restore_snapshot(self, recreate_snapshot=True):
        """
        Restores a snapshot and optionally removes and recreates it

        KWargs:
           recreate_snapshot (bool) : Removes and recreates an unnamed snapshot
        """
        cmd = "/usr/bin/litp restore_snapshot"
        if not self.node.handle_run_command(cmd):
            print ">> ERROR: RESTORE SNAPSHOT COMMAND FAILED ON HOST"
            return False

        # Wait for the MS node to become unreachable
        ms_ip = self.ai_params["MS_IP"]
        self.wait_for_ping(ms_ip, False, 20)

        # Wipe active SSH connection to force a reconnect
        if self.node.ssh:
            try:
                self.node.ssh.close()
                self.node.ssh = None
            except Exception as except_err:
                print "Error disconnecting: {1}".\
                    format(str(except_err))
                self.node.ssh = None
        else:
            self.node.ssh = None

        # Wait for MS to be reachable again after reboot
        self.wait_for_ping(ms_ip)

        # Sleep to give some final time for merge
        time.sleep(360)

        # Reconnect node
        self.node = NodeConnect(self.ai_params["MS_IP"],
                                constants.LITP_USER,
                                constants.LITP_USER_MS_PASSWD)

        if recreate_snapshot:
            if not (self.remove_snapshot() and self.create_snapshot()):
                return False

        return True


def main():
    """
    Create or restore a LITP snapshot

    :option str ms_ip: The network address of the MS to connect to
    :option bool create_snapshot: Create a snapshot if True, default=False
    :option bool restore_snapshot: Restore a snapshot if True, default=False
    :return: True if successful, False otherwise
    :rtype: bool
    """
    params = dict()

    ms_ip = None
    create_snapshot = False
    restore_snapshot = False

    for line in sys.argv:
        if "--create_snapshot" in line:
            create_snapshot = True
        if "--restore_snapshot" in line:
            restore_snapshot = True
        if "--ms_ip=" in line:
            params["MS_IP"] = line.split("=")[-1]

    # Disable output buffering to receive the output instantly
    sys.stdout = os.fdopen(sys.stdout.fileno(), "w", 0)
    sys.stderr = os.fdopen(sys.stderr.fileno(), "w", 0)
    if len(sys.argv) < 3:
        print ">> ERROR: Not all required arguments supplied: %s" % sys.argv
        return False

    if create_snapshot:
        if not CreateRestoreSnapshot(params).create_snapshot():
            return False

    if restore_snapshot:
        if not CreateRestoreSnapshot(params).restore_snapshot():
            return False

    return True


if  __name__ == '__main__':
    main()
