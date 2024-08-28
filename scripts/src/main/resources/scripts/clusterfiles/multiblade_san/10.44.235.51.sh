#!/bin/bash

blade_type="G8"

ms_ilo_ip="10.44.84.132"
ms_ilo_username="root"
ms_ilo_password='Amm30n!!'
ms_ip="10.44.235.51"
ms_ip_ext="10.44.86.170"
ms_subnet="10.44.235.0/24"
ms_gateway="10.44.235.1"
ms_gateway_ext="10.44.86.129"

ms_host="ms1dot51"
ms_eth0_mac="2C:59:E5:3D:B3:B0"
ms_eth1_mac="2C:59:E5:3D:B3:B4"
ms_eth2_mac="2C:59:E5:3D:B3:B1"
ms_eth3_mac="2C:59:E5:3D:B3:B5"

ms_sysname="CZJ33308HS"
vcs_cluster_id="5051"
cluster_id="5051"
ms_disk_0_uuid="600508b1001cf4cad57b7cf9f80a06b7"
ms_vlan=""

ms_ip_898_bond="10.44.235.51"
ms_ip_836_bond="10.44.86.170"
ms_ip_898="10.44.235.72"
ms_ip_834="10.44.86.5"
ms_ip_835="10.44.86.69"
ms_ip_836="10.44.86.173"
ms_ip_837="10.44.86.195"
ms_ipv6_898_bond="fdde:4d7e:d471:0004::0898:51:100/64"
ms_ipv6_898="fdde:4d7e:d471:0004::0898:51:103/64"
ms_ipv6_834="fdde:4d7e:d471:0000::0834:51:100/64"
ms_ipv6_835="fdde:4d7e:d471:0001::0835:51:100/64"
ms_ipv6_836_bond="fdde:4d7e:d471:0002::0836:51:0100/64"
ms_ipv6_836="fdde:4d7e:d471:0002::0836:51:0103/64"
ms_ipv6_837="fdde:4d7e:d471:0003::0837:51:0100/64"

ipv6_898_tp="fdde:4d7e:d471:4::898:51:a"

# PREPARE RESTORE
num_clusters="1"
num_prepare_restore_tasks="450"

# Config for VMs
net1vm_ip_ms="10.46.81.2"
net1vm_subnet="10.46.81.0/26" # 1 -> 63 - gateway .1
net1vm_gw[0]="10.46.81.1"

ms_vm_ip_834="10.44.86.9"
ms_vm_ip_net1vm="10.46.81.5"

#node1
net1vm_ip[0]="10.46.81.44" #br333 for node1
net2vm_ip[0]="10.46.81.68" #br444 for node1
net3vm_ip[0]="10.46.81.132" #br555 for node1
net4vm_ip[0]="10.46.81.195" #br665 for node1
netipv6vm_ip[0]=fdde:4d7e:d471:51::100/64
netipv6vm_ip_nhs[0]=fdde:4d7e:d471:51::100

#node2
net1vm_ip[1]="10.46.81.45" #br333 for node2
net2vm_ip[1]="10.46.81.69" #br444 for node2
net3vm_ip[1]="10.46.81.133" #br555 for node2
net4vm_ip[1]="10.46.81.196" #br665 for node2
netipv6vm_ip[1]=fdde:4d7e:d471:51::200/64
netipv6vm_ip_nhs[1]=fdde:4d7e:d471:51::200

net2vm_ip_ms="10.46.81.66"
net2vm_subnet="10.46.81.64/26" # 65 -> 127 - gateway .65
net2vm_gw[0]="10.46.81.65"

net3vm_ip_ms="10.46.81.131"
net3vm_subnet="10.46.81.128/26" # 129 -> 190 - gateway .129
net3vm_gw[0]="10.46.81.129"

net4vm_ip_ms="10.46.81.194"
net4vm_subnet="10.46.81.192/26" # 193 -> 254 - gateway .193
net4vm_gw[0]="10.46.81.193"

