#!/usr/bin/bash

# COPYRIGHT Ericsson 2020
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.

# @since:     June 2020
# @author:    Laurence Canny
# @summary:   This script is based off build_rhel7_litp_iso.sh in utils/bash-utils
#             dRHEL7_7 branch. Check the dRHEL7_7 branch for all of the litp and
#             3PP plugins to detect code changes to any of the plugins.
#             If a code change is detected build, install and run automated
#             tests against a new litp iso.

BASENAME=/bin/basename
ECHO=/bin/echo
EGREP=/usr/bin/egrep
GIT=/usr/bin/git
GERRIT_PORT=29418
GERRIT="gerrit.ericsson.se"
GREP=/usr/bin/grep
MKDIR=/usr/bin/mkdir
SED=/bin/sed

SCRIPTNAME=$("${BASENAME}" "${0}")

function log_msg()
{
    MSG=$1
    CALLER="${FUNCNAME[1]}"
    NOW=$(date +%H.%M.%S)

    if [ "${CALLER}" = 'exit_on_error' ]
    then
        MKR='****'
    else
        MKR='----'
    fi
    ${ECHO} "${MKR} ${SCRIPTNAME}: ${NOW}: ${CALLER}: ${MSG} ${MKR}"
}

function clone_repo()
{
   REPO=$1

   GIT_PROJECT="LITP/${REPO}"
   if [ -n "${NON_STANDARD_GIT_PROJECTS[${REPO}]}" ]
   then
       GIT_PROJECT="${NON_STANDARD_GIT_PROJECTS[${REPO}]}"
   fi
   # ldu clone doesn't work because ssh keys don't work from docker container
   # so git clone from gerrit

   log_msg "Cloning ${REPO}"
   ( "${GIT}" clone ssh://"${XID}"@"${GERRIT}":"${GERRIT_PORT}"/"${GIT_PROJECT}" && \
    scp -p -P "${GERRIT_PORT}" "${XID}"@"${GERRIT}":hooks/commit-msg "${REPO}"/.git/hooks/ ) || \
   exit_on_error "clone_repo failed for repo: ${REPO}"

   return 0
}

function setup_repo()
{
   REPO=$1
   REPO_WORKSPACE=$2

   cd "${REPO_WORKSPACE}"
   if [ ! -d "${REPO}" ]
   then
       clone_repo "${REPO}"
   fi
   cd "${REPO}"
   checkout_and_refresh_branch "${REPO}"
   cd "${BASEDIR}"

   return 0
}

function setup_plugins()
{
   create_dir "${LITP_WORKSPACE}"

   REPOS=$(litp_docker_exec ldu list_all_repos | "${EGREP}" -v '^(ERIClitpdocs$|^integration)$')
   if [ "${PIPESTATUS[0]}" -ne 0 ]
   then
       exit_on_error "setup_plugins: ldu list_all_repos failed"
   fi

   for REPO in ${REPOS} LITP_iso;
   do
       if [ "${REPO}" == "LITP_iso" ]
       then
           DIR=${BASEDIR}
       else
           DIR=${LITP_WORKSPACE}
       fi
       setup_repo "${REPO}" "${DIR}"
   done

   return 0
}

function git_reset_to_origin ()
{
    REPO=$1
    BRANCH=$2
    TARGET=origin/"${BRANCH}"

    log_msg "Resetting ${REPO} hard to ${TARGET}"
    "${GIT}" reset --hard "${TARGET}" || \
    exit_on_error "git_reset_to_origin: Failed to reset ${BRANCH} to ${TARGET}"

    return 0
}

function git_merge_with_origin()
{
    REPO=$1
    BRANCH=$2
    TARGET=origin/"${BRANCH}"

    log_msg "Merging ${REPO} ${TARGET}"
    "${GIT}" merge "${TARGET}" || \
    exit_on_error "git_merge_with_origin: Failed to merge ${BRANCH} with $(
    )${TARGET}. Resolve conflicts manually."

    return 0
}

function checkout_and_refresh_branch()
{

   REPO=$1
   BRANCH=""
   ALTERNATE_BRANCH=""
   RHEL76_BRANCH="dRHEL7_6"
   RHEL77_BRANCH="dRHEL7_7"
   MASTER="master"

   "${GIT}" fetch || exit_on_error "checkout_and_refresh_branch: Git fetch failed"

   if [ -n "${ALTERNATE_BRANCH}" ] && branch_exists "${ALTERNATE_BRANCH}"; then
       BRANCH=${ALTERNATE_BRANCH}
   elif branch_exists "${RHEL77_BRANCH}"; then
       BRANCH=${RHEL77_BRANCH}
   elif branch_exists "${RHEL76_BRANCH}"; then
       BRANCH=${RHEL76_BRANCH}
   else
       BRANCH=${MASTER}
   fi

   log_msg "Checking out ${REPO} branch ${BRANCH}"
   "${GIT}" checkout "${BRANCH}"

   git_merge_with_origin "${REPO}" "${BRANCH}"

   return 0
}

function branch_exists()
{
   BRANCH=$1
   if ${GIT} branch -a | ${SED} 's/\s*//' | ${GREP} '^(remotes/origin/${BRANCH})$'; then
       return 0
   fi
   return 1
}

function create_dir()
{
  DIR_NAME=$1

  [ ! -d "${DIR_NAME}" ] && { "${MKDIR}" --parents "${DIR_NAME}" || \
  exit_on_error "create_dir for dir: ${DIR_NAME} failed"; }
}

function setup_3pps()
{

  create_dir "${THREEPP_WORKSPACE}"

  setup_repo LITP_iso "${BASEDIR}"
  for REPO in "${!THREE_PPS[@]}";
  do
      log_msg "Setting up ${REPO} in ${THREEPP_WORKSPACE}"
      setup_repo "${REPO}" "${THREEPP_WORKSPACE}"
  done

  return 0
}

function copy_extr_3pp_rpms {

  DESTINATION=$1
  for REPO in "${!THREE_PPS[@]}";
  do
      cd "${THREEPP_WORKSPACE}/${REPO}"
      for CXP in ${THREE_PPS[${REPO}]};
      do
          RPM=$(find . -type f -name "${CXP}*.rpm" | grep -v 'src.rpm' | head -1)
          cp "${RPM}" "${DESTINATION}" || \
          exit_on_error "copy_extr_3pp_rpms: Copy of ${CXP} rpm ${RPM} to ${DESTINATION} failed"
      done
  done
  cd "${BASEDIR}"

  return 0
}

function exit_on_error()
{
  ERROR_MSG=$1

  log_msg "Failure: ${ERROR_MSG}"
  exit 1
}

# ****************************
# Main
# ****************************
if [ -z "${BASEDIR}" ]
then
   BASEDIR="${WORKSPACE}"
fi

# If BASEDIR is still empty, the script vars are not being set when called from
# a cron so need to ensure vars are set by sourcing bashrc
if [ -z "${BASEDIR}" ]
then
   . ~/.bashrc
   BASEDIR="${WORKSPACE}"
fi

BASEDIR="${BASEDIR%/}"
LITP_WORKSPACE="${BASEDIR}"/LITP_Plugins
THREEPP_WORKSPACE="${BASEDIR}"/LITP_3PPs

create_dir "${BASEDIR}"

. "${WORKSPACE}"/utils/dockerfilesRHEL7/scripts/docker_helpers_setup.sh
. "${WORKSPACE}"/utils/bash-utils/3pp_repo_data

setup_plugins
setup_3pps
