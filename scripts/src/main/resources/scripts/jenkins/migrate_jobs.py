"""
    COPYRIGHT Ericsson 2019
    The copyright to the computer program(s) herein is the property of
    Ericsson Inc. The programs may be used and/or copied only with written
    permission from Ericsson Inc. or in accordance with the terms and
    conditions stipulated in the agreement/contract under which the
    program(s) have been supplied.
    @since:     July 2020
    @author:    Luke Henry
    @summary:   Export, import, enable and/or disable Jenkins jobs under a
                Jenkins tab/view or containing a specified substring
"""

import os
import sys
import subprocess
import requests
import time

import_mode = True
export_mode = True
import_delay = 12
disable_import = False
disable_export = False
enable_export = False
invert_filter = False
config_directory = "."
cli_path = "/jnlpJars/jenkins-cli.jar"


def disableJobs(server, job_list):
    """
    Disables a passed in list of jobs on a specified Jenkins server

    :param str server: The Jenkins server URL
    :return: True if all jobs in list are disabled successfully
    :rtype: bool
    """
    jenkins_cli = requests.get(server + cli_path)
    if jenkins_cli.status_code // 10 != 20:
        print "ERROR: {0} returned {1} when downloading Jenkins CLI"\
            .format(server, jenkins_cli.status_code)
        return False

    open('jenkins-cli.jar', 'wb').write(jenkins_cli.content)

    for job in job_list:
        try:
            print "Disabling job {0} on {1}".format(job, server)

            cmd = 'java -jar jenkins-cli.jar '\
                  '-s {0} disable-job {1}'.format(server, job)
            with open(os.devnull, 'w') as fp:
                process = subprocess.Popen(cmd, stderr=subprocess.PIPE,
                                               stdout=fp, shell=True)
                process.wait()
        except Exception as e:
            print "ERROR: Failed to disable job {0} with exception: {1}"\
                .format(job, e)

    return True

def enableJobs(server, job_list):
    """
    Enables a passed in list of jobs on a specified Jenkins server

    :param str server: The Jenkins server URL
    :return: True if all jobs in list are enabled successfully
    :rtype: bool
    """
    jenkins_cli = requests.get(server + cli_path)
    if jenkins_cli.status_code // 10 != 20:
        print "ERROR: {0} returned {1} when downloading Jenkins CLI"\
            .format(server, jenkins_cli.status_code)
        return False

    open('jenkins-cli.jar', 'wb').write(jenkins_cli.content)

    for job in job_list:
        try:
            print "Enabling job {0} on {1}".format(job, server)

            cmd = 'java -jar jenkins-cli.jar '\
                  '-s {0} enable-job {1}'.format(server, job)
            with open(os.devnull, 'w') as fp:
                process = subprocess.Popen(cmd, stderr=subprocess.PIPE,
                                               stdout=fp, shell=True)
                process.wait()
        except Exception as e:
            print "ERROR: Failed to enable job {0} with exception: {1}"\
                .format(job, e)

    return True

def getJobs(from_server, view, job_filter):
    """
    Retrieves all jobs from a specified Jenkins server
    Optionally finds jobs only under a given view or that
    contain a particular substring

    :param str from_server: The Jenkins server URL
    :param str view: The view or tab to search under
    :param str job_filter: Filter out jobs that do not contain this substring
    :return: The list of jobs retrieved
    :rtype: list
    """
    jenkins_cli = requests.get(from_server + cli_path)
    if jenkins_cli.status_code // 10 != 20:
        print "ERROR: {0} returned {1} when downloading Jenkins CLI"\
            .format(from_server, jenkins_cli.status_code)
        return False

    open('jenkins-cli.jar', 'wb').write(jenkins_cli.content)

    try:
        cmd = 'java -jar jenkins-cli.jar '\
              '-s {0} list-jobs {1}'.format(from_server, view)
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True)
        process.wait()
        job_list = process.communicate()[0].split()
    except Exception as e:
        print "ERROR: Failed to list jobs in view {0} with exception: {1}"\
            .format(view, e)

    if job_filter:
        if invert_filter:
            job_list = [n for n in job_list if job_filter not in n]
        else:
            job_list = [n for n in job_list if job_filter in n]

    if len(job_list) == 0:
        print "WARNING: No jobs found in view {0} that match filter '{1}'"\
            .format(view, job_filter)

    return job_list

