#!/bin/bash

blade_type="G8"

ms_ilo_ip="10.44.84.52"
ms_ilo_username="root"
ms_ilo_password='Amm30n!!'
ms_ip="10.44.86.105"
ms_ip_ext="10.44.235.111"
ms_ip_backup="10.44.235.140"
ms_ipv6_835="fdde:4d7e:d471:0001::0835:105:0100/64"
ms_ipv6_835_short="fdde:4d7e:d471:0001::0835:105:0100"
ms_ipv6_898="fdde:4d7e:d471:0004::0898:105:0100/64"
ms_ipv6_834="fdde:4d7e:d471:0000::0834:105:0100/64"

ms_subnet="10.44.86.64/26"
ms_gateway="10.44.86.65"
ms_vlan=""
ms_host="Ms1105.company.com"
ms_host_short='Ms1105'
ms_eth0_mac="2C:59:E5:3D:B2:D0"
ms_eth1_mac="2C:59:E5:3D:B2:D4"
ms_eth2_mac="2C:59:E5:3D:B2:D1"
ms_eth3_mac="2C:59:E5:3D:B2:D5"
ms_sysname="CZJ33308JD"
ms1_disk_uuid="600508B1001C906D990D2C1D159B1C94"
enm_iso="/tmp/ERICenm_CXP9027091-1.26.29.iso"

# PREPARE RESTORE
num_clusters="1"
num_prepare_restore_tasks="287"

nodes_ip_start="10.44.86.105"
nodes_ip_end="10.44.86.107"
nodes_gateway="$ms_gateway"
nodes_ilo_username="root"
nodes_ilo_password='Amm30n!!'
nodes_gateway_ext="10.44.235.1"

vcs_cluster_id="4805"

# MS VM
ms_vm_835="10.44.86.109"
ms_vm_ipv6_835="fdde:4d7e:d471:0001::0835:105:0101/64"
ms_vm_net1="10.46.85.3"
ms_vm_ipv6_834="fdde:4d7e:d471:0000::0834:105:0101/64"

### vms
net1vm_ip_ms="10.46.85.2"
net1vm_subnet="10.46.85.0/26" # 1 -> 63 - gateway .1
#net1vm_subnet="10.46.85.0/27" # 1 -> 30 - gateway .1 reduced range
net1vm_gw="10.46.85.1"


net2vm_ip_ms="10.46.85.66"
net2vm_subnet="10.46.85.64/26" # 65 -> 127 - gateway .65
net2vm_gw="10.46.85.65"

net3vm_ip_ms="10.46.85.131"
net3vm_subnet="10.46.85.128/26" # 129 -> 190 - gateway .129
net3vm_gw="10.46.85.129"

net4vm_ip_ms="10.46.85.194"
net4vm_subnet="10.46.85.192/26" # 193 -> 254 - gateway .193
net4vm_gw="10.46.85.193"

node_ip[0]="10.44.86.106"
node_ipv6[0]="fdde:4d7e:d471:0001::0835:105:0200/64"
node_sysname[0]="CZJ33308J7"
node_hostname[0]="Node1Dot105"
node_eth0_mac[0]="2C:59:E5:3D:D3:80"
node_eth1_mac[0]="2C:59:E5:3D:D3:84"
node_eth2_mac[0]="2C:59:E5:3D:D3:81"
node_eth3_mac[0]="2C:59:E5:3D:D3:85"
node_eth4_mac[0]="2C:59:E5:3D:D3:82"
node_eth5_mac[0]="2C:59:E5:3D:D3:86"
node_eth6_mac[0]="2C:59:E5:3D:D3:83"
node_eth7_mac[0]="2C:59:E5:3D:D3:87"

node_disk0_uuid[0]="600601602851390095257DD0028BEB11"
node_disk1_uuid[0]="6006016028513900FFF620A5018BEB11"
node_bmc_ip[0]="10.44.84.53"
node_ip_ext[0]="10.44.235.112"
node_ip_bond[0]="10.44.86.180"
node_ip_898[0]="10.44.235.141"
node_ip_836[0]="10.44.86.182"
node_ipv6_834[0]="fdde:4d7e:d471:0000::0834:105:0201/64"
node_ipv6_898[0]="fdde:4d7e:d471:0004::0898:105:0201/64"
node_ipv6_898_nomask[0]="fdde:4d7e:d471:0004::0898:105:0201"
node_ipv6_836[0]="fdde:4d7e:d471:0002::0836:105:0201/64"
node_ipv6_836_nomask[0]="fdde:4d7e:d471:0002::0836:105:0201"
node_ipv6_837[0]="fdde:4d7e:d471:0003::0837:105:0201/64"
traf1_ip[0]="10.19.105.10"
traf2_ip[0]="10.20.105.10"


