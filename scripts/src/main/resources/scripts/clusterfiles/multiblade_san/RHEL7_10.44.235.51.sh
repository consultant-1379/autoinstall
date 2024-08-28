#!/bin/bash

# Used for PCDB_2node_autoupgrade_RHEL7 and PCDB_2node_expansion_RHEL7

blade_type="G8"

ms_ilo_ip="10.44.84.132"
ms_ilo_username="root"
ms_ilo_password="Amm30n!!"
ms_ip="10.44.235.51"
ms_ip_net898="${ms_ip}"
ms_ip_net837="10.44.86.200"
ms_subnet="10.44.235.0/24"
ms_gateway="10.44.235.1"
ms_vlan=""
ms_host_short="ms1"
ms_host="ms1"
ms_eth0_mac="2C:59:E5:3D:B3:B0"
ms_eth1_mac="2C:59:E5:3D:B3:B4"
ms_eth2_mac="2C:59:E5:3D:B3:B1"
ms_eth3_mac="2C:59:E5:3D:B3:B5"

ms_sysname="CZJ33308HS"
ms_disk_uuid="600508b1001c48383bc8f86f797ad2e3"

ipv6_gateway="fdde:4d7e:d471:0004:0:898:0:1"
ms_ipv6_00="fdde:4d7e:d471:0004:0:898:68:0/64"
ms_ipv6_01="fdde:4d7e:d471:0004:0:898:68:10/64"
ms_ipv6_00_noprefix="fdde:4d7e:d471:0004:0:898:68:0"


nodes_subnet="$ms_subnet"
nodes_gateway="$ms_gateway"
nodes_ilo_password='Amm30n!!'


traffic_network1_gw_subnet="172.16.168.1/32"
traffic_network2_gw_subnet="172.16.168.2/32"
##VCS requires gateway is pingable
traffic_network1_gw="172.16.100.2"
traffic_network2_gw="172.16.200.130"

traffic_network1_subnet="172.16.100.0/24"
traffic_network2_subnet="172.16.200.128/24"

##SETUP VIPS
##Traffic network 3
##VCS requires gateway is pingable
traffic_network3_gw="172.16.201.2"
traffic_network3_gw_subnet="172.16.168.3/32"
traffic_network3_subnet="172.16.201.0/24"


ntp_ip[1]="10.44.86.212"
ntp_ip[2]="127.127.1.0"

# DNS Server
nameserver_ip="10.44.86.212"

#NAS - VA
sfs_username="support"
sfs_password="veritas"
sfs_management_ip="10.44.235.29"
sfs_vip="10.44.235.32"
sfs_snapshot_cleanup_list="10.44.235.29:master:veritas:L_int_68_Managed-fs1_=int_68_Managed-fs1:68Cache1"
sfs_cleanup_list="10.44.235.29:master:veritas:/vx/int_68_Managed-fs1=10.44.235.68:int_68_Managed-fs1"

sfs_unmanaged_prefix="/vx/int_68_unmanaged-fs1"
sfs_prefix="/vx/int_68"
sfs_pool1="ST_Pool"
sfs_pool2="ST_Pool2"
sfs_cache="CI68_cache1"
sfs_username="support"
sfs_password="veritas"
managedfs1="${sfs_prefix}_Managed-fs1"
managedfs2="${sfs_prefix}_Managed-fs2"
managedfs3="${sfs_prefix}_Managed-fs3"


vcs_cluster_id="5068"
cluster_id=$vcs_cluster_id
cluster2_id="5168"
cluster3_id="5268"


#Vlan_837
net837_subnet="10.44.86.192/26"


# Private Network
network1_VIP[0]="10.46.68.68"
private_network_subnet="10.46.68.64/26"


node_sysname[1]="CZJ33308HV"
node_bmc_ip[1]="10.44.84.131"
node_disk_uuid[1]="600601600f3133005262413971c9e411"
vm_images_disk_uuid[1]="600508b1001cdfcd145d44e2377fed13"
vm_instances_disk_uuid[1]="600508b1001cf47758ee7b1e10d6629c"

