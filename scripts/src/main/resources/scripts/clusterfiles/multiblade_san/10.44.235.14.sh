#!/bin/bash

#### MS          ###########################################
blade_type="G8"

ms_host="ms1"
ms_ip="10.44.235.14"
ms_ilo_ip="10.44.84.138"
ms_ilo_username="root"
ms_ilo_password='Amm30n!!'
ms_subnet="10.44.235.0/24"
ms_gateway="10.44.235.1"
ms_vlan=""
ms_sysname="CZJ33308HX"

ms_eth0_mac="2C:59:E5:3D:83:58"
ms_eth1_mac="2C:59:E5:3D:83:5C"
ms_eth2_mac="2C:59:E5:3d:83:59"
ms_eth3_mac="2C:59:E5:3d:83:5D"
ms_eth4_mac="2C:59:E5:3d:83:5A"
ms_eth5_mac="2C:59:E5:3d:83:5E"
ms_eth6_mac="2C:59:E5:3d:83:5B"
ms_eth7_mac="2C:59:E5:3d:83:5F"

ipv6_gateway="fdde:4d7e:d471:0004:0:898:0:1"
ms_ipv6_00="fdde:4d7e:d471:0004:0:898:14:0/64"
ms_ipv6_01="fdde:4d7e:d471:0004:0:898:14:10/64"
ms_ipv6_00_noprefix="fdde:4d7e:d471:0004:0:898:14:0"

ms_disk_uuid="600508b1001c71ffb5473067e79bfd5d"

#### Networking          ###################################
nodes_ip_start="10.44.235.20"
nodes_ip_end="10.44.235.30"
nodes_subnet="$ms_subnet"
nodes_gateway="$ms_gateway"

traffic_network1_gw_subnet="172.16.168.1/32"
traffic_network2_gw_subnet="172.16.168.2/32"
##VCS requires gateway is pingable
traffic_network1_gw="172.16.100.2"
traffic_network2_gw="172.16.200.130"

traffic_network1_subnet="172.16.100.0/24"
traffic_network2_subnet="172.16.200.128/24"

# DNS Server
nameserver_ip="10.44.86.14"

# VCS Cluster IDs
# Note the ID for each cluster must be unique
cluster_id="4814"
cluster2_id="5167"
cluster3_id="5267"

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


fencing_disk1_uuid="600601600f31330080412b141611e511"
fencing_disk2_uuid="600601600f313300b2db20251611e511"
fencing_disk3_uuid="600601600f3133002448f6391611e511"

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
nodes_sg_sl1_vip1_ipv6="fdde:4d7e:d471:19::15:0/64"

nodes_sg_fo2_vip1="172.16.201.14"
nodes_sg_fo2_vip2="172.16.201.15"
nodes_sg_pl2_vip1="172.16.201.16"
nodes_sg_pl2_vip2="172.16.201.17"
nodes_sg_sl2_vip1="172.16.201.18"
nodes_sg_sl2_vip1_ipv6="fdde:4d7e:d471:19::67:51/64"

nodes_sg_sl3_vip1="172.16.201.19"
nodes_sg_sl3_vip1_ipv6="fdde:4d7e:d471:19::67:53/64"


#### Node 1 Setup        ###################################

node_hostname[0]="node1"
node_bmc_ip[0]="10.44.84.107"
node_sysname[0]="CZ3450K234"
sanity_node_ip_check[0]="10.44.235.16"

node_ip[0]="10.44.235.16"
node_ip_2[0]="$traffic_network1_gw"
node_ip_3[0]="$traffic_network2_gw"
node_ip_4[0]="$traffic_network3_gw"

node_ipv6_00[0]="fdde:4d7e:d471:0004:0:898:16:0/64"
node_ipv6_01[0]="fdde:4d7e:d471::834:15:3/64"