node_ip[1]="10.44.86.107"
node_ipv6[1]="fdde:4d7e:d471:0001::0835:105:0300/64"
node_sysname[1]="CZJ33308J1"
node_hostname[1]="node2Dot105"
node_eth0_mac[1]="2C:59:E5:3F:34:E8"
node_eth1_mac[1]="2C:59:E5:3F:34:EC"
node_eth2_mac[1]="2C:59:E5:3F:34:E9"
node_eth3_mac[1]="2C:59:E5:3F:34:ED"
node_eth4_mac[1]="2C:59:E5:3F:34:EA"
node_eth5_mac[1]="2C:59:E5:3F:34:EE"
node_eth6_mac[1]="2C:59:E5:3F:34:EB"
node_eth7_mac[1]="2C:59:E5:3F:34:EF"

node_disk0_uuid[1]="6006016028513900D229484D038BEB11"
node_disk1_uuid[1]="6006016028513900BE079329028BEB11"
node_bmc_ip[1]="10.44.84.54"
node_ip_ext[1]="10.44.235.113"
node_ip_bond[1]="10.44.86.181"
node_ip_898[1]="10.44.235.142"
node_ip_836[1]="10.44.86.183"
node_ipv6_834[1]="fdde:4d7e:d471:0000::0834:105:0301/64"
node_ipv6_898[1]="fdde:4d7e:d471:0004::0898:105:0301/64"
node_ipv6_898_nomask[1]="fdde:4d7e:d471:0004::0898:105:0301"
node_ipv6_836[1]="fdde:4d7e:d471:0002::0836:105:0301/64"
node_ipv6_836_nomask[1]="fdde:4d7e:d471:0002::0836:105:0301"
node_ipv6_837[1]="fdde:4d7e:d471:0003::0837:105:0301/64"
traf1_ip[1]="10.19.105.30"
traf2_ip[1]="10.20.105.30"

route834_subnet="10.44.86.0/26"
route836_subnet="10.44.86.128/26"
route837_subnet="10.44.86.192/26"
route835_subnet="10.44.86.64/26" 
route898_subnet="10.44.235.0/24"
route_subnet_801="10.44.84.0/24"

ipv6_835_gateway="fdde:4d7e:d471:1:0:835:0:1"
ipv6_834_gateway="fdde:4d7e:d471:0:0:834:0:1"
ipv6_834_subnet="fdde:4d7e:d471:0000:0000:0834::/64 "

sfs_prefix="/vx/ST105"

# NEW VA SERCVER
sfs_management_ip="10.44.235.29"
sfs_vip="10.44.235.26"
sfs_password="veritas"
sfs_subnet=$route898_subnet
sfs_network=data
ms_ip_sfs=$ms_ip_ext
node_ip_sfs[0]="${node_ip_898[0]}"
node_ip_sfs[1]="${node_ip_898[1]}"


#NFS
nfs_management_ip="10.44.86.212"
nfs_prefix="/home/admin/ST/nfs_share_dir_105"

#VCS
traf1_subnet="10.19.105.0/24"
traf2_subnet="10.20.105.0/24"

#VIPs
traf1_vip[1]="10.19.105.100"
traf1_vip[2]="10.19.105.101"
traf1_vip[3]="10.19.105.102"
traf1_vip[4]="10.19.105.103"
traf1_vip[5]="10.19.105.104"
traf1_vip[6]="10.19.105.105"
traf1_vip[7]="10.19.105.106"
traf1_vip[8]="10.19.105.107"
traf1_vip[9]="10.19.105.108"
traf1_vip[10]="10.19.105.109"
traf1_vip[11]="10.19.105.110"
traf1_vip[12]="10.19.105.111"
traf1_vip[13]="10.19.105.112"
traf1_vip[14]="10.19.105.113"
traf1_vip[15]="10.19.105.114"
traf1_vip[16]="10.19.105.115"
traf1_vip[17]="10.19.105.116"
traf1_vip[18]="10.19.105.117"
traf1_vip[19]="10.19.105.118"
traf1_vip[20]="10.19.105.119"
traf1_vip[21]="10.19.105.120"
traf1_vip[22]="10.19.105.121"
traf1_vip[23]="10.19.105.122"
traf1_vip[24]="10.19.105.123"


