#!/bin/bash
#
# Sample LITP multi-blade deployment (SAN version)
#
# Usage:
#   ST_Deployment_15.sh <CLUSTER_SPEC_FILE>
#

if [ "$#" -lt 1 ]; then
    echo -e "Usage:\n  $0 <CLUSTER_SPEC_FILE>" >&2
    exit 1
fi

cluster_file="$1"
source "$cluster_file"

set -x
litp update -p /litp/logging -o force_debug=true
litpcrypt set key-for-root root "${nodes_ilo_password}"
litpcrypt set key-for-sfs support support

litp create  -p /software/profiles/os_prof1  -t os-profile  -o name=os-profile1 path=/var/www/html/6/os/x86_64/
litp create  -p /deployments/d1              -t deployment
litp create  -p /deployments/d1/clusters/c1  -t vcs-cluster -o cluster_type=vcs low_prio_net=mgmt llt_nets=heartbeat1,heartbeat2 cluster_id="${vcs_cluster_id}"
litp create  -p /infrastructure/systems/sys1 -t blade       -o system_name="${ms_sysname}"

# Add NTP alias with alias
litp create -t ntp-service -p /software/items/ntp1
litp create -t alias-node-config -p /ms/configs/alias_config
for (( i=0; i<2; i++ )); do
        litp create -t alias -p /ms/configs/alias_config/aliases/ntp_alias$(($i+1)) -o alias_names=ntpAliasName$(($i+1)) address="${ntp_ip[$i+1]}"
        litp create -t ntp-server -p /software/items/ntp1/servers/server$(($i+1)) -o server=ntpAliasName$(($i+1))
done

litp update  -p /ms                    -o hostname="${ms_host}"
litp create  -p /ms/services/cobbler -o pxe_boot_timeout=300   -t cobbler-service
litp inherit -p /ms/system             -s /infrastructure/systems/sys1
litp inherit -p /ms/items/ntp          -s /software/items/ntp1

# Create storage volume group 1 LVM
litp create -t storage-profile -p /infrastructure/storage/storage_profiles/profile_1 
litp create -t volume-group    -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1                      -o volume_group_name=vg_root
litp create -t physical-device -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/pd1 -o device_name=hd0_1

litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/root                         -t file-system     -o type=ext4 mount_point=/                size=8G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/swap                         -t file-system     -o type=swap mount_point=swap             size=2G


# Setup node disks, and node ilo's
for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp create -t blade -p /infrastructure/systems/sys$(($i+2))               -o system_name="${node_sysname[$i]}"
    litp create -t disk  -p /infrastructure/systems/sys$(($i+2))/disks/disk0_1 -o name=hd0_1 size=28G bootable=true  uuid="${node_disk1_uuid[$i]}"
    litp create -t bmc   -p /infrastructure/systems/sys$(($i+2))/bmc           -o ipaddress="${node_bmc_ip[$i]}" username=root password_key=key-for-root
done

# Routes 
litp create -t route   -p /infrastructure/networking/routes/route1            -o subnet="0.0.0.0/0"          gateway="${nodes_gateway}"

# Networks
litp create -t network -p /infrastructure/networking/networks/mgmt            -o name=mgmt      subnet="${nodes_subnet}"    litp_management=true
litp create -t network -p /infrastructure/networking/networks/heartbeat1      -o name=heartbeat1
litp create -t network -p /infrastructure/networking/networks/heartbeat2      -o name=heartbeat2

# Interfaces
litp create -t eth  -p /ms/network_interfaces/if0       -o device_name=eth0 macaddress="${ms_eth0_mac}" network_name=mgmt     ipaddress="${ms_ip}"    
#litp create -t vlan -p /ms/network_interfaces/if0_vlan0 -o device_name=eth0.898                         network_name=mgmt     ipaddress="${ms_ip}"      ipv6address="${ms_ipv6_00}"
#litp create -t eth  -p /ms/network_interfaces/if1       -o device_name=eth1 macaddress="${ms_eth1_mac}" network_name=data     ipaddress="${ms_ip_ext}"  ipv6address="${ms_ipv6_01}"

