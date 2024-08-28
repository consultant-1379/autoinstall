#!/bin/bash
#
# Sample LITP multi-blade deployment (SAN version)
# This plan will always fail first time as VM vm12 will fail to come online in time
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

set -x
litp update -p /litp/logging -o force_debug=true
litpcrypt set key-for-root root "${nodes_ilo_password}"
litpcrypt set key-for-sfs support "${sfs_password}"

litp create -p /software/profiles/os_prof1 -t os-profile -o name=os-profile1 path=/var/www/html/6/os/x86_64/
litp create -p /deployments/d1 -t deployment
litp create -t vcs-cluster -p /deployments/d1/clusters/c1 -o cluster_type=sfha low_prio_net=mgmt llt_nets=hb1,hb2 cluster_id="${vcs_cluster_id}"
litp create -p /ms/services/cobbler -t cobbler-service

litp create -t ntp-service -p /software/items/ntp1
litp create -t alias-node-config -p /ms/configs/alias_config
for (( i=0; i<2; i++ )); do
        litp create -t alias -p /ms/configs/alias_config/aliases/ntp_alias$(($i+1)) -o alias_names=ntpAliasName$(($i+1)) address="${ntp_ip[$i+1]}"
        litp create -t ntp-server -p /software/items/ntp1/servers/server$(($i+1)) -o server=ntpAliasName$(($i+1))
done

litp update  -p /ms                    -o hostname="${ms_host}"
litp inherit -p /ms/items/ntp          -s /software/items/ntp1
litp create -p /infrastructure/systems/sys1 -t blade -o system_name="${ms_sysname}"

litp create -p /infrastructure/storage/storage_profiles/profile_1 -t storage-profile -o volume_driver=lvm

litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1 -t volume-group -o volume_group_name=vg_root

litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/root -t file-system -o type=ext4 mount_point=/ size=8G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/swap -t file-system -o type=swap mount_point=swap size=2G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/internal -t physical-device -o device_name=hd0

# Create storage volume group VXVM VG 3
litp create -p /infrastructure/storage/storage_profiles/profile_3 -t storage-profile -o volume_driver='vxvm'
for (( i=1; i<5; i++ )); do
    litp create -p /infrastructure/storage/storage_profiles/profile_3/volume_groups/vg_vxvm_$i                                -t volume-group    -o volume_group_name=vg_vxvm_$i
    litp create -p /infrastructure/storage/storage_profiles/profile_3/volume_groups/vg_vxvm_$i/physical_devices/hd_vxvm_$i    -t physical-device -o device_name=VxVM_hd$(($i))
    litp create -p /infrastructure/storage/storage_profiles/profile_3/volume_groups/vg_vxvm_$i/file_systems/VxVMVGFS_$i    -t file-system     -o type=vxfs mount_point=/VxVM_mp_VG_FS$i size=1050M snap_size=100
done
litp inherit -p  /deployments/d1/clusters/c1/storage_profile/sp3 -s /infrastructure/storage/storage_profiles/profile_3