### ipv6 private network
ipv61_subnet="fdde:4d7e:d471:51:0000:0000::/64"
ipv61_gateway="fdde:4d7e:d471:51:0:0:0:1"
ipv6_834_gateway="fdde:4d7e:d471:0:0:834:0:1"
net1vm_ipv6_vm1=fdde:4d7e:d471:51::300/64
net1vm_ipv6_vm2=fdde:4d7e:d471:51::400/64


copytestfile1="http://10.44.235.150/st/vm-images/vm_rhel_7_test_image-1-3.0.1.qcow2:/var/www/html/images/rhel_7_image.qcow2"
copytestfile2="http://10.44.235.150/st/test-plugins/ERIClitptag_CXP1234567-1.0.1-SNAPSHOT20151014152125.noarch.rpm:/tmp/ERIClitptag_CXP1234567-1.0.1-SNAPSHOT20151014152125.noarch.rpm"
copytestfile3="http://10.44.235.150/st/test-plugins/ERIClitptagapi_CXP1234567-1.0.1-SNAPSHOT20160205115231.noarch.rpm:/tmp/ERIClitptagapi_CXP1234567-1.0.1-SNAPSHOT20160205115231.noarch.rpm"
copytestfile4="http://10.44.235.150/st/test-plugins/ERIClitpsan_CXP9030786-1.16.1.rpm:/tmp/ERIClitpsan_CXP9030786-1.16.1.rpm"
copytestfile5="http://10.44.235.150/st/test-plugins/ERIClitpsanapi_CXP9030787-1.8.1.rpm:/tmp/ERIClitpsanapi_CXP9030787-1.8.1.rpm"
copytestfile6="http://10.44.235.150/st/test-plugins/ERIClitpsanemc_CXP9030788-1.13.2.rpm:/tmp/ERIClitpsanemc_CXP9030788-1.13.2.rpm"
copytestfile14="http://10.44.235.150/st/test-plugins/root_yum_install_pkg.exp:/tmp/root_yum_install_pkg.exp"
copytestfile31="http://10.44.235.150/st/example_apps/3PP-azerbaijani-in-ear-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-azerbaijani-in-ear-1.0.0-1.noarch.rpm"
copytestfile32="http://10.44.235.150/st/example_apps/3PP-czech-hello-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-czech-hello-1.0.0-1.noarch.rpm"
copytestfile33="http://10.44.235.150/st/example_apps/3PP-dutch-hello-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-dutch-hello-1.0.0-1.noarch.rpm"
copytestfile34="http://10.44.235.150/st/example_apps/3PP-ejb-in-ear-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-ejb-in-ear-1.0.0-1.noarch.rpm"
copytestfile35="http://10.44.235.150/st/example_apps/3PP-english-hello-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-english-hello-1.0.0-1.noarch.rpm"
copytestfile36="http://10.44.235.150/st/example_apps/3PP-esperanto-in-ear-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-esperanto-in-ear-1.0.0-1.noarch.rpm"
copytestfile37="http://10.44.235.150/st/example_apps/3PP-finnish-hello-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-finnish-hello-1.0.0-1.noarch.rpm"
copytestfile38="http://10.44.235.150/st/example_apps/3PP-french-hello-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-french-hello-1.0.0-1.noarch.rpm"
copytestfile39="http://10.44.235.150/st/example_apps/3PP-french-in-ear-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-french-in-ear-1.0.0-1.noarch.rpm"
copytestfile41="http://10.44.235.150/st/example_apps/3PP-german-hello-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-german-hello-1.0.0-1.noarch.rpm"
copytestfile42="http://10.44.235.150/st/example_apps/3PP-german-in-ear-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-german-in-ear-1.0.0-1.noarch.rpm"
copytestfile43="http://10.44.235.150/st/example_apps/3PP-helloworld-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-helloworld-1.0.0-1.noarch.rpm"
copytestfile44="http://10.44.235.150/st/example_apps/3PP-hungarian-in-ear-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-hungarian-in-ear-1.0.0-1.noarch.rpm"
copytestfile45="http://10.44.235.150/st/example_apps/3PP-irish-hello-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-irish-hello-1.0.0-1.noarch.rpm"
copytestfile46="http://10.44.235.150/st/example_apps/3PP-irish-in-ear-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-irish-in-ear-1.0.0-1.noarch.rpm"
copytestfile47="http://10.44.235.150/st/example_apps/3PP-italian-hello-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-italian-hello-1.0.0-1.noarch.rpm"
copytestfile48="http://10.44.235.150/st/example_apps/3PP-italian-in-ear-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-italian-in-ear-1.0.0-1.noarch.rpm"
copytestfile49="http://10.44.235.150/st/example_apps/3PP-klingon-hello-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-klingon-hello-1.0.0-1.noarch.rpm"
copytestfile50="http://10.44.235.150/st/example_apps/3PP-norwegian-in-ear-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-norwegian-in-ear-1.0.0-1.noarch.rpm"
copytestfile51="http://10.44.235.150/st/example_apps/3PP-polish-hello-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-polish-hello-1.0.0-1.noarch.rpm"
copytestfile52="http://10.44.235.150/st/example_apps/3PP-portuguese-hello-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-portuguese-hello-1.0.0-1.noarch.rpm"
copytestfile53="http://10.44.235.150/st/example_apps/3PP-portuguese-hungarian-slovak-hello-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-portuguese-hungarian-slovak-hello-1.0.0-1.noarch.rpm"
copytestfile54="http://10.44.235.150/st/example_apps/3PP-romanian-hello-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-romanian-hello-1.0.0-1.noarch.rpm"
copytestfile55="http://10.44.235.150/st/example_apps/3PP-russian-hello-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-russian-hello-1.0.0-1.noarch.rpm"
copytestfile56="http://10.44.235.150/st/example_apps/3PP-serbian-hello-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-serbian-hello-1.0.0-1.noarch.rpm"
copytestfile57="http://10.44.235.150/st/example_apps/3PP-slovak-in-ear-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-slovak-in-ear-1.0.0-1.noarch.rpm"
copytestfile58="http://10.44.235.150/st/example_apps/3PP-spanish-hello-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-spanish-hello-1.0.0-1.noarch.rpm"
copytestfile59="http://10.44.235.150/st/example_apps/3PP-spanish-in-ear-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-spanish-in-ear-1.0.0-1.noarch.rpm"
copytestfile70="http://10.44.235.150/st/example_apps/3PP-swedish-hello-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-swedish-hello-1.0.0-1.noarch.rpm"
copytestfile71="http://10.44.235.150/st/test-packages/diff_name_srvc/test_service_name-2.0-1.noarch.rpm:/var/www/html/3pp/test_service_name-2.0-1.noarch.rpm"
copytestfile1="http://10.44.235.150/st/vm-images/test_image-1.0.37.qcow2:/var/www/html/images/rhel_6_image.qcow2"

