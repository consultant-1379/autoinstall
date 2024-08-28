#!/bin/bash

#### MS          ###########################################
blade_type="DL380-G9"

ms_ilo_ip="10.44.84.176"
ms_ilo_username="root"
ms_ilo_password='Amm30n!!'
ms_ip="10.44.235.15"
ms_subnet="10.44.235.0/24"
ms_gateway="10.44.235.1"
ms_vlan=""
ms_vlan_id="898"
ms_host="ms1"
ms_eth0_mac="c4:34:6b:b8:13:18"
ms_eth1_mac="c4:34:6b:b8:13:19"
ms_eth2_mac="c4:34:6b:b8:13:1a"
ms_eth3_mac="c4:34:6b:b8:13:1b"
ms_disk_uuid="600508b1001c89188ad1894963b2c67e"
ms_sysname="CZ3450K229"

ms_ipv6_00="fdde:4d7e:d471::898:215:0/64"
ms_ipv6_00_noprefix="fdde:4d7e:d471::898:215:0"
ipv6_gateway="fdde:4d7e:d471::898:0:1"
#### Networking          ###################################

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
nameserver_ip="10.44.86.212"

# VCS Cluster IDs
# Note the ID for each cluster must be unique
cluster_id="5215"


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

fencing_disk1_uuid="600601600f3133000eb1728fd394e811"
fencing_disk2_uuid="600601600f313300dc1e2caed394e811"
fencing_disk3_uuid="600601600f3133007a72c7cbd394e811"

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
nodes_sg_sl1_vip1_ipv6="fdde:4d7e:d471:215::215:50/64"

nodes_sg_fo2_vip1="172.16.201.14"
nodes_sg_fo2_vip2="172.16.201.15"
nodes_sg_pl2_vip1="172.16.201.16"
nodes_sg_pl2_vip2="172.16.201.17"
nodes_sg_sl2_vip1="172.16.201.18"
nodes_sg_sl2_vip1_ipv6="fdde:4d7e:d471:215::215:51/64"

nodes_sg_sl3_vip1="172.16.201.19"
nodes_sg_sl3_vip1_ipv6="fdde:4d7e:d471:215::215:53/64"

#### Node 1 Setup        ###################################


node_hostname[0]="node1"
node_bmc_ip[0]="10.44.84.103"
node_ip[0]="10.44.235.216"
node_sysname[0]="CZ34164L1A"
sanity_node_ip_check[0]="10.44.235.216"

node_ip_2[0]="$traffic_network1_gw"
node_ip_3[0]="$traffic_network2_gw"
node_ip_4[0]="$traffic_network3_gw"

node_ipv6_00[0]="fdde:4d7e:d471::898:215:11/64"
node_ipv6_01[0]="fdde:4d7e:d471::898:215:12/64"

node_eth0_mac[0]="9c:b6:54:93:ea:b0"
node_eth1_mac[0]="9c:b6:54:93:ea:b4"
node_eth2_mac[0]="9c:b6:54:93:ea:b1"
node_eth3_mac[0]="9c:b6:54:93:ea:b5"
node_eth4_mac[0]="9c:b6:54:93:ea:b2"
node_eth5_mac[0]="9c:b6:54:93:ea:b6"
node_eth6_mac[0]="9c:b6:54:93:ea:b3"
node_eth7_mac[0]="9c:b6:54:93:ea:b7"

node_disk_uuid[0]="600601600f313300c4e6c05c0994e811"
node_disk1_uuid[0]="600601600f3133005ae409e90994e811"

node_vxvm_uuid[0]="600601600f313300f68a243bd294e811"
node_vxvm2_uuid[0]="600601600f313300c434e826d394e811"


#### Node 2 Setup        ###################################

node_hostname[1]="node2"
node_bmc_ip[1]="10.44.84.105"
node_sysname[1]="CZ3218HDWD "
sanity_node_ip_check[1]="10.44.235.217"

node_ip[1]="10.44.235.217"
node_ip_2[1]="172.16.100.3"
node_ip_3[1]="172.16.200.131"
node_ip_4[1]="172.16.201.3"

node_ipv6_00[1]="fdde:4d7e:d471::898:215:22/64"
node_ipv6_01[1]="fdde:4d7e:d471::898:215:23/64"

node_eth0_mac[1]="80:c1:6e:7a:09:c0"
node_eth1_mac[1]="80:c1:6e:7a:09:c4"
node_eth2_mac[1]="80:c1:6e:7a:09:c1"
node_eth3_mac[1]="80:c1:6e:7a:09:c5"
node_eth4_mac[1]="80:c1:6e:7a:09:c2"
node_eth5_mac[1]="80:c1:6e:7a:09:c6"
node_eth6_mac[1]="80:c1:6e:7a:09:c3"
node_eth7_mac[1]="80:c1:6e:7a:09:c7"

node_disk_uuid[1]="600601600f31330052cf87370a94e811"
node_disk1_uuid[1]="600601600f313300cabe9f670a94e811"

node_vxvm_uuid[1]="600601600f313300f68a243bd294e811"
node_vxvm2_uuid[1]="600601600f313300c434e826d394e811"


