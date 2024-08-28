#!/bin/bash

#### MS          ###########################################
blade_type="G8"

ms_ilo_ip="10.44.84.66"
ms_ilo_username="root"
ms_ilo_password='Amm30n!!'
ms_ip="10.44.235.120"
# Former 38
ms_subnet="10.44.235.0/24"
ms_gateway="10.44.235.1"
ms_vlan=""
ms_vlan_id="898"
ms_host="ms1"
ms_eth0_mac="80:C1:6E:7A:FA:A8"
ms_eth1_mac="80:C1:6E:7A:FA:AC"
ms_eth2_mac="80:C1:6E:7A:FA:A9"
ms_eth3_mac="80:C1:6E:7A:FA:AD"
ms_disk_uuid="600508b1001c0bfd04a7dcbe6d8a26a1"
ms_sysname="CZ3218HDW1"

ms_ipv6_00="fdde:4d7e:d471::898:120:0/64"
ms_ipv6_00_noprefix="fdde:4d7e:d471::898:120:0"
ipv6_gateway="fdde:4d7e:d471::898:0:1"
#### Networking          ###################################

#nodes_ip_start="10.44.235.121"
#nodes_ip_end="10.44.235.125"
nodes_subnet="$ms_subnet"
nodes_gateway="$ms_gateway"

traffic_network1_gw_subnet="172.16.168.1/32"
traffic_network2_gw_subnet="172.16.168.2/32"

# VCS requires a gateway that is pingable
traffic_network1_gw="172.16.100.2"
traffic_network2_gw="172.16.200.130"

traffic_network1_subnet="172.16.100.0/24"
traffic_network2_subnet="172.16.200.128/24"

# DNS Server
nameserver_ip="10.44.86.4"

# VCS Cluster IDs
# Note the ID for each cluster must be unique
cluster_id="5120"
cluster2_id="5121"
cluster3_id="5122"

# VCS Network host settings
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

vcs_network_host15="172.16.101.16"
vcs_network_host16="2001:ABCD:F0::16"
vcs_network_host17="2001:ABCD:F0::16"
vcs_network_host18="172.16.101.17"
vcs_network_host19="2001:ABCD:F0::18"
vcs_network_host20="172.16.101.19"
vcs_network_host21="20.20.20.79"
vcs_network_host22="20.20.20.79"
vcs_network_host23="172.16.101.20"
vcs_network_host24="172.16.101.21"
vcs_network_host25="172.16.101.22"

vcs_network_host26="172.16.101.23"
vcs_network_host27="2001:ABCD:F0::23"
vcs_network_host28="2001:ABCD:F0::23"
vcs_network_host29="172.16.101.24"
vcs_network_host30="2001:ABCD:F0::25"
vcs_network_host31="172.16.101.26"
vcs_network_host32="20.20.20.80"
vcs_network_host33="20.20.20.80"
vcs_network_host34="172.16.101.27"
vcs_network_host35="172.16.101.28"
vcs_network_host36="172.16.101.29"

fencing_disk1_uuid="6006016011602D009A3697CEDD2DE411"
fencing_disk2_uuid="6006016011602D00BAA35EE8DD2DE411"
fencing_disk3_uuid="6006016011602D00560CDD00DE2DE411"

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
nodes_sg_pl1_vip3="172.16.201.12"
nodes_sg_sl1_vip1="172.16.201.13"
nodes_sg_sl1_vip1_ipv6="fdde:4d7e:d471:120::120:50/64"

nodes_sg_fo2_vip1="172.16.201.14"
nodes_sg_fo2_vip2="172.16.201.15"
nodes_sg_pl2_vip1="172.16.201.16"
nodes_sg_pl2_vip2="172.16.201.17"
nodes_sg_sl2_vip1="172.16.201.18"
nodes_sg_sl2_vip1_ipv6="fdde:4d7e:d471:120::120:51/64"

nodes_sg_sl3_vip1="172.16.201.19"
nodes_sg_sl3_vip1_ipv6="fdde:4d7e:d471:120::120:53/64"

#### Node 1 Setup        ###################################