# ENM FILES
# this is used to copy over the ENM ISO and needs to be updated if changing the ENM ISO
#copytestfile71="/ST/enm-iso/ERICenm_CXP9027091-1.21.16.iso:/tmp/ERICenm_CXP9027091-1.26.29.iso"
# this is the XML used to create all the package and package list items under /software
#copytestfile71="/ST/enm-iso/enm_package_2.xml:/tmp/enm_package_2.xml"
# bash script that handles the import the ENM ISO and polling maintenace mode to see when it completes
#copytestfile72="/ST/enm-iso/import_iso.sh:/tmp/import_iso.sh"
# expect script to run the import_iso.sh script as root - it also removes a plugin using yum that causes restore_snapshot to break
#copytestfile73="/ST/enm-iso/root_import_iso.exp:/tmp/root_import_iso.exp"
# variable used by the expect script to import the ISO - needs to be updated if changing the ENM ISO
#enm_iso="/tmp/ERICenm_CXP9027091-1.21.16.iso"
#enm_iso="/tmp/ERICenm_CXP9027091-1.26.29.iso"
#copytestfile74="/ST/enm-iso/ERICenm_CXP9027091-1.26.29.iso:/tmp/ERICenm_CXP9027091-1.26.29.iso"


# vm-image used in expansion deployment
copytestfile75="/ST/vm-images/image_with_ocf_v1_26.qcow2:/var/www/html/images/image.qcow2"

