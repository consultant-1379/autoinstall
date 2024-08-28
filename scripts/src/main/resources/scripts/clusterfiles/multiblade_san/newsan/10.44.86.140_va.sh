#!/bin/bash

blade_type="G8"

ms_ilo_ip="10.44.84.67"
ms_ilo_username="root"
ms_ilo_password='Amm30n!!'
install_with_nic="eth1"
ms_ip="10.44.86.140"
ms_subnet="10.44.86.128/26"
ms_gateway="10.44.86.129"
ms_vlan=""
ms_vlan_id="836"
ms_host="ms1140"
ms_eth0_mac="C4:34:6B:B8:13:18"
ms_eth1_mac="C4:34:6B:B8:13:19"
ms_eth2_mac="C4:34:6B:B8:13:1A"
ms_eth3_mac="C4:34:6B:B8:13:1B"
ms_ipv6_00="fdde:4d7e:d471:0000:0:836:140:140/64"
ms_ipv6_00_noprefix="fdde:4d7e:d471:0000:0:836:140:140"
ms_disk_uuid="600508b1001c83322a1517d74d11ea65"
ipv6_gateway="fdde:4d7e:d471:0000:0:836:0:1"
ms_sysname="atrcxb2391"

nodes_subnet="$ms_subnet"
nodes_gateway="$ms_gateway"
nodes_ilo_password='Amm30n!!'

nameserver_ip="10.44.86.212"

traffic_network1_subnet="172.16.100.0/24"
traffic_network2_subnet="172.16.200.128/24"

##network host settings (Note these are the same for .100 and .42)
vcs_network_host1="172.16.101.10"
vcs_network_host3="2001:ABCD:F0::10"
vcs_network_host5="2001:ABCD:F0::10"
vcs_network_host6="172.16.101.11"
vcs_network_host7="2001:ABCD:F0::11"
vcs_network_host8="172.16.101.12"
vcs_network_host10="20.20.20.78"
vcs_network_host11="20.20.20.78"
vcs_network_host12="172.16.101.13"
vcs_network_host13="172.16.101.14"
vcs_network_host14="172.16.101.15"

##VCS requires gateway is pingable
traffic_network1_gw="172.16.100.2"
traffic_network2_gw="172.16.200.130"
traffic_network2_gw_subnet="172.16.168.2/32"


cluster_id="4840"

fencing_disk1_uuid="60060160285139006135dd56d0b8eb11"
fencing_disk2_uuid="600601602851390042b2bc7ad0b8eb11"
fencing_disk3_uuid="60060160285139004c6f878dd0b8eb11"

##SETUP VIPS
##Traffic network 3
##VCS requires gateway is pingable
traffic_network3_gw="172.16.201.2"
traffic_network3_gw_subnet="172.16.168.3/32"
traffic_network3_subnet="172.16.201.0/24"

nodes_sg_fo1_vip1="172.16.201.8"
nodes_sg_fo1_vip2="172.16.201.9"
nodes_sg_pl1_vip1="172.16.201.10"
nodes_sg_pl1_vip2="172.16.201.11"


node_ip[0]="10.44.86.141"
sanity_node_ip_check[0]="10.44.86.141"
node_ip_2[0]="$traffic_network1_gw"
node_ip_3[0]="$traffic_network2_gw"
node_ip_4[0]="$traffic_network3_gw"
node_ipv6_00[0]="fdde:4d7e:d471:0000:0:836:140:141/64"
node_sysname[0]="CZ3218HDWB"
node_hostname[0]="SC1140"
node_eth0_mac[0]="EC:B1:D7:8B:87:50"
node_eth1_mac[0]="EC:B1:D7:8B:87:54"
node_eth2_mac[0]="EC:B1:D7:8B:87:51"
node_eth3_mac[0]="EC:B1:D7:8B:87:55"
node_eth4_mac[0]="EC:B1:D7:8B:87:52"
node_eth5_mac[0]="EC:B1:D7:8B:87:56"
node_eth6_mac[0]="EC:B1:D7:8B:87:53"
node_eth7_mac[0]="EC:B1:D7:8B:87:57"
node_disk_uuid[0]="60060160285139002d50c34dd1b8eb11"
node_disk1_uuid[0]="600601602851390009b1f56ad1b8eb11"

