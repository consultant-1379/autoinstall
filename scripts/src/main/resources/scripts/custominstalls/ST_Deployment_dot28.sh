#!/bin/bash
#
if [ "$#" -lt 1 ]; then
    echo -e "Usage:\n  $0 <CLUSTER_SPEC_FILE>" >&2
    exit 1
fi

cluster_file="$1"
source "$cluster_file"

#set -x
litp update -p /litp/logging -o force_debug=true
#litpcrypt set key-for-root root "${nodes_ilo_password}"
#litpcrypt set key-for-sfs support "${sfs_password}"

litp create -p /software/profiles/os_prof1 -t os-profile -o name=os-profile1 path=/var/www/html/6/os/x86_64/

litp create -p /software/items/ntp1 -t ntp-service
litp create -p /ms/configs/alias_config -t alias-node-config
litp create -p /ms/configs/alias_config/aliases/ntp_alias1 -t alias -o alias_names=ntpAlias1 address=10.44.86.30
litp create -p /software/items/ntp1/servers/server0 -t ntp-server -o server=ntpAlias1

litp create -p /deployments/d1 -t deployment
#litp create -p /deployments/d1/clusters/c1 -t vcs-cluster -o cluster_type=sfha low_prio_net=mgmt llt_nets=hb1,hb2 cluster_id=4728
#litp create -p /deployments/d1/clusters/c1/configs/fw_config_init -t firewall-cluster-config
#litp create -p /deployments/d1/clusters/c1/configs/fw_config_init/rules/fw_icmp -t firewall-rule -o 'name=100 icmp' proto=icmp

litp create -p /ms/services/cobbler -t cobbler-service
litp create -p /infrastructure/storage/storage_profiles/profile_1 -t storage-profile
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1 -t volume-group -o volume_group_name=vg_root
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/root -t file-system -o type=ext4 mount_point=/ size=8G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/swap -t file-system -o type=swap mount_point=swap size=2G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/internal -t physical-device -o device_name=hd0
#litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg2 -t volume-group -o volume_group_name=vg_data
#litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg2/file_systems/data1 -t file-system -o type=ext4 mount_point=/data1 size=2G snap_size=0
#litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg2/physical_devices/internal -t physical-device -o device_name=hd1

litp create -p /infrastructure/systems/sys1 -t blade -o system_name=CZ3217FFJ2

#litp create -p /infrastructure/systems/sys2 -t blade -o system_name=WH03MP3507
#litp create -p /infrastructure/systems/sys2/disks/disk0 -t disk -o name=hd0 size=28G bootable=true uuid=600508b1001c5cc74dab2673ee6ef471
#litp create -p /infrastructure/systems/sys2/bmc -t bmc -o ipaddress=10.44.84.12 username=root password_key=key-for-root

#litp create -p /infrastructure/systems/sys3 -t blade -o system_name=CZ3218HDVR
#litp create -p /infrastructure/systems/sys3/disks/disk0 -t disk -o name=hd0 size=28G bootable=true uuid=600508b1001c07559150027921a7b59f
#litp create -p /infrastructure/systems/sys3/bmc -t bmc -o ipaddress=10.44.84.64 username=root password_key=key-for-root

litp create -p /infrastructure/networking/routes/r1 -t route -o subnet=0.0.0.0/0 gateway=10.44.86.1
litp create -p /infrastructure/networking/networks/mgmt -t network -o name=mgmt subnet=10.44.86.0/26 litp_management=true
litp create -p /infrastructure/networking/networks/heartbeat1 -t network -o name=hb1
litp create -p /infrastructure/networking/networks/heartbeat2 -t network -o name=hb2
litp create -p /infrastructure/networking/networks/traffic1 -t network -o name=traffic1 subnet=192.168.100.0/24
litp create -p /infrastructure/networking/networks/traffic2 -t network -o name=traffic2 subnet=192.168.200.128/24

litp inherit -p /ms/system -s /infrastructure/systems/sys1
litp create -p /ms/network_interfaces/if0 -t eth -o device_name=eth0 macaddress=98:4B:E1:02:74:AA network_name=traffic1 ipaddress=192.168.100.97
litp create -p /ms/network_interfaces/vlan834 -t vlan -o device_name=eth0.834 network_name=mgmt ipaddress=10.44.86.28

litp create -p /ms/configs/fw_config_init -t firewall-node-config
litp create -p /ms/configs/fw_config_init/rules/fw_icmp -t firewall-rule -o 'name=100 icmp' proto=icmp

litp create -t package -p /software/items/openjdk -o name=java-1.7.0-openjdk
litp inherit -p /ms/items/java -s /software/items/openjdk

litp inherit -p /ms/routes/r1 -s /infrastructure/networking/routes/r1
litp inherit -p /ms/items/ntp -s /software/items/ntp1
litp update -p /ms -o hostname=ms1