copytestfile76="/ISO/package-test/test_service-1.0-1.noarch.rpm:/tmp/test_service-1.0-1.noarch.rpm"
copytestfile77="/ISO/package-test/test_service-2.0-1.noarch.rpm:/var/www/html/newRepo_dir/test_service-2.0-1.noarch.rpm"

### subnets
netwrk834="10.44.86.0/26"
netwrk835="10.44.86.64/26"
netwrk836="10.44.86.128/26"
netwrk837="10.44.86.192/26"
netwrk898="10.44.235.0/24"

### gateways
gateway_898="10.44.235.1"
gateway_834="10.44.86.1"
gateway_835="10.44.86.65"
gateway_836="10.44.86.129"
gateway_837="10.44.86.193"

nodes_gateway="$ms_gateway"
#nodes_gateway_ext="10.44.86.129"
nodes_gateway_ext="10.44.86.65"
nodes_ilo_password='Amm30n!!'

ipv6_835_gateway="fdde:4d7e:d471:1:0:835:0:1"
ipv6_834_gateway="fdde:4d7e:d471:0:0:834:0:1"
ipv6_836_subnet="fdde:4d7e:d471:0002::0836:0:0/64"

# MN1
node_ip[0]="10.44.235.52"
sanity_node_ip_check[0]="10.44.86.6"
node_ip_898_bond[0]="10.44.235.52"
node_ip_836_bond[0]="10.44.86.171"
node_ip_834[0]="10.44.86.6"
node_ip_835[0]="10.44.86.70"
node_ip_836[0]="10.44.86.174"
node_ip_837[0]="10.44.86.196"
node_ip_898[0]="10.44.235.73"
node_ipv6_898_bond[0]="fdde:4d7e:d471:0004::0898:51:0200/64"
node_ipv6_898[0]="fdde:4d7e:d471:0004::0898:51:0204/64"
node_ipv6_834[0]="fdde:4d7e:d471:0000::0834:51:0200/64"
node_ipv6_835[0]="fdde:4d7e:d471:0001::0835:51:0200/64"
node_ipv6_836_bond[0]="fdde:4d7e:d471:0002::0836:51:0200/64"
node_ipv6_836_bond_nhs[0]="fdde:4d7e:d471:0002::0836:51:0200"
node_ipv6_836[0]="fdde:4d7e:d471:0002::0836:51:0204/64"
node_ipv6_837[0]="fdde:4d7e:d471:0003::0837:51:0200/64"

traf1_ip[0]="10.19.51.10"
traf2_ip[0]="10.20.51.10"
node_ip_sg1[0]="10.19.51.2"
node_ip_sg2[0]="10.20.51.5"
node_ip_sg3[0]="10.20.51.6"
node_sysname[0]="CZJ33308HK"
node_hostname[0]="node1dot51"
node_eth0_mac[0]="2C:59:E5:3D:F2:08"
node_eth1_mac[0]="2C:59:E5:3D:F2:0C"
node_eth2_mac[0]="2C:59:E5:3D:F2:09"
node_eth3_mac[0]="2C:59:E5:3D:F2:0D"
node_eth4_mac[0]="2C:59:E5:3D:F2:0A"
node_eth5_mac[0]="2C:59:E5:3D:F2:0E"
node_eth6_mac[0]="2C:59:E5:3D:F2:0B"
node_eth7_mac[0]="2C:59:E5:3D:F2:0F"

