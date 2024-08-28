#!/bin/bash

blade_type="G8"

ms_ilo_ip="10.44.84.43"
ms_ilo_username="root"
ms_ilo_password='Amm30n!!'
ms_ip="10.44.86.90"
ms_ip_ext="10.44.235.108"
ms_subnet="10.44.86.64/26"
ms_gateway="10.44.86.65"
ms_vlan=""
ms_host="ms1dot90"
ms_eth0_mac="2C:59:E5:3D:E3:D8"
ms_eth1_mac="2c:59:E5:3D:E3:DC"
ms_eth2_mac="2C:59:E5:3D:E3:D9"
ms_eth3_mac="2C:59:E5:3D:E3:DD"
ms_eth4_mac="2c:59:e5:3d:e3:da"
ms_sysname="CZJ33308JF"
ms_ipv6_00="fdde:4d7e:d471:1::835:90:100/64"
ms_ipv6_01="fdde:4d7e:d471:4::898:90:101/64"
ms_ipv6_02="fdde:4d7e:d471:0::834:90:150/64"
ms_ipv6_03="fdde:4d7e:d471:1::835:90:150/64"
ms_ipv6_04="fdde:4d7e:d471:2::836:90:150/64"
ms_ipv6_05="fdde:4d7e:d471:3::835:90:150/64"
ms_disk_uuid="600508b1001c0d4162c49428ebb8236e"

net1vm_ip_ms="10.46.82.3"
net1vm_subnet="10.46.82.0/24"


nodes_ip_start="10.44.86.88"
nodes_ip_end="10.44.86.90"
nodes_subnet="$ms_subnet"
nodes_subnet_ext="10.44.235.0/24"
nodes_gateway="$ms_gateway"
nodes_gateway_ext="10.44.235.1"
nodes_ilo_password='Amm30n!!'

# VCS
traf1_subnet="10.19.90.0/24"
traf2_subnet="10.20.90.0/24"

#NFS
nfs_management_ip="10.44.86.212"
nfs_prefix="/home/admin/ST/nfs_share_dir_90"

### subnets
netwrk834="10.44.86.0/26"
netwrk835="10.44.86.64/26"
netwrk836="10.44.86.128/26"
netwrk837="10.44.86.192/26"
netwrk898="10.44.235.0/24"

#VM

copytestfile1="http://10.44.235.150/cdb/vm_test_image-1-1.0.3.qcow2:/var/www/html/images/vm_image_rhel7.qcow2"

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
copytestfile13="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper12-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper12-2.0.0.rpm"
copytestfile14="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper13-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper13-2.0.0.rpm"
copytestfile15="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper14-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper14-2.0.0.rpm"
copytestfile16="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper15-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper15-2.0.0.rpm"
copytestfile17="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper16-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper16-2.0.0.rpm"
copytestfile18="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper17-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper17-2.0.0.rpm"
copytestfile19="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper18-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper18-2.0.0.rpm"
copytestfile20="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper19-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper19-2.0.0.rpm"
copytestfile21="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper20-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper20-2.0.0.rpm"
copytestfile22="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper21-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper21-2.0.0.rpm"
copytestfile23="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper22-2.0.0.rpm:/var/www/html/new_repo/EXTR-lsbwrapper22-2.0.0.rpm"
copytestfile24="http://10.44.235.150/iso/st_plugins/ERIClitptag_CXP1234567-1.0.1-SNAPSHOT20151014152125.noarch.rpm:/tmp/ERIClitptag_CXP1234567-1.0.1-SNAPSHOT20151014152125.noarch.rpm"
copytestfile25="http://10.44.235.150/iso/st_plugins/ERIClitptagapi_CXP1234567-1.0.1-SNAPSHOT20151014130657.noarch.rpm:/tmp/ERIClitptagapi_CXP1234567-1.0.1-SNAPSHOT20151014130657.noarch.rpm"
copytestfile26="http://10.44.235.150/iso/st_plugins/root_yum_install_pkg.exp:/tmp/root_yum_install_pkg.exp"

