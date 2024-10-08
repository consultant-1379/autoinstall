#!/bin/bash

blade_type="G8"

ms_ilo_ip="10.44.84.65"
ms_ilo_username="root"
ms_ilo_password='Amm30n!!'
ms_ip="10.44.86.86"
ms_subnet="10.44.86.64/26"
ms_gateway="10.44.86.65"
ms_vlan=""
ms_host="dot86-ms"
ms_eth0_mac="80:C1:6E:7A:8B:28"
ms_eth1_mac="80:C1:6E:7A:8B:2C"
ms_eth2_mac="80:C1:6E:7A:8B:29"
ms_eth3_mac="80:C1:6E:7A:8B:2D"
ms_eth4_mac="80:C1:6E:7A:8B:2A"
ms_eth5_mac="80:C1:6E:7A:8B:2E"
ms_eth6_mac="80:C1:6E:7A:8B:2B"
ms_eth7_mac="80:C1:6E:7A:8B:2F"
ms_sysname="CZ3218HDVY"
ms_ip_ext="10.44.235.100"
ms_ip_ext1="10.44.86.166"
ms_ip_ext2="10.44.86.203"
ms_ipv6_00="fdde:4d7e:d471:1::835:66:f100/64"
ms_ipv6_01="fdde:4d7e:d471:4::898:66:f101/64"
ms_ipv6_11="fdde:4d7e:d471:0::834:66:f100/64"
ms_ipv6_12="fdde:4d7e:d471:2::836:66:f100/64"
ms_ipv6_13="fdde:4d7e:d471:3::837:66:f100/64"
vcs_cluster_id="4766"
ms_host_add6_00="fdde:4d7e:d471:1::835:66:f100"
ms_disk_uuid="600508B1001C2672411EBA9EE66947DA"

fd1_uuid="600601602851390071255D48A590EB11"
fd2_uuid="6006016028513900A96B998DA590EB11"
fd3_uuid="6006016028513900AE1D1AB8A590EB11"

# Copy Test Files
rpms[0]=ERIClitptag_CXP1234567-1.0.1-SNAPSHOT20151014152125.noarch.rpm
rpms[1]=ERIClitptagapi_CXP1234567-1.0.1-SNAPSHOT20151014130657.noarch.rpm
# Test Images
copytestfile1="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper1-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper1-2.0.0.rpm"
copytestfile2="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper2-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper2-2.0.0.rpm"
copytestfile3="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper3-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper3-2.0.0.rpm"
copytestfile4="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper4-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper4-2.0.0.rpm"
copytestfile5="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper5-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper5-2.0.0.rpm"
copytestfile6="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper6-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper6-2.0.0.rpm"
copytestfile7="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper7-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper7-2.0.0.rpm"
copytestfile8="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper8-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper8-2.0.0.rpm"
copytestfile9="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper9-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper9-2.0.0.rpm"
copytestfile10="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper10-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper10-2.0.0.rpm"
copytestfile11="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper11-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper11-2.0.0.rpm"
copytestfile12="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper12-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper12-2.0.0.rpm"
copytestfile13="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper13-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper13-2.0.0.rpm"
copytestfile14="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper14-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper14-2.0.0.rpm"
copytestfile15="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper15-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper15-2.0.0.rpm"
copytestfile16="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper16-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper16-2.0.0.rpm"
copytestfile17="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper17-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper17-2.0.0.rpm"
copytestfile18="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper18-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper18-2.0.0.rpm"
copytestfile19="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper19-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper19-2.0.0.rpm"
copytestfile20="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper20-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper20-2.0.0.rpm"

# Vm images
copytestfile23="http://10.44.235.150/cdb/vm_test_image-2-1.0.4.qcow2:/var/www/html/images/vm_image_rhel6.qcow2"
# Test Services
copytestfile24="http://10.44.235.150/st/test-packages/test_service-1.0-1.noarch.rpm:/tmp/test_service-1.0-1.noarch.rpm"
copytestfile25="http://10.44.235.150/st/test-packages/test_service-2.0-1.noarch.rpm:/tmp/test_service-2.0-1.noarch.rpm"
copytestfile26="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper1-2.0.0.rpm:/var/www/html/newRepo_dir/EXTR-lsbwrapper1-2.0.0.rpm"