def migrateJobs(from_server, to_server, job_list):
    """
    Exports job configurations as XML from a Jenkins server and/or creates new
    jobs using XML configurations on a Jenkins server
    Optionally enable or disable jobs on export or import server

    :param str from_server: The Jenkins server URL to EXPORT from
    :param str to_server: The Jenkins server URL to IMPORT to
    :param str job_list: List containing names of jobs to be exported/imported
                         If importing, name is derived from XML config filename
    :return: True if export/import ran successfully
    :rtype: bool
    """
    if export_mode:
        for job in job_list:
            try:
                print "Exporting job {0} as {0}.xml".format(job)

                cmd = 'java -jar jenkins-cli.jar '\
                      '-s {0} get-job {1} > {2}/{1}.xml '\
                      .format(from_server, job, config_directory)
                with open(os.devnull, 'w') as fp:
                        process = subprocess.Popen(cmd, stderr=subprocess.PIPE,
                                                   stdout=fp, shell=True)
                        process.wait()
            except Exception as e:
                print "ERROR: Failed to retrieve job {0} with exception: {1}"\
                    .format(job, e)

    if enable_export:
        enableJobs(from_server, job_list)
    elif disable_export:
        disableJobs(from_server, job_list)

    if import_mode:
        jenkins_cli = requests.get(to_server + cli_path)
        if jenkins_cli.status_code // 10 != 20:
            print "ERROR: {0} returned {1} when downloading Jenkins CLI"\
                .format(to_server, jenkins_cli.status_code)
            return False

        open('jenkins-cli.jar', 'wb').write(jenkins_cli.content)

        configurations = os.listdir(config_directory)
        configurations = [n for n in configurations if '.xml' in n]
        configurations = map(lambda x: x[:-4], configurations)

        for job in configurations:
            print "Creating job {0} on {1}".format(job, to_server)
            try:
                cmd = 'java -jar jenkins-cli.jar '\
                      '-s {0} create-job {1} < {2}/{1}.xml'\
                      .format(to_server, job, config_directory)
                with open(os.devnull, 'w') as fp:
                    process = subprocess.Popen(cmd, stderr=subprocess.PIPE,
                                               stdout=fp, shell=True)
                    _, std_err = process.communicate()
                    if "already exists" in std_err:
                        print "Job {0} already exists on server {1}"\
                            .format(job, to_server)
                    elif "resource busy" in std_err:
                        print "{0}\n\nERROR: Failed to create job {1} on "\
                              "server {2}: server is busy. Stopping..."\
                            .format(std_err, job, to_server)
                        return False
                    else:
                        time.sleep(float(import_delay))
            except Exception as e:
                print "ERROR: Failed to create job {0} with exception: {1}"\
                    .format(job, e)

            if not "already exists" in std_err and disable_import:
                disableJobs(to_server, job.split())

    if disable_import and not import_mode:
        disableJobs(to_server, job_list)

def print_usage():
    usage = "USAGE:\npython migrate_jobs.py [--help|-h]\n"\
    "python migrate_jobs.py [--export_server=<JENKINS_URL>]\n"\
        "\tExport jobs to the working directory as <JOB_NAME>.xml"\
        " (all jobs will be exported if view or filter not provided)\n"\
    "python migrate_jobs.py [--import_server=<JENKINS_URL>]\n"\
        "\tImport job configurations in working dir to the Jenkins server\n"\
    "python migrate_jobs.py [--export_server=<JENKINS_URL>"\
    " --import_server=<JENKINS_URL>]\n"\
        "\tExport jobs from one Jenkins server and import to another\n\n" \
    + "OPTIONS:\n"\
    "--export\t"\
        "Export only; will not import jobs\n"\
    "--import\t"\
        "Import only; will not export jobs\n"\
    "--disable_export_jobs\t"\
        "Disables jobs on Jenkins immediately after exporting them\n"\
    "--disable_import_jobs\t"\
        "Disables jobs on Jenkins immediately after importing them\n"\
    "--enable_only\t"\
        "Enables matching jobs on export_server without exporting them\n"\
    "--disable_only\t"\
        "Disables matching jobs on export_server without exporting them\n"\
    "--view=<str:JENKINS_VIEW>\t"\
        "Export jobs from a specific view\n"\
    "--filter=<str:SUBSTRING>\t"\
        "Export jobs that contain a specific substring\n"\
    "--invert_filter=<str:SUBSTRING>\t"\
        "Export jobs that do not contain a specific substring\n"\
    "--dir=<str:FILEPATH>\t"\
        "Specify working directory for export and import\n"\
    "--import_delay=<int:SECONDS>\t"\
        "Delay between imports (avoids server busy error); default 12\n"\

    print usage

def main():
    from_server = ""
    to_server = ""
    view = ""
    job_filter = ""
    job_list = None

    global import_mode
    global export_mode
    global disable_import
    global disable_export
    global enable_export
    global config_directory
    global import_delay
    global invert_filter

    if len(sys.argv) < 2:
        print_usage()
        print "\n\nERROR: One or more arguments expected; see --help for usage"
        return False

    if sys.argv[1] == "--help" or sys.argv[1] == "-h":
        print_usage()
        return True

    for line in sys.argv:
        if "--export_server=" in line or "-es=" in line:
            from_server = line.split("=")[-1]
        if "--import_server=" in line or "-is=" in line:
            to_server = line.split("=")[-1]
        if "--view=" in line or "-v=" in line:
            view = line.split("=")[-1]
        if "--filter=" in line or "-f=" in line:
            job_filter = line.split("=")[-1]
        if "--invert_filter=" in line or "-if=" in line:
            job_filter = line.split("=")[-1]
            invert_filter = True
        if "--dir=" in line or "-d=" in line:
            config_directory = line.split("=")[-1]
        if "--import_delay=" in line:
            import_delay = line.split("=")[-1]
        if "--export" in line.split():
            import_mode = False
        if "--import" in line.split():
            export_mode = False
        if "--disable_export_jobs" in line.split():
            disable_export = True
        if "--disable_import_jobs" in line.split():
            disable_import = True
        if "--enable_only" in line.split():
            import_mode = False
            export_mode = False
            enable_export = True
        if "--disable_only" in line.split():
            import_mode = False
            export_mode = False
            disable_export = True

    if export_mode or enable_export or disable_export:
        job_list = getJobs(from_server, view, job_filter)

    migrateJobs(from_server, to_server, job_list)

    return True

if  __name__ == '__main__': main()