litp inherit -p /ms/routes/route1 -s /infrastructure/networking/routes/route1
for (( i=0; i<${#node_sysname[@]}; i++ )); do
    # Node misc
        litp create  -p /deployments/d1/clusters/c1/nodes/n$(($i+1))                    -t node                                       -o hostname="${node_hostname[$i]}"
        litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/system             -s /infrastructure/systems/sys$(($i+2))
        litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/os                 -s /software/profiles/os_prof1
        litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/storage_profile    -s /infrastructure/storage/storage_profiles/profile_1
        litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/ntp1         -s /software/items/ntp1
    # Node Routes
        litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/route1      -s /infrastructure/networking/routes/route1
done
# Heterogeneous network set up - LITPCDS-4886 define a single IP resource on different NICs on different nodes across the cluster
# Network Node 1
#    litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/mybr0       -o device_name=br0  forwarding_delay=0               network_name=mgmt      ipaddress="${node_ip[0]}"      ipv6address="${ipv6_00[0]}" 
    litp create -t  eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if0           -o device_name=eth0 macaddress="${node_eth0_mac[0]}" network_name=mgmt ipaddress="${node_ip[0]}"  
    litp create -t  eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if2           -o device_name=eth2 macaddress="${node_eth2_mac[0]}" network_name=heartbeat1    
    litp create -t  eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if3           -o device_name=eth3 macaddress="${node_eth3_mac[0]}" network_name=heartbeat2    

#    litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/mybr0       -o device_name=br0  forwarding_delay=0               network_name=mgmt      ipaddress="${node_ip[1]}"      ipv6address="${ipv6_00[1]}"
    litp create -t  eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if0           -o device_name=eth0 macaddress="${node_eth0_mac[1]}" network_name=mgmt ipaddress="${node_ip[1]}"  
    litp create -t  eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if2           -o device_name=eth2 macaddress="${node_eth2_mac[1]}" network_name=heartbeat1
    litp create -t  eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if3           -o device_name=eth3 macaddress="${node_eth3_mac[1]}" network_name=heartbeat2


# VCS Service Groups
#Create a SW Package
litp create -t package -p /software/items/ricci -o name=ricci release=75.el6 version=0.16.2
litp create -t package -p /software/items/httpd -o name=httpd release=39.el6 version=2.2.15
litp create -t package -p /software/items/luci -o name=luci release=63.el6 version=0.26.0
litp create -t package -p /software/items/dovecot -o name=dovecot release=7.el6_5.1 version=2.0.9 epoch=1
litp create -t package -p /software/items/cups -o name=cups release=67.el6 version=1.4.2 epoch=1

# Pin dependent packages to support version pinning of LSB Packages above
litp create -t package -p /software/items/httpd-tools -o name=httpd-tools version=2.2.15 release=39.el6
litp create -t package -p /software/items/cups-libs -o name=cups-libs version=1.4.2 release=67.el6 epoch=1
litp create -t package -p /software/items/openjdk     -o name=java-1.7.0-openjdk

litp inherit -p /ms/items/java -s /software/items/openjdk


# Service Group - Service
x=0
SG_pkg[x]="httpd";      SG_VIP_count[x]=$[0*2]; SG_active[x]=2; SG_standby[x]=0 status_interval[x]=20   status_timeout[x]=30    restart_limit[x]=30     startup_retry_limit[x]=40    node_list[x]="n2,n1" dependency_list[x]="" x=$[$x+1]


vip_count=10
for (( x=0; x<${#SG_pkg[@]}; x++ )); do
litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}" -o active="${SG_active[$x]}" standby="${SG_standby[$x]}" name=vcs_"${SG_pkg[$x]}" online_timeout=45 node_list="${node_list[$x]}" dependency_list="${dependency_list[$x]}"
litp create -t ha-service-config     -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}"/ha_configs/conf1 -o status_interval="${status_interval[$x]}" status_timeout="${status_timeout[$x]}" restart_limit="${restart_limit[$x]}" startup_retry_limit="${startup_retry_limit[$x]}"
litp create -t service  -p /software/services/"${SG_pkg[$x]}"   -o service_name="${SG_pkg[$x]}"
litp inherit            -p /software/services/"${SG_pkg[$x]}"/packages/pkg1 -s /software/items/"${SG_pkg[$x]}"
litp inherit            -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}"/applications/s1_"${SG_pkg[$x]}" -s /software/services/"${SG_pkg[$x]}"
        for (( i=0; i<${SG_VIP_count[x]}; i++ )); do
                litp create -t vip   -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}"/ipaddresses/t1_ip${i} -o ipaddress="${traf1_vip[$vip_count]}" network_name=traffic1
                litp create -t vip   -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}"/ipaddresses/t2_ip${i} -o ipaddress="${traf2_vip_ipv6[$vip_count]}" network_name=traffic2
                vip_count=($vip_count+1)
        done
done

litp create_plan

#https://team.ammeon.com/confluence/display/LITPExt/BVPS+Installation+Procedure+Sprint+25
#Step 4
#MAC address must be all lower case.....
#/etc/udev/rules.d/70-persistent-net.rules
#Node1 - DangerZone1
#SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="2c:76:8a:55:45:40", ATTR{type}=="1", KERNEL=="eth*", NAME:="eth0"
#SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="2c:76:8a:55:45:41", ATTR{type}=="1", KERNEL=="eth*", NAME:="eth1"
#SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="2c:76:8a:55:45:42", ATTR{type}=="1", KERNEL=="eth*", NAME:="eth2"
#SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="2c:76:8a:55:45:43", ATTR{type}=="1", KERNEL=="eth*", NAME:="eth3"
#SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="f4:ce:46:a9:df:fc", ATTR{type}=="1", KERNEL=="eth*", NAME:="eth4"
#SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="f4:ce:46:a9:df:fd", ATTR{type}=="1", KERNEL=="eth*", NAME:="eth5"
#SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="f4:ce:46:a9:df:fe", ATTR{type}=="1", KERNEL=="eth*", NAME:="eth6"
#SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="f4:ce:46:a9:df:ff", ATTR{type}=="1", KERNEL=="eth*", NAME:="eth7" 
#SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="80:c1:6e:07:d5:50", ATTR{type}=="1", KERNEL=="eth*", NAME:="eth8"
#SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="80:c1:6e:07:d5:54", ATTR{type}=="1", KERNEL=="eth*", NAME:="eth9"

#Node2 - Phrasing2
#SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="2c:76:8a:55:15:3c", ATTR{type}=="1", KERNEL=="eth*", NAME="eth0"
#SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="2c:76:8a:55:15:3d", ATTR{type}=="1", KERNEL=="eth*", NAME="eth1"
#SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="2c:76:8a:55:15:3e", ATTR{type}=="1", KERNEL=="eth*", NAME="eth2"
#SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="2c:76:8a:55:15:3f", ATTR{type}=="1", KERNEL=="eth*", NAME="eth3"
#SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="f4:ce:46:a9:e3:40", ATTR{type}=="1", KERNEL=="eth*", NAME="eth4"
#SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="f4:ce:46:a9:e3:41", ATTR{type}=="1", KERNEL=="eth*", NAME="eth5"
#SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="f4:ce:46:a9:e3:42", ATTR{type}=="1", KERNEL=="eth*", NAME="eth6"
#SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="f4:ce:46:a9:e3:43", ATTR{type}=="1", KERNEL=="eth*", NAME="eth7"
#SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="80:c1:6e:07:e5:30", ATTR{type}=="1", KERNEL=="eth*", NAME="eth8"
#SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="80:c1:6e:07:e5:34", ATTR{type}=="1", KERNEL=="eth*", NAME="eth9"
