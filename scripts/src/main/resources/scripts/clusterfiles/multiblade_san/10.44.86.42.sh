#!/bin/bash

blade_type="G8"

ms_ilo_ip="10.44.84.62"
ms_ilo_username="root"
ms_ilo_password='Amm30n!!'
install_with_nic="eth1"
ms_ip="10.44.86.42"
ms_ip_2="192.168.201.10"
ms_subnet="10.44.86.0/26"
ms_gateway="10.44.86.1"
ms_vlan=""
ms_vlan_id="834"
ms_host="ms1"
ms_eth0_mac="80:C1:6E:7A:19:A0"
ms_eth1_mac="80:C1:6E:7A:19:A4"
ms_eth2_mac="80:C1:6E:7A:19:A1"
ms_eth3_mac="80:C1:6E:7A:19:A5"
ms_ipv6_00="fdde:4d7e:d471:0000:0:834:42:42/64"
ms_ipv6_00_noprefix="fdde:4d7e:d471:0000:0:834:42:42"
ms_disk_uuid="3600508b1001cb70924048ae8f442d7dc"
ipv6_gateway="fdde:4d7e:d471:0000:0:834:0:1"
ms_sysname="CZJ33308J8"

nodes_ip_start="10.44.86.42"
nodes_ip_end="10.44.86.44"
nodes_subnet="$ms_subnet"
nodes_gateway="$ms_gateway"
nodes_ilo_password='Amm30n!!'

traffic_network1_gw_subnet="172.16.168.1/32"
traffic_network2_gw_subnet="172.16.168.2/32"

nameserver_ip="10.44.86.14"
##network host settings
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

traffic_network1_subnet="172.16.100.0/24"
traffic_network2_subnet="172.16.200.128/24"

cluster_id="4742"

fencing_disk1_uuid="6006016011602D002E76C725DD2DE411"
fencing_disk2_uuid="6006016011602D002697AA38DD2DE411"
fencing_disk3_uuid="6006016011602D005CC9C55FDD2DE411"

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
nodes_sg_sl1_vip1="172.16.201.12"
nodes_sg_sl1_vip1_ipv6="fdde:4d7e:d471:19::42:0/64"

node_ip[0]="10.44.86.43"
sanity_node_ip_check[0]="10.44.86.43"
node_ip_2[0]="$traffic_network1_gw"
node_ip_3[0]="$traffic_network2_gw"
node_ip_4[0]="$traffic_network3_gw"
node_sysname[0]="CZJ33308J0"
node_hostname[0]="SC-1"
node_eth0_mac[0]="98:4B:E1:68:6C:A8"
node_eth1_mac[0]="98:4B:E1:68:6C:AC"
node_ipv6_00[0]="fdde:4d7e:d471:0000:0:834:42:43/64"
node_ipv6_01[0]="fdde:4d7e:d471::834:42:3/64"
node_eth2_mac[0]="98:4B:E1:68:6C:A9"
node_eth3_mac[0]="98:4B:E1:68:6C:AD"
node_eth4_mac[0]="98:4B:E1:68:6C:AA"
node_eth5_mac[0]="98:4B:E1:68:6C:AE"
node_eth6_mac[0]="98:4B:E1:68:6C:AB"
node_eth7_mac[0]="98:4B:E1:68:6C:AF"
node_disk_uuid[0]="6006016011602D005A1291BA391EE411"
node_disk1_uuid[0]="6006016011602D004AFAF4DD391EE411"

node_vxvm_uuid[0]="6006016011602D006C414B980218E411"
node_vxvm2_uuid[0]="6006016011602D00C6C135D8CF4FE411"
node_bmc_ip[0]="10.44.84.17"

