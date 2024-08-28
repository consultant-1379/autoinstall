#!/bin/bash
#
# LITP deployment script for RHEL7
#  deploys 2 peer nodes
#  very basic model written for rack machines
#  no remote storage
#
# Usage:
#   RHEL7_deploy_rack_MN.sh <CLUSTER_SPEC_FILE>
#

if [ "$#" -lt 1 ]; then
    echo -e "Usage:\n  $0 <CLUSTER_SPEC_FILE>" >&2
    exit 1
fi

cluster_file="$1"
source "$cluster_file"

set -x

litpcrypt set key-for-root root "${nodes_ilo_password}"

############################################################################
# SOFTWARE
############################################################################

# OS PROFILE
litp create -p /software/profiles/os_prof1 -t os-profile -o name=os-profile1 path=/var/www/html/7/os/x86_64/ version=rhel7

# SOFTWARE ITEMS
litp create -p /software/items/jdk -t package -o name=EXTRserverjre_CXP9035480
litp create -p /software/items/dovecot -t package -o name=dovecot release=3.el7 version=2.2.36 epoch=1
litp create -p /software/items/sentinel -t package -o name=EXTRlitpsentinellicensemanager_CXP9031488

# SERVICES
litp create  -p /software/services/sentinel -t service -o service_name=sentinel
litp inherit -p /software/services/sentinel/packages/sentinel -s /software/items/sentinel

############################################################################
# DEPLOYMENTS
############################################################################

litp create -p /deployments/d1 -t deployment

############################################################################
# INFRASTRUCTURE
############################################################################

# STORAGE PROFILE 1, 1 VOLUME GROUP 1 DISKS
litp create -p /infrastructure/storage/storage_profiles/profile_1 -t storage-profile
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1 -t volume-group -o volume_group_name=vg_root
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/root -t file-system -o type=xfs mount_point=/ size=8G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/swap -t file-system -o type=swap mount_point=swap size=2G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/data1 -t file-system -o type=ext4 mount_point=/data1 size=2G snap_size=0
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/internal -t physical-device -o device_name=hd0

# CREATE INFRASTRUCTURE
litp create -p /infrastructure/systems/sys1 -t blade -o system_name="${ms_sysname}"

