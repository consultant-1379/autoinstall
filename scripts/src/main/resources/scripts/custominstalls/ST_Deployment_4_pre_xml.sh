#!/bin/bash
#
# Script to set up MS in order for xml model to be loaded
#
# Usage:
#   ST_Deployment_4_pre_xml.sh <CLUSTER_SPEC_FILE>
#

if [ "$#" -lt 1 ]; then
    echo -e "Usage:\n  $0 <CLUSTER_SPEC_FILE>" >&2
    exit 1
fi

cluster_file="$1"
source "$cluster_file"

set -x

# Plugin Install
for (( i=0; i<${#rpms[@]}; i++)); do
    # import plugin
    litp import "/tmp/${rpms[$i]}" litp
    # install plugin
    expect /tmp/root_yum_install_pkg.exp "${ms_host}" "${rpms[$i]%%-*}"
done

# Import the ENM ISO 
expect /tmp/root_import_iso.exp "${ms_host}" "${enm_iso}"

# Import other packages
litp import /tmp/helloapps /var/www/html/hello_packages
litp import /tmp/lsb_pkg 3pp
litp import /tmp/test_service-1.0-1.noarch.rpm /var/www/html/newRepo_dir/

# Create md5 files
/usr/bin/md5sum /var/www/html/images/rhel7_image.qcow2     | cut -d ' ' -f 1 > /var/www/html/images/rhel7_image.qcow2.md5
/usr/bin/md5sum /var/www/html/images/base_image.qcow2 | cut -d ' ' -f 1 > /var/www/html/images/base_image.qcow2.md5

# Set up litpcrypt
litpcrypt set key-for-root root "${nodes_ilo_password}"
litpcrypt set key-for-sfs support "${nas_support_password}"

litp update -p /litp/logging -o force_debug=true