copytestfile27="http://10.44.235.150/st/example_apps/3PP-russian-hello-1.0.0-1.noarch.rpm:/var/www/html/3pp/3PP-russian-hello-1.0.0-1.noarch.rpm"
copytestfile28="http://10.44.235.150/st/example_apps/3PP-german-hello-1.0.0-1.noarch.rpm:/var/www/html/3pp/3PP-german-hello-1.0.0-1.noarch.rpm"
copytestfile29="http://10.44.235.150/st/example_apps/3PP-polish-hello-1.0.0-1.noarch.rpm:/var/www/html/3pp/3PP-polish-hello-1.0.0-1.noarch.rpm"
copytestfile30="http://10.44.235.150/st/example_apps/3PP-swedish-hello-1.0.0-1.noarch.rpm:/var/www/html/3pp/3PP-swedish-hello-1.0.0-1.noarch.rpm"
copytestfile31="http://10.44.235.150/st/example_apps/3PP-dutch-hello-1.0.0-1.noarch.rpm:/var/www/html/3pp/3PP-dutch-hello-1.0.0-1.noarch.rpm"
copytestfile32="http://10.44.235.150/st/example_apps/3PP-czech-hello-1.0.0-1.noarch.rpm:/var/www/html/3pp/3PP-czech-hello-1.0.0-1.noarch.rpm"
copytestfile33="http://10.44.235.150/st/example_apps/3PP-azerbaijani-in-ear-1.0.0-1.noarch.rpm:/var/www/html/3pp/3PP-azerbaijani-in-ear-1.0.0-1.noarch.rpm"
copytestfile34="http://10.44.235.150/st/example_apps/3PP-ejb-in-ear-1.0.0-1.noarch.rpm:/var/www/html/3pp/3PP-ejb-in-ear-1.0.0-1.noarch.rpm"
copytestfile35="http://10.44.235.150/st/example_apps/3PP-esperanto-in-ear-1.0.0-1.noarch.rpm:/var/www/html/3pp/3PP-esperanto-in-ear-1.0.0-1.noarch.rpm"
copytestfile36="http://10.44.235.150/st/example_apps/3PP-finnish-hello-1.0.0-1.noarch.rpm:/var/www/html/3pp/3PP-finnish-hello-1.0.0-1.noarch.rpm"
copytestfile37="http://10.44.235.150/st/example_apps/3PP-french-hello-1.0.0-1.noarch.rpm:/var/www/html/3pp/3PP-french-hello-1.0.0-1.noarch.rpm"
copytestfile38="http://10.44.235.150/st/example_apps/3PP-hungarian-in-ear-1.0.0-1.noarch.rpm:/var/www/html/3pp/3PP-hungarian-in-ear-1.0.0-1.noarch.rpm"
copytestfile39="http://10.44.235.150/st/example_apps/3PP-italian-hello-1.0.0-1.noarch.rpm:/var/www/html/3pp/3PP-italian-hello-1.0.0-1.noarch.rpm"
copytestfile40="http://10.44.235.150/st/example_apps/3PP-klingon-hello-1.0.0-1.noarch.rpm:/var/www/html/3pp/3PP-klingon-hello-1.0.0-1.noarch.rpm"
copytestfile41="http://10.44.235.150/st/example_apps/3PP-spanish-hello-1.0.0-1.noarch.rpm:/var/www/html/3pp/3PP-spanish-hello-1.0.0-1.noarch.rpm"
copytestfile42="http://10.44.235.150/st/example_apps/3PP-english-hello-1.0.0-1.noarch.rpm:/var/www/html/3pp/3PP-english-hello-1.0.0-1.noarch.rpm"
copytestfile43="http://10.44.235.150/st/example_apps/3PP-irish-hello-1.0.0-1.noarch.rpm:/var/www/html/3pp/3PP-irish-hello-1.0.0-1.noarch.rpm"

