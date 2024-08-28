"""
COPYRIGHT Ericsson 2019
The copyright to the computer program(s) herein is the property of
Ericsson Inc. The programs may be used and/or copied only with written
permission from Ericsson Inc. or in accordance with the terms and
conditions stipulated in the agreement/contract under which the
program(s) have been supplied.

@since:     April 2016
@author:    Laura Forbes
"""

import os
import sys
import subprocess
from run_ssh_cmd_su import RunSUCommands

# Disable output buffering to receive the output instantly
sys.stdout = os.fdopen(sys.stdout.fileno(), "w", 0)
sys.stderr = os.fdopen(sys.stderr.fileno(), "w", 0)

# Default file locations on MS
MS_DIR = "/root/Collect_Logs"
# Directory on MS to store all logs in
MS_LITP_LOGS = "/root/litp_logs"
CLUSTER_PATH = "/deployments/d1/clusters"


for line in sys.argv:
    if "--peer_user=" in line:
        PEER_USER = line.split("=")[-1]
    if "--peer_password=" in line:
        PEER_PASSWORD = line.split("=")[-1]
    if "--su_password=" in line:
        PEER_SU_PASSWORD = line.split("=")[-1]
    if "--cluster_path=" in line:
        CLUSTER_PATH = line.split("=")[-1]

COPY_LOGS={
    "/var/log/messages" : "var_log_messages",
    "/var/log/audit/audit.log" : "audit.log",
    "/var/log/litp/litp_libvirt.log" : "litp_libvirt.log",
    "/var/log/mcollective.log" : "mcollective.log",
    "/var/log/mcollective-audit.log" : "mcollective-audit.log",
    "/var/log/boot.log" : "boot.log",
    "/var/VRTSvcs/log/" : "VRTSvcs",
    "/etc/VRTSvcs/conf/config/" : "VRTSvcs_conf",
    "/var/coredumps/" : "coredumps",
    "/root/ks-pre.log" : "ks-pre.log"
}

RUN_CMDS = {
    "virsh list" : "virsh_list.txt",
    "hastatus -sum" : "hastatus_sum.txt"
}

# Get all nodes in cluster
CMD = 'litp show -rp {0} | grep -v "inherited from" | grep -B1 "type: node" ' \
      '| grep -v type | grep "/"'.format(CLUSTER_PATH)
PROCESS = subprocess.Popen(CMD, stdout=subprocess.PIPE, shell=True)
PEER_NODES = PROCESS.communicate()[0]

print "Nodes:"
print PEER_NODES
print "==============="

for node in PEER_NODES.splitlines():
    # Get nodes hostname
    cmd = 'litp show -p {0} | grep hostname | ' \
          'sed "s/        hostname: //g"'.format(node)
    print cmd
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True)
    hostname = process.communicate()[0][:-1]
    print "Hostname: {0}".format(hostname)
    # Add node name to file for MS to SCP logs over
    for host in hostname.splitlines():
        with open("{0}/nodes.txt".format(MS_LITP_LOGS), "a") as node_file:
            node_file.write("{0}\n".format(host))

        # Create directory on node to copy its logs to
        peer_dir = "/home/{0}/{1}".format(PEER_USER, host)
        cmd = "mkdir {0}".format(peer_dir)
        node_dir = RunSUCommands(hostname, PEER_USER,
                                 PEER_PASSWORD, PEER_SU_PASSWORD, cmd)
        node_dir.run_cmds()

        # Read file of logs to copy and GET TO WORK
        for cp_from, cp_to_dir in COPY_LOGS.iteritems():
            cp_to = "{0}/{1}".format(peer_dir, cp_to_dir)

            cmd = "cp {0} {1}".format(cp_from, cp_to)
            print cmd

            # If directory, copy all of its contents
            if cp_from[-1] == '/':
                cmd += " -r"

            copy_file = RunSUCommands(hostname, PEER_USER,
                                      PEER_PASSWORD, PEER_SU_PASSWORD, cmd)
            copy_file.run_su_cmds()

        # Read file of commands to run and GET TO GOD DAMN WORK
        for cmd_to_run, output_file_name in RUN_CMDS.iteritems():
            print cmd_to_run
            output_file = "{0}/{1}".format(peer_dir, output_file_name)

            cmd = "{0} > {1}".format(cmd_to_run, output_file)
            exec_cmd = RunSUCommands(hostname, PEER_USER,
                                     PEER_PASSWORD, PEER_SU_PASSWORD, cmd)
            exec_cmd.run_su_cmds()

        # Change user permissions on all files in
        # created log directory so they can be SCPed
        print 'Changing user permissions on files so they can be SCPed'
        cmd = "chmod -R 745 {0}/*".format(peer_dir)

        run_cmd = RunSUCommands(hostname, PEER_USER,
                                PEER_PASSWORD, PEER_SU_PASSWORD, cmd)
        run_cmd.run_su_cmds()