traf1_vip_ipv6[1]="fdde:4d7e:d471:19::105:100/64"
traf1_vip_ipv6[2]="fdde:4d7e:d471:19::105:101/64"
traf1_vip_ipv6[3]="fdde:4d7e:d471:19::105:102/64"
traf1_vip_ipv6[4]="fdde:4d7e:d471:19::105:103/64"
traf1_vip_ipv6[5]="fdde:4d7e:d471:19::105:104/64"
traf1_vip_ipv6[6]="fdde:4d7e:d471:19::105:105/64"
traf1_vip_ipv6[7]="fdde:4d7e:d471:19::105:106/64"
traf1_vip_ipv6[8]="fdde:4d7e:d471:19::105:107/64"
traf1_vip_ipv6[9]="fdde:4d7e:d471:19::105:108/64"
traf1_vip_ipv6[10]="fdde:4d7e:d471:19::105:109/64"
traf1_vip_ipv6[11]="fdde:4d7e:d471:19::105:110/64"
traf1_vip_ipv6[12]="fdde:4d7e:d471:19::105:111/64"
traf1_vip_ipv6[13]="fdde:4d7e:d471:19::105:112/64"
traf1_vip_ipv6[14]="fdde:4d7e:d471:19::105:113/64"
traf1_vip_ipv6[15]="fdde:4d7e:d471:19::105:114/64"
traf1_vip_ipv6[16]="fdde:4d7e:d471:19::105:115/64"
traf1_vip_ipv6[17]="fdde:4d7e:d471:19::105:116/64"
traf1_vip_ipv6[18]="fdde:4d7e:d471:19::105:117/64"
traf1_vip_ipv6[19]="fdde:4d7e:d471:19::105:118/64"
traf1_vip_ipv6[20]="fdde:4d7e:d471:19::105:119/64"
traf1_vip_ipv6[21]="fdde:4d7e:d471:19::105:120/64"
traf1_vip_ipv6[22]="fdde:4d7e:d471:19::105:121/64"
traf1_vip_ipv6[23]="fdde:4d7e:d471:19::105:122/64"
traf1_vip_ipv6[24]="fdde:4d7e:d471:19::105:123/64"

traf2_vip[1]="10.20.105.100"
traf2_vip[2]="10.20.105.101"
traf2_vip[3]="10.20.105.102"
traf2_vip[4]="10.20.105.103"
traf2_vip[5]="10.20.105.104"
traf2_vip[6]="10.20.105.105"
traf2_vip[7]="10.20.105.106"
traf2_vip[8]="10.20.105.107"
traf2_vip[9]="10.20.105.108"
traf2_vip[10]="10.20.105.109"
traf2_vip[11]="10.20.105.110"
traf2_vip[12]="10.20.105.111"
traf2_vip[13]="10.20.105.112"
traf2_vip[14]="10.20.105.113"
traf2_vip[15]="10.20.105.114"
traf2_vip[16]="10.20.105.115"
traf2_vip[17]="10.20.105.116"
traf2_vip[18]="10.20.105.117"
traf2_vip[19]="10.20.105.118"
traf2_vip[20]="10.20.105.119"
traf2_vip[21]="10.20.105.120"
traf2_vip[22]="10.20.105.121"
traf2_vip[23]="10.20.105.122"
traf2_vip[24]="10.20.105.123"