node_hostname[0]="node1"
node_bmc_ip[0]="10.44.84.9"
node_ip[0]="10.44.235.121"
node_sysname[0]="CZ3128LSDD"
sanity_node_ip_check[0]="10.44.235.121"

node_ip_2[0]="$traffic_network1_gw"
node_ip_3[0]="$traffic_network2_gw"
node_ip_4[0]="$traffic_network3_gw"

node_ipv6_00[0]="fdde:4d7e:d471::898:120:11/64"
node_ipv6_01[0]="fdde:4d7e:d471::898:120:12/64"

node_eth0_mac[0]="98:4B:E1:69:D1:D0"
node_eth1_mac[0]="98:4B:E1:69:D1:D4"
node_eth2_mac[0]="98:4B:E1:69:D1:D1"
node_eth3_mac[0]="98:4B:E1:69:D1:D5"
node_eth4_mac[0]="98:4B:E1:69:D1:D2"
node_eth5_mac[0]="98:4B:E1:69:D1:D6"
node_eth6_mac[0]="98:4B:E1:69:D1:D3"
node_eth7_mac[0]="98:4B:E1:69:D1:D7"

node_disk_uuid[0]="6006016011602d0024c11b02f6a3e311"
node_disk1_uuid[0]="6006016011602d00f233c864f6a3e311"

node_vxvm_uuid[0]="6006016011602D005E3C0A7E0218E411"
node_vxvm2_uuid[0]="6006016011602D00C04C1AC4CF4FE411"


#### Node 2 Setup        ###################################

node_hostname[1]="node2"
node_bmc_ip[1]="10.44.84.11"
node_sysname[1]="CZ3128LSDR"
sanity_node_ip_check[1]="10.44.235.122"

node_ip[1]="10.44.235.122"
node_ip_2[1]="172.16.100.3"
node_ip_3[1]="172.16.200.131"
node_ip_4[1]="172.16.201.3"

node_ipv6_00[1]="fdde:4d7e:d471::898:120:22/64"
node_ipv6_01[1]="fdde:4d7e:d471::898:120:23/64"

node_eth0_mac[1]="98:4B:E1:68:7C:08"
node_eth1_mac[1]="98:4B:E1:68:7C:0C"
node_eth2_mac[1]="98:4B:E1:68:7C:09"
node_eth3_mac[1]="98:4B:E1:68:7C:0D"
node_eth4_mac[1]="98:4B:E1:68:7C:0A"
node_eth5_mac[1]="98:4B:E1:68:7C:0E"
node_eth6_mac[1]="98:4B:E1:68:7C:0B"
node_eth7_mac[1]="98:4B:E1:68:7C:0F"

node_disk_uuid[1]="6006016011602d0000c3586ef6a3e311"
node_disk1_uuid[1]="6006016011602d00eef1c3d1f6a3e311"

node_vxvm_uuid[1]="6006016011602D005E3C0A7E0218E411"
node_vxvm2_uuid[1]="6006016011602D00C04C1AC4CF4FE411"


#### General Setup       ###################################
nodes_ilo_password='Amm30n!!'
ntp_ip[1]="10.44.86.14"
ntp_ip[2]="127.127.1.0"
ntp_ip[3]="10.44.235.150"

# NFS
nfs_management_ip="10.44.86.14"
nfs_prefix="/home/admin/CI/nfs_share_dir_120"

# SFS
sfs_management_ip="10.44.86.230"
sfs_vip="10.44.86.230"
sfs_vip2="10.44.86.240"
sfs_unmanaged_prefix="/vx/int_120-fs1"
sfs_prefix="/vx/CI120"
sfs_pool1="ST_Pool"
sfs_pool2="ST_Pool2"
sfs_cache="CI120_cache1"
sfs_username="support"
sfs_password="support"
managedfs1="$sfs_prefix-managed-fs1"
managedfs2="$sfs_prefix-managed-fs2"
managedfs3="$sfs_prefix-managed-fs3"


