#!/bin/bash
#
# Sample LITP multi-blade deployment (SAN version)
#
# Usage:
#   ST_Deployment_14.sh <CLUSTER_SPEC_FILE>
#

function check_cs_initial_online_tasks {
	# Added as part of LITPCDS-11240
	# Checks that correct number of tasks are been created cs_initial_online is been set to on and off
        cs_initial_online_on="litp update -p $1 -o cs_initial_online=on"
        cs_initial_online_off="litp update -p $1 -o cs_initial_online=off"
        sg_count=$(($(litp show -p ${1}services -l | wc -l) -1))
        $cs_initial_online_off
        litp create_plan
        task_states=$(litp show_plan -a | grep Tasks:)
        tasks=${task_states%%|*}
        tasks_count_off=${tasks##*:}

        $cs_initial_online_on
        litp create_plan
        task_states=$(litp show_plan -a | grep Tasks:)
        tasks=${task_states%%|*}
        tasks_count_on=${tasks##*:}
	# compare difference in number of tasks with the number of SG present.
	if [ "$(($tasks_count_on - $tasks_count_off))" == $sg_count ]        
                then echo "count of online SG tasks is correct"
        else
                echo "count of online SG tasks is Incorrect. Exit for investigation"
                exit
        fi
}


if [ "$#" -lt 1 ]; then
    echo -e "Usage:\n  $0 <CLUSTER_SPEC_FILE>" >&2
    exit 1
fi

cluster_file="$1"
source "$cluster_file"

set -x
# Plugin Install
for (( i=0; i<${#rpms[@]}; i++ )); do
    # import plugin into litp repo
    litp import "/tmp/${rpms[$i]}" litp
    # install plugin
    expect /tmp/root_yum_install_pkg.exp "${ms_host}" "${rpms[$i]%%-*}"
done

### Import ENM ISO 
#expect /tmp/root_import_iso.exp "${ms_host}" "${enm_iso}"

# Install plugin for LITPCDS-10650
expect /tmp/root_run_script.exp "${ms_host}" /tmp/litpcds10650_plugin_install.sh

litp update -p /litp/logging -o force_debug=true
litpcrypt set key-for-root root "${nodes_ilo_password}"
litpcrypt set key-for-sfs support support

# Mount the ENM iso

litp create  -p /software/profiles/os_prof1  -t os-profile  -o name=os-profile1 path=/var/www/html/6/os/x86_64/
litp create  -p /deployments/d1              -t deployment
litp create  -p /deployments/d1/clusters/c1  -t vcs-cluster -o cluster_type=vcs low_prio_net=mgmt llt_nets=heartbeat1,heartbeat2 cluster_id="${vcs_cluster_id}" app_agent_num_threads=20 default_nic_monitor=mii
litp create  -p /infrastructure/systems/sys1 -t blade       -o system_name="${ms_sysname}"

# Add NTP alias with alias
litp create -t ntp-service -p /software/items/ntp1
litp create -t alias-node-config -p /ms/configs/alias_config
for (( i=0; i<2; i++ )); do
        litp create -t alias -p /ms/configs/alias_config/aliases/ntp_alias$(($i+1)) -o alias_names=ntpAliasName$(($i+1)) address="${ntp_ip[$i+1]}"
        litp create -t ntp-server -p /software/items/ntp1/servers/server$(($i+1)) -o server=ntpAliasName$(($i+1))
done

# Added for MS Scalability
for (( i=0; i<40; i++ )); do
        litp create -p /ms/configs/alias_config/aliases/test_alias$(($i+1)) -t alias -o alias_names="testalias$(($i+1))" address="${ntp_ip[1]}"
        litp create -p /ms/configs/alias_config/aliases/test_alias000$(($i+2)) -t alias -o alias_names="testalias00$(($i+2))" address="${ntp_ip[2]}"
done


litp update  -p /ms                    -o hostname="${ms_host}"
litp create  -p /ms/services/cobbler   -t cobbler-service -o pxe_boot_timeout=777
litp inherit -p /ms/system             -s /infrastructure/systems/sys1
litp inherit -p /ms/items/ntp          -s /software/items/ntp1

# Setup MS disk and storage_profile with FS
litp create  -t disk                -p /infrastructure/systems/sys1/disks/d1 -o name="hd1" size=558G bootable="true" uuid=$ms_disk_uuid
litp create  -t storage-profile     -p /infrastructure/storage/storage_profiles/sp1
litp create  -t volume-group        -p /infrastructure/storage/storage_profiles/sp1/volume_groups/vg1 -o volume_group_name="vg_root"
litp create  -t file-system         -p /infrastructure/storage/storage_profiles/sp1/volume_groups/vg1/file_systems/fs1 -o type="ext4" mount_point="/mount_ms_fs1" size="100M" snap_size="5" snap_external="false"
litp create  -t file-system         -p /infrastructure/storage/storage_profiles/sp1/volume_groups/vg1/file_systems/fs2 -o type="ext4" mount_point="/mount_ms_fs2" size="100M" snap_size="0" snap_external="false"
litp create  -t file-system         -p /infrastructure/storage/storage_profiles/sp1/volume_groups/vg1/file_systems/fs3 -o type="ext4" size="100M" snap_size="5" snap_external="false"
litp create  -t file-system         -p /infrastructure/storage/storage_profiles/sp1/volume_groups/vg1/file_systems/fs4 -o type="ext4" mount_point="/mount_ms_fs4" size="100M" snap_size="5" snap_external="false"
litp create  -t physical-device     -p /infrastructure/storage/storage_profiles/sp1/volume_groups/vg1/physical_devices/pd1 -o device_name="hd1"

# Model KS filesystems
litp create -t file-system -p /infrastructure/storage/storage_profiles/sp1/volume_groups/vg1/file_systems/root -o type="ext4" mount_point=/ size=15G snap_size=100
litp create -t file-system -p /infrastructure/storage/storage_profiles/sp1/volume_groups/vg1/file_systems/home -o type="ext4" mount_point=/home size=6G snap_size=100 backup_snap_size=100
litp create -t file-system -p /infrastructure/storage/storage_profiles/sp1/volume_groups/vg1/file_systems/var_log -o type="ext4" mount_point=/var/log size=20G snap_size=0 backup_snap_size=100
litp create -t file-system -p /infrastructure/storage/storage_profiles/sp1/volume_groups/vg1/file_systems/var_www -o type="ext4" mount_point=/var/www size=70G snap_size=100 backup_snap_size=100

litp inherit -p /ms/storage_profile -s /infrastructure/storage/storage_profiles/sp1

# Create storage volume group 1 LVM
litp create -t storage-profile -p /infrastructure/storage/storage_profiles/profile_1 
litp create -t volume-group    -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1                      -o volume_group_name=vg_root
litp create -t physical-device -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/pd1 -o device_name=hd0_1

litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/root                         -t file-system     -o type=ext4 mount_point=/                size=10G snap_size=50
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/swap                         -t file-system     -o type=swap mount_point=swap             size=2G snap_size=50
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/LVM_VG1_FS0 -t file-system -o type=ext4 mount_point=/LVM_mp_VG1_FS0 size=200M snap_size=10 backup_snap_size=20
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/LVM_VG1_FS1 -t file-system -o type=ext4 mount_point=/LVM_mp_VG1_FS1 size=100M snap_size=10 backup_snap_size=10
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/LVM_VG1_FS2 -t file-system -o type=ext4 size=100M snap_size=10 backup_snap_size=25
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/LVM_VG1_FS3 -t file-system -o type=ext4 mount_point=/LVM_mp_VG1_FS3 size=100M snap_size=10

# Setup node disks, and node ilo's
for (( i=0; i<${#node_sysname[@]}; i++ )); do
   litp create -t blade -p /infrastructure/systems/sys$(($i+2))               -o system_name="${node_sysname[$i]}"
    litp create -t disk  -p /infrastructure/systems/sys$(($i+2))/disks/disk0_1 -o name=hd0_1 size=38G bootable=true  uuid="${node_disk1_uuid[$i]}"
    litp create -t bmc   -p /infrastructure/systems/sys$(($i+2))/bmc           -o ipaddress="${node_bmc_ip[$i]}" username=root password_key=key-for-root
done

# Routes 
litp create -t route   -p /infrastructure/networking/routes/route1            -o subnet="0.0.0.0/0"          gateway="${nodes_gateway}"
litp create -t route   -p /infrastructure/networking/routes/route_t1          -o subnet="${traf1gw_subnet}"  gateway="${traf1_ip[1]}"
litp create -t route   -p /infrastructure/networking/routes/route_t2          -o subnet="${traf2gw_subnet}"  gateway="${traf2_ip[1]}"
litp create -t route6  -p /infrastructure/networking/routes/route1_ipv6       -o subnet="${ipv6_898_subnet}" gateway="${ipv6_898_gw}"
litp create -t route6  -p /infrastructure/networking/routes/route2_ipv6       -o subnet=::/0                 gateway="${ipv6_898_gw}"

# Networks
litp create -t network -p /infrastructure/networking/networks/mgmt            -o name=mgmt      subnet="${nodes_subnet}"    litp_management=true
litp create -t network -p /infrastructure/networking/networks/net834          -o name=net834    subnet="${nodes_subnet_ext}"
litp create -t network -p /infrastructure/networking/networks/net837          -o name=net837    subnet="${net837_subnet}"
litp create -t network -p /infrastructure/networking/networks/net835          -o name=net835    subnet="${net835_subnet}"
litp create -t network -p /infrastructure/networking/networks/heartbeat1      -o name=heartbeat1
litp create -t network -p /infrastructure/networking/networks/heartbeat2      -o name=heartbeat2
litp create -t network -p /infrastructure/networking/networks/traffic1        -o name=traffic1  subnet="${traf1_subnet}"
litp create -t network -p /infrastructure/networking/networks/traffic2        -o name=traffic2  subnet="${traf2_subnet}"
litp create -t network -p /infrastructure/networking/networks/net1vm          -o name=net1vm    subnet="$VM_net1vm_subnet"
litp create -t network -p /infrastructure/networking/networks/net2vm          -o name=net2vm    subnet="$VM_net2vm_subnet"
# Interfaces
litp create -t eth  -p /ms/network_interfaces/if0       -o device_name=eth0 macaddress="${ms_eth0_mac}"
litp create -t vlan -p /ms/network_interfaces/if0_vlan0 -o device_name=eth0.898 bridge=br0
litp create -t bridge -p /ms/network_interfaces/br0 -o network_name=mgmt ipaddress="${ms_ip}" ipv6address="${ms_ipv6_00}" device_name=br0 multicast_snooping=0

#litp create -t vlan -p /ms/network_interfaces/if0_vip1  -o device_name=eth0.100 network_name=net1vm ipaddress="${VM_net1vm_ip[0]}"
#litp create -t vlan -p /ms/network_interfaces/if0_vip2  -o device_name=eth0.200 network_name=net2vm ipaddress="${VM_net2vm_ip[0]}"
litp inherit -p /ms/routes/route1 -s /infrastructure/networking/routes/route1
litp inherit -p /ms/routes/default_ipv6 -s /infrastructure/networking/routes/route2_ipv6

for (( i=0; i<${#node_sysname[@]}; i++ )); do
    # Node misc
        litp create  -p /deployments/d1/clusters/c1/nodes/n$(($i+1))                    -t node                                       -o hostname="${node_hostname[$i]}"
        litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/system             -s /infrastructure/systems/sys$(($i+2))
        litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/os                 -s /software/profiles/os_prof1
        litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/storage_profile    -s /infrastructure/storage/storage_profiles/profile_1
        litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/ntp1         -s /software/items/ntp1
    # Node Routes
        litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/route1      -s /infrastructure/networking/routes/route1
        litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/traffic1_gw -s /infrastructure/networking/routes/route_t1 -o subnet="${traf1gw_subnet}"   gateway="${traf1_ip[$i]}"
        litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/traffic2_gw -s /infrastructure/networking/routes/route_t2 -o subnet="${traf2gw_subnet}"   gateway="${traf2_ip[$i]}" 
        litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/default_ipv6 -s /infrastructure/networking/routes/route2_ipv6
done
# Heterogeneous network set up - LITPCDS-4886 define a single IP resource on different NICs on different nodes across the cluster
# Network Node 1
    litp create -t bond -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/b0 		 -o device_name='bond0' mode=1 arp_interval=1200 arp_ip_target=10.44.235.1 arp_validate=active arp_all_targets=all bridge=br898
    litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/b0_834	 -o device_name=bond0.834 bridge=br834
    litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/b0_835        -o device_name=bond0.835 bridge=br835
    litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/b0_837        -o device_name=bond0.837 bridge=br837
    litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/b0_vip1	 -o device_name=bond0.151 bridge=br_vip1
    litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/b0_vip2	 -o device_name=bond0.152 bridge=br_vip2
    litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/mybr0       -o device_name=br898   forwarding_delay=0            network_name=mgmt      ipaddress="${net898_ip[0]}"  ipv6address="${ipv6_00[0]}" 
    litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/mybr1       -o device_name=br834   forwarding_delay=0            network_name=net834    ipaddress="${net834_ip[0]}"  ipv6address="${ipv6_01[0]}" multicast_snooping=0
    litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/mybr2       -o device_name=br837   forwarding_delay=0            network_name=net837    ipaddress="${net837_ip[0]}"
    litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/mybr3       -o device_name=br_vip1 forwarding_delay=0            network_name=net1vm    ipaddress="${VM_net1vm_ip[0]}" multicast_snooping=0
    litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/mybr4       -o device_name=br_vip2 forwarding_delay=0            network_name=net2vm    ipaddress="${VM_net2vm_ip[0]}" 
    litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/mybr5       -o device_name=br835   forwarding_delay=0            network_name=net835
    litp create -t  eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if0           -o device_name=eth0 macaddress="${node_eth0_mac[0]}" master=bond0 
# Commenting out if1 as appears to be hardware problem (TORF-191582)
    # litp create -t  eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if1           -o device_name=eth1 macaddress="${node_eth1_mac[0]}" master=bond0
    litp create -t  eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if2           -o device_name=eth2 macaddress="${node_eth2_mac[0]}" network_name=heartbeat1
    litp create -t  eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if3           -o device_name=eth3 macaddress="${node_eth3_mac[0]}" network_name=heartbeat2
    litp create -t  eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if4           -o device_name=eth4 macaddress="${node_eth4_mac[0]}" network_name=traffic1  ipaddress="${traf1_ip[0]}"   ipv6address="${ipv6_04[0]}"
    litp create -t  eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if5           -o device_name=eth5 macaddress="${node_eth5_mac[0]}" network_name=traffic2  ipaddress="${traf2_ip[0]}"   ipv6address="${ipv6_05[0]}"

# Network Node 2
    litp create -t bond -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/b0 		 -o device_name='bond0' mode=1 miimon=100 bridge=br898 
    litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/b0_834	 -o device_name=bond0.834 bridge=br834
    litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/b0_835        -o device_name=bond0.835 bridge=br835
    litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/b0_837        -o device_name=bond0.837 bridge=br837
    litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/b0_vip1	 -o device_name=bond0.151 bridge=br_vip1
    litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/b0_vip2	 -o device_name=bond0.152 bridge=br_vip2
    litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/mybr0       -o device_name=br898   forwarding_delay=0            network_name=mgmt      ipaddress="${net898_ip[1]}"  ipv6address="${ipv6_00[1]}"
    litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/mybr1       -o device_name=br834   forwarding_delay=0            network_name=net834    ipaddress="${net834_ip[1]}"  ipv6address="${ipv6_01[1]}" multicast_snooping=0
    litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/mybr2       -o device_name=br837   forwarding_delay=0            network_name=net837    ipaddress="${net837_ip[1]}"
    litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/mybr3       -o device_name=br_vip1 forwarding_delay=0            network_name=net1vm    ipaddress="${VM_net1vm_ip[1]}"      
    litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/mybr4       -o device_name=br_vip2 forwarding_delay=0            network_name=net2vm    ipaddress="${VM_net2vm_ip[1]}"  multicast_snooping=0
    litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/mybr5       -o device_name=br835   forwarding_delay=0            network_name=net835
    litp create -t  eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if6           -o device_name=eth6 macaddress="${node_eth6_mac[1]}" master=bond0
    litp create -t  eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if1           -o device_name=eth1 macaddress="${node_eth1_mac[1]}" master=bond0
    litp create -t  eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if2           -o device_name=eth2 macaddress="${node_eth2_mac[1]}" network_name=heartbeat1
    litp create -t  eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if3           -o device_name=eth3 macaddress="${node_eth3_mac[1]}" network_name=heartbeat2
    litp create -t  eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if4           -o device_name=eth4 macaddress="${node_eth4_mac[1]}" network_name=traffic1  ipaddress="${traf1_ip[1]}"   ipv6address="${ipv6_04[1]}"
    litp create -t  eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if5           -o device_name=eth5 macaddress="${node_eth5_mac[1]}" network_name=traffic2  ipaddress="${traf2_ip[1]}"   ipv6address="${ipv6_05[1]}"

# Alias
litp create -t alias-cluster-config -p /deployments/d1/clusters/c1/configs/alias_config
litp create -t alias                -p /deployments/d1/clusters/c1/configs/alias_config/aliases/sfs_alias -o alias_names="sfsAlias","nasAlias" address="10.44.86.231"

litp create -t alias-node-config    -p /deployments/d1/clusters/c1/nodes/n2/configs/alias_config
litp create -t alias                -p /deployments/d1/clusters/c1/nodes/n2/configs/alias_config/aliases/fwServer -o alias_names="fwServer","dot30","ciNode" address="10.44.86.30"

# Firewall's
litp create -t firewall-node-config -p /ms/configs/fw_config
litp create -t firewall-rule 	    -p /ms/configs/fw_config/rules/fw_icmp   -o name="100 icmp" proto="icmp"
litp create -t firewall-rule 	    -p /ms/configs/fw_config/rules/fw_icmpv6 -o name="101 icmpv6" proto="ipv6-icmp" provider=ip6tables
litp create -t firewall-rule        -p /ms/configs/fw_config/rules/fw_nfstcp -o 'name=001 nfstcp' dport=53,111,2049,4001 proto=tcp
litp create -t firewall-rule        -p /ms/configs/fw_config/rules/fw_nfsudp -o 'name=011 nfsudp' dport=53,111,2049,4001 proto=udp
litp create -p /ms/configs/fw_config/rules/fw_hyperic_server_in -t firewall-rule -o action=accept chain=INPUT dport=57004,57005 'name=112 hyperic tcp agent to server ports' proto=tcp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_hyperic_server_out -t firewall-rule -o action=accept chain=OUTPUT dport=57006 'name=113 hyperic tcp server to agent port' proto=tcp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_sfsudp -t firewall-rule -o action=accept dport=111,2049,4011,4001 'name=013 sfsudp' proto=udp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_sfstcp -t firewall-rule -o action=accept dport=111,2049,4011,4001 'name=012 sfstcp' proto=tcp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_vmmonitord -t firewall-rule -o action=accept dport=12987 'name=018 vmmonitord' proto=tcp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_dns -t firewall-rule -o action=accept dport=53 'name=021 DNS udp' proto=udp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_brs -t firewall-rule -o action=accept dport=1556,2821,4032,13724,13782 'name=022 backuprestore tcp' proto=tcp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_ntp -t firewall-rule -o action=accept dport=123 'name=029 NTP udp' proto=tcp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_dhcp_tcp -t firewall-rule -o action=accept dport=546,547,647,847 'name=030 DHCP tcp' proto=tcp
litp create -p /ms/configs/fw_config/rules/fw_dhcp_udp -t firewall-rule -o action=accept dport=546,547,647,847 'name=031 DHCP udp' proto=udp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_cobbler -t firewall-rule -o action=accept dport=25150,25151 'name=032 cobbler' proto=udp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_cobbler_tcp -t firewall-rule -o action=accept dport=25150,25151 'name=033 cobbler' proto=tcp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_nexus -t firewall-rule -o action=accept dport=8080,8443 'name=034 nexus tcp' proto=tcp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_lserv -t firewall-rule -o action=accept dport=5093 'name=035 lserv' proto=udp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_rpcbind -t firewall-rule -o action=accept dport=676 'name=036 rpcbind' proto=udp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_loop_back -t firewall-rule -o action=accept iniface=lo 'name=02 loop back' proto=all
litp create -p /ms/configs/fw_config/rules/fw_http_allow_int -t firewall-rule -o action=accept provider=iptables dport=80 'name=106 allow http internal' proto=tcp state=NEW source=10.247.244.0/22
litp create -p /ms/configs/fw_config/rules/fw_http_allow_stor -t firewall-rule -o action=accept dport=80 'name=102 allow http storage' proto=tcp state=NEW provider=iptables source=10.140.2.0/24
litp create -p /ms/configs/fw_config/rules/fw_http_allow_serv -t firewall-rule -o action=accept dport=80 'name=103 allow http services' proto=tcp state=NEW provider=iptables source=10.151.9.128/26
litp create -p /ms/configs/fw_config/rules/fw_http_allow_bkp -t firewall-rule -o action=accept dport=80 'name=104 allow http backup' proto=tcp state=NEW provider=iptables source=10.151.24.0/23
litp create -p /ms/configs/fw_config/rules/fw_http_block -t firewall-rule -o action=accept dport=80 'name=105 drop http' proto=tcp state=NEW provider=iptables

for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp create -t firewall-node-config 	-p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config
    litp create -t firewall-rule 		-p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config/rules/fw_icmpv6 	-o name="101 icmpv6" proto="ipv6-icmp" provider=ip6tables
    litp create -t firewall-rule 		-p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config/rules/fw_icmp 	-o name="100 icmp"   proto="icmp"
    litp create -t firewall-rule 		-p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config/rules/fw_nfsudp 	-o 'name=011 nfsudp' dport=53,111,662,756,875,1110,2020,2049,4001,4045 proto=udp
    litp create -t firewall-rule 		-p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config/rules/fw_nfstcp 	-o 'name=001 nfstcp' dport=53,111,662,756,875,1110,2020,2049,4001,4045,12987 proto=tcp
done

#DNS
litp create -t dns-client -p /ms/configs/dns_client -o search=ammeonvpn.com,exampleone.com,exampletwo.com
litp create -t nameserver -p /ms/configs/dns_client/nameservers/my_name_server_A -o ipaddress=fdde:4d7e:d471::834:4:4 position=1
litp create -t nameserver -p /ms/configs/dns_client/nameservers/my_name_server_B -o ipaddress=10.10.10.1 position=2
litp create -t nameserver -p /ms/configs/dns_client/nameservers/my_name_server_C -o ipaddress=10.44.86.4 position=3

litp create -t dns-client -p /deployments/d1/clusters/c1/nodes/n1/configs/dns_client -o search=ammeonvpn.com,exampleone.com,exampletwo.com
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n1/configs/dns_client/nameservers/my_name_server_A -o ipaddress=10.10.10.1 position=1
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n1/configs/dns_client/nameservers/my_name_server_B -o ipaddress=10.44.86.4 position=2
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n1/configs/dns_client/nameservers/my_name_server_C -o ipaddress=2001:4860:0:1001::68 position=3

litp create -t dns-client -p /deployments/d1/clusters/c1/nodes/n2/configs/dns_client -o search=ammeonvpn.com,exampleone.com,exampletwo.com
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n2/configs/dns_client/nameservers/my_name_server_A -o ipaddress=10.10.10.1 position=1
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n2/configs/dns_client/nameservers/my_name_server_B -o ipaddress=10.44.86.4 position=2
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n2/configs/dns_client/nameservers/my_name_server_C -o ipaddress=2001:4860:0:1001::68 position=3

#Sysparms  
litp create -t sysparam-node-config -p /ms/configs/mynodesysctl 
litp create -t sysparam -p /ms/configs/mynodesysctl/params/sysctl_MS01 -o key=net.ipv4.udp_mem                      value="24794401 33059201 49588801"
litp create -t sysparam -p /ms/configs/mynodesysctl/params/sysctl_MS02 -o key=net.ipv6.route.mtu_expires            value=599
litp create -t sysparam -p /ms/configs/mynodesysctl/params/sysctl_MS03 -o key=net.ipv6.conf.eth2.max_desync_factor  value=599
#litp create -t sysparam -p /ms/configs/mynodesysctl/params/sysctl30 -o key="vm.nr_hugepages" value="56412"
#litp create -t sysparam -p /ms/configs/mynodesysctl/params/sysctl31 -o key="vm.hugetlb_shm_group" value="400"
litp create -t sysparam -p /ms/configs/mynodesysctl/params/sysctl28 -o key="debug.kprobes-optimization" value="0"
litp create -t sysparam -p /ms/configs/mynodesysctl/params/sysctl29 -o key="net.core.rmem_default" value="650001"
litp create -t sysparam -p /ms/configs/mynodesysctl/params/sysctl26 -o key="net.core.wmem_max" value="830000"
litp create -t sysparam -p /ms/configs/mynodesysctl/params/sysctl27 -o key="net.core.wmem_default" value="645682"
litp create -t sysparam -p /ms/configs/mynodesysctl/params/sysctl24 -o key="net.core.rmem_max" value="6487482"
#litp create -t sysparam -p /ms/configs/mynodesysctl/params/sysctl25 -o key="vm.swappiness" value="7"
litp create -t sysparam -p /ms/configs/mynodesysctl/params/sysctl1 -o key="kernel.threads-max" value="4593222"
#litp create -t sysparam -p /ms/configs/mynodesysctl/params/sysctl23 -o key="vm.dirty_background_ratio" value="13"
litp create -t sysparam -p /ms/configs/mynodesysctl/params/sysctl32 -o key="net.ipv6.conf.default.autoconf" value="0"
litp create -t sysparam -p /ms/configs/mynodesysctl/params/sysctl33 -o key="net.ipv6.conf.default.accept_ra" value="0"
litp create -t sysparam -p /ms/configs/mynodesysctl/params/sysctl34 -o key="net.ipv6.conf.default.accept_ra_defrtr" value="0"
litp create -t sysparam -p /ms/configs/mynodesysctl/params/sysctl35 -o key="net.ipv6.conf.default.accept_ra_rtr_pref" value="0"
litp create -t sysparam -p /ms/configs/mynodesysctl/params/sysctl36 -o key="net.ipv6.conf.default.accept_ra_pinfo" value="0"
litp create -t sysparam -p /ms/configs/mynodesysctl/params/sysctl37 -o key="net.ipv6.conf.default.accept_source_route" value="0"
litp create -t sysparam -p /ms/configs/mynodesysctl/params/sysctl38 -o key="net.ipv6.conf.default.accept_redirects" value="0"
litp create -t sysparam -p /ms/configs/mynodesysctl/params/sysctl39 -o key="net.ipv6.conf.all.autoconf" value="0"
litp create -t sysparam -p /ms/configs/mynodesysctl/params/sysctl40 -o key="net.ipv6.conf.all.accept_ra" value="0"
litp create -t sysparam -p /ms/configs/mynodesysctl/params/sysctl41 -o key="net.ipv6.conf.all.accept_ra_defrtr" value="0"
litp create -t sysparam -p /ms/configs/mynodesysctl/params/sysctl42 -o key="net.ipv6.conf.all.accept_ra_rtr_pref" value="0"
litp create -t sysparam -p /ms/configs/mynodesysctl/params/sysctl43 -o key="net.ipv6.conf.all.accept_ra_pinfo" value="0"
litp create -t sysparam -p /ms/configs/mynodesysctl/params/sysctl44 -o key="net.ipv6.conf.all.accept_source_route" value="0"
litp create -t sysparam -p /ms/configs/mynodesysctl/params/sysctl45 -o key="net.ipv6.conf.all.accept_redirects" value="0"

#Adding network hosts for vm's
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/traf_vm100 -o network_name=net1vm ip="${VM_net1vm_ip[0]}" #10.46.150.100
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/traf_vm101 -o network_name=net1vm ip="${VM_net1vm_ip[1]}" #10.46.150.101
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/traf_vm102 -o network_name=net1vm ip="${VM_net1vm_ip[2]}" 
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/traf_vm103 -o network_name=net1vm ip="${VM_net1vm_ip[3]}"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/traf_vm104 -o network_name=net1vm ip="${VM_net1vm_ip[4]}"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/traf_vm105 -o network_name=net1vm ip="${VM_net1vm_ip[5]}"

litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/traf_vm200 -o network_name=net2vm ip="${VM_net2vm_ip[0]}" #10.46.150.200
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/traf_vm201 -o network_name=net2vm ip="${VM_net2vm_ip[1]}" #10.46.150.201
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/traf_vm202 -o network_name=net2vm ip="${VM_net2vm_ip[2]}" 
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/traf_vm203 -o network_name=net2vm ip="${VM_net2vm_ip[3]}" 
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/traf_vm204 -o network_name=net2vm ip="${VM_net2vm_ip[4]}" 
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/traf_vm205 -o network_name=net2vm ip="${VM_net2vm_ip[5]}"
# Log Rotate
for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp create -t logrotate-rule-config -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/logrotate
    litp create -t logrotate-rule        -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/logrotate/rules/exampleservice -o name="exampleservice" path="/var/log/exampleservice/exampleservice.log" missingok=true ifempty=true rotate=4 copytruncate=true
    litp create -t logrotate-rule        -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/logrotate/rules/exampleservice_tasks -o name="exampleservice_tasks" path="/var/log/exampleservice/tasks/*.log" copytruncate=true rotate=0 missingok=true ifempty=true compress=false create=false
    litp create -t logrotate-rule        -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/logrotate/rules/rotate_maillog -o name="maillog" path="/var/log/maillog" copytruncate=true rotate=5 missingok=true ifempty=true compress=false create=false size=1k dateext=true dateformat=%Y-%m-%d-%s mailfirst=true maillast=false maxage=5
    litp create -t logrotate-rule        -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/logrotate/rules/logrotate -o name="syslog" path="/var/log/cron,/var/log/maillog,/var/log/messages,/var/log/secure,/var/log/spooler" minsize=500M rotate=28 compress=true delaycompress=true rotate_every=day sharedscripts=true postrotate='/bin/kill -HUP `cat /var/run/syslogd.pid 2> /dev/null` 2> /dev/null || true'
done;

litp create -t logrotate-rule-config -p /ms/configs/logrotate
litp create -t logrotate-rule        -p /ms/configs/logrotate/rules/exampleservice -o name="exampleservice" path="/var/log/exampleservice/exampleservice.log" missingok=true ifempty=true rotate=4 copytruncate=true
litp create -t logrotate-rule        -p /ms/configs/logrotate/rules/exampleservice_tasks -o name="exampleservice_tasks" path="/var/log/exampleservice/tasks/*.log" copytruncate=true rotate=0 missingok=true ifempty=true compress=false create=false
litp create -t logrotate-rule        -p /ms/configs/logrotate/rules/rotate_maillog -o name="maillog" path="/var/log/maillog" copytruncate=true rotate=5 missingok=false ifempty=false compress=false create=false size=1k dateext=false dateformat=%Y-%m-%d-%s mailfirst=true maillast=false maxage=5 start=150
litp create -t logrotate-rule        -p /ms/configs/logrotate/rules/logrotate -o name="syslog" path="/var/log/cron,/var/log/maillog,/var/log/messages,/var/log/secure,/var/log/spooler" minsize=500M rotate=28 compress=true delaycompress=true rotate_every=day sharedscripts=true postrotate='/bin/kill -HUP `cat /var/run/syslogd.pid 2> /dev/null` 2> /dev/null || true'


# NFS & SFS File systems
litp create -t sfs-service          -p /infrastructure/storage/storage_providers/sfs_service_sp1 -o name="sfs1" management_ipv4="${sfs_management_ip}" user_name='support' password_key='key-for-sfs' # pool_name="SFS_Pool"
litp create -t sfs-virtual-server   -p /infrastructure/storage/storage_providers/sfs_service_sp1/virtual_servers/vs1 -o name="virtserv1" ipv4address="${sfs_vip}"
litp create -t sfs-pool             -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl1 -o name="SFS_Pool"
litp create -t sfs-cache            -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl1/cache_objects/cache1 -o name='dot150cashe2'
litp create -t nfs-service -p /infrastructure/storage/storage_providers/sp1 -o name="nfs1" ipv4address="10.44.86.14"
 
for (( i=0; i<10; i++)); do
    litp create -t sfs-filesystem       -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl1/file_systems/mgmt_fs$i -o path="${sfs_prefix}_mgmt_sfs-fs"$i size='50M' snap_size='0' cache_name='dot150cashe2'
    litp create -t sfs-export           -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl1/file_systems/mgmt_fs$i/exports/ex1 -o ipv4allowed_clients="${net837_ip[0]},${net837_ip[1]},${net837_ip_vm[0]},${net837_ip_vm[1]},${net837_ip_vm[2]},${net837_ip_vm[3]},${net898_ip_vm[0]}" options="rw,no_root_squash,secure_locks"
    litp create -t nfs-mount            -p /infrastructure/storage/nfs_mounts/mgmt_sfs$i -o provider="virtserv1" mount_point="/mgmt_sfs_fs"$i mount_options="soft" network_name=net837 export_path="${sfs_prefix}_mgmt_sfs-fs"$i
    litp create -t nfs-mount            -p /infrastructure/storage/nfs_mounts/nfs_nm$i   -o provider="nfs1"      mount_point="/nfs_fs"$i      mount_options="soft" network_name=net834 export_path="/home/admin/ST/nfs_share_dir_150/dir_share_150_"$i
    for (( j=0; j<${#node_sysname[@]}; j++ )); do
        litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($j+1))/file_systems/mgmt_sfs$i -s /infrastructure/storage/nfs_mounts/mgmt_sfs$i
	litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($j+1))/file_systems/nfs_nm$i -s /infrastructure/storage/nfs_mounts/nfs_nm$i
    done
done
litp update -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl1/file_systems/mgmt_fs1 -o snap_size=270
litp update -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl1/file_systems/mgmt_fs2 -o snap_size=300
litp update -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl1/file_systems/mgmt_fs3 -o snap_size=2 size='2G'
# Create VM's
/usr/bin/md5sum /var/www/html/images/image.qcow2      | cut -d ' ' -f 1 > /var/www/html/images/image.qcow2.md5
/usr/bin/md5sum /var/www/html/images/base_image.qcow2 | cut -d ' ' -f 1 > /var/www/html/images/base_image.qcow2.md5
/usr/bin/md5sum /var/www/html/images/imageRHEL7.qcow2 | cut -d ' ' -f 1 > /var/www/html/images/imageRHEL7.qcow2.md5
#/usr/bin/md5sum /var/www/html/images/test_image.qcow2 | cut -d ' ' -f 1 > /var/www/html/images/test_image.qcow2.md5
x=0
x=$[$x+1] hostname[x]="vm1a" VM_cpu[x]=4; VM_ram[x]=2000M; VM_active[x]=1; VM_standby[x]=1 VM_node_list[x]="n1,n2" VM_dependency_list[x]="SG_cups"     offline[x]="20"  eth0_ip[x]="${net898_ip_vm[0]}" eth1_ip[x]="${VM_net1vm_ip[1]}" eth2_ip[x]="${VM_net2vm_ip[2]}"
x=$[$x+1] hostname[x]="vm2a,vm2b" VM_cpu[x]=4; VM_ram[x]=4000M; VM_active[x]=2; VM_standby[x]=0 VM_node_list[x]="n1,n2" VM_dependency_list[x]="id_vm1" offline[x]="50"  eth0_ip[x]="${net898_ip_vm[1]}","${net898_ip_vm[2]}" eth1_ip[x]="${VM_net1vm_ip[2]}","${VM_net1vm_ip[3]}" eth2_ip[x]="${VM_net2vm_ip[3]}","${VM_net2vm_ip[4]}"
x=$[$x+1] hostname[x]="vm3a" VM_cpu[x]=8; VM_ram[x]=4000M; VM_active[x]=1; VM_standby[x]=1 VM_node_list[x]="n2,n1" VM_dependency_list[x]="SG_cups"     offline[x]="150" eth0_ip[x]="${net898_ip_vm[3]}" eth1_ip[x]="${VM_net1vm_ip[4]}" eth2_ip[x]="${VM_net2vm_ip[5]}"
x=$[$x+1] hostname[x]="vm4ipv6" VM_cpu[x]=8; VM_ram[x]=4000M; VM_active[x]=1; VM_standby[x]=0 VM_node_list[x]="n2" VM_dependency_list[x]="id_vm1"      offline[x]="20"  eth0_ip[x]="" eth1_ip[x]=""
x=$[$x+1] hostname[x]="vm5ipv6" VM_cpu[x]=8; VM_ram[x]=4000M; VM_active[x]=1; VM_standby[x]=0 VM_node_list[x]="n1" VM_dependency_list[x]="id_vm1"      offline[x]="20"  eth0_ip[x]="" eth1_ip[x]=""
x=$[$x+1] hostname[x]="vm6a" VM_cpu[x]=8; VM_ram[x]=4000M; VM_active[x]=1; VM_standby[x]=1 VM_node_list[x]="n2,n1" VM_dependency_list[x]="id_vm1,SG_dovecot"      offline[x]="20"  eth0_ip[x]="${net898_ip_vm[4]}" eth1_ip[x]="${VM_net1vm_ip[5]}" eth2_ip[x]="${VM_net2vm_ip[6]}"
x=$[$x+1]

for (( i=1; i<=${#VM_cpu[@]}; i++ )); do
    litp create -t vm-image    -p /software/images/id_image$i -o name="image_vm$i" source_uri=http://"${ms_host}"/images/image.qcow2
    litp create -t vm-service  -p /software/services/se_vm$i  -o service_name=vm$i image_name=image_vm$i  cpus="${VM_cpu[i]}" ram="${VM_ram[i]}" internal_status_check=on cleanup_command="/sbin/service vm$i force-stop"
    litp create -t vm-alias    -p /software/services/se_vm$i/vm_aliases/vm_ms1    -o alias_names="${ms_host}","Ammeon-LITP-mars-VIP.ammeonvpn.com"             address="${ms_ip}"
    litp create -t vm-alias    -p /software/services/se_vm$i/vm_aliases/vm_mn1    -o alias_names=mn1,"${node_hostname[0]}","Ammeon-LITP-Tag-898-VIP.ammeonvpn.com" address="${net898_ip[0]}"
    litp create -t vm-alias    -p /software/services/se_vm$i/vm_aliases/vm_mn2    -o alias_names="${node_hostname[1]}"                                             address="${net898_ip[1]}"
    litp create -t vm-yum-repo -p /software/services/se_vm$i/vm_yum_repos/updates -o name=vm_UPDATES base_url="http://"${ms_host}"/6.6/updates/x86_64/Packages"
    litp create -t vm-yum-repo -p /software/services/se_vm$i/vm_yum_repos/os      -o name=vm_os      base_url="http://"${ms_ip}"/6.6/os/x86_64"
    litp create -t vm-yum-repo -p /software/services/se_vm$i/vm_yum_repos/3pp     -o name=vm_3pp     base_url="http://"Ammeon-LITP-mars-VIP.ammeonvpn.com"/3pp"
    litp create -t vm-package  -p /software/services/se_vm$i/vm_packages/tree  -o name=tree
    litp create -t vm-package  -p /software/services/se_vm$i/vm_packages/unzip     -o name=unzip
    litp create -t vm-ram-mount -p /software/services/se_vm$i/vm_ram_mounts/vm_ram_mnt -o mount_point="/mnt/tmpfs" mount_options="size=512M,noexec,nodev,nosuid" type=tmpfs
    litp create -t vm-network-interface  -p /software/services/se_vm$i/vm_network_interfaces/net0 -o network_name=mgmt   device_name=eth0 host_device=br898   mac_prefix=0E:01:02 ipv6addresses=$ipv6_898_tp$((ip6_898count++)) gateway6=$ipv6_898_gw
    litp create -t vm-network-interface  -p /software/services/se_vm$i/vm_network_interfaces/net1 -o network_name=net1vm device_name=eth1 host_device=br_vip1 mac_prefix=0E:01:02
    litp create -t vm-network-interface  -p /software/services/se_vm$i/vm_network_interfaces/net2 -o network_name=net2vm device_name=eth2 host_device=br_vip2 mac_prefix=F6:FF:FF
    litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/id_vm$i -o name=vm$i active="${VM_active[$i]}" standby="${VM_standby[$i]}" node_list="${VM_node_list[i]}" dependency_list="${VM_dependency_list[$i]}" online_timeout=800 offline_timeout="${offline[$i]}"
    litp create -t ha-service-config     -p /deployments/d1/clusters/c1/services/id_vm$i/ha_configs/conf1 -o fault_on_monitor_timeouts=6 tolerance_limit=2 clean_timeout=40 status_interval=70 status_timeout=30 restart_limit=2 startup_retry_limit=2
    litp inherit                         -p /deployments/d1/clusters/c1/services/id_vm$i/applications/vm -s /software/services/se_vm$i -o hostnames="${hostname[i]}"
    litp update                          -p /deployments/d1/clusters/c1/services/id_vm$i/applications/vm/vm_network_interfaces/net0 -o ipaddresses="${eth0_ip[i]}" gateway="${gw_898}"
    litp update                          -p /deployments/d1/clusters/c1/services/id_vm$i/applications/vm/vm_network_interfaces/net1 -o ipaddresses="${eth1_ip[i]}"
    litp update                          -p /deployments/d1/clusters/c1/services/id_vm$i/applications/vm/vm_network_interfaces/net2 -o ipaddresses="${eth2_ip[i]}"
done
    litp update                          -p /software/services/se_vm1 -o cleanup_command="/sbin/service vm1 stop-undefine --stop-timeout=10"
    litp update                          -p /software/services/se_vm3 -o cleanup_command="/sbin/service vm3 stop-undefine --stop-timeout=5"
    litp update                          -p /software/services/se_vm6 -o cleanup_command="/sbin/service vm6 force-stop-undefine"
# VM specific CLI
    litp create -t vm-network-interface  -p /software/services/se_vm1/vm_network_interfaces/net3 -o network_name=net834   device_name=eth3 host_device=br834 ipv6addresses=$ipv6_834_tp$((ip6_834count++))
    litp update                          -p /software/services/se_vm2/vm_network_interfaces/net0 -o                                                          ipv6addresses=$ipv6_898_tp$((ip6_898count++)),$ipv6_898_tp$((ip6_898count++))
    litp create -t vm-network-interface  -p /software/services/se_vm2/vm_network_interfaces/net3 -o network_name=net837   device_name=eth3 host_device=br837 ipv6addresses=$ipv6_837_tp$((ip6_837count++)),$ipv6_837_tp$((ip6_837count++))
    litp create -t vm-network-interface  -p /software/services/se_vm3/vm_network_interfaces/net3 -o network_name=net837   device_name=eth3 host_device=br837 #ipv6addresses=$ipv6_837_tp$((ip6_837count++))
    litp create -t vm-network-interface  -p /software/services/se_vm6/vm_network_interfaces/net3 -o network_name=net834   device_name=eth3 host_device=br834 #ipv6addresses=$ipv6_834_tp$((ip6_834count++))
    litp create -t vm-network-interface  -p /software/services/se_vm6/vm_network_interfaces/net4 -o network_name=net837   device_name=eth4 host_device=br837 #ipv6addresses=$ipv6_837_tp$((ip6_837count++))
    litp create -t vm-network-interface  -p /software/services/se_vm6/vm_network_interfaces/net5 -o network_name=net835   device_name=eth5 host_device=br835 #ipv6addresses=$ipv6_835_tp$((ip6_835count++))
    litp update -p /software/services/se_vm4 -o internal_status_check=off
    litp update -p /deployments/d1/clusters/c1/services/id_vm4/applications/vm/vm_network_interfaces/net0 -d gateway
    litp remove -p /software/services/se_vm4/vm_network_interfaces/net1
    litp remove -p /software/services/se_vm4/vm_network_interfaces/net2
    litp update -p /software/services/se_vm5 -o internal_status_check=off
    litp update -p /deployments/d1/clusters/c1/services/id_vm5/applications/vm/vm_network_interfaces/net0 -d gateway
    litp update -p /software/services/se_vm5/vm_network_interfaces/net1 -o network_name=net834 device_name=eth1 host_device=br834 ipv6addresses=$ipv6_834_tp$((ip6_834count++))
    litp remove -p /software/services/se_vm5/vm_network_interfaces/net2
    litp create -t vm-ssh-key            -p /software/services/se_vm1/vm_ssh_keys/sshkey1 -o 'ssh_key=ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAgEAxMEYvlt5OvXmPNyMP/QM/mAcDk0KpOgUg7PZNXz6jRU5d99a4cndSHIyoLYyP/4EuCVNUWsjCMFsm/B06zOlCxs6XNAId+bSiABF1Vr5XzjUiFRRqsV1hM7FrFBvImYYgKCLag5xwRhajJAdu/4J+ZgRmHOsHfeRJJoVWnVzjvDOSMSiYf+Lo8dYywy94tyNll4RnXKu4D6bqwSn9YEsJX03gzijwPDTdnMVGj+/+8NxwWbc6BzV0GX5QqY/FnZ6/yuC0jxjizYEaH56PIbkRmK2wNSewjEZDhFCAm0+JWJ1bPrmJXErP3X1KBKFZSpDyHPyLQNB280PwX0jXu+KVNXAbQQXx0sNi2+Qmrx3KnhJlKyJdw2W1qf5OdsL6arDduZB/aWR0xxVPvHHPh18lrhgJMm8dHgfNDTqISabpWQtdJOUbCssvLEOjeZoVlehnENWbI4+zfDNq/gwr3PJfzFOcWimwvZK8FlV1NfuzOgzMbmS1deQUb7wJ6YivlrIEHhElbjoXTfEw+eAhhTroJJ4YVIM/v2MoHe/aGBxsXl01xv7TZAWPppPPGJ+4R7qKKr4+XpkPSGJn1nBKd71cD4L4cSKy0Pqac+fw4Tt9kQ+SIwQYe8gbdXnvQdqpvTv/e+r5IA3QsRuktwV/tTCx++9ghXSJhtUpF2Mqgr+9I8= key1@localhost.localdomain'	
    litp create -t vm-ssh-key            -p /software/services/se_vm2/vm_ssh_keys/sshkey1 -o 'ssh_key=ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAgEAxMEYvlt5OvXmPNyMP/QM/mAcDk0KpOgUg7PZNXz6jRU5d99a4cndSHIyoLYyP/4EuCVNUWsjCMFsm/B06zOlCxs6XNAId+bSiABF1Vr5XzjUiFRRqsV1hM7FrFBvImYYgKCLag5xwRhajJAdu/4J+ZgRmHOsHfeRJJoVWnVzjvDOSMSiYf+Lo8dYywy94tyNll4RnXKu4D6bqwSn9YEsJX03gzijwPDTdnMVGj+/+8NxwWbc6BzV0GX5QqY/FnZ6/yuC0jxjizYEaH56PIbkRmK2wNSewjEZDhFCAm0+JWJ1bPrmJXErP3X1KBKFZSpDyHPyLQNB280PwX0jXu+KVNXAbQQXx0sNi2+Qmrx3KnhJlKyJdw2W1qf5OdsL6arDduZB/aWR0xxVPvHHPh18lrhgJMm8dHgfNDTqISabpWQtdJOUbCssvLEOjeZoVlehnENWbI4+zfDNq/gwr3PJfzFOcWimwvZK8FlV1NfuzOgzMbmS1deQUb7wJ6YivlrIEHhElbjoXTfEw+eAhhTroJJ4YVIM/v2MoHe/aGBxsXl01xv7TZAWPppPPGJ+4R7qKKr4+XpkPSGJn1nBKd71cD4L4cSKy0Pqac+fw4Tt9kQ+SIwQYe8gbdXnvQdqpvTv/e+r5IA3QsRuktwV/tTCx++9ghXSJhtUpF2Mqgr+9I9= key1@localhost.localdomain'
    litp update                          -p /deployments/d1/clusters/c1/services/id_vm1/applications/vm/vm_network_interfaces/net3 -o ipaddresses="${net834_ip_vm[0]}"
    litp update                          -p /deployments/d1/clusters/c1/services/id_vm2/applications/vm/vm_network_interfaces/net3 -o ipaddresses="${net837_ip_vm[0]}","${net837_ip_vm[1]}"
    litp update                          -p /deployments/d1/clusters/c1/services/id_vm3/applications/vm/vm_network_interfaces/net3 -o ipaddresses="${net837_ip_vm[2]}"
    litp update                          -p /deployments/d1/clusters/c1/services/id_vm6/applications/vm/vm_network_interfaces/net3 -o ipaddresses="${net834_ip_vm[1]}"
    litp update                          -p /deployments/d1/clusters/c1/services/id_vm6/applications/vm/vm_network_interfaces/net4 -o ipaddresses="${net837_ip_vm[3]}"
    litp update                          -p /deployments/d1/clusters/c1/services/id_vm6/applications/vm/vm_network_interfaces/net5 -o ipaddresses="${net835_ip_vm[0]}"
    litp update -p /software/services/se_vm1/vm_ram_mounts/vm_ram_mnt -o type=ramfs mount_point="/mnt/ramfs"
    litp update -p /software/services/se_vm2/vm_ram_mounts/vm_ram_mnt -o type=ramfs mount_point="/mnt/ramfs" mount_options="size=256m,noexec,nosuid"

    # Update to use stop failover trigger -- TORF-107489
    litp create -t vcs-trigger -p /deployments/d1/clusters/c1/services/id_vm3/triggers/trig1 -o trigger_type=nofailover
    # The below image does not support IPV6
    #litp update                          -p /software/images/id_image3 -o name="image_vm3" source_uri=http://"${ms_ip}"/images/base_image.qcow2

# Add VM to MS


# Adding nfs shares to vm 
    for (( i=0; i<10; i++ )); do
        # Add NFS mounts to VM
        litp create -t vm-nfs-mount -p /software/services/se_vm2/vm_nfs_mounts/mount$i -o mount_point="/nfs_$i"    mount_options=soft,defaults   device_path="${nfs_ip}":/home/admin/ST/nfs_share_dir_150/dir_share_150_$i
        litp create -t vm-nfs-mount -p /software/services/se_vm3/vm_nfs_mounts/mount$i -o mount_point="/nfs_$i"    mount_options=soft,defaults   device_path="${nfs_ip}":/home/admin/ST/nfs_share_dir_150/dir_share_150_$i

        # Add managed SFS to VM
        litp create -t vm-nfs-mount -p /software/services/se_vm1/vm_nfs_mounts/mount$i -o mount_point=/nfs_mount$i mount_options="rw,sharecache" device_path="${sfs_management_ip}":"${sfs_prefix}"_mgmt_sfs-fs$i
    done

    # Add 5 managed SFS and 5 NFS to VM4
    for (( i=0; i<5; i++ )); do
         litp create -t vm-nfs-mount -p /software/services/se_vm6/vm_nfs_mounts/sfs_mount$i -o mount_point=/nfs_mount$i mount_options="rw,sharecache" device_path="${sfs_management_ip}":"${sfs_prefix}"_mgmt_sfs-fs$i
         litp create -t vm-nfs-mount -p /software/services/se_vm6/vm_nfs_mounts/mount$i     -o mount_point="/nfs_$i"    mount_options=soft,defaults   device_path="${nfs_ip}":/home/admin/ST/nfs_share_dir_150/dir_share_150_$i
    done

x=0
x=$[$x+1] hostname[x]="vm1ms" msVM_cpu[x]=4; VM_ram[x]=4000M; eth0_ip[x]="${net898_ip_vm[7]}"
x=$[$x+1] hostname[x]="vm2ms" msVM_cpu[x]=8; VM_ram[x]=8000M; eth0_ip[x]="${net898_ip_vm[8]}"
x=$[$x+1]

for (( i=1; i<=${#msVM_cpu[@]}; i++ )); do
    litp create -t vm-service  -p /ms/services/ms_vm$i  -o service_name=vm$i image_name=image_vm$i  cpus="${msVM_cpu[i]}" ram="${VM_ram[i]}" internal_status_check=off 
    litp create -t vm-alias    -p /ms/services/ms_vm$i/vm_aliases/vm_ms1    -o alias_names="Ammeon-LITP-mars-VIP.ammeonvpn.com"             address="${ms_ip}"
    litp create -t vm-alias    -p /ms/services/ms_vm$i/vm_aliases/vm_mn1    -o alias_names=mn1,"${node_hostname[0]}","Ammeon-LITP-Tag-898-VIP.ammeonvpn.com" address="${net898_ip[0]}"
    litp create -t vm-yum-repo -p /ms/services/ms_vm$i/vm_yum_repos/updates -o name=vm_UPDATES base_url="http://"${ms_host}"/6.6/updates/x86_64/Packages"
    litp create -t vm-yum-repo -p /ms/services/ms_vm$i/vm_yum_repos/os      -o name=vm_os      base_url="http://"${ms_ip}"/6.6/os/x86_64"
    litp create -t vm-package  -p /ms/services/ms_vm$i/vm_packages/tree  -o name=tree
    litp create -t vm-network-interface  -p /ms/services/ms_vm$i/vm_network_interfaces/net0 -o network_name=mgmt device_name=eth0 host_device=br0 mac_prefix=0E:01:02 ipaddresses="${eth0_ip[i]}" gateway="${gw_898}" ipv6addresses=$ipv6_898_tp$((ip6_898count++)) gateway6=$ipv6_898_gw
    litp update                -p /ms/services/ms_vm$i -o hostnames="${hostname[i]}"
done

    litp create -t vm-ssh-key            -p /ms/services/ms_vm1/vm_ssh_keys/sshkey1 -o 'ssh_key=ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAgEAxMEYvlt5OvXmPNyMP/QM/mAcDk0KpOgUg7PZNXz6jRU5d99a4cndSHIyoLYyP/4EuCVNUWsjCMFsm/B06zOlCxs6XNAId+bSiABF1Vr5XzjUiFRRqsV1hM7FrFBvImYYgKCLag5xwRhajJAdu/4J+ZgRmHOsHfeRJJoVWnVzjvDOSMSiYf+Lo8dYywy94tyNll4RnXKu4D6bqwSn9YEsJX03gzijwPDTdnMVGj+/+8NxwWbc6BzV0GX5QqY/FnZ6/yuC0jxjizYEaH56PIbkRmK2wNSewjEZDhFCAm0+JWJ1bPrmJXErP3X1KBKFZSpDyHPyLQNB280PwX0jXu+KVNXAbQQXx0sNi2+Qmrx3KnhJlKyJdw2W1qf5OdsL6arDduZB/aWR0xxVPvHHPh18lrhgJMm8dHgfNDTqISabpWQtdJOUbCssvLEOjeZoVlehnENWbI4+zfDNq/gwr3PJfzFOcWimwvZK8FlV1NfuzOgzMbmS1deQUb7wJ6YivlrIEHhElbjoXTfEw+eAhhTroJJ4YVIM/v2MoHe/aGBxsXl01xv7TZAWPppPPGJ+4R7qKKr4+XpkPSGJn1nBKd71cD4L4cSKy0Pqac+fw4Tt9kQ+SIwQYe8gbdXmvQdqpvTv/e+r5IA3QsRuktwV/tTCx++9ghXSJhtUpF2Mqgr+9I8= key1@localhost.localdomain'
    litp create -t vm-ssh-key            -p /ms/services/ms_vm2/vm_ssh_keys/sshkey1 -o 'ssh_key=ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAgEAxMEYvlt5OvXmPNyMP/QM/mAcDk0KpOgUg7PZNXz6jRU5d99a4cndSHIyoLYyP/4EuCVNUWsjCMFsm/B06zOlCxs6XNAId+bSiABF1Vr5XzjUiFRRqsV1hM7FrFBvImYYgKCLag5xwRhajJAdu/4J+ZgRmHOsHfeRJJoVWnVzjvDOSMSiYf+Lo8dYywy94tyNll4RnXKu4D6bqwSn9YEsJX03gzijwPDTdnMVGj+/+8NxwWbc6BzV0GX5QqY/FnZ6/yuC0jxjizYEaH56PIbkRmK2wNSewjEZDhFCAm0+JWJ1bPrmJXErP3X1KBKFZSpDyHPyLQNB280PwX0jXu+KVNXAbQQXx0sNi2+Qmrx3KnhJlKyJdw2W1qf5OdsL6arDduZB/aWR0xxVPvHHPh18lrhgJMm8dHgfNDTqISabpWQtdJOUbCssvLEOjeZoVlehnENWbI4+zfDNq/gwr3PJfzFOcWimwvZK8FlV1NfuzOgzMbmS1deQUb7wJ6YivlrIEHhElbjoXTfEw+eAhhTroJJ4YVIM/v2MoHe/aGBxsXl01xv7TZAWPppPPGJ+4R7qKKr4+XpkPSGJn1nBKd71cD4L4cSKy0Pqac+fw4Tt9kQ+SIwQYe8gbdXivQdqpvTv/e+r5IA3QsRuktwV/tTCx++9ghXSJhtUpF2Mqgr+9I9= key1@localhost.localdomain'

    # Add 5 managed SFS and 5 NFS to VM4
    for (( i=0; i<5; i++ )); do
         litp create -t vm-nfs-mount -p /ms/services/ms_vm1/vm_nfs_mounts/sfs_mount$i -o mount_point=/nfs_mount$i mount_options="rw,sharecache" device_path="${sfs_management_ip}":"${sfs_prefix}"_mgmt_sfs-fs$i
         litp create -t vm-nfs-mount -p /ms/services/ms_vm1/vm_nfs_mounts/mount$i     -o mount_point="/nfs_$i"    mount_options=soft,defaults   device_path="${nfs_ip}":/home/admin/ST/nfs_share_dir_150/dir_share_150_$i
         litp create -t vm-nfs-mount -p /ms/services/ms_vm2/vm_nfs_mounts/sfs_mount$i -o mount_point=/nfs_mount$i mount_options="rw,sharecache" device_path="${sfs_management_ip}":"${sfs_prefix}"_mgmt_sfs-fs$i
         litp create -t vm-nfs-mount -p /ms/services/ms_vm2/vm_nfs_mounts/mount$i     -o mount_point="/nfs_$i"    mount_options=soft,defaults   device_path="${nfs_ip}":/home/admin/ST/nfs_share_dir_150/dir_share_150_$i
    done


#Create repo and import package
litp create -p /software/items/new_repo_id -t yum-repository -o name='new_repo_name' ms_url_path=/newRepo_dir 
litp import /tmp/test_service-1.0-1.noarch.rpm /var/www/html/newRepo_dir/
litp import /tmp/test_service_name-2.0-1.noarch.rpm /var/www/html/newRepo_dir/
litp import /tmp/hello_pkg/ /var/www/html/newRepo_dir
litp create -t package -p /software/items/test_service -o name=test_service

litp inherit -p /ms/items/new_repo_id  -s /software/items/new_repo_id
litp inherit -p /ms/items/test_service -s /software/items/test_service

# Package Lists
litp create -t package-list -p /software/items/packagelist150 -o name=packagelist150
litp create -t package -p /software/items/packagelist150/packages/hello_romanian -o name=3PP-romanian-hello
litp create -t package -p /software/items/packagelist150/packages/hello_irish -o name=3PP-irish-hello
litp create -t package -p /software/items/packagelist150/packages/hello_french -o name=3PP-french-hello
litp create -t package -p /software/items/packagelist150/packages/hello_german -o name=3PP-german-hello
litp create -t package -p /software/items/packagelist150/packages/hello_russian -o name=3PP-russian-hello

litp inherit -p /ms/items/hello_list -s /software/items/packagelist150

#Create a SW Package
litp create -t yum-repository -p /software/items/yum_osHA_repo -o name=osHA base_url=http://"${ms_host}"/6/os/x86_64/HighAvailability
litp inherit -s /software/items/yum_osHA_repo -p /deployments/d1/clusters/c1/nodes/n1/items/yum_osHA_repo
litp inherit -s /software/items/yum_osHA_repo -p /deployments/d1/clusters/c1/nodes/n2/items/yum_osHA_repo
litp create -t package -p /software/items/ricci -o name=ricci release=75.el6 version=0.16.2
litp create -t package -p /software/items/httpd -o name=httpd release=39.el6 version=2.2.15
litp create -t package -p /software/items/luci -o name=luci release=63.el6 version=0.26.0
litp create -t package -p /software/items/dovecot -o name=dovecot release=7.el6_5.1 version=2.0.9 epoch=1
litp create -t package -p /software/items/cups -o name=cups release=67.el6 version=1.4.2 epoch=1

# Pin dependent packages to support version pinning of LSB Packages above
litp create -t package -p /software/items/httpd-tools      -o name=httpd-tools version=2.2.15 release=39.el6
litp create -t package -p /software/items/cups-libs        -o name=cups-libs   version=1.4.2  release=67.el6 epoch=1
litp create -t package -p /software/items/jdk              -o name=jdk
litp create -t package -p /software/items/libguestfs-tools -o name=libguestfs-tools
litp create -t package -p /software/items/telnet           -o name=telnet
litp inherit -p /ms/items/telnet -s /software/items/telnet

for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/java             -s /software/items/jdk
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/httpd-tools      -s /software/items/httpd-tools
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/cups-libs        -s /software/items/cups-libs
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/libguestfs-tools -s /software/items/libguestfs-tools  #LITPCDS-11129
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/telnet           -s /software/items/telnet
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/new_repo_id      -s /software/items/new_repo_id       # REPO
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/test_service     -s /software/items/test_service
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/hello_list     -s /software/items/packagelist150
done;

litp inherit -p /ms/items/java -s /software/items/jdk

# Service Group - Service
x=0
SG_pkg[x]="httpd";      SG_VIP_count[x]=$[3*2]; SG_active[x]=2; SG_standby[x]=0 status_interval[x]=20  status_timeout[x]=30   restart_limit[x]=1   startup_retry_limit[x]=4   node_list[x]="n2,n1" offline[x]="90"  dependency_list[x]="SG_cups" initial_online_dependency_list[x]="SG_ricci" x=$[$x+1]
SG_pkg[x]="dovecot";    SG_VIP_count[x]=$[5*2]; SG_active[x]=2; SG_standby[x]=0 status_interval[x]=20  status_timeout[x]=30   restart_limit[x]=2   startup_retry_limit[x]=3   node_list[x]="n2,n1" offline[x]="100" dependency_list[x]="SG_ricci,SG_httpd"  x=$[$x+1]
SG_pkg[x]="cups";       SG_VIP_count[x]=3;      SG_active[x]=1; SG_standby[x]=1 status_interval[x]=40  status_timeout[x]=30   restart_limit[x]=3   startup_retry_limit[x]=1   node_list[x]="n2,n1" offline[x]="50"  x=$[$x+1] #dependency_list[x]="SG_ricci,id_fmmed3" 
SG_pkg[x]="ricci";      SG_VIP_count[x]=$[0*2]; SG_active[x]=2; SG_standby[x]=0 status_interval[x]=100 status_timeout[x]=100  restart_limit[x]=10  startup_retry_limit[x]=10  node_list[x]="n1,n2" offline[x]="40"  x=$[$x+1]


vip_count=1
for (( x=0; x<${#SG_pkg[@]}; x++ )); do
litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}" -o active="${SG_active[$x]}" standby="${SG_standby[$x]}" name=vcs_"${SG_pkg[$x]}" online_timeout=45 offline_timeout="${offline[$x]}" node_list="${node_list[$x]}" dependency_list="${dependency_list[$x]}" initial_online_dependency_list="${initial_online_dependency_list[$x]}"
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

#sentinel
litp create -t package -p /software/items/sentinel -o name=EXTRlitpsentinellicensemanager_CXP9031488
litp inherit -p /ms/items/sentinel -s /software/items/sentinel

litp create -t service -p /ms/services/sentinel -o service_name=sentinel

litp create -t service -p /software/services/sentinel -o service_name=sentinel
litp inherit -p /software/services/sentinel/packages/sentinel -s /software/items/sentinel

# Service with different name as package (TORF-114306)
litp create -t package -p /software/items/diff_service_pack -o name=test_service_name
litp create -t service -p /ms/services/diff_service -o service_name=diff_service
litp inherit -p /ms/services/diff_service/packages/diff_service_pack -s /software/items/diff_service_pack
#litp create -t service -p /software/services/diff_service -o service_name=diff_service
#litp inherit -p /software/services/diff_service/packages/diff_service_pack -s /software/items/diff_service_pack
#litp inherit -p /deployments/d1/clusters/c1/nodes/n1/services/diff_service -s /software/services/diff_service
#litp inherit -p /deployments/d1/clusters/c1/nodes/n2/services/diff_service -s /software/services/diff_service


# Cause plan to fail correct value is D8:D3:85:E0:C5:76 or just reverse last octet
#litp update       -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if5           -o device_name=eth5 macaddress="D8:D3:85:E0:C5:67"

# Plugin items
dep_tags=(ms boot node cluster pre_node_cluster)
snap_tags=(validation pre_op ms_lvm node_lvm node_vxvm nas san post_op prep_puppet prep_vcs node_reboot node_power_off sanitisation node_power_on node_post_on ms_reboot)

# Deployment tag: ms
litp create -t tag-model-item -p /software/items/dep_tag_ms -o snapshot_tag=san deployment_tag=ms
litp inherit -p /ms/items/dep_tag_ms -s /software/items/dep_tag_ms

# Deployment tag : boot
litp create -t tag-model-item -p /software/items/dep_tag_boot -o snapshot_tag=san deployment_tag=boot
litp inherit -p /ms/items/dep_tag_boot -s /software/items/dep_tag_boot
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/dep_tag_boot -s /software/items/dep_tag_boot
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/items/dep_tag_boot -s /software/items/dep_tag_boot

# Deployment tag : node
litp create -t tag-model-item -p /software/items/dep_tag_node -o snapshot_tag=san deployment_tag=node
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/dep_tag_node -s /software/items/dep_tag_node
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/items/dep_tag_node -s /software/items/dep_tag_node

# Deployment tag : cluster
litp create -t tag-model-item -p /software/items/dep_tag_cluster -o snapshot_tag=san deployment_tag=cluster
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/dep_tag_cluster -s /software/items/dep_tag_cluster
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/items/dep_tag_cluster -s /software/items/dep_tag_cluster

# Deployment tag : pre_node_cluster
litp create -t tag-model-item -p /software/items/dep_tag_pre_node_cluster -o snapshot_tag=san deployment_tag=pre_node_cluster
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/dep_tag_pre_node_cluster -s /software/items/dep_tag_pre_node_cluster
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/items/dep_tag_pre_node_cluster -s /software/items/dep_tag_pre_node_cluster

# Snapshot tag : validation
litp create -t tag-model-item -p /software/items/snap_tag_validation -o snapshot_tag=validation deployment_tag=node
litp inherit -p /ms/items/snap_tag_validation -s /software/items/snap_tag_validation -o deployment_tag=ms
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/snap_tag_validation -s /software/items/snap_tag_validation
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/items/snap_tag_validation -s /software/items/snap_tag_validation

# Snapshot tag : pre_op
litp create -t tag-model-item -p /software/items/snap_tag_pre_op -o snapshot_tag=pre_op deployment_tag=node
litp inherit -p /ms/items/snap_tag_pre_op -s /software/items/snap_tag_pre_op -o deployment_tag=ms
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/snap_tag_pre_op -s /software/items/snap_tag_pre_op
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/items/snap_tag_pre_op -s /software/items/snap_tag_pre_op

# Snapshot tag : ms_lvm
litp create -t tag-model-item -p /software/items/snap_tag_ms_lvm -o snapshot_tag=ms_lvm deployment_tag=ms
litp inherit -p /ms/items/snap_tag_ms_lvm -s /software/items/snap_tag_ms_lvm

# Snapshot tag : node_lvm
litp create -t tag-model-item -p /software/items/snap_tag_node_lvm -o snapshot_tag=node_lvm deployment_tag=node
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/snap_tag_node_lvm -s /software/items/snap_tag_node_lvm
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/items/snap_tag_node_lvm -s /software/items/snap_tag_node_lvm

# Snapshot tag : node_vxvm
litp create -t tag-model-item -p /software/items/snap_tag_node_vxvm -o snapshot_tag=node_vxvm deployment_tag=node
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/snap_tag_node_vxvm -s /software/items/snap_tag_node_vxvm
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/items/snap_tag_node_vxvm -s /software/items/snap_tag_node_vxvm

# Snapshot tag : nas
litp create -t tag-model-item -p /software/items/snap_tag_nas -o snapshot_tag=nas deployment_tag=node
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/snap_tag_nas -s /software/items/snap_tag_nas
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/items/snap_tag_nas -s /software/items/snap_tag_nas

# Snapshot tag : san
litp create -t tag-model-item -p /software/items/snap_tag_san -o snapshot_tag=san deployment_tag=node
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/snap_tag_san -s /software/items/snap_tag_san
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/items/snap_tag_san -s /software/items/snap_tag_san

# Snapshot tag : post_op
litp create -t tag-model-item -p /software/items/snap_tag_post_op -o snapshot_tag=post_op deployment_tag=node
litp inherit -p /ms/items/snap_tag_post_op -s /software/items/snap_tag_post_op -o deployment_tag=ms
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/snap_tag_post_op -s /software/items/snap_tag_post_op
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/items/snap_tag_post_op -s /software/items/snap_tag_post_op

# Snapshot tag : prep_puppet
litp create -t tag-model-item -p /software/items/snap_tag_prep_puppet -o snapshot_tag=prep_puppet deployment_tag=node
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/snap_tag_prep_puppet -s /software/items/snap_tag_prep_puppet
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/items/snap_tag_prep_puppet -s /software/items/snap_tag_prep_puppet

# Snapshot tag : prep_vcs
litp create -t tag-model-item -p /software/items/snap_tag_prep_vcs -o snapshot_tag=prep_vcs deployment_tag=node
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/snap_tag_prep_vcs -s /software/items/snap_tag_prep_vcs
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/items/snap_tag_prep_vcs -s /software/items/snap_tag_prep_vcs

# Snapshot tag : node_reboot
litp create -t tag-model-item -p /software/items/snap_tag_node_reboot -o snapshot_tag=node_reboot deployment_tag=node
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/snap_tag_node_reboot -s /software/items/snap_tag_node_reboot
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/items/snap_tag_node_reboot -s /software/items/snap_tag_node_reboot

# Snapshot tag : node_power_off
litp create -t tag-model-item -p /software/items/snap_tag_node_power_off -o snapshot_tag=node_power_off deployment_tag=node
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/snap_tag_node_power_off -s /software/items/snap_tag_node_power_off
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/items/snap_tag_node_power_off -s /software/items/snap_tag_node_power_off

# Snapshot tag : sanitisation
litp create -t tag-model-item -p /software/items/snap_tag_sanitisation -o snapshot_tag=sanitisation deployment_tag=node
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/snap_tag_sanitisation -s /software/items/snap_tag_sanitisation
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/items/snap_tag_sanitisation -s /software/items/snap_tag_sanitisation

# Snapshot tag : node_power_on
litp create -t tag-model-item -p /software/items/snap_tag_node_power_on -o snapshot_tag=node_power_on deployment_tag=node
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/snap_tag_node_power_on -s /software/items/snap_tag_node_power_on
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/items/snap_tag_node_power_on -s /software/items/snap_tag_node_power_on

# Snapshot tag : node_post_on
litp create -t tag-model-item -p /software/items/snap_tag_node_post_on -o snapshot_tag=node_post_on deployment_tag=node
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/snap_tag_node_post_on -s /software/items/snap_tag_node_post_on
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/items/snap_tag_node_post_on -s /software/items/snap_tag_node_post_on

# Snapshot tag: ms_reboot
litp create -t tag-model-item -p /software/items/snap_tag_ms_reboot -o snapshot_tag=ms_reboot deployment_tag=ms
litp inherit -p /ms/items/snap_tag_ms_reboot -s /software/items/snap_tag_ms_reboot

# force a retry
#litp update -p /deployments/d1/clusters/c1/services/id_vm6/ -o online_timeout=10
#check_cs_initial_online_tasks "/deployments/d1/clusters/c1/"

# Packages from ENM ISO
#litp load -p /software -f /tmp/enm_package_2.xml --merge
#litp inherit -p /ms/items/model_repo -s /software/items/model_repo
#litp inherit -p /ms/items/model_package -s /software/items/model_package
#litp inherit -p /ms/items/ms_repo -s /software/items/ms_repo
#litp inherit -p /ms/items/common_repo -s /software/items/common_repo
#litp inherit -p /ms/items/db_repo -s /software/items/db_repo
#litp inherit -p /ms/items/services_repo -s /software/items/services_repo

# Items for LITPCDS-10650 plugin - config task replacement plugin
litp create -t story10650 -p /software/items/tc01_foobar1 -o name=tc01_foobar1
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/testplug -s /software/items/tc01_foobar1
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/items/testplug -s /software/items/tc01_foobar1

litp export -p / -f /tmp/initial_deployment.xml

# temp dhcp data
#litp create -t dhcp-service -p /software/services/s1 -o service_name="dhcp_svc1" nameservers="10.44.86.4" domainsearch="ammeonvpn.com" ntpservers="10.44.86.30"
#litp create -t dhcp-subnet -p /software/services/s1/subnets/s1 -o network_name="traffic1"
#litp create -t dhcp-range -p /software/services/s1/subnets/s1/ranges/r1 -o start="10.19.150.124" end="10.19.150.144"
#litp inherit -p /deployments/d1/clusters/c1/nodes/n1/services/s1 -s /software/services/s1 -o primary="true"
#litp inherit -p /deployments/d1/clusters/c1/nodes/n2/services/s1 -s /software/services/s1 -o primary="false"


litp create_plan
