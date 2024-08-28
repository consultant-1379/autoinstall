#####
#
# This deployment file is used to add all of the additional deployment updates made to ../custominstall/ST_Deployment_8_inherit.sh since the deployment XMML files were created. 
#
#####
if [ "$#" -lt 1 ]; then
    echo -e "Usage:\n  $0 <CLUSTER_SPEC_FILE>" >&2
    exit 1
fi

cluster_file="$1"
source "$cluster_file"

expect /tmp/root_import_iso.exp "${ms_host}" "${enm_iso}"
litp load -p /software -f /tmp/enm_package_2.xml --merge

litp inherit -p /ms/items/model_repo -s /software/items/model_repo
litp inherit -p /ms/items/model_package -s /software/items/model_package
litp inherit -p /ms/items/ms_repo -s /software/items/ms_repo
litp inherit -p /ms/items/common_repo -s /software/items/common_repo
litp inherit -p /ms/items/db_repo -s /software/items/db_repo
litp inherit -p /ms/items/services_repo -s /software/items/services_repo

# MODELLING DISK & STORAGE PROFILE ON THE MS
litp create -p /infrastructure/systems/sys1/disks/disk0 -t disk -o bootable="false" disk_part="false" name="ms_hd0" size="550G" uuid="${ms_disk_0_uuid}"

# STORAGE PROFILE - MS
litp create -p /infrastructure/storage/storage_profiles/ms_storage_profile -t storage-profile -o volume_driver="lvm"
# VG1
litp create -p /infrastructure/storage/storage_profiles/ms_storage_profile/volume_groups/vg1 -t volume-group -o volume_group_name="vg_root"
litp create -p /infrastructure/storage/storage_profiles/ms_storage_profile/volume_groups/vg1/file_systems/fs_root -t file-system -o mount_point="/" size="15G" snap_external="false" snap_size=100 type="ext4"
litp create -p /infrastructure/storage/storage_profiles/ms_storage_profile/volume_groups/vg1/file_systems/fs_home -t file-system -o mount_point="/home" size="6G" snap_external="false" snap_size=50 type="ext4" backup_snap_size=100
litp create -p /infrastructure/storage/storage_profiles/ms_storage_profile/volume_groups/vg1/file_systems/fs_var_www -t file-system -o mount_point="/var/www" size="70G" snap_external="false" snap_size=50 type="ext4" backup_snap_size=80
litp create -p /infrastructure/storage/storage_profiles/ms_storage_profile/volume_groups/vg1/file_systems/fs_var -t file-system -o mount_point="/var" size="18G" snap_external="false" snap_size=100 type="ext4" backup_snap_size=50
litp create -p /infrastructure/storage/storage_profiles/ms_storage_profile/volume_groups/vg1/file_systems/fs_data -t file-system -o mount_point="/var/lib/mysql" size="20G" snap_external="false" snap_size=1 type="ext4"
litp create -p /infrastructure/storage/storage_profiles/ms_storage_profile/volume_groups/vg1/file_systems/fs_unmounted -t file-system -o size="100M" snap_external="false" snap_size=20 type="ext4" backup_snap_size=30
litp create -p /infrastructure/storage/storage_profiles/ms_storage_profile/volume_groups/vg1/physical_devices/pd1 -t physical-device -o device_name="ms_hd0"

# UPDATE VXVM FILE SYSTEM
litp update -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vxvg1/file_systems/fs1 -o backup_snap_size=90

# MS Firewall Rules
litp create -t firewall-node-config -p /ms/configs/fw_config
litp create -p /ms/configs/fw_config/rules/fw_hyperic_server_in -t firewall-rule -o action=accept chain=INPUT dport=57004,57005 'name=112 hyperic tcp agent to server ports' proto=tcp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_hyperic_server_out -t firewall-rule -o action=accept chain=OUTPUT dport=57006 'name=113 hyperic tcp server to agent port' proto=tcp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_sfsudp -t firewall-rule -o action=accept dport=111,2049,4011,4001 'name=013 sfsudp' proto=udp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_sfstcp -t firewall-rule -o action=accept dport=111,2049,4011,4001 'name=012 sfstcp' proto=tcp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_vmmonitord -t firewall-rule -o action=accept dport=12987 'name=018 vmmonitord' proto=tcp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_dns -t firewall-rule -o action=accept dport=53 'name=021 DNS udp' proto=udp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_brs -t firewall-rule -o action=accept dport=1556,2821,4032,13724,13782 'name=022 backuprestore tcp' proto=tcp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_ntp -t firewall-rule -o action=accept dport=123 'name=029 NTP udp' proto=tcp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_dhcp_tcp -t firewall-rule -o action=accept dport=546,547,647,847 'name=030 DHCP tcp' proto=tcp state=NEW
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

# Create DNS Client
litp create -t dns-client -p /ms/configs/dns_client -o search=ammeonvpn.com,exampleone.com,exampletwo.com
#litp create -t nameserver -p /ms/configs/dns_client/nameservers/my_name_server_D -o ipaddress=2001:4860:0:1001::68 position=1
#litp create -t nameserver -p /ms/configs/dns_client/nameservers/my_name_server_E -o ipaddress=10.10.10.1 position=2
litp create -t nameserver -p /ms/configs/dns_client/nameservers/my_name_server_F -o ipaddress=10.44.86.4 position=3