sfs_cleanup_list="10.44.86.231:master:master:/vx/CI120-managed-fs1=10.44.235.0/24:CI120-managed-fs1__BREAK__10.44.86.231:master:master:/vx/CI120-managed-fs2=10.44.235.121,/vx/CI120-managed-fs2=10.44.235.122,/vx/CI120-managed-fs2=10.44.235.123,/vx/CI120-managed-fs2=10.44.235.124:CI67-managed-fs2__BREAK__10.44.86.231:master:master:/vx/CI120-managed-fs3=10.44.235.0/24:CI120-managed-fs3"

sfs_snapshot_cleanup_list="10.44.86.231:master:master:L_CI120-managed-fs1_=CI120-managed-fs1:CI120_cache1"

#List only for the nodes for prepare_restore testing
sfs_cleanup_list_restore="10.44.86.231:master:master:/vx/CI120-managed-fs2=10.44.235.121,/vx/CI120-managed-fs2=10.44.235.122,/vx/CI120-managed-fs2=10.44.235.123,/vx/CI120-managed-fs2=10.44.235.124:CI120-managed-fs2"

# VM IMAGE CONTENT
#vm_image_include="run_image"

copytestfile1="http://10.44.235.150/cdb/vm_test_image-2-1.0.4.qcow2:/var/www/html/images/vm_image_rhel6.qcow2"
copytestfile2="http://10.44.235.150/cdb/test_service-1.0-1.noarch.rpm:/tmp/test_services/test_service-1.0-1.noarch.rpm"
copytestfile3="http://10.44.235.150/cdb/ci_test_service1-1.0-1.noarch.rpm:/tmp/test_services/ci_test_service1-1.0-1.noarch.rpm"
copytestfile4="http://10.44.235.150/cdb/vm_test_image-1-1.0.3.qcow2:/var/www/html/images/vm_image_rhel7.qcow2"
copytestfile5="http://10.44.235.150/cdb/3PP-dutch-hello-1.0.0-1.noarch.rpm:/tmp/test_services/3PP-dutch-hello-1.0.0-1.noarch.rpm"
copytestfile6="http://10.44.235.150/cdb/3PP-english-hello-1.0.0-1.noarch.rpm:/tmp/test_services/3PP-english-hello-1.0.0-1.noarch.rpm"

net1vm_ip_ms="10.46.93.2"

net1vm_ip[0]="10.46.93.3"
net1vm_ip[1]="10.46.93.4"
net1vm_ip[2]="10.46.93.5"
net1vm_ip[3]="10.46.93.6"

net1vm_subnet="10.46.93.0/24"
net1vm_gateway="10.46.93.1"
net1vm_gateway6="fdde:4d7e:d471:46::93:1"
vm_ip_for_del[0]="10.46.93.23"
vm_ip_for_del[1]="10.46.93.24"
vm_ip[0]="10.46.93.7"
vm_ip[1]="10.46.93.8"
vm_ip[2]="10.46.93.9"
vm_ip[3]="10.46.93.10"
vm_ip[4]="10.46.93.11"
vm_ip[5]="10.46.93.12"
vm_ip[6]="10.46.93.13"
vm_ip[7]="10.46.93.14"
vm_ip[8]="10.46.93.15"
vm_ip[9]="10.46.93.16"
vm_ip[10]="10.46.93.17"
vm_ip[11]="10.46.93.18"
vm_ip[12]="10.46.93.19"
vm_ip[13]="10.46.93.20"
vm_ip[14]="10.46.93.21"
vm_ip[15]="10.46.93.22"
vm_ip6[0]="fdde:4d7e:d471:46::93:7/64"
vm_ip6[1]="fdde:4d7e:d471:46::93:8/64"
vm_ip6[2]="fdde:4d7e:d471:46::93:9/64"
vm_ip6[3]="fdde:4d7e:d471:46::93:10/64"
vm_ip6[4]="fdde:4d7e:d471:46::93:11/64"
vm_ip6[5]="fdde:4d7e:d471:46::93:12/64"
vm_ip6[6]="fdde:4d7e:d471:46::93:13/64"
vm_ip6[7]="fdde:4d7e:d471:46::93:14/64"
vm_ip6[8]="fdde:4d7e:d471:46::93:15/64"
vm_ip6[9]="fdde:4d7e:d471:46::93:16/64"
vm_ip6[10]="fdde:4d7e:d471:46::93:17/64"
vm_ip6[11]="fdde:4d7e:d471:46::93:18/64"
vm_ip6[12]="fdde:4d7e:d471:46::93:19/64"
vm_ip6[13]="fdde:4d7e:d471:46::93:20/64"
vm_ip6[14]="fdde:4d7e:d471:46::93:21/64"
vm_ip6[15]="fdde:4d7e:d471:46::93:22/64"

