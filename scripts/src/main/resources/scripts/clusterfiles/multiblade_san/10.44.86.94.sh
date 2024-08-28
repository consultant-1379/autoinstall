#!/bin/bash

# This is a small cluster file to enable us to run prepare restore on the ST-CDB environment
# which has had its management IP changed from 10.44.86.72 to 10.44.86.94

# The differences to .72 are 

# MS IP Changed to 10.44.86.94
# dot73 IP changed to 10.44.86.97
# dot75 IP changed to 10.44.86.93
# CopyFile Lines have been removed



blade_type="G8"

ms_ilo_ip="10.44.84.20"
ms_ilo_username="root"
ms_ilo_password='Amm30n!!'
ms_ip="10.44.86.94"
ms_poweroff_ip="10.44.86.131"
ms_ipv6="fdde:4d7e:d471:0001::835:72:72/64"
ms_ipv6_834="fdde:4d7e:d471::834:72:72/64"
ms_ip_898="10.44.235.103"
ms_ip_836="10.44.86.131"
ms_ip_837="10.44.86.222"
ms_subnet="10.44.86.64/26"
ms_gateway="10.44.86.65"
ms_vlan=""
ms_host="helios.ammeon.com"
ms_host_short='helios'
#ms_eth0_mac="2C:59:E5:3F:E6:F0"
#ms_eth1_mac="2C:59:E5:3F:E6:F4"
#ms_eth2_mac="2C:59:E5:3F:E6:F1"
#ms_eth3_mac="2C:59:E5:3F:E6:F5"
ms_eth0_mac="8C:DC:D4:1D:39:00"
ms_eth1_mac="8C:DC:D4:1D:39:08"
ms_eth2_mac="8C:DC:D4:1D:39:01"
ms_eth3_mac="8C:DC:D4:1D:39:09"

#ms_sysname="CZJ33308J6"
ms_sysname="CZ34216AFK"

ms_disk_uuid="600508b1001cc2fb729fb974aeed0852"
net1vm_ip_ms="10.46.83.2"
net2vm_ip_ms="10.46.80.2"
net3vm_ip_ms="10.46.83.130"
net4vm_ip_ms="10.46.80.130"

nodes_ip_start="10.44.86.72"
nodes_ip_end="10.44.86.76"
nodes_subnet="$ms_subnet"
nodes_subnet_898="10.44.235.0/24"
nodes_subnet_836="10.44.86.129/26"
nodes_subnet_837="10.44.86.193/26"
nodes_gateway="$ms_gateway"
ipv6_835_gateway="fdde:4d7e:d471:0001::835:0:1"
ipv6_834_gateway="fdde:4d7e:d471::834:0:1"
ipv6_traf2_gateway="fdde:4d7e:d471:20::0:1"
ipv6_836_network="fdde:4d7e:d471:0002::0836:0:0/64"
ipv6_837_network="fdde:4d7e:d471:0003::0837:0:0/64"
ipv6_dummy_network="fdde:4d7e:d471:22::0:0/64"

nodes_gateway_898="10.44.235.1"
nodes_ilo_password='Amm30n!!'
vcs_cluster_id="4773"
vcs_cluster2_id="4775"
vcs_cluster3_id="4777"

node_ip[0]="10.44.86.97"
node_ip_updated[0]="10.44.86.97"
node_ip_898[0]="10.44.235.104"
node_ip_836[0]="10.44.86.132"
node_ipv6[0]="fdde:4d7e:d471:0001::835:72:73/64"
node_ipv6_nh[0]="fdde:4d7e:d471:0001::835:72:73"
node_ipv6_837[0]="fdde:4d7e:d471:0003::0837:72:104/64"
node_ipv6_834[0]="fdde:4d7e:d471::834:72:73/64"
traf1_ip[0]="10.19.72.10"
traf1_ipv6[0]="fdde:4d7e:d471:19::72:10/64"
traf1_nhipv6[0]="fdde:4d7e:d471:19::72:10"
traf2_ip[0]="10.20.72.10"
traf2_ipv6[0]="fdde:4d7e:d471:20::72:10/64"
traf2_nhipv6[0]="fdde:4d7e:d471:20::72:10"
node_sysname[0]="CZJ33308J5"
node_hostname[0]="dot73"
node_eth0_mac[0]="2c:59:e5:3f:d6:10"
node_eth1_mac[0]="2c:59:e5:3f:d6:14"
node_eth2_mac[0]="2c:59:e5:3f:d6:11"
node_eth3_mac[0]="2c:59:e5:3f:d6:15"
node_eth4_mac[0]="2c:59:e5:3f:d6:12"
node_eth5_mac[0]="2c:59:e5:3f:d6:16"
node_eth6_mac[0]="2c:59:e5:3f:d6:13"
node_eth7_mac[0]="2c:59:e5:3f:d6:17"
node_disk_uuid[0]="6006016011602d00bc383819f679e311"
node_disk_add1_uuid[0]="6006016011602D00C408E442107FE411"
node_bmc_ip[0]="10.44.84.21"
cluster[0]="1"
sanity_node_ip_check[0]="10.44.86.97"