traf2_vip_ipv6[1]="fdde:4d7e:d471:20::105:100/64"
traf2_vip_ipv6[2]="fdde:4d7e:d471:20::105:101/64"
traf2_vip_ipv6[3]="fdde:4d7e:d471:20::105:102/64"
traf2_vip_ipv6[4]="fdde:4d7e:d471:20::105:103/64"
traf2_vip_ipv6[5]="fdde:4d7e:d471:20::105:104/64"
traf2_vip_ipv6[6]="fdde:4d7e:d471:20::105:105/64"
traf2_vip_ipv6[7]="fdde:4d7e:d471:20::105:106/64"
traf2_vip_ipv6[8]="fdde:4d7e:d471:20::105:107/64"
traf2_vip_ipv6[9]="fdde:4d7e:d471:20::105:108/64"
traf2_vip_ipv6[10]="fdde:4d7e:d471:20::105:109/64"
traf2_vip_ipv6[11]="fdde:4d7e:d471:20::105:110/64"
traf2_vip_ipv6[12]="fdde:4d7e:d471:20::105:111/64"
traf2_vip_ipv6[13]="fdde:4d7e:d471:20::105:112/64"
traf2_vip_ipv6[14]="fdde:4d7e:d471:20::105:113/64"
traf2_vip_ipv6[15]="fdde:4d7e:d471:20::105:114/64"
traf2_vip_ipv6[16]="fdde:4d7e:d471:20::105:115/64"
traf2_vip_ipv6[17]="fdde:4d7e:d471:20::105:116/64"
traf2_vip_ipv6[18]="fdde:4d7e:d471:20::105:117/64"
traf2_vip_ipv6[19]="fdde:4d7e:d471:20::105:118/64"
traf2_vip_ipv6[20]="fdde:4d7e:d471:20::105:119/64"
traf2_vip_ipv6[21]="fdde:4d7e:d471:20::105:120/64"
traf2_vip_ipv6[22]="fdde:4d7e:d471:20::105:121/64"
traf2_vip_ipv6[23]="fdde:4d7e:d471:20::105:122/64"
traf2_vip_ipv6[24]="fdde:4d7e:d471:20::105:123/64"

#vxvm
vxvm1_disk_uuid=600601602851390019CA12AD038BEB11
vxvm2_disk_uuid=6006016028513900BC279AF1038BEB11
vxvm3_disk_uuid=6006016028513900363B553C048BEB11
vxvm4_disk_uuid=60060160285139000C03B137088BEB11
vxvm5_disk_uuid=600601602851390009B8EBA0088BEB11
vxvm6_disk_uuid=6006016028513900FA57440D0A8BEB11
vxvm7_disk_uuid=600601602851390053AB54F40A8BEB11

#fencing
fen1_disk_uuid=600601602851390035DED75E0B8BEB11
fen2_disk_uuid=6006016028513900712AD2920B8BEB11
fen3_disk_uuid=6006016028513900D3D978FF0B8BEB11

ntp_alias="10.44.86.212"

#vm
vm_mgmt_ips="10.44.86.80,10.44.86.81"
copytestfile1="http://10.44.235.150/st/vm-images/vm_test_image-1.0.37.qcow2:/var/www/html/images/image_customscript.qcow2"
# Used in plan soak
copytestfile20="http://10.44.235.150/cdb/vm_test_image-1-1.0.3.qcow2:/var/www/html/images/RHEL_7_image.qcow2"
# Used in plan soak
copytestfile21="http://10.44.235.150/cdb/vm_test_image-2-1.0.4.qcow2:/var/www/html/images/RHEL_6_image.qcow2"
# custom script
copytestfile22="http://10.44.235.150/st/vm-images/cscript_crontab.sh:/var/www/html/vm_scripts/cscript_crontab.sh"
copytestfile23="http://10.44.235.150/st/vm-images/cscript_crontab.sh:/var/www/html/vm_scripts/cscript1_crontab.sh"

VM_net1vm_ip[0]="10.46.85.10"
VM_net1vm_ip[1]="10.46.85.11"
VM_net1vm_ip[2]="10.46.85.12"
VM_net1vm_ip[3]="10.46.85.13"
VM_net1vm_ip[4]="10.46.85.14"
VM_net1vm_ip[5]="10.46.85.15"
# 10.46.85.106 reserved for plan soak

net1vm_ip6_ms=fdde:4d7e:d471:10:105::99
VM_net1vm_ip6[0]=fdde:4d7e:d471:10:105::100
VM_net1vm_ip6[1]=fdde:4d7e:d471:10:105::101
VM_net1vm_ip6[2]=fdde:4d7e:d471:10:105::102/64
# fdde:4d7e:d471:10:105::106/64 reserved for plan soak
# fdde:4d7e:d471:10:105::107/64 reserved for plan soak

