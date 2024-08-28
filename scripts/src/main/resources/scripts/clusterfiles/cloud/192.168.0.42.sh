#!/bin/bash

blade_type="cloud"

ms_ilo_ip=""
ms_ilo_username=""
ms_ilo_password=""
ms_ip="192.168.0.42"
ms_ipv6_00="2001:1b70:82a1:0103::42/64"
ms_ipv6_00_noprefix="2001:1b70:82a1:0103::42"
ipv6_gateway="2001:1b70:82a1:0103::1"
ms_subnet="192.168.0.0/16"
ms_gateway="192.168.0.1"
ms_vlan=""
ms_host="ms1"
ms_eth0_mac="00:50:56:00:00:42"
ms_eth1_mac="00:50:56:00:00:60"
ms_sysname="MS1"

nodes_ip_start="192.168.0.42"
nodes_ip_end="192.168.0.46"
nodes_subnet="$ms_subnet"
nodes_gateway="$ms_gateway"
nodes_ilo_password=''

dhcp_subnet_1="10.10.14.0/24"
dhcp_range_1_start="10.10.14.3"
dhcp_range_1_end="10.10.14.14"
traffic_network1_gw_subnet="172.16.168.1/32"
traffic_network2_gw_subnet="172.16.168.2/32"

##VCS requires gateway is pingable
traffic_network1_gw="172.16.100.2"
traffic_network2_gw="172.16.200.130"

traffic_network1_subnet="172.16.100.0/24"
traffic_network2_subnet="172.16.200.128/24"
traffic_network4_subnet="172.17.100.0/24"
cluster_id="1042"

nameserver_ip="10.44.86.212"
##network host settings
vcs_network_host1="172.16.101.10"
vcs_network_host3="2001:ABCD:F0::10"
vcs_network_host5="2001:ABCD:F0::10"
vcs_network_host6="172.16.101.11"
vcs_network_host7="2001:ABCD:F0::11"
vcs_network_host8="172.16.101.12"
vcs_network_host12="172.16.101.13"
vcs_network_host13="172.16.101.14"
vcs_network_host14="172.16.101.15"
vcs_network_host15="172.16.101.16"

node_ip[0]="192.168.0.43"
node_ip_2[0]="$traffic_network1_gw"
node_ip_3[0]="$traffic_network2_gw"
dhcp_ip_1[0]="10.10.14.1"
sanity_node_ip_check[0]="192.168.0.43"
node_sysname[0]="MN1"
node_hostname[0]="node1"
node_eth0_mac[0]="00:50:56:00:00:43"
node_eth1_mac[0]="00:50:56:00:00:61"
node_ipv6_00[0]="2001:1b70:82a1:0103::43/64"
node_eth2_mac[0]="00:50:56:00:00:73"
node_eth3_mac[0]="00:50:56:00:00:77"
node_eth4_mac[0]="00:50:56:00:00:75"
node_eth5_mac[0]="00:50:56:00:00:76"
node_eth6_mac[0]="00:50:56:00:00:80"
node_eth7_mac[0]="00:50:56:00:00:88"
node_disk_uuid[0]="kgb"
#node_disk_uuid[0]="6000c29a17c97a09222bcdac91d09ca6"
#node_disk_uuid[0]="6000c29e41df0c3cdc2b558e8b0be7df"
node_bmc_ip[0]=""

node_ip[1]="192.168.0.44"
node_ip_2[1]="172.16.100.3"
node_ip_3[1]="172.16.200.131"
dhcp_ip_1[1]="10.10.14.2"
sanity_node_ip_check[0]="192.168.0.44"
node_sysname[1]="MN2"
node_hostname[1]="node2"
node_eth0_mac[1]="00:50:56:00:00:44"
node_ipv6_00[1]="2001:1b70:82a1:0103::44/64"
node_eth1_mac[1]="00:50:56:00:00:62"
node_eth2_mac[1]="00:50:56:00:00:74"
node_eth3_mac[1]="00:50:56:00:00:78"
node_eth4_mac[1]="00:50:56:00:00:79"
node_eth5_mac[1]="00:50:56:00:00:85"
node_eth6_mac[1]="00:50:56:00:00:83"
node_eth7_mac[1]="00:50:56:00:00:99"
node_disk_uuid[1]="kgb"
#node_disk_uuid[1]="6000c29cf71947cee26f5c25c7d7886f"
#node_disk_uuid[1]="6000c299e5727e4214da69f1c454c676"
node_bmc_ip[1]=""

ntp_ip[2]="127.127.1.0"
ntp_ip[1]=172.16.30.1

##SFS SETUP
sfs_management_ip="172.16.30.17"
sfs_vip="172.16.30.17"
sfs_unmanaged_prefix="/vx/intcdb-fs1"
sfs_prefix="/vx/CIcdb"
sfs_pool1="litp2"
sfs_username="support"
sfs_password="symantec"
managedfs1="$sfs_prefix-managed-fs1"
managedfs2="$sfs_prefix-managed-fs2"
managedfs3="$sfs_prefix-managed-fs3"