node_ip[1]="10.44.86.74"
node_ip_898[1]="10.44.235.105"
node_ip_836[1]="10.44.86.133"
node_ipv6[1]="fdde:4d7e:d471:0001::835:72:74/64"
node_ipv6_nh[1]="fdde:4d7e:d471:0001::835:72:74"
node_ipv6_837[1]="fdde:4d7e:d471:0003::0837:72:105/64"
node_ipv6_834[1]="fdde:4d7e:d471::834:72:74/64"
traf1_ip[1]="10.19.72.20"
traf1_ipv6[1]="fdde:4d7e:d471:19::72:20/64"
traf1_nhipv6[1]="fdde:4d7e:d471:19::72:20"
traf2_ip[1]="10.20.72.20"
traf2_ipv6[1]="fdde:4d7e:d471:20::72:20/64"
traf2_nhipv6[1]="fdde:4d7e:d471:20::72:20"
node_sysname[1]="CZJ33308HZ"
node_hostname[1]="dot74"
node_eth0_mac[1]="2c:59:e5:3f:25:30"
node_eth1_mac[1]="2c:59:e5:3f:25:34"
node_eth2_mac[1]="2c:59:e5:3f:25:31"
node_eth3_mac[1]="2c:59:e5:3f:25:35"
node_eth4_mac[1]="2c:59:e5:3f:25:32"
node_eth5_mac[1]="2c:59:e5:3f:25:36"
node_eth6_mac[1]="2c:59:e5:3f:25:33"
node_eth7_mac[1]="2c:59:e5:3f:25:37"
node_disk_uuid[1]="6006016011602d00f2a5ab48f679e311"
node_disk_add1_uuid[1]="6006016011602D00C608E442107FE411"
node_bmc_ip[1]="10.44.84.22"
cluster[1]="1"
sanity_node_ip_check[1]="10.44.86.74"

node_ip[2]="10.44.86.93"
node_ip_898[2]="10.44.235.106"
node_ip_834[2]="10.44.86.50"
node_ip_836[2]="10.44.86.134"
node_ip_837[2]="10.44.86.225"
node_ipv6[2]="fdde:4d7e:d471:0001::835:72:75/64"
node_ipv6_nh[2]="fdde:4d7e:d471:0001::835:72:75"
node_ipv6_837[2]="fdde:4d7e:d471:0003::0837:72:106/64"
node_ipv6_834[2]="fdde:4d7e:d471::834:72:75/64"
traf1_ip[2]="10.19.72.30"
traf1_ipv6[2]="fdde:4d7e:d471:19::72:30/64"
traf1_nhipv6[2]="fdde:4d7e:d471:19::72:30"
traf2_ip[2]="10.20.72.30"
traf2_ipv6[2]="fdde:4d7e:d471:20::72:30/64"
traf2_nhipv6[2]="fdde:4d7e:d471:20::72:30"
node_sysname[2]="CZJ33308J4"
node_hostname[2]="dot75"
node_eth0_mac[2]="2c:59:e5:3f:03:88"
node_eth1_mac[2]="2c:59:e5:3f:03:8c"
node_eth2_mac[2]="2c:59:e5:3f:03:89"
node_eth3_mac[2]="2c:59:e5:3f:03:8d"
node_eth4_mac[2]="2c:59:e5:3f:03:8a"
node_eth5_mac[2]="2c:59:e5:3f:03:8e"
node_eth6_mac[2]="2c:59:e5:3f:03:8b"
node_eth7_mac[2]="2c:59:e5:3f:03:8f"
node_disk_uuid[2]="6006016011602d00c87b127c220ce411"
node_disk_add1_uuid[2]="6006016011602D00C808E442107FE411"
vm_images_disk_uuid[2]="6006016011602D00DA59CC2CA519E511"
vm_instances_disk_uuid[2]="6006016011602D0042BE535BA519E511"
node_bmc_ip[2]="10.44.84.23"
cluster[2]="2"
sanity_node_ip_check[2]="10.44.86.93"
net1vm_ip[2]="10.46.83.3"
net2vm_ip[2]="10.46.80.3"
net3vm_ip[2]="10.46.83.131"
net4vm_ip[2]="10.46.80.131"

