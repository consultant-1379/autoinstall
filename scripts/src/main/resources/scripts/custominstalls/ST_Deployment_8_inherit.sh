#!/bin/bash
#
# Sample LITP multi-blade deployment ('local disk' version)
#
# Usage:
#   ST_Deployment_8.sh <CLUSTER_SPEC_FILE>
#
# VCS Cluster (sfha)
#
# See Deployment page in Confluence for details
#
# Note cs_initial_online=off, so all services will be offline until MNs are rebooted
#

function check_cs_initial_online_tasks {
	# Added as part of LITPCDS-11240
        # Checks correct number of tasks are created when cs_initial_online is both off and on
        cs_initial_online_on="litp update -p $1 -o cs_initial_online=on"
        cs_initial_online_off="litp update -p $1 -o cs_initial_online=off"
        sg_count=$(($(litp show -p ${1}services -l | wc -l) -1))
        $cs_initial_online_off
        litp create_plan
        task_states=$(litp show_plan -a | grep Tasks:)
        tasks=${task_states%%|*}
        tasks_count_off=${tasks##*:}

        $cs_initial_online_on
        litp create_plan
        task_states=$(litp show_plan -a | grep Tasks:)
        tasks=${task_states%%|*}
        tasks_count_on=${tasks##*:}
	# compare difference in number of tasks with the number of SG present.
	if [ "$(($tasks_count_on - $tasks_count_off))" == $sg_count ]        
                then echo "count of online SG tasks is correct"
        else
                echo "count of online SG tasks is Incorrect. Exit for investigation"
                exit
        fi
}


if [ "$#" -lt 1 ]; then
    echo -e "Usage:\n  $0 <CLUSTER_SPEC_FILE>" >&2
    exit 1
fi

cluster_file="$1"
source "$cluster_file"

set -x
#expect /tmp/root_import_iso.exp "${ms_host}" "${enm_iso}"
#litp load -p /software -f /tmp/enm_package_2.xml --merge

litp update -p /litp/logging -o force_debug=true
litpcrypt set key-for-root root "${nodes_ilo_password}"
litpcrypt set key-for-sfs support "${sfs_password}"



litp create -p /software/profiles/os_prof1 -t os-profile -o name=os-profile1 path=/var/www/html/6/os/x86_64/
litp create -t yum-repository -p /software/items/yum_osHA_repo -o name="osHA" base_url="http://ms1dot51/6/os/x86_64/HighAvailability"
litp create -p /deployments/d1 -t deployment

### 1 VCS Cluster - SFHA Type ###
litp create -t vcs-cluster -p /deployments/d1/clusters/c1 -o cluster_type=sfha low_prio_net=mgmt llt_nets=heartbeat1,heartbeat2 cluster_id="${vcs_cluster_id}" critical_service="SG_STvm2" app_agent_num_threads=20 default_nic_monitor=netstat

litp create -p /ms/services/cobbler -t cobbler-service -o pxe_boot_timeout=999
litp create -p /infrastructure/storage/storage_profiles/profile_1 -t storage-profile -o volume_driver=lvm #-o storage_profile_name=sp1
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1 -t volume-group -o volume_group_name=vg_root
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/root -t file-system -o type=ext4 mount_point=/ size=8G snap_size=70
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/swap -t file-system -o type=swap mount_point=swap size=2G snap_size=70
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/file1 -t file-system -o type=ext4 mount_point=/file1 size=1G snap_size=70
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/file2 -t file-system -o type=ext4 mount_point=/file2 size=1G snap_size=70
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/file3 -t file-system -o type=ext4 size=100M snap_size=70
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/internal -t physical-device -o device_name=hd0
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/pd1 -t physical-device -o device_name=hd1
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/pd2 -t physical-device -o device_name=hd2

for (( i=0; i<2; i++ )); do
        litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/VG1_FS$i -t file-system -o type=ext4 mount_point=/mp_VG1_FS$i size=200M snap_size=$((100-($i * 10)))
done

litp create -p /infrastructure/systems/sys1 -t blade -o system_name="${ms_sysname}"

# MODELLING DISK & STORAGE PROFILE ON THE MS
litp create -p /infrastructure/systems/sys1/disks/disk0 -t disk -o bootable="true" disk_part="false" name="ms_hd0" size="550G" uuid="${ms_disk_0_uuid}"

# STORAGE PROFILE - MS
litp create -p /infrastructure/storage/storage_profiles/ms_storage_profile -t storage-profile -o volume_driver="lvm"
# VG1
litp create -p /infrastructure/storage/storage_profiles/ms_storage_profile/volume_groups/vg1 -t volume-group -o volume_group_name="vg_root"
litp create -p /infrastructure/storage/storage_profiles/ms_storage_profile/volume_groups/vg1/file_systems/fs_root -t file-system -o mount_point="/" size="15G" snap_external="false" snap_size=70 type="ext4"
litp create -p /infrastructure/storage/storage_profiles/ms_storage_profile/volume_groups/vg1/file_systems/fs_home -t file-system -o mount_point="/home" size="6G" snap_external="false" snap_size=50 type="ext4" backup_snap_size=70
litp create -p /infrastructure/storage/storage_profiles/ms_storage_profile/volume_groups/vg1/file_systems/fs_var_www -t file-system -o mount_point="/var/www" size="70G" snap_external="false" snap_size=50 type="ext4" backup_snap_size=70
litp create -p /infrastructure/storage/storage_profiles/ms_storage_profile/volume_groups/vg1/file_systems/fs_var -t file-system -o mount_point="/var" size="18G" snap_external="false" snap_size=70 type="ext4" backup_snap_size=50
litp create -p /infrastructure/storage/storage_profiles/ms_storage_profile/volume_groups/vg1/file_systems/fs_data -t file-system -o mount_point="/var/lib/mysql" size="20G" snap_external="false" snap_size=1 type="ext4"
litp create -p /infrastructure/storage/storage_profiles/ms_storage_profile/volume_groups/vg1/file_systems/fs_unmounted -t file-system -o size="100M" snap_external="false" snap_size=20 type="ext4" backup_snap_size=30
litp create -p /infrastructure/storage/storage_profiles/ms_storage_profile/volume_groups/vg1/physical_devices/pd1 -t physical-device -o device_name="ms_hd0"

# STORAGE
# LVM Storage Profile
for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp create -p /infrastructure/systems/sys$(($i+2)) -t blade -o system_name="${node_sysname[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk0 -t disk -o name=hd0 size=27G bootable=true uuid="${node_disk_uuid0[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk1 -t disk -o name=hd1 size=2G bootable=false uuid="${node_disk_uuid1[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk3 -t disk -o name=hd2 size=3G bootable=false uuid="${node_disk_uuid2[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk2 -t disk -o name=hdvx1 size=20G bootable=false uuid="${vxvm_disk_uuid1}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk4 -t disk -o name=hdvx2 size=3G bootable=false uuid="${vxvm_disk_uuid2}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk5 -t disk -o name=hdvx3 size=3G bootable=false uuid="${vxvm_disk_uuid3}"
    litp create -p /infrastructure/systems/sys$(($i+2))/bmc -t bmc -o ipaddress="${node_bmc_ip[$i]}" username=root password_key=key-for-root
done

# VXVM Storage Profile
litp create -p /infrastructure/storage/storage_profiles/profile_2 -t storage-profile -o volume_driver=vxvm
litp create -t volume-group -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vxvg1 -o volume_group_name=vxvg1
litp create -t file-system -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vxvg1/file_systems/fs1 -o type=vxfs size=1G mount_point=/vxvm_vol1 snap_size=70 backup_snap_size=70
litp create -t physical-device -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vxvg1/physical_devices/pd1 -o device_name=hdvx1
litp create -t physical-device -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vxvg1/physical_devices/pd2 -o device_name=hdvx2 
litp create -t physical-device -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vxvg1/physical_devices/pd3 -o device_name=hdvx3

# VCS Cluster inherits the VXVM Profile 
litp inherit -p /deployments/d1/clusters/c1/storage_profile/sp2 -s /infrastructure/storage/storage_profiles/profile_2

# Fencing disks
litp create -t disk -p /deployments/d1/clusters/c1/fencing_disks/fd1 -o uuid="${fencing_disk_uuid1}" size=90M name=fencing_disk_1
litp create -t disk -p /deployments/d1/clusters/c1/fencing_disks/fd2 -o uuid="${fencing_disk_uuid2}" size=90M name=fencing_disk_2
litp create -t disk -p /deployments/d1/clusters/c1/fencing_disks/fd3 -o uuid="${fencing_disk_uuid3}" size=90M name=fencing_disk_3

# IPv4 Routes
litp create -p /infrastructure/networking/routes/route1 -t route -o subnet="0.0.0.0/0" gateway="${nodes_gateway}" #name=default 
litp create -p /infrastructure/networking/routes/route2 -t route -o subnet="${route2_subnet}" gateway="${nodes_gateway}" 
litp create -p /infrastructure/networking/routes/route3 -t route -o subnet="${route3_subnet}" gateway="${nodes_gateway}" 
litp create -p /infrastructure/networking/routes/route4 -t route -o subnet="${route4_subnet}" gateway="${nodes_gateway}"
litp create -p /infrastructure/networking/routes/route5 -t route -o subnet="${route_subnet_801}" gateway="${nodes_gateway_ext}"
litp create -p /infrastructure/networking/routes/traffic1_gw -t route -o subnet="${traf1gw_subnet}" gateway="${traf1_ip[1]}"
litp create -p /infrastructure/networking/routes/traffic2_gw -t route -o subnet="${traf2gw_subnet}" gateway="${traf2_ip[1]}"

# IPv6 Routes
litp create -t route6 -p /infrastructure/networking/routes/default_ipv6 -o subnet=::/0 gateway="${ipv6_835_gateway}"
# litp create -t route6 -p /infrastructure/networking/routes/ipv6_r1 -o subnet=${ipv6_836_subnet} gateway=${ipv6_834_gateway}

litp create -t network -p /infrastructure/networking/networks/mgmt -o name=mgmt subnet="${netwrk898}" litp_management=true
litp create -t network -p /infrastructure/networking/networks/data -o name=data subnet="${netwrk836}"
litp create -t network -p /infrastructure/networking/networks/netwrk898 -o name=netwrk898 subnet="${netwrk898}"
litp create -t network -p /infrastructure/networking/networks/netwrk834 -o name=netwrk834 subnet="${netwrk834}"
litp create -t network -p /infrastructure/networking/networks/netwrk835 -o name=netwrk835 subnet="${netwrk835}"
litp create -t network -p /infrastructure/networking/networks/netwrk836 -o name=netwrk836 subnet="${netwrk836}"
litp create -t network -p /infrastructure/networking/networks/netwrk837 -o name=netwrk837 subnet="${netwrk837}"

litp create -t network -p /infrastructure/networking/networks/heartbeat1 -o name=heartbeat1
litp create -t network -p /infrastructure/networking/networks/heartbeat2 -o name=heartbeat2

litp create -t network -p /infrastructure/networking/networks/ipv61 -o name=ipv61


# Cluster Level Aliases
litp create -t alias-cluster-config -p /deployments/d1/clusters/c1/configs/alias_config
litp create -t alias -p /deployments/d1/clusters/c1/configs/alias_config/aliases/master_cluster_alias -o alias_names="master-c-alias" address="10.10.10.100"
litp create -t alias -p /deployments/d1/clusters/c1/configs/alias_config/aliases/ldap_cluster_alias -o alias_names="ldap-c-alias" address="10.10.10.240"
litp create -t alias -p /deployments/d1/clusters/c1/configs/alias_config/aliases/mysql_queue_cluster_alias -o alias_names="mysql-c-alias,queue-c-alias" address="10.10.10.222"

litp create -t alias -p /deployments/d1/clusters/c1/configs/alias_config/aliases/cluster_duplicate_alias_names_01 -o alias_names="cluster-primary-alias-names-01,secondary-name" address="127.0.0.1"
litp create -t alias -p /deployments/d1/clusters/c1/configs/alias_config/aliases/cluster_duplicate_alias_names_02 -o alias_names="cluster-primary-alias-names-02,secondary-name,tertiary-name" address="127.0.0.1"
litp create -t alias -p /deployments/d1/clusters/c1/configs/alias_config/aliases/cluster_duplicate_alias_names_03 -o alias_names="cluster-primary-alias-names-03,secondary-name,tertiary-name" address="127.0.0.1"
# Finished Creating Cluster Level Aliases

# MS Level Aliases
litp create -t alias-node-config -p /ms/configs/alias_config

#ENM_DEP:Add 100+ MS Aliases
for (( i=0; i<100; i++ )); do
    litp create -t alias -p /ms/configs/alias_config/aliases/ms_alias_$i -o alias_names=msalias$i address=$ipv6_898_tp$i
done

litp create -t alias -p /ms/configs/alias_config/aliases/duplicate_alias_names_01 -o alias_names="primary-alias-names-01,secondary-name" address="127.0.0.1"
litp create -t alias -p /ms/configs/alias_config/aliases/duplicate_alias_names_02 -o alias_names="primary-alias-names-02,secondary-name,tertiary-name" address="127.0.0.1"
litp create -t alias -p /ms/configs/alias_config/aliases/duplicate_alias_names_03 -o alias_names="primary-alias-names-03,secondary-name,tertiary-name,quaternary-name" address="127.0.0.1"
litp create -t alias -p /ms/configs/alias_config/aliases/duplicate_alias_names_04 -o alias_names="primary-alias-names-04,secondary-name,tertiary-name,quaternary-name" address="127.0.0.1"

#NTP aliases on both MS and cluster:
for (( i=0; i<${#ntp_ip[@]}; i++ )); do
    litp create -t alias -p /ms/configs/alias_config/aliases/ntp_alias_$(($i+1)) -o alias_names=ntp-alias-$(($i+1)) address="${ntp_ip[i+1]}"
    litp create -t alias -p /deployments/d1/clusters/c1/configs/alias_config/aliases/ntp_alias_$(($i+1)) -o alias_names=ntp-alias-$(($i+1)) address="${ntp_ip[i+1]}"
done

# VCS Service Groups
#Create a SW Package
litp create -t package -p /software/items/ricci -o name=ricci release=87.el6 version=0.16.2 epoch=0
litp create -t package -p /software/items/httpd -o name=httpd release=69.el6 version=2.2.15 epoch=0
litp create -t package -p /software/items/luci -o name=luci release=93.el6 version=0.26.0 epoch=0
litp create -t package -p /software/items/dovecot -o name=dovecot release=22.el6 version=2.0.9 epoch=1
litp create -t package -p /software/items/cups -o name=cups release=79.el6 version=1.4.2 epoch=1

# Pin dependent packages to support version pinning of LSB Packages above
litp create -t package -p /software/items/httpd-tools -o name=httpd-tools version=2.2.15 release=69.el6 epoch=0
litp create -t package -p /software/items/cups-libs -o name=cups-libs version=1.4.2 release=79.el6 epoch=1

#jdk
litp create -t package -p /software/items/jdk -o name=EXTRserverjre_CXP9035480
litp inherit -p /ms/items/java -s /software/items/jdk

# ENM
#litp inherit -p /ms/items/model_repo -s /software/items/model_repo
#litp inherit -p /ms/items/model_package -s /software/items/model_package
#litp inherit -p /ms/items/ms_repo -s /software/items/ms_repo
#litp inherit -p /ms/items/common_repo -s /software/items/common_repo
#litp inherit -p /ms/items/db_repo -s /software/items/db_repo
#litp inherit -p /ms/items/services_repo -s /software/items/services_repo

litp create -t package -p /software/items/libguestfs-tools-c -o name=libguestfs-tools-c

litp import /tmp/helloapps/ 3pp
litp create -t package-list -p /software/items/pkg_list_empty -o name=pkg_list_empty version=8
litp inherit -p /ms/items/pkg_list_empty -s /software/items/pkg_list_empty
litp create -t package-list -p /software/items/pkg_list -o name=pkg_list1 version=5
litp create -t package -p /software/items/pkg_list/packages/3PP-azerbaijani-in-ear -o name=3PP-azerbaijani-in-ear
litp create -t package -p /software/items/pkg_list/packages/3PP-czech-hello -o name=3PP-czech-hello
litp create -t package -p /software/items/pkg_list/packages/3PP-dutch-hello -o name=3PP-dutch-hello
litp create -t package -p /software/items/pkg_list/packages/3PP-ejb-in-ear -o name=3PP-ejb-in-ear
litp create -t package -p /software/items/pkg_list/packages/3PP-english-hello -o name=3PP-english-hello
litp create -t package -p /software/items/pkg_list/packages/3PP-esperanto-in-ear -o name=3PP-esperanto-in-ear
litp create -t package -p /software/items/pkg_list/packages/3PP-finnish-hello -o name=3PP-finnish-hello
litp create -t package -p /software/items/pkg_list/packages/3PP-french-hello -o name=3PP-french-hello
litp create -t package -p /software/items/pkg_list/packages/3PP-french-in-ear -o name=3PP-french-in-ear
litp create -t package -p /software/items/pkg_list/packages/3PP-german-hello -o name=3PP-german-hello
litp create -t package -p /software/items/pkg_list/packages/3PP-german-in-ear -o name=3PP-german-in-ear
litp create -t package -p /software/items/pkg_list/packages/3PP-helloworld -o name=3PP-helloworld
litp create -t package -p /software/items/pkg_list/packages/3PP-hungarian-in-ear -o name=3PP-hungarian-in-ear
litp create -t package -p /software/items/pkg_list/packages/3PP-irish-hello -o name=3PP-irish-hello
litp create -t package -p /software/items/pkg_list/packages/3PP-irish-in-ear -o name=3PP-irish-in-ear
litp create -t package -p /software/items/pkg_list/packages/3PP-italian-hello -o name=3PP-italian-hello
litp create -t package -p /software/items/pkg_list/packages/3PP-italian-in-ear -o name=3PP-italian-in-ear
litp create -t package -p /software/items/pkg_list/packages/3PP-klingon-hello -o name=3PP-klingon-hello
litp create -t package -p /software/items/pkg_list/packages/3PP-norwegian-in-ear -o name=3PP-norwegian-in-ear
litp create -t package -p /software/items/pkg_list/packages/3PP-polish-hello -o name=3PP-polish-hello
litp create -t package -p /software/items/pkg_list/packages/3PP-portuguese-hello -o name=3PP-portuguese-hello
litp create -t package -p /software/items/pkg_list/packages/3PP-portuguese-hungarian-slovak-hello -o name=3PP-portuguese-hungarian-slovak-hello
litp create -t package -p /software/items/pkg_list/packages/3PP-romanian-hello -o name=3PP-romanian-hello
litp create -t package -p /software/items/pkg_list/packages/3PP-russian-hello -o name=3PP-russian-hello
litp create -t package -p /software/items/pkg_list/packages/3PP-serbian-hello -o name=3PP-serbian-hello
litp create -t package -p /software/items/pkg_list/packages/3PP-slovak-in-ear -o name=3PP-slovak-in-ear
litp create -t package -p /software/items/pkg_list/packages/3PP-spanish-hello -o name=3PP-spanish-hello
litp create -t package -p /software/items/pkg_list/packages/3PP-spanish-in-ear -o name=3PP-spanish-in-ear
litp create -t package -p /software/items/pkg_list/packages/3PP-swedish-hello -o name=3PP-swedish-hello
litp inherit -p /ms/items/pkg_list_on_ms -s /software/items/pkg_list


# Sentinel
litp create -t package -p /software/items/sentinel -o name="EXTRlitpsentinellicensemanager_CXP9031488"
litp inherit -p /ms/items/sentinel -s /software/items/sentinel
litp create -t service -p /ms/services/sentinel -o service_name="sentinel"
litp create -t service -p /software/services/sentinel -o service_name="sentinel"
litp inherit -p /software/services/sentinel/packages/sentinel -s /software/items/sentinel

# DIFF NAME SERVICE
litp create -p /software/items/diff_name_pkg -t package -o name="test_service_name-2.0-1"
litp create -p /software/services/diff_name_srvc -t service -o service_name="diff_service"
litp inherit -p /software/services/diff_name_srvc/packages/diff_name_pkg -s /software/items/diff_name_pkg

litp create -p /ms/services/diff_name_srvc -t service -o service_name="diff_service"
litp inherit -p /ms/services/diff_name_srvc/packages/diff_name_pkg -s /software/items/diff_name_pkg

# Create Failover VCS Service Group
litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/apachecs -o active=1 standby=1 name=vcs1 online_timeout=45 node_list='n1,n2' initial_online_dependency_list=cups,luci
litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/apachecs/ha_configs/conf1 -o status_interval=50 status_timeout=60 restart_limit=5 startup_retry_limit=2
litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/ricci -o active=1 standby=1 name=vcs4 online_timeout=70 node_list='n2,n1'
litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/ricci/ha_configs/conf1 -o status_interval=60 status_timeout=60 restart_limit=5 startup_retry_limit=2
litp create -t vcs-trigger -p /deployments/d1/clusters/c1/services/ricci/triggers/trig1 -o trigger_type=nofailover

# Create Parallel VCS Service Groups
litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/luci -o active=2 standby=0 name=vcs2 online_timeout=90 node_list='n1,n2' initial_online_dependency_list=ricci
litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/luci/ha_configs/conf1 -o status_interval=50 status_timeout=60 restart_limit=5 startup_retry_limit=2

litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/cups -o active=2 standby=0 name=vcs3 online_timeout=90 node_list='n1,n2'
litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/cups/ha_configs/conf1 -o status_interval=40 status_timeout=60 restart_limit=5 startup_retry_limit=2

# Create the LSB Service item type.
litp create -t service -p /software/services/httpd -o service_name=httpd
litp inherit -p /software/services/httpd/packages/pkg1 -s /software/items/httpd
litp inherit -p /deployments/d1/clusters/c1/services/apachecs/applications/httpd -s /software/services/httpd
litp create -t service -p /software/services/cups -o service_name=cups
litp inherit -p /software/services/cups/packages/pkg1 -s /software/items/cups
litp inherit -p /deployments/d1/clusters/c1/services/cups/applications/cups -s /software/services/cups
litp create -t service -p /software/services/luci -o service_name=luci
litp inherit -p /software/services/luci/packages/pkg1 -s /software/items/luci
litp inherit -p /deployments/d1/clusters/c1/services/luci/applications/luci -s /software/services/luci
litp create -t service -p /software/services/ricci -o service_name=ricci
litp inherit -p /software/services/ricci/packages/pkg1 -s /software/items/ricci
litp inherit -p /deployments/d1/clusters/c1/services/ricci/applications/ricci -s /software/services/ricci


# Create the networks
litp create -t network -p /infrastructure/networking/networks/traffic1 -o name=traffic1 subnet="${traf1_subnet}"
litp create -t network -p /infrastructure/networking/networks/traffic2 -o name=traffic2 subnet="${traf2_subnet}"

# Finished Creating VCS Cluster Service Groups
# 2 MS NIC
# MS - 4 eth - 2 bonds
litp create -t eth -p /ms/network_interfaces/if0 -o device_name=eth0 macaddress="${ms_eth0_mac}" master=bond0
litp create -t eth -p /ms/network_interfaces/if1 -o device_name=eth1 macaddress="${ms_eth1_mac}" master=bond0
litp create -t eth -p /ms/network_interfaces/if2 -o device_name=eth2 macaddress="${ms_eth2_mac}" master=bond1
litp create -t eth -p /ms/network_interfaces/if3 -o device_name=eth3 macaddress="${ms_eth3_mac}" master=bond1

litp create -t bond -p /ms/network_interfaces/b0 -o device_name='bond0' ipaddress="${ms_ip_898_bond}" ipv6address="${ms_ipv6_898_bond}" network_name=mgmt mode=1 miimon=100
litp create -t bond -p /ms/network_interfaces/b1 -o device_name='bond1' ipaddress="${ms_ip_836_bond}" ipv6address="${ms_ipv6_836_bond}" network_name=data mode=1 arp_interval=1250 arp_ip_target="10.44.86.129,10.44.86.130,10.44.86.131,10.44.86.132,10.44.86.133,10.44.86.134,10.44.86.135,10.44.86.136,10.44.86.137,10.44.86.138,10.44.86.139" arp_validate=backup arp_all_targets=any
#litp create -t vlan -p /ms/network_interfaces/bond0_898 -o device_name='bond0.898' ipaddress="${ms_ip_898}" ipv6address="${ms_ipv6_898}" network_name='netwrk898'
litp create -t vlan -p /ms/network_interfaces/bond1_835 -o device_name='bond1.835' ipaddress="${ms_ip_835}" ipv6address="${ms_ipv6_835}" network_name='netwrk835'
#litp create -t vlan -p /ms/network_interfaces/bond1_836 -o device_name='bond1.836' ipaddress="${ms_ip_836}" ipv6address="${ms_ipv6_836}" network_name='netwrk836'
litp create -t vlan -p /ms/network_interfaces/bond1_837 -o device_name='bond1.837' ipaddress="${ms_ip_837}" ipv6address="${ms_ipv6_837}" network_name='netwrk837'

# vlan on bridge - so that VM can use this network
litp create -t vlan -p /ms/network_interfaces/bond0_834 -o device_name='bond0.834' bridge=br834 
litp create -t bridge -p /ms/network_interfaces/br834 -o device_name='br834' network_name='netwrk834' ipaddress="${ms_ip_834}" ipv6address="${ms_ipv6_834}" network_name='netwrk834'

litp update -p /ms -o hostname="$ms_host"
# 5 MS Routes
litp inherit -p /ms/system -s /infrastructure/systems/sys1
litp inherit -p /ms/routes/route1 -s /infrastructure/networking/routes/route1
#litp inherit -p /ms/routes/route2 -s /infrastructure/networking/routes/route1 -o subnet="${route2_subnet}" gateway="${nodes_gateway}" #name=route2 
#litp inherit -p /ms/routes/route3 -s /infrastructure/networking/routes/route1 -o subnet="${route3_subnet}" gateway="${nodes_gateway}" #name=route3 
#litp inherit -p /ms/routes/route4 -s /infrastructure/networking/routes/route1 -o subnet="${route4_subnet}" gateway="${nodes_gateway}" #name=route4 
litp inherit -p /ms/routes/route5 -s /infrastructure/networking/routes/route1 -o subnet="${route_subnet_801}" gateway="${nodes_gateway_ext}" #name=route5 
litp inherit -p /ms/routes/default_ipv6 -s /infrastructure/networking/routes/default_ipv6
#litp inherit -p /ms/routes/ipv6_r1 -s /infrastructure/networking/routes/ipv6_r1

#SysCtl Parameters
# MS
litp create -t sysparam-node-config -p /ms/configs/sysctl
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_enm1 -o key="net.core.rmem_default" value="5242880"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_enm2 -o key="net.core.rmem_max" value="5242880"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_enm3 -o key="net.core.wmem_default" value="655360"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_enm4 -o key="net.core.wmem_max" value="655360"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_enm6 -o key=kernel.core_pattern value="/tmp/core.%e.pid%p.usr%u.sig%s.tim%t"

litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_ipv6_harding01 -o key="net.ipv6.conf.default.autoconf" value="0"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_ipv6_harding02 -o key="net.ipv6.conf.default.accept_ra" value="0"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_ipv6_harding03 -o key="net.ipv6.conf.default.accept_ra_defrtr" value="0"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_ipv6_harding04 -o key="net.ipv6.conf.default.accept_ra_rtr_pref" value="0"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_ipv6_harding05 -o key="net.ipv6.conf.default.accept_ra_pinfo" value="0"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_ipv6_harding06 -o key="net.ipv6.conf.default.accept_source_route" value="0"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_ipv6_harding07 -o key="net.ipv6.conf.default.accept_redirects" value="0"
  
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_ipv6_harding08 -o key="net.ipv6.conf.all.autoconf" value="0"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_ipv6_harding09 -o key="net.ipv6.conf.all.accept_ra" value="0"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_ipv6_harding10 -o key="net.ipv6.conf.all.accept_ra_defrtr" value="0"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_ipv6_harding11 -o key="net.ipv6.conf.all.accept_ra_rtr_pref" value="0"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_ipv6_harding12 -o key="net.ipv6.conf.all.accept_ra_pinfo" value="0"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_ipv6_harding13 -o key="net.ipv6.conf.all.accept_source_route" value="0"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_ipv6_harding14 -o key="net.ipv6.conf.all.accept_redirects" value="0"

### NTP ###
litp create -t ntp-service -p /software/items/ntp1 #-o name=ntp1
litp inherit -p /ms/items/ntp -s /software/items/ntp1
for (( i=0; i<${#ntp_ip[@]}; i++ )); do
    litp create -t ntp-server -p /software/items/ntp1/servers/server"$i" -o server=ntp-alias-$(($i+1))
done

# Create nodes
# 6 MNs NICs
for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1)) -t node -o hostname="${node_hostname[$i]}"
    # Creating Node Level Aliases
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/alias_config -t alias-node-config 
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/alias_config/aliases/master_node_alias -t alias -o alias_names="master-n-alias" address="10.10.10.10"

    litp create -t alias -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/alias_config/aliases/duplicate_alias_names_01 -o alias_names="primary-alias-names-01,secondary-name" address="127.0.0.1"
    litp create -t alias -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/alias_config/aliases/duplicate_alias_names_02 -o alias_names="primary-alias-names-02,secondary-name,tertiary-name" address="127.0.0.1"
    litp create -t alias -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/alias_config/aliases/duplicate_alias_names_03 -o alias_names="primary-alias-names-03,secondary-name,tertiary-name,quaternary-name" address="127.0.0.1"
    litp create -t alias -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/alias_config/aliases/duplicate_alias_names_04 -o alias_names="primary-alias-names-04,secondary-name,tertiary-name,quaternary-name" address="127.0.0.1"
    # Finished Creating Node Level Aliases
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/system -s /infrastructure/systems/sys$(($i+2))
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/os -s /software/profiles/os_prof1

    litp create -t eth -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if4 -o device_name=eth4 macaddress="${node_eth4_mac[$i]}" network_name=traffic1 ipaddress="${traf1_ip[$i]}" ipv6address="${traf1_ipv6[$i]}"
    litp create -t eth -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if5 -o device_name=eth5 macaddress="${node_eth5_mac[$i]}" network_name=traffic2 ipaddress="${traf2_ip[$i]}" ipv6address="${traf2_ipv6[$i]}"

    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/storage_profile -s /infrastructure/storage/storage_profiles/profile_1
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/ntp1 -s /software/items/ntp1
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/route1 -s /infrastructure/networking/routes/route1
#    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/route2 -s /infrastructure/networking/routes/route1 -o subnet="${route2_subnet}" gateway="${nodes_gateway}" #name=route2 
#    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/route3 -s /infrastructure/networking/routes/route1 -o subnet="${route3_subnet}" gateway="${nodes_gateway}" #name=route3
#    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/route4 -s /infrastructure/networking/routes/route1 -o subnet="${route4_subnet}" gateway="${nodes_gateway}" #name=route4
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/route5 -s /infrastructure/networking/routes/route1 -o subnet="${route_subnet_801}" gateway="${nodes_gateway_ext}" #name=route5
#  litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/route6 -s /infrastructure/networking/routes/route1 -o subnet="${route3_subnet}" gateway="${node_ip_898_bond[$i]}"
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/traffic1_gw -s /infrastructure/networking/routes/traffic1_gw
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/traffic2_gw -s /infrastructure/networking/routes/traffic2_gw
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/default_ipv6 -s /infrastructure/networking/routes/default_ipv6
    # litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/ipv6_r1 -s /infrastructure/networking/routes/ipv6_r1
    # Pin dependent packages to support version pinning of LSB Packages above
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/java -s /software/items/jdk
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/httpd-tools -s /software/items/httpd-tools
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/cups-libs   -s /software/items/cups-libs

    litp update -p /deployments/d1/clusters/c1/nodes/n$(($i+1)) -o node_id=$[$i+1]

    litp inherit -s /software/items/yum_osHA_repo -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/yum_osHA_repo

    # SysCtl Params
     litp create -t sysparam-node-config -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_enm1 -o key="net.core.rmem_default" value="5242880"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_enm2 -o key="net.core.rmem_max" value="5242880"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_enm3 -o key="net.core.wmem_default" value="655360"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_enm4 -o key="net.core.wmem_max" value="655360"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_enm6 -o key="kernel.core_pattern" value=/tmp/core.%e.pid%p.usr%u.sig%s.tim%t

     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_ipv6_harding01 -o key="net.ipv6.conf.default.autoconf" value="0"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_ipv6_harding02 -o key="net.ipv6.conf.default.accept_ra" value="0"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_ipv6_harding03 -o key="net.ipv6.conf.default.accept_ra_defrtr" value="0"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_ipv6_harding04 -o key="net.ipv6.conf.default.accept_ra_rtr_pref" value="0"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_ipv6_harding05 -o key="net.ipv6.conf.default.accept_ra_pinfo" value="0"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_ipv6_harding06 -o key="net.ipv6.conf.default.accept_source_route" value="0"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_ipv6_harding07 -o key="net.ipv6.conf.default.accept_redirects" value="0"
  
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_ipv6_harding08 -o key="net.ipv6.conf.all.autoconf" value="0"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_ipv6_harding09 -o key="net.ipv6.conf.all.accept_ra" value="0"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_ipv6_harding10 -o key="net.ipv6.conf.all.accept_ra_defrtr" value="0"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_ipv6_harding11 -o key="net.ipv6.conf.all.accept_ra_rtr_pref" value="0"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_ipv6_harding12 -o key="net.ipv6.conf.all.accept_ra_pinfo" value="0"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_ipv6_harding13 -o key="net.ipv6.conf.all.accept_source_route" value="0"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_ipv6_harding14 -o key="net.ipv6.conf.all.accept_redirects" value="0"

done


litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if0 -o device_name=eth0 macaddress="${node_eth0_mac[0]}" master=bond0 
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if6 -o device_name=eth6 macaddress="${node_eth6_mac[0]}" master=bond0 
litp create -t bond -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/b0 -o device_name='bond0' ipaddress="${node_ip_898_bond[0]}" ipv6address="${node_ipv6_898_bond[0]}" network_name=mgmt mode=1 arp_validate=active  arp_all_targets=any arp_interval=1250 arp_ip_target="10.44.235.1,10.44.235.2,10.44.235.3,10.44.235.4,10.44.235.5,10.44.235.6,10.44.235.7,10.44.235.8,10.44.235.9,10.44.235.10,10.44.235.11"
litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/bond0_834  -o device_name='bond0.834' network_name='netwrk834' ipv6address="${node_ipv6_834[0]}"  ipaddress="${node_ip_834[0]}" 
#litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/bond0_898  -o device_name='bond0.898' ipaddress="${node_ip_898[0]}" ipv6address="${node_ipv6_898[0]}" network_name='netwrk898'

litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if1 -o device_name=eth1 macaddress="${node_eth1_mac[0]}" master=bond1
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if7 -o device_name=eth7 macaddress="${node_eth7_mac[0]}" master=bond1 
litp create -t bond -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/b1 -o device_name='bond1' ipaddress="${node_ip_836_bond[0]}" ipv6address="${node_ipv6_836_bond[0]}" network_name=data mode=1 arp_interval=1250 arp_ip_target="10.44.86.129,10.44.86.130,10.44.86.131,10.44.86.132,10.44.86.133,10.44.86.134,10.44.86.135,10.44.86.136,10.44.86.137,10.44.86.138,10.44.86.139"
litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/bond1_835  -o device_name='bond1.835' ipaddress="${node_ip_835[0]}" ipv6address="${node_ipv6_835[0]}" network_name='netwrk835'
litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/bond1_837  -o device_name='bond1.837' ipaddress="${node_ip_837[0]}" ipv6address="${node_ipv6_837[0]}" network_name='netwrk837'
#litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/bond1_836  -o device_name='bond1.836' ipaddress="${node_ip_836[0]}" ipv6address="${node_ipv6_836[0]}" network_name='netwrk836'


litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if0 -o device_name=eth0 macaddress="${node_eth0_mac[1]}" master=bond0 
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if2 -o device_name=eth2 macaddress="${node_eth2_mac[1]}" master=bond0 
litp create -t bond -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/b0 -o device_name='bond0' ipaddress="${node_ip_898_bond[1]}" ipv6address="${node_ipv6_898_bond[1]}" network_name=mgmt mode=1 arp_validate=all arp_all_targets=any arp_interval=1250 arp_ip_target="10.44.235.1,10.44.235.2,10.44.235.3,10.44.235.4,10.44.235.5,10.44.235.6,10.44.235.7,10.44.235.8,10.44.235.9,10.44.235.10,10.44.235.11"
litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/bond0_834  -o device_name='bond0.834' ipaddress="${node_ip_834[1]}" ipv6address="${node_ipv6_834[1]}" network_name='netwrk834'
#litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/bond0_898  -o device_name='bond0.898' ipaddress="${node_ip_898[1]}" ipv6address="${node_ipv6_898[1]}" network_name='netwrk898'

litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if1 -o device_name=eth1 macaddress="${node_eth1_mac[1]}" master=bond1 
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if3 -o device_name=eth3 macaddress="${node_eth3_mac[1]}" master=bond1 
litp create -t bond -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/b1 -o device_name='bond1' ipaddress="${node_ip_836_bond[1]}" ipv6address="${node_ipv6_836_bond[1]}" network_name=data mode=1 arp_interval=1250 arp_ip_target="10.44.86.129,10.44.86.130,10.44.86.131,10.44.86.132,10.44.86.133,10.44.86.134,10.44.86.135,10.44.86.136,10.44.86.137,10.44.86.138,10.44.86.139"
litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/bond1_835  -o device_name='bond1.835' ipaddress="${node_ip_835[1]}" ipv6address="${node_ipv6_835[1]}" network_name='netwrk835'
litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/bond1_837  -o device_name='bond1.837' ipaddress="${node_ip_837[1]}" ipv6address="${node_ipv6_837[1]}" network_name='netwrk837'
#litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/bond1_836  -o device_name='bond1.836' ipaddress="${node_ip_836[1]}" ipv6address="${node_ipv6_836[1]}" network_name='netwrk836'



##### Firewalls #######

#cluster level

litp create -t firewall-cluster-config -p /deployments/d1/clusters/c1/configs/fw_config
litp create -t firewall-rule -p /deployments/d1/clusters/c1/configs/fw_config/rules/fw_vmhc -o 'name=300 vmhc' proto=tcp dport=12987 provider=iptables

# MS Firewall and Rules
litp create -t firewall-node-config -p /ms/configs/fw_config
litp create -p /ms/configs/fw_config/rules/fw_hyperic_server_in -t firewall-rule -o action=accept chain=INPUT dport=57004,57005 'name=112 hyperic tcp agent to server ports' proto=tcp state=NEW
 litp create -p /ms/configs/fw_config/rules/fw_hyperic_server_out -t firewall-rule -o action=accept chain=OUTPUT dport=57006 'name=113 hyperic tcp server to agent port' proto=tcp state=NEW
 litp create -p /ms/configs/fw_config/rules/fw_sfsudp -t firewall-rule -o action=accept dport=111,2049,4011,4001 'name=013 sfsudp' proto=udp state=NEW
 litp create -p /ms/configs/fw_config/rules/fw_sfstcp -t firewall-rule -o action=accept dport=111,2049,4011,4001 'name=012 sfstcp' proto=tcp state=NEW
 litp create -p /ms/configs/fw_config/rules/fw_vmmonitord -t firewall-rule -o action=accept dport=12987 'name=018 vmmonitord' proto=tcp state=NEW
 litp create -p /ms/configs/fw_config/rules/fw_dns -t firewall-rule -o action=accept dport=53 'name=021 DNS udp' proto=udp state=NEW
 litp create -p /ms/configs/fw_config/rules/fw_brs -t firewall-rule -o action=accept dport=1556,2821,4032,13724,13782 'name=022 backuprestore tcp' proto=tcp state=NEW
 litp create -p /ms/configs/fw_config/rules/fw_ntp -t firewall-rule -o action=accept dport=123 'name=029 NTP udp' proto=tcp state=NEW
 litp create -p /ms/configs/fw_config/rules/fw_dhcp_tcp -t firewall-rule -o action=accept dport=546,547,647,847 'name=030 DHCP tcp' proto=tcp state=NEW
 litp create -p /ms/configs/fw_config/rules/fw_dhcp_udp -t firewall-rule -o action=accept dport=546,547,647,847 'name=031 DHCP udp' proto=udp state=NEW
 litp create -p /ms/configs/fw_config/rules/fw_cobbler -t firewall-rule -o action=accept dport=25150,25151 'name=032 cobbler' proto=udp state=NEW
 litp create -p /ms/configs/fw_config/rules/fw_cobbler_tcp -t firewall-rule -o action=accept dport=25150,25151 'name=033 cobbler' proto=tcp state=NEW
 litp create -p /ms/configs/fw_config/rules/fw_nexus -t firewall-rule -o action=accept dport=8080,8443 'name=034 nexus tcp' proto=tcp state=NEW
 litp create -p /ms/configs/fw_config/rules/fw_lserv -t firewall-rule -o action=accept dport=5093 'name=035 lserv' proto=udp state=NEW
 litp create -p /ms/configs/fw_config/rules/fw_rpcbind -t firewall-rule -o action=accept dport=676 'name=036 rpcbind' proto=udp state=NEW
 litp create -p /ms/configs/fw_config/rules/fw_loop_back -t firewall-rule -o action=accept iniface=lo 'name=02 loop back' proto=all
 litp create -p /ms/configs/fw_config/rules/fw_http_allow_int -t firewall-rule -o action=accept provider=iptables dport=80 'name=106 allow http internal' proto=tcp state=NEW source=10.247.244.0/22
 litp create -p /ms/configs/fw_config/rules/fw_http_allow_stor -t firewall-rule -o action=accept dport=80 'name=102 allow http storage' proto=tcp state=NEW provider=iptables source=10.140.2.0/24
 litp create -p /ms/configs/fw_config/rules/fw_http_allow_serv -t firewall-rule -o action=accept dport=80 'name=103 allow http services' proto=tcp state=NEW provider=iptables source=10.151.9.128/26
 litp create -p /ms/configs/fw_config/rules/fw_http_allow_bkp -t firewall-rule -o action=accept dport=80 'name=104 allow http backup' proto=tcp state=NEW provider=iptables source=10.151.24.0/23
 litp create -p /ms/configs/fw_config/rules/fw_http_block -t firewall-rule -o action=accept dport=80 'name=105 drop http' proto=tcp state=NEW provider=iptables

# NODE Firewall and Rules
for (( i=0; i<${#node_sysname[@]}; i++ )); do

  litp create -t firewall-node-config -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config
  litp create -t firewall-rule -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config/rules/fw_nfsudp -o 'name=011 nfsudp' dport=53,111,2049,4001 proto=udp
  litp create -t firewall-rule -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config/rules/fw_nfstcp -o 'name=001 nfstcp' dport=53,111,2049,4001 proto=tcp
  litp create -t firewall-rule -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config/rules/fw_icmp -o name="100 icmp" proto="icmp"
  litp create -t firewall-rule -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config/rules/fw_icmpv6 -o name="101 icmpv6" proto="ipv6-icmp" provider=ip6tables
  litp create -t firewall-rule -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config/rules/fw_dhcpudp -o 'name=021 dhcpudp' dport=67,68 proto=udp
  litp create -t firewall-rule -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config/rules/fw_dhcptcp -o 'name=020 dhcp' dport=647 proto=tcp

done

# LLT Links
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if2 -o device_name=eth2 macaddress="${node_eth2_mac[0]}" network_name=heartbeat1 
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if6 -o device_name=eth6 macaddress="${node_eth6_mac[1]}" network_name=heartbeat1 
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if3 -o device_name=eth3 macaddress="${node_eth3_mac[0]}" network_name=heartbeat2 
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if7 -o device_name=eth7 macaddress="${node_eth7_mac[1]}" network_name=heartbeat2 

# FO SG1 #VIPs = 5x #AC(1) .......5 IPv4 + 5 IPv6 VIPs per Traffic1 Network, 5 IPv4 VIPs per Traffic2 Network
for (( i=1; i<6; i++ )); do

 litp create -t vip -p /deployments/d1/clusters/c1/services/apachecs/ipaddresses/ip${i} -o ipaddress="${traf1_vip[$(($i))]}"  network_name=traffic1
 litp create -t vip -p /deployments/d1/clusters/c1/services/apachecs/ipaddresses/ip$(($i+5)) -o ipaddress="${traf1_vip_ipv6[$(($i))]}"  network_name=traffic1
 litp create -t vip -p /deployments/d1/clusters/c1/services/apachecs/ipaddresses/ip$(($i+10)) -o ipaddress="${traf2_vip[$(($i))]}" network_name=traffic2

done

# PAR SG3 #VIPs = 2x #AC(2) ..........4 IPv4 + 4 IPv6 VIPs per Traffic1 Network, 4 IPv4 VIPs per Traffic2 Network
for (( i=1; i<5; i++ )); do

 litp create -t vip -p /deployments/d1/clusters/c1/services/luci/ipaddresses/ip${i} -o ipaddress="${traf1_vip[$(($i+5))]}" network_name=traffic1
 litp create -t vip -p /deployments/d1/clusters/c1/services/luci/ipaddresses/ip$(($i+4)) -o ipaddress="${traf1_vip_ipv6[$(($i+5))]}" network_name=traffic1
 litp create -t vip -p /deployments/d1/clusters/c1/services/luci/ipaddresses/ip$(($i+8)) -o ipaddress="${traf2_vip[$(($i+5))]}" network_name=traffic2

done

# FO SG4 #VIPs = 5x #AC(1) .......5 IPv4 + 5 IPv6 VIPs per Traffic1 Network, 5 IPv4 VIPs per Traffic2 Network
for (( i=1; i<6; i++ )); do

 litp create -t vip -p /deployments/d1/clusters/c1/services/ricci/ipaddresses/ip${i} -o ipaddress="${traf1_vip[$(($i+11))]}"  network_name=traffic1
 litp create -t vip -p /deployments/d1/clusters/c1/services/ricci/ipaddresses/ip$(($i+5)) -o ipaddress="${traf1_vip_ipv6[$(($i+11))]}"  network_name=traffic1
 litp create -t vip -p /deployments/d1/clusters/c1/services/ricci/ipaddresses/ip$(($i+10)) -o ipaddress="${traf2_vip[$(($i+11))]}" network_name=traffic2

done

# PAR SG2 #VIPs = NONE

# Add FO SG Filesystem
 litp inherit -p /deployments/d1/clusters/c1/services/apachecs/filesystems/fs1 -s /deployments/d1/clusters/c1/storage_profile/sp2/volume_groups/vxvg1/file_systems/fs1

# Network hosts
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/nh1 -o network_name=traffic1 ip="${traf1_ip[0]}"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/nh2 -o network_name=traffic2 ip="${traf2_ip[0]}"

litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/nh3 -o network_name=traffic1 ip="${traf1_ip[1]}"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/nh4 -o network_name=traffic2 ip="${traf2_ip[1]}"

# network hosted by a bond
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/nh5 -o network_name=data ip="${node_ip_836_bond[0]}" 
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/nh6 -o network_name=data ip="${node_ipv6_836_bond_nhs[0]}"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/nh7 -o network_name=data ip="${node_ip_836_bond[1]}" 
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/nh8 -o network_name=data ip="${node_ipv6_836_bond_nhs[1]}"

# for ipv6 only network
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/nh9 -o network_name=ipv61 ip="${netipv6vm_ip_nhs[0]}"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/nh10 -o network_name=ipv61 ip="${netipv6vm_ip_nhs[1]}"

#DNS
litp create -t dns-client -p /ms/configs/dns_client -o search=ammeonvpn.com,exampleone.com,exampletwo.com,examplethree.com,examplefour.com,examplefive.com
litp create -t nameserver -p /ms/configs/dns_client/nameservers/my_name_server_A -o ipaddress=10.44.86.212 position=1
litp create -t nameserver -p /ms/configs/dns_client/nameservers/my_name_server_B -o ipaddress=2001:4860:0:1001::68 position=2


##### NAS #######

# SFS Filesystem Server 1
litp create -t sfs-service -p /infrastructure/storage/storage_providers/sfs_service_sp1 -o name="sfs1" management_ipv4="${sfs1_management_ip}" user_name='support' password_key='key-for-sfs'
litp create -t sfs-virtual-server -p /infrastructure/storage/storage_providers/sfs_service_sp1/virtual_servers/vs1 -o name="virtserv1" ipv4address="${sfs1_vip}"

# SFS POOL 1 LAYOUT
litp create -t sfs-pool             -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl1 -o name="ST_Pool"
litp create -t sfs-cache            -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl1/cache_objects/cache1 -o name="${sfs_cache}"
litp create -t sfs-filesystem       -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl1/file_systems/mgmt_fs1 -o path="${sfs_prefix}-managed1" size='40M' snap_size=50 cache_name="${sfs_cache}"
litp create -t sfs-filesystem       -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl1/file_systems/mgmt_fs2 -o path="${sfs_prefix}-managed2" size='40M' snap_size=70 cache_name="${sfs_cache}"
litp create -t sfs-export           -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl1/file_systems/mgmt_fs1/exports/ex1 -o ipv4allowed_clients="${ms_ip_sfs},${node_ip_sfs[0]},${node_ip_sfs[1]}" options="rw,no_root_squash"
litp create -t sfs-export           -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl1/file_systems/mgmt_fs2/exports/ex2 -o ipv4allowed_clients="${ms_ip_sfs},${node_ip_sfs[0]},${node_ip_sfs[1]}" options="rw,no_root_squash"


# SFS POOL 2 LAYOUT
litp create -t sfs-pool             -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl2 -o name="ST_Pool2"
litp create -t sfs-filesystem       -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl2/file_systems/extra_fs1 -o path="${sfs_prefix}_pl1_xtra_sfs_fs1" size='100M' snap_size='230' cache_name="ST51-cache"
litp create -t sfs-filesystem       -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl2/file_systems/extra_fs2 -o path="${sfs_prefix}_pl1_xtra_sfs_fs2" size='100M' snap_size='230' cache_name="ST51-cache"
litp create -t sfs-export           -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl2/file_systems/extra_fs1/exports/ex1 -o ipv4allowed_clients="${ms_ip_sfs},${node_ip_sfs[0]}" options="ro,no_root_squash,secure_locks"
litp create -t sfs-export           -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl2/file_systems/extra_fs1/exports/ex2 -o ipv4allowed_clients="${node_ip_sfs[1]}" options="ro,no_root_squash,secure_locks"
litp create -t sfs-export           -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl2/file_systems/extra_fs2/exports/ex1 -o ipv4allowed_clients="${ms_ip_sfs},${node_ip_sfs[0]}" options="ro,no_root_squash,secure_locks"
litp create -t sfs-export           -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl2/file_systems/extra_fs2/exports/ex2 -o ipv4allowed_clients="${node_ip_sfs[1]}" options="ro,no_root_squash,secure_locks"



# NFS MOUNTS FOR MS AND NODES
litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mount1_1 -o export_path="${sfs_prefix}-managed1" provider="virtserv1" mount_point="/SFS1_managed1" mount_options="soft,intr" network_name="${sfs_network}"
litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mount1_2 -o export_path="${sfs_prefix}-managed2" provider="virtserv1" mount_point="/SFS1_managed2" mount_options="soft,intr" network_name="${sfs_network}"

litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/extra1 -o export_path="${sfs_prefix}_pl1_xtra_sfs_fs1" provider="virtserv1" mount_point="/SFS1_extra1" mount_options="soft,intr" network_name="${sfs_network}"
litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/extra2 -o export_path="${sfs_prefix}_pl1_xtra_sfs_fs2" provider="virtserv1" mount_point="/SFS1_extra2" mount_options="soft,intr" network_name="${sfs_network}"

litp inherit -p /ms/file_systems/fs2 -s /infrastructure/storage/nfs_mounts/mount1_2
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/file_systems/fs1 -s /infrastructure/storage/nfs_mounts/mount1_1
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/file_systems/fs2 -s /infrastructure/storage/nfs_mounts/mount1_2
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/file_systems/fs1 -s /infrastructure/storage/nfs_mounts/mount1_1
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/file_systems/fs2 -s /infrastructure/storage/nfs_mounts/mount1_2
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/file_systems/extra1 -s /infrastructure/storage/nfs_mounts/extra1
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/file_systems/extra2 -s /infrastructure/storage/nfs_mounts/extra2
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/file_systems/extra1 -s /infrastructure/storage/nfs_mounts/extra1
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/file_systems/extra2 -s /infrastructure/storage/nfs_mounts/extra2


# ADDING DIFF NAMED SERVICE TO NODES
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/services/diff_name_srvc -s /software/services/diff_name_srvc
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/services/diff_name_srvc -s /software/services/diff_name_srvc

# FS unmanaged on server 1
# This FS must already exist on the SFS server
litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/unmanaged1 -o export_path="${sfs_prefix}-fs1" provider="virtserv1" mount_point="/SFSunmanaged1" mount_options="soft,intr" network_name="${sfs_network}"
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/file_systems/unmanaged1 -s /infrastructure/storage/nfs_mounts/unmanaged1
litp inherit -p /ms/file_systems/unmanaged1 -s /infrastructure/storage/nfs_mounts/unmanaged1


# SFS Filesystem Server 2
#litp create -t sfs-service -p /infrastructure/storage/storage_providers/sfs_service_sp2 -o name="sfs2" management_ipv4="${sfs2_management_ip}" user_name='support' password_key='key-for-sfs'
#litp create -t sfs-virtual-server -p /infrastructure/storage/storage_providers/sfs_service_sp2/virtual_servers/vs2 -o name="virtserv2" ipv4address="${sfs2_vip}"

# SFS POOL 1 LAYOUT
#litp create -t sfs-pool             -p /infrastructure/storage/storage_providers/sfs_service_sp2/pools/pl1 -o name="SFS_Pool"
#litp create -t sfs-cache            -p /infrastructure/storage/storage_providers/sfs_service_sp2/pools/pl1/cache_objects/cache1 -o name="${sfs_cache}"
#litp create -t sfs-filesystem       -p /infrastructure/storage/storage_providers/sfs_service_sp2/pools/pl1/file_systems/mgmt_fs1 -o path="/vx/ST51-managed2" size='40M' snap_size=100 cache_name="${sfs_cache}"
#litp create -t sfs-export           -p /infrastructure/storage/storage_providers/sfs_service_sp2/pools/pl1/file_systems/mgmt_fs1/exports/ex1         -o ipv4allowed_clients="10.44.86.0/26" options="rw,no_root_squash"

# SFS POOL 2 LAYOUT
#litp create -t sfs-pool             -p /infrastructure/storage/storage_providers/sfs_service_sp2/pools/pl2 -o name="SFS_Pool2"
#litp create -t sfs-filesystem       -p /infrastructure/storage/storage_providers/sfs_service_sp2/pools/pl2/file_systems/extra_fs1 -o path="/vx/ST51_pl2_xtra_sfs_fs1" size='100M' snap_size='230' cache_name="ST51-cache"
#litp create -t sfs-filesystem       -p /infrastructure/storage/storage_providers/sfs_service_sp2/pools/pl2/file_systems/extra_fs2 -o path="/vx/ST51_pl2_xtra_sfs_fs2" size='100M' snap_size='230' cache_name="ST51-cache"
#litp create -t sfs-export           -p /infrastructure/storage/storage_providers/sfs_service_sp2/pools/pl2/file_systems/extra_fs1/exports/ex1         -o ipv4allowed_clients="10.44.86.194,10.44.86.195" options="ro,no_root_squash,secure_locks"
#litp create -t sfs-export           -p /infrastructure/storage/storage_providers/sfs_service_sp2/pools/pl2/file_systems/extra_fs2/exports/ex2         -o ipv4allowed_clients="10.44.86.196" options="ro,no_root_squash,secure_locks"


# NFS MOUNT FOR MS AND NODE 1
#litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mount2_1 -o export_path="/vx/ST51-managed2" provider="virtserv2" mount_point="/SFS2_managed" mount_options="soft,intr" network_name="netwrk834"
#litp inherit -p /ms/file_systems/managed2 -s /infrastructure/storage/nfs_mounts/mount2_1
#litp inherit -p /deployments/d1/clusters/c1/nodes/n1/file_systems/managed2 -s /infrastructure/storage/nfs_mounts/mount2_1





# Non SFS 
litp create -t nfs-service -p /infrastructure/storage/storage_providers/nas_service_sp1 -o name="nas1" ipv4address="${nfs_management_ip}"
litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/nm1 -o export_path="${nfs_prefix}/ro_unmanaged" provider="nas1" mount_point="/cluster_ro" mount_options="soft,intr" network_name="netwrk834"
litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/nm2 -o export_path="${nfs_prefix}/rw_unmanaged" provider="nas1" mount_point="/cluster_rw" mount_options="soft,intr" network_name="netwrk834"


litp inherit -p /ms/file_systems/nm1 -s /infrastructure/storage/nfs_mounts/nm1
litp inherit -p /ms/file_systems/nm2 -s /infrastructure/storage/nfs_mounts/nm2
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/file_systems/nm1 -s /infrastructure/storage/nfs_mounts/nm1
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/file_systems/nm2 -s /infrastructure/storage/nfs_mounts/nm2
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/file_systems/nm1 -s /infrastructure/storage/nfs_mounts/nm1
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/file_systems/nm2 -s /infrastructure/storage/nfs_mounts/nm2


#log rotate rules
litp create -t logrotate-rule-config -p /deployments/d1/clusters/c1/nodes/n1/configs/logrotate
litp create -t logrotate-rule -p /deployments/d1/clusters/c1/nodes/n1/configs/logrotate/rules/messages -o name="a_messages" path="/var/log/messages" size=10M mail=stefan.ulian@ammeon.com rotate=50 copytruncate=true
litp create -t logrotate-rule-config -p /ms/configs/logrotate
litp create -t logrotate-rule -p /ms/configs/logrotate/rules/messages -o name="a_messages" path="/var/log/messages" size=10M mail=stefan.ulian@ammeon.com rotate=50 copytruncate=true


# private network
litp create -t network -p /infrastructure/networking/networks/net1vm -o name=net1vm subnet="${net1vm_subnet}"
litp create -t network -p /infrastructure/networking/networks/net2vm -o name=net2vm subnet="${net2vm_subnet}"
litp create -t network -p /infrastructure/networking/networks/net3vm -o name=net3vm subnet="${net3vm_subnet}"
litp create -t network -p /infrastructure/networking/networks/net4vm -o name=net4vm subnet="${net4vm_subnet}"

# Bridge for ms for private network
litp create -t vlan -p /ms/network_interfaces/bond1_333 -o device_name=bond1.333 bridge=br333 
litp create -t bridge -p /ms/network_interfaces/br333 -o device_name=br333 network_name=net1vm ipaddress="${net1vm_ip_ms}" multicast_snooping=0

litp create -t vlan -p /ms/network_interfaces/bond1_444 -o device_name=bond1.444 bridge=br444
litp create -t bridge -p /ms/network_interfaces/br444 -o device_name=br444 network_name=net2vm ipaddress="${net2vm_ip_ms}"

litp create -t vlan -p /ms/network_interfaces/bond1_555 -o device_name=bond1.555 bridge=br555
litp create -t bridge -p /ms/network_interfaces/br555 -o device_name=br555 network_name=net3vm ipaddress="${net3vm_ip_ms}"

litp create -t vlan -p /ms/network_interfaces/bond1_665 -o device_name=bond1.665 bridge=br665
litp create -t bridge -p /ms/network_interfaces/br665 -o device_name=br665 network_name=net4vm ipaddress="${net4vm_ip_ms}"



# Bridge for nodes for private network
litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/bond1_333 -o device_name=bond1.333 bridge=br333
litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/bond1_333 -o device_name=bond1.333 bridge=br333
litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/br333 -o device_name=br333 network_name=net1vm ipaddress="${net1vm_ip[0]}" multicast_snooping=0
litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/br333 -o device_name=br333 network_name=net1vm ipaddress="${net1vm_ip[1]}" multicast_snooping=0

litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/bond1_444 -o device_name=bond1.444 bridge=br444
litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/bond1_444 -o device_name=bond1.444 bridge=br444
litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/br444 -o device_name=br444 network_name=net2vm ipaddress="${net2vm_ip[0]}"
litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/br444 -o device_name=br444 network_name=net2vm ipaddress="${net2vm_ip[1]}"

litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/bond1_555 -o device_name=bond1.555 bridge=br555
litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/bond1_555 -o device_name=bond1.555 bridge=br555
litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/br555 -o device_name=br555 network_name=net3vm ipaddress="${net3vm_ip[0]}"
litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/br555 -o device_name=br555 network_name=net3vm ipaddress="${net3vm_ip[1]}"

litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/bond1_665 -o device_name=bond1.665 bridge=br665
litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/bond1_665 -o device_name=bond1.665 bridge=br665
litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/br665 -o device_name=br665 network_name=net4vm ipaddress="${net4vm_ip[0]}"
litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/br665 -o device_name=br665 network_name=net4vm ipaddress="${net4vm_ip[1]}"

#ipv6 only
litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/bond1_6 -o device_name=bond1.6 bridge=br6 
litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/bond1_6 -o device_name=bond1.6 bridge=br6 
litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/br6 -o device_name=br6 network_name=ipv61 ipv6address="${netipv6vm_ip[0]}" multicast_snooping=0
litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/br6 -o device_name=br6 network_name=ipv61 ipv6address="${netipv6vm_ip[1]}" multicast_snooping=0


# Cluster 1 - VMs

# Add vcs hosts

litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/net1vm_1 -o network_name=net1vm ip="${net1vm_ip[0]}"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/net1vm_2 -o network_name=net1vm ip="${net1vm_ip[1]}"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/net2vm_1 -o network_name=net2vm ip="${net2vm_ip[0]}"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/net2vm_2 -o network_name=net2vm ip="${net2vm_ip[1]}"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/net3vm_1 -o network_name=net3vm ip="${net3vm_ip[0]}"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/net3vm_2 -o network_name=net3vm ip="${net3vm_ip[1]}"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/net4vm_1 -o network_name=net4vm ip="${net4vm_ip[0]}"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/net4vm_2 -o network_name=net4vm ip="${net4vm_ip[1]}"




# Create the md5 checksum file
/usr/bin/md5sum /var/www/html/images/rhel_7_image.qcow2 | cut -d ' ' -f 1 > /var/www/html/images/rhel_7_image.qcow2.md5
/usr/bin/md5sum /var/www/html/images/rhel_6_image.qcow2 | cut -d ' ' -f 1 > /var/www/html/images/rhel_6_image.qcow2.md5


for (( i=1; i<5; i++ )); do

   if (($i % 2)); then
      litp create -t vm-image -p /software/images/image${i} -o name="STvm${i}" source_uri="http://10.44.235.51/images/rhel_7_image.qcow2"
   else
      litp create -t vm-image -p /software/images/image${i} -o name="STvm${i}" source_uri="http://ms1dot51/images/rhel_6_image.qcow2"
   fi

# litp create -t vm-service -p /software/services/vmservice${i} -o service_name="STvmserv${i}" image_name="STvm${i}" cpus=$((2**i)) ram=4096M internal_status_check=on cleanup_command="/sbin/service STvmserv$i force-stop"
  litp create -t vm-service -p /software/services/vmservice${i} -o service_name="STvmserv${i}" image_name="STvm${i}" cpus=4 ram=4096M internal_status_check=on cleanup_command="/sbin/service STvmserv$i force-stop "
  litp create -t vm-alias -p /software/services/vmservice${i}/vm_aliases/alias_ms -o alias_names=ms1dot51 address="${net1vm_ip_ms}"
  litp create -t vm-alias -p /software/services/vmservice${i}/vm_aliases/alias_node1 -o alias_names="${node_hostname[0]}" address="${net1vm_ip[0]}"
  litp create -t vm-alias -p /software/services/vmservice${i}/vm_aliases/alias_node2 -o alias_names="${node_hostname[1]}" address="${net1vm_ip[1]}"
   if (($i % 2)); then 
      litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/SG_STvm${i} -o name="PL_vmSG${i}" active=2 standby=0 node_list='n1,n2' online_timeout=900 offline_timeout=199  
#      litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/SG_STvm${i}/ha_configs/vm_hc -o status_interval=120 status_timeout=120 restart_limit=4 startup_retry_limit=2
      litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/SG_STvm${i}/ha_configs/vm_hc -o status_interval=60 status_timeout=60 restart_limit=4 startup_retry_limit=2 fault_on_monitor_timeouts=5 tolerance_limit=8 clean_timeout=50
       litp create -t vm-package -p /software/services/vmservice${i}/vm_packages/tree -o name=tree
       litp create -t vm-package -p /software/services/vmservice${i}/vm_packages/unzip -o name=unzip
       litp create -t vm-yum-repo -p /software/services/vmservice${i}/vm_yum_repos/3pp -o name=vm_3pp base_url=http://"${net1vm_ip_ms}"/3pp
       litp create -t vm-yum-repo -p /software/services/vmservice${i}/vm_yum_repos/os -o name=vm_os base_url=http://"${ms_host}"/6/os/x86_64

   else
      litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/SG_STvm${i} -o name="FO_vmSG${i}" active=1 standby=1 node_list='n1,n2' online_timeout=900 offline_timeout=400
#      litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/SG_STvm${i}/ha_configs/vm_hc -o status_interval=120 status_timeout=120 restart_limit=4 startup_retry_limit=2	
      litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/SG_STvm${i}/ha_configs/vm_hc -o status_interval=60 status_timeout=60 restart_limit=4 startup_retry_limit=2 fault_on_monitor_timeouts=5 tolerance_limit=8 clean_timeout=50   
       litp create -t vm-package -p /software/services/vmservice${i}/vm_packages/firefox -o name=firefox
       litp create -t vm-package -p /software/services/vmservice${i}/vm_packages/cups -o name=cups 
       litp create -t vm-yum-repo -p /software/services/vmservice${i}/vm_yum_repos/os -o name=vm_os base_url=http://"${ms_host}"/6/os/x86_64

   fi

 litp inherit -p /deployments/d1/clusters/c1/services/SG_STvm${i}/applications/vmservice${i} -s /software/services/vmservice${i}
done

# ADDING TRIGGER TO ONE OF THE FAILOVER CLUSTERED-SERVICES
litp create -t vcs-trigger -p /deployments/d1/clusters/c1/services/SG_STvm2/triggers/trig1 -o trigger_type=nofailover

litp update -p /software/services/vmservice1 -o cleanup_command="/sbin/service STvmserv1 stop-undefine --stop-timeout=30"
litp update -p /software/services/vmservice2 -o cleanup_command="/sbin/service STvmserv2 force-stop-undefine --stop-timeout=15"

litp create -t vm-ram-mount -p /software/services/vmservice1/vm_ram_mounts/fs_test_mount -o type=ramfs mount_point="/mnt/ram_test_mount" mount_options="size=32M,noexec,nodev,nosuid"
litp create -t vm-ram-mount -p /software/services/vmservice2/vm_ram_mounts/fs_test_mount -o type=ramfs mount_point="/mnt/ram_test_mount" mount_options="size=128M,nosuid"
litp create -t vm-ram-mount -p /software/services/vmservice3/vm_ram_mounts/fs_test_mount -o type=tmpfs mount_point="/mnt/tmp_test_mount" mount_options="size=256M,nodev,nosuid"
litp create -t vm-ram-mount -p /software/services/vmservice4/vm_ram_mounts/fs_test_mount -o type=tmpfs mount_point="/mnt/tmp_test_mount" mount_options="size=64M,noexec,nosuid"

#Adding nfs shares to vm's
#removed the mounts till there is direct connection to the nfs server
#litp create -t vm-nfs-mount -p /software/services/vmservice1/vm_nfs_mounts/mount1 -o mount_point="/nfs_A" mount_options=soft,defaults device_path=10.44.86.4:/home/admin/ST/nfs_share_dir_51/dir_share_51_A
#litp create -t vm-nfs-mount -p /software/services/vmservice1/vm_nfs_mounts/mount2 -o mount_point="/nfs_B" device_path=10.44.86.4:/home/admin/ST/nfs_share_dir_51/dir_share_51_B
#litp create -t vm-nfs-mount -p /software/services/vmservice1/vm_nfs_mounts/mount3 -o mount_point="/nfs_C" device_path=10.44.86.4:/home/admin/ST/nfs_share_dir_51/dir_share_51_C

#litp create -t vm-nfs-mount -p /software/services/vmservice2/vm_nfs_mounts/mount1 -o mount_point="/nfs_A" device_path=10.44.86.4:/home/admin/ST/nfs_share_dir_51/dir_share_51_A
#litp create -t vm-nfs-mount -p /software/services/vmservice2/vm_nfs_mounts/mount2 -o mount_point="/nfs_B" mount_options=soft,defaults device_path=10.44.86.4:/home/admin/ST/nfs_share_dir_51/dir_share_51_B
#litp create -t vm-nfs-mount -p /software/services/vmservice2/vm_nfs_mounts/mount3 -o mount_point="/nfs_C" device_path=10.44.86.4:/home/admin/ST/nfs_share_dir_51/dir_share_51_C

#litp create -t vm-nfs-mount -p /software/services/vmservice3/vm_nfs_mounts/mount1 -o mount_point="/nfs_A" device_path=10.44.86.4:/home/admin/ST/nfs_share_dir_51/dir_share_51_A
#litp create -t vm-nfs-mount -p /software/services/vmservice3/vm_nfs_mounts/mount2 -o mount_point="/nfs_B" device_path=10.44.86.4:/home/admin/ST/nfs_share_dir_51/dir_share_51_B
#litp create -t vm-nfs-mount -p /software/services/vmservice3/vm_nfs_mounts/mount3 -o mount_point="/nfs_C" mount_options=soft,defaults device_path=10.44.86.4:/home/admin/ST/nfs_share_dir_51/dir_share_51_C


###################
## VMS
##################
litp create -t vm-network-interface -p /software/services/vmservice1/vm_network_interfaces/vm_nic1 -o device_name=eth0 host_device=br333 network_name=net1vm
litp update -p  /deployments/d1/clusters/c1/services/SG_STvm1/applications/vmservice1/vm_network_interfaces/vm_nic1 -o ipaddresses=10.46.81.10,10.46.81.11 gateway="${net1vm_gw[0]}" ipv6addresses=${net1vm_ipv6_vm1},${net1vm_ipv6_vm2}

litp create -t vm-network-interface -p /software/services/vmservice1/vm_network_interfaces/vm_nic2 -o device_name=eth1 host_device=br444 network_name=net2vm
litp create -t vm-network-interface -p /software/services/vmservice1/vm_network_interfaces/vm_nic3 -o device_name=eth2 host_device=br555 network_name=net3vm
litp create -t vm-network-interface -p /software/services/vmservice1/vm_network_interfaces/vm_nic4 -o device_name=eth3 host_device=br665 network_name=net4vm
litp update -p  /deployments/d1/clusters/c1/services/SG_STvm1/applications/vmservice1/vm_network_interfaces/vm_nic2 -o ipaddresses=10.46.81.80,10.46.81.81
litp update -p  /deployments/d1/clusters/c1/services/SG_STvm1/applications/vmservice1/vm_network_interfaces/vm_nic3 -o ipaddresses=10.46.81.140,10.46.81.141
litp update -p  /deployments/d1/clusters/c1/services/SG_STvm1/applications/vmservice1/vm_network_interfaces/vm_nic4 -o ipaddresses=10.46.81.200,10.46.81.201 #gateway="${net4vm_gw[0]}"

# ipv6 only interface
litp create -t vm-network-interface -p /software/services/vmservice1/vm_network_interfaces/vm_nic5 -o network_name=ipv61 device_name=eth4 host_device=br6 gateway6=${ipv61_gateway}
litp update -p  /deployments/d1/clusters/c1/services/SG_STvm1/applications/vmservice1/vm_network_interfaces/vm_nic5 -o ipv6addresses=${ipv61_vm1},${ipv61_vm2}  

litp update -p  /deployments/d1/clusters/c1/services/SG_STvm1/applications/vmservice1 -o hostnames=51vm1a,51vm1b

litp update -p /software/services/vmservice1/vm_network_interfaces/vm_nic1 -o mac_prefix="AA:AA:AA"

litp create -t vm-network-interface -p /software/services/vmservice2/vm_network_interfaces/vm_nic1 -o device_name=eth0 host_device=br333 network_name=net1vm
litp update -p  /deployments/d1/clusters/c1/services/SG_STvm2/applications/vmservice2/vm_network_interfaces/vm_nic1 -o ipaddresses=10.46.81.12 gateway="${net1vm_gw[0]}"
litp create -t vm-network-interface -p /software/services/vmservice2/vm_network_interfaces/vm_nic2 -o device_name=eth1 host_device=br444 network_name=net2vm #ipaddresses=dhcp
litp create -t vm-network-interface -p /software/services/vmservice2/vm_network_interfaces/vm_nic3 -o device_name=eth2 host_device=br555 network_name=net3vm #ipaddresses=dhcp
litp update -p  /deployments/d1/clusters/c1/services/SG_STvm2/applications/vmservice2/vm_network_interfaces/vm_nic2 -o ipaddresses=10.46.81.82
litp update -p  /deployments/d1/clusters/c1/services/SG_STvm2/applications/vmservice2/vm_network_interfaces/vm_nic3 -o ipaddresses=10.46.81.142
litp update -p  /deployments/d1/clusters/c1/services/SG_STvm2/applications/vmservice2 -o hostnames=51vm2


litp create -t vm-network-interface -p /software/services/vmservice3/vm_network_interfaces/vm_nic1 -o device_name=eth0 host_device=br333 network_name=net1vm
litp update -p  /deployments/d1/clusters/c1/services/SG_STvm3/applications/vmservice3/vm_network_interfaces/vm_nic1 -o ipaddresses=10.46.81.13,10.46.81.14 gateway="${net1vm_gw[0]}"
litp create -t vm-network-interface -p /software/services/vmservice3/vm_network_interfaces/vm_nic2 -o device_name=eth1 host_device=br444 network_name=net2vm #ipaddresses=dhcp
litp create -t vm-network-interface -p /software/services/vmservice3/vm_network_interfaces/vm_nic3 -o device_name=eth2 host_device=br555 network_name=net3vm #ipaddresses=dhcp
litp update -p  /deployments/d1/clusters/c1/services/SG_STvm3/applications/vmservice3/vm_network_interfaces/vm_nic2 -o ipaddresses=10.46.81.84,10.46.81.85
litp update -p  /deployments/d1/clusters/c1/services/SG_STvm3/applications/vmservice3/vm_network_interfaces/vm_nic3 -o ipaddresses=10.46.81.143,10.46.81.144
litp update -p  /deployments/d1/clusters/c1/services/SG_STvm3/applications/vmservice3 -o hostnames=51vm3a,51vm3b



litp create -t vm-network-interface -p /software/services/vmservice4/vm_network_interfaces/vm_nic1 -o device_name=eth0 host_device=br333 network_name=net1vm
litp update -p  /deployments/d1/clusters/c1/services/SG_STvm4/applications/vmservice4/vm_network_interfaces/vm_nic1 -o ipaddresses=10.46.81.15 gateway="${net1vm_gw[0]}"
litp create -t vm-network-interface -p /software/services/vmservice4/vm_network_interfaces/vm_nic2 -o device_name=eth1 host_device=br444 network_name=net2vm #ipaddresses=dhcp
litp create -t vm-network-interface -p /software/services/vmservice4/vm_network_interfaces/vm_nic3 -o device_name=eth2 host_device=br555 network_name=net3vm #ipaddresses=dhcp
litp update -p  /deployments/d1/clusters/c1/services/SG_STvm4/applications/vmservice4/vm_network_interfaces/vm_nic2 -o ipaddresses=10.46.81.86
litp update -p  /deployments/d1/clusters/c1/services/SG_STvm4/applications/vmservice4/vm_network_interfaces/vm_nic3 -o ipaddresses=10.46.81.145

#litp update -p /deployments/d1/clusters/c1/services/SG_STvm1 -o dependency_list=SG_STvm2,SG_STvm3
#litp update -p /deployments/d1/clusters/c1/services/SG_STvm3 -o dependency_list=SG_STvm4

### Add DHCP server for VMs
#litp create -t dhcp-service -p /software/services/dhcp -o service_name="dhcp_51" nameservers="10.44.86.4" domainsearch="ammeonvpn.com,openvpn.com,example105one.com,example105two.com" ntpservers="10.44.86.30"

#litp create -t dhcp-subnet -p /software/services/dhcp/subnets/vm2 -o network_name=net2vm
#litp create -t dhcp-subnet -p /software/services/dhcp/subnets/vm3 -o network_name=net3vm

#litp create -t dhcp-range -p /software/services/dhcp/subnets/vm2/ranges/r1 -o start=10.46.81.80 end=10.46.81.86
#litp create -t dhcp-range -p /software/services/dhcp/subnets/vm3/ranges/r1 -o start=10.46.81.140 end=10.46.81.146

#litp inherit -p /deployments/d1/clusters/c1/nodes/n1/services/dhcp -s /software/services/dhcp -o primary="true" 
#litp inherit -p /deployments/d1/clusters/c1/nodes/n2/services/dhcp -s /software/services/dhcp -o primary="false"

# add ssh keys to vm's temp

litp create -t vm-ssh-key -p /software/services/vmservice2/vm_ssh_keys/support_key1 -o ssh_key="ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAuLmfvcm6mOieGb6wSs+L1iSoIsblK1xx0f8YM1pnTuXqTdSxvtex+A9rCvGS8paBjzA665EcOtOh81D3B0HxgVj2p4PYWEWtzpCGyGNbUvOuwoDViHKe2ubtI6m6CYVz70GGTyKdlEwyvXLTkk0rZo8LGVAxUkdnuACjDyqAWPKtIUsmz1L6dlXx5dv6spfYq1wZDBhocUux2vk7RrHY2fOfOLXnYqDm6d5T7Wv5v2v/Kt2vdaHt556ZMa06bNStcXn+7CGJ9Pr+bFy0kid7YKypbFFKeS2o3HwGo4vqz+G8hUGakaZmxRznEdQSx1gAxZ6vk0ueqk6ALtV5IVqD1w== adrian.vornic@1VGS45J"

#litp create -t vm-ssh-key -p /software/services/vmservice1/vm_ssh_keys/support_key1 -o ssh_key="cucu rucu cucu"

#Adding rsyslog8 with requires elesticsearch
#Ms and node1 - rsyslog8 and elasticsearch
#Node2 only rsyslog8

litp create -t package -p /software/items/p1 -o name=EXTRlitprsyslog_CXP9032140 replaces=rsyslog7
litp create -t package -p /software/items/p2 -o name=EXTRlitprsyslogelasticsearch_CXP9032173 requires=EXTRlitprsyslog_CXP9032140 
litp inherit -p /ms/items/EXTRlitprsyslog -s /software/items/p1
litp inherit -p /ms/items/EXTRlitprsyslogelasticsearch -s /software/items/p2
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/EXTRlitprsyslog -s /software/items/p1
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/EXTRlitprsyslogelasticsearch -s /software/items/p2
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/items/EXTRlitprsyslog -s /software/items/p1

# Add VM on MS
litp create -t vm-image -p /software/images/fmmed -o name="fmmed" source_uri="http://ms1dot51/images/rhel_7_image.qcow2"
litp create -t vm-service -p /ms/services/msfmmed1 -o service_name=msfmmed1 image_name=fmmed cpus=2 ram=512M internal_status_check=off
litp create -t vm-network-interface -p /ms/services/msfmmed1/vm_network_interfaces/net1 -o network_name=netwrk834 device_name=eth0 host_device=br834 ipaddresses="${ms_vm_ip_834}"
litp create -t vm-network-interface -p /ms/services/msfmmed1/vm_network_interfaces/net2 -o network_name=net1vm device_name=eth1 host_device=br333 ipaddresses="${ms_vm_ip_net1vm}"
# non SFS FS mount
litp create -t vm-nfs-mount -p /ms/services/msfmmed1/vm_nfs_mounts/non_sfs_mount1 -o mount_point=/mnt/nfs_rw device_path="${nfs_management_ip}:${nfs_prefix}/rw_unmanaged" mount_options=defaults
# SFS FS mount
# Can only mount from sfs2 as sfs1 is not reachable from the VM
# litp create -t vm-nfs-mount -p /ms/services/msfmmed1/vm_nfs_mounts/sfs_mount1 -o mount_point=/sfs device_path="${sfs2_vip}:/vx/ST51-managed2" mount_options=defaults

#litp create -p /software/items/EXTRlitprsyslog_CXP9032140 -t package -o name=EXTRlitprsyslog_CXP9032140 replaces=rsyslog7
#litp inherit -p /ms/items/EXTRlitprsyslog_CXP9032140 -s /software/items/EXTRlitprsyslog_CXP9032140

#for (( i=0; i<${#node_sysname[@]}; i++ )); do

#	litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/EXTRlitprsyslog_CXP9032140 -s /software/items/EXTRlitprsyslog_CXP9032140
	
#done

# Add software
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/libguestfs-tools-c -s /software/items/libguestfs-tools-c
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/items/libguestfs-tools-c -s /software/items/libguestfs-tools-c

# Check correct number of tasks are created when cs_initial_online is both off and on
check_cs_initial_online_tasks "/deployments/d1/clusters/c1/"

# Install with cs_initial_online=off, so all services will be offline until MNs are rebooted
# Temporarily change to on to investigate frequent install failures
litp update -p /deployments/d1/clusters/c1/ -o cs_initial_online=on


# Plugin Install
for (( i=0; i<${#rpms[@]}; i++ )); do
    # import plugin into litp repo
    litp import "/tmp/${rpms[$i]}" litp
    # install plugin 
    expect /tmp/root_yum_install_pkg.exp "${ms_host}" "${rpms[$i]%%-*}"
done


dep_tags=(ms boot node cluster pre_node_cluster)
snap_tags=(validation pre_op ms_lvm node_lvm node_vxvm nas san post_op prep_puppet prep_vcs node_reboot node_power_off sanitisation node_power_on node_post_on ms_reboot)

for i in "${dep_tags[@]}" 
do
    litp create -t tag-model-item -p /software/items/dep_tag_$i -o snapshot_tag=san deployment_tag=$i	
    litp inherit -p /ms/items/dep_tag_$i -s /software/items/dep_tag_$i
    litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/dep_tag_$i -s /software/items/dep_tag_$i
    litp inherit -p /deployments/d1/clusters/c1/nodes/n2/items/dep_tag_$i -s /software/items/dep_tag_$i
done
for i in "${snap_tags[@]}" 
do
    litp create -t tag-model-item -p /software/items/snap_tag_$i -o snapshot_tag=$i deployment_tag=node                  
    litp inherit -p /ms/items/snap_tag_$i -s /software/items/snap_tag_$i -o deployment_tag=ms
    litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/snap_tag_$i -s /software/items/snap_tag_$i
    litp inherit -p /deployments/d1/clusters/c1/nodes/n2/items/snap_tag_$i -s /software/items/snap_tag_$i
done  
# two or more of these cause problems
#litp remove -p /ms/items/snap_tag_node_vxm  # plugin update required
#litp remove -p /deployments/d1/clusters/c1/nodes/n1/items/snap_tag_node_vxm 
#litp remove -p /deployments/d1/clusters/c1/nodes/n2/items/snap_tag_node_vxm
litp remove -p /ms/items/dep_tag_cluster  		# internal server error
litp remove -p /ms/items/dep_tag_pre_node_cluster
litp remove -p /ms/items/dep_tag_node
litp remove -p /deployments/d1/clusters/c1/nodes/n2/items/dep_tag_ms # plan fails
litp remove -p /deployments/d1/clusters/c1/nodes/n1/items/dep_tag_ms

litp create_plan