# Plugins
copytestfile27="http://10.44.235.150/st/test-plugins/ERIClitptag_CXP1234567-1.0.1-SNAPSHOT20151014152125.noarch.rpm:/tmp/ERIClitptag_CXP1234567-1.0.1-SNAPSHOT20151014152125.noarch.rpm"
copytestfile28="http://10.44.235.150/st/test-plugins/ERIClitptagapi_CXP1234567-1.0.1-SNAPSHOT20151014130657.noarch.rpm:/tmp/ERIClitptagapi_CXP1234567-1.0.1-SNAPSHOT20151014130657.noarch.rpm"
copytestfile29="http://10.44.235.150/st/test-plugins/root_yum_install_pkg.exp:/tmp/root_yum_install_pkg.exp"

# ST-CDB: ROBUSTNESS
copytestfile30="http://10.44.235.150/st/example_apps/3PP-irish-hello-1.0.0-1.noarch.rpm:/tmp/3PP-irish-hello-1.0.0-1.noarch.rpm"
copytestfile31="http://10.44.235.150/st/test-packages/EXTR-lsbwrapper40-2.0.0.rpm:/tmp/lsb_pkg/EXTR-lsbwrapper40-2.0.0.rpm"

# copy files from "example_apps" on .150 to new directory "helloapps" for package list on ms
copytestfile32="http://10.44.235.150/st/example_apps/3PP-azerbaijani-in-ear-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-azerbaijani-in-ear-1.0.0-1.noarch.rpm"
copytestfile33="http://10.44.235.150/st/example_apps/3PP-czech-hello-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-czech-hello-1.0.0-1.noarch.rpm"
copytestfile34="http://10.44.235.150/st/example_apps/3PP-dutch-hello-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-dutch-hello-1.0.0-1.noarch.rpm"
copytestfile35="http://10.44.235.150/st/example_apps/3PP-ejb-in-ear-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-ejb-in-ear-1.0.0-1.noarch.rpm"
copytestfile36="http://10.44.235.150/st/example_apps/3PP-english-hello-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-english-hello-1.0.0-1.noarch.rpm"
copytestfile37="http://10.44.235.150/st/example_apps/3PP-esperanto-in-ear-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-esperanto-in-ear-1.0.0-1.noarch.rpm"
copytestfile38="http://10.44.235.150/st/example_apps/3PP-finnish-hello-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-finnish-hello-1.0.0-1.noarch.rpm"
copytestfile39="http://10.44.235.150/st/example_apps/3PP-french-hello-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-french-hello-1.0.0-1.noarch.rpm"
copytestfile40="http://10.44.235.150/st/example_apps/3PP-french-in-ear-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-french-in-ear-1.0.0-1.noarch.rpm"
copytestfile41="http://10.44.235.150/st/example_apps/3PP-german-hello-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-german-hello-1.0.0-1.noarch.rpm"
copytestfile42="http://10.44.235.150/st/example_apps/3PP-german-in-ear-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-german-in-ear-1.0.0-1.noarch.rpm"
copytestfile43="http://10.44.235.150/st/example_apps/3PP-helloworld-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-helloworld-1.0.0-1.noarch.rpm"
copytestfile44="http://10.44.235.150/st/example_apps/3PP-hungarian-in-ear-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-hungarian-in-ear-1.0.0-1.noarch.rpm"
copytestfile45="http://10.44.235.150/st/example_apps/3PP-irish-hello-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-irish-hello-1.0.0-1.noarch.rpm"
copytestfile46="http://10.44.235.150/st/example_apps/3PP-irish-in-ear-1.0.0-1.noarch.rpm:/tmp/helloapps/3PP-irish-in-ear-1.0.0-1.noarch.rpm"
copytestfile47="http://10.44.235.150/cdb/vm_test_image-1-1.0.3.qcow2:/var/www/html/images/vm_image_rhel7.qcow2"
copytestfile48="http://10.44.235.150/st/example_apps/3PP-italian-hello-1.0.0-1.noarch.rpm:/var/www/html/hello_packages/3PP-italian-hello-1.0.0-1.noarch.rpm"

vm_image_source="http://dot86-ms/images/image.qcow2"