node_ip[3]="10.44.86.76"
node_ip_898[3]="10.44.235.107"
node_ip_834[3]="10.44.86.52"
node_ip_836[3]="10.44.86.135"
node_ip_837[3]="10.44.86.226"
node_ipv6[3]="fdde:4d7e:d471:0001::835:72:76/64"
node_ipv6_nh[3]="fdde:4d7e:d471:0001::835:72:76"
node_ipv6_837[3]="fdde:4d7e:d471:0003::0837:72:107/64"
node_ipv6_834[3]="fdde:4d7e:d471::834:72:76/64"
traf1_ip[3]="10.19.72.40"
traf1_ipv6[3]="fdde:4d7e:d471:19::72:40/64"
traf1_nhipv6[3]="fdde:4d7e:d471:19::72:40"
traf2_ip[3]="10.20.72.40"
traf2_ipv6[3]="fdde:4d7e:d471:20::72:40/64"
traf2_nhipv6[3]="fdde:4d7e:d471:20::72:40"
node_sysname[3]="CZJ33308HT"
node_hostname[3]="dot76"
node_eth0_mac[3]="2c:59:e5:3d:b3:18"
node_eth1_mac[3]="2c:59:e5:3d:b3:1c"
node_eth2_mac[3]="2c:59:e5:3d:b3:19"
node_eth3_mac[3]="2c:59:e5:3d:b3:1d"
node_eth4_mac[3]="2c:59:e5:3d:b3:1a"
node_eth5_mac[3]="2c:59:e5:3d:b3:1e"
node_eth6_mac[3]="2c:59:e5:3d:b3:1b"
node_eth7_mac[3]="2c:59:e5:3d:b3:1f"
node_disk_uuid[3]="6006016011602d00cc21d99fd67de311"
node_disk_add1_uuid[3]="6006016011602D00CA08E442107FE411"
vm_images_disk_uuid[3]="6006016011602D00DC59CC2CA519E511"
vm_instances_disk_uuid[3]="6006016011602D0044BE535BA519E511"
node_bmc_ip[3]="10.44.84.24"
cluster[3]="2"
sanity_node_ip_check[3]="10.44.86.76"
net1vm_ip[3]="10.46.83.4"
net2vm_ip[3]="10.46.80.4"
net3vm_ip[3]="10.46.83.132"
net4vm_ip[3]="10.46.80.132"

node_ip[4]="10.44.86.77"
#node_ip_898[4]="10.44.235.107"
#node_ip_836[4]="10.44.86.135"
#node_ip_837[4]="10.44.86.226"
node_ipv6[4]="fdde:4d7e:d471:0001::835:72:77/64"
#node_ipv6_837[4]="fdde:4d7e:d471:0003::0837:72:107/64"
#node_ipv6_834[4]="fdde:4d7e:d471::834:72:76/64"
#traf1_ip[4]="10.19.72.40"
#traf1_ipv6[4]="fdde:4d7e:d471:19::72:40/64"
#traf1_nhipv6[4]="fdde:4d7e:d471:19::72:40"
#traf2_ip[4]="10.20.72.40"
#traf2_ipv6[4]="fdde:4d7e:d471:20::72:40/64"
#traf2_nhipv6[4]="fdde:4d7e:d471:20::72:40"
node_sysname[4]="CZ3128LSDW"
node_hostname[4]="amosC3"
node_eth0_mac[4]="98:4B:E1:69:B1:60"
#node_eth1_mac[4]="2c:59:e5:3d:b3:1c"
node_eth2_mac[4]="98:4B:E1:69:B1:61"
node_eth3_mac[4]="98:4B:E1:69:B1:65"
#node_eth4_mac[4]="2c:59:e5:3d:b3:1a"
#node_eth5_mac[4]="2c:59:e5:3d:b3:1e"
#node_eth6_mac[4]="2c:59:e5:3d:b3:1b"
#node_eth7_mac[4]="2c:59:e5:3d:b3:1f"
node_disk_uuid[4]="6006016011602d00f0d4726f54a5e411"
node_bmc_ip[4]="10.44.84.47"
cluster[4]="3"
sanity_node_ip_check[4]="10.44.86.77"
#net1vm_ip[4]="10.46.83.4"
#net2vm_ip[4]="10.46.80.4"
#net3vm_ip[4]="10.46.83.132"
#net4vm_ip[4]="10.46.80.132"

