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

set -x
function litp(){
    command litp "$@" 2>&1
    retval=( $(echo "$?") )
    if [ $retval -ne 0 ]
    then
        exit 1
    fi
}


litpcrypt set key-for-root root 'Amm30n!!'

litp create -p /software/profiles/os_prof1 -t os-profile -o name=os-profile1 path=/var/www/html/6/os/x86_64/

litp create -p /software/items/ntp1 -t ntp-service
litp create -p /ms/configs/alias_config -t alias-node-config
litp create -p /ms/configs/alias_config/aliases/ntp_alias1 -t alias -o alias_names=ntpAlias1 address=10.44.86.30
litp create -p /software/items/ntp1/servers/server0 -t ntp-server -o server=ntpAlias1

litp create -p /deployments/d1 -t deployment
litp create -p /deployments/d1/clusters/c1 -t vcs-cluster -o cluster_type=sfha low_prio_net=mgmt llt_nets=hb1,hb2 cluster_id=4791 default_nic_monitor=mii
litp create -p /deployments/d1/clusters/c1/configs/fw_config_init -t firewall-cluster-config
litp create -p /deployments/d1/clusters/c1/configs/fw_config_init/rules/fw_icmp -t firewall-rule -o 'name=100 icmp' proto=icmp
litp create -p /deployments/d1/clusters/c1/configs/fw_config_init/rules/fw_icmp_ip6 -t firewall-rule -o 'name=101 icmpipv6' proto=ipv6-icmp

litp create -p /ms/services/cobbler -t cobbler-service
litp create -p /infrastructure/storage/storage_profiles/profile_1 -t storage-profile
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1 -t volume-group -o volume_group_name=vg_root
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/root -t file-system -o type=ext4 mount_point=/ size=8G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/swap -t file-system -o type=swap mount_point=swap size=2G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/internal -t physical-device -o device_name=hd0
#litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg2 -t volume-group -o volume_group_name=vg_data
#litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg2/file_systems/data1 -t file-system -o type=ext4 mount_point=/data1 size=2G snap_size=0
#litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg2/physical_devices/internal -t physical-device -o device_name=hd1

litp create -p /infrastructure/systems/sys1 -t blade -o system_name=CZ3129MH0H

litp create -p /infrastructure/systems/sys2 -t blade -o system_name=CZ3128LSEA
litp create -p /infrastructure/systems/sys2/disks/disk0 -t disk -o name=hd0 size=28G bootable=true uuid=6006016057602d00a663a7b58678e311
litp create -p /infrastructure/systems/sys2/bmc -t bmc -o ipaddress=10.44.84.14 username=root password_key=key-for-root

litp create -p /infrastructure/systems/sys3 -t blade -o system_name=CZ3128LSEM
litp create -p /infrastructure/systems/sys3/disks/disk0 -t disk -o name=hd0 size=28G bootable=true uuid=6006016057602d00948f562d8778e311
litp create -p /infrastructure/systems/sys3/bmc -t bmc -o ipaddress=10.44.84.49 username=root password_key=key-for-root

litp create -p /infrastructure/networking/routes/r1 -t route -o subnet=0.0.0.0/0 gateway=10.44.86.65
litp create -p /infrastructure/networking/networks/mgmt -t network -o name=mgmt subnet=10.44.86.64/26 litp_management=true
litp create -p /infrastructure/networking/networks/heartbeat1 -t network -o name=hb1
litp create -p /infrastructure/networking/networks/heartbeat2 -t network -o name=hb2
litp create -p /infrastructure/networking/networks/traffic1 -t network -o name=traffic1 subnet=192.168.100.0/24
litp create -p /infrastructure/networking/networks/traffic2 -t network -o name=traffic2 subnet=192.168.200.128/24

litp inherit -p /ms/system -s /infrastructure/systems/sys1
litp create -p /ms/network_interfaces/if0 -t eth -o device_name=eth0 macaddress=78:AC:C0:FB:55:42 network_name=traffic1 ipaddress=192.168.100.97
litp create -p /ms/network_interfaces/vlan835 -t vlan -o device_name=eth0.835 network_name=mgmt ipaddress=10.44.86.91

litp create -p /ms/configs/fw_config_init -t firewall-node-config
litp create -p /ms/configs/fw_config_init/rules/fw_icmp -t firewall-rule -o 'name=100 icmp' proto=icmp
litp inherit -p /ms/routes/r1 -s /infrastructure/networking/routes/r1
litp inherit -p /ms/items/ntp -s /software/items/ntp1
litp update -p /ms -o hostname=ms1

litp create -p /deployments/d1/clusters/c1/nodes/n1 -t node -o hostname=node1
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/system -s /infrastructure/systems/sys2
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/os -s /software/profiles/os_prof1
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/storage_profile -s /infrastructure/storage/storage_profiles/profile_1
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/ntp1 -s /software/items/ntp1
litp create -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if0 -t eth -o device_name=eth0 macaddress=98:4B:E1:68:1D:70 ipaddress=10.44.86.95 network_name=mgmt
litp create -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if2 -t eth -o device_name=eth2 macaddress=98:4B:E1:68:1D:71 network_name=hb1
litp create -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if3 -t eth -o device_name=eth3 macaddress=98:4B:E1:68:1D:75 network_name=hb2
#litp create -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if4 -t eth -o device_name=eth4 macaddress=98:4B:E1:68:1D:70 network_name=traffic1 ipaddress=192.168.100.2
#litp create -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if5 -t eth -o device_name=eth5 macaddress=98:4B:E1:68:1D:70 network_name=traffic2 ipaddress=192.168.200.130
litp create -p /deployments/d1/clusters/c1/nodes/n1/configs/fw_config_init -t firewall-node-config
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/routes/r1 -s /infrastructure/networking/routes/r1

litp create -p /deployments/d1/clusters/c1/nodes/n2 -t node -o hostname=node2
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/system -s /infrastructure/systems/sys3
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/os -s /software/profiles/os_prof1
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/storage_profile -s /infrastructure/storage/storage_profiles/profile_1
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/items/ntp1 -s /software/items/ntp1
litp create -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if0 -t eth -o device_name=eth0 macaddress=98:4B:E1:69:B1:D8 ipaddress=10.44.86.96 network_name=mgmt
litp create -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if2 -t eth -o device_name=eth2 macaddress=98:4B:E1:69:B1:D9 network_name=hb1
litp create -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if3 -t eth -o device_name=eth3 macaddress=98:4B:E1:69:B1:DD network_name=hb2
#litp create -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if4 -t eth -o device_name=eth4 macaddress=2C:59:E5:3D:B3:6A network_name=traffic1 ipaddress=192.168.100.3
#litp create -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if5 -t eth -o device_name=eth5 macaddress=2C:59:E5:3D:B3:6E network_name=traffic2 ipaddress=192.168.200.131
litp create -p /deployments/d1/clusters/c1/nodes/n2/configs/fw_config_init -t firewall-node-config
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/routes/r1 -s /infrastructure/networking/routes/r1
litp create_plan