# Diff name service
copytestfile52="http://10.44.235.150/st/test-packages/diff_name_srvc/test_service_name-2.0-1.noarch.rpm:/var/www/html/3pp/test_service_name-2.0-1.noarch.rpm"

nodes_subnet="$ms_subnet"
nodes_subnet_ext="10.44.235.0/24"  # VLAN 898
nodes_gateway="$ms_gateway"
nodes_ilo_password='Amm30n!!'
nodes_gateway_ext="10.44.235.1"

#NFS
nfs_management_ip="10.44.86.212"
nfs_prefix="/home/admin/ST/nfs_share_dir_86"


node_ip[0]="10.44.86.87"
node_sysname[0]="CZJ45103PJ"
node_hostname[0]="dot86-node1"
node_eth0_mac[0]="14:58:d0:42:db:20"
node_eth1_mac[0]="14:58:d0:42:db:24"
node_eth2_mac[0]="14:58:d0:42:db:21"
node_eth3_mac[0]="14:58:d0:42:db:25"
node_eth4_mac[0]="14:58:d0:42:db:22"
node_eth5_mac[0]="14:58:d0:42:db:26"
node_eth6_mac[0]="14:58:d0:42:db:23"
node_eth7_mac[0]="14:58:d0:42:db:27"
node_disk1_uuid[0]="60060160285139007A9926EABB90EB11"
node_disk2_uuid[0]="6006016028513900C8F951F9BD90EB11"
node_disk3_uuid[0]="6006016028513900E98FB84DB990EB11"
node_disk4_uuid[0]="600601602851390087E64FAEB990EB11"
node_disk5_uuid[0]="6006016028513900683D9FE2AE90EB11"
node_bmc_ip[0]="10.44.84.10"
node_ip_ext[0]="10.44.235.101"
node_ip_ext1[0]="10.44.86.167"
node_ip_ext2[0]="10.44.86.204"
traf1_ip[0]="10.19.66.10"
traf2_ip[0]="10.20.66.10"
ipv6_00[0]="fdde:4d7e:d471:1::835:66:100/64"
ipv6_01[0]="fdde:4d7e:d471:4::898:66:101/64"
ipv6_02[0]="fdde:4d7e:d471:1::835:66:102/64"
ipv6_03[0]="fdde:4d7e:d471:1::835:66:103/64"
ipv6_04[0]="fdde:4d7e:d471:19::66:104/64"
ipv6_05[0]="fdde:4d7e:d471:20::66:126/64"
ipv6_06[0]="fdde:4d7e:d471:1::835:66:106/64"
ipv6_07[0]="fdde:4d7e:d471:1::835:66:107/64"
ipv6_08[0]="fdde:4d7e:d471:1::835:66:108/64"
ipv6_09[0]="fdde:4d7e:d471:1::835:66:109/64"
ipv6_10[0]="fdde:4d7e:d471:1::835:66:10a/64"
ipv6_11[0]="fdde:4d7e:d471:0::834:66:110/64"
ipv6_12[0]="fdde:4d7e:d471:2::836:66:110/64"
ipv6_13[0]="fdde:4d7e:d471:3::837:66:110/64"
ipv6_14[0]="fdde:4d7e:d471:1::835:66:a/64"

ipv6_835_tp="fdde:4d7e:d471:1::835:66:a"
host_add6_00[0]="fdde:4d7e:d471:19::66:104"
host_add6_01[0]="fdde:4d7e:d471:20::66:105"