route2_subnet="10.44.86.0/26"
route3_subnet="10.44.86.128/26"
route4_subnet="10.44.86.192/26"
route_subnet_801="10.44.84.0/24"


#VXVM
vxvm_disk_uuid[0]="6006016011602D00C6225B942035E411"
vxvm_disk_uuid[1]="6006016011602D00DC9E5CC32135E411"
vxvm_disk_uuid[2]="6006016011602D007E8C271E2135E411"
vxvm_disk_uuid[3]="6006016011602D00364722E72135E411"
vxvm_disk_uuid[4]="6006016011602D00349F45861456E511"

#FENCING
fencing_disk_uuid[0]="6006016011602D004C4F52783C59E411"
fencing_disk_uuid[1]="6006016011602D004E4F52783C59E411"
fencing_disk_uuid[2]="6006016011602D00504F52783C59E411"

#NAS
sfs_management_ip="10.44.86.230"
sfs_vip="10.44.86.230"
sfs_prefix="/vx/ST72"
sfs_pool1="SFS_Pool"
sfs_pool2="ST_Pool"
sfs_pool3="ST_Pool2"
sfs_cache1="72cache"
sfs_password="support"
sfs_network_gw="10.44.86.193"
nfs_management_ip="10.44.86.4"
nfs_prefix="/home/admin/ST/nfs_share_dir_72"
#ipv4_allowed_clients_all="10.44.86.73,10.44.86.74,10.44.86.75,10.44.86.76,10.44.86.222"
ipv4_allowed_clients_all="10.44.86.64/26,10.44.86.192/26"
ipv4_allowed_clients_ms="10.44.86.222,10.44.86.227"
ipv4_allowed_clients_nodes_c1="10.44.86.73,10.44.86.74,10.44.86.97"
ipv4_allowed_clients_nodes_c2="10.44.86.192/26"

#SFS CLEANUP
sfs_cleanup_list="10.44.86.231:master:master:/vx/ST72-managedfs1=10.44.86.64/26,/vx/ST72-managedfs1=10.44.86.192/26,/vx/ST72-managedfs1=10.44.86.222:ST72-managedfs1__BREAK__10.44.86.231:master:master:/vx/ST72-managedfs2=10.44.86.73,/vx/ST72-managedfs2=10.44.86.74,/vx/ST72-managedfs2=10.44.86.97:ST72-managedfs2__BREAK__10.44.86.231:master:master:/vx/ST72-managedp2fs=10.44.86.222:ST72-managedp2fs__BREAK__10.44.86.231:master:master:/vx/ST72-managedp3fs=10.44.86.192/26:no_filesystem_cleanup__BREAK__10.44.86.231:master:master:/vx/ST72-managedp4fs=10.44.86.73,/vx/ST72-managedp4fs=10.44.86.97:ST72-managedp4fs__BREAK__10.44.86.231:master:master:/vx/ST72-managedp3fsvm1=10.44.86.192/26:ST72-managedp3fsvm1__BREAK__10.44.86.231:master:master:/vx/ST72-managedp3fsvm2=10.44.86.192/26:ST72-managedp3fsvm2"
sfs_snapshot_cleanup_list="10.44.86.231:master:master:L_ST72-managedp3fsvm1_=ST72-managedp3fsvm1:72cache__BREAK__10.44.86.231:master:master:L_ST72-managedp3fsvm2_=ST72-managedp3fsvm2:72cache__BREAK__10.44.86.231:master:master:L_ST72-managedp2fs_=ST72-managedp2fs:72cache__BREAK__10.44.86.231:master:master:L_ST72-managedp3fs_=ST72-managedp3fs:72cache__BREAK__10.44.86.231:master:master:L_ST72-managedp4fs_=ST72-managedp4fs:72cache__BREAK__10.44.86.231:master:master:L_ST72-managedfs2_=ST72-managedfs2:72cache__BREAK__10.44.86.231:master:master:L_ST72-managedfs1_=ST72-managedfs1:72cache"

#VCS
traf1_subnet="10.19.72.0/24"
traf2_subnet="10.20.72.0/24"
traf1gw_subnet="10.72.19.0/24"
traf2gw_subnet="10.72.20.0/24"

traf1_c3_subnet="10.19.77.0/24"
traf2_c3_subnet="10.20.77.0/24"