node_disk_uuid0[0]="600601602030330054899af1cf06e611" #LITP_Site1Int51_MN1_Lun72
node_disk_uuid1[0]="6006016020303300240e1d83d006e611" #LITP_Site1Int51_MN1_Lun73
node_disk_uuid2[0]="60060160203033005c6a1b68d106e611" #LITP_Site1Int51_MN1_Lun74

node_bmc_ip[0]="10.44.84.133"

traf1_ipv6[0]="fdde:4d7e:d471:19::51:10/64"
traf2_ipv6[0]="fdde:4d7e:d471:20::51:10/64"


# MN2
node_ip[1]="10.44.235.53"
sanity_node_ip_check[1]="10.44.86.7"
node_ip_898_bond[1]="10.44.235.53"
node_ip_836_bond[1]="10.44.86.172"
node_ip_834[1]="10.44.86.7"
node_ip_835[1]="10.44.86.71"
node_ip_836[1]="10.44.86.175"
node_ip_837[1]="10.44.86.197"
node_ip_898[1]="10.44.235.74"

node_ipv6_898_bond[1]="fdde:4d7e:d471:0004::0898:51:0300/64"
node_ipv6_898[1]="fdde:4d7e:d471:0004::0898:51:0304/64"
node_ipv6_834[1]="fdde:4d7e:d471:0000::0834:51:0300/64"
node_ipv6_835[1]="fdde:4d7e:d471:0001::0835:51:0300/64"
node_ipv6_836_bond[1]="fdde:4d7e:d471:0002::0836:51:0300/64"
node_ipv6_836_bond_nhs[1]="fdde:4d7e:d471:0002::0836:51:0300"
node_ipv6_836[1]="fdde:4d7e:d471:0002::0836:51:0304/64"
node_ipv6_837[1]="fdde:4d7e:d471:0003::0837:51:0300/64"

traf1_ip[1]="10.19.51.20"
traf2_ip[1]="10.20.51.20"
node_ip_sg1[1]="10.19.51.3"
node_ip_sg2[1]="10.20.51.7"
node_ip_sg3[1]="10.20.51.8"
node_sysname[1]="CZJ33308HL"
node_hostname[1]="node2dot51"
node_eth0_mac[1]="2C:59:E5:3D:93:70"
node_eth1_mac[1]="2C:59:E5:3D:93:74"
node_eth2_mac[1]="2C:59:E5:3D:93:71"
node_eth3_mac[1]="2C:59:E5:3D:93:75"
node_eth4_mac[1]="2C:59:E5:3D:93:72"
node_eth5_mac[1]="2C:59:E5:3D:93:76"
node_eth6_mac[1]="2C:59:E5:3D:93:73"
node_eth7_mac[1]="2C:59:E5:3D:93:77"

node_disk_uuid0[1]="60060160203033007c0809c7d506e611" #LITP_Site1Int51_MN2_Lun78
node_disk_uuid1[1]="6006016020303300a87b5517d606e611" #LITP_Site1Int51_MN2_Lun79
node_disk_uuid2[1]="600601602030330066b2685fd606e611" #LITP_Site1Int51_MN2_Lun80

node_bmc_ip[1]="10.44.84.134"

traf1_ipv6[1]="fdde:4d7e:d471:19::51:20/64"
traf2_ipv6[1]="fdde:4d7e:d471:20::51:20/64"

ntp_ip[1]="10.44.86.30"
ntp_ip[2]="127.127.1.0"

route2_subnet="10.44.86.0/26"
route3_subnet="10.44.86.64/26"
route4_subnet="10.44.86.192/26"
route_subnet_801="10.44.84.0/24"

