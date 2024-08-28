#!/bin/bash
#
# Sample LITP multi-blade deployment (SAN version)
#
# Usage:
#   ST_Deployment_12.sh <CLUSTER_SPEC_FILE>
##

litp update -p /litp/logging -o force_debug=true

if [ "$#" -lt 1 ]; then
    echo -e "Usage:\n  $0 <CLUSTER_SPEC_FILE>" >&2
    exit 1
fi

cluster_file="$1"
source "$cluster_file"

set -x

litpcrypt set key-for-root root "${nodes_ilo_password}"
litpcrypt set key-for-sfs support support
litp create -p /software/profiles/os_prof1 -t os-profile -o name=os-profile1 path=/var/www/html/6/os/x86_64/
litp create -p /ms/services/cobbler -o pxe_boot_timeout=360 -t cobbler-service
litp create -p /infrastructure/systems/sys1 -t blade -o system_name="${ms_sysname}"


# Setup MS disk and storage_profile with FS
litp create -t disk -p /infrastructure/systems/sys1/disks/d1 -o name="hdms1" size=550G bootable="true" uuid=$ms_disk_uuid
litp create -t storage-profile -p /infrastructure/storage/storage_profiles/spms
litp create -t volume-group -p /infrastructure/storage/storage_profiles/spms/volume_groups/vg1 -o volume_group_name="vg_root"
litp create -t file-system -p /infrastructure/storage/storage_profiles/spms/volume_groups/vg1/file_systems/fs1 -o type="ext4" mount_point="/data_dir1" size="200M" snap_size="5" snap_external="false"
litp create -t file-system -p /infrastructure/storage/storage_profiles/spms/volume_groups/vg1/file_systems/fs2 -o type="ext4" mount_point="/data_dir2" size="200M" snap_size="0" snap_external="false"
litp create -t file-system -p /infrastructure/storage/storage_profiles/spms/volume_groups/vg1/file_systems/fs3 -o type="ext4" size="200M" snap_size="5" snap_external="false"
litp create -t physical-device -p /infrastructure/storage/storage_profiles/spms/volume_groups/vg1/physical_devices/pd1 -o device_name="hdms1"
litp inherit -p /ms/storage_profile -s /infrastructure/storage/storage_profiles/spms
# KS FS
litp create -t file-system -p /infrastructure/storage/storage_profiles/spms/volume_groups/vg1/file_systems/var -o type="ext4" mount_point="/var" size="15G" snap_size="5" backup_snap_size="10" snap_external="false"
litp create -t file-system -p /infrastructure/storage/storage_profiles/spms/volume_groups/vg1/file_systems/varlog -o type="ext4" mount_point="/var/log" size="20G" snap_size="5" backup_snap_size="10" snap_external="false"
litp create -t file-system -p /infrastructure/storage/storage_profiles/spms/volume_groups/vg1/file_systems/varwww -o type="ext4" mount_point="/var/www" size="70G" snap_size="5" backup_snap_size="10" snap_external="false"
litp create -t file-system -p /infrastructure/storage/storage_profiles/spms/volume_groups/vg1/file_systems/home -o type="ext4" mount_point="/home" size="6G" snap_size="5" backup_snap_size="10" snap_external="false"
litp create -t file-system -p /infrastructure/storage/storage_profiles/spms/volume_groups/vg1/file_systems/root -o type="ext4" mount_point="/" size="15G" snap_size="5" backup_snap_size="10" snap_external="false"
litp create -t file-system -p /infrastructure/storage/storage_profiles/spms/volume_groups/vg1/file_systems/software -o type="ext4" mount_point="/software" size="50G" snap_size="5" backup_snap_size="10" snap_external="false"



litp create -t ntp-service -p /software/items/ntp1 #-o name=ntp1
### MS Level Aliases ###
litp create -t alias-node-config -p /ms/configs/alias_config

