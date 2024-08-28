"""
COPYRIGHT Ericsson 2019
The copyright to the computer program(s) herein is the property of
Ericsson Inc. The programs may be used and/or copied only with written
permission from Ericsson Inc. or in accordance with the terms and
conditions stipulated in the agreement/contract under which the
program(s) have been supplied.

@since:     April 2016
@author:    Laura Forbes

Collect logs from the MS creating relevant directories.
Call script to collect peer node logs. Copy node logs here.

TO DO: NEED TO RUN PASSWORD SCRIPTS FIRST.
"""

import sys
import subprocess
import pexpect
from collect_logs_funcs import CollectLogsFuncs
import os.path
from run_ssh_cmd_su import RunSUCommands

# Disable output buffering to receive the output instantly
sys.stdout = os.fdopen(sys.stdout.fileno(), "w", 0)
sys.stderr = os.fdopen(sys.stderr.fileno(), "w", 0)

collect_logs_funcs = CollectLogsFuncs

# Default file locations on MS
MS_DIR = "/root/Collect_Logs"
# Directory on MS to store all logs in
MS_LITP_LOGS = "/root/litp_logs"
MS_SCRIPTS_DIR = "{0}/scripts".format(MS_DIR)
# Create directory for MS specific Logs
MS_LOG_DIR = "{0}/ms_logs".format(MS_LITP_LOGS)
PEER_USER = ""
PEER_PASSWORD = ""
PEER_SU_PASSWORD = ""
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



RUN_CMDS = {
"litp show_plan":"litp_plan.txt",
"tar -czvf /var/log/litp/metrics.tar.gz /var/log/litp/*" : "metrics-collection.txt",
"/opt/ericsson/nms/litp/bin/litp_state_backup.sh /tmp" : "litp_state_backup_run_output"
}

COPY_LOGS={
    "/var/log/messages" : "var_log_messages",
    "/var/log/mcollective.log" : "mcollective.log",
    "/var/log/mcollective-audit.log" : "mcollective-audit.log",
    "/var/lib/litp/core/model/LAST_KNOWN_CONFIG" : "LAST_KNOWN_CONFIG",
    "/opt/ericsson/enminst/log/patch_rhel.log" : "patch_rhel.log",
    "/var/log/boot.log" : "boot.log",
    "/var/log/yum.log" : "yum.log",
    "/var/log/litp/metrics.log" : "metrics.log",
    "/var/tmp/enm-version" : "enm-version",
    "/etc/litp-release" : "litp-release",
    "/var/log/enminst.log" : "enminst.log",
    "/var/log/audit/audit.log" : "audit.log",
    "/ericsson/deploymentDescriptions/2svc_enm_physical_test_dd.xml" : "2svc_enm_physical_test_dd.xml",
    "/opt/ericsson/nms/litp/etc/puppet/manifests/plugins/" : "plugins",
    "/var/log/litp/" : "var_log_litp",
    "/var/log/cobbler/" : "cobbler",
    "/var/log/httpd/" : "httpd",
    "/var/log/hyperic/" : "hyperic",
    "/var/log/tuned/" : "tuned",
    "/var/log/litp/metrics.tar.gz" : "metrics.tar.gz",
    "/tmp/litp_backup_*" : "db_dumps"
}

collect_logs_funcs.mkdir_parent(MS_LOG_DIR)

# Run the specified commands piping the output to the specified file
for cmd_to_run, output_file_name in RUN_CMDS.iteritems():
    output_file = "{0}/{1}".format(MS_LOG_DIR, output_file_name)
    cmd = "{0} > {1}".format(cmd_to_run, output_file)
    print cmd
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True).wait()

# Copy all specified logs to newly created MS log directory
for cp_from, to_dir_name in COPY_LOGS.iteritems():
    cp_to = "{0}/{1}".format(MS_LOG_DIR, to_dir_name)
    # If directory, copy all of its contents
    if cp_from[-1] == '/':
        collect_logs_funcs.copy_dir(cp_from, cp_to)
    else:
        # Otherwise, just copy the file
        collect_logs_funcs.copy_file(cp_from, cp_to)


# Run script to set passwords on all nodes
# TO DO: FOR ALL SYSTEMS
SET_PASS_SH = "{0}/scripts/reset_passwords.bsh".format(MS_DIR)
CMD = "sh {0}".format(SET_PASS_SH)
print CMD
PROCESS = subprocess.Popen(CMD, stdout=subprocess.PIPE, shell=True).wait()

# Run script to collect logs off nodes
CMD = "python {0}/collect_node_logs.py --peer_user={1} --peer_password={2} --su_password={3}".format(
    MS_SCRIPTS_DIR, PEER_USER, PEER_PASSWORD, PEER_SU_PASSWORD)
print CMD
PROCESS = subprocess.Popen(CMD, stdout=subprocess.PIPE, shell=True)

# Print the output of running the node collection script
NODE_LOGS = "node_collection_logs.txt"
print "Logging node collection script output to {0}".format(NODE_LOGS)
for line in iter(PROCESS.stdout.readline, ''):
    with open("{0}/{1}".format(MS_LITP_LOGS, NODE_LOGS), "a") as out_file:
        out_file.write(line)

NODES_FILE = "{0}/nodes.txt".format(MS_LITP_LOGS)

# Check if nodes.txt exists
if os.path.isfile(NODES_FILE):
    # SCP logs from each node to MS
    with open(NODES_FILE) as f:
        NODES_LIST = f.readlines()

    for node in NODES_LIST:
        cmd = "scp -r {0}@{1}:/home/{0}/{1} {2}".format(
            PEER_USER, node.rstrip(), MS_LITP_LOGS)
        print cmd
        child = pexpect.spawn(cmd)
        child.expect(["password:", pexpect.EOF])
        child.sendline(PEER_PASSWORD)
        child.expect(pexpect.EOF)

        # Remove created log directory on each node
        cmd = "rm -rf /home/{0}/{1}*".format(PEER_USER, node.rstrip())
        remove_dir = RunSUCommands(node.rstrip(), PEER_USER,
                                   PEER_PASSWORD, PEER_SU_PASSWORD, cmd)
        remove_dir.run_su_cmds()

# Tar created log directory
CMD = "tar -Pzcvf litp_logs.tar.gz litp_logs".format(MS_LITP_LOGS)
print CMD
PROCESS = subprocess.Popen(CMD, stdout=subprocess.PIPE, shell=True).wait()