#VXVM
vxvm_disk_uuid1="60060160203033009ead26e1d106e611" #LITP_Site1Int51_MN1-2_Lun75
vxvm_disk_uuid2="600601602030330038382a68d206e611" #LITP_Site1Int51_MN1-2_Lun76
vxvm_disk_uuid3="6006016020303300a07f3857d506e611" #LITP_Site1Int51_MN1-2_Lun77

#Fencing
fencing_disk_uuid1="6006016020303300a031289ed162e611" #LITP_Site1Int51_MN1-2_Lun100_100
fencing_disk_uuid2="6006016020303300a231289ed162e611" #LITP_Site1Int51_MN1-2_Lun100_101
fencing_disk_uuid3="6006016020303300a431289ed162e611" #LITP_Site1Int51_MN1-2_Lun100_102

#NAS
sfs_prefix="/vx/ST51"
sfs_cache="ST51-cache"

# NEW VA SERVER
sfs1_management_ip="10.44.235.29"
sfs1_vip="10.44.235.26"
sfs_password="veritas"
sfs_network=mgmt
ms_ip_sfs=$ms_ip
node_ip_sfs[0]="${node_ip[0]}"
node_ip_sfs[1]="${node_ip[1]}"
sfs_snapshot_cleanup_list="10.44.235.30:master:veritas:L_ST51-managed1_=ST51-managed1,L_ST51-managed2_=ST51-managed2,L_ST51_pl1_xtra_sfs_fs1_=ST51_pl1_xtra_sfs_fs1,L_ST51_pl1_xtra_sfs_fs2_=ST51_pl1_xtra_sfs_fs2,L_ST51-managed1_X=ST51-managed1,L_ST51-managed2_X=ST51-managed2,L_ST51_pl1_xtra_sfs_fs1_X=ST51_pl1_xtra_sfs_fs1,L_ST51_pl1_xtra_sfs_fs2_X=ST51_pl1_xtra_sfs_fs2:ST51-cache"
sfs_cleanup_list="10.44.235.30:master:veritas:/vx/ST51-managed1=10.44.235.51,/vx/ST51-managed1=10.44.235.52,/vx/ST51-managed1=10.44.235.53:ST51-managed1__BREAK__10.44.235.30:master:veritas:/vx/ST51-managed2=10.44.235.51,/vx/ST51-managed2=10.44.235.52,/vx/ST51-managed2=10.44.235.53:ST51-managed2"


# OLD SFS SERVER
#sfs1_management_ip="10.44.86.231"
#sfs1_vip="10.44.86.230"
#sfs_password="support"
#sfs_network=netwrk837
#ms_ip_sfs=$ms_ip_837
#node_ip_sfs[0]="${node_ip_837[0]}"
#node_ip_sfs[1]="${node_ip_837[1]}"
#sfs_snapshot_cleanup_list="10.44.86.231:master:master:L_ST51-managed1_=ST51-managed1,L_ST51-managed2_=ST51-managed2,L_ST51_pl1_xtra_sfs_fs1_=ST51_pl1_xtra_sfs_fs1,L_ST51_pl1_xtra_sfs_fs2_=ST51_pl1_xtra_sfs_fs2,L_ST51-managed1_X=ST51-managed1,L_ST51-managed2_X=ST51-managed2,L_ST51_pl1_xtra_sfs_fs1_X=ST51_pl1_xtra_sfs_fs1,L_ST51_pl1_xtra_sfs_fs2_X=ST51_pl1_xtra_sfs_fs2:ST51-cache"
#sfs_cleanup_list="10.44.86.231:master:master:/vx/ST51-managed1=10.44.86.195,/vx/ST51-managed1=10.44.86.196,/vx/ST51-managed1=10.44.86.197:ST51-managed1__BREAK__10.44.86.231:master:master:/vx/ST51-managed2=10.44.86.195,/vx/ST51-managed2=10.44.86.196,/vx/ST51-managed2=10.44.86.197:ST51-managed2"