for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp create -p /infrastructure/systems/sys$(($i+2)) -t blade -o system_name="${node_sysname[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk0 -t disk -o name=hd0 size=28G bootable=true uuid="${node_disk_uuid[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/bmc -t bmc -o ipaddress="${node_bmc_ip[$i]}" username=root password_key=key-for-root
    # VxVM disks
    litp create -t disk  -p /infrastructure/systems/sys$(($i+2))/disks/disk1   -o name=VxVM_hd1   size=4G bootable=false uuid="${vxvm_disk_uuid[1]}"
    litp create -t disk  -p /infrastructure/systems/sys$(($i+2))/disks/disk2   -o name=VxVM_hd2   size=4G bootable=false uuid="${vxvm_disk_uuid[2]}"
    litp create -t disk  -p /infrastructure/systems/sys$(($i+2))/disks/disk3   -o name=VxVM_hd3   size=4G bootable=false uuid="${vxvm_disk_uuid[3]}"
    litp create -t disk  -p /infrastructure/systems/sys$(($i+2))/disks/disk4   -o name=VxVM_hd4   size=4G bootable=false uuid="${vxvm_disk_uuid[4]}"
done

litp create -p /infrastructure/networking/routes/r1 -t route -o subnet=0.0.0.0/0 gateway="${nodes_gateway}"
litp create -p /infrastructure/networking/routes/r5 -t route -o subnet="${route_subnet_801}" gateway="${nodes_gateway_ext}"
litp create -p /infrastructure/networking/routes/traffic1_gw -t route -o subnet="${traffic1gw_subnet}" gateway="${traf1_ip[1]}"
litp create -p /infrastructure/networking/routes/traffic2_gw -t route -o subnet="${traffic2gw_subnet}" gateway="${traf2_ip[1]}"

# Create networks
litp create -t network -p /infrastructure/networking/networks/mgmt -o name=mgmt subnet="${nodes_subnet}" litp_management=true
litp create -t network -p /infrastructure/networking/networks/data -o name=data subnet="${nodes_subnet_ext}"
litp create -t network -p /infrastructure/networking/networks/hb1 -o name=hb1
litp create -t network -p /infrastructure/networking/networks/hb2 -o name=hb2
litp create -t network -p /infrastructure/networking/networks/hb3 -o name=hb3
litp create -t network -p /infrastructure/networking/networks/traffic1 -o name=traffic1 subnet="${traffic1_subnet}"
litp create -t network -p /infrastructure/networking/networks/traffic2 -o name=traffic2 subnet="${traffic2_subnet}"
litp create -t network -p /infrastructure/networking/networks/net2vm   -o name=net2vm    subnet="$VM_net2vm_subnet"
litp create -t network -p /infrastructure/networking/networks/net3vm   -o name=net3vm    subnet="$VM_net3vm_subnet"


# MS network
litp create -t eth -p /ms/network_interfaces/if0 -o device_name=eth0 macaddress="${ms_eth0_mac}" master=bond0
litp create -t eth -p /ms/network_interfaces/if1 -o device_name=eth1 macaddress="${ms_eth1_mac}" master=bond0
litp create -t eth -p /ms/network_interfaces/if2 -o device_name=eth2 macaddress="${ms_eth2_mac}" master=bond0
litp create -t eth -p /ms/network_interfaces/if3 -o device_name=eth3 macaddress="${ms_eth3_mac}" master=bond0

litp inherit -p /ms/system -s /infrastructure/systems/sys1

litp create -t bond -p /ms/network_interfaces/b0 -o device_name='bond0' ipaddress="${ms_ip_898_bond}" ipv6address="${ms_ipv6_898_bond}" network_name=mgmt mode=1 miimon=100

litp inherit -p /ms/routes/r1 -s /infrastructure/networking/routes/r1
litp update -p /ms -o hostname="$ms_host"

#Java
litp create -t package -p /software/items/openjdk -o name=java-1.7.0-openjdk
litp inherit -p /ms/items/java -s /software/items/openjdk


#MNs
for (( i=0; i<${#node_sysname[@]}; i++ )); do
     litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1)) -t node -o hostname="${node_hostname[$i]}" node_id="$(($i+1))"
     litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/system -s /infrastructure/systems/sys$(($i+2))
     litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/os -s /software/profiles/os_prof1 
     litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/java -s /software/items/openjdk
     litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/ntp1  -s /software/items/ntp1
     litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/mybr0 -o device_name=br0 forwarding_delay=0 ipaddress="${node_ip_898_bond[$i]}" ipv6address="${node_ipv6_898_bond[$i]}" network_name=mgmt
     litp create -t bond -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/b0 -o device_name='bond0' mode=1 miimon=100 bridge=br0
     litp create -t eth -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if0 -o device_name=eth0 macaddress="${node_eth0_mac[$i]}" master=bond0
     litp create -t eth -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if1 -o device_name=eth1 macaddress="${node_eth1_mac[$i]}" master=bond0
     litp create -t eth -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if2 -o device_name=eth2 macaddress="${node_eth2_mac[$i]}" network_name=hb1
     litp create -t eth -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if3 -o device_name=eth3 macaddress="${node_eth3_mac[$i]}" network_name=hb2
     litp create -t eth -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if4 -o device_name=eth4 macaddress="${node_eth4_mac[$i]}" network_name=hb3
     litp create -t eth -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if5 -o device_name=eth5 macaddress="${node_eth5_mac[$i]}" network_name=traffic1 ipaddress="${traf1_ip[$i]}"
     litp create -t eth -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if6 -o device_name=eth6 macaddress="${node_eth6_mac[$i]}" network_name=traffic2 ipaddress="${traf2_ip[$i]}"
     litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/storage_profile -s /infrastructure/storage/storage_profiles/profile_1
     litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/r1 -s /infrastructure/networking/routes/r1
     litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/r5 -s /infrastructure/networking/routes/r1 -o subnet="${route_subnet_801}" gateway="${nodes_gateway_ext}"
     litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/traffic1_gw -s /infrastructure/networking/routes/traffic1_gw
     litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/traffic2_gw -s /infrastructure/networking/routes/traffic2_gw


     # bridges for VMs
    litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/b0_vip2 -o device_name=bond0.86 bridge=br_vip2
    litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/br_vip2 -o device_name=br_vip2 forwarding_delay=0            network_name=net2vm    ipaddress="${VM_net2vm_ip[$i]}" 

     # bridges for VMs
    litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/b0_vip3 -o device_name=bond0.87 bridge=br_vip3
    litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/br_vip3 -o device_name=br_vip3 forwarding_delay=0            network_name=net3vm    ipaddress="${VM_net3vm_ip[$i]}" 

done
# Log Rotate
for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp create -t logrotate-rule-config -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/logrotate
    litp create -t logrotate-rule        -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/logrotate/rules/logRotate1 -o name="log_rotate1" path="/var/log/exampleservice/exampleservice.log" missingok=true ifempty=true rotate=4 copytruncate=true
    litp create -t logrotate-rule        -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/logrotate/rules/logRotate2 -o name="logRotate2" path="/var/log/exampleservice/tasks/*.log" copytruncate=true rotate=0 missingok=true ifempty=true compress=false create=false
    litp create -t logrotate-rule        -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/logrotate/rules/rotate_maillog -o name="maillog" path="/var/log/maillog" copytruncate=true rotate=7 missingok=true ifempty=true compress=false create=false size=1k dateext=true dateformat=%Y-%m-%d-%s mailfirst=true maillast=false maxage=5
done;

litp create -t logrotate-rule-config -p /ms/configs/logrotate
litp create -t logrotate-rule        -p /ms/configs/logrotate/rules/exampleservice -o name="exampleservice" path="/var/log/exampleservice/exampleservice.log" missingok=true ifempty=true rotate=4 copytruncate=true
litp create -t logrotate-rule        -p /ms/configs/logrotate/rules/exampleservice_tasks -o name="exampleservice_tasks" path="/var/log/exampleservice/tasks/*.log" copytruncate=true rotate=0 missingok=true ifempty=true compress=false create=false compressext="zip" maxage=5
litp create -t logrotate-rule        -p /ms/configs/logrotate/rules/rotate_maillog -o name="maillog" path="/var/log/maillog" copytruncate=true rotate=5 missingok=false ifempty=false compress=false create=false size=1k dateext=false dateformat=%Y-%m-%d-%s mailfirst=true maillast=false maxage=5 start=150 uncompresscmd="anystring"

##### NAS #######
# SFS unmanaged ONLY
litp create -t sfs-service -p /infrastructure/storage/storage_providers/sfs_service_sp1 -o name="sfs1" 
litp create -t sfs-virtual-server -p /infrastructure/storage/storage_providers/sfs_service_sp1/virtual_servers/vs1 -o name="virtserv1" ipv4address="${sfs_vip}"

# unmanaged in pool SFS_Pool
litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mount1 -o export_path=${sfs_prefix}_unmgmt-fs1 provider=virtserv1 mount_point=/SFS_unmgmt_fs1 mount_options=soft,intr network_name=mgmt
litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mount2 -o export_path=${sfs_prefix}_unmgmt-fs2 provider=virtserv1 mount_point=/SFS_unmgmt_fs2 mount_options=soft,intr network_name=mgmt

# unmanaged in pool ST_Pool
litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mount3 -o export_path=${sfs_prefix}-pool2-unmanaged1 provider=virtserv1 mount_point=/SFS_unmgmt_fs3 mount_options=soft,intr network_name=mgmt

litp inherit -p /ms/file_systems/nm1 -s /infrastructure/storage/nfs_mounts/mount1
litp inherit -p /ms/file_systems/nm2 -s /infrastructure/storage/nfs_mounts/mount2

for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/file_systems/fs1 -s /infrastructure/storage/nfs_mounts/mount1
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/file_systems/fs2 -s /infrastructure/storage/nfs_mounts/mount2
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/file_systems/fs3 -s /infrastructure/storage/nfs_mounts/mount3
done


##### NFS #######
# NFS 2 directory shares
litp create -t nfs-service -p /infrastructure/storage/storage_providers/nfs_service_sp1 -o name="nfs1" ipv4address="${nfs_management_ip}"
litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/nfs1 -o export_path="${nfs_prefix}/ro_unmanaged" provider="nfs1" mount_point="/nfs_cluster_ro" mount_options="soft,noexec,nosuid" network_name="mgmt"
litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/nfs2 -o export_path="${nfs_prefix}/rw_unmanaged" provider="nfs1" mount_point="/nfs_cluster_rw" mount_options="soft,noexec,nosuid" network_name="mgmt"

litp inherit -p /deployments/d1/clusters/c1/nodes/n1/file_systems/nfs1 -s /infrastructure/storage/nfs_mounts/nfs1
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/file_systems/nfs1 -s /infrastructure/storage/nfs_mounts/nfs1
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/file_systems/nfs2 -s /infrastructure/storage/nfs_mounts/nfs2
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/file_systems/nfs2 -s /infrastructure/storage/nfs_mounts/nfs2

litp inherit -p /ms/file_systems/nfs1 -s /infrastructure/storage/nfs_mounts/nfs1
litp inherit -p /ms/file_systems/nfs2 -s /infrastructure/storage/nfs_mounts/nfs2


litp create -t yum-repository -p /software/items/yum_osHA_repo -o name="osHA" base_url="http://"${ms_host}"/6/os/x86_64/HighAvailability"
litp inherit -s /software/items/yum_osHA_repo -p /deployments/d1/clusters/c1/nodes/n1/items/yum_osHA_repo
litp inherit -s /software/items/yum_osHA_repo -p /deployments/d1/clusters/c1/nodes/n2/items/yum_osHA_repo


# VCS Service Groups
litp create  -t package -p /software/items/sentinel    -o name=EXTRlitpsentinellicensemanager_CXP9031488
litp inherit            -p /ms/items/sentinel                                     -s /software/items/sentinel
litp create  -t service -p /ms/services/sentinel       -o service_name=sentinel
litp create  -t service -p /software/services/sentinel -o service_name=sentinel
litp inherit            -p /software/services/sentinel/packages/sentinel          -s /software/items/sentinel
litp inherit            -p /deployments/d1/clusters/c1/nodes/n1/services/sentinel -s /software/services/sentinel

# Create the software packages.
litp create -t package -p /software/items/luci -o name=luci repository=OS release=63.el6 version=0.26.0
litp create -t package -p /software/items/cups -o name=cups release=67.el6 version=1.4.2 epoch=1

#FAILOVER SG - with 2 SG
litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/multiple_SG -o active=1 standby=1 name=FO_MULTISG online_timeout=80 node_list=n1,n2

#litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/multiple_SG/ha_configs/service1_conf -o status_interval=10 status_timeout=10 restart_limit=5 startup_retry_limit=2 app_offline_timeout=300 app_online_timeout=300 service_id=service1
#litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/multiple_SG/ha_configs/service2_conf -o status_interval=10 status_timeout=10 restart_limit=5 startup_retry_limit=2 app_offline_timeout=300 app_online_timeout=300 service_id=service2 dependency_list=service1

litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/multiple_SG/ha_configs/service1_conf -o status_interval=10 status_timeout=10 restart_limit=5 startup_retry_limit=2 service_id=service1
litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/multiple_SG/ha_configs/service2_conf -o status_interval=10 status_timeout=10 restart_limit=5 startup_retry_limit=2 service_id=service2 dependency_list=service1

litp create -t service -p /software/services/luci -o service_name=luci
litp inherit -p /software/services/luci/packages/pkg1 -s /software/items/luci

litp create -t service -p /software/services/cups -o service_name=cups
litp inherit -p /software/services/cups/packages/pkg1 -s /software/items/cups

litp inherit -p /deployments/d1/clusters/c1/services/multiple_SG/applications/service1 -s /software/services/luci
litp inherit -p /deployments/d1/clusters/c1/services/multiple_SG/applications/service2 -s /software/services/cups


# Add VxVM FS
litp inherit -p /deployments/d1/clusters/c1/services/multiple_SG/filesystems/VxVX_fs1 -s /deployments/d1/clusters/c1/storage_profile/sp3/volume_groups/vg_vxvm_1/file_systems/VxVMVGFS_1
litp inherit -p /deployments/d1/clusters/c1/services/multiple_SG/filesystems/VxVX_fs2 -s /deployments/d1/clusters/c1/storage_profile/sp3/volume_groups/vg_vxvm_2/file_systems/VxVMVGFS_2
litp inherit -p /deployments/d1/clusters/c1/services/multiple_SG/filesystems/VxVX_fs3 -s /deployments/d1/clusters/c1/storage_profile/sp3/volume_groups/vg_vxvm_3/file_systems/VxVMVGFS_3
litp inherit -p /deployments/d1/clusters/c1/services/multiple_SG/filesystems/VxVX_fs4 -s /deployments/d1/clusters/c1/storage_profile/sp3/volume_groups/vg_vxvm_4/file_systems/VxVMVGFS_4


for (( i=1; i<4; i++ )); do

 litp create -t vip -p /deployments/d1/clusters/c1/services/multiple_SG/ipaddresses/ip${i} -o ipaddress="${traf1_vip[$(($i+1))]}"  network_name=traffic1
 litp create -t vip -p /deployments/d1/clusters/c1/services/multiple_SG/ipaddresses/ip$(($i+3)) -o ipaddress="${traf2_vip[$(($i+1))]}" network_name=traffic2

done

# Create Parallel SG

litp create -t package -p /software/items/httpd -o name=httpd repository=OS version=2.2.15 release=39.el6

# removed from sp 14 litp create -t package -p /software/items/httpd -o name=httpd repository=OS release=29.el6_4 version=2.2.15
# sp 14 litp create -t package -p /software/items/httpd -o name=httpd repository=OS release=26.el6 version=2.2.15

litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/SG_httpd -o active=2 standby=0 name=vcs3 online_timeout=45 node_list=n1,n2 dependency_list=
litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/SG_httpd/ha_configs/conf1 -o status_interval=20 status_timeout=60 restart_limit=10 startup_retry_limit=10
litp create -t service -p /software/services/httpd -o service_name=httpd
litp inherit -p /software/services/httpd/packages/pkg1 -s /software/items/httpd
litp inherit -p /deployments/d1/clusters/c1/services/SG_httpd/applications/httpd -s /software/services/httpd

litp create -t package -p /software/items/httpd-tools -o name=httpd-tools version=2.2.15 release=39.el6
for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/httpd-tools -s /software/items/httpd-tools
done;



# Setup the fencing disks
litp create -t disk -p /deployments/d1/clusters/c1/fencing_disks/fd1 -o size=90M uuid="${fencing_disk_uuid[0]}" name=fd1
litp create -t disk -p /deployments/d1/clusters/c1/fencing_disks/fd2 -o size=90M uuid="${fencing_disk_uuid[1]}" name=fd2
litp create -t disk -p /deployments/d1/clusters/c1/fencing_disks/fd3 -o size=90M uuid="${fencing_disk_uuid[2]}" name=fd3

# Create VM's
/usr/bin/md5sum /var/www/html/images/image.qcow2 | cut -d ' ' -f 1 > /var/www/html/images/image.qcow2.md5

x=11
x=$[$x+1] VM_cpu[x]=4; VM_ram[x]=2000M; VM_active[x]=1; VM_standby[x]=1 VM_node_list[x]="n1,n2"  
#x=$[$x+1] VM_cpu[x]=1; VM_ram[x]=32M;  VM_active[x]=2; VM_standby[x]=0 VM_node_list[x]="n1,n2" VM_dependency_list[x]="id_vm$[$x+1]" VM_ip[x]=10.44.235.153,10.44.235.154
x=$[$x+1] VM_cpu[x]=8; VM_ram[x]=4000M;  VM_active[x]=1; VM_standby[x]=1 VM_node_list[x]="n2,n1" 

for (( i=12; i<14; i++ )); do
    litp create -t vm-image    -p /software/images/id_image$i -o name="image_vm$i" source_uri=http://"${ms_host}"/images/image.qcow2
    litp create -t vm-service  -p /software/services/se_vm$i  -o service_name=vm$i image_name=image_vm$i  cpus="${VM_cpu[i]}" ram="${VM_ram[i]}" internal_status_check=on cleanup_command="/sbin/service vm$i force-stop"
    litp create -t vm-alias    -p /software/services/se_vm$i/vm_aliases/vm_ms1    -o alias_names=ms1,"${ms_host}","Ammeon-LITP-mars-VIP.ammeonvpn.com"             address="${ms_ip}"
    litp create -t vm-alias    -p /software/services/se_vm$i/vm_aliases/vm_mn1    -o alias_names=mn1,"${node_hostname[0]}","Ammeon-LITP-Tag-898-VIP.ammeonvpn.com" address="${node_ip[0]}"
    litp create -t vm-alias    -p /software/services/se_vm$i/vm_aliases/vm_mn2    -o alias_names="${node_hostname[1]}"                                             address="${node_ip[1]}"
    litp create -t vm-yum-repo -p /software/services/se_vm$i/vm_yum_repos/updates -o name=vm_UPDATES base_url="http://"${ms_host}"/6.6/updates/x86_64/Packages"
    litp create -t vm-yum-repo -p /software/services/se_vm$i/vm_yum_repos/os      -o name=vm_os      base_url="http://"${ms_ip}"/6.6/os/x86_64"
    litp create -t vm-yum-repo -p /software/services/se_vm$i/vm_yum_repos/3pp     -o name=vm_3pp     base_url="http://"Ammeon-LITP-mars-VIP.ammeonvpn.com"/3pp"
    litp create -t vm-yum-repo -p /software/services/se_vm$i/vm_yum_repos/litp    -o name=vm_litp    base_url="http://"${ms_host}"/litp"
    litp create -t vm-package  -p /software/services/se_vm$i/vm_packages/firefox  -o name=firefox
    litp create -t vm-package  -p /software/services/se_vm$i/vm_packages/cups     -o name=cups
    litp create -t vm-network-interface  -p /software/services/se_vm$i/vm_network_interfaces/net1 -o network_name=mgmt device_name=eth0 host_device=br0 gateway="${ms_gateway}"
    litp create -t vm-network-interface  -p /software/services/se_vm$i/vm_network_interfaces/net2 -o network_name=net2vm device_name=eth1 host_device=br_vip2 
    litp create -t vm-network-interface  -p /software/services/se_vm$i/vm_network_interfaces/net3 -o network_name=net3vm device_name=eth2 host_device=br_vip3  

    litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/id_vm$i  -o name=vm$i active="${VM_active[$i]}" standby="${VM_standby[$i]}" node_list="${VM_node_list[i]}" dependency_list="${VM_dependency_list[$i]}" online_timeout=300 # Leave timeout as default 
    litp inherit                         -p /deployments/d1/clusters/c1/services/id_vm$i/applications/vm -s /software/services/se_vm$i
    litp update                          -p /deployments/d1/clusters/c1/services/id_vm$i/applications/vm/vm_network_interfaces/net1 -o ipaddresses="${eth0_ip[i]}"
    litp update                          -p /deployments/d1/clusters/c1/services/id_vm$i/applications/vm/vm_network_interfaces/net2 -o ipaddresses="${eth1_ip[i]}"
    litp update                          -p /deployments/d1/clusters/c1/services/id_vm$i/applications/vm/vm_network_interfaces/net3 -o ipaddresses="${eth2_ip[i]}"


# Mount NFS
    litp create -t vm-nfs-mount -p /software/services/se_vm$i/vm_nfs_mounts/mount1 -o mount_point="/mnt/ro_unmanaged" device_path="${nfs_management_ip}:${nfs_prefix}/ro_unmanaged"
    litp create -t vm-nfs-mount -p /software/services/se_vm$i/vm_nfs_mounts/mount2 -o mount_point="/mnt/rw_unmanaged" device_path="${nfs_management_ip}:${nfs_prefix}/rw_unmanaged"
done

# Setup ip forwarding - temporary work around
#litp create -t sysparam-node-config -p /deployments/d1/clusters/c1/nodes/n1/configs/mynodesysctl
#litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n1/configs/mynodesysctl/params/sysctl001 -o  key="net.ipv4.ip_forward" value="1"
#litp create -t sysparam-node-config -p /deployments/d1/clusters/c1/nodes/n2/configs/mynodesysctl
#litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n2/configs/mynodesysctl/params/sysctl001 -o  key="net.ipv4.ip_forward" value="1"


# increase VM13 and VM12's online_timeout 
litp update -p /deployments/d1/clusters/c1/services/id_vm13 -o online_timeout=600 
litp update -p /deployments/d1/clusters/c1/services/id_vm12 -o online_timeout=600

# configure vm12 for HA
litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/id_vm12/ha_configs/conf2 -o status_interval=300 status_timeout=300 restart_limit=5 startup_retry_limit=5

#Adding network hosts for vms
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/traf_vm200 -o network_name=net2vm ip="${VM_net2vm_ip[0]}" 
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/traf_vm300 -o network_name=net3vm ip="${VM_net3vm_ip[0]}" 
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/traf_vm201 -o network_name=net2vm ip="${VM_net2vm_ip[1]}" 
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/traf_vm301 -o network_name=net3vm ip="${VM_net3vm_ip[1]}" 

#dns
litp create -t dhcp-service -p /software/services/s1 -o service_name="dhcp_svc1" ntpservers="10.44.86.30"
litp create -t dhcp-subnet -p /software/services/s1/subnets/s1 -o network_name="net2vm"
litp create -t dhcp-range -p /software/services/s1/subnets/s1/ranges/r1 -o start="${net2vm_dhcp_start}" end="${net2vm_dhcp_end}"

litp inherit -p /deployments/d1/clusters/c1/nodes/n1/services/s1 -s /software/services/s1 

litp create_plan
