#!/usr/bin/env python

# This file is a modified version of the file at https://fem32s11-eiffel004.eiffel.gic.ericsson.se:8443/jenkins/userContent/testware_runner.py which has been made to work with the jenkins on 10.44.235.150 for RHEL7

"""
Runs autoinstall and upgrade scripts
"""

import os
import sys
import json
import subprocess


# GLOBAL VARIABLES
RHEL_ISO = "rhel-server-7.9-x86_64-dvd.iso"

class ToolsDownload:

    def __init__(self, job_details):
        """
        Initialise variables
        """
        self.copy_dir = get_env('WORKSPACE')
        self.create_dir(self.copy_dir)
        self.results_dir = self.copy_dir + "/test-results"
        self.create_dir(self.results_dir)
        self.python_command = "/usr/bin/python"
        self.job_details = job_details

    @staticmethod
    def run_command_local(cmd, logs=True):

        if logs:
            print "[local]# {0}".format(cmd)

        child = subprocess.Popen(cmd, stdout=subprocess.PIPE,
                                 stderr=subprocess.PIPE, shell=True)

        result_1 = []
        result_2 = []
        if logs:
            while True:
                nextline = child.stdout.readline()
                if nextline == '' and child.poll() != None:
                    break
                if nextline:
                    sys.stdout.write(nextline)
                    sys.stdout.flush()
                    result_1.append(nextline.strip("\n"))

        result = child.communicate()
        if logs:
            print result[1]
            print child.returncode

        exit_code = child.returncode

        if logs:
            stdout = result_1
        else:
            stdout = result[0].splitlines()
        stderr = result[1].splitlines()

        return stdout, stderr, exit_code

    def create_dir(self, target_dir):
        """
        Method to create a directory
        """
        cmd = "/bin/mkdir -p {0}".format(target_dir)
        self.run_command_local(cmd, logs=False)

    def wget_tool(self, file_to_wget, target_dir):
        """
        Wget a file to a given directory
        """
        filen = file_to_wget.split("/")[-1]
        copy_to = target_dir + "/" + filen
        self.create_dir(target_dir)
        wget_cmd = '/usr/bin/wget -q -O - --no-check-certificate "{0}" -O {1}'.format(file_to_wget, copy_to)
        print "Copying {0} to {1}".format(file_to_wget, copy_to)
        self.run_command_local(wget_cmd, logs=False)
        return copy_to

    def untar_package(self, tarball, target_dir):
        """
        Wget a file to a given directory
        """
        filen = tarball.split("/")[-1]
        self.create_dir(target_dir)
        untar_cmd = "/bin/tar -C {0} -zxvf {1}".format(target_dir, tarball)
        print "Untar {0} to {1}".format(tarball, target_dir)
        self.run_command_local(untar_cmd, logs=False)
        rmfile_cmd = "/bin/rm -rf {0}".format(tarball)
        self.run_command_local(rmfile_cmd, logs=False)
        untar_dir = target_dir + "/" + filen.replace(".tar.gz", "")
        return untar_dir

    def get_test_dir(self, test_dir):
        """
        Find test cases under a given directory and return the path
        """

        cmd = "/usr/bin/find {0} | grep SKIPTTESTS.TXT".format(test_dir, logs=False)
        stdout, stderr, rc = self.run_command_local(cmd, logs=False)
        if rc == 0:
            for line in stdout:
                if "SKIPTTESTS.TXT" in line:
                    self.run_command_local("/bin/rm -rf {0}".format(test_dir, logs=False))
                    return "__SKIP__"
        if get_env("cdbRegRun"):
            if get_env("cdbRegRun") == "true":
                return test_dir
        cmd = "/usr/bin/find {0} | grep testset | grep .py".format(test_dir)
        stdout, stderr, rc = self.run_command_local(cmd, logs=False)
        if rc == 0:
            test_out = stdout[0].split("/")
            test_dir = "/".join(test_out[:-1])

        return test_dir

    def download_given_tools(self, rhel_only=False):
        """
        Download the given tools into the correct directories
        """

        autoinstall_dir = self.copy_dir + "/autoinstall"
        iso_install_dir = autoinstall_dir + "/install_iso"
        iso_upgrade_dir = autoinstall_dir + "/upgrade_iso"
        litp_3pp_download = autoinstall_dir + "/3pp_tarball"
        autoinstall_code = autoinstall_dir + "/autoinstall_code"
        ipmi_tool = autoinstall_dir + "/impi_tool"
        kgb_testing = self.copy_dir + "/kgb_testing"
        kgb_packages = kgb_testing + "/kgb_packages"
        kgb_replace_packages = kgb_testing + "/kgb_replace_packages"
        testware_pkgs = self.copy_dir + "/testware_packages"
        testware_pkgs_other = self.copy_dir + "/testware_other_packages"
        testware_pkgs_tools = self.copy_dir + "/testware_tools"
        utils_dir = self.copy_dir + "/utils_dir"

        self.job_details["autoinstall_dir"] = autoinstall_dir
        self.job_details["testware_pkgs"] = testware_pkgs
        self.job_details["testware_pkgs_other"] = testware_pkgs_other
        self.job_details["litp_testware_tools_directory"] = testware_pkgs_tools

        if rhel_only:
            if self.job_details["local_autoinstall"]:
                self.job_details["autoinstall_tarball_nexus_link"] = self.job_details["local_autoinstall"]
            else:
                self.job_details["autoinstall_tarball_nexus_link"] = self.wget_tool(self.job_details["autoinstall_tarball_nexus_link"], autoinstall_code)
            self.job_details["autoinstall_tarball_nexus_link"] = self.untar_package(self.job_details["autoinstall_tarball_nexus_link"], autoinstall_code) + "/scripts/"

        else:

            if self.job_details["litp_testware_utils_version"]:
                if self.job_details["custom_testware_utils"]:
                    self.job_details["litp_testware_utils_version"] = self.untar_package(self.job_details["custom_testware_utils"], utils_dir)
                else:
                    self.job_details["litp_testware_utils_version"] = self.wget_tool(self.job_details["litp_testware_utils_version"], utils_dir)
                    self.job_details["litp_testware_utils_version"] = self.untar_package(self.job_details["litp_testware_utils_version"], utils_dir)
                self.job_details["test_runner_file"] = self.job_details["litp_testware_utils_version"] + "/scripts/runner/test_runner.py"
                self.job_details["host_properties_dir"] = self.job_details["litp_testware_utils_version"] + "/scripts/hw_property_host_file"
                self.job_details["test_utils_directory"] = self.job_details["litp_testware_utils_version"] + "/scripts/utils"
                self.job_details["kgb_rpm_update_file"] = self.job_details["litp_testware_utils_version"] + "/scripts/kgb_scripts/litp_rpm_update.py"
                self.job_details["black_rpm_update_file"] = self.job_details["litp_testware_utils_version"] + "/scripts/kgb_scripts/litp_black_rpm_update.py"
                self.job_details["kgb_snapshot_file"] = self.job_details["litp_testware_utils_version"] + "/scripts/kgb_scripts/litp_hw_snapshot_handling.py"
            if self.job_details["litp_iso_version"]:
                self.job_details["litp_iso_nexus_link"] = self.wget_tool(self.job_details["litp_iso_nexus_link"], iso_install_dir)
                self.job_details["ipmi_tool_nexus"] = self.wget_tool(self.job_details["ipmi_tool_nexus"], ipmi_tool)
            if self.job_details["litp_upgrade_iso_version"]:
                self.job_details["litp_upgrade_iso_nexus_link"] = self.wget_tool(self.job_details["litp_upgrade_iso_nexus_link"], iso_upgrade_dir)
            if self.job_details["litp_iso_version"] or self.job_details["litp_upgrade_iso_version"] or self.job_details["expansionScript"] or self.job_details["litp_backup_restore"]:
                if self.job_details["local_autoinstall"]:
                    self.job_details["autoinstall_tarball_nexus_link"] = self.job_details["local_autoinstall"]
                else:
                    self.job_details["autoinstall_tarball_nexus_link"] = self.wget_tool(self.job_details["autoinstall_tarball_nexus_link"], autoinstall_code)
                self.job_details["autoinstall_tarball_nexus_link"] = self.untar_package(self.job_details["autoinstall_tarball_nexus_link"], autoinstall_code) + "/scripts/"
            if self.job_details["litp_package_nexus_links"]:
                pkg_names = ""
                for line in self.job_details["litp_package_nexus_links"].split(","):
                    pkg = line.split("__SPL__")
                    if pkg_names == "":
                        pkg_names += "{0}__SPL__{1}".format(self.wget_tool(pkg[0], kgb_packages), pkg[0].split("/")[-1])
                    else:
                        pkg_names += ",{0}__SPL__{1}".format(self.wget_tool(pkg[0], kgb_packages), pkg[0].split("/")[-1])
                self.job_details["litp_package_nexus_links"] = pkg_names
            if self.job_details["litp_package_replace_nexus_links"]:
                pkg_names = ""
                for line in self.job_details["litp_package_replace_nexus_links"].split(","):
                    pkg = line.split("__SPL__")
                    if pkg_names == "":
                        pkg_names += "{0}__SPL__{1}".format(self.wget_tool(pkg[0], kgb_replace_packages), pkg[0].split("/")[-1])
                    else:
                        pkg_names += ",{0}__SPL__{1}".format(self.wget_tool(pkg[0], kgb_replace_packages), pkg[0].split("/")[-1])
                self.job_details["litp_package_replace_nexus_links"] = pkg_names
            if self.job_details["litp_package_testware_nexus_links"]:
                testw_names = ""
                for line in self.job_details["litp_package_testware_nexus_links"].split(","):
                    pkg = line.split("__SPL__")
                    testwn = "{0}".format(self.wget_tool(pkg[0], testware_pkgs))
                    testwn = self.untar_package(testwn, testware_pkgs)
                    testwn = self.get_test_dir(testwn)
                    if testwn == "__SKIP__":
                        print "No tests found in: {0}".format(pkg[1])
                        continue
                    if testw_names == "":
                        testw_names += "{0}__SPL__{1}".format(testwn, pkg[1])
                    else:
                        testw_names += ",{0}__SPL__{1}".format(testwn, pkg[1])
                self.job_details["litp_package_testware_nexus_links"] = testw_names
            if self.job_details["litp_testware_other_nexus_links"]:
                testo_names = ""
                for line in self.job_details["litp_testware_other_nexus_links"].split(","):
                    pkg = line.split("__SPL__")
                    teston = "{0}".format(self.wget_tool(pkg[0], testware_pkgs_other))
                    teston = self.untar_package(teston, testware_pkgs_other)
                    teston = self.get_test_dir(teston)
                    if testo_names == "":
                        testo_names += "{0}__SPL__{1}".format(teston, pkg[1])
                    else:
                        testo_names += ",{0}__SPL__{1}".format(teston, pkg[1])
                    self.job_details["litp_testware_other_nexus_links"] = testo_names
            if self.job_details["litp_testware_tools_nexus_links"]:
                testt_names = ""
                for line in self.job_details["litp_testware_tools_nexus_links"].split(","):
                    if testt_names == "":
                        testt_names += "{0}".format(self.wget_tool(line, testware_pkgs_tools))
                    else:
                        testt_names += ",{0}".format(self.wget_tool(line, testware_pkgs_tools))
                    self.job_details["litp_testware_tools_nexus_links"] = testt_names

    def run_autoinstall(self, only_test=False):
        """
        Section to run autoinstall code
        """

        autoinstall_code = self.job_details["autoinstall_tarball_nexus_link"] + "autoinstall.py"
        autoinstall_command = "{0} {1}".format(self.python_command, autoinstall_code)
        autoinstall_command += " {0}".format(get_env("INSTALL_METHOD", "-ci"))
        autoinstall_command += " --litpiso={0}".format(self.job_details["litp_iso_nexus_link"])
        autoinstall_command += " --install_type={0}".format(get_env("installType", "cloud"))
        custom_script_env_name = "customLitpInstallScript"
        if get_env(custom_script_env_name ):
            autoinstall_command += " --install_script={0}/{1}".format(self.copy_dir, custom_script_env_name)
        elif get_env("litpInstallScript"):
            autoinstall_command += " --install_script={0}/{1}".format(self.job_details["autoinstall_tarball_nexus_link"], get_env("litpInstallScript"))
        if get_env("litpClusterFile"):
            autoinstall_command += " --cluster_file={0}/{1}".format(self.job_details["autoinstall_tarball_nexus_link"], get_env("litpClusterFile"))
        if get_env("INSTALL_METHOD", default="-ci") != "-rhellitp":
            ip_addr, _, _ = self.run_command_local("/bin/hostname -i")
            server_http_location = get_env("server_http_location",
                                           default="http://" + ip_addr[0] + ":80/")
            autoinstall_command += " --server_http_location={0}".format(server_http_location)
            autoinstall_command += " --rheliso={0}/{1}".format(server_http_location, RHEL_ISO)
        server_http_location_path = get_env("server_http_location_path",
                                            default="/var/www/html/")
        if get_env("INSTALL_METHOD", "-ci") == "-rhellitp":
            server_http_location_path = get_env("server_http_location_path",
                                            default=self.job_details["autoinstall_dir"] + "/ai_tools/")
            self.create_dir(server_http_location_path)
        autoinstall_command += " --server_http_full_path_location={0}".format(server_http_location_path)
        if get_env("OS_PATCHES"):
            if get_env("OS_PATCHES") == "true":
                autoinstall_command += " --with_os_patches={0}".format(get_env("OS_PATCHES_PATH", OS_PATCHES_INSTALL))
        autoinstall_command += " --install_option={0}".format(get_env("deployType", "CLI"))
        if get_env("RETRY_FAILED_PLAN"):
            if get_env("RETRY_FAILED_PLAN") == "true":
                autoinstall_command += " --retry-failed-plan"
        if get_env("UPGRADE_3PP"):
            if get_env("UPGRADE_3PP") == "true":
                autoinstall_command += " --upgrade_3pp"
        if get_env("REBOOT_PEER_NODES"):
            if get_env("REBOOT_PEER_NODES") == "true":
                autoinstall_command += " --reboot_peer_nodes_after_install"
        if get_env("VCS_DEBUG_LOGGING"):
            if get_env("VCS_DEBUG_LOGGING") == "true":
                autoinstall_command += " --initiate_vcs_debug_level_logging"
        if get_env("RETRY_FAILED_SCRIPT"):
            if get_env("RETRY_FAILED_SCRIPT") == "true":
                autoinstall_command += " --retry-failed-plan-script={0}".format(get_env("RETRY_FAILED_SCRIPT"))
        if get_env("SKIP_INSTALL_SNAPSHOT"):
            if get_env("SKIP_INSTALL_SNAPSHOT") == "true":
                autoinstall_command += " --skip_install_snapshot"
        if get_env("SKIP_POST_DEPLOY_SNAPSHOT"):
            if get_env("SKIP_POST_DEPLOY_SNAPSHOT") == "true":
                autoinstall_command += " --skip_post_deploy_snapshot"
        if get_env("EXPECT_LARGE_PLAN") == "true":
            autoinstall_command += " --expect_large_plan"
        if get_env("SKIP_PASSWORDS") == "true":
            autoinstall_command += " --skip_peer_node_passwd_setup"
        if get_env("installType", "cloud") == "cloud":
            autoinstall_command += " --ipmi_tool_location={0}".format(self.job_details["ipmi_tool_nexus"])
        if get_env("local_trust_auth", "false") == "true":
            autoinstall_command += " --local_trust_auth"
        if get_env("plan_monitor_script"):
            autoinstall_command += " --plan_monitor_script={0}/{1}"\
                .format(self.job_details["autoinstall_tarball_nexus_link"],
                        get_env("plan_monitor_script"))

        rc = 0
        if not only_test:
            _, _, rc = self.run_command_local(autoinstall_command)

        if rc != 0:
            sys.exit(1)

    def run_autoupgrade(self):
        """
        Section to run autoupgrade code
        Generate the command arguments to run autoupgrade.
        """
        autoinstall_code = self.job_details["autoinstall_tarball_nexus_link"] + "autoinstall.py"
        autoinstall_command = "{0} {1}".format(self.python_command, autoinstall_code)
        autoinstall_command += " {0}".format(get_env("UPGRADE_METHOD", "-litpup"))
        autoinstall_command += " --litp_upgrade={0}".format(self.job_details["litp_upgrade_iso_nexus_link"])
        if self.job_details["litp_iso_nexus_link"]:
            autoinstall_command += " --litpiso={0}".format(self.job_details["litp_iso_nexus_link"])
        autoinstall_command += " --install_type={0}".format(get_env("installType", "cloud"))
        autoinstall_command += " --install_option={0}".format(get_env("deployType", "CLI"))
        if get_env("litpClusterFile"):
            autoinstall_command += " --cluster_file={0}/{1}".format(self.job_details["autoinstall_tarball_nexus_link"], get_env("litpClusterFile"))

        # TODO: I think this is not used, but needs to be removed from
        # autoinstall first if that is the case.
        server_http_location_path = get_env("server_http_location_path",
                                            default=self.job_details["autoinstall_dir"] + "/ai_tools/")
        self.create_dir(server_http_location_path)
        autoinstall_command += " --server_http_full_path_location={0}".format(server_http_location_path)

        if get_env("OS_PATCHES") == "true":
            autoinstall_command += " --with_os_patches_upgrade={0}".format(get_env("OS_PATCHES_PATH_UPGRADE", OS_PATCHES_UPGRADE))
        if get_env("UPGRADE_3PP") == "true":
            autoinstall_command += " --upgrade_3pp"
        if get_env("RESTORE_OPTION") == "true":
            autoinstall_command += " --restore-from-upgrade"
        if get_env("RSYSLOG_UPDATE") == "true":
            autoinstall_command += " --update-rsyslog8"

        _, _, rc = self.run_command_local(autoinstall_command)
        if rc != 0:
            sys.exit(1)

    def run_autoexpand(self):
        """
        Section to run autoupgrade code
        Generate the command arguments to run autoupgrade.
        """
        autoinstall_code = self.job_details["autoinstall_tarball_nexus_link"] + "autoinstall.py"
        autoinstall_command = "{0} {1}".format(self.python_command, autoinstall_code)
        autoinstall_command += " {0}".format(get_env("EXPAND_METHOD", "-elc"))
        autoinstall_command += " --install_type={0}".format(get_env("installType", "cloud"))
        autoinstall_command += " --install_option={0}".format(get_env("deployType", "CLI"))

        autoinstall_command += " --expand_script={0}/{1}".format(self.job_details["autoinstall_tarball_nexus_link"], get_env("expansionScript"))

        if get_env("litpClusterFile"):
            autoinstall_command += " --cluster_file={0}/{1}".format(self.job_details["autoinstall_tarball_nexus_link"], get_env("litpClusterFile"))

        # TODO: I think this is not used, but needs to be removed from
        # autoinstall first if that is the case.
        server_http_location_path = get_env("server_http_location_path",
                                            default=self.job_details["autoinstall_dir"] + "/ai_tools/")
        self.create_dir(server_http_location_path)
        autoinstall_command += " --server_http_full_path_location={0}".format(
            server_http_location_path)
        if get_env("RESTORE_OPTION") == "true":
            autoinstall_command += " --restore-from-expand"

        if get_env("plan_monitor_script"):
            autoinstall_command += " --plan_monitor_script={0}/{1}"\
                .format(self.job_details["autoinstall_tarball_nexus_link"],
                        get_env("plan_monitor_script"))

        _, _, rc = self.run_command_local(autoinstall_command)
        if rc != 0:
            sys.exit(1)

    def run_backup_restore(self):
        """
        Section to run autoupgrade code
        Generate the command arguments to run autoupgrade.
        """
        autoinstall_code = self.job_details["autoinstall_tarball_nexus_link"] + "autoinstall.py"
        autoinstall_command = "{0} {1}".format(self.python_command, autoinstall_code)
        autoinstall_command += " {0}".format(get_env("BUR_METHOD", "-lbr"))
        autoinstall_command += " --install_type={0}".format(get_env("installType", "cloud"))
        #autoinstall_command += " --install_option={0}".format(get_env("deployType", "CLI"))

        if get_env("litpClusterFile"):
            autoinstall_command += " --cluster_file={0}/{1}".format(self.job_details["autoinstall_tarball_nexus_link"], get_env("litpClusterFile"))

        # TODO: I think this is not used, but needs to be removed from
        # autoinstall first if that is the case.
        server_http_location_path = get_env("server_http_location_path",
                                            default=self.job_details["autoinstall_dir"] + "/ai_tools/")
        self.create_dir(server_http_location_path)
        autoinstall_command += " --server_http_full_path_location={0}".format(
            server_http_location_path)

        _, _, rc = self.run_command_local(autoinstall_command)
        if rc != 0:
            sys.exit(1)

    def run_kgb_job(self):
        """
        Section to run kgb rpm upgrades and testware test cases
        """
        host_prop = self.job_details["host_properties_dir"] + "/{0}".format(get_env("hostsPropFileName", "cloud_host.properties"))
        kgb_pkg_update_command = "{0} {1} {2}".format(self.python_command, self.job_details["kgb_rpm_update_file"], host_prop)
        for pkg in job_details["litp_package_nexus_links"].split(","):
            name = pkg.split("__SPL__")
            print "#######################################"
            print "Updating rpm for: ", name[1]
            print "#######################################"
            run_cmd = kgb_pkg_update_command + " " + name[0]
            _, _, rc = self.run_command_local(run_cmd)
            if rc != 0:
                sys.exit(1)
        result = self.run_testware_job(self.job_details["litp_package_testware_nexus_links"], "testware-results", "testware_pkgs")
        return result

    def run_kgb_hw_snapshot_creation(self):
        """
        Run script which creates snapshots manually outside of LITP
        """
        host_prop = self.job_details["host_properties_dir"] + "/{0}".format(get_env("hostsPropFileName", "cloud_host.properties"))
        kgb_create_snap_command = "{0} {1} {2} create_snapshot".format(self.python_command, self.job_details["kgb_snapshot_file"], host_prop)
        _, _, rc = self.run_command_local(kgb_create_snap_command)
        if rc != 0:
            sys.exit(1)

    def run_kgb_hw_snapshot_restore(self):
        """
        Run script which restores snapshots manually outside of LITP
        """
        host_prop = self.job_details["host_properties_dir"] + "/{0}".format(get_env("hostsPropFileName", "cloud_host.properties"))
        kgb_restore_snap_command = "{0} {1} {2} restore_snapshot".format(self.python_command, self.job_details["kgb_snapshot_file"], host_prop)
        _, _, rc = self.run_command_local(kgb_restore_snap_command)
        if rc != 0:
            sys.exit(1)

    def run_rpm_replace_job(self):
        """
        Section to run rpm upgrades
        """
        host_prop = self.job_details["host_properties_dir"] + "/{0}".format(get_env("hostsPropFileName", "cloud_host.properties"))
        kgb_pkg_update_command = "{0} {1} {2}".format(self.python_command, self.job_details["kgb_rpm_update_file"], host_prop)
        for pkg in job_details["litp_package_replace_nexus_links"].split(","):
            name = pkg.split("__SPL__")
            print "#######################################"
            print "Updating rpm for: ", name[1]
            print "#######################################"
            run_cmd = kgb_pkg_update_command + " " + name[0]
            _, _, rc = self.run_command_local(run_cmd)
            if rc != 0:
                sys.exit(1)

    def run_black_rpm_replace_job(self):
        """
        Section to run rpm upgrades
        """
        host_prop = self.job_details["host_properties_dir"] + "/{0}"\
            .format(get_env("hostsPropFileName", "cloud_host.properties"))
        kgb_pkg_update_command = "{0} {1} {2}"\
            .format(self.python_command,
                    self.job_details["black_rpm_update_file"], host_prop)

        rpms_not_updated = list()

        print "#######################################"
        print "Updating black rpms: "
        for pkg in job_details["black_rpm_package_list_local"].split(","):
            name = pkg.split("/")[-1]
            print "   {0}".format(name)
        print "#######################################"
        rpm_packages = job_details["black_rpm_package_list_local"]

        run_cmd = kgb_pkg_update_command + " " + rpm_packages
        stdout, stderr, rc = self.run_command_local(run_cmd)

        if rc != 0:
            sys.exit(1)

        if 'does not update installed package' in " ".join(stdout):
            rpms_not_updated.append(name)

        if rpms_not_updated:
            print "ERROR: RPMS not updated because a newer version already exists on the VAPP"
            print "Refresh your base VAPP to an older ISO and try again"
            sys.exit(1)

    def add_test_runner_options(self, run_cmd):
        """
        Method to add test runner options from env variables
        """

        if get_env("installType") == "physical":
            run_cmd += " --include-physical"
        else:
            run_cmd += " --add-local-nas"

        if get_env("runBeta")== "true":
            run_cmd += " --run-non-reg"
        if get_env("reportOnlyRun") == "true":
            run_cmd += " --report-tests-run"
        if get_env("includeCDBOnly") == "true":
            run_cmd += " --include-cdb-only"
        if get_env("includeKGBOnly") == "true":
            run_cmd += " --include-kgb-only"
        if get_env("includeKGBPhysical") == "true":
            run_cmd += " --include-kgb-physical-only"
        if get_env("includeKGBOther") == "true":
            run_cmd += " --include-kgb-only"
        if get_env("includeBackupRestoreOnly") == "true":
            run_cmd += " --include-bur-tests-only"
        if get_env("vmImage") == "true":
            run_cmd += " --copy-vm-image={0}".format(self.job_details["litp_testware_tools_directory"])
        if not get_env("stopFail"):
            run_cmd += " --continue-on-fail"
        if get_env("stopFail") != "true":
            run_cmd += " --continue-on-fail"
        if get_env("includeExpansion"):
            run_cmd += " --include-expansion"
        if self.job_details["litp_package_nexus_links"]:
            run_cmd += " --add-to-tms"
        if get_env("addTMS") == "true":
            run_cmd += " --add-to-tms"
        if get_env("excludeDB") == "true":
            run_cmd += " ----exclude_db"
        if get_env("excludeSFS") == "true":
            run_cmd += " --ignore-sfs-only"
        if get_env("excludeVA") == "true":
            run_cmd += " --ignore-va-only"

        return run_cmd

    def run_testware_job(self, testw_files, results_dir_name, test_case_dir):
        """
        Section to run given testware test cases
        """
        test_runner_command = "{0} {1}".format(self.python_command, self.job_details["test_runner_file"])
        combined = False
        host_prop = self.job_details["host_properties_dir"] + "/{0}".format(get_env("hostsPropFileName", "cloud_host.properties"))
        run_cmd = None
        if get_env("COMBINE_TESTWARE_RUN_REPORT")  == "true":
            combined = True
            print ""
            print "#######################################"
            print "Running testware for: "
            for testw in testw_files.split(","):
                print "    {0}".format(testw.split("__SPL__")[1])
            print "#######################################"
            print ""
            run_cmd = test_runner_command + " -rs" + " --test-dir={0}".format(self.job_details[test_case_dir]) + " --results-dir={0}/{1}".format(self.results_dir, results_dir_name) + " --test-type={0}".format(get_env("testTags", "all").replace(" ", "")) + " --connection-file={0}".format(host_prop) + " --utils-dir={0}".format(self.job_details["test_utils_directory"]) + " --cdb-regression-run" + " --create-allure-report"
            run_cmd = self.add_test_runner_options(run_cmd)
            stdout, _, rc = self.run_command_local(run_cmd)
            if rc != 0:
                sys.exit(1)
            print "INFO: Test runner has complete"
            failed = False
            error = False
            skipped = False
            for line in stdout:
                if "0 test cases failed" == line:
                    failed = True
                if "0 test cases had errors" == line:
                    error = True
                if "0 test cases were skipped" == line:
                    skipped = True

            if failed and error and skipped:
                return True
            print "ERROR: Test Runner has failures, exit 1"
            return False
        if not combined:
            failcount = 0
            for testw in testw_files.split(","):
                name = testw.split("__SPL__")
                print ""
                print "#######################################"
                print "Running testware for: ", name[1]
                print "#######################################"
                print ""
                # FIND PYTHON TEST DIR
                run_cmd = test_runner_command + " -rs" + " --test-dir={0}".format(name[0]) + " --results-dir={0}/{1}-results".format(self.results_dir, name[1]) + " --test-type={0}".format(get_env("testTags", "all").replace(" ", "")) + " --connection-file={0}".format(host_prop) + " --utils-dir={0}".format(self.job_details["test_utils_directory"]) + " --create-allure-report"
                run_cmd = self.add_test_runner_options(run_cmd)
                stdout, _, rc = self.run_command_local(run_cmd)
                if rc != 0:
                    sys.exit(1)
                print "INFO: Test runner has complete"
                failed = False
                error = False
                skipped = False
                for line in stdout:
                    if "0 test cases failed" == line:
                        failed = True
                    if "0 test cases had errors" == line:
                        error = True
                    if "0 test cases were skipped" == line:
                        skipped = True

                if failed and error and skipped:
                    continue
                failcount += 1
            if failcount == 0:
                return True
            print "ERROR: Test Runner has failures, exit 1"
            return False

    def print_dict(self):
        """
        print info
        """

        print ""
        print "--------------------------------------------------------------------"
        print ""
        for line in self.job_details:
            if self.job_details[line]:
                print line, " : ", self.job_details[line]
        print ""
        print "--------------------------------------------------------------------"
        print ""