node_eth0_mac[0]="6C:C2:17:3D:5F:D0"
node_eth1_mac[0]="6C:C2:17:3D:5F:D8"
node_eth2_mac[0]="6C:C2:17:3D:5F:D1"
node_eth3_mac[0]="6C:C2:17:3D:5F:D9"
node_eth4_mac[0]="6C:C2:17:3D:5F:D2"
node_eth5_mac[0]="6C:C2:17:3D:5F:DA"
node_eth6_mac[0]="6C:C2:17:3D:5F:D3"
node_eth7_mac[0]="6C:C2:17:3D:5F:DB"

node_disk_uuid[0]="600601600f313300f8564aa91511e511"
node_disk1_uuid[0]="600601600f31330024a699bb1511e511"

node_vxvm_uuid[0]="600601600f313300664e72521611e511"
node_vxvm2_uuid[0]="600601600f31330020b5c3671611e511"


#### Node 2 Setup        ###################################

node_hostname[1]="node2"
node_bmc_ip[1]="10.44.84.108"
node_sysname[1]="IEATRCXB4123"
sanity_node_ip_check[1]="10.44.235.17"

node_ip[1]="10.44.235.17"
node_ip_2[1]="172.16.100.3"
node_ip_3[1]="172.16.200.131"
node_ip_4[1]="172.16.201.3"

#IPV6 addresses
node_ipv6_00[1]="fdde:4d7e:d471:0004:0:898:17:0/64"
node_ipv6_01[1]="fdde:4d7e:d471::834:15:5/64"

node_eth0_mac[1]="6C:C2:17:3D:43:40"
node_eth1_mac[1]="6C:C2:17:3D:43:48"
node_eth2_mac[1]="6C:C2:17:3D:43:41"
node_eth3_mac[1]="6C:C2:17:3D:43:49"
node_eth4_mac[1]="6C:C2:17:3D:43:42"
node_eth5_mac[1]="6C:C2:17:3D:43:4A"
node_eth6_mac[1]="6C:C2:17:3D:43:43"
node_eth7_mac[1]="6C:C2:17:3D:43:4B"

node_disk_uuid[1]="600601600f3133000272b2da1511e511"
node_disk1_uuid[1]="600601600f313300220cabf51511e511"

node_vxvm_uuid[1]="600601600f313300664e72521611e511"
node_vxvm2_uuid[1]="600601600f31330020b5c3671611e511"


#### General Setup       ###################################
nodes_ilo_password='Amm30n!!'
ntp_ip[1]="10.44.86.14"
ntp_ip[2]="127.127.1.0"

# NFS
nfs_management_ip="10.44.86.14"
nfs_prefix="/home/admin/CI/nfs_share_dir_15"

# SFS
sfs_management_ip="10.44.86.230"
sfs_vip="10.44.86.230"
sfs_vip2="10.44.86.240"
sfs_unmanaged_prefix="/vx/int_15-fs1"
sfs_prefix="/vx/CI15"
sfs_pool1="ST_Pool"
sfs_pool2="ST_Pool2"
sfs_cache="CI15_cache1new"
sfs_username="support"
sfs_password="support"
managedfs1="$sfs_prefix-managed-fs1new"
managedfs2="$sfs_prefix-managed-fs2"
managedfs3="$sfs_prefix-managed-fs3"

sfs_cleanup_list="10.44.86.231:master:master:/vx/CI15-managed-fs1new=10.44.235.0/24:CI15-managed-fs1new__BREAK__10.44.86.231:master:master:/vx/CI15-managed-fs2=10.44.235.16,/vx/CI15-managed-fs2=10.44.235.17:CI15-managed-fs2__BREAK__10.44.86.231:master:master:/vx/CI15-managed-fs3=10.44.235.0/24:CI15-managed-fs3"

sfs_snapshot_cleanup_list="10.44.86.231:master:master:L_CI15-managed-fs1new_=CI15-managed-fs1new:CI15_cache1new"

# VM IMAGE CONTENT
#vm_image_include="run_image"