node_ip[1]="10.44.86.68"
node_sysname[1]="CZ3520XY2H"
node_hostname[1]="dot86-node2"
node_eth0_mac[1]="ec:b1:d7:91:b4:e0"
node_eth1_mac[1]="ec:b1:d7:91:b4:e4"
node_eth2_mac[1]="ec:b1:d7:91:b4:e1"
node_eth3_mac[1]="ec:b1:d7:91:b4:e5"
node_eth4_mac[1]="ec:b1:d7:91:b4:e2"
node_eth5_mac[1]="ec:b1:d7:91:b4:e6"
node_eth6_mac[1]="ec:b1:d7:91:b4:e3"
node_eth7_mac[1]="ec:b1:d7:91:b4:e7"
node_disk1_uuid[1]="6006016028513900927E0890BC90EB11"
node_disk2_uuid[1]="600601602851390050D09545BE90EB11"
node_disk3_uuid[1]="600601602851390061E5D20FBA90EB11"
node_disk4_uuid[1]="6006016028513900C47C944ABA90EB11"
node_disk5_uuid[1]="600601602851390000E70A2AAF90EB11"
node_bmc_ip[1]="10.44.84.15"
node_ip_ext[1]="10.44.235.102"
node_ip_ext1[1]="10.44.86.168"
node_ip_ext2[1]="10.44.86.205"
ipv6_00[1]="fdde:4d7e:d471:1::835:66:200/64"
ipv6_01[1]="fdde:4d7e:d471:19::66:201/64"
ipv6_02[1]="fdde:4d7e:d471:1::835:66:202/64"
ipv6_03[1]="fdde:4d7e:d471:1::835:66:203/64"
ipv6_04[1]="fdde:4d7e:d471:20::66:204/64"
ipv6_05[1]="fdde:4d7e:d471:4::898:66:205/64"
ipv6_06[1]="fdde:4d7e:d471:1::835:66:206/64"
ipv6_07[1]="fdde:4d7e:d471:1::835:66:207/64"
ipv6_08[1]="fdde:4d7e:d471:1::835:66:208/64"
ipv6_09[1]="fdde:4d7e:d471:1::835:66:209/64"
ipv6_10[1]="fdde:4d7e:d471:1::835:66:20a/64"
ipv6_11[1]="fdde:4d7e:d471:0::834:66:120/64"
ipv6_12[1]="fdde:4d7e:d471:2::836:66:120/64"
ipv6_13[1]="fdde:4d7e:d471:3::837:66:120/64"
traf1_ip[1]="10.19.66.20"
traf2_ip[1]="10.20.66.20"

host_add6_00[1]="fdde:4d7e:d471:19::66:201"
host_add6_01[1]="fdde:4d7e:d471:20::66:204"

vxvm_disk_uuid[0]="60060160285139007F121977AF90EB11"
vxvm_disk_uuid[1]="6006016028513900B92FC432B090EB11"
vxvm_disk_uuid[2]="600601602851390011ACAEDCAF90EB11"
vxvm_disk_uuid[3]="60060160285139000E1CE29DB090EB11"
vxvm_disk_uuid[4]="600601602851390031CDD775B490EB11"
vxvm_disk_uuid[5]="60060160285139000A2ED3AAB490EB11"
vxvm_disk_uuid[6]="6006016028513900E5CD3C30B590EB11"

vxvm_disk_uuid[7]="60060160285139009C73E212B690EB11"
vxvm_disk_uuid[8]="6006016028513900D85B3771B690EB11"
vxvm_disk_uuid[9]="60060160285139001A4854A4B690EB11"
vxvm_disk_uuid[10]="6006016028513900537F5ACDB690EB11"

route2_subnet="10.44.86.0/26"    # VLAN 834
route3_subnet="10.44.86.128/26"  # VLAN 836
route4_subnet="10.44.86.192/26"  # VLAN 837
route_subnet_801="10.44.84.0/24"

ipv6_834[0]="fdde:4d7e:d471:0:834::4:4"
route_835_subnet_ipv6="fdde:4d7e:d471:1::835:0:0/64"

route_835_gw_ipv6="fdde:4d7e:d471:1::835:0:1"
ntp_ip[1]="10.44.86.212"
ntp_ip[2]="127.127.1.0"