#VIPs
traf1_vip[1]="10.19.72.100"
traf1_vip[2]="10.19.72.101"
traf1_vip[3]="10.19.72.102"
traf1_vip[4]="10.19.72.103"
traf1_vip[5]="10.19.72.104"
traf1_vip[6]="10.19.72.105"
traf1_vip[7]="10.19.72.106"
traf1_vip[8]="10.19.72.107"
traf1_vip[9]="10.19.72.108"
traf1_vip[10]="10.19.72.109"
traf1_vip[11]="10.19.72.110"
traf1_vip[12]="10.19.72.111"
traf1_vip[13]="10.19.72.112"
traf1_vip[14]="10.19.72.113"
traf1_vip[15]="10.19.72.114"
traf1_vip[16]="10.19.72.115"
traf1_vip[17]="10.19.72.116"
traf1_vip[18]="10.19.72.117"
traf1_vip[19]="10.19.72.118"
traf1_vip[20]="10.19.72.119"
traf1_vip[21]="10.19.72.120"
traf1_vip[22]="10.19.72.121"
traf1_vip[23]="10.19.72.122"
traf1_vip[24]="10.19.72.123"

traf1_vip_ipv6[1]="fdde:4d7e:d471:19::72:100/64"
traf1_vip_ipv6[2]="fdde:4d7e:d471:19::72:101/64"
traf1_vip_ipv6[3]="fdde:4d7e:d471:19::72:102/64"
traf1_vip_ipv6[4]="fdde:4d7e:d471:19::72:103/64"
traf1_vip_ipv6[5]="fdde:4d7e:d471:19::72:104/64"
traf1_vip_ipv6[6]="fdde:4d7e:d471:19::72:105/64"
traf1_vip_ipv6[7]="fdde:4d7e:d471:19::72:106/64"
traf1_vip_ipv6[8]="fdde:4d7e:d471:19::72:107/64"
traf1_vip_ipv6[9]="fdde:4d7e:d471:19::72:108/64"
traf1_vip_ipv6[10]="fdde:4d7e:d471:19::72:109/64"
traf1_vip_ipv6[11]="fdde:4d7e:d471:19::72:110/64"
traf1_vip_ipv6[12]="fdde:4d7e:d471:19::72:111/64"
traf1_vip_ipv6[13]="fdde:4d7e:d471:19::72:112/64"
traf1_vip_ipv6[14]="fdde:4d7e:d471:19::72:113/64"
traf1_vip_ipv6[15]="fdde:4d7e:d471:19::72:114/64"
traf1_vip_ipv6[16]="fdde:4d7e:d471:19::72:115/64"
traf1_vip_ipv6[17]="fdde:4d7e:d471:19::72:116/64"
traf1_vip_ipv6[18]="fdde:4d7e:d471:19::72:117/64"
traf1_vip_ipv6[19]="fdde:4d7e:d471:19::72:118/64"
traf1_vip_ipv6[20]="fdde:4d7e:d471:19::72:119/64"
traf1_vip_ipv6[21]="fdde:4d7e:d471:19::72:120/64"
traf1_vip_ipv6[22]="fdde:4d7e:d471:19::72:121/64"
traf1_vip_ipv6[23]="fdde:4d7e:d471:19::72:122/64"
traf1_vip_ipv6[24]="fdde:4d7e:d471:19::72:123/64"

traf2_vip[1]="10.20.72.100"
traf2_vip[2]="10.20.72.101"
traf2_vip[3]="10.20.72.102"
traf2_vip[4]="10.20.72.103"
traf2_vip[5]="10.20.72.104"
traf2_vip[6]="10.20.72.105"
traf2_vip[7]="10.20.72.106"
traf2_vip[8]="10.20.72.107"
traf2_vip[9]="10.20.72.108"
traf2_vip[10]="10.20.72.109"
traf2_vip[11]="10.20.72.110"
traf2_vip[12]="10.20.72.111"
traf2_vip[13]="10.20.72.112"
traf2_vip[14]="10.20.72.113"
traf2_vip[15]="10.20.72.114"
traf2_vip[16]="10.20.72.115"
traf2_vip[17]="10.20.72.116"
traf2_vip[18]="10.20.72.117"
traf2_vip[19]="10.20.72.118"
traf2_vip[20]="10.20.72.119"
traf2_vip[21]="10.20.72.120"
traf2_vip[22]="10.20.72.121"
traf2_vip[23]="10.20.72.122"
traf2_vip[24]="10.20.72.123"

