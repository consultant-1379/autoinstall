#!/bin/bash

blade_type="G8"

ms_ilo_ip="10.44.84.46"
ms_ilo_username="root"
ms_ilo_password='Amm30n!!'
ms_ip="10.44.86.100"
ms_subnet="10.44.86.64/26"
ms_gateway="10.44.86.65"
ms_vlan=""
ms_eth0_mac="2C:59:E5:3D:D2:60"
ms_eth1_mac="2C:59:E5:3D:D2:64"
ms_sysname="CZJ33308J8"

nodes_ip_start="10.44.86.100"
nodes_ip_end="10.44.86.102"
nodes_subnet="$ms_subnet"
nodes_gateway="$ms_gateway"
nodes_ilo_password='Amm30n!!'

node_ip[0]="10.44.86.101"
node_sysname[0]="CZJ33308J0"
node_hostname[0]="node1"
node_eth0_mac[0]="2C:59:E5:3F:65:40"
node_disk_uuid[0]="600508b1001c071d8ce19303f0809128"
node_bmc_ip[0]="10.44.84.50"

node_ip[1]="10.44.86.102"
node_sysname[1]="CZJ33308J2"
node_hostname[1]="node2"
node_eth0_mac[1]="2C:59:E5:3D:B3:68"
node_disk_uuid[1]="600508b1001c86f257ba6328fc1dccd2"
node_bmc_ip[1]="10.44.84.51"