# ST-CDB: ROBUSTNESS
copytestfile44="http://10.44.235.150/st/example_apps/3PP-irish-hello-1.0.0-1.noarch.rpm:/tmp/3PP-irish-hello-1.0.0-1.noarch.rpm"
copytestfile45="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper40-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper40-2.0.0.rpm"
copytestfile46="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper39-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper39-2.0.0.rpm"

# import ENM ISO files
# this is the XML used to create all the package and package list items under /software
copytestfile48="http://10.44.235.150/st/enm-iso/enm_package_2.xml:/tmp/enm_package_2.xml"
# bash script that handles the import the ENM ISO and polling maintenace mode to see when it completes
copytestfile49="http://10.44.235.150/st/enm-iso/import_iso.sh:/tmp/import_iso.sh"
# expect script to run the import_iso.sh script as root - it also removes a plugin using yum that causes restore_snapshot to break
copytestfile50="http://10.44.235.150/st/enm-iso/root_import_iso.exp:/tmp/root_import_iso.exp"
# variable used by the expect script to import the ISO - needs to be updated if changing the ENM ISO
enm_iso="/tmp/ERICenm_CXP9027091-1.26.29.iso"
# Diff name service
copytestfile51="http://10.44.235.150/st/test-packages/diff_name_srvc/test_service_name-2.0-1.noarch.rpm:/var/www/html/3pp/test_service_name-2.0-1.noarch.rpm"

#Name servers

ipv6_nameserver_ip="fe80::2e76:8aff:fe55:4540"
ipv4_nameserver_ip="10.44.86.212"

#Check nodes

sanity_node_ip_check[0]="${node_ip_ext[0]}"
sanity_node_ip_check[1]="${node_ip_ext[1]}"



node_ip[0]="10.44.86.88"
node_ip_2[0]="10.19.90.98"
node_ip_3[0]="10.20.90.98"
node_sysname[0]="CZJ33308J9"
node_hostname[0]="node1dot90"
node_eth0_mac[0]="2C:59:E5:3D:B3:48"
node_eth1_mac[0]="2C:59:E5:3D:B3:4C"
node_eth2_mac[0]="2C:59:E5:3D:B3:49"
node_eth3_mac[0]="2C:59:E5:3D:B3:4D"
node_eth4_mac[0]="2C:59:E5:3D:B3:4A"
node_eth5_mac[0]="2C:59:E5:3D:B3:4E"
node_eth6_mac[0]="2C:59:E5:3D:B3:4B"
node_eth7_mac[0]="2C:59:E5:3D:B3:4F"
node_disk_uuid[0]="6006016011602d00ac03b5856769e311"
node_disk1_uuid[0]="6006016011602d00c4a8be46b1c4e311"
hd2_uuid[0]="6006016011602D00389ba603fa6fe411"
hd3_uuid[0]="6006016011602d008861a97d1170e411"
hd4_uuid[0]="6006016011602D000411EE209519E511"
hd5_uuid[0]="6006016011602D009862B32F9519E511"
hd6_uuid[0]="6006016011602D0042E155559519E511"
hd7_uuid[0]="6006016011602D005ADD01639519E511"
hd8_uuid[0]="6006016011602D00BA92F72AF45AE511"




