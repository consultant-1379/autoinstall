#!/bin/bash
#
# Sample LITP multi-blade deployment (SAN version)
#
# Usage:
#   deploy_multiblade_san.sh <CLUSTER_SPEC_FILE>
#
if [ "$#" -lt 1 ]; then
    echo -e "Usage:\n  $0 <CLUSTER_SPEC_FILE>" >&2
    exit 1
fi

cluster_file="$1"
source "$cluster_file"

# Commenting out here for now to see if it responsible for some things falling into the stderr stream
# set -x

litp import /tmp/helloapps/ 3pp

# Create the md5 checksum file
/usr/bin/md5sum /var/www/html/images/rhel_7_image.qcow2 | cut -d ' ' -f 1 > /var/www/html/images/rhel_7_image.qcow2.md5
/usr/bin/md5sum /var/www/html/images/rhel_6_image.qcow2 | cut -d ' ' -f 1 > /var/www/html/images/rhel_6_image.qcow2.md5
/usr/bin/md5sum /var/www/html/images/image.qcow2 | cut -d ' ' -f 1 > /var/www/html/images/image.qcow2.md5

litp import /tmp/test_service-1.0-1.noarch.rpm /var/www/html/newRepo_dir
#litp import /tmp/helloapps/ 3pp

litpcrypt set key-for-root root 'Amm30n!!'
litpcrypt set key-for-sfs support "${sfs_password}"
