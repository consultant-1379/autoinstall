#!/bin/bash
#
# Sample LITP multi-blade deployment (SAN version)
#
# Usage:
#   ST_Deployment_12.sh <CLUSTER_SPEC_FILE>
##

litp update -p /litp/logging -o force_debug=true

if [ "$#" -lt 1 ]; then
    echo -e "Usage:\n  $0 <CLUSTER_SPEC_FILE>" >&2
    exit 1
fi

cluster_file="$1"
source "$cluster_file"

set -x

litpcrypt set key-for-root root "${nodes_ilo_password}"
litpcrypt set key-for-sfs support support

litp create -p /software/profiles/os_prof1 -t os-profile -o name=os-profile1 path=/var/www/html/6/os/x86_64/
litp create -p /deployments/d1 -t deployment
litp create -p /deployments/d1/clusters/c1 -t vcs-cluster -o cluster_type=sfha low_prio_net=mgmt llt_nets=heartbeat1,heartbeat2 cluster_id="${vcs_cluster_id}"
#litp create -t clustered-service -p /deployments/d1/clusters/c1/services/PMmed -o active=1 standby=1 name=PMmed
litp create -p /ms/services/cobbler -t cobbler-service
litp create -p /infrastructure/systems/sys1 -t blade -o system_name="${ms_sysname}"

# Create storage volume group 1
litp create -p /infrastructure/storage/storage_profiles/profile_1 -t storage-profile #-o storage_profile_name=sp1
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1 -t volume-group -o volume_group_name=vg_root
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/internal -t physical-device -o device_name=hd0
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/internal1 -t physical-device -o device_name=s1
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/internal2 -t physical-device -o device_name=s2
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/root -t file-system -o type=ext4 mount_point=/ size=8G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/swap -t file-system -o type=swap mount_point=swap size=2G
for (( i=0; i<2; i++ )); do
        litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/VG1_FS$i -t file-system -o type=ext4 mount_point=/mp_VG1_FS$i size=200M snap_size=$((100-($i * 10)))
done

# Create storage volume group 2
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg2 -t volume-group -o volume_group_name=vg_secondDisk
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg2/physical_devices/internal -t physical-device -o device_name=hd1
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg2/physical_devices/internal1 -t physical-device -o device_name=s3
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg2/physical_devices/internal2 -t physical-device -o device_name=s4
for (( i=0; i<3; i++ )); do
        litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg2/file_systems/VG2FS$i -t file-system -o type=ext4 mount_point=/mp_VG2_FS$i size=500M snap_size=$((100-($i * 10)))
done
# done (VG1 and VG2)

### NTP ###
litp create -t ntp-service -p /software/items/ntp1 #-o name=ntp1


### Cluster Level Aliases ####
# Alias
litp create -t alias-cluster-config -p /deployments/d1/clusters/c1/configs/alias_config
litp create -t alias -p /deployments/d1/clusters/c1/configs/alias_config/aliases/sfs_alias -o alias_names="sfsAlias","nasAlias" address="${sfs_management_ip}"

# Finished Creating Cluster Level Aliases

### MS Level Aliases ###
litp create -t alias-node-config -p /ms/configs/alias_config