def get_env(key, default=None):
    """
    Get a variable from the JSON dictionary if json options are used otherwise
    get the value from an environment variable.
    """
    if USE_JSON:
        if key in JSON_DICT:
            return JSON_DICT[key]
        else:
            return os.getenv(key, default)
    else:
        return os.getenv(key, default)


USE_JSON = False
PHASE = ""
JSON_FILE = "env.json"
force_install = False
force_upgrade = False
force_expand = False
force_restore = False
only_test = False

for arg in sys.argv:
    if arg == "-use_json_options":
        USE_JSON = True
    if "-phase=" in arg:
        PHASE = arg.split('=')[-1]
    if "-file_name=" in arg:
        JSON_FILE = arg.split('=')[-1]
    if '--install' in arg:
        force_install = True
    if '--upgrade' in arg:
        force_upgrade = True
    if '--expand' in arg:
        force_expand = True
    if '--restore' in arg:
        force_restore = True
    if '--only-test' in arg:
        only_test = True

if USE_JSON and not PHASE:
    print "ERROR: -phase option must be supplied with -use_json_options"
    sys.exit(1)
if USE_JSON:
    with open(JSON_FILE, 'r') as json_file:
        JSON_DICT = json.load(json_file)
        # convert bools to str in dict.
        for key, value in JSON_DICT.items():
            if type(value) == bool:
                JSON_DICT[key] = str(value).lower()