node_bmc_ip[0]="10.44.84.44"
traf1_ip[0]="10.19.90.10"
traf2_ip[0]="10.20.90.10"
node_ip_ext[0]="10.44.235.109"
ipv6_00[0]="fdde:4d7e:d471:4::898:90:100/64"
ipv6_01[0]="fdde:4d7e:d471:1::835:90:101/64"
ipv6_02[0]="fdde:4d7e:d471:1::835:90:102/64"
ipv6_03[0]="fdde:4d7e:d471:1::835:90:103/64"
ipv6_04[0]="fdde:4d7e:d471:1::835:90:104/64"
ipv6_05[0]="fdde:4d7e:d471:1::835:90:105/64"
ipv6_06[0]="fdde:4d7e:d471:1::835:90:106/64"
ipv6_07[0]="fdde:4d7e:d471:1::835:90:107/64"
ipv6_08[0]="fdde:4d7e:d471:1::835:90:108/64"
ipv6_09[0]="fdde:4d7e:d471:1::835:90:109/64"
ipv6_10[0]="fdde:4d7e:d471:1::835:90:10a/64"
ipv6_11[0]="fdde:4d7e:d471:0::834:90:100/64"
ipv6_12[0]="fdde:4d7e:d471:2::836:90:101/64"
ipv6_13[0]="fdde:4d7e:d471:1::835:90:180/64"
ipv6_14[0]="fdde:4d7e:d471:2::836:90:181/64"
ipv6_15[0]="fdde:4d7e:d471:3::837:90:182/64"
ipv6_16[0]="fdde:4d7e:d471:19::90:104"
ipv6_17[0]="fdde:4d7e:d471:19::90:204"
ipv6_18[0]="fdde:4d7e:d471:19::90:150"
ipv6_20[0]="fdde:4d7e:d471:19::90:150"
ipv6_19[0]="fdde:4d7e:d471:0::834:90:182/64"
ipv6_20[0]="fdde:4d7e:d471:20::90:151"
ipv6_21[0]="fdde:4d7e:d471:19::90:210"
net1vm_ip[0]="10.46.82.99"



node_ip[1]="10.44.86.89"
node_ip_2[1]="10.19.90.99"
node_ip_3[1]="10.20.90.99"
node_sysname[1]="CZJ33308HJ"
node_hostname[1]="node2dot90"
node_eth0_mac[1]="2C:59:E5:3D:A3:90"
node_eth1_mac[1]="2C:59:E5:3D:A3:94"
node_eth2_mac[1]="2C:59:E5:3D:A3:91"
node_eth3_mac[1]="2C:59:E5:3D:A3:95"
node_eth4_mac[1]="2C:59:E5:3D:A3:92"
node_eth5_mac[1]="2C:59:E5:3D:A3:96"
node_eth6_mac[1]="2C:59:E5:3D:A3:93"
node_eth7_mac[1]="2C:59:E5:3D:A3:97"
node_disk_uuid[1]="6006016011602d009243a59c6769e311"
node_disk1_uuid[1]="6006016011602d000af0b95eb1c4e311"
hd2_uuid[1]="6006016011602D00389ba603fa6fe411"
hd3_uuid[1]="6006016011602d008861a97d1170e411"
hd4_uuid[1]="6006016011602D00808FF7A39519E511"
hd5_uuid[1]="6006016011602D00305CFCB39519E511"
hd6_uuid[1]="6006016011602D00D201FAC39519E511"
hd7_uuid[1]="6006016011602D00748275029619E511"
hd8_uuid[1]="6006016011602D00BA92F72AF45AE511"


node_bmc_ip[1]="10.44.84.45"
traf1_ip[1]="10.19.90.20"
traf2_ip[1]="10.20.90.20"
node_ip_ext[1]="10.44.235.110"
ipv6_00[1]="fdde:4d7e:d471:1::835:90:200/64"
ipv6_01[1]="fdde:4d7e:d471:4::898:90:201/64"
ipv6_02[1]="fdde:4d7e:d471:1::835:90:202/64"
ipv6_03[1]="fdde:4d7e:d471:1::835:90:203/64"
ipv6_04[1]="fdde:4d7e:d471:1::835:90:204/64"
ipv6_05[1]="fdde:4d7e:d471:1::835:90:205/64"
ipv6_06[1]="fdde:4d7e:d471:1::835:90:206/64"
ipv6_07[1]="fdde:4d7e:d471:1::835:90:207/64"
ipv6_08[1]="fdde:4d7e:d471:1::835:90:208/64"
ipv6_09[1]="fdde:4d7e:d471:1::835:90:209/64"
ipv6_10[1]="fdde:4d7e:d471:1::835:90:20a/64"
ipv6_11[1]="fdde:4d7e:d471:1::835:90:120/64"
ipv6_12[1]="fdde:4d7e:d471:2::836:90:120/64"
ipv6_13[1]="fdde:4d7e:d471:3::837:90:120/64"
ipv6_14[1]="fdde:4d7e:d471::555:90:120/64"
ipv6_15[1]="fdde:4d7e:d471:19::90:105"
ipv6_16[1]="fdde:4d7e:d471:0::834:90:120/64"
ipv4_00[1]="10.44.235.220"
net1vm_ip[1]="10.46.82.98"