ms_vm_ip[0]="10.46.93.30"
ms_vm_ip6[0]="fdde:4d7e:d471:46::92:30/64"



###############################
# Expansion Specific section
###############################

exclude_vxvm="exclude"

#### Node 3 Setup        ###################################
node_expansion_hostname[0]="node3"
node_expansion_bmc_ip[0]="10.44.84.41"
node_expansion_sysname[0]="CZ3128LSDY"


node_expansion_ip[0]="10.44.235.123"
node_expansion_ip_2[0]="172.16.100.4"
node_expansion_ip_3[0]="172.16.200.132"
node_expansion_ip_4[0]="172.16.201.4"

node_expansion_ipv6_00[0]="fdde:4d7e:d471::898:120:31/64"

node_expansion_eth0_mac[0]="98:4B:E1:69:D1:70"
node_expansion_eth1_mac[0]="98:4B:E1:69:D1:74"
node_expansion_eth2_mac[0]="98:4B:E1:69:D1:71"
node_expansion_eth3_mac[0]="98:4B:E1:69:D1:75"
node_expansion_eth4_mac[0]="98:4B:E1:69:D1:72"
node_expansion_eth5_mac[0]="98:4B:E1:69:D1:76"
node_expansion_eth6_mac[0]="98:4B:E1:69:D1:73"
node_expansion_eth7_mac[0]="98:4B:E1:69:D1:77"

node_expansion_disk_uuid[0]="6006016011602d009cc935a6eef7e411"
node_expansion_disk1_uuid[0]="6006016011602d00f8595ce3eef7e411"

node_expansion_vxvm_uuid[0]="6006016011602D005E3C0A7E0218E411"
node_expansion_vxvm2_uuid[0]="6006016011602D00C04C1AC4CF4FE411"

#### Node 4 Setup        ###################################

node_expansion_hostname[1]="node4"
node_expansion_bmc_ip[1]="10.44.84.42"
node_expansion_sysname[1]="CZ3128LSEE"

node_expansion_ip[1]="10.44.235.124"
node_expansion_ip_2[1]="172.16.100.5"
node_expansion_ip_3[1]="172.16.200.133"
node_expansion_ip_4[1]="172.16.201.5"

node_expansion_ipv6_00[1]="fdde:4d7e:d471::898:120:41/64"

node_expansion_eth0_mac[1]="98:4B:E1:69:D0:90"
node_expansion_eth1_mac[1]="98:4B:E1:69:D0:94"
node_expansion_eth2_mac[1]="98:4B:E1:69:D0:91"
node_expansion_eth3_mac[1]="98:4B:E1:69:D0:95"
node_expansion_eth4_mac[1]="98:4B:E1:69:D0:92"
node_expansion_eth5_mac[1]="98:4B:E1:69:D0:96"
node_expansion_eth6_mac[1]="98:4B:E1:69:D0:93"
node_expansion_eth7_mac[1]="98:4B:E1:69:D0:97"

node_expansion_disk_uuid[1]="6006016011602d009ebfbdc6eef7e411"
node_expansion_disk1_uuid[1]="6006016011602d0020a384feeef7e411"

node_expansion_vxvm_uuid[1]="6006016011602D005E3C0A7E0218E411"
node_expansion_vxvm2_uuid[1]="6006016011602D00C04C1AC4CF4FE411"

############################################################
# Nodes to shutdown after prepare_restore
prepare_restore_shutdown_ip[0]="10.44.235.121"
prepare_restore_shutdown_ip[1]="10.44.235.122"
prepare_restore_shutdown_ip[2]="10.44.235.123"
prepare_restore_shutdown_ip[3]="10.44.235.124"