VM_net834_ip6=fdde:4d7e:d471:0000::0834:105:401/64

#cleanup
sfs_cleanup_list="10.44.235.30:master:veritas:/vx/ST105-managed1=10.44.235.111,/vx/ST105-managed1=10.44.235.141,/vx/ST105-managed1=10.44.235.143,/vx/ST105-managed1=10.44.235.142:ST105-managed1__BREAK__10.44.235.30:master:veritas:/vx/ST105-managed2=10.44.235.0/24,/vx/ST105-managed2=10.44.235.111,/vx/ST105-managed2=10.44.235.141,/vx/ST105-managed2=10.44.235.142,/vx/ST105-managed2=10.44.235.143:ST105-managed2__BREAK__10.44.235.30:master:veritas:/vx/ST105-managed1=10.44.235.111,/vx/ST105-managed1=10.44.235.141,/vx/ST105-managed1=10.44.235.142,/vx/ST105-managed1=10.44.235.143:ST105-managed1__BREAK__10.44.235.30:master:veritas:/vx/ST105-managed3=10.44.235.0/24,/vx/ST105-managed3=10.44.235.111,/vx/ST105-managed3=10.44.235.141,/vx/ST105-managed3=10.44.235.142,/vx/ST105-managed3=10.44.235.143:ST105-managed3__BREAK__10.44.235.30:master:veritas:/vx/ST105Pool2_managed1=10.44.235.111,/vx/ST105Pool2_managed1=10.44.235.141,/vx/ST105Pool2_managed1=10.44.235.142,/vx/ST105Pool2_managed1=10.44.235.143:ST105Pool2_managed1__BREAK__10.44.235.30:master:veritas:/vx/ST105Pool3_managed1=10.44.235.111,/vx/ST105Pool3_managed1=10.44.235.141,/vx/ST105Pool3_managed1=10.44.235.142,/vx/ST105Pool3_managed1=10.44.235.143:ST105Pool3_managed1"
sfs_snapshot_cleanup_list="10.44.235.30:master:veritas:L_ST105-managed1_=ST105-managed1,L_ST105-managed1_soak=ST105-managed1,L_ST105-managed2_=ST105-managed2,L_ST105-managed2_soak=ST105-managed2,L_ST105-managed3_=ST105-managed3,L_ST105-managed3_soak=ST105-managed3,L_ST105Pool2_managed1_=ST105Pool2_managed1,L_ST105Pool2_managed1_soak=ST105Pool2_managed1,L_ST105Pool3_managed1_=ST105Pool3_managed1,L_ST105Pool3_managed1_soak=ST105Pool3_managed1:105cache1"

# Multiple services
copytestfile2="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper1-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper1-2.0.0.rpm"
copytestfile3="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper2-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper2-2.0.0.rpm"
copytestfile4="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper3-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper3-2.0.0.rpm"
copytestfile5="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper4-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper4-2.0.0.rpm"
copytestfile6="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper5-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper5-2.0.0.rpm"
copytestfile7="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper6-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper6-2.0.0.rpm"
copytestfile8="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper7-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper7-2.0.0.rpm"
copytestfile9="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper8-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper8-2.0.0.rpm"
copytestfile10="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper9-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper9-2.0.0.rpm"
copytestfile11="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper10-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper10-2.0.0.rpm"
copytestfile12="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper11-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper11-2.0.0.rpm"
copytestfile60="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper12-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper12-2.0.0.rpm"
copytestfile61="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper13-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper13-2.0.0.rpm"

# test packages
copytestfile13="http://10.44.235.150/st/example_apps/3PP-irish-hello-1.0.0-1.noarch.rpm:/tmp/3PP-irish-hello-1.0.0-1.noarch.rpm"
copytestfile14="http://10.44.235.150/st/test-plugins/mkdir.repo.exp:/tmp/mkdir.repo.exp"