ntp_ip[1]="10.44.86.14"
ntp_ip[2]="127.127.1.0"
ntp_ip[3]="10.44.86.66" #Vinnie env

vcs_cluster_id="4790"
cluster_id="4790"

route2_subnet="10.44.86.0/26"    # VLAN 835
route3_subnet="10.44.86.128/26"  # VLAN 836
route4_subnet="10.44.86.192/26"  # VLAN 837
route_subnet_801="10.44.84.0/24"

#VCS
traf1_subnet="10.19.90.0/24"
traf2_subnet="10.20.90.0/24"



#VIPs
traf1_vip[1]="10.19.90.100"
traf1_vip[2]="10.19.90.101"
traf1_vip[3]="10.19.90.102"
traf1_vip[4]="10.19.90.103"
traf1_vip[5]="10.19.90.104"
traf1_vip[6]="10.19.90.105"
traf1_vip[7]="10.19.90.106"
traf1_vip[8]="10.19.90.107"
traf1_vip[9]="10.19.90.108"
traf1_vip[10]="10.19.90.109"
traf1_vip[11]="10.19.90.110"
traf1_vip[12]="10.19.90.111"
traf1_vip[13]="10.19.90.112"
traf1_vip[14]="10.19.90.113"
traf1_vip[15]="10.19.90.114"
traf1_vip[15]="10.19.90.115"
traf1_vip[16]="10.19.90.116"
traf1_vip[17]="10.19.90.117"
traf1_vip[18]="10.19.90.118"
traf1_vip[19]="10.19.90.119"
traf1_vip[20]="10.19.90.120"
traf1_vip[21]="10.19.90.121"
traf1_vip[22]="10.19.90.122"
traf1_vip[23]="10.19.90.123"
traf1_vip_ipv6[1]="fdde:4d7e:d471:19::90:108/64"
traf1_vip_ipv6[2]="fdde:4d7e:d471:19::90:201/64"
traf1_vip_ipv6[3]="fdde:4d7e:d471:19::90:202/64"
traf1_vip_ipv6[4]="fdde:4d7e:d471:19::90:203/64"
traf1_vip_ipv6[5]="fdde:4d7e:d471:19::90:204/64"
traf1_vip_ipv6[6]="fdde:4d7e:d471:19::90:205/64"
traf1_vip_ipv6[7]="fdde:4d7e:d471:19::90:206/64"
traf1_vip_ipv6[8]="fdde:4d7e:d471:19::90:207/64"
traf1_vip_ipv6[9]="fdde:4d7e:d471:19::90:208/64"
traf1_vip_ipv6[10]="fdde:4d7e:d471:19::90:209/64"
traf1_vip_ipv6[11]="fdde:4d7e:d471:19::90:20a/64"
traf1_vip_ipv6[12]="fdde:4d7e:d471:19::90:210/64"
traf1_vip_ipv6[13]="fdde:4d7e:d471:19::90:211/64"
traf1_vip_ipv6[14]="fdde:4d7e:d471:19::90:212/64"
traf1_vip_ipv6[15]="fdde:4d7e:d471:19::90:213/64"
traf1_vip_ipv6[16]="fdde:4d7e:d471:19::90:214/64"
traf1_vip_ipv6[17]="fdde:4d7e:d471:19::90:215/64"
traf1_vip_ipv6[18]="fdde:4d7e:d471:19::90:216/64"
traf1_vip_ipv6[19]="fdde:4d7e:d471:19::90:217/64"
traf1_vip_ipv6[20]="fdde:4d7e:d471:19::90:218/64"
traf1_vip_ipv6[21]="fdde:4d7e:d471:19::90:219/64"
traf1_vip_ipv6[22]="fdde:4d7e:d471:19::90:220/64"
traf1_vip_ipv6[23]="fdde:4d7e:d471:19::90:221/64"
traf1_vip_ipv6[24]="fdde:4d7e:d471:19::90:222/64"
traf1_vip_ipv6[25]="fdde:4d7e:d471:19::90:223/64"
traf1_vip_ipv6[26]="fdde:4d7e:d471:19::90:224/64"
traf1_vip_ipv6[27]="fdde:4d7e:d471:19::90:225/64"
traf1_vip_ipv6[28]="fdde:4d7e:d471:19::90:226/64"
traf1_vip_ipv6[29]="fdde:4d7e:d471:19::90:227/64"