for (( i=0; i<${#node_sysname[@]}; i++ )); do
    # DISK CREATION RACK PEER NODES - LOCAL STORAGE
    litp create -p /infrastructure/systems/sys$(($i+2)) -t blade -o system_name="${node_sysname[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk0 -t disk -o name=hd0 size=28G bootable=true uuid="${node_disk_uuid[$i]}"
    # BMC SETUP FOR PXE BOOTING
    litp create -p /infrastructure/systems/sys$(($i+2))/bmc -t bmc -o ipaddress="${node_bmc_ip[$i]}" username=root password_key=key-for-root
done

##### NETWORKING SETUP #####

# ROUTES IPV4
litp create -p /infrastructure/networking/routes/r1 -t route -o subnet="0.0.0.0/0" gateway="${nodes_gateway}"

# SETUP MGMT NETWORK
litp create -p /infrastructure/networking/networks/mgmt -t network -o name=mgmt subnet="${nodes_subnet}" litp_management=true

# HEARTBEAT NETWORKS FOR VCS
litp create -p /infrastructure/networking/networks/heartbeat1 -t network -o name=hb1
litp create -p /infrastructure/networking/networks/heartbeat2 -t network -o name=hb2

##### NO STORAGE SETUP #####
##### NO NAS #####
##### NO NFS #####

############################################################################
# MS
############################################################################

# SET MS HOSTNAME - SET DURING RHEL/LITP INSTALLATION
litp update -p /ms -o hostname="$ms_host"

# CREATE MS SYSTEM
litp inherit -p /ms/system -s /infrastructure/systems/sys1

# MS SERVICES
litp create -p /ms/services/cobbler -t cobbler-service
litp create -p /ms/services/sentinel -t service -o service_name=sentinel

# MS ROUTES
litp inherit -p /ms/routes/r1 -s /infrastructure/networking/routes/r1

# BASIC NETWORK #
litp create -p /ms/network_interfaces/if0 -t eth -o device_name=eth0 macaddress="${ms_eth0_mac}" ipaddress="${ms_ip}" network_name=mgmt
#litp create -t vlan -p /ms/network_interfaces/vlan834 -o device_name=eth0.834  ipaddress="${ms_ip}" network_name=mgmt

# FIREWALL SETUP FOR  MS
litp create -p /ms/configs/fw_config_init -t firewall-node-config
litp create -p /ms/configs/fw_config_init/rules/fw_icmp -t firewall-rule -o name="100 icmp" proto="icmp"
litp create -p /ms/configs/fw_config_init/rules/fw_icmpv6 -t firewall-rule -o name="099 icmpv6" proto="ipv6-icmp" provider=ip6tables
litp create -p /ms/configs/fw_config_init/rules/fw_nfsudp -t firewall-rule -o name='011 nfsudp' dport=111,2049,4001 proto=udp
litp create -p /ms/configs/fw_config_init/rules/fw_nfstcp -t firewall-rule -o name='001 nfstcp' dport=111,2049,4001 proto=tcp
litp create -p /ms/configs/fw_config_init/rules/fw_dnstcp -t firewall-rule -o name='200 dnstcp' dport=53 proto=tcp
litp create -p /ms/configs/fw_config_init/rules/fw_dnsudp -t firewall-rule -o name='201 dnsudp' dport=53 proto=udp

# DNS FOR MS
litp create -p /ms/configs/dns_client -t dns-client -o search=ammeonvpn.com,exampleone.com,exampletwo.com,examplethree.com,examplefour.com,examplefive.com
litp create -p /ms/configs/dns_client/nameservers/init_name_server -t nameserver -o ipaddress="${nameserver_ip}" position=1

# LOGROTATE RULES FOR /var/log/messages
litp create -p /ms/configs/logrotate -t logrotate-rule-config
litp create -p /ms/configs/logrotate/rules/messages -t logrotate-rule -o name="syslog" path="/var/log/cron,/var/log/maillog,/var/log/messages,/var/log/secure,/var/log/spooler" minsize=500M rotate=28 compress=true delaycompress=false rotate_every=day sharedscripts=true postrotate='/bin/kill -HUP `cat /var/run/syslogd.pid 2> /dev/null` 2> /dev/null || true'


############################################################################
# CLUSTER SETUP
############################################################################

# CLUSTER CREATION - VCS
litp create -p /deployments/d1/clusters/c1 -t vcs-cluster -o cluster_type=vcs low_prio_net=mgmt llt_nets='hb1,hb2' cluster_id="${cluster_id}" default_nic_monitor="mii" vcs_seed_threshold=1

# CLUSTER CONFIGURATION FOR FILEWALLS
litp create -p /deployments/d1/clusters/c1/configs/fw_config_init -t firewall-cluster-config
litp create -p /deployments/d1/clusters/c1/configs/fw_config_init/rules/fw_icmp -t firewall-rule -o name="100 icmp" proto="icmp"

# INDIVIDUAL NODE SETUP

for (( i=0; i<${#node_sysname[@]}; i++ )); do
    # HOSTNAME SETUP
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1)) -t node -o hostname="${node_hostname[$i]}"

    # INHERIT SYSTEM SETUP FROM ABOVE
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/system -s  /infrastructure/systems/sys$(($i+2))

    # CREATE OS PROFILE
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/os -s /software/profiles/os_prof1

    # CREATE STORAGE PROFILE
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/storage_profile -s /infrastructure/storage/storage_profiles/profile_1

    # INHERIT SPECIFIC SOFTWARE ITEMS
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/java -s /software/items/jdk
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/dovecot -s /software/items/dovecot

    # LOG ROTATE RULES FOR THE NODE
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/logrotate -t logrotate-rule-config
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/logrotate/rules/messages -t logrotate-rule -o name="syslog" path="/var/log/messages,/var/log/cron,/var/log/maillog,/var/log/secure,/var/log/spooler" size=10M rotate=50 copytruncate=true sharedscripts=true postrotate="/bin/kill -HUP \`cat /var/run/syslogd.pid 2> /dev/null\` 2> /dev/null || true"

    #PXE BOOT
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if4 -t eth -o device_name=eth4 macaddress="${node_eth4_mac[$i]}" pxe_boot_only=true

    # MGMT NETWORK SETUP
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if0 -t eth -o device_name=eth0 macaddress="${node_eth0_mac[$i]}" ipaddress="${node_ip[$i]}"  network_name=mgmt

    # HEARTBEAT NETWORK SETUP
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if1 -t eth -o device_name=eth1 macaddress="${node_eth1_mac[$i]}" network_name=hb1 rx_ring_buffer=453 tx_ring_buffer=4078
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if2 -t eth -o device_name=eth2 macaddress="${node_eth2_mac[$i]}" network_name=hb2

    # ROUTE SETUP
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/r1 -s /infrastructure/networking/routes/r1

    # CREATE FIREWALL SETUP FOR NODES
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config_init -t firewall-node-config
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config_init/rules/fw_nfsudp -t firewall-rule -o 'name=011 nfsudp' dport=111,2049,4001 proto=udp
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config_init/rules/fw_nfstcp -t firewall-rule -o 'name=001 nfstcp' dport=111,2049,4001 proto=tcp
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config_init/rules/fw_icmp_ip6 -t firewall-rule -o 'name=099 icmpipv6' proto=ipv6-icmp
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config_init/rules/fw_dnstcp -t firewall-rule -o name='200 dnstcp' dport=53 proto=tcp
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config_init/rules/fw_dnsudp -t firewall-rule -o name='201 dnsudp' dport=53 proto=udp

    # DNS SETUP FOR NODES
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/dns_client -t dns-client -o search=ammeonvpn.com,exampleone.com,exampletwo.com,examplethree.com,examplefour.com,examplefive.com
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/dns_client/nameservers/init_name_server -t nameserver -o ipaddress=10.44.86.212 position=1

    # NO NAS or NFS
    # NO NODE SERVICES

done

# NO VXVM SETUP FOR CLUSTER
# NO FENCING DISKS SETUP FOR CLUSTER

# CLUSTER NETWORK SETUP
litp create -p /deployments/d1/clusters/c1/network_hosts/nh1 -t vcs-network-host -o network_name="mgmt"     ip="${vcs_network_host1}"
litp create -p /deployments/d1/clusters/c1/network_hosts/nh2 -t vcs-network-host -o network_name="mgmt"     ip="${ms_ip}"
litp create -p /deployments/d1/clusters/c1/network_hosts/nh3 -t vcs-network-host -o network_name="mgmt"     ip="${vcs_network_host3}"

# NO VCS SERVICE GROUPS
# NO IMAGES

litp create_plan