#litp create -p /deployments/d1/clusters/c1/nodes/n1 -t node -o hostname=node1
#litp inherit -p /deployments/d1/clusters/c1/nodes/n1/system -s /infrastructure/systems/sys2
#litp inherit -p /deployments/d1/clusters/c1/nodes/n1/os -s /software/profiles/os_prof1
#litp inherit -p /deployments/d1/clusters/c1/nodes/n1/storage_profile -s /infrastructure/storage/storage_profiles/profile_1
#litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/ntp1 -s /software/items/ntp1
#litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/java -s /software/items/openjdk
#litp create -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if0 -t eth -o device_name=eth0 macaddress=D8:D3:85:E0:C5:70 ipaddress=10.44.86.8 network_name=mgmt
#litp create -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if2 -t eth -o device_name=eth2 macaddress=D8:D3:85:E0:C5:71 network_name=hb1
#litp create -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if3 -t eth -o device_name=eth3 macaddress=D8:D3:85:E0:C5:75 network_name=hb2
##litp create -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if4 -t eth -o device_name=eth4 macaddress=D8:D3:85:E0:C5:72 network_name=traffic1 ipaddress=192.168.100.2
##litp create -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if5 -t eth -o device_name=eth5 macaddress=D8:D3:85:E0:C5:76 network_name=traffic2 ipaddress=192.168.200.130
#litp create -p /deployments/d1/clusters/c1/nodes/n1/configs/fw_config_init -t firewall-node-config
#litp inherit -p /deployments/d1/clusters/c1/nodes/n1/routes/r1 -s /infrastructure/networking/routes/r1

#litp create -p /deployments/d1/clusters/c1/nodes/n2 -t node -o hostname=node2
#litp inherit -p /deployments/d1/clusters/c1/nodes/n2/system -s /infrastructure/systems/sys3
#litp inherit -p /deployments/d1/clusters/c1/nodes/n2/os -s /software/profiles/os_prof1
#litp inherit -p /deployments/d1/clusters/c1/nodes/n2/storage_profile -s /infrastructure/storage/storage_profiles/profile_1
#litp inherit -p /deployments/d1/clusters/c1/nodes/n2/items/ntp1 -s /software/items/ntp1
#litp inherit -p /deployments/d1/clusters/c1/nodes/n2/items/java -s /software/items/openjdk
#litp create -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if0 -t eth -o device_name=eth0 macaddress=80:C1:6E:7A:B8:D0 ipaddress=10.44.86.47 network_name=mgmt
#litp create -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if2 -t eth -o device_name=eth2 macaddress=80:C1:6E:7A:B8:D1 network_name=hb1
#litp create -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if3 -t eth -o device_name=eth3 macaddress=80:C1:6E:7A:B8:D5 network_name=hb2
#litp create -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if4 -t eth -o device_name=eth4 macaddress=80:C1:6E:7A:B8:D2 network_name=traffic1 ipaddress=192.168.100.3
#litp create -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if5 -t eth -o device_name=eth5 macaddress=80:C1:6E:7A:B8:D6 network_name=traffic2 ipaddress=192.168.200.131
#litp create -p /deployments/d1/clusters/c1/nodes/n2/configs/fw_config_init -t firewall-node-config
#litp inherit -p /deployments/d1/clusters/c1/nodes/n2/routes/r1 -s /infrastructure/networking/routes/r1

#litp create -p /deployments/d1/clusters/c1/services/cups -t vcs-clustered-service -o active=1 standby=1 name=FO_vcs1 online_timeout=45 node_list=n1,n2
#litp create -p /deployments/d1/clusters/c1/services/cups/runtimes/cups -t lsb-runtime -o name=cups service_name=cups
#litp create -p /software/items/cups -t package -o name=cups
#litp inherit -p /deployments/d1/clusters/c1/services/cups/runtimes/cups/packages/pkg1 -s /software/items/cups
#litp create -p /deployments/d1/clusters/c1/services/postfix -t vcs-clustered-service -o active=1 standby=1 name=FO_vcs2 online_timeout=45 node_list=n1,n2
#litp create -p /deployments/d1/clusters/c1/services/postfix/runtimes/postfix -t lsb-runtime -o name=postfix service_name=postfix
#litp create -p /software/items/postfix -t package -o name=postfix
#litp inherit -p /deployments/d1/clusters/c1/services/postfix/runtimes/postfix/packages/pkg1 -s /software/items/postfix
#litp create -p /deployments/d1/clusters/c1/services/httpd -t vcs-clustered-service -o active=2 standby=0 name=PL_vcs1 node_list=n1,n2
#litp create -p /deployments/d1/clusters/c1/services/httpd/runtimes/httpd -t lsb-runtime -o name=httpd service_name=httpd
#litp create -p /software/items/httpd -t package -o name=httpd
#litp inherit -p /deployments/d1/clusters/c1/services/httpd/runtimes/httpd/packages/pkg1 -s /software/items/httpd
#litp create -p /deployments/d1/clusters/c1/services/ricci -t vcs-clustered-service -o active=2 standby=0 name=PL_vcs2 node_list=n1,n2
#litp create -p /deployments/d1/clusters/c1/services/ricci/runtimes/ricci -t lsb-runtime -o name=ricci service_name=ricci
#litp create -p /software/items/ricci -t package -o name=ricci
#litp inherit -p /deployments/d1/clusters/c1/services/ricci/runtimes/ricci/packages/pkg1 -s /software/items/ricci

litp create_plan