node_vxvm_uuid[1]="6006016020303300cca745c7590ae711"
node_vxvm2_uuid[1]="6006016020303300e2767f5c5a0ae711"

node_ip[1]="10.44.235.70"
node_ip_2[1]="172.16.100.3"
node_ip_3[1]="172.16.200.131"
node_ip_4[1]="172.16.201.3"
node_ipv6_00[1]="fdde:4d7e:d471:0004:0:898:70:0/64"

node_hostname[1]="node2dot68"
node_eth0_mac[1]="2C:59:E5:3D:32:58"
node_eth1_mac[1]="2C:59:E5:3D:32:5C"
node_eth2_mac[1]="2C:59:E5:3D:32:59"
node_eth3_mac[1]="2C:59:E5:3D:32:5D"
node_eth4_mac[1]="2C:59:E5:3D:32:5A"
node_eth5_mac[1]="2C:59:E5:3D:32:5E"
node_eth6_mac[1]="2C:59:E5:3D:32:5B"
node_eth7_mac[1]="2C:59:E5:3D:32:5F"

node_sysname[0]="CZJ33308HP"
node_bmc_ip[0]="10.44.84.130"

node_disk_uuid[0]="600601600f3133009a406f2b71c9e411"
vm_images_disk_uuid[0]="600508b1001c2ca000bd5f51b10abafd"
vm_instances_disk_uuid[0]="600508b1001c70cf42d17e5fb8d5c0f9"

node_vxvm_uuid[0]="6006016020303300cca745c7590ae711"
node_vxvm2_uuid[0]="6006016020303300e2767f5c5a0ae711"

node_ip[0]="10.44.235.69"
node_ip_2[0]="$traffic_network1_gw"
node_ip_3[0]="$traffic_network2_gw"
node_ip_4[0]="$traffic_network3_gw"
node_ipv6_00[0]="fdde:4d7e:d471:0004:0:898:69:0/64"

node_hostname[0]="node1dot68"
node_eth0_mac[0]="2C:59:E5:3C:5F:F8"
node_eth1_mac[0]="2C:59:E5:3C:5F:FC"
node_eth2_mac[0]="2C:59:E5:3C:5F:F9"
node_eth3_mac[0]="2C:59:E5:3C:5F:FD"
node_eth4_mac[0]="2C:59:E5:3C:5F:FA"
node_eth5_mac[0]="2C:59:E5:3C:5F:FE"
node_eth6_mac[0]="2C:59:E5:3C:5F:FB"
node_eth7_mac[0]="2C:59:E5:3C:5F:FF"

nodes_sg_fo1_vip1="172.16.201.8"
nodes_sg_fo1_vip2="172.16.201.9"
nodes_sg_pl1_vip1="172.16.201.10"
nodes_sg_pl1_vip2="172.16.201.11"
nodes_sg_pl1_vip3="172.16.201.12"
nodes_sg_sl1_vip1="172.16.201.13"
nodes_sg_sl1_vip1_ipv6="fdde:4d7e:d471:19::15:0/64"

nodes_sg_fo2_vip1="172.16.201.14"
nodes_sg_fo2_vip2="172.16.201.15"
nodes_sg_pl2_vip1="172.16.201.16"
nodes_sg_pl2_vip2="172.16.201.17"
nodes_sg_sl2_vip1="172.16.201.18"
nodes_sg_sl2_vip1_ipv6="fdde:4d7e:d471:19::67:51/64"

nodes_sg_sl3_vip1="172.16.201.19"
nodes_sg_sl3_vip1_ipv6="fdde:4d7e:d471:19::67:53/64"


# VCS Network host settings
vcs_network_host1="172.16.101.10"
vcs_network_host3="2001:ABCD:F0::10"
vcs_network_host5="2001:ABCD:F0::10"
vcs_network_host6="172.16.101.11"
vcs_network_host7="2001:ABCD:F0::11"
vcs_network_host8="172.16.101.12"
vcs_network_host10="20.20.20.78"
vcs_network_host11="20.20.20.78"
vcs_network_host12="172.16.101.13"
vcs_network_host13="172.16.101.14"
vcs_network_host14="172.16.101.15"

