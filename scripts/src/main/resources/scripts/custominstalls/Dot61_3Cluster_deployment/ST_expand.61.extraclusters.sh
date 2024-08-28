#!/bin/bash
#
# Simple script to expand system .61
# Adds 1 cluster and 2 nodes - nodes from .68 system
# In order to use this .61 must be installed with no fencing disks and no VXVM
# All values are hardwired
#
#

set -x

litp create -t blade -p /infrastructure/systems/sys4 -o system_name="sys4"

litp create -t cluster -p /deployments/d1/clusters/AMOS

litp create -t node -p /deployments/d1/clusters/AMOS/nodes/n3 -o hostname=node3dot61 node_id=3

litp create -t eth -p /deployments/d1/clusters/AMOS/nodes/n3/network_interfaces/nic_0 -o device_name=eth0 macaddress=2c:59:e5:3c:5f:f8 network_name=mgmt ipaddress=10.44.235.47

#litp create -t eth -p /deployments/d1/clusters/AMOS/nodes/n3/network_interfaces/nic_2 -o device_name=eth2 macaddress=2c:59:e5:3c:5f:f9 network_name=hb1
#litp create -t eth -p /deployments/d1/clusters/AMOS/nodes/n3/network_interfaces/nic_3 -o device_name=eth3 macaddress=2c:59:e5:3c:5f:fd network_name=hb2
#litp create -t eth -p /deployments/d1/clusters/AMOS/nodes/n3/network_interfaces/nic_4 -o device_name=eth4 macaddress=2c:59:e5:3c:5f:fa network_name=hb3
#litp create -t eth -p /deployments/d1/clusters/AMOS/nodes/n3/network_interfaces/nic_5 -o device_name=eth5 macaddress=2c:59:e5:3c:5f:fe network_name=traffic1 ipaddress=10.19.61.30
#litp create -t eth -p /deployments/d1/clusters/AMOS/nodes/n3/network_interfaces/nic_6 -o device_name=eth6 macaddress=2c:59:e5:3c:5f:fb network_name=traffic2 ipaddress=10.20.61.30

litp create -t disk -p /infrastructure/systems/sys4/disks/disk0 -o name=hd0 size=28G bootable=true uuid=600601600F3133009A406F2B71C9E411

litp create -t bmc -p /infrastructure/systems/sys4/bmc -o ipaddress=10.44.84.130 username=root password_key=key-for-root


litp inherit -p /deployments/d1/clusters/AMOS/nodes/n3/system -s /infrastructure/systems/sys4
litp inherit -p /deployments/d1/clusters/AMOS/nodes/n3/os -s /software/profiles/os_prof1
litp inherit -p /deployments/d1/clusters/AMOS/nodes/n3/storage_profile -s /infrastructure/storage/storage_profiles/profile_1

litp inherit -p /deployments/d1/clusters/AMOS/nodes/n3/routes/r1 -s /infrastructure/networking/routes/r1
litp inherit -p /deployments/d1/clusters/AMOS/nodes/n3/routes/r5 -s /infrastructure/networking/routes/r1 -o subnet=10.44.84.0/24 gateway=10.44.235.1

litp create -t cluster -p /deployments/d1/clusters/varley

litp create -t blade -p /infrastructure/systems/sys5 -o system_name="sys5"

litp create -t node -p /deployments/d1/clusters/varley/nodes/n4 -o hostname=node4dot61 node_id=4

litp create -t eth -p /deployments/d1/clusters/varley/nodes/n4/network_interfaces/nic_0 -o device_name=eth0 macaddress=2c:59:e5:3d:32:58 network_name=mgmt ipaddress=10.44.235.48

#litp create -t eth -p /deployments/d1/clusters/AMOS/nodes/n4/network_interfaces/nic_2 -o device_name=eth2 macaddress=2c:59:e5:3d:32:59 network_name=hb1
#litp create -t eth -p /deployments/d1/clusters/AMOS/nodes/n4/network_interfaces/nic_3 -o device_name=eth3 macaddress=2c:59:e5:3d:32:5d network_name=hb2
#litp create -t eth -p /deployments/d1/clusters/AMOS/nodes/n4/network_interfaces/nic_4 -o device_name=eth4 macaddress=2c:59:e5:3d:32:5a network_name=hb3
#litp create -t eth -p /deployments/d1/clusters/AMOS/nodes/n4/network_interfaces/nic_5 -o device_name=eth5 macaddress=2c:59:e5:3d:32:5e network_name=traffic1 ipaddress=10.19.61.40
#litp create -t eth -p /deployments/d1/clusters/AMOS/nodes/n4/network_interfaces/nic_6 -o device_name=eth6 macaddress=2c:59:e5:3d:32:5b network_name=traffic2 ipaddress=10.20.61.40

litp create -t disk -p /infrastructure/systems/sys5/disks/disk0 -o name=hd0 size=28G bootable=true uuid=600601600F3133005262413971C9E411

litp create -t bmc -p /infrastructure/systems/sys5/bmc -o ipaddress=10.44.84.131 username=root password_key=key-for-root


litp inherit -p /deployments/d1/clusters/varley/nodes/n4/system -s /infrastructure/systems/sys5
litp inherit -p /deployments/d1/clusters/varley/nodes/n4/os -s /software/profiles/os_prof1
litp inherit -p /deployments/d1/clusters/varley/nodes/n4/storage_profile -s /infrastructure/storage/storage_profiles/profile_1

litp inherit -p /deployments/d1/clusters/varley/nodes/n4/routes/r1 -s /infrastructure/networking/routes/r1
litp inherit -p /deployments/d1/clusters/varley/nodes/n4/routes/r5 -s /infrastructure/networking/routes/r1 -o subnet=10.44.84.0/24 gateway=10.44.235.1

litp create_plan

