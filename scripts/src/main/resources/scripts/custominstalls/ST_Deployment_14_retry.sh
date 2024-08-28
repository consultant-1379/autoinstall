#!/bin/bash
#
# Sample LITP multi-blade deployment (SAN version)
#
# Usage:
#   ST_Deployment_14.sh <CLUSTER_SPEC_FILE>
#
if [ "$#" -lt 1 ]; then
    echo -e "Usage:\n  $0 <CLUSTER_SPEC_FILE>" >&2
    exit 1
fi

cluster_file="$1"
source "$cluster_file"

set -x


xml_filter=" | grep -v checksum | grep -v _map "
retry_msg="Running_Retry_"

function contract_a_vm() {
# Function to contract a VM to be only on one node
	vm_contract=$1
	active_count=$(litp show -p $vm_contract -o active)
	if [ $active_count -le "1" ]; then
        	echo "ERROR - Can't contract not a PL SG on multiple node"
	        return 1
	fi
        litp update -p $vm_contract -o active=1 node_list=n2
        litp update -p ${vm_contract}/applications/vm -o hostnames=vm-contracted
        vm_net=${vm_contract}/applications/vm/vm_network_interfaces/
        net_url_str=$(litp show -p $vm_net -l )
        net_url_list=(${net_url_str//deployments/deployments})
        echo $net_url_list
        for (( x=1; x<${#net_url_list[@]}; x++ )) do
                ipv4=$(litp show -p ${net_url_list[$x]} -o ipaddresses)
                if [ $? -ne 1 ]; then
                        litp update -p ${net_url_list[$x]} -o ipaddresses=${ipv4/,*/}
                fi
                obj_props=$(litp show -p ${net_url_list[$x]})
                if [[ $obj_props == *"ipv6addresses"* ]]; then
                    ipv6=$(litp show -p ${net_url_list[$x]} -o ipv6addresses)
                    if [ $? -ne 1 ]; then
                            litp update -p ${net_url_list[$x]} -o ipv6addresses=${ipv6/,*/}
                    fi
                fi
        done
}

# Check for /var/log/messages for ->  LITPCDS-12037 Wait for node to PXE boot task fails after timeout
grep "has not PXE booted within the specified timeout" /var/log/messages
if [ $? == 0 ]
then
        echo "EXIT found -> LITPCDS-12037 Wait for node to PXE boot task fails after timeout" 
        exit 1
fi

# Check /var/log/messages for 'Wait for node to install and deregister node from Cobbler' failure
grep "Node has not come up within 3600 seconds" /var/log/messages
if [ $? == 0 ]
then
    echo "Node has not come up within 3600 seconds ---- EXITING"
    echo "Check added due to intermittent issue with connection to the SAN"
    echo "Check the iLo of the node to see what state it is in"
    exit 1
fi


grep $retry_msg /var/log/messages
if [ $? == 0 ]
then
	echo ${retry_msg}2 >> /var/log/messages
	# Backup files
	litp show -p / -r > /tmp/model_b4_retry_2.log
	litp export -p / -f /tmp/deployment_after_retry_1.xml
        #echo "tempoary check for future ideompentcy test"
	#service litpd stop
        #/bin/cp $LAST_KNOWN_CONFIG_b4_retry $LAST_KNOWN_CONFIG
	#service litpd start 
else
	echo ${retry_msg}1 >> /var/log/messages
	# Backup files
	litp show -p / -r > /tmp/model_b4_retry.log
	#litp export -p / -f /tmp/initial_deployment.xml
fi


ip6_898count=500
ip4_t1count=200
ip4_t1count=200
ip6_t2count=500
ip6_t2count=500

# Create and show plan after failure and before updates
litp create_plan
litp show_plan
litp show -p /ms/ -r | grep state | grep -v Applied | grep -v NEW | wc -l
litp show -p /deployments/ -r | grep state | grep -v Applied | grep -v NEW | wc -l
litp load -p / -f /tmp/initial_deployment.xml --replace
litp create_plan
litp show_plan
litp show -p /ms/ -r | grep state | grep -v Applied | grep -v NEW | wc -l
litp show -p /deployments/ -r | grep state | grep -v Applied | grep -v NEW | wc -l

# Package 
litp create  -t package   -p /software/items/finger -o name=finger
litp inherit -p /ms/items/finger  -s /software/items/finger
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/finger -s /software/items/finger
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/items/finger -s /software/items/finger
litp remove  -p /software/items/telnet

# upgrade a package
litp import /tmp/test_service-2.0-1.noarch.rpm /var/www/html/newRepo_dir/
litp upgrade -p /deployments/d1

# Storage
# Can't change file sizes as they are snapshots

# VM on MS
        litp create -t vm-image    -p /software/images/imageRHEL7 -o name="imageRHEL7" source_uri=http://"${ms_host}"/images/imageRHEL7.qcow2
	litp create -t vm-service  -p /ms/services/ms_vm3  -o service_name=vm3 image_name=imageRHEL7  cpus=4 ram=4000M internal_status_check=off hostnames=vm3
	litp create -t vm-alias    -p /ms/services/ms_vm3/vm_aliases/vm_ms1    -o alias_names="${ms_host}","Ammeon-LITP-mars-VIP.ammeonvpn.com"             address="${ms_ip}"
	litp create -t vm-alias    -p /ms/services/ms_vm3/vm_aliases/vm_mn1    -o alias_names=mn1,"${node_hostname[0]}","Ammeon-LITP-Tag-898-VIP.ammeonvpn.com" address="${net898_ip[0]}"
	litp create -t vm-alias    -p /ms/services/ms_vm3/vm_aliases/vm_mn2    -o alias_names="${node_hostname[1]}"                                             address="${net898_ip[1]}"
	litp create -t vm-yum-repo -p /ms/services/ms_vm3/vm_yum_repos/updates -o name=vm_UPDATES base_url="http://"${ms_host}"/6.6/updates/x86_64/Packages"
	litp create -t vm-yum-repo -p /ms/services/ms_vm3/vm_yum_repos/os      -o name=vm_os      base_url="http://"${ms_ip}"/6.6/os/x86_64"
	litp create -t vm-yum-repo -p /ms/services/ms_vm3/vm_yum_repos/3pp     -o name=vm_3pp     base_url="http://"Ammeon-LITP-mars-VIP.ammeonvpn.com"/3pp"
	litp create -t vm-package  -p /ms/services/ms_vm3/vm_packages/firefox  -o name=firefox
	litp create -t vm-package  -p /ms/services/ms_vm3/vm_packages/cups     -o name=cups
	litp create -t vm-network-interface  -p /ms/services/ms_vm3/vm_network_interfaces/net0 -o network_name=mgmt device_name=eth0 host_device=br0 mac_prefix=0E:01:02 ipaddresses="${net898_ip_vm[7]}" gateway="${gw_898}" ipv6addresses=$ipv6_898_tp$((ip6_898count++)) gateway6=$ipv6_898_gw
	litp create -t vm-nfs-mount -p /ms/services/ms_vm3/vm_nfs_mounts/sfs_mount4 -o mount_point=/nfs_mount4 mount_options=rw,sharecache device_path=${sfs_management_ip}:/vx/ST150_mgmt_sfs-fs4
	litp create -t vm-nfs-mount -p /ms/services/ms_vm3/vm_nfs_mounts/mount4 -o mount_point=/nfs_4 mount_options=soft,defaults device_path="${nfs_ip}":/home/admin/ST/nfs_share_dir_150/dir_share_150_4

# Cluster
	litp update -p /deployments/d1/clusters/c1 -o app_agent_num_threads=15

# Remove VM on MS
	litp export -p /ms/services/ms_vm2 -f /tmp/ms_vm2.xml
	litp remove -p /ms/services/ms_vm2

# Update a VM on MS
	litp update -p /ms/services/ms_vm1 -o cpus=1 ram=2048M hostnames=vm1Updated image_name=imageRHEL7
	litp create -t vm-alias     -p /ms/services/ms_vm1/vm_aliases/vm_mn2    -o alias_names="${node_hostname[1]}" address="${net898_ip[1]}"
	litp create -t vm-yum-repo  -p /ms/services/ms_vm1/vm_yum_repos/3pp     -o name=vm_3pp     base_url="http://"Ammeon-LITP-mars-VIP.ammeonvpn.com"/3pp"
	litp create -t vm-package   -p /ms/services/ms_vm1/vm_packages/unzip     -o name=unzip
	litp update                 -p /ms/services/ms_vm1/vm_network_interfaces/net0 -o network_name=mgmt device_name=eth0 host_device=br0 mac_prefix=0E:01:04 ipaddresses="${net898_ip_vm[8]}" gateway="${gw_898}" ipv6addresses=$ipv6_898_tp$((ip6_898count++))
	litp create -t vm-nfs-mount -p /ms/services/ms_vm1/vm_nfs_mounts/sfs_mount5 -o mount_point=/nfs_mount5 mount_options=rw,sharecache device_path=${sfs_management_ip}:/vx/ST150_mgmt_sfs-fs4
	litp create -t vm-nfs-mount -p /ms/services/ms_vm1/vm_nfs_mounts/mount5 -o mount_point=/nfs_5 mount_options=soft,defaults device_path="${nfs_ip}":/home/admin/ST/nfs_share_dir_150/dir_share_150_4

# VCS services
litp update -p /deployments/d1/clusters/c1/services/SG_httpd -o online_timeout=46 offline_timeout=91

echo "################# update dependancies list and update initial online dependency"
litp update -p /deployments/d1/clusters/c1/services/SG_httpd -o dependency_list=id_vm4
litp update -p /deployments/d1/clusters/c1/services/SG_ricci -o dependency_list=id_vm4 initial_online_dependency_list="SG_cups"
litp update -p /deployments/d1/clusters/c1/services/SG_cups -o dependency_list=id_vm1,id_vm4
litp update -p /deployments/d1/clusters/c1/services/id_vm1 -o dependency_list=
litp update -p /deployments/d1/clusters/c1/services/id_vm2 -o dependency_list=
litp update -p /deployments/d1/clusters/c1/services/id_vm3 -d dependency_list
litp update -p /deployments/d1/clusters/c1/services/id_vm4 -o dependency_list=
litp update -p /deployments/d1/clusters/c1/services/id_vm5 -o dependency_list=id_vm4
litp update -p /deployments/d1/clusters/c1/services/id_vm6 -d dependency_list

echo "################# Contract a SG - VM2"
contract_a_vm "/deployments/d1/clusters/c1/services/id_vm2"
# Can't contract ricci anymore due to fix for TORF-159242
# litp update -p /deployments/d1/clusters/c1/services/SG_ricci/ -o node_list=n2 active=1 online_timeout=60
# litp update -p /deployments/d1/clusters/c1/services/SG_ricci/applications/s1_ricci/ -o cleanup_command="/bin/false "


echo "################# Add SG using a new repo, remove service installed as a package"
litp import /tmp/test_service-2.0-1.noarch.rpm /var/www/html/newRepo_dir
litp import /tmp/test_service-2.0-1.noarch.rpm /var/www/html/newRepo_dir2
litp import /var/www/html/newRepo_dir /var/www/html/newRepo_dir2
litp create -p /software/items/new_repo_id2 -t yum-repository -o name='new_repo_name' ms_url_path=/newRepo_dir2
litp update -p /software/items/new_repo_id -o ms_url_path=/newRepo_dir2
litp remove -p /deployments/d1/clusters/c1/nodes/n1/items/test_service
litp remove -p /deployments/d1/clusters/c1/nodes/n2/items/test_service
litp create -t service -p /software/services/test_service -o service_name=test_service start_command="/etc/init.d/test_service.sh start" status_command="/etc/init.d/test_service.sh status" stop_command="/etc/init.d/test_service.sh stop"
litp create -p /deployments/d1/clusters/c1/services/test_service -t vcs-clustered-service -o active=2 standby=0 name=FO_test_service online_timeout=45 node_list='n1,n2'
litp inherit -p /software/services/test_service/packages/pkg1 -s /software/items/test_service
litp inherit -p /deployments/d1/clusters/c1/services/test_service/applications/ser -s /software/services/test_service
litp upgrade -p /deployments/d1
echo "################# Remove a SG"
litp remove -p /deployments/d1/clusters/c1/services/SG_dovecot
litp export -p /deployments/d1/clusters/c1/services/SG_dovecot -f /tmp/SG_dovecot.xml
    
echo "################# Change a FO service to a PL"
litp update -p /deployments/d1/clusters/c1/services/SG_cups  -o active=2 standby=0  online_timeout=55 offline_timeout=55
litp update -p /deployments/d1/clusters/c1/services/SG_cups/ha_configs/conf1 -o status_interval=45 status_timeout=35 restart_limit=4 startup_retry_limit=1 fault_on_monitor_timeouts=5 tolerance_limit=2 -d clean_timeout
for (( i=0; i<3; i++ )); do
litp create -t vip   -p /deployments/d1/clusters/c1/services/SG_cups/ipaddresses/t1_ipA${i} -o ipaddress="$ipv4_t1_tp$((ip4_t1count++))" network_name=traffic1
litp create -t vip   -p /deployments/d1/clusters/c1/services/SG_cups/ipaddresses/t2_ipA${i} -o ipaddress="$ipv6_t2_tp$((ip6_t2count++))/64" network_name=traffic2
done
		
# VCS vm-services
echo "################# vm1 update IP's and max number of interfaces, also create alais for each new interface"
litp update -p /software/services/se_vm1/vm_network_interfaces/net0 -o ipv6addresses=$ipv6_898_tp$((ip6_898count++))
litp update -p /software/services/se_vm1/vm_network_interfaces/net1 -o network_name=net1vm device_name=eth1 host_device=br_vip1 mac_prefix=0E:01:03
for (( i=4; i<15; i++ )); do
ipv6=$ipv6_898_tp$((ip6_898count++))
litp create -t vm-network-interface -p /software/services/se_vm1/vm_network_interfaces/net${i} -o network_name=mgmt device_name=eth${i} host_device=br898 ipv6addresses=$ipv6
litp create -t alias    -p /ms/configs/alias_config/aliases/vm1_net${i} -o alias_names=vm1net${i} address=$ipv6
litp create -t alias    -p /deployments/d1/clusters/c1/configs/alias_config/aliases/vm1_net${i} -o alias_names=vm1net${i} address=$ipv6
done;

echo "################# vm1 update multiple properties"
litp update -p /software/services/se_vm1/vm_network_interfaces/net0 -o ipv6addresses=$ipv6_898_tp$((ip6_898count++))
litp update -p /software/services/se_vm1 -o cleanup_command="/sbin/service vm1 stop-undefine --stop-timeout=5"
litp update -p /deployments/d1/clusters/c1/services/id_vm1 -o online_timeout=801 offline_timeout=51
litp update -p /deployments/d1/clusters/c1/services/id_vm1/ha_configs/conf1 -o fault_on_monitor_timeouts=5 tolerance_limit=3 clean_timeout=41 status_interval=71 status_timeout=31 restart_limit=1 -d startup_retry_limit 
litp update -p /deployments/d1/clusters/c1/services/id_vm1/applications/vm -o hostnames=vm1-roverupdate -o cpus=16 -d ram -o cpus=8	
echo "################# vm3 update cleanup command, source_uri info"
litp update -p /software/services/se_vm3 -o cleanup_command="/sbin/service vm3 force-stop-undefine"
litp update -p /software/images/id_image3 -o name="image_vm3" source_uri=http://"${ms_ip}"/images/base_image.qcow2

litp update -p /software/services/se_vm5/vm_aliases/vm_ms1 -o address=fdde:4d7e:d471:4::898:150:f100
litp update -p /software/services/se_vm5/vm_yum_repos/os -o base_url=http://"${ms_host}"/6.6/os/x86_64

echo "################# vm6 remove a vm-service"
litp update -p /deployments/d1/clusters/c1/services/id_vm6/ -o online_timeout=800
litp remove -p /deployments/d1/clusters/c1/services/id_vm6/
litp export -p /deployments/d1/clusters/c1/services/id_vm6/ -f /tmp/vm6.xml
echo "################# vm4 expand a vm-service from 1 to 2 node"
litp update -p /deployments/d1/clusters/c1/services/id_vm4/applications/vm/vm_network_interfaces/net0 -o ipv6addresses=$ipv6_898_tp$((ip6_898count++)),$ipv6_898_tp$((ip6_898count++)) mac_prefix=0E:01:04 ipaddresses="${net898_ip_vm[5]}","${net898_ip_vm[6]}" gateway=$gw_898
litp create -t vm-network-interface -p /software/services/se_vm4/vm_network_interfaces/net1 -o network_name=net835 device_name=eth1 host_device=br835 ipv6addresses=$ipv6_835_tp$((ip6_835count++)),$ipv6_835_tp$((ip6_835count++))
litp update -p /deployments/d1/clusters/c1/services/id_vm4 -o active=2 node_list=n1,n2
litp update -p /deployments/d1/clusters/c1/services/id_vm4/applications/vm/ -d hostnames -o internal_status_check=on

echo "################# remove vcs-network-host"
litp show -p /deployments/d1/clusters/c1/network_hosts/traf_vm105
litp remove -p /deployments/d1/clusters/c1/network_hosts/traf_vm105
litp remove -p /deployments/d1/clusters/c1/network_hosts/traf_vm205

echo "################ add vcs-network-hosts to VCS NIC Resource"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/traf_vm107 -o network_name=net1vm ip=10.46.150.107
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/traf_vm108 -o network_name=net1vm ip=10.46.150.108
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/traf_vm109 -o network_name=net1vm ip=10.46.150.109

echo "################ add vcs-network-hosts to VCS NIC Resource - inferred route"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/traf1_1 -o network_name=traffic1 ip=10.19.150.1
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/traf1_2 -o network_name=traffic1 ip=10.19.150.2

echo "################# Log Rotate updates"
for (( i=0; i<${#node_sysname[@]}; i++ )); do
litp update -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/logrotate/rules/exampleservice -o missingok=false rotate=5 copytruncate=true
done;

echo "################# DNS server"
litp update -p /ms/configs/dns_client/nameservers/my_name_server_C -o position=2
litp update -p /ms/configs/dns_client/nameservers/my_name_server_B -o position=3 ipaddress=2001:4860:0:1001::69
# Sysparms
litp update -p /ms/configs/mynodesysctl/params/sysctl_MS03 -o key=net.ipv6.conf.eth2.max_desync_factor  value=598
# create alias
# added during VCS vm-services vm1 updates
# misc
litp update -p /ms/services/cobbler -o pxe_boot_timeout=405

echo "################# LVM FS mount_point"
litp update -p /infrastructure/storage/storage_profiles/sp1/volume_groups/vg1/file_systems/fs1 -d mount_point
litp update -p /infrastructure/storage/storage_profiles/sp1/volume_groups/vg1/file_systems/fs2 -o mount_point="/mount_ms_fs2_new"
litp create -t vm-disk -p /ms/services/ms_vm1/vm_disks/vm_disk1 -o host_volume_group=vg1 host_file_system=fs1 mount_point=/vm_data_dir1

litp update -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/LVM_VG1_FS0 -d mount_point
litp update -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/LVM_VG1_FS1 -o mount_point="/LVM_mp_VG1_FS1_new"

echo "################### remove vm-network-interface, vm-alias, & vm-package"
litp remove -p /deployments/d1/clusters/c1/services/id_vm5/applications/vm/vm_network_interfaces/net1
litp remove -p /software/services/se_vm4/vm_aliases/vm_mn2
litp remove -p /ms/services/ms_vm1/vm_aliases/vm_mn1
litp remove -p /deployments/d1/clusters/c1/services/id_vm3/applications/vm/vm_aliases/vm_mn1
litp remove -p /deployments/d1/clusters/c1/services/id_vm5/applications/vm/vm_packages/tree

echo "################# update VM image to RHEL7"
litp update -p /software/services/se_vm2 -o image_name=imageRHEL7

echo "################# update VM image to one with custom script functionality"
litp create -t vm-image -p /software/images/image_custom_script -o name="image_custom_script" source_uri=http://"${ms_host}"/images/image_customscript.qcow2
litp update -p /software/services/se_vm1 -o image_name=image_custom_script

echo "################# add custom script to VM"
litp create -t vm-custom-script -p /software/services/se_vm1/vm_custom_script/customscript -o custom_script_names="cscript_crontab.sh"

echo "################ add a VIP to VCS Service Group at retry"
litp create -t vip -p /deployments/d1/clusters/c1/services/id_vm1/ipaddresses/vip_net1vm_1 -o network_name=net1vm ipaddress=10.46.150.125
litp create -t vip -p /deployments/d1/clusters/c1/services/id_vm1/ipaddresses/vip_net1vm_2 -o network_name=net1vm ipaddress=4d7e:d471:150::126/64

echo "################ add an extra SFS pool to an existing SFS service"
litp create -t sfs-pool -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pool2 -o name=ST_Pool2
litp create -t sfs-filesystem -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pool2/file_systems/mgmt_p2_fs -o path=/vx/ST150_mgmt_p2_sfs-fs size=50M
litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mgmt_p2_fs -o provider=virtserv1 mount_point=/mgmt_p2_fs mount_options=soft network_name="${nas_network}" export_path=/vx/ST150_mgmt_p2_sfs-fs
litp create -t sfs-export -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pool2/file_systems/mgmt_p2_fs/exports/ex1 -o ipv4allowed_clients="${allowed_ips}" options=rw,no_root_squash,secure_locks
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/file_systems/mgmt_sfs_p2 -s /infrastructure/storage/nfs_mounts/mgmt_p2_fs
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/file_systems/mgmt_sfs_p2 -s /infrastructure/storage/nfs_mounts/mgmt_p2_fs

echo "############### Update default_nic_monitor property of cluster"
litp update -p /deployments/d1/clusters/c1 -o default_nic_monitor=netstat

echo "############## Update bond0 on node2 to use arp monitoring properties"
litp update -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/b0 -d miimon -o arp_interval=2000 arp_ip_target=10.44.235.1 arp_validate=all arp_all_targets=any

echo "############# Update bond0 on node1 to use miimon"
litp update -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/b0 -o miimon=200 -d arp_interval arp_ip_target arp_validate arp_all_targets

echo "############ Update FO SG to use nofailover trigger TORF-107489 -- and remove nofailover trigger from other SG"
litp create -t vcs-trigger -p /deployments/d1/clusters/c1/services/id_vm1/triggers/test_trig -o trigger_type=nofailover
litp remove -p /deployments/d1/clusters/c1/services/id_vm3/triggers/trig1

echo "############ Update vm-ram-mount type tmpfs to ramfs and change mount_point"
litp update -p /software/services/se_vm4/vm_ram_mounts/vm_ram_mnt -o type=ramfs mount_point="/mnt/ramfs_retry"

echo "############ Update vm-ram-mount type ramfs to tmpfs and change mount_point"
litp update -p /software/services/se_vm1/vm_ram_mounts/vm_ram_mnt -o type=tmpfs mount_point="/mnt/tmpfs_retry"

echo "########### Replace config task in manifest using test plugin (LITPCDS-10650)"
litp update -p /software/items/tc01_foobar1 -o name=tc01_foobar2

echo "########### Update backup_snap_size for LVM volume (TORF-113332)"
litp update -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/LVM_VG1_FS0 -o backup_snap_size=15

echo "########## Add kickstarted filesystems during retry and update others"
litp create -t file-system -p /infrastructure/storage/storage_profiles/sp1/volume_groups/vg1/file_systems/var -o type="ext4" mount_point=/var size=16G snap_size=50 backup_snap_size=50
litp create -t file-system -p /infrastructure/storage/storage_profiles/sp1/volume_groups/vg1/file_systems/software -o type="ext4" mount_point=/software size=50G snap_size=0 backup_snap_size=0
litp update -p /infrastructure/storage/storage_profiles/sp1/volume_groups/vg1/file_systems/root -o backup_snap_size=10
litp update -p /infrastructure/storage/storage_profiles/sp1/volume_groups/vg1/file_systems/home -o size=7G
litp update -p /infrastructure/storage/storage_profiles/sp1/volume_groups/vg1/file_systems/var_www -o snap_size=10 backup_snap_size=15

echo "########## Update multicast properties (TORF-130325)"
litp update -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/mybr1 -o multicast_snooping=0
litp update -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/mybr3 -o multicast_snooping=0
litp update -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/mybr2 -o hash_max=512 multicast_router=2 multicast_querier=1

# TO BE ADDED
#echo "######### add another SFS service with two SFS pools"
#litp create -t sfs-service -p /infrastructure/storage/storage_providers/retry_sfs_service -o name=retry_sfs management_ipv4=10.44.86.31 user_name=support password_key=key-for-sfs
#litp create -t sfs-virtual-server -p /infrastructure/storage/storage_providers/sfs_service_sp1/virtual_servers/vs_retry -o name=virtserv_retry ipv4address=10.44.86.30
#litp create -t sfs-pool -p /infrastructure/storage/storage_providers/retry_sfs_service/pools/pool1 -o name=SFS_Pool
#litp create -t sfs-cache -p /infrastructure/storage/storage_providers/retry_sfs_service/pools/pool1/cache_objects/cache -o name=dot150cashe3
#litp create -t sfs-filesystem -p /infrastructure/storage/storage_providers/retry_sfs_service/pools/pool1/file_systems/fs1 -o path=/vx/ST150_sfs-fs1 size=50M cache_name=dot150cashe3 snap_size=0
#litp create -t nfs-service -p /infrastructure/storage/storage_providers/retry_nfs -o name=nfs_retry ipv4address=10.44.86.5
#litp create -t sfs-export -p /infrastructure/storage/storage_providers/retry_sfs_service/pools/pool1/file_systems/fs1/exports/export1 -o ipv4allowed_clients=10.44.86.211,10.44.86.213,10.44.86.219,10.44.86.215,10.44.86.217,10.44.86.218,10.44.235.153 options=rw,no_root_squash,secure_locks
#litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mgmt_retry_sfs -o provider=virtserv_retry mount_point=/retry_sfs_service_fs mount_options=soft network_name=net837 export_path=/vx/ST150_sfs-fs1
#litp inherit -p /deployments/d1/clusters/c1/nodes/n1/file_systems/mgmt_retry_sfs -s /infrastructure/storage/nfs_mounts/mgmt_retry_sfs
#litp inherit -p /deployments/d1/clusters/c1/nodes/n2/file_systems/mgmt_retry_sfs -s /infrastructure/storage/nfs_mounts/mgmt_retry_sfs

echo "################# Migrate a SG to a different node - id_vm5"
litp update -p /deployments/d1/clusters/c1/services/id_vm5 -o node_list="n2"

echo "################# Add an additional alias to each node which has an unique first entry in alias_name but a duplicate secondary entry."
litp create -p /deployments/d1/clusters/c1/nodes/n1/configs/alias_config/aliases/additional_alias -t alias -o alias_names="additional-alias,secondary-alias" address="127.0.0.1"
litp create -p /deployments/d1/clusters/c1/nodes/n2/configs/alias_config/aliases/additional_alias -t alias -o alias_names="additional-alias,secondary-alias" address="127.0.0.1"

echo "################# Create a new vcs-clustered-service which deactivates a currently deployed one."
litp create -t service -p /software/services/EXTR_lsbwrapper40 -o cleanup_command='/bin/touch /tmp/test-lsb-40.cleanup' service_name='test-lsb-40' stop_command='/sbin/service test-lsb-40 stop' status_command='/sbin/service test-lsb-40 status' start_command='/sbin/service test-lsb-40 start'  
litp inherit -p /software/services/EXTR_lsbwrapper40/packages/pkg1 -s /software/items/EXTR_lsbwrapper40
litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/SG_EXTR_lsbwrapper40 -o node_list="n2" active=1 standby=0 node_list='n2' online_timeout=900 offline_timeout=199 deactivates="SG_EXTR_lsbwrapper39" name="vcs_EXTR_lsbwrapper40"
litp inherit -p /deployments/d1/clusters/c1/services/SG_EXTR_lsbwrapper40/applications/SG_EXTR_lsbwrapper40 -s /software/services/EXTR_lsbwrapper40

litp export -p / -f /tmp/retry_deployment.xml

litp create_plan