copytestfile30="http://10.44.235.150/st/example_apps/3PP-german-hello-1.0.0-1.noarch.rpm:/tmp/3PP-german-hello-1.0.0-1.noarch.rpm"
copytestfile31="http://10.44.235.150/st/example_apps/3PP-czech-hello-1.0.0-1.noarch.rpm:/tmp/3PP-czech-hello-1.0.0-1.noarch.rpm"
copytestfile32="http://10.44.235.150/st/example_apps/3PP-dutch-hello-1.0.0-1.noarch.rpm:/tmp/3PP-dutch-hello-1.0.0-1.noarch.rpm"
copytestfile33="http://10.44.235.150/st/example_apps/3PP-english-hello-1.0.0-1.noarch.rpm:/tmp/3PP-english-hello-1.0.0-1.noarch.rpm"
copytestfile34="http://10.44.235.150/st/example_apps/3PP-french-hello-1.0.0-1.noarch.rpm:/tmp/3PP-french-hello-1.0.0-1.noarch.rpm"
copytestfile35="http://10.44.235.150/st/example_apps/3PP-italian-hello-1.0.0-1.noarch.rpm:/tmp/3PP-italian-hello-1.0.0-1.noarch.rpm"
copytestfile36="http://10.44.235.150/st/example_apps/3PP-klingon-hello-1.0.0-1.noarch.rpm:/tmp/3PP-klingon-hello-1.0.0-1.noarch.rpm"
copytestfile37="http://10.44.235.150/st/example_apps/3PP-polish-hello-1.0.0-1.noarch.rpm:/tmp/3PP-polish-hello-1.0.0-1.noarch.rpm"
copytestfile38="http://10.44.235.150/st/example_apps/3PP-portuguese-hello-1.0.0-1.noarch.rpm:/tmp/3PP-portuguese-hello-1.0.0-1.noarch.rpm"
copytestfile39="http://10.44.235.150/st/example_apps/3PP-portuguese-hungarian-slovak-hello-1.0.0-1.noarch.rpm:/tmp/3PP-portuguese-hungarian-slovak-hello-1.0.0-1.noarch.rpm"
copytestfile40="http://10.44.235.150/st/example_apps/3PP-romanian-hello-1.0.0-1.noarch.rpm:/tmp/3PP-romanian-hello-1.0.0-1.noarch.rpm"
copytestfile41="http://10.44.235.150/st/example_apps/3PP-russian-hello-1.0.0-1.noarch.rpm:/tmp/3PP-russian-hello-1.0.0-1.noarch.rpm"
copytestfile42="http://10.44.235.150/st/example_apps/3PP-serbian-hello-1.0.0-1.noarch.rpm:/tmp/3PP-serbian-hello-1.0.0-1.noarch.rpm"
copytestfile43="http://10.44.235.150/st/example_apps/3PP-spanish-hello-1.0.0-1.noarch.rpm:/tmp/3PP-spanish-hello-1.0.0-1.noarch.rpm"
copytestfile44="http://10.44.235.150/st/example_apps/3PP-swedish-hello-1.0.0-1.noarch.rpm:/tmp/3PP-swedish-hello-1.0.0-1.noarch.rpm"
copytestfile45="http://10.44.235.150/st/example_apps/3PP-finnish-hello-1.0.0-1.noarch.rpm:/tmp/3PP-finnish-hello-1.0.0-1.noarch.rpm"

#### Service Plugin
copytestfile50="http://10.44.235.150/st/test-packages/diff_name_srvc/test_service_name-2.0-1.noarch.rpm:/tmp/test_service_name-2.0-1.noarch.rpm"

copytestfile51="http://10.44.235.150/st/test-plugins/litpcds10650plugins.tar.gz:/tmp/litpcds10650plugins.tar.gz"
copytestfile52="http://10.44.235.150/st/test-plugins/litpcds10650_plugin_install.sh:/tmp/litpcds10650_plugin_install.sh"
copytestfile53="http://10.44.235.150/st/test-plugins/root_run_script.exp:/tmp/root_run_script.exp"

##### Test Plugin
copytestfile54="http://10.44.235.150/st/test-plugins/ERIClitpmassive_phase_CXP1234567-1.0.1-SNAPSHOT20170118111648.noarch.rpm:/tmp/ERIClitpmassive_phase_CXP1234567-1.0.1-SNAPSHOT20170118111648.noarch.rpm"