for (( i=0; i<${#ntp_ip[@]}; i++ )); do
    litp create -t alias -p /ms/configs/alias_config/aliases/ntp_alias_$(($i+1)) -o alias_names=ntp-alias-$(($i+1)) address="${ntp_ip[i+1]}"
done

# done with NTP +3


# litp create -t nfs-service -p /infrastructure/storage/storage_providers/nfs_service -o service_name="sfs1" management_ip="${sfs_management_ip}" user_name="master" password="master" service_type="SFS"
# litp create -t nfs-service -p /infrastructure/storage/storage_providers/nfs_service -o service_name="sfs1" management_ip="${sfs_management_ip}" user_name='support' password_key='key-for-sfs' service_type="SFS"


for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp create -p /infrastructure/systems/sys$(($i+2)) -t blade -o system_name="${node_sysname[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk0 -t disk -o name=hd0 size=28G bootable=true uuid="${node_disk_uuid[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk1 -t disk -o name=hd1 size=28G bootable=false uuid="${node_disk1_uuid[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/bmc -t bmc -o ipaddress="${node_bmc_ip[$i]}" username=root password_key=key-for-root
done

litp create -t route   -p /infrastructure/networking/routes/route1 -o subnet="0.0.0.0/0" gateway="${nodes_gateway}"
litp create -t network -p /infrastructure/networking/networks/mgmt -o name=mgmt subnet="${nodes_subnet}" litp_management=true
litp create -t network -p /infrastructure/networking/networks/data -o name=data subnet="${nodes_subnet_ext}" 
litp create -t network -p /infrastructure/networking/networks/data1 -o name=data1
litp create -t network -p /infrastructure/networking/networks/heartbeat1 -o name=heartbeat1
litp create -t network -p /infrastructure/networking/networks/heartbeat2 -o name=heartbeat2
litp create -t network -p /infrastructure/networking/networks/traffic1 -o name=traffic1 # subnet="${traf1_subnet}"
litp create -t network -p /infrastructure/networking/networks/traffic2 -o name=traffic2 subnet="${traf2_subnet}"
litp create -t network -p /infrastructure/networking/networks/xxx1 -o name=xxx1
litp create -t network -p /infrastructure/networking/networks/xxx2 -o name=xxx2
litp create -t network -p /infrastructure/networking/networks/bare_nic -o name=bare_nic
litp create -t network -p /infrastructure/networking/networks/vlan1_node2 -o name=vlan1_node2 subnet="${nodes_subnet_ext}"
litp create -t network -p /infrastructure/networking/networks/subnet_834 -o name=netwk834
litp create -t network -p /infrastructure/networking/networks/subnet_835 -o name=netwk835
litp create -t network -p /infrastructure/networking/networks/subnet_836 -o name=netwk836 
litp create -t network -p /infrastructure/networking/networks/subnet_837 -o name=netwk837
litp create -t route6  -p /infrastructure/networking/routes/route1_ipv6  -o                subnet=fdde:4e7e:d473::835:0:0/96      gateway=fdde:4d7e:d473::835:90:80
litp create -t route6  -p /infrastructure/networking/routes/route2_ipv6  -o                subnet=::/0                            gateway=fdde:4d7e:d471::898:1:1
litp create -t network -p /infrastructure/networking/networks/net1vm -o name=net1vm subnet="${net1vm_subnet}" 


# MS NICs, bonds and Vlans

litp create -t eth -p /ms/network_interfaces/if0 -o device_name=eth0 macaddress="${ms_eth0_mac}" master=bond0
litp create -t eth -p /ms/network_interfaces/if3 -o device_name=eth3 macaddress="${ms_eth3_mac}" master=bond0
litp create -t bond -p /ms/network_interfaces/b0 -o device_name='bond0' mode=1 miimon=100 ipaddress="${ms_ip}" ipv6address="${ms_ipv6_00}" network_name=mgmt
# litp create -t vlan -p /ms/network_interfaces/bond0_835 -o device_name='bond0.835' ipaddress="${ms_ip}" ipv6address="${ms_ipv6_00}" network_name=mgmt

# litp create -t eth -p /ms/network_interfaces/if0 -o device_name=eth0 macaddress="${ms_eth0_mac}" ipaddress="${ms_ip}" network_name=mgmt ipv6address="${ms_ipv6_00}"
litp create -t eth -p /ms/network_interfaces/if1 -o device_name=eth1 macaddress="${ms_eth1_mac}" ipaddress="${ms_ip_ext}" network_name=data ipv6address="${ms_ipv6_01}"
litp create -t eth  -p /ms/network_interfaces/if2 -o device_name=eth2 macaddress="${ms_eth2_mac}"
litp create -t vlan -p /ms/network_interfaces/vlan834 -o device_name=eth2.834                     network_name=netwk834 ipv6address="${ms_ipv6_02}"
# litp create -t vlan -p /ms/network_interfaces/vlan835 -o device_name=eth2.835                     network_name=netwk835 ipv6address="${ms_ipv6_03}"
litp create -t vlan -p /ms/network_interfaces/vlan836 -o device_name=eth2.836                     network_name=netwk836 ipv6address="${ms_ipv6_04}"
litp create -t vlan -p /ms/network_interfaces/vlan837 -o device_name=eth2.837                     network_name=netwk837 ipv6address="${ms_ipv6_05}"
# litp create -t vlan -p /ms/network_interfaces/vlan911 -o device_name=eth2.911 bridge=br0
litp create -t bridge -p /ms/network_interfaces/br0 -o device_name=br0 network_name=net1vm ipaddress="${net1vm_ip_ms}"
litp create -t eth -p /ms/network_interfaces/if5 -o device_name=eth5 macaddress=2C:59:E5:3D:E3:DE bridge=br0


# 5 MS routes

litp inherit -p /ms/system -s /infrastructure/systems/sys1
litp inherit -p /ms/items/ntp -s /software/items/ntp1
litp inherit -p /ms/routes/route1 -s /infrastructure/networking/routes/route1
litp inherit -p /ms/routes/route2 -s /infrastructure/networking/routes/route1 	-o subnet="${route2_subnet}" gateway="${nodes_gateway}"
litp inherit -p /ms/routes/route3 -s /infrastructure/networking/routes/route1	-o subnet="${route3_subnet}" gateway="${nodes_gateway}"
litp inherit -p /ms/routes/route4 -s /infrastructure/networking/routes/route1 	-o subnet="${route4_subnet}" gateway="${nodes_gateway}"
litp inherit -p /ms/routes/route5 -s /infrastructure/networking/routes/route1 	-o subnet="${route_subnet_801}" gateway="${nodes_gateway_ext}"
litp inherit -p /ms/routes/route6 -s /infrastructure/networking/routes/route1_ipv6
litp inherit -p /ms/routes/route7 -s /infrastructure/networking/routes/route2_ipv6

litp update -p /ms -o hostname="${ms_host}"

#  Create Nics

litp create -p /deployments/d1/clusters/c1/nodes/n1 -t node -o hostname=node1dot90
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if0 	     -o device_name=eth0 macaddress="${node_eth0_mac[0]}" network_name=data1 ipv6address="${ipv6_00[0]}"
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if1            -o device_name=eth1 macaddress="${node_eth1_mac[0]}" master=bond0
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if7 	     -o device_name=eth7 macaddress="${node_eth7_mac[0]}" master=bond0
litp create -t bond -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/b0 	     -o device_name='bond0' mode=1 miimon=100 ipv6address="${ipv6_01[0]}" ipaddress="${node_ip[0]}" network_name=mgmt

#litp create -t bond -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/b1 	     -o device_name='bond1' mode=1 miimon=100 ipv6address="${ipv6_19[0]}" network_name=xxx1
#litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if2 	     -o device_name=eth2 macaddress="${node_eth2_mac[0]}" master=bond1
#litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if3            -o device_name=eth3 macaddress="${node_eth3_mac[0]}" master=bond1

litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if2 	     -o device_name=eth2 macaddress="${node_eth2_mac[0]}" network_name=xxx1 ipv6address="${ipv6_19[0]}"
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if3 	     -o device_name=eth3 macaddress="${node_eth3_mac[0]}" #network_name=xxx2 ipv6address="${ipv6_12[0]}"

#litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/vlan834       -o device_name=eth3.834  network_name=netwk834 ipv6address="${ipv6_11[0]}"
#litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/vlan835       -o device_name=eth3.835  network_name=netwk835 ipv6address="${ipv6_13[0]}"
litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/vlan836       -o device_name=eth3.836  network_name=netwk836 ipv6address="${ipv6_14[0]}" 
litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/vlan837       -o device_name=eth3.837  network_name=netwk837 ipv6address="${ipv6_15[0]}"
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if4 	     -o device_name=eth4 macaddress="${node_eth4_mac[0]}" network_name=heartbeat1
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if5 	     -o device_name=eth5 macaddress="${node_eth5_mac[0]}" network_name=heartbeat2
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if6 	     -o device_name=eth6 macaddress="${node_eth6_mac[0]}" network_name=traffic1 ipv6address="${ipv6_16[0]}" # ipaddress="${traf1_ip[0]}" 


litp create -p /deployments/d1/clusters/c1/nodes/n2 -t node -o hostname=node2dot90
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if0 	-o device_name=eth0 macaddress="${node_eth0_mac[1]}" master=bond0
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if6 	-o device_name=eth6 macaddress="${node_eth6_mac[1]}" master=bond0
litp create -t bond -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/b0 	-o device_name='bond0' mode=1 miimon=100 ipv6address="${ipv6_00[1]}" ipaddress="${node_ip[1]}" network_name=mgmt
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if1 	-o device_name=eth1 macaddress="${node_eth1_mac[1]}" network_name=data1 ipv6address="${ipv6_01[1]}"
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if2 	-o device_name=eth2 macaddress="${node_eth2_mac[1]}" network_name=heartbeat1
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if3 	-o device_name=eth3 macaddress="${node_eth3_mac[1]}" network_name=traffic1 ipv6address="${ipv6_15[1]}" # ipaddress="${traf1_ip[1]}"
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if4 	-o device_name=eth4 macaddress="${node_eth4_mac[1]}" network_name=heartbeat2 
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if5 	-o device_name=eth5 macaddress="${node_eth5_mac[1]}" network_name=bare_nic ipv6address=fdde:4d7e:d473::899:90:150/96
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if7 	-o device_name=eth7 macaddress="${node_eth7_mac[1]}"
litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/vlan834       -o device_name=eth7.834  network_name=netwk834 ipv6address="${ipv6_16[1]}"
# litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/vlan835       -o device_name=eth7.835  network_name=netwk835 ipv6address="${ipv6_11[1]}"
litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/vlan836       -o device_name=eth7.836  network_name=netwk836 ipv6address="${ipv6_12[1]}" 
litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/vlan837       -o device_name=eth7.837  network_name=netwk837 ipv6address="${ipv6_13[1]}"


# Adding routes

for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp create  -p /deployments/d1/clusters/c1/nodes/n$(($i+1)) -t node -o hostname="${node_hostname[$i]}"
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/system             -s /infrastructure/systems/sys$(($i+2))
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/os                 -s /software/profiles/os_prof1
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/storage_profile    -s /infrastructure/storage/storage_profiles/profile_1
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/ntp1         -s /software/items/ntp1
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/route1      -s /infrastructure/networking/routes/route1
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/route2      -s /infrastructure/networking/routes/route1 -o subnet="${route2_subnet}"    gateway="${ms_gateway}"
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/route3      -s /infrastructure/networking/routes/route1 -o subnet="${route3_subnet}"    gateway="${ms_gateway}"
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/route4      -s /infrastructure/networking/routes/route1 -o subnet="${route4_subnet}"    gateway="${ms_gateway}"
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/route5      -s /infrastructure/networking/routes/route1 -o subnet="${route_subnet_801}" gateway="${ms_gateway}"
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/route1_ipv6 -s /infrastructure/networking/routes/route1_ipv6
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/route2_ipv6 -s /infrastructure/networking/routes/route2_ipv6
done

# Bridge for nodes for private network

litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/vlan911 -o device_name=eth3.911 bridge=br1
litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/vlan911 -o device_name=eth7.911 bridge=br1
litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/br1 -o device_name=br1 network_name=net1vm ipaddress="${net1vm_ip[0]}"
litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/br1 -o device_name=br1 network_name=net1vm ipaddress="${net1vm_ip[1]}"

# Network hosts

litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/traffic1_ipv6_10 -o network_name=traffic1 ip="${ipv6_16[0]}"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/traffic1_ipv6_20 -o network_name=traffic1 ip="${ipv6_15[1]}"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/traffic1_ipv6_30 -o network_name=traffic1 ip="${ipv6_21[0]}"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/traffic1_bare_nic -o network_name=bare_nic ip=fdde:4d7e:d473::899:90:150

litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/traf_vm1 -o network_name=net1vm ip="${net1vm_ip[0]}"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/traf_vm2 -o network_name=net1vm ip="${net1vm_ip[1]}"

# Firewall

# CLUSTER
litp create -t firewall-cluster-config -p /deployments/d1/clusters/c1/configs/fw_config
litp create -t firewall-rule -p /deployments/d1/clusters/c1/configs/fw_config/rules/fw_icmp -o 'name=100 icmp' proto=icmp
litp create -t firewall-rule -p /deployments/d1/clusters/c1/configs/fw_config/rules/fw_nfstcp -o 'name=001 nfstcp' dport=111,2049,4001 proto=tcp
litp create -t firewall-rule -p /deployments/d1/clusters/c1/configs/fw_config/rules/fw_icmpv6 -o 'name=101 icmpv6' proto=ipv6-icmp provider=ip6tables
litp create -t firewall-rule -p /deployments/d1/clusters/c1/configs/fw_config/rules/fw_vmhc -o 'name=300 vmhc' proto=tcp dport=12987 provider=iptables
litp create -t firewall-rule -p /deployments/d1/clusters/c1/configs/fw_config/rules/fw_dnsudp -o 'name=201 dnsudp' dport=53 proto=udp
litp create -t firewall-rule -p /deployments/d1/clusters/c1/configs/fw_config/rules/fw_dnstcp -o 'name=200 dnstcp' dport=53 proto=tcp



# NODE
for (( i=0; i<${#node_sysname[@]}; i++ )); do

  litp create -t firewall-node-config -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config
  litp create -t firewall-rule -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config/rules/fw_nfsudp -o 'name=011 nfsudp' dport=111,2049,4001 proto=udp

done


# Extra routes

# litp create -p /infrastructure/networking/routes/traffic1_gw -t route -o subnet=10.19.72.0/24 gateway=10.19.90.0
# litp inherit -p /deployments/d1/clusters/c1/nodes/n1/routes/traffic1_gw -s /infrastructure/networking/routes/traffic1_gw
# litp inherit -p /deployments/d1/clusters/c1/nodes/n2/routes/traffic1_gw -s /infrastructure/networking/routes/traffic1_gw

# Non SFS

litp create -t nfs-service -p /infrastructure/storage/storage_providers/nas_service_sp1 -o name="nas1" ipv4address="${nfs_management_ip}"
litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/nm1 -o export_path="${nfs_prefix}/dir_share_90_C" provider="nas1" mount_point="/cluster_ro" mount_options="soft,intr" network_name="mgmt"
litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/nm2 -o export_path="${nfs_prefix}/dir_share_90_A" provider="nas1" mount_point="/cluster_rw" mount_options="soft,intr" network_name="mgmt"

litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mountCaransebes -o export_path="${nfs_prefix}/dir_share_90_C" provider="nas1" mount_point="/ms_share_nfs" mount_options="soft,intr" network_name="mgmt"
litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mountDrobeta -o export_path="${nfs_prefix}/dir_share_90_B" provider="nas1" mount_point="/ms_share_nfs1" mount_options="soft,intr" network_name="mgmt"


for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/file_systems/nm1 -s /infrastructure/storage/nfs_mounts/nm1
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/file_systems/nm2 -s /infrastructure/storage/nfs_mounts/nm2
done

#MS
litp inherit -p /ms/file_systems/fs1 -s /infrastructure/storage/nfs_mounts/mountArad
litp inherit -p /ms/file_systems/fs3 -s /infrastructure/storage/nfs_mounts/mountCaransebes
litp inherit -p /ms/file_systems/fs4 -s /infrastructure/storage/nfs_mounts/mountDrobeta


#Sysparms  
litp create -t sysparam-node-config -p /ms/configs/sysctl
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl01 -o key="fs.mqueue.msgsize_max" value="8200"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl02 -o key="dev.raid.speed_limit_min" value="1100"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_enm1 -o key="net.core.rmem_default" value="100000000"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_enm2 -o key="net.core.rmem_max" value="100000000"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_enm3 -o key="net.core.wmem_default" value="640000"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_enm4 -o key="net.core.wmem_max" value="640000"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_enm5 -o key="vm.swappiness" value="10"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_enm6 -o key="kernel.core_pattern" value="/ericsson/tor/dumps/core.%e.pid%p.usr%u.sig%s.tim%t"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_enm7 -o key="vm.nr_hugepages" value="47104"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_enm8 -o key="vm.hugetlb_shm_group" value="205"

for (( i=0; i<${#node_sysname[@]}; i++ )); do
 litp create -t sysparam-node-config -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl01 -o key="kernel.threads-max" value="4132410"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl02 -o key="vm.dirty_background_ratio" value="11"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl03 -o key="debug.kprobes-optimization" value="0"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl04 -o key="sunrpc.udp_slot_table_entries" value="15"
#      litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl05 -o key="vxvm.vxio.vol_failfast_on_write" value="2"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_enm1 -o key="net.core.rmem_default" value="100000000"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_enm2 -o key="net.core.rmem_max" value="100000000"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_enm3 -o key="net.core.wmem_default" value="640000"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_enm4 -o key="net.core.wmem_max" value="640000"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_enm5 -o key="vm.swappiness" value="10"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_enm6 -o key="kernel.core_pattern" value="/ericsson/tor/dumps/core.%e.pid%p.usr%u.sig%s.tim%t"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_enm7 -o key="vm.nr_hugepages" value="47104"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_enm8 -o key="vm.hugetlb_shm_group" value="205"
done;



# Name servers 

litp create -t dns-client -p /deployments/d1/clusters/c1/nodes/n1/configs/dns_client -o search=ammeonvpn.com,masteroforion123456789.com,ex3.com,ex4444444444444444.com,a5.com,6666666666666666.com
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n1/configs/dns_client/nameservers/name_server_A -o ipaddress="${ipv6_nameserver_ip}" position=1
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n1/configs/dns_client/nameservers/name_server_B -o ipaddress="${ipv4_nameserver_ip}" position=2


litp create -t dns-client -p /deployments/d1/clusters/c1/nodes/n2/configs/dns_client -o search=ammeonvpn.com,masteroforion123456789.com,ex3.com,ex4444444444444444.com,a5.com,6666666666666666.com
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n2/configs/dns_client/nameservers/name_server_A -o ipaddress="${ipv6_nameserver_ip}" position=1
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n2/configs/dns_client/nameservers/name_server_B -o ipaddress="${ipv4_nameserver_ip}" position=2


#node 1 disks

litp create -p /infrastructure/systems/sys2/disks/disk2 -t disk -o name=hd2 size=5G bootable=false uuid="${hd2_uuid[0]}"
litp create -p /infrastructure/systems/sys2/disks/disk3 -t disk -o name=hd3 size=5G bootable=false uuid="${hd3_uuid[0]}"

litp create -p /infrastructure/systems/sys2/disks/disk4 -t disk -o name=s1 size=11G bootable=false uuid="${hd4_uuid[0]}"
litp create -p /infrastructure/systems/sys2/disks/disk5 -t disk -o name=s2 size=11G bootable=false uuid="${hd5_uuid[0]}"
litp create -p /infrastructure/systems/sys2/disks/disk6 -t disk -o name=s3 size=11G bootable=false uuid="${hd6_uuid[0]}"
litp create -p /infrastructure/systems/sys2/disks/disk7 -t disk -o name=s4 size=11G bootable=false uuid="${hd7_uuid[0]}"

#node 2 disks

litp create -p /infrastructure/systems/sys3/disks/disk3 -t disk -o name=hd3 size=5G bootable=false uuid="${hd3_uuid[1]}"
litp create -p /infrastructure/systems/sys3/disks/disk2 -t disk -o name=hd2 size=5G bootable=false uuid="${hd2_uuid[1]}"

litp create -p /infrastructure/systems/sys3/disks/disk4 -t disk -o name=s1 size=11G bootable=false uuid="${hd4_uuid[1]}"
litp create -p /infrastructure/systems/sys3/disks/disk5 -t disk -o name=s2 size=11G bootable=false uuid="${hd5_uuid[1]}"
litp create -p /infrastructure/systems/sys3/disks/disk6 -t disk -o name=s3 size=11G bootable=false uuid="${hd6_uuid[1]}"
litp create -p /infrastructure/systems/sys3/disks/disk7 -t disk -o name=s4 size=11G bootable=false uuid="${hd7_uuid[1]}"


litp create -t storage-profile -p /infrastructure/storage/storage_profiles/profile_2 -o volume_driver=vxvm

litp inherit -p /deployments/d1/clusters/c1/storage_profile/sp2 -s /infrastructure/storage/storage_profiles/profile_2

litp create -t volume-group -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vg_vxvm_0 -o volume_group_name=vg_vxvm_0
# litp create -t file-system -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vg_vxvm_0/file_systems/VxVM_VG2_FS_0 -o type=vxfs size=2G snap_size=100 mount_point=/VxVM_mp_VG2_FS0
litp create -t file-system -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vg_vxvm_0/file_systems/VxVMVG2FS0 -o type=vxfs size=2G snap_size=100 mount_point=/VxVM_mp_VG2_FS0
litp create -t physical-device -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vg_vxvm_0/physical_devices/hd1_vxvm -o device_name=hd2

litp create -t volume-group -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vg_vxvm_1 -o volume_group_name=vg_vxvm_1
# litp create -t file-system -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vg_vxvm_1/file_systems/VxVM_VG2_FS_1 -o type=vxfs size=2G snap_size=100 mount_point=/VxVM_mp_VG2_FS1
litp create -t file-system -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vg_vxvm_1/file_systems/VxVMVG2FS1 -o type=vxfs size=2G snap_size=100 mount_point=/VxVM_mp_VG2_FS1
litp create -t physical-device -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vg_vxvm_1/physical_devices/hd1_vxvm -o device_name=hd3



# fencing 

litp create -t disk -p /deployments/d1/clusters/c1/fencing_disks/fd1 -o uuid=6006016011602d00a0840eb51170e411 size=90M name=fencing_disk_1
litp create -t disk -p /deployments/d1/clusters/c1/fencing_disks/fd2 -o uuid=6006016011602d0068e535c91170e411 size=90M name=fencing_disk_2
litp create -t disk -p /deployments/d1/clusters/c1/fencing_disks/fd3 -o uuid=6006016011602d00b2ef50a01170e411 size=90M name=fencing_disk_3


# Service Groups
# 2 F/O SGs - 1st SG #VIP=#AC 2nd SG  #VIP=2x#AC
# 1 PL  SGs -  

x=0
SG_pkg[x]="cups";    SG_rel[x]="67.el6"; SG_ver[x]="1.4.2";    SG_VIP_count[x]=3;      SG_active[x]=1; SG_standby[x]=1 status_interval[x]=30	status_timeout[x]=20	restart_limit[x]=2	startup_retry_limit[x]=1	node_list[x]="n2,n1" dependency_list[x]="SG_httpd" 	   x=$[$x+1]
SG_pkg[x]="luci";    SG_rel[x]="63.el6";     SG_ver[x]="0.26.0";   SG_VIP_count[x]=4;      SG_active[x]=1; SG_standby[x]=1 status_interval[x]=10	status_timeout[x]=10	restart_limit[x]=0	startup_retry_limit[x]=0	node_list[x]="n1,n2" dependency_list[x]="SG_cups"  	   x=$[$x+1]
SG_pkg[x]="httpd";   SG_rel[x]="39.el6";   SG_ver[x]="2.2.15";   SG_VIP_count[x]=$[5*2]; SG_active[x]=2; SG_standby[x]=0 status_interval[x]=20	status_timeout[x]=60	restart_limit[x]=10	startup_retry_limit[x]=10 	node_list[x]="n1,n2"					   x=$[$x+1]
# SG_pkg[x]="ricci"; SG_rel[x]="63.el6";     SG_ver[x]="0.16.2";   SG_rel[x]="63.el6"; 	SG_ver[x]="0.16.2";     SG_VIP_count[x]=$[2*2]; SG_active[x]=2; SG_standby[x]=0 status_interval[x]=1000	status_timeout[x]=1000	restart_limit[x]=1000startup_retry_limit[x]=1000	x=$[$x+1]

vip_count=1
for (( x=0; x<${#SG_pkg[@]}; x++ )); do
litp create -t package               -p /software/items/"${SG_pkg[$x]}" -o name="${SG_pkg[$x]}" repository=OS version="${SG_ver[$x]}" release="${SG_rel[$x]}" 
litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}" -o active="${SG_active[$x]}" standby="${SG_standby[$x]}" name=vcs$(($x+1)) online_timeout=45 node_list="${node_list[$x]}" dependency_list="${dependency_list[$x]}"
litp create -t ha-service-config     -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}"/ha_configs/conf1 -o status_interval="${status_interval[$x]}" status_timeout="${status_timeout[$x]}" restart_limit="${restart_limit[$x]}" startup_retry_limit="${startup_retry_limit[$x]}"
litp create -t service           -p /software/services/"${SG_pkg[$x]}" -o service_name="${SG_pkg[$x]}"
litp inherit                     -p /software/services/"${SG_pkg[$x]}"/packages/pkg1 -s /software/items/"${SG_pkg[$x]}"
litp inherit                     -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}"/applications/"${SG_pkg[$x]}" -s /software/services/"${SG_pkg[$x]}"
       for (( i=0; i<${SG_VIP_count[x]}; i++ )); do
               litp create -t vip   -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}"/ipaddresses/t1_ip6${i} -o ipaddress="${traf1_vip_ipv6[$vip_count]}" network_name=traffic1
                vip_count=($vip_count+1)
        done
done


# Add Packages & REPO 
litp create -t yum-repository -p /software/items/yum_osHA_repo -o name="osHA" base_url="http://"${ms_host}"/6/os/x86_64/HighAvailability"
litp inherit -s /software/items/yum_osHA_repo -p /deployments/d1/clusters/c1/nodes/n1/items/yum_osHA_repo
litp inherit -s /software/items/yum_osHA_repo -p /deployments/d1/clusters/c1/nodes/n2/items/yum_osHA_repo

litp create -t package -p /software/items/openjdk     -o name=java-1.7.0-openjdk
litp create -t package -p /software/items/cups-libs   -o name=cups-libs   version=1.4.2  release=67.el6_3 
litp create -t package -p /software/items/httpd-tools -o name=httpd-tools version=2.2.15 release=39.el6
litp inherit -p /ms/items/java -s /software/items/openjdk
for (( i=0; i<${#node_sysname[@]}; i++ )); do
#    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/java        -s /software/items/openjdk
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/httpd-tools -s /software/items/httpd-tools
#    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/cups-libs   -s /software/items/cups-libs
done;

# Update packages  LITPCDS-7747 
litp update -p /software/items/cups-libs -o epoch=1
litp update -p /software/items/httpd -o epoch=0
litp update -p /software/items/luci -o epoch=0
litp update -p /software/items/cups -o epoch=1


litp inherit -p /deployments/d1/clusters/c1/services/SG_luci/filesystems/fs1 -s /deployments/d1/clusters/c1/storage_profile/sp2/volume_groups/vg_vxvm_0/file_systems/VxVMVG2FS0
litp inherit -p /deployments/d1/clusters/c1/services/SG_luci/filesystems/fs2 -s /deployments/d1/clusters/c1/storage_profile/sp2/volume_groups/vg_vxvm_1/file_systems/VxVMVG2FS1

# Log Rotate

litp create -t logrotate-rule-config -p /deployments/d1/clusters/c1/nodes/n2/configs/logrotate
litp create -t logrotate-rule -p /deployments/d1/clusters/c1/nodes/n2/configs/logrotate/rules/exampleservice -o name="exampleservice" path="/var/log/exampleservice/exampleservice.log" missingok=true ifempty=true rotate=4 copytruncate=true
litp create -t logrotate-rule -p /deployments/d1/clusters/c1/nodes/n2/configs/logrotate/rules/exampleservice_tasks -o name="exampleservice_tasks" path="/var/log/exampleservice/tasks/*.log" copytruncate=true rotate=0 missingok=true ifempty=true compress=false create=false


litp create -t logrotate-rule-config -p /ms/configs/logrotate
litp create -t logrotate-rule -p /ms/configs/logrotate/rules/exampleservice -o name="exampleservice" path="/var/log/exampleservice/exampleservice.log" missingok=true ifempty=true rotate=4 copytruncate=true
litp create -t logrotate-rule -p /ms/configs/logrotate/rules/exampleservice_tasks -o name="exampleservice_tasks" path="/var/log/exampleservice/tasks/*.log" copytruncate=true rotate=0 missingok=true ifempty=true compress=false create=false



# Sentinel
litp create  -t package -p /software/items/sentinel    -o name=EXTRlitpsentinellicensemanager_CXP9031488
litp inherit            -p /ms/items/sentinel                                     -s /software/items/sentinel
litp create  -t service -p /ms/services/sentinel       -o service_name=sentinel
litp create  -t service -p /software/services/sentinel -o service_name=sentinel
litp inherit            -p /software/services/sentinel/packages/sentinel          -s /software/items/sentinel
litp inherit            -p /deployments/d1/clusters/c1/nodes/n1/services/sentinel -s /software/services/sentinel

litp create_plan