node_vxvm_uuid[0]="6006016028513900f88c4a2dd0b8eb11"
node_vxvm2_uuid[0]="60060160285139005a00e240d0b8eb11"
node_bmc_ip[0]="10.44.84.75"

node_ip[1]="10.44.86.142"
sanity_node_ip_check[1]="10.44.86.142"
node_ip_2[1]="172.16.100.3"
node_ip_3[1]="172.16.200.131"
node_ip_4[1]="172.16.201.3"
node_ipv6_00[1]="fdde:4d7e:d471:0000:0:836:140:142/64"
node_sysname[1]="CZ3450K226"
node_hostname[1]="SC2140"
node_eth0_mac[1]="6C:C2:17:3D:63:F0"
node_eth1_mac[1]="6C:C2:17:3D:63:F8"
node_eth2_mac[1]="6C:C2:17:3D:63:F1"
node_eth3_mac[1]="6C:C2:17:3D:63:F9"
node_eth4_mac[1]="6C:C2:17:3D:63:F2"
node_eth5_mac[1]="6C:C2:17:3D:63:Fa"
node_eth6_mac[1]="6C:C2:17:3D:63:F3"
node_eth7_mac[1]="6C:C2:17:3D:63:Fb"
node_disk_uuid[1]="600601602851390055c0af88d1b8eb11"
node_disk1_uuid[1]="6006016028513900a073c281d6b8eb11"
node_vxvm_uuid[1]="6006016028513900f88c4a2dd0b8eb11"
node_vxvm2_uuid[1]="60060160285139005a00e240d0b8eb11"
node_bmc_ip[1]="10.44.84.76"

ntp_ip[1]="10.44.86.212"
ntp_ip[2]="127.127.1.0"

##NFS SETUP
nfs_management_ip="10.44.86.212"
nfs_prefix="/home/admin/CI/nfs_share_dir_140"
##SFS SETUP
sfs_management_ip="10.44.235.29"
sfs_vip="10.44.235.32"
sfs_unmanaged_prefix="/vx/CI140-fs1"
sfs_prefix="/vx/CI40"
sfs_pool1="ST_Pool"
sfs_cache="CI40_cache1"
sfs_username="support"
sfs_password="veritas"
managedfs1="$sfs_prefix-managed-fs1"
managedfs2="$sfs_prefix-managed-fs2"
managedfs3="$sfs_prefix-managed-fs3"

sfs_cleanup_list="10.44.235.29:master:veritas:/vx/CI140-managed-fs1=10.44.86.0/26:CI40-managed-fs1__BREAK__10.44.235.29:master:veritas:/vx/CI40-managed-fs2=10.44.86.141,/vx/CI40-managed-fs2=10.44.86.142:CI40-managed-fs2__BREAK__10.44.235.29:master:veritas:/vx/CI40-managed-fs3=10.44.86.0/26:CI40-managed-fs3"

sfs_snapshot_cleanup_list="10.44.235.29:master:veritas:L_CI40-managed-fs1_=CI40-managed-fs1:CI40_cache1"

copytestfile1="http://10.44.235.150/cdb/vm_test_image-2-1.0.4.qcow2:/var/www/html/images/vm_image_rhel6.qcow2"
copytestfile2="http://10.44.235.150/cdb/ci_test_service1-1.0-1.noarch.rpm:/tmp/test_services/ci_test_service1-1.0-1.noarch.rpm"
copytestfile3="http://10.44.235.150/cdb/vm_test_image-1-1.0.3.qcow2:/var/www/html/images/vm_image_rhel7.qcow2"
copytestfile4="http://10.44.235.150/cdb/3PP-dutch-hello-1.0.0-1.noarch.rpm:/tmp/test_services/3PP-dutch-hello-1.0.0-1.noarch.rpm"
copytestfile5="http://10.44.235.150/cdb/3PP-english-hello-1.0.0-1.noarch.rpm:/tmp/test_services/3PP-english-hello-1.0.0-1.noarch.rpm"