#### General Setup       ###################################
nodes_ilo_password='Amm30n!!'
ntp_ip[1]="10.44.86.212"
ntp_ip[2]="127.127.1.0"
ntp_ip[3]="10.44.235.150"

# NFS
nfs_management_ip="10.44.86.212"
nfs_prefix="/home/admin/CI/nfs_share_dir_15"


##NAS SETUP with VA
sfs_management_ip="10.44.235.29"
sfs_vip="10.44.235.32"
sfs_password="veritas"

sfs_unmanaged_prefix="/vx/int_215-fs1"
sfs_prefix="/vx/CI215"
sfs_pool1="ST_Pool"
sfs_pool2="ST_Pool2"
sfs_cache="CI215_cache1"
sfs_username="support"
managedfs1="$sfs_prefix-managed-fs1"
managedfs2="$sfs_prefix-managed-fs2"
managedfs3="$sfs_prefix-managed-fs3"


sfs_cleanup_list="10.44.235.29:master:veritas:/vx/CI215-managed-fs1=10.44.235.0/24:CI215-managed-fs1__BREAK__10.44.235.29:master:veritas:/vx/CI215-managed-fs2==10.44.235.0/24:CI215-managed-fs2__BREAK__10.44.235.29:master:veritas:/vx/CI215-managed-fs3=10.44.235.0/24:CI215-managed-fs3"

sfs_snapshot_cleanup_list="10.44.235.29:master:veritas:L_CI215-managed-fs1_=CI215-managed-fs1:CI215_cache1"


# VM IMAGE CONTENT

copytestfile1="http://10.44.235.150/cdb/vm_test_image-2-1.0.4.qcow2:/var/www/html/images/vm_image_rhel6.qcow2"
copytestfile2="http://10.44.235.150/cdb/test_service-1.0-1.noarch.rpm:/tmp/test_services/test_service-1.0-1.noarch.rpm"
copytestfile3="http://10.44.235.150/cdb/ci_test_service1-1.0-1.noarch.rpm:/tmp/test_services/ci_test_service1-1.0-1.noarch.rpm"
copytestfile4="http://10.44.235.150/cdb/vm_test_image-1-1.0.3.qcow2:/var/www/html/images/vm_image_rhel7.qcow2"
copytestfile5="http://10.44.235.150/cdb/3PP-dutch-hello-1.0.0-1.noarch.rpm:/tmp/test_services/3PP-dutch-hello-1.0.0-1.noarch.rpm"
copytestfile6="http://10.44.235.150/cdb/3PP-english-hello-1.0.0-1.noarch.rpm:/tmp/test_services/3PP-english-hello-1.0.0-1.noarch.rpm"

net1vm_ip_ms="10.46.96.2"

net1vm_ip[0]="10.46.96.3"
net1vm_ip[1]="10.46.96.4"
net1vm_ip[2]="10.46.96.5"
net1vm_ip[3]="10.46.96.6"

net1vm_subnet="10.46.96.0/24"
net1vm_gateway="10.46.96.1"
net1vm_gateway6="fdde:4d7e:d471:46::96:1"
vm_ip_for_del[0]="10.46.96.23"
vm_ip_for_del[1]="10.46.96.24"
vm_ip[0]="10.46.96.7"
vm_ip[1]="10.46.96.8"
vm_ip[2]="10.46.96.9"
vm_ip[3]="10.46.96.10"
vm_ip[4]="10.46.96.11"
vm_ip[5]="10.46.96.12"
vm_ip[6]="10.46.96.13"
vm_ip[7]="10.46.96.14"
vm_ip[8]="10.46.96.15"
vm_ip[9]="10.46.96.16"
vm_ip[10]="10.46.96.17"
vm_ip[11]="10.46.96.18"
vm_ip[12]="10.46.96.19"
vm_ip[13]="10.46.96.20"
vm_ip[14]="10.46.96.21"
vm_ip[15]="10.46.96.22"
vm_ip6[0]="fdde:4d7e:d471:46::96:7/64"
vm_ip6[1]="fdde:4d7e:d471:46::96:8/64"
vm_ip6[2]="fdde:4d7e:d471:46::96:9/64"
vm_ip6[3]="fdde:4d7e:d471:46::96:10/64"
vm_ip6[4]="fdde:4d7e:d471:46::96:11/64"
vm_ip6[5]="fdde:4d7e:d471:46::96:12/64"
vm_ip6[6]="fdde:4d7e:d471:46::96:13/64"
vm_ip6[7]="fdde:4d7e:d471:46::96:14/64"
vm_ip6[8]="fdde:4d7e:d471:46::96:15/64"
vm_ip6[9]="fdde:4d7e:d471:46::96:16/64"
vm_ip6[10]="fdde:4d7e:d471:46::96:17/64"
vm_ip6[11]="fdde:4d7e:d471:46::96:18/64"
vm_ip6[12]="fdde:4d7e:d471:46::96:19/64"
vm_ip6[13]="fdde:4d7e:d471:46::96:20/64"
vm_ip6[14]="fdde:4d7e:d471:46::96:21/64"
vm_ip6[15]="fdde:4d7e:d471:46::96:22/64"

ms_vm_ip[0]="10.46.96.30"
ms_vm_ip6[0]="fdde:4d7e:d471:46::96:30/64"