node_ip[1]="10.44.86.44"
sanity_node_ip_check[1]="10.44.86.44"
node_ip_2[1]="172.16.100.3"
node_ip_3[1]="172.16.200.131"
node_ip_4[1]="172.16.201.3"
node_sysname[1]="CZJ33308J2"
node_hostname[1]="SC-2"
node_eth0_mac[1]="98:4B:E1:63:B3:88"
node_eth1_mac[1]="98:4B:E1:63:B3:8C"
#IPV6 addresses
node_ipv6_00[1]="fdde:4d7e:d471:0000:0:834:42:44/64"
node_ipv6_01[1]="fdde:4d7e:d471::834:42:5/64"
node_eth2_mac[1]="98:4B:E1:63:B3:89"
node_eth3_mac[1]="98:4B:E1:63:B3:8D"
node_eth4_mac[1]="98:4B:E1:63:B3:8A"
node_eth5_mac[1]="98:4B:E1:63:B3:8E"
node_eth6_mac[1]="98:4B:E1:63:B3:8B"
node_eth7_mac[1]="98:4B:E1:63:B3:8F"
#OLD SAN DISKS
node_disk_uuid[1]="6006016011602D0042F93E3C3B1EE411"
node_disk1_uuid[1]="6006016011602D00F0B629093B1EE411"
node_vxvm_uuid[1]="6006016011602D006C414B980218E411"
node_vxvm2_uuid[1]="6006016011602D00C6C135D8CF4FE411"
node_bmc_ip[1]="10.44.84.18"

ntp_ip[1]="10.44.86.14"
ntp_ip[2]="127.127.1.0"

##NFS SETUP
nfs_management_ip="10.44.86.14"
nfs_prefix="/home/admin/CI/nfs_share_dir_42"
##SFS SETUP
sfs_management_ip="10.44.86.230"
sfs_vip="10.44.86.230"
sfs_unmanaged_prefix="/vx/int_42-fs1"
sfs_prefix="/vx/CI42"
sfs_pool1="ST_Pool"
sfs_pool2="ST_Pool"
sfs_cache="CI42_cache1"
sfs_username="support"
sfs_password="support"
managedfs1="$sfs_prefix-managed-fs1"
managedfs2="$sfs_prefix-managed-fs2"
managedfs3="$sfs_prefix-managed-fs3"

sfs_cleanup_list="10.44.86.231:master:master:/vx/CI42-managed-fs1=10.44.86.0/26:CI42-managed-fs1__BREAK__10.44.86.231:master:master:/vx/CI42-managed-fs2=10.44.86.43,/vx/CI42-managed-fs2=10.44.86.44:CI42-managed-fs2__BREAK__10.44.86.231:master:master:/vx/CI42-managed-fs3=10.44.86.0/26:CI42-managed-fs3"

sfs_snapshot_cleanup_list="10.44.86.231:master:master:L_CI42-managed-fs1_=CI42-managed-fs1:CI42_cache1"

# VM IMAGE CONTENT

copytestfile1="http://10.44.235.150/cdb/vm_test_image-2-1.0.4.qcow2:/var/www/html/images/vm_image_rhel6.qcow2"
copytestfile2="http://10.44.235.150/cdb/ci_test_service1-1.0-1.noarch.rpm:/tmp/test_services/ci_test_service1-1.0-1.noarch.rpm"
copytestfile3="http://10.44.235.150/cdb/vm_test_image-1-1.0.3.qcow2:/var/www/html/images/vm_image_rhel7.qcow2"
copytestfile4="http://10.44.235.150/cdb/3PP-dutch-hello-1.0.0-1.noarch.rpm:/tmp/test_services/3PP-dutch-hello-1.0.0-1.noarch.rpm"
copytestfile5="http://10.44.235.150/cdb/3PP-english-hello-1.0.0-1.noarch.rpm:/tmp/test_services/3PP-english-hello-1.0.0-1.noarch.rpm"

net1vm_ip_ms="10.46.84.2"

net1vm_ip[0]="10.46.84.3"
net1vm_ip[1]="10.46.84.4"

net1vm_subnet="10.46.84.0/24"
net1vm_gateway="10.46.84.1"
net1vm_gateway6="fdde:4d7e:d471:46::84:1"
vm_ip[0]="10.46.84.5"
vm_ip[1]="10.46.84.6"
vm_ip[2]="10.46.84.7"
vm_ip_for_del[0]="10.46.84.23"
vm_ip_for_del[1]="10.46.84.24"
vm_ip6[0]="fdde:4d7e:d471:46::84:5/64"
vm_ip6[1]="fdde:4d7e:d471:46::84:6/64"
vm_ip6[2]="fdde:4d7e:d471:46::84:7/64"

ms_vm_ip[0]="10.46.84.8"
ms_vm_ip6[0]="fdde:4d7e:d471:46::84:8/64"