litp create -t dns-client -p /deployments/d1/clusters/c1/nodes/n1/configs/dns_client -o search=ammeonvpn.com,exampleone.com,exampletwo.com
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n1/configs/dns_client/nameservers/my_name_server_D -o ipaddress=10.10.10.1 position=1
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n1/configs/dns_client/nameservers/my_name_server_E -o ipaddress=10.44.86.4 position=2
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n1/configs/dns_client/nameservers/my_name_server_F -o ipaddress=2001:4860:0:1001::68 position=3

litp create -t dns-client -p /deployments/d1/clusters/c1/nodes/n2/configs/dns_client -o search=ammeonvpn.com,exampleone.com,exampletwo.com
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n2/configs/dns_client/nameservers/my_name_server_A -o ipaddress=10.10.10.1 position=1
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n2/configs/dns_client/nameservers/my_name_server_B -o ipaddress=10.44.86.4 position=2
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n2/configs/dns_client/nameservers/my_name_server_C -o ipaddress=2001:4860:0:1001::68 position=3

# VM updates
# VCS TRIGGER
litp create -t vcs-trigger -p /deployments/d1/clusters/c1/services/apachecs/triggers/trig1 -o trigger_type=nofailover
litp create -t vcs-trigger -p /deployments/d1/clusters/c1/services/SG_STvm4/triggers/trig1 -o trigger_type=nofailover

# MV RAM MOUNT
litp create -t vm-ram-mount -p /software/services/vmservice1/vm_ram_mounts/fs_test_mount -o type=ramfs mount_point="/mnt/ram_test_mount" mount_options="size=32M,noexec,nodev,nosuid"
litp create -t vm-ram-mount -p /software/services/vmservice2/vm_ram_mounts/fs_test_mount -o type=ramfs mount_point="/mnt/ram_test_mount" mount_options="size=128M,nosuid"
litp create -t vm-ram-mount -p /software/services/vmservice3/vm_ram_mounts/fs_test_mount -o type=tmpfs mount_point="/mnt/tmp_test_mount" mount_options="size=256M,nodev,nosuid"
litp create -t vm-ram-mount -p /software/services/vmservice4/vm_ram_mounts/fs_test_mount -o type=tmpfs mount_point="/mnt/tmp_test_mount" mount_options="size=64M,noexec,nosuid"


/usr/bin/md5sum /var/www/html/images/rhel_7_image.qcow2 | cut -d ' ' -f 1 > /var/www/html/images/rhel_7_image.qcow2.md5
/usr/bin/md5sum /var/www/html/images/rhel_6_image.qcow2 | cut -d ' ' -f 1 > /var/www/html/images/rhel_6_image.qcow2.md5


for (( i=1; i<5; i++ )); do

   if (($i % 2)); then
      litp update -p /software/images/image${i} -o source_uri="http://10.44.235.51/images/rhel_7_image.qcow2"
   else
      litp update -p /software/images/image${i} -o source_uri="http://ms1dot51/images/rhel_6_image.qcow2"
   fi
done

for (( i=1; i<5; i++ )); do
    litp create -t vm-alias -p /software/services/vmservice${i}/vm_aliases/alias_ms -o alias_names=ms1dot51 address="${net1vm_ip_ms}"
    litp create -t vm-alias -p /software/services/vmservice${i}/vm_aliases/alias_node1 -o alias_names="${node_hostname[0]}" address="${net1vm_ip[0]}"
    litp create -t vm-alias -p /software/services/vmservice${i}/vm_aliases/alias_node2 -o alias_names="${node_hostname[1]}" address="${net1vm_ip[1]}"
    if (($i % 2)); then 
        litp create -t vm-package -p /software/services/vmservice${i}/vm_packages/tree -o name=tree
        litp create -t vm-package -p /software/services/vmservice${i}/vm_packages/unzip -o name=unzip
        litp create -t vm-yum-repo -p /software/services/vmservice${i}/vm_yum_repos/3pp -o name=vm_3pp base_url=http://"${net1vm_ip_ms}"/3pp
        litp create -t vm-yum-repo -p /software/services/vmservice${i}/vm_yum_repos/os -o name=vm_os base_url=http://"${ms_host}"/6/os/x86_64
    else
        litp create -t vm-package -p /software/services/vmservice${i}/vm_packages/firefox -o name=firefox
        litp create -t vm-package -p /software/services/vmservice${i}/vm_packages/cups -o name=cups 
        litp create -t vm-yum-repo -p /software/services/vmservice${i}/vm_yum_repos/os -o name=vm_os base_url=http://"${ms_host}"/6/os/x86_64
    fi
done
# fmmed does not exist
#litp update -p /software/images/fmmed -o source_uri="http://ms1dot51/images/rhel_7_image.qcow2"