for (( i=0; i<${#ntp_ip[@]}; i++ )); do
    litp create -t alias -p /ms/configs/alias_config/aliases/ntp_alias_$(($i+1)) -o alias_names=ntp-alias-$(($i+1)) address="${ntp_ip[i+1]}"
done
litp create -t route   -p /infrastructure/networking/routes/route1 -o subnet="0.0.0.0/0" gateway="${nodes_gateway}"
litp create -t network -p /infrastructure/networking/networks/mgmt -o name=mgmt subnet="${nodes_subnet}" litp_management=true
litp create -t network -p /infrastructure/networking/networks/data -o name=data subnet="${nodes_subnet_ext}"
litp create -t network -p /infrastructure/networking/networks/data1 -o name=data1
litp create -t network -p /infrastructure/networking/networks/heartbeat1 -o name=heartbeat1
litp create -t network -p /infrastructure/networking/networks/heartbeat2 -o name=heartbeat2
litp create -t network -p /infrastructure/networking/networks/traffic1 -o name=traffic1 # subnet="${traf1_subnet}"
litp create -t network -p /infrastructure/networking/networks/traffic2 -o name=traffic2
litp create -t network -p /infrastructure/networking/networks/xxx1 -o name=xxx1
litp create -t network -p /infrastructure/networking/networks/xxx2 -o name=xxx2
litp create -t network -p /infrastructure/networking/networks/bare_nic -o name=bare_nic
litp create -t network -p /infrastructure/networking/networks/vlan1_node2 -o name=vlan1_node2 subnet="${nodes_subnet_ext}"
litp create -t network -p /infrastructure/networking/networks/subnet_834 -o name=netwk834
litp create -t network -p /infrastructure/networking/networks/subnet_835 -o name=netwk835
litp create -t network -p /infrastructure/networking/networks/subnet_836 -o name=netwk836
litp create -t network -p /infrastructure/networking/networks/subnet_837 -o name=netwk837
litp create -t route6  -p /infrastructure/networking/routes/route1_ipv6  -o subnet=fdde:4e7e:d471:4::898:0:0/64 gateway=fdde:4d7e:d471:1::835:0:01
litp create -t route6  -p /infrastructure/networking/routes/route2_ipv6  -o                subnet=::/0                            gateway=fdde:4d7e:d471:1::835:0:1
litp create -t network -p /infrastructure/networking/networks/net1vm -o name=net1vm subnet="${net1vm_subnet}"


litp create -t eth -p /ms/network_interfaces/if0 -o device_name=eth0 macaddress="${ms_eth0_mac}" ipaddress="${ms_ip}" ipv6address="${ms_ipv6_00}" network_name=mgmt

litp inherit -p /ms/system -s /infrastructure/systems/sys1
litp inherit -p /ms/items/ntp -s /software/items/ntp1
litp inherit -p /ms/routes/route1 -s /infrastructure/networking/routes/route1


litp update -p /ms -o hostname="${ms_host}"


# Firewall

# MS
litp create -p /ms/configs/fw_config -t firewall-node-config -o drop_all='true'
litp create -p /ms/configs/fw_config/rules/fw_hyperic_server_in -t firewall-rule -o action=accept chain=INPUT dport="57004,57005" name="112 hyperic tcp agent to server ports" proto=tcp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_hyperic_server_out -t firewall-rule -o action=accept chain=OUTPUT dport="57006" name="113 hyperic tcp server to agent port" proto=tcp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_sfsudp -t firewall-rule -o action=accept dport="111,2049,4011,4001" name="011 sfsudp" proto=udp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_sfstcp -t firewall-rule -o action=accept dport="111,2049,4011,4001" name="012 sfstcp" proto=tcp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_vmmonitord -t firewall-rule -o action=accept dport="12987" name="018 vmmonitord" proto=tcp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_dns -t firewall-rule -o action=accept dport="53" name="021 DNS udp" proto=udp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_brs -t firewall-rule -o action=accept dport="1556,2821,4032,13724,13782" name="022 backuprestore tcp" proto=tcp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_ntp -t firewall-rule -o action=accept dport="123" name="029 NTP udp" proto=tcp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_dhcp_tcp -t firewall-rule -o action=accept dport="546,547,647,847" name="030 DHCP tcp" proto=tcp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_dhcp_udp -t firewall-rule -o action=accept dport="546,547,647,847" name="031 DHCP udp" proto=udp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_cobbler -t firewall-rule -o action=accept dport="25150,25151" name="032 cobbler" proto=udp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_cobbler_tcp -t firewall-rule -o action=accept dport="25150,25151" name="033 cobbler" proto=tcp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_nexus -t firewall-rule -o action=accept dport="8080,8443" name="034 nexus tcp" proto=tcp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_lserv -t firewall-rule -o action=accept dport="5093" name="035 lserv" proto=udp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_rpcbind -t firewall-rule -o action=accept dport="676" name="036 rpcbind" proto=udp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_loop_back -t firewall-rule -o action=accept iniface=lo name="01 loop back" proto=all
litp create -p /ms/configs/fw_config/rules/fw_icmp -t firewall-rule -o action=accept name="100 icmp" proto=icmp
litp create -p /ms/configs/fw_config/rules/fw_http_allow_int -t firewall-rule -o action=accept provider="iptables" dport="80" name="101 allow http internal" proto=tcp state=NEW source="10.247.244.0/22"
litp create -p /ms/configs/fw_config/rules/fw_http_allow_stor -t firewall-rule -o action=accept dport="80" name="102 allow http storage" proto=tcp state=NEW provider="iptables" source="10.140.2.0/24"
litp create -p /ms/configs/fw_config/rules/fw_http_allow_serv -t firewall-rule -o action=accept dport="80" name="103 allow http services" proto=tcp state=NEW provider="iptables" source="10.151.9.128/26"
litp create -p /ms/configs/fw_config/rules/fw_http_allow_bkp -t firewall-rule -o action=accept dport="80" name="104 allow http backup" proto=tcp state=NEW provider="iptables" source="10.151.24.0/23"
litp create -p /ms/configs/fw_config/rules/fw_http_block -t firewall-rule -o action=accept dport="80" name="105 drop http" proto=tcp state=NEW provider="iptables"

litp create_plan

