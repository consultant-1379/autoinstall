#!/bin/bash

# variables used in autoinstall scripts for MS install
blade_type="G8"
ms_subnet="10.44.86.0/26"
ms_gateway="10.44.86.1"
ms_vlan=""

# MS variables
ms_ilo_ip="10.44.84.132"
ms_ilo_username="root"
ms_ilo_password="Amm30n!!"
ms_ip="10.44.86.40"
ms_sysname="CZJ33308HS"
ms_host="ms1"
ms_host_short="ms1"
ms_eth0_mac="2c:59:e5:3d:b3:b0"

nameserver_ip="10.44.86.212"

# Node variables
nodes_subnet="$ms_subnet"
nodes_gateway="$ms_gateway"
nodes_ilo_password='shroot12'

cluster_id="4720"

# network host settings
vcs_network_host1="172.16.101.10"
vcs_network_host3="2001:ABCD:F0::10"


## 1st node
node_bmc_ip[0]="10.44.84.92"
node_ip[0]="10.44.86.21"
sanity_node_ip_check[0]="${node_ip[0]}"

node_sysname[0]="CZ28460251"
node_hostname[0]="SC-1"

# Used for PXE boot
node_eth4_mac[0]="20:67:7c:e2:4e:a4"

# These reorder so this doesn't work
node_eth0_mac[0]="48:df:37:63:1b:d0"
node_eth1_mac[0]="48:df:37:63:1b:d8"
node_eth2_mac[0]="48:df:37:60:db:f0"
node_eth3_mac[0]="48:df:37:60:db:f8"

node_disk_uuid[0]="600508B1001C355B72A1F8638180473C"




## 2nd node
node_bmc_ip[1]="10.44.84.177"
node_ip[1]="10.44.86.26"
sanity_node_ip_check[1]="${node_ip[1]}"

node_sysname[1]="CZ3506P7B5"
node_hostname[1]="SC-2"

# Used for PXE boot
node_eth4_mac[1]="38:63:bb:44:00:28"

node_eth0_mac[1]="8c:dc:d4:ae:5d:30"
node_eth1_mac[1]="8c:dc:d4:ae:5d:31"
node_eth2_mac[1]="8c:dc:d4:ae:52:74"
node_eth3_mac[1]="8c:dc:d4:ae:52:75"

node_disk_uuid[1]="600508B1001C762B4A7BACFF43BFD689"