copytestfile1="http://10.44.235.150/cdb/image_with_ocf_v1_8.qcow2:/var/www/html/images/image_with_ocf_v1_8.qcow2"
copytestfile2="http://10.44.235.150/cdb/ci_test_service1-1.0-1.noarch.rpm:/tmp/test_services/ci_test_service1-1.0-1.noarch.rpm"
copytestfile3="http://10.44.235.150/cdb/vm_rhel_7_test_image-1-1.0.1.qcow2:/var/www/html/images/vm_rhel_7_test_image-1-1.0.1.qcow2"
copytestfile4="http://10.44.235.150/cdb/3PP-dutch-hello-1.0.0-1.noarch.rpm:/tmp/test_services/3PP-dutch-hello-1.0.0-1.noarch.rpm"
copytestfile5="http://10.44.235.150/cdb/3PP-english-hello-1.0.0-1.noarch.rpm:/tmp/test_services/3PP-english-hello-1.0.0-1.noarch.rpm"
copytestfile6="http://10.44.235.150/cdb/test_service-1.0-1.noarch.rpm:/tmp/test_services/test_service-1.0-1.noarch.rpm"

# If set will use the IPs below for MS vm service.
use_real_ip=true

ms_vm_ip[0]="10.44.235.18"
vm_gw_ip="10.44.235.1"
ms_vm_ip6[0]="fdde:4d7e:d471:0004:0:898:18:0/64"
vm_gw6_ip="fdde:4d7e:d471:0004:0:898:0:1"


net1vm_subnet="10.46.92.0/24"
net1vm_gateway="10.46.92.1"
net1vm_ip_ms="10.46.92.2"
net1vm_ip[0]="10.46.92.3"
net1vm_ip[1]="10.46.92.4"
net1vm_ip[2]="10.46.92.5"
net1vm_ip[3]="10.46.92.6"

vm_ip_for_del[0]="10.46.92.23"
vm_ip_for_del[1]="10.46.92.24"

vm_ip[0]="10.46.92.5"
vm_ip[1]="10.46.92.6"
vm_ip[2]="10.46.92.7"
vm_ip[3]="10.46.92.10"
vm_ip[4]="10.46.92.11"
vm_ip[5]="10.46.92.12"
vm_ip[6]="10.46.92.13"
vm_ip[7]="10.46.92.14"
vm_ip[8]="10.46.92.15"
vm_ip[9]="10.46.92.16"
vm_ip[10]="10.46.92.17"
vm_ip[11]="10.46.92.18"
vm_ip[12]="10.46.92.19"
vm_ip[13]="10.46.92.20"
vm_ip[14]="10.46.92.21"
vm_ip[15]="10.46.92.22"


net1vm_gateway6="fdde:4d7e:d471:46::92:1"
vm_ip6[0]="fdde:4d7e:d471:46::92:5/64"
vm_ip6[1]="fdde:4d7e:d471:46::92:6/64"
vm_ip6[2]="fdde:4d7e:d471:46::92:7/64"
vm_ip6[3]="fdde:4d7e:d471:46::92:10/64"
vm_ip6[4]="fdde:4d7e:d471:46::92:11/64"
vm_ip6[5]="fdde:4d7e:d471:46::92:12/64"
vm_ip6[6]="fdde:4d7e:d471:46::92:13/64"
vm_ip6[7]="fdde:4d7e:d471:46::92:14/64"
vm_ip6[8]="fdde:4d7e:d471:46::92:15/64"
vm_ip6[9]="fdde:4d7e:d471:46::92:16/64"
vm_ip6[10]="fdde:4d7e:d471:46::92:17/64"
vm_ip6[11]="fdde:4d7e:d471:46::92:18/64"
vm_ip6[12]="fdde:4d7e:d471:46::92:19/64"
vm_ip6[13]="fdde:4d7e:d471:46::92:20/64"
vm_ip6[14]="fdde:4d7e:d471:46::92:21/64"
vm_ip6[15]="fdde:4d7e:d471:46::92:22/64"