Vm_vip_ipv6[1]="fdde:4d7e:d471:15:90::09/64"
Vm_vip_ipv6[2]="fdde:4d7e:d471:15:90::08/64"

traf2_vip[1]="10.20.90.100"
traf2_vip[2]="10.20.90.101"
traf2_vip[3]="10.20.90.102"
traf2_vip[4]="10.20.90.103"
traf2_vip[5]="10.20.90.104"
traf2_vip[6]="10.20.90.105"
traf2_vip[7]="10.20.90.106"
traf2_vip[8]="10.20.90.107"
traf2_vip[9]="10.20.90.108"
traf2_vip[10]="10.20.90.109"
traf2_vip[11]="10.20.90.110"
traf2_vip[12]="10.20.90.111"
traf2_vip[13]="10.20.90.112"
traf2_vip[14]="10.20.90.113"
traf2_vip[15]="10.20.90.114"
traf2_vip[15]="10.20.90.115"
traf2_vip[16]="10.20.90.116"
traf2_vip[17]="10.20.90.117"
traf2_vip[18]="10.20.90.118"
traf2_vip[19]="10.20.90.119"
traf2_vip[20]="10.20.90.120"
traf2_vip[21]="10.20.90.121"
traf2_vip[22]="10.20.90.122"
traf2_vip[23]="10.20.90.123"

# NAS - New VA Server
sfs_management_ip="10.44.235.30"
sfs_vip="10.44.235.29"
sfs_prefix="/vx/ST90"
nas_password="veritas"
ms_ip_nas="$ms_ip_ext"
node_ip_nas[0]="${node_ip_ext[0]}"
node_ip_nas[1]="${node_ip_ext[1]}"
nas_network="data" # Network must exist with this name in deployment script
sfs_cleanup_list="10.44.235.30:master:veritas:/vx/ST90-fs1=10.44.235.108,/vx/ST90-fs1=10.44.235.109,/vx/ST90-fs1=10.44.235.110__BREAK__10.44.235.30:master:veritas:/vx/ST90-fs2=10.44.235.108,/vx/ST90-fs2=10.44.235.109,/vx/ST90-fs2=10.44.235.110__BREAK__10.44.235.30:master:veritas:/vx/ST90-fs3=10.44.235.108,/vx/ST90-fs3=10.44.235.109,/vx/ST90-fs3=10.44.235.110"
sfs_snapshot_cleanup_list="10.44.235.30:master:veritas:L_ST90-fs1_=ST90-fs1,L_ST90-fs3_=ST90-fs3,L_ST90-fs2_=ST90-fs2:dot90cache1"

# TAG PLUGIN ADDITION
rpms[0]="ERIClitptag_CXP1234567-1.0.1-SNAPSHOT20151014152125.noarch.rpm"
rpms[1]="ERIClitptagapi_CXP1234567-1.0.1-SNAPSHOT20151014130657.noarch.rpm"

# PREPARE RESTORE
num_clusters="1"
num_prepare_restore_tasks="347"