traf2_vip_ipv6[1]="fdde:4d7e:d471:20::72:100/64"
traf2_vip_ipv6[2]="fdde:4d7e:d471:20::72:101/64"
traf2_vip_ipv6[3]="fdde:4d7e:d471:20::72:102/64"
traf2_vip_ipv6[4]="fdde:4d7e:d471:20::72:103/64"
traf2_vip_ipv6[5]="fdde:4d7e:d471:20::72:104/64"
traf2_vip_ipv6[6]="fdde:4d7e:d471:20::72:105/64"
traf2_vip_ipv6[7]="fdde:4d7e:d471:20::72:106/64"
traf2_vip_ipv6[8]="fdde:4d7e:d471:20::72:107/64"
traf2_vip_ipv6[9]="fdde:4d7e:d471:20::72:108/64"
traf2_vip_ipv6[10]="fdde:4d7e:d471:20::72:109/64"
traf2_vip_ipv6[11]="fdde:4d7e:d471:20::72:110/64"
traf2_vip_ipv6[12]="fdde:4d7e:d471:20::72:111/64"
traf2_vip_ipv6[13]="fdde:4d7e:d471:20::72:112/64"
traf2_vip_ipv6[14]="fdde:4d7e:d471:20::72:113/64"
traf2_vip_ipv6[15]="fdde:4d7e:d471:20::72:114/64"
traf2_vip_ipv6[16]="fdde:4d7e:d471:20::72:115/64"
traf2_vip_ipv6[17]="fdde:4d7e:d471:20::72:116/64"
traf2_vip_ipv6[18]="fdde:4d7e:d471:20::72:117/64"
traf2_vip_ipv6[19]="fdde:4d7e:d471:20::72:118/64"
traf2_vip_ipv6[20]="fdde:4d7e:d471:20::72:119/64"
traf2_vip_ipv6[21]="fdde:4d7e:d471:20::72:120/64"
traf2_vip_ipv6[22]="fdde:4d7e:d471:20::72:121/64"
traf2_vip_ipv6[23]="fdde:4d7e:d471:20::72:122/64"
traf2_vip_ipv6[24]="fdde:4d7e:d471:20::72:123/64"

#VM DATA

net1vm_subnet="10.46.83.0/25"
net1vm_gateway="10.46.83.1"

net2vm_subnet="10.46.80.0/25"
net2vm_gateway="10.46.80.1"

net3vm_subnet="10.46.83.128/25"
net3vm_gateway="10.46.83.129"

net4vm_subnet="10.46.80.128/25"
net4vm_gateway="10.46.80.129"

net5vmnfs_subnet="10.44.86.1/26"
net5vmnfs_gateway="10.44.86.1"
net5vmnfs_ip="10.44.86.41"

net837_vmip1="10.44.86.223"
net837_vmip2="10.44.86.224"

#VM IPs

# Subnet net1lvm
vm_ip[1]="10.46.83.54"
vm_ip[2]="10.46.83.5"
vm_ip[3]="10.46.83.6"
vm_ip[4]="10.46.83.7"
vm_ip[5]="10.46.83.8"
vm_ip[6]="10.46.83.9"
vm_ip[7]="10.46.83.10"
vm_ip[8]="10.46.83.11"
vm_ip[9]="10.46.83.12"
vm_ip[10]="10.46.83.13"
vm_ip[11]="10.46.83.14"
vm_ip[12]="10.46.83.15"
vm_ip[13]="10.46.83.16"
vm_ip[14]="10.46.83.17"
vm_ip[15]="10.46.83.18"
vm_ip[16]="10.46.83.19"
vm_ip[17]="10.46.83.20"
vm_ip[18]="10.46.83.21"
vm_ip[19]="10.46.83.22"
vm_ip[20]="10.46.83.23"
vm_ip[21]="10.46.83.24"
vm_ip[22]="10.46.83.25"
vm_ip[23]="10.46.83.26"
vm_ip[24]="10.46.83.27"
vm_ip[25]="10.46.83.28"
vm_ip[26]="10.46.83.29"
vm_ip[27]="10.46.83.30"
vm_ip[28]="10.46.83.31"
vm_ip[29]="10.46.83.32"
vm_ip[30]="10.46.83.33"
vm_ip[31]="10.46.83.34"
vm_ip[32]="10.46.83.35"
vm_ip[33]="10.46.83.36"
vm_ip[34]="10.46.83.37"
vm_ip[35]="10.46.83.38"
vm_ip[36]="10.46.83.39"
vm_ip[37]="10.46.83.40"
vm_ip[38]="10.46.83.41"
vm_ip[39]="10.46.83.42"
vm_ip[40]="10.46.83.43"
vm_ip[41]="10.46.83.44"
vm_ip[42]="10.46.83.45"
vm_ip[43]="10.46.83.46"
vm_ip[44]="10.46.83.47"
vm_ip[45]="10.46.83.48"
vm_ip[46]="10.46.83.49"
vm_ip[47]="10.46.83.50"
vm_ip[48]="10.46.83.51"
vm_ip[49]="10.46.83.52"
vm_ip[50]="10.46.83.53"