vcs_network_host15="172.16.101.16"
vcs_network_host16="2001:ABCD:F0::16"
vcs_network_host17="2001:ABCD:F0::16"
vcs_network_host18="172.16.101.17"
vcs_network_host19="2001:ABCD:F0::18"
vcs_network_host20="172.16.101.19"
vcs_network_host21="20.20.20.79"
vcs_network_host22="20.20.20.79"
vcs_network_host23="172.16.101.20"
vcs_network_host24="172.16.101.21"
vcs_network_host25="172.16.101.22"

vcs_network_host26="172.16.101.23"
vcs_network_host27="2001:ABCD:F0::23"
vcs_network_host28="2001:ABCD:F0::23"
vcs_network_host29="172.16.101.24"
vcs_network_host30="2001:ABCD:F0::25"
vcs_network_host31="172.16.101.26"
vcs_network_host32="20.20.20.80"
vcs_network_host33="20.20.20.80"
vcs_network_host34="172.16.101.27"
vcs_network_host35="172.16.101.28"
vcs_network_host36="172.16.101.29"

#LSB service VIPs
traf2_ip[0]="10.20.68.5"
traf2_ip[1]="10.20.68.6"
traf2_vip[0]="10.20.68.10"
traf2_vip[1]="10.20.68.20"
traf2_vip[2]="10.20.68.30"
traf2_subnet="10.20.68.0/24"
traf2_ip[1]="10.20.68.1"


net1vm_gateway="10.46.94.65"
net1vm_subnet="10.46.94.64/26"
net2vm_subnet="10.46.94.128/26"
net3vm_subnet="10.46.94.192/26"

net1vm_ip_ms="10.46.94.126"
br1_net1vm[0]="10.46.94.125"
br1_net1vm[1]="10.46.94.124"
br2_net2vm[0]="10.46.94.190"
br2_net2vm[1]="10.46.94.189"
br3_net3vm[0]="10.46.94.254"
br3_net3vm[1]="10.46.94.253"
net1vm_ip[0]="10.46.94.66"
net1vm_ip[1]="10.46.94.67"
net1vm_ip[2]="10.46.94.68"
net1vm_ip[3]="10.46.94.69"

vm_ip_for_del[0]="10.46.94.110"
vm_ip_for_del[1]="10.46.94.111"

# If set will use the IPs below for MS vm service.
use_real_ip=true

ms_vm_ip[0]="10.44.235.67"
vm_gw_ip="10.44.235.1"
ms_vm_ip6[0]="fdde:4d7e:d471:0004:0:898:67:0/64"
vm_gw6_ip="fdde:4d7e:d471:0004:0:898:0:1"


vm_ip[0]="10.46.94.70"
vm_ip[1]="10.46.94.71"
vm_ip[2]="10.46.94.72"
vm_ip[3]="10.46.94.73"
vm_ip[4]="10.46.94.74"
vm_ip[5]="10.46.94.75"
vm_ip[6]="10.46.94.76"
vm_ip[7]="10.46.94.77"
vm_ip[8]="10.46.94.78"
vm_ip[9]="10.46.94.79"
vm_ip[10]="10.46.94.80"
vm_ip[11]="10.46.94.81"
vm_ip[12]="10.46.94.82"
vm_ip[13]="10.46.94.83"
vm_ip[14]="10.46.94.84"
vm_ip[15]="10.46.94.85"