############################################################
# Expansion Specific section
############################################################

exclude_vxvm="exclude"

#### Node 3 Setup        ###################################
node_expansion_hostname[0]="node3"
node_expansion_bmc_ip[0]="10.44.84.127"
node_expansion_sysname[0]="CZJ33308JB"

node_expansion_ip[0]="10.44.235.42"
node_expansion_ip_2[0]="172.16.100.4"
node_expansion_ip_3[0]="172.16.200.132"
node_expansion_ip_4[0]="172.16.201.4"

node_expansion_ipv6_00[0]="fdde:4d7e:d471:0004:0:898:42:0/64"
node_expansion_ipv6_01[0]="fdde:4d7e:d471::835:67:3/64"

node_expansion_eth0_mac[0]="2C:59:E5:3D:C3:88"
node_expansion_eth1_mac[0]="2C:59:E5:3D:C3:8C"
node_expansion_eth2_mac[0]="2C:59:E5:3D:C3:89"
node_expansion_eth3_mac[0]="2C:59:E5:3D:C3:8D"
node_expansion_eth4_mac[0]="2C:59:E5:3D:C3:8A"
node_expansion_eth5_mac[0]="2C:59:E5:3D:C3:8E"
node_expansion_eth6_mac[0]="2C:59:E5:3D:C3:8B"
node_expansion_eth7_mac[0]="2C:59:E5:3D:C3:8F"

node_expansion_disk_uuid[0]="600601600f3133004ce01ebfd0f7e411"
node_expansion_disk1_uuid[0]="600601600f31330036407ab4d1f7e411"

#node_expansion_vxvm_uuid[0]="600601600f313300f6dce12b6f1ee511"
#node_expansion_vxvm2_uuid[0]="600601600f313300f4501a6d6f1ee511"


#### Node 4 Setup        ###################################
node_expansion_hostname[1]="node4"
node_expansion_bmc_ip[1]="10.44.84.128"
node_expansion_sysname[1]="CZJ33308J3"

node_expansion_ip[1]="10.44.235.43"
node_expansion_ip_2[1]="172.16.100.5"
node_expansion_ip_3[1]="172.16.200.133"
node_expansion_ip_4[1]="172.16.201.5"

node_expansion_ipv6_00[1]="fdde:4d7e:d471:0004:0:898:43:0/64"
node_expansion_ipv6_01[1]="fdde:4d7e:d471::835:67:5/64"

node_expansion_eth0_mac[1]="2C:59:E5:3F:B4:58"
node_expansion_eth1_mac[1]="2C:59:E5:3F:B4:5C"
node_expansion_eth2_mac[1]="2C:59:E5:3F:B4:59"
node_expansion_eth3_mac[1]="2C:59:E5:3F:B4:5D"
node_expansion_eth4_mac[1]="2C:59:E5:3F:B4:5A"
node_expansion_eth5_mac[1]="2C:59:E5:3F:B4:5E"
node_expansion_eth6_mac[1]="2C:59:E5:3F:B4:5B"
node_expansion_eth7_mac[1]="2C:59:E5:3F:B4:5F"

node_expansion_disk_uuid[1]="600601600f3133002267c83fd1f7e411"
node_expansion_disk1_uuid[1]="600601600f3133008cc6f703d3f7e411"

#node_expansion_vxvm_uuid[1]="600601600f313300f6dce12b6f1ee511"
#node_expansion_vxvm2_uuid[1]="600601600f313300f4501a6d6f1ee511"

############################################################
# Nodes to shutdown after prepare_restore
prepare_restore_shutdown_ip[0]="10.44.235.16"
prepare_restore_shutdown_ip[1]="10.44.235.17"
prepare_restore_shutdown_ip[2]="10.44.235.42"
prepare_restore_shutdown_ip[3]="10.44.235.43"

