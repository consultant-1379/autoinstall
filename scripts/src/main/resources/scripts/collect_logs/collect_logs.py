"""
COPYRIGHT Ericsson 2019
The copyright to the computer program(s) herein is the property of
Ericsson Inc. The programs may be used and/or copied only with written
permission from Ericsson Inc. or in accordance with the terms and
conditions stipulated in the agreement/contract under which the
program(s) have been supplied.

@since:     July 2016
@author:    John Dolan

Run this script from your local machine or gateway
to get MS and node logs of specified system.

Run this script like:
python collect_logs.py <SYSTEM>
Ex. python collect_logs.py 38
"""
import os
import sys
import subprocess
from collect_logs_funcs import CollectLogsFuncs




class CollectLogs:

    def __init__(self, ms_ip, ms_pass, peer_user, peer_pass, peer_su_pass):

        # Disable output buffering to receive the output instantly
        # sys.stdout = os.fdopen(sys.stdout.fileno(), "w", 0)
        # sys.stderr = os.fdopen(sys.stderr.fileno(), "w", 0)
        self.ms_ip = ms_ip
        self.ms_password = ms_pass
        self.peer_user = peer_user
        self.peer_password = peer_pass
        self.peer_su_password = peer_su_pass
        self.cluster_path = "/deployments/d1/clusters"
        self.dir_path = os.path.dirname(os.path.realpath(__file__))
        self.ms_dir = "/root/Collect_Logs"
        self.ms_litp_logs = "/root/litp_logs"
        self.ms_scripts_dir = "{0}/scripts".format(self.ms_dir)
        self.funcs_script = "collect_logs_funcs.py"
        self.ms_collect_script = "{0}/collect_ms_logs.py".format(self.ms_scripts_dir)

    def collect_logs(self):
        """
        Collect logs from MS and nodes of given system.
        """
        print "Collecting logs..."
        mkdir = 'ssh root@{0} -C "mkdir {1}"'.format(self.ms_ip, self.ms_dir)
        scp_scripts = "scp -r {0}/scripts/ root@{1}:{2}".format(
            self.dir_path, self.ms_ip, self.ms_dir)
        scp_funcs = "scp {0}/{1} root@{2}:{3}".format(
            self.dir_path, self.funcs_script, self.ms_ip, self.ms_scripts_dir)
        collect_cmd = 'ssh root@{0} -C "python {1} --peer_user={2} --peer_password={3} --su_password={4}"'.format(
            self.ms_ip, self.ms_collect_script, self.peer_user, self.peer_password, self.peer_su_password)
        scp_back = "scp -r root@{0}:{1}.tar.gz .".format(self.ms_ip, self.ms_litp_logs)
        remove_dirs = 'ssh root@{0} -C "rm -rf {1}; rm -rf {2}*"'.format(
            self.ms_ip, self.ms_dir, self.ms_litp_logs)

        # If MS_PASSWORD != "NONE", use pexpect
        if self.ms_password != "NONE":
            print "Using pexpect"
            collect_logs_funcs = CollectLogsFuncs
            try:
                # Create directory on MS to store log files
                collect_logs_funcs.expect_cmd(mkdir, self.ms_password)
                # SCP the scripts folder to the new directory
                collect_logs_funcs.expect_cmd(scp_scripts, self.ms_password)
                # SCP the functions script
                collect_logs_funcs.expect_cmd(scp_funcs, self.ms_password)
                # Run script on MS to collect logs
                collect_logs_funcs.expect_cmd(collect_cmd, self.ms_password)
                # SCP the logs collected to the current machine
                collect_logs_funcs.expect_cmd(scp_back, self.ms_password)
                # Remove the created directories on the MS
                collect_logs_funcs.expect_cmd(remove_dirs, self.ms_password)
            except Exception as e:
                print "ERROR: Log collection script has not been successful."
                print e.message
        else:
            # Create directory on MS to store log files
            process = subprocess.Popen(
                mkdir, stdout=subprocess.PIPE, shell=True).wait()

            # SCP the scripts folder to the new directory
            scp_scripts += "/scripts"
            process = subprocess.Popen(
                scp_scripts, stdout=subprocess.PIPE, shell=True).wait()

            # SCP the functions script
            process = subprocess.Popen(
                scp_funcs, stdout=subprocess.PIPE, shell=True).wait()

            # Run script on MS to collect logs
            #process = subprocess.Popen(
            # collect_cmd, stdout=subprocess.PIPE, shell=True).wait()
            process = subprocess.Popen(
                collect_cmd, stdout=subprocess.PIPE, shell=True)
            out, err = process.communicate()
            for line in out:
                with open("collection_logs.txt", "a") as out_file:
                    out_file.write(line)

            # SCP the logs collected to the current machine
            process = subprocess.Popen(
                scp_back, stdout=subprocess.PIPE, shell=True).wait()

            # Remove the created directories on the MS
            print "Removing created dirs on the MS"
            process = subprocess.Popen(
                remove_dirs, stdout=subprocess.PIPE, shell=True).wait()


if __name__ == "__main__":
    MS_IP = ""
    MS_PASSWORD = ""
    PEER_USER = ""
    PEER_PASSWORD = ""
    PEER_SU_PASSWORD = ""
    CLUSTER_PATH = ""

    for line in sys.argv:
        if "--ms_ip=" in line:
            MS_IP = line.split("=")[-1]
        if "--ms_password=" in line:
            MS_PASSWORD = line.split("=")[-1]
        if "--peer_user=" in line:
            PEER_USER = line.split("=")[-1]
        if "--peer_password=" in line:
            PEER_PASSWORD = line.split("=")[-1]
        if "--su_password=" in line:
            PEER_SU_PASSWORD = line.split("=")[-1]

    CollectLogs(MS_IP, MS_PASSWORD, PEER_USER, PEER_PASSWORD, PEER_SU_PASSWORD).collect_logs()