net1vm_gateway6="fdde:4d7e:d471:46::68:1"
vm_ip6[0]="fdde:4d7e:d471:46::68:5/64"
vm_ip6[1]="fdde:4d7e:d471:46::68:6/64"
vm_ip6[2]="fdde:4d7e:d471:46::68:7/64"
vm_ip6[3]="fdde:4d7e:d471:46::68:10/64"
vm_ip6[4]="fdde:4d7e:d471:46::68:11/64"
vm_ip6[5]="fdde:4d7e:d471:46::68:12/64"
vm_ip6[6]="fdde:4d7e:d471:46::68:13/64"
vm_ip6[7]="fdde:4d7e:d471:46::68:14/64"
vm_ip6[8]="fdde:4d7e:d471:46::68:15/64"
vm_ip6[9]="fdde:4d7e:d471:46::68:16/64"
vm_ip6[10]="fdde:4d7e:d471:46::68:17/64"
vm_ip6[11]="fdde:4d7e:d471:46::68:18/64"
vm_ip6[12]="fdde:4d7e:d471:46::68:19/64"
vm_ip6[13]="fdde:4d7e:d471:46::68:20/64"
vm_ip6[14]="fdde:4d7e:d471:46::68:21/64"
vm_ip6[15]="fdde:4d7e:d471:46::68:22/64"


#IPv6
ipv6_834_subnet="fdde:4d7e:d471:0::834:0:0/64"
ipv6_835_subnet="fdde:4d7e:d471:1::835:0:0/64"
ipv6_836_subnet="fdde:4d7e:d471:2::836:0:0/64"
ipv6_837_subnet="fdde:4d7e:d471:3::837:0:0/64"
ipv6_898_subnet="fdde:4d7e:d471:4::898:0:0/64"

ipv6_t1_subnet="fdde:4d7e:d471:19::68:0/64"
ipv6_t2_subnet="fdde:4d7e:d471:20::68:0/64"
ipv6_vm1_subnet="fdde:4d7e:d471:6801::68:0/64"
ipv6_vm2_subnet="fdde:4d7e:d471:6802::68:0/64"
ipv6_vm3_subnet="fdde:4d7e:d471:6803::68:0/64"

ipv6_834_gw="fdde:4d7e:d471:0::834:0:1"
ipv6_835_gw="fdde:4d7e:d471:1::835:0:1"
ipv6_836_gw="fdde:4d7e:d471:2::836:0:1"
ipv6_837_gw="fdde:4d7e:d471:3::837:0:1"
ipv6_898_gw="fdde:4d7e:d471:4::898:0:1"
ipv6_t1_gw="fdde:4d7e:d471:19::68:1"
ipv6_t2_gw="fdde:4d7e:d471:20::68:1"
ipv6_vm1_gw="fdde:4d7e:d471:6801::68:1"
ipv6_vm2_gw="fdde:4d7e:d471:6802::68:1"
ipv6_vm3_gw="fdde:4d7e:d471:6803::68:1"

ipv6_834_tp="fdde:4d7e:d471:0::834:68:a"
ipv6_835_tp="fdde:4d7e:d471:1::835:68:a"
ipv6_836_tp="fdde:4d7e:d471:2::836:68:a"
ipv6_837_tp="fdde:4d7e:d471:3::837:68:a"
ipv6_898_tp="fdde:4d7e:d471:4::898:68:a"
ipv6_t1_tp="fdde:4d7e:d471:19::68:a"
ipv6_t2_tp="fdde:4d7e:d471:20::68:a"
ipv6_vm1_tp="fdde:4d7e:d471:6801::68:a"
ipv6_vm2_tp="fdde:4d7e:d471:6802::68:a"
ipv6_vm3_tp="fdde:4d7e:d471:6803::68:a"

fencing_disk1_uuid="6006016020303300da39eb85292ce711"
fencing_disk2_uuid="60060160203033000a0512a0292ce711"
fencing_disk3_uuid="6006016020303300a4445fbf292ce711"