# subnet net2lvm
vm2_ip[1]="10.46.80.54"
vm2_ip[2]="10.46.80.5"
vm2_ip[3]="10.46.80.6"
vm2_ip[4]="10.46.80.7"
vm2_ip[5]="10.46.80.8"
vm2_ip[6]="10.46.80.9"
vm2_ip[7]="10.46.80.10"
vm2_ip[8]="10.46.80.11"
vm2_ip[9]="10.46.80.12"
vm2_ip[10]="10.46.80.13"
vm2_ip[11]="10.46.80.14"
vm2_ip[12]="10.46.80.15"
vm2_ip[13]="10.46.80.16"
vm2_ip[14]="10.46.80.17"
vm2_ip[15]="10.46.80.18"
vm2_ip[16]="10.46.80.19"
vm2_ip[17]="10.46.80.20"
vm2_ip[18]="10.46.80.21"
vm2_ip[19]="10.46.80.22"
vm2_ip[20]="10.46.80.23"
vm2_ip[21]="10.46.80.24"
vm2_ip[22]="10.46.80.25"
vm2_ip[23]="10.46.80.26"
vm2_ip[24]="10.46.80.27"
vm2_ip[25]="10.46.80.28"
vm2_ip[26]="10.46.80.29"
vm2_ip[27]="10.46.80.30"
vm2_ip[28]="10.46.80.31"
vm2_ip[29]="10.46.80.32"
vm2_ip[30]="10.46.80.33"
vm2_ip[31]="10.46.80.34"
vm2_ip[32]="10.46.80.35"
vm2_ip[33]="10.46.80.36"
vm2_ip[34]="10.46.80.37"
vm2_ip[35]="10.46.80.38"
vm2_ip[36]="10.46.80.39"
vm2_ip[37]="10.46.80.40"
vm2_ip[38]="10.46.80.41"
vm2_ip[39]="10.46.80.42"
vm2_ip[40]="10.46.80.43"
vm2_ip[41]="10.46.80.44"
vm2_ip[42]="10.46.80.45"
vm2_ip[43]="10.46.80.46"
vm2_ip[44]="10.46.80.47"
vm2_ip[45]="10.46.80.48"
vm2_ip[46]="10.46.80.49"
vm2_ip[47]="10.46.80.50"
vm2_ip[48]="10.46.80.51"
vm2_ip[49]="10.46.80.52"
vm2_ip[50]="10.46.80.53"


#subnet net3lvm
vm3_ip[1]="10.46.83.194"
vm3_ip[2]="10.46.83.135"
vm3_ip[3]="10.46.83.136"
vm3_ip[4]="10.46.83.137"
vm3_ip[5]="10.46.83.138"
vm3_ip[6]="10.46.83.139"
vm3_ip[7]="10.46.83.140"
vm3_ip[8]="10.46.83.141"
vm3_ip[9]="10.46.83.142"
vm3_ip[10]="10.46.83.143"
vm3_ip[11]="10.46.83.144"
vm3_ip[12]="10.46.83.145"
vm3_ip[13]="10.46.83.146"
vm3_ip[14]="10.46.83.147"
vm3_ip[15]="10.46.83.148"
vm3_ip[16]="10.46.83.149"
vm3_ip[17]="10.46.83.150"
vm3_ip[18]="10.46.83.161"
vm3_ip[19]="10.46.83.162"
vm3_ip[20]="10.46.83.163"
vm3_ip[21]="10.46.83.164"
vm3_ip[22]="10.46.83.165"
vm3_ip[23]="10.46.83.166"
vm3_ip[24]="10.46.83.167"
vm3_ip[25]="10.46.83.168"
vm3_ip[26]="10.46.83.169"
vm3_ip[27]="10.46.83.170"
vm3_ip[28]="10.46.83.171"
vm3_ip[29]="10.46.83.172"
vm3_ip[30]="10.46.83.173"
vm3_ip[31]="10.46.83.174"
vm3_ip[32]="10.46.83.175"
vm3_ip[33]="10.46.83.176"
vm3_ip[34]="10.46.83.177"
vm3_ip[35]="10.46.83.178"
vm3_ip[36]="10.46.83.179"
vm3_ip[37]="10.46.83.180"
vm3_ip[38]="10.46.83.181"
vm3_ip[39]="10.46.83.182"
vm3_ip[40]="10.46.83.183"
vm3_ip[41]="10.46.83.184"
vm3_ip[42]="10.46.83.185"
vm3_ip[43]="10.46.83.186"
vm3_ip[44]="10.46.83.187"
vm3_ip[45]="10.46.83.188"
vm3_ip[46]="10.46.83.189"
vm3_ip[47]="10.46.83.190"
vm3_ip[48]="10.46.83.191"
vm3_ip[49]="10.46.83.192"
vm3_ip[50]="10.46.83.193"

