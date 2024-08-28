#!/bin/bash
#
# Add extra node (10.44.84.44) to existing deployment
#
#


set -x

litp create -t blade -p /infrastructure/systems/sys4 -o system_name="CZJ33308J9"

litp create -p /deployments/d1/clusters/c1/nodes/n3 -t node -o hostname=node3dot105 


litp create -t eth -p /deployments/d1/clusters/c1/nodes/n3/network_interfaces/if1            -o device_name=eth1 macaddress="2C:59:E5:3D:B3:4C" ipaddress="10.44.86.88" network_name=mgmt 

litp create -t eth -p /deployments/d1/clusters/c1/nodes/n3/network_interfaces/if4 	     -o device_name=eth4 macaddress="2C:59:E5:3D:B3:4A" network_name=heartbeat1
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n3/network_interfaces/if5 	     -o device_name=eth5 macaddress="2C:59:E5:3D:B3:4E" network_name=heartbeat2

litp create -t eth -p /deployments/d1/clusters/c1/nodes/n3/network_interfaces/if6 	     -o device_name=eth6 macaddress="2C:59:E5:3D:B3:4B" network_name=traffic1 ipaddress="10.19.105.40"




litp create -t disk -p /infrastructure/systems/sys4/disks/boot0 -o name=boot0 size=28G bootable=true uuid=6006016011602d00ac03b5856769e311
litp create -t disk -p /infrastructure/systems/sys4/disks/boot1 -o name=boot1 size=28M bootable=false uuid=6006016011602d00c4a8be46b1c4e311
    

litp create -t bmc -p /infrastructure/systems/sys4/bmc -o ipaddress=10.44.84.44 username=root password_key=key-for-root

litp inherit -p /deployments/d1/clusters/c1/nodes/n3/system -s /infrastructure/systems/sys4
litp inherit -p /deployments/d1/clusters/c1/nodes/n3/os -s /software/profiles/os_prof1
litp inherit -p /deployments/d1/clusters/c1/nodes/n3/storage_profile -s /infrastructure/storage/storage_profiles/profile_1


litp inherit -p /deployments/d1/clusters/c1/nodes/n3/routes/r1 -s /infrastructure/networking/routes/r1
litp inherit -p /deployments/d1/clusters/c1/nodes/n3/routes/r4 -s /infrastructure/networking/routes/r1 -o subnet="10.44.86.192/26" gateway="10.44.86.65"


litp inherit -s /software/items/yum_osHA_repo -p /deployments/d1/clusters/c1/nodes/n3/items/yum_osHA_repo

litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/nh9 -o network_name=traffic1 ip="10.19.105.40"

litp update -p /deployments/d1/clusters/c1 -d critical_service
litp create_plan