# ARP updates
litp update -p /ms/network_interfaces/b1 -o arp_interval=1250 arp_ip_target="10.44.86.129,10.44.86.130,10.44.86.131,10.44.86.132,10.44.86.133,10.44.86.134,10.44.86.135,10.44.86.136,10.44.86.137,10.44.86.138,10.44.86.139" arp_validate=backup arp_all_targets=any -d miimon

litp update -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/b0 -o arp_validate=active  arp_all_targets=any arp_interval=1250 arp_ip_target="10.44.235.1,10.44.235.2,10.44.235.3,10.44.235.4,10.44.235.5,10.44.235.6,10.44.235.7,10.44.235.8,10.44.235.9,10.44.235.10,10.44.235.11" -d miimon

litp update -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/b1 -o arp_interval=1250 arp_ip_target="10.44.86.129,10.44.86.130,10.44.86.131,10.44.86.132,10.44.86.133,10.44.86.134,10.44.86.135,10.44.86.136,10.44.86.137,10.44.86.138,10.44.86.139" -d miimon

litp update -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/b0 -o arp_validate=all arp_all_targets=any arp_interval=1250 arp_ip_target="10.44.235.1,10.44.235.2,10.44.235.3,10.44.235.4,10.44.235.5,10.44.235.6,10.44.235.7,10.44.235.8,10.44.235.9,10.44.235.10,10.44.235.11" -d miimon

litp update -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/b1 -o arp_interval=1250 arp_ip_target="10.44.86.129,10.44.86.130,10.44.86.131,10.44.86.132,10.44.86.133,10.44.86.134,10.44.86.135,10.44.86.136,10.44.86.137,10.44.86.138,10.44.86.139" -d miimon

litp update -p /deployments/d1/clusters/c1/services/luci -d dependency_list

litp create -t alias -p /ms/configs/alias_config/aliases/duplicate_alias_names_01 -o alias_names="primary-alias-names-01,secondary-name" address="127.0.0.1"
litp create -t alias -p /ms/configs/alias_config/aliases/duplicate_alias_names_02 -o alias_names="primary-alias-names-02,secondary-name,tertiary-name" address="127.0.0.1"
litp create -t alias -p /ms/configs/alias_config/aliases/duplicate_alias_names_03 -o alias_names="primary-alias-names-03,secondary-name,tertiary-name,quaternary-name" address="127.0.0.1"
litp create -t alias -p /ms/configs/alias_config/aliases/duplicate_alias_names_04 -o alias_names="primary-alias-names-04,secondary-name,tertiary-name,quaternary-name" address="127.0.0.1"

litp create -t alias -p /deployments/d1/clusters/c1/nodes/n1/configs/alias_config/aliases/duplicate_alias_names_01 -o alias_names="primary-alias-names-01,secondary-name" address="127.0.0.1"
litp create -t alias -p /deployments/d1/clusters/c1/nodes/n1/configs/alias_config/aliases/duplicate_alias_names_02 -o alias_names="primary-alias-names-02,secondary-name,tertiary-name" address="127.0.0.1"
litp create -t alias -p /deployments/d1/clusters/c1/nodes/n1/configs/alias_config/aliases/duplicate_alias_names_03 -o alias_names="primary-alias-names-03,secondary-name,tertiary-name,quaternary-name" address="127.0.0.1"
litp create -t alias -p /deployments/d1/clusters/c1/nodes/n1/configs/alias_config/aliases/duplicate_alias_names_04 -o alias_names="primary-alias-names-04,secondary-name,tertiary-name,quaternary-name" address="127.0.0.1"

litp create -t alias -p /deployments/d1/clusters/c1/nodes/n2/configs/alias_config/aliases/duplicate_alias_names_01 -o alias_names="primary-alias-names-01,secondary-name" address="127.0.0.1"
litp create -t alias -p /deployments/d1/clusters/c1/nodes/n2/configs/alias_config/aliases/duplicate_alias_names_02 -o alias_names="primary-alias-names-02,secondary-name,tertiary-name" address="127.0.0.1"
litp create -t alias -p /deployments/d1/clusters/c1/nodes/n2/configs/alias_config/aliases/duplicate_alias_names_03 -o alias_names="primary-alias-names-03,secondary-name,tertiary-name,quaternary-name" address="127.0.0.1"
litp create -t alias -p /deployments/d1/clusters/c1/nodes/n2/configs/alias_config/aliases/duplicate_alias_names_04 -o alias_names="primary-alias-names-04,secondary-name,tertiary-name,quaternary-name" address="127.0.0.1"

litp create -t alias -p /deployments/d1/clusters/c1/configs/alias_config/aliases/cluster_duplicate_alias_names_01 -o alias_names="cluster-primary-alias-names-01,secondary-name" address="127.0.0.1"
litp create -t alias -p /deployments/d1/clusters/c1/configs/alias_config/aliases/cluster_duplicate_alias_names_02 -o alias_names="cluster-primary-alias-names-02,secondary-name,tertiary-name" address="127.0.0.1"
litp create -t alias -p /deployments/d1/clusters/c1/configs/alias_config/aliases/cluster_duplicate_alias_names_03 -o alias_names="cluster-primary-alias-names-03,secondary-name,tertiary-name" address="127.0.0.1"

litp create_plan
#litp show_plan
#litp run_plan