#subnet net4lvm
vm4_ip[1]="10.46.80.194"
vm4_ip[2]="10.46.80.135"
vm4_ip[3]="10.46.80.136"
vm4_ip[4]="10.46.80.137"
vm4_ip[5]="10.46.80.138"
vm4_ip[6]="10.46.80.139"
vm4_ip[7]="10.46.80.140"
vm4_ip[8]="10.46.80.141"
vm4_ip[9]="10.46.80.142"
vm4_ip[10]="10.46.80.143"
vm4_ip[11]="10.46.80.144"
vm4_ip[12]="10.46.80.145"
vm4_ip[13]="10.46.80.146"
vm4_ip[14]="10.46.80.147"
vm4_ip[15]="10.46.80.148"
vm4_ip[16]="10.46.80.149"
vm4_ip[17]="10.46.80.150"
vm4_ip[18]="10.46.80.161"
vm4_ip[19]="10.46.80.162"
vm4_ip[20]="10.46.80.163"
vm4_ip[21]="10.46.80.164"
vm4_ip[22]="10.46.80.165"
vm4_ip[23]="10.46.80.166"
vm4_ip[24]="10.46.80.167"
vm4_ip[25]="10.46.80.168"
vm4_ip[26]="10.46.80.169"
vm4_ip[27]="10.46.80.170"
vm4_ip[28]="10.46.80.171"
vm4_ip[29]="10.46.80.172"
vm4_ip[30]="10.46.80.173"
vm4_ip[31]="10.46.80.174"
vm4_ip[32]="10.46.80.175"
vm4_ip[33]="10.46.80.176"
vm4_ip[34]="10.46.80.177"
vm4_ip[35]="10.46.80.178"
vm4_ip[36]="10.46.80.179"
vm4_ip[37]="10.46.80.180"
vm4_ip[38]="10.46.80.181"
vm4_ip[39]="10.46.80.182"
vm4_ip[40]="10.46.80.183"
vm4_ip[41]="10.46.80.184"
vm4_ip[42]="10.46.80.185"
vm4_ip[43]="10.46.80.186"
vm4_ip[44]="10.46.80.187"
vm4_ip[45]="10.46.80.188"
vm4_ip[46]="10.46.80.189"
vm4_ip[47]="10.46.80.190"
vm4_ip[48]="10.46.80.191"
vm4_ip[49]="10.46.80.192"
vm4_ip[50]="10.46.80.193"

net1vm_ipv6gateway="fdde:4d7e:d471:1111:0072:0072:0072:0001"

vm1_ipv6[1]="fdde:4d7e:d471:1111:0072:0072:0072:0010/64"
vm1_ipv6[2]="fdde:4d7e:d471:1111:0072:0072:0072:0020/64"
vm1_ipv6[3]="fdde:4d7e:d471:1111:0072:0072:0072:0030/64"
vm1_ipv6[4]="fdde:4d7e:d471:1111:0072:0072:0072:0040/64"

vm2_ipv6[1]="fdde:4d7e:d471:2222:0072:0072:0072:0010/64"
vm2_ipv6[2]="fdde:4d7e:d471:2222:0072:0072:0072:0020/64"
vm2_ipv6[3]="fdde:4d7e:d471:2222:0072:0072:0072:0030/64"
vm2_ipv6[4]="fdde:4d7e:d471:2222:0072:0072:0072:0040/64"

vm3_ipv6[1]="fdde:4d7e:d471:3333:0072:0072:0072:0010/64"
vm3_ipv6[2]="fdde:4d7e:d471:3333:0072:0072:0072:0020/64"
vm3_ipv6[3]="fdde:4d7e:d471:3333:0072:0072:0072:0030/64"
vm3_ipv6[4]="fdde:4d7e:d471:3333:0072:0072:0072:0040/64"

vm4_ipv6[1]="fdde:4d7e:d471:4444:0072:0072:0072:0010/64"
vm4_ipv6[2]="fdde:4d7e:d471:4444:0072:0072:0072:0020/64"
vm4_ipv6[3]="fdde:4d7e:d471:4444:0072:0072:0072:0030/64"
vm4_ipv6[4]="fdde:4d7e:d471:4444:0072:0072:0072:0040/64"

# PREPARE RESTORE
num_clusters="3"
num_prepare_restore_tasks="746"