# NAS - New VA Server
sfs_management_ip="10.44.235.30"
sfs_vip="10.44.235.29"
sfs_prefix="/vx/ST66"
nas_support_password="veritas"
ms_ip_nas="$ms_ip_ext"
node_ip_nas[0]="${node_ip_ext[0]}"
node_ip_nas[1]="${node_ip_ext[1]}"
nas_network="data" # Network must exist with this name in deployment script
sfs_snapshot_cleanup_list="10.44.235.30:master:veritas:L_ST66_mgmt_sfs_fs1_=ST66_mgmt_sfs_fs1,L_ST66_mgmt_sfs_fs3_=ST66_mgmt_sfs_fs3,L_ST66_mgmt_sfs_fs2_=ST66_mgmt_sfs_fs2:ST66_cashe"
sfs_cleanup_list="10.44.235.30:master:veritas:/vx/ST66_mgmt_sfs_fs1=10.44.235.100,/vx/ST66_mgmt_sfs_fs1=10.44.235.101,/vx/ST66_mgmt_sfs_fs1=10.44.235.102:ST66_mgmt_sfs_fs1__BREAK__10.44.235.30:master:veritas:/vx/ST66_mgmt_sfs_fs2=10.44.235.100,/vx/ST66_mgmt_sfs_fs2=10.44.235.101,/vx/ST66_mgmt_sfs_fs2=10.44.235.102:ST66_mgmt_sfs_fs2__BREAK__10.44.235.30:master:veritas:/vx/ST66_mgmt_sfs_fs3=10.44.235.100,/vx/ST66_mgmt_sfs_fs3=10.44.235.101,/vx/ST66_mgmt_sfs_fs3=10.44.235.102:ST66_mgmt_sfs_fs3"

#VCS
traf1_subnet="10.19.66.0/24"
traf2_subnet="10.20.66.0/24"
traf1gw_subnet="10.66.19.0/24"
traf2gw_subnet="10.66.20.0/24"

#VIPs
traf1_vip[1]="10.19.66.100"
traf1_vip[2]="10.19.66.101"
traf1_vip[3]="10.19.66.102"
traf1_vip[4]="10.19.66.103"
traf1_vip[5]="10.19.66.104"
traf1_vip[6]="10.19.66.105"
traf1_vip[7]="10.19.66.106"
traf1_vip[8]="10.19.66.107"
traf1_vip[9]="10.19.66.108"
traf1_vip[10]="10.19.66.109"
traf1_vip[11]="10.19.66.110"
traf1_vip[12]="10.19.66.111"
traf1_vip[13]="10.19.66.112"
traf1_vip[14]="10.19.66.113"
traf1_vip[15]="10.19.66.114"
traf1_vip[15]="10.19.66.115"
traf1_vip[16]="10.19.66.116"
traf1_vip[17]="10.19.66.117"
traf1_vip[18]="10.19.66.118"
traf1_vip[19]="10.19.66.119"
traf1_vip[20]="10.19.66.120"
traf1_vip[21]="10.19.66.121"
traf1_vip[22]="10.19.66.122"
traf1_vip[23]="10.19.66.123"

traf1_vip_ipv6[1]="fdde:4d7e:d471:19::66:100/64"
traf1_vip_ipv6[2]="fdde:4d7e:d471:19::66:101/64"
traf1_vip_ipv6[3]="fdde:4d7e:d471:19::66:102/64"
traf1_vip_ipv6[4]="fdde:4d7e:d471:19::66:103/64"
traf1_vip_ipv6[5]="fdde:4d7e:d471:19::66:104/64"
traf1_vip_ipv6[6]="fdde:4d7e:d471:19::66:105/64"
traf1_vip_ipv6[7]="fdde:4d7e:d471:19::66:106/64"
traf1_vip_ipv6[8]="fdde:4d7e:d471:19::66:107/64"
traf1_vip_ipv6[9]="fdde:4d7e:d471:19::66:108/64"
traf1_vip_ipv6[10]="fdde:4d7e:d471:19::66:109/64"
traf1_vip_ipv6[11]="fdde:4d7e:d471:19::66:110/64"
traf1_vip_ipv6[12]="fdde:4d7e:d471:19::66:111/64"
traf1_vip_ipv6[13]="fdde:4d7e:d471:19::66:112/64"
traf1_vip_ipv6[14]="fdde:4d7e:d471:19::66:113/64"
traf1_vip_ipv6[15]="fdde:4d7e:d471:19::66:114/64"
traf1_vip_ipv6[16]="fdde:4d7e:d471:19::66:115/64"
traf1_vip_ipv6[17]="fdde:4d7e:d471:19::66:116/64"
traf1_vip_ipv6[18]="fdde:4d7e:d471:19::66:117/64"
traf1_vip_ipv6[19]="fdde:4d7e:d471:19::66:118/64"
traf1_vip_ipv6[20]="fdde:4d7e:d471:19::66:119/64"
traf1_vip_ipv6[21]="fdde:4d7e:d471:19::66:120/64"
traf1_vip_ipv6[22]="fdde:4d7e:d471:19::66:121/64"
traf1_vip_ipv6[23]="fdde:4d7e:d471:19::66:122/64"
traf1_vip_ipv6[24]="fdde:4d7e:d471:19::66:123/64"