#NFS storage
nfs_management_ip="10.44.86.14"
nfs_prefix="/home/admin/ST/nfs_share_dir_51"

#VCS
traf1_subnet="10.19.51.0/24"
traf2_subnet="10.20.51.0/24"
traf1gw_subnet="10.51.19.0/24"
traf2gw_subnet="10.51.20.0/24"

#VM IPs
ipv61_vm1="fdde:4d7e:d471:51::201/64"
ipv61_vm2="fdde:4d7e:d471:51::202/64" 

#VIPs
traf1_vip[1]="10.19.51.100"
traf1_vip[2]="10.19.51.101"
traf1_vip[3]="10.19.51.102"
traf1_vip[4]="10.19.51.103"
traf1_vip[5]="10.19.51.104"
traf1_vip[6]="10.19.51.105"
traf1_vip[7]="10.19.51.106"
traf1_vip[8]="10.19.51.107"
traf1_vip[9]="10.19.51.108"
traf1_vip[10]="10.19.51.109"
traf1_vip[11]="10.19.51.110"
traf1_vip[12]="10.19.51.111"
traf1_vip[13]="10.19.51.112"
traf1_vip[14]="10.19.51.113"
traf1_vip[15]="10.19.51.114"
traf1_vip[16]="10.19.51.115"
traf1_vip[17]="10.19.51.116"
traf1_vip[18]="10.19.51.117"
traf1_vip[19]="10.19.51.118"
traf1_vip[20]="10.19.51.119"
traf1_vip[21]="10.19.51.120"
traf1_vip[22]="10.19.51.121"
traf1_vip[23]="10.19.51.122"
traf1_vip[24]="10.19.51.123"

traf1_vip_ipv6[1]="fdde:4d7e:d471:19::51:100/64"
traf1_vip_ipv6[2]="fdde:4d7e:d471:19::51:101/64"
traf1_vip_ipv6[3]="fdde:4d7e:d471:19::51:102/64"
traf1_vip_ipv6[4]="fdde:4d7e:d471:19::51:103/64"
traf1_vip_ipv6[5]="fdde:4d7e:d471:19::51:104/64"
traf1_vip_ipv6[6]="fdde:4d7e:d471:19::51:105/64"
traf1_vip_ipv6[7]="fdde:4d7e:d471:19::51:106/64"
traf1_vip_ipv6[8]="fdde:4d7e:d471:19::51:107/64"
traf1_vip_ipv6[9]="fdde:4d7e:d471:19::51:108/64"
traf1_vip_ipv6[10]="fdde:4d7e:d471:19::51:109/64"
traf1_vip_ipv6[11]="fdde:4d7e:d471:19::51:110/64"
traf1_vip_ipv6[12]="fdde:4d7e:d471:19::51:111/64"
traf1_vip_ipv6[13]="fdde:4d7e:d471:19::51:112/64"
traf1_vip_ipv6[14]="fdde:4d7e:d471:19::51:113/64"
traf1_vip_ipv6[15]="fdde:4d7e:d471:19::51:114/64"
traf1_vip_ipv6[16]="fdde:4d7e:d471:19::51:115/64"
traf1_vip_ipv6[17]="fdde:4d7e:d471:19::51:116/64"
traf1_vip_ipv6[18]="fdde:4d7e:d471:19::51:117/64"
traf1_vip_ipv6[19]="fdde:4d7e:d471:19::51:118/64"
traf1_vip_ipv6[20]="fdde:4d7e:d471:19::51:119/64"
traf1_vip_ipv6[21]="fdde:4d7e:d471:19::51:120/64"
traf1_vip_ipv6[22]="fdde:4d7e:d471:19::51:121/64"
traf1_vip_ipv6[23]="fdde:4d7e:d471:19::51:122/64"
traf1_vip_ipv6[24]="fdde:4d7e:d471:19::51:123/64"

