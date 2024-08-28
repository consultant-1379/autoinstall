#!/usr/bin/env python
'''
COPYRIGHT Ericsson 2019
The copyright to the computer program(s) herein is the property of
Ericsson Inc. The programs may be used and/or copied only with written
permission from Ericsson Inc. or in accordance with the terms and
conditions stipulated in the agreement/contract under which the
program(s) have been supplied.

@summary:   Common methods for Autoinstall
'''
import time
from common_methods import NodeConnect

class LitpMethods(object):
    """
    Common methods used in Autoinstall.
    """

    def litp_create_plan(self, node):
        cmd = "/usr/bin/litp create_plan"
        if not node.handle_run_command(cmd):
            print ">> ERROR: CREATE PLAN COMMAND FAILED ON HOST"
            return False

    def litp_show_plan(self, node):
        cmd = "/usr/bin/litp show_plan"
        if not node.handle_run_command(cmd):
            print ">> ERROR: SHOW PLAN COMMAND FAILED ON HOST"
            return False

    def litp_run_plan(self, node):
        cmd = "/usr/bin/litp run_plan"
        if not node.handle_run_command(cmd):
            print ">> ERROR: RUN PLAN FAILED ON HOST"
            return False

    def litp_remove_plan(self, node):
        cmd = "/usr/bin/litp remove_plan"
        if not node.handle_run_command(cmd):
            print ">> ERROR: CREATE SNAPSHOT COMMAND FAILED ON HOST"
            return False

    def litp_create_snapshot(self, node):
        cmd = "/usr/bin/litp create_snapshot"
        if not node.handle_run_command(cmd):
            print ">> ERROR: CREATE SNAPSHOT FAILED ON HOST"
            return False

    def litp_remove_snapshot(self, node):
        cmd = "/usr/bin/litp remove_snapshot"
        if not node.handle_run_command(cmd):
            print ">> ERROR: REMOVE SNAPSHOT FAILED ON HOST"
            return False

    def litp_version(self, node):
        cmd = "/usr/bin/litp version --all"
        if not node.handle_run_command(cmd):
            print ">> ERROR: VERSION COMMAND FAILED ON HOST"
            return False

    def litp_import(self, node, item):
        cmd = "/usr/bin/litp import {0}".format(item)
        if not node.handle_run_command(cmd):
            print ">> ERROR: LITP IMPORT COMMAND FAILED"
            return False

    def litp_import_iso(self, ms_ip, litp_user, litp_user_passwd):
        node = NodeConnect(ms_ip, litp_user, litp_user_passwd)
        cmd = "/usr/bin/litp import_iso /mnt/"
        if not node.handle_run_command(cmd):
            print ">> ERROR: LITP IMPORT ISO COMMAND FAILED"
            return False

    def enable_litp_debug(self, ms_ip, litp_user, litp_user_passwd):
        node = NodeConnect(ms_ip, litp_user, litp_user_passwd)
        # SET LITP LOGGING TO DEBUG
        cmd = "litp update -p /litp/logging -o force_debug=true"
        if not node.handle_run_command(cmd):
            print ">> WARNING: TURN ON LITP DEBUG FAILED ON HOST"

    def litp_restore_snapshot(self, node):
        cmd = "/usr/bin/litp restore_snapshot"
        if not node.handle_run_command(cmd):
            print ">> ERROR: RUN RESTORE SNAPSHOT FAILED ON HOST"
            return False

    def litp_inherit(self, node, path, source):
        cmd = "litp inherit -p {0} -s {1}".format(path, source)
        if not node.handle_run_command(cmd):
            print ">> ERROR: INHERIT COMMAND FAILED ON HOST"
            return False

    def create_ai_dir(self, node, jenkins_job_id):
        if not node.handle_run_command("mkdir -p /tmp/.{0}".format(jenkins_job_id)):
            print ">> ERROR: MKDIR FAILED ON HOST"
            return False

    def wait_for_puppet(self, node):
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
            stdout, stderr, retc = node.run_command(cmd)
            ##If grep fails it means catelog applied
            if retc == 1:

                stdout, stderr, retc = \
                    node.run_command('mco puppet status')
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

            # Puppet is either not running catalogues or all nodes
            # currently running have completed one before
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

            # If at least one node has had a total of 180 attempts without finding a completed
            # catalogue - FAIL
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

    def wait_for_restore(self, node):
        """
        As documented on create_snapshot page will wait until snapshots are
        fully merged after a restore before running create snapshot.
        """
        cmd = "/sbin/lvs | /bin/awk '{print $3}' | /bin/grep 'Owi'"

        max_count = 120
        count = 0
        while True:
            node.run_command("/sbin/lvs", logs=True)
            stdout, stderr, retc = \
                node.run_command(cmd, logs=True)

            if retc == 1:
                return True

            count += 1

            if count == max_count:
                return False

            time.sleep(10)
            print "Waited {0} secs".format(count * 10)