traf2_vip[1]="10.20.66.100"
traf2_vip[2]="10.20.66.101"
traf2_vip[3]="10.20.66.102"
traf2_vip[4]="10.20.66.103"
traf2_vip[5]="10.20.66.104"
traf2_vip[6]="10.20.66.105"
traf2_vip[7]="10.20.66.106"
traf2_vip[8]="10.20.66.107"
traf2_vip[9]="10.20.66.108"
traf2_vip[10]="10.20.66.109"
traf2_vip[11]="10.20.66.110"
traf2_vip[12]="10.20.66.111"
traf2_vip[13]="10.20.66.112"
traf2_vip[14]="10.20.66.113"
traf2_vip[15]="10.20.66.114"
traf2_vip[15]="10.20.66.115"
traf2_vip[16]="10.20.66.116"
traf2_vip[17]="10.20.66.117"
traf2_vip[18]="10.20.66.118"
traf2_vip[19]="10.20.66.119"
traf2_vip[20]="10.20.66.120"
traf2_vip[21]="10.20.66.121"
traf2_vip[22]="10.20.66.122"
traf2_vip[23]="10.20.66.123"

traf2_vip_ipv6[1]="fdde:4d7e:d471:20::66:100/64"
traf2_vip_ipv6[2]="fdde:4d7e:d471:20::66:101/64"
traf2_vip_ipv6[3]="fdde:4d7e:d471:20::66:102/64"
traf2_vip_ipv6[4]="fdde:4d7e:d471:20::66:103/64"
traf2_vip_ipv6[5]="fdde:4d7e:d471:20::66:104/64"
traf2_vip_ipv6[6]="fdde:4d7e:d471:20::66:105/64"
traf2_vip_ipv6[7]="fdde:4d7e:d471:20::66:106/64"
traf2_vip_ipv6[8]="fdde:4d7e:d471:20::66:107/64"
traf2_vip_ipv6[9]="fdde:4d7e:d471:20::66:108/64"
traf2_vip_ipv6[10]="fdde:4d7e:d471:20::66:109/64"
traf2_vip_ipv6[11]="fdde:4d7e:d471:20::66:110/64"
traf2_vip_ipv6[12]="fdde:4d7e:d471:20::66:111/64"
traf2_vip_ipv6[13]="fdde:4d7e:d471:20::66:112/64"
traf2_vip_ipv6[14]="fdde:4d7e:d471:20::66:113/64"
traf2_vip_ipv6[15]="fdde:4d7e:d471:20::66:114/64"
traf2_vip_ipv6[16]="fdde:4d7e:d471:20::66:115/64"
traf2_vip_ipv6[17]="fdde:4d7e:d471:20::66:116/64"
traf2_vip_ipv6[18]="fdde:4d7e:d471:20::66:117/64"
traf2_vip_ipv6[19]="fdde:4d7e:d471:20::66:118/64"
traf2_vip_ipv6[20]="fdde:4d7e:d471:20::66:119/64"
traf2_vip_ipv6[21]="fdde:4d7e:d471:20::66:120/64"
traf2_vip_ipv6[22]="fdde:4d7e:d471:20::66:121/64"
traf2_vip_ipv6[23]="fdde:4d7e:d471:20::66:122/64"
traf2_vip_ipv6[24]="fdde:4d7e:d471:20::66:123/64"

# PREPARE RESTORE
num_clusters="1"
num_prepare_restore_tasks="412"

# Node 3
node_sysname[2]="CZ3218HDVR"
node_hostname[2]="rover1"
node_eth0_mac[2]="80:C1:6E:7A:B8:D0"
node_eth2_mac[2]="80:C1:6E:7A:B8:D1"
node_eth3_mac[2]="80:C1:6E:7A:B8:D5"
node_disk1_uuid[2]="600601600F3133002AF0427DC495E411"
node_bmc_ip[2]="10.44.84.115"

net835_ip[2]="10.44.86.98"

vcs_cluster_id_2="4767"