copytestfile1="http://10.44.235.150/cdb/vm_test_image-2-1.0.4.qcow2:/var/www/html/images/vm_image_rhel6.qcow2"
copytestfile2="http://10.44.235.150/cdb/ci_test_service1-1.0-1.noarch.rpm:/tmp/test_services/ci_test_service1-1.0-1.noarch.rpm"
copytestfile3="http://10.44.235.150/cdb/vm_test_image-1-1.0.3.qcow2:/var/www/html/images/vm_image_rhel7.qcow2"
copytestfile4="http://10.44.235.150/cdb/3PP-dutch-hello-1.0.0-1.noarch.rpm:/tmp/test_services/3PP-dutch-hello-1.0.0-1.noarch.rpm"
copytestfile5="http://10.44.235.150/cdb/3PP-english-hello-1.0.0-1.noarch.rpm:/tmp/test_services/3PP-english-hello-1.0.0-1.noarch.rpm"
copytestfile6="http://10.44.235.150/cdb/test_service-1.0-1.noarch.rpm:/tmp/test_services/test_service-1.0-1.noarch.rpm"



############################################################
# Expansion Specific section
############################################################

exclude_vxvm="exclude"

#### Node 3 Setup        ###################################
node_expansion_hostname[0]="node3"
node_expansion_bmc_ip[0]="10.44.84.133"
node_expansion_sysname[0]="CZJ33308HK"

node_expansion_ip[0]="10.44.235.71"
node_expansion_ip_2[0]="172.16.100.4"
node_expansion_ip_3[0]="172.16.200.132"
node_expansion_ip_4[0]="172.16.201.4"

node_expansion_ipv6_00[0]="fdde:4d7e:d471:0004:0:898:71:0/64"

node_expansion_eth0_mac[0]="2C:59:E5:3D:F2:08"
node_expansion_eth1_mac[0]="2C:59:E5:3D:F2:0C"
node_expansion_eth2_mac[0]="2C:59:E5:3D:F2:09"
node_expansion_eth3_mac[0]="2C:59:E5:3D:F2:0D"
node_expansion_eth4_mac[0]="2C:59:E5:3D:F2:0A"
node_expansion_eth5_mac[0]="2C:59:E5:3D:F2:0E"
node_expansion_eth6_mac[0]="2C:59:E5:3D:F2:0B"
node_expansion_eth7_mac[0]="2C:59:E5:3D:F2:0F"

node_expansion_disk_uuid[0]="600601602030330054899af1cf06e611" #LITP_Site1Int51_MN1_Lun72
node_expansion_disk1_uuid[0]="6006016020303300240e1d83d006e611" #LITP_Site1Int51_MN1_Lun73

#### Node 4 Setup        ###################################
node_expansion_hostname[1]="node4"
node_expansion_bmc_ip[1]="10.44.84.134"
node_expansion_sysname[1]="CZJ33308HL"

node_expansion_ip[1]="10.44.235.72"
node_expansion_ip_2[1]="172.16.100.5"
node_expansion_ip_3[1]="172.16.200.133"
node_expansion_ip_4[1]="172.16.201.5"

node_expansion_ipv6_00[1]="fdde:4d7e:d471:0004:0:898:72:0/64"

node_expansion_eth0_mac[1]="2C:59:E5:3D:93:70"
node_expansion_eth1_mac[1]="2C:59:E5:3D:93:74"
node_expansion_eth2_mac[1]="2C:59:E5:3D:93:71"
node_expansion_eth3_mac[1]="2C:59:E5:3D:93:75"
node_expansion_eth4_mac[1]="2C:59:E5:3D:93:72"
node_expansion_eth5_mac[1]="2C:59:E5:3D:93:76"
node_expansion_eth6_mac[1]="2C:59:E5:3D:93:73"
node_expansion_eth7_mac[1]="2C:59:E5:3D:93:77"

node_expansion_disk_uuid[1]="60060160203033007c0809c7d506e611" #LITP_Site1Int51_MN2_Lun78
node_expansion_disk1_uuid[1]="6006016020303300a87b5517d606e611" #LITP_Site1Int51_MN2_Lun79

############################################################
# Nodes to shutdown after prepare_restore
prepare_restore_shutdown_ip[0]="10.44.235.69"
prepare_restore_shutdown_ip[1]="10.44.235.70"
prepare_restore_shutdown_ip[2]="10.44.235.71"
prepare_restore_shutdown_ip[3]="10.44.235.72"