job_details = dict()
##INSTALL
job_details["litp_iso_version"] = None
if get_env("litp_iso_version")  and not force_upgrade \
        and not force_expand \
        and not force_restore:
    job_details["litp_iso_version"] = get_env("litp_iso_version")

#EXPAND
job_details["expansionScript"] = None
if get_env("expansionScript") and not force_install \
        and not force_upgrade \
        and not force_restore:
    job_details["expansionScript"] = get_env("expansionScript")

#BACKUP_RESTORE
job_details["litp_backup_restore"] = None
if get_env("litp_backup_restore") and not force_install \
        and not force_upgrade \
        and not force_expand:
    job_details["litp_backup_restore"] = get_env("litp_backup_restore")

#UPGRADE
job_details["litp_upgrade_iso_version"] = None
if get_env("litp_upgrade_iso_version")  and not force_install \
        and not force_expand \
        and not force_restore:
    job_details["litp_upgrade_iso_version"] = get_env("litp_upgrade_iso_version")

job_details["local_autoinstall"] = get_env("local_autoinstall")
job_details["litp_iso_nexus_link"] = get_env("litp_iso_nexus_link")
job_details["litp_testware_utils_version"] = get_env("litp_testware_utils_version")
job_details["custom_testware_utils"] = get_env("custom_testware_utils")
job_details["litp_upgrade_iso_nexus_link"] = get_env("litp_upgrade_iso_nexus_link")
job_details["autoinstall_tarball_nexus_link"] = get_env("autoinstall_tarball_nexus_link")
job_details["ipmi_tool_nexus"] = get_env("ipmi_tool_nexus")
job_details["black_rpm_package_list_local"] = get_env("black_rpm_package_list_local")
job_details["litp_package_nexus_links"] = get_env("litp_package_nexus_links")
job_details["litp_package_replace_nexus_links"] = get_env("litp_package_replace_nexus_links")
job_details["litp_package_testware_nexus_links"] = get_env("litp_package_testware_nexus_links")
job_details["litp_testware_other_nexus_links"] = get_env("litp_testware_other_nexus_links")
job_details["litp_testware_tools_nexus_links"] = get_env("litp_testware_tools_nexus_links")
job_details["litp_testware_tools_nexus_links"] = get_env("litp_testware_tools_nexus_links")