traf2_vip[1]="10.20.51.100"
traf2_vip[2]="10.20.51.101"
traf2_vip[3]="10.20.51.102"
traf2_vip[4]="10.20.51.103"
traf2_vip[5]="10.20.51.104"
traf2_vip[6]="10.20.51.105"
traf2_vip[7]="10.20.51.106"
traf2_vip[8]="10.20.51.107"
traf2_vip[9]="10.20.51.108"
traf2_vip[10]="10.20.51.109"
traf2_vip[11]="10.20.51.110"
traf2_vip[12]="10.20.51.111"
traf2_vip[13]="10.20.51.112"
traf2_vip[14]="10.20.51.113"
traf2_vip[15]="10.20.51.114"
traf2_vip[16]="10.20.51.115"
traf2_vip[17]="10.20.51.116"
traf2_vip[18]="10.20.51.117"
traf2_vip[19]="10.20.51.118"
traf2_vip[20]="10.20.51.119"
traf2_vip[21]="10.20.51.120"
traf2_vip[22]="10.20.51.121"
traf2_vip[23]="10.20.51.122"
traf2_vip[24]="10.20.51.123"

traf2_vip_ipv6[1]="fdde:4d7e:d471:20::51:100/64"
traf2_vip_ipv6[2]="fdde:4d7e:d471:20::51:101/64"
traf2_vip_ipv6[3]="fdde:4d7e:d471:20::51:102/64"
traf2_vip_ipv6[4]="fdde:4d7e:d471:20::51:103/64"
traf2_vip_ipv6[5]="fdde:4d7e:d471:20::51:104/64"
traf2_vip_ipv6[6]="fdde:4d7e:d471:20::51:105/64"
traf2_vip_ipv6[7]="fdde:4d7e:d471:20::51:106/64"
traf2_vip_ipv6[8]="fdde:4d7e:d471:20::51:107/64"
traf2_vip_ipv6[9]="fdde:4d7e:d471:20::51:108/64"
traf2_vip_ipv6[10]="fdde:4d7e:d471:20::51:109/64"
traf2_vip_ipv6[11]="fdde:4d7e:d471:20::51:110/64"
traf2_vip_ipv6[12]="fdde:4d7e:d471:20::51:111/64"
traf2_vip_ipv6[13]="fdde:4d7e:d471:20::51:112/64"
traf2_vip_ipv6[14]="fdde:4d7e:d471:20::51:113/64"
traf2_vip_ipv6[15]="fdde:4d7e:d471:20::51:114/64"
traf2_vip_ipv6[16]="fdde:4d7e:d471:20::51:115/64"
traf2_vip_ipv6[17]="fdde:4d7e:d471:20::51:116/64"
traf2_vip_ipv6[18]="fdde:4d7e:d471:20::51:117/64"
traf2_vip_ipv6[19]="fdde:4d7e:d471:20::51:118/64"
traf2_vip_ipv6[20]="fdde:4d7e:d471:20::51:119/64"
traf2_vip_ipv6[21]="fdde:4d7e:d471:20::51:120/64"
traf2_vip_ipv6[22]="fdde:4d7e:d471:20::51:121/64"
traf2_vip_ipv6[23]="fdde:4d7e:d471:20::51:122/64"
traf2_vip_ipv6[24]="fdde:4d7e:d471:20::51:123/64"


# setup a list of rpm to install
rpms[0]=ERIClitptag_CXP1234567-1.0.1-SNAPSHOT20151014152125.noarch.rpm
rpms[1]=ERIClitptagapi_CXP1234567-1.0.1-SNAPSHOT20160205115231.noarch.rpm
rpms[2]=ERIClitpsan_CXP9030786-1.17.1.rpm
rpms[3]=ERIClitpsanapi_CXP9030787-1.6.1.rpm
rpms[4]=ERIClitpsanemc_CXP9030788-1.13.2.rpm