# Disable output buffering to receive the output instantly
sys.stdout = os.fdopen(sys.stdout.fileno(), "w", 0)
sys.stderr = os.fdopen(sys.stderr.fileno(), "w", 0)



# Check conflicting arguments were not provided.
if job_details["litp_iso_version"]  and job_details["litp_package_nexus_links"]:
    print "ERROR: Cannot run Autoinstall and KGB in the same job, exiting"
    sys.exit(1)
if job_details["litp_upgrade_iso_version"] and job_details["litp_package_nexus_links"]:
    print "ERROR: Cannot run Autoinstall and KGB in the same job, exiting"
    sys.exit(1)

mytools = ToolsDownload(job_details)

if 'rhel-only' in arg:
    mytools.download_given_tools(rhel_only=True)
    result_kgb_tw = True
    result_tw = True
    result_tw_other = True
    mytools.run_autoinstall()
else:
    mytools.download_given_tools()
    mytools.print_dict()
    result_kgb_tw = True
    result_tw = True
    result_tw_other = True

    #INSTALL
    if job_details["litp_iso_version"]:
        mytools.run_autoinstall(only_test)
    if job_details["litp_upgrade_iso_version"]:
        mytools.run_autoupgrade()
    if job_details["expansionScript"]:
        mytools.run_autoexpand()
    if job_details["litp_backup_restore"]:
        mytools.run_backup_restore()
    if get_env("kgbSnapshot", "false") == "true":
        mytools.run_kgb_hw_snapshot_creation()
    if job_details["black_rpm_package_list_local"]:
        mytools.run_black_rpm_replace_job()
    if job_details["litp_package_replace_nexus_links"]:
        mytools.run_rpm_replace_job()
    if job_details["litp_package_nexus_links"]:
        if not job_details["litp_package_testware_nexus_links"]:
            print "ERROR: No testware given/found for KGB run, exiting"
            sys.exit(1)
        result_kgb_tw = mytools.run_kgb_job()
    if job_details["litp_package_testware_nexus_links"] and not job_details["litp_package_nexus_links"]:
        result_tw = mytools.run_testware_job(job_details["litp_package_testware_nexus_links"], "testware-results", "testware_pkgs")
    if job_details["litp_testware_other_nexus_links"]:
        result_tw_other = mytools.run_testware_job(job_details["litp_testware_other_nexus_links"], "testware-other-results", "testware_pkgs_other")
    if get_env("kgbSnapshot", "false") == "true":
        mytools.run_kgb_hw_snapshot_restore()


if not result_kgb_tw or not result_tw or not result_tw_other:
    print "---> ", result_kgb_tw
    print "---> ", result_tw
    print "---> ", result_tw_other
    sys.exit(1)
sys.exit(0)

