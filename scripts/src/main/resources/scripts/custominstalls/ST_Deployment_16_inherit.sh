#!/bin/bash
#
if [ "$#" -lt 1 ]; then
    echo -e "Usage:\n  $0 <CLUSTER_SPEC_FILE>" >&2
    exit 1
fi

cluster_file="$1"
source "$cluster_file"

set -x

# Import ENM ISO
expect /tmp/root_import_iso.exp "${ms_host}" "${enm_iso}"

litp update -p /litp/logging -o force_debug=true
litpcrypt set key-for-root root "${nodes_ilo_password}"
litpcrypt set key-for-sfs support "${sfs_password}"

litp create -p /software/profiles/os_prof1 -t os-profile -o name=os-profile1 path=/var/www/html/6/os/x86_64/
litp create -t yum-repository -p /software/items/yum_osHA_repo -o name="osHA" base_url="http://ms1dot28/6/os/x86_64/HighAvailability"

litp create -p /software/items/ntp1 -t ntp-service
litp create -p /ms/configs/alias_config -t alias-node-config
# MS Alias
litp create -p /ms/configs/alias_config/aliases/ntp_alias1 -t alias -o alias_names=ntpAlias1 address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/ntp_alias2 -t alias -o alias_names=ntpAlias2 address=127.127.1.0
litp create -p /ms/configs/alias_config/aliases/ipv6_alias -t alias -o alias_names=vmipv6 address=fdde:4d7e:d471:46::28:1

litp create -p /infrastructure/systems/sys1 -t blade -o system_name=CZ3217FFJ2

# Added for MS Scalability
for (( i=0; i<70; i++ )); do
    litp create -p /ms/configs/alias_config/aliases/test_alias$(($i+1)) -t alias -o alias_names="testalias$(($i+1))" address="${ntp_ip[1]}"
    litp create -p /ms/configs/alias_config/aliases/test_alias000$(($i+2)) -t alias -o alias_names="testalias00$(($i+2))" address="${ntp_ip[2]}"
done

litp create -t alias -p /ms/configs/alias_config/aliases/duplicate_alias_names_01 -o alias_names="primary-alias-names-01,secondary-name" address="127.0.0.1"
litp create -t alias -p /ms/configs/alias_config/aliases/duplicate_alias_names_02 -o alias_names="primary-alias-names-02,secondary-name,tertiary-name" address="127.0.0.1"
litp create -t alias -p /ms/configs/alias_config/aliases/duplicate_alias_names_03 -o alias_names="primary-alias-names-03,secondary-name,tertiary-name,quaternary-name" address="127.0.0.1"
litp create -t alias -p /ms/configs/alias_config/aliases/duplicate_alias_names_04 -o alias_names="primary-alias-names-04,secondary-name,tertiary-name,quaternary-name" address="127.0.0.1"

litp create -p /software/items/ntp1/servers/server0 -t ntp-server -o server=ntpAlias1
litp create -p /software/items/ntp1/servers/server1 -t ntp-server -o server=ntpAlias2

litp create  -t disk -p /infrastructure/systems/sys1/disks/d1 -o name="hd0" size=558G bootable="true" uuid=$ms_disk_uuid

#### MS Storage Profile ######
litp create -p /infrastructure/storage/storage_profiles/profile_ms -t storage-profile -o volume_driver=lvm
litp create -p /infrastructure/storage/storage_profiles/profile_ms/volume_groups/vg1 -t volume-group -o volume_group_name=vg_root
litp create -p /infrastructure/storage/storage_profiles/profile_ms/volume_groups/vg1/file_systems/dataA -t file-system -o type=ext4 mount_point=/dataA size=500M
litp create -p /infrastructure/storage/storage_profiles/profile_ms/volume_groups/vg1/file_systems/msvmFS -t file-system -o type=ext4 size=2G
litp create -p /infrastructure/storage/storage_profiles/profile_ms/volume_groups/vg1/file_systems/msfilesystemtest -t file-system -o type=ext4 size=2G
for (( i=0; i<20; i++)); do
    litp create -p /infrastructure/storage/storage_profiles/profile_ms/volume_groups/vg1/file_systems/morefilesystems$(($i+1)) -t file-system -o type=ext4 size=200M mount_point=/moreFS$(($i+1)) backup_snap_size=$(($i+1))
done
# Add MS Kickstarted filesystems
litp create -p /infrastructure/storage/storage_profiles/profile_ms/volume_groups/vg1/file_systems/root -t file-system -o type=ext4 mount_point=/ size=15G snap_size=100
litp create -p /infrastructure/storage/storage_profiles/profile_ms/volume_groups/vg1/file_systems/var -t file-system -o type=ext4 mount_point=/var size=15G snap_size=100 backup_snap_size=50
litp create -p /infrastructure/storage/storage_profiles/profile_ms/volume_groups/vg1/file_systems/home -t file-system -o type=ext4 mount_point=/home size=6G snap_size=100 backup_snap_size=10

litp create -p /infrastructure/storage/storage_profiles/profile_ms/volume_groups/vg1/physical_devices/internal -t physical-device -o device_name=hd0

litp inherit -p /ms/storage_profile -s /infrastructure/storage/storage_profiles/profile_ms

litp create -p /ms/services/cobbler -t cobbler-service
litp create -p /infrastructure/storage/storage_profiles/profile_1 -t storage-profile
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1 -t volume-group -o volume_group_name=vg_root
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/root -t file-system -o type=ext4 mount_point=/ size=8G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/swap -t file-system -o type=swap mount_point=swap size=2G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/internal -t physical-device -o device_name=hd0

litp create -p /infrastructure/networking/routes/r1 -t route -o subnet=0.0.0.0/0 gateway=10.44.86.1
litp create -p /infrastructure/networking/networks/mgmt -t network -o name=mgmt subnet=10.44.86.0/26 litp_management=true

litp create -p /infrastructure/networking/networks/heartbeat1 -t network -o name=hb1
litp create -p /infrastructure/networking/networks/heartbeat2 -t network -o name=hb2

litp create -p /infrastructure/networking/networks/traffic1 -t network -o name=traffic1 subnet=192.168.100.0/24
litp create -p /infrastructure/networking/networks/traffic2 -t network -o name=traffic2 subnet=192.168.200.128/24

litp inherit -p /ms/system -s /infrastructure/systems/sys1
litp create -p /ms/network_interfaces/if0 -t eth -o device_name=eth0 macaddress=98:4B:E1:02:74:AA network_name=traffic1 ipaddress=192.168.100.97
litp create -p /ms/network_interfaces/vlan834 -t vlan -o device_name=eth0.834 network_name=mgmt ipaddress=10.44.86.28


# MS Firewalls
litp create -p /ms/configs/fw_config_init -t firewall-node-config
litp create -p /ms/configs/fw_config_init/rules/fw_icmp -t firewall-rule -o name="100 icmp" proto=icmp
litp create -p /ms/configs/fw_config_init/rules/fw_icmpv6 -t firewall-rule -o name="099 icmpv6" proto="ipv6-icmp" provider=ip6tables
litp create -p /ms/configs/fw_config_init/rules/fw_nfsudp -t firewall-rule -o name='011 nfsudp' dport=111,2049,4001 proto=udp
litp create -p /ms/configs/fw_config_init/rules/fw_nfstcp -t firewall-rule -o name='001 nfstcp' dport=111,2049,4001 proto=tcp
litp create -p /ms/configs/fw_config_init/rules/fw_dnstcp -t firewall-rule -o name='200 dnstcp' dport=53 proto=tcp
litp create -p /ms/configs/fw_config_init/rules/fw_dnsudp -t firewall-rule -o name='201 dnsudp' dport=53 proto=udp
litp create -p /ms/configs/fw_config_init/rules/fw_hyperic_server_in -t firewall-rule -o action=accept chain=INPUT dport=57004,57005 'name=112 hyperic tcp agent to server ports' proto=tcp state=NEW
litp create -p /ms/configs/fw_config_init/rules/fw_hyperic_server_out -t firewall-rule -o action=accept chain=OUTPUT dport=57006 'name=113 hyperic tcp server to agent port' proto=tcp state=NEW
litp create -p /ms/configs/fw_config_init/rules/fw_sfsudp -t firewall-rule -o action=accept dport=111,2049,4011,4001 'name=013 sfsudp' proto=udp state=NEW
litp create -p /ms/configs/fw_config_init/rules/fw_sfstcp -t firewall-rule -o action=accept dport=111,2049,4011,4001 'name=012 sfstcp' proto=tcp state=NEW
litp create -p /ms/configs/fw_config_init/rules/fw_vmmonitord -t firewall-rule -o action=accept dport=12987 'name=018 vmmonitord' proto=tcp state=NEW
litp create -p /ms/configs/fw_config_init/rules/fw_dns -t firewall-rule -o action=accept dport=53 'name=021 DNS udp' proto=udp state=NEW
litp create -p /ms/configs/fw_config_init/rules/fw_brs -t firewall-rule -o action=accept dport=1556,2821,4032,13724,13782 'name=022 backuprestore tcp' proto=tcp state=NEW
litp create -p /ms/configs/fw_config_init/rules/fw_ntp -t firewall-rule -o action=accept dport=123 'name=029 NTP udp' proto=tcp state=NEW
litp create -p /ms/configs/fw_config_init/rules/fw_dhcp_tcp -t firewall-rule -o action=accept dport=546,547,647,847 'name=030 DHCP tcp' proto=tcp state=NEW
litp create -p /ms/configs/fw_config_init/rules/fw_dhcp_udp -t firewall-rule -o action=accept dport=546,547,647,847 'name=031 DHCP udp' proto=udp state=NEW
litp create -p /ms/configs/fw_config_init/rules/fw_cobbler -t firewall-rule -o action=accept dport=25150,25151 'name=032 cobbler' proto=udp state=NEW
litp create -p /ms/configs/fw_config_init/rules/fw_cobbler_tcp -t firewall-rule -o action=accept dport=25150,25151 'name=033 cobbler' proto=tcp state=NEW
litp create -p /ms/configs/fw_config_init/rules/fw_nexus -t firewall-rule -o action=accept dport=8080,8443 'name=034 nexus tcp' proto=tcp state=NEW
litp create -p /ms/configs/fw_config_init/rules/fw_lserv -t firewall-rule -o action=accept dport=5093 'name=035 lserv' proto=udp state=NEW
litp create -p /ms/configs/fw_config_init/rules/fw_rpcbind -t firewall-rule -o action=accept dport=676 'name=036 rpcbind' proto=udp state=NEW
litp create -p /ms/configs/fw_config_init/rules/fw_loop_back -t firewall-rule -o action=accept iniface=lo 'name=02 loop back' proto=all
litp create -p /ms/configs/fw_config_init/rules/fw_http_allow_int -t firewall-rule -o action=accept provider=iptables dport=80 'name=106 allow http internal' proto=tcp state=NEW source=10.247.244.0/22
litp create -p /ms/configs/fw_config_init/rules/fw_http_allow_stor -t firewall-rule -o action=accept dport=80 'name=102 allow http storage' proto=tcp state=NEW provider=iptables source=10.140.2.0/24
litp create -p /ms/configs/fw_config_init/rules/fw_http_allow_serv -t firewall-rule -o action=accept dport=80 'name=103 allow http services' proto=tcp state=NEW provider=iptables source=10.151.9.128/26
litp create -p /ms/configs/fw_config_init/rules/fw_http_allow_bkp -t firewall-rule -o action=accept dport=80 'name=104 allow http backup' proto=tcp state=NEW provider=iptables source=10.151.24.0/23
litp create -p /ms/configs/fw_config_init/rules/fw_http_block -t firewall-rule -o action=accept dport=80 'name=105 drop http' proto=tcp state=NEW provider=iptables

litp inherit -p /ms/routes/r1 -s /infrastructure/networking/routes/r1
litp inherit -p /ms/items/ntp -s /software/items/ntp1

# MS Packages
litp create -p /software/items/cups -t package -o name=cups
litp inherit -p /ms/items/cups -s /software/items/cups
litp create -p /software/items/postfix -t package -o name=postfix
litp inherit -p /ms/items/postfix -s /software/items/postfix
litp create -p /software/items/httpd -t package -o name=httpd
litp create -t package -p /software/items/jdk -o name=jdk
litp inherit -p /ms/items/java -s /software/items/jdk

# New Repo
litp import /tmp/hello_pkg/ /var/www/html/helloRepo
litp create -t yum-repository -p /software/items/hellorepo -o name="hello_test" ms_url_path=/helloRepo
litp inherit -p /ms/items/hellorepo -s /software/items/hellorepo

# Package Lists
litp create -t package-list -p /software/items/hello_pkg_list -o name=hello_pkg_list
litp create -t package -p /software/items/hello_pkg_list/packages/hello_1 -o name=3PP-czech-hello
litp create -t package -p /software/items/hello_pkg_list/packages/hello_2 -o name=3PP-english-hello
litp create -t package -p /software/items/hello_pkg_list/packages/hello_3 -o name=3PP-dutch-hello
litp create -t package -p /software/items/hello_pkg_list/packages/hello_4 -o name=3PP-finnish-hello
litp create -t package -p /software/items/hello_pkg_list/packages/hello_5 -o name=3PP-german-hello
litp create -t package -p /software/items/hello_pkg_list/packages/hello_6 -o name=3PP-irish-hello
litp create -t package -p /software/items/hello_pkg_list/packages/hello_7 -o name=3PP-swedish-hello
litp inherit -p /ms/items/test_package -s /software/items/hello_pkg_list

litp create -t package-list -p /software/items/second_pkg_list -o name=second_pkg_list
litp create -t package -p /software/items/second_pkg_list/packages/package_test1 -o name=3PP-serbian-hello
litp create -t package -p /software/items/second_pkg_list/packages/package_test2 -o name=3PP-russian-hello
litp inherit -p /ms/items/test_package2 -s /software/items/second_pkg_list

# Install 40 test packages on MS
for (( i=0; i<40; i++ )); do
    litp import /tmp/lsb_pkg/EXTR-lsbwrapper$(($i+1))-2.0.0.rpm 3pp
    litp create -p /software/items/lsb_pack$(($i+1)) -t package -o name="EXTR-lsbwrapper$(($i+1))"
    litp inherit -p /ms/items/lsb_pack$(($i+1)) -s /software/items/lsb_pack$(($i+1))
done

litp create -p /infrastructure/networking/networks/net1vm -t network -o name=net1vm subnet="${net1vm_subnet}"

# MS Bridging
litp create -p /ms/network_interfaces/if2 -t eth -o device_name=eth2 macaddress="${ms_eth2_mac}"
litp create -p /ms/network_interfaces/br2 -t bridge -o device_name=br2 network_name=net1vm ipaddress="${net1vm_ip_ms}" multicast_snooping=1 multicast_querier=0 multicast_router=2 hash_max=512
litp create -p /ms/network_interfaces/vlan911 -t vlan -o device_name=eth2.911 bridge=br2

# Sentinel
litp create -t package -p /software/items/sentinel -o name=EXTRlitpsentinellicensemanager_CXP9031488
litp inherit -p /ms/items/sentinel -s /software/items/sentinel
litp create -t service -p /ms/services/sentinel -o service_name=sentinel
litp create -t service -p /software/services/sentinel -o service_name=sentinel
litp inherit -p /software/services/sentinel/packages/sentinel -s /software/items/sentinel

# Service with different name as package (TORF-114306)
litp import /tmp/test_service_name-2.0-1.noarch.rpm 3pp
litp create -t package -p /software/items/diff_service_pack -o name=test_service_name
litp create -t service -p /ms/services/diff_service -o service_name=diff_service
litp inherit -p /ms/services/diff_service/packages/diff_service_pack -s /software/items/diff_service_pack

# SETUP THE VM_IMAGE
/usr/bin/md5sum /var/www/html/images/image_with_ocf.qcow2 | cut -d ' ' -f 1 > /var/www/html/images/image_with_ocf.qcow2.md5

# MS VM Service
litp create -p /software/images/image1 -t vm-image -o name="MS_SG_vm1" source_uri="http://${ms_ip}/images/image_with_ocf.qcow2"
litp create -p /ms/services/ms_vmservice1 -t vm-service -o service_name="MSSTvmserv1" image_name="MS_SG_vm1" cpus=2 ram=2000M internal_status_check=off
litp create -p /ms/services/ms_vmservice1/vm_network_interfaces/vm_nic1 -t vm-network-interface -o device_name=eth0 host_device=br2 network_name=net1vm ipaddresses="${ms_vm_ip[0]}" gateway=${net1vm_gateway} ipv6addresses="${ms_vm_ip6[0]}" gateway6=${net1vm_gateway6}
litp create -p /ms/services/ms_vmservice1/vm_aliases/stms -t vm-alias -o alias_names=stms address=${net1vm_ip_ms}
litp create -p /ms/services/ms_vmservice1/vm_aliases/stms_ipv6 -t vm-alias -o alias_names=ipv6stms address=fdde:4d7e:d471:46::28:1
litp create -p /ms/services/ms_vmservice1/vm_aliases/stnode1 -t vm-alias -o alias_names=stnode1 address=${net1vm_ip[0]}
litp create -p /ms/services/ms_vmservice1/vm_aliases/stnode2 -t vm-alias -o alias_names=stnode2 address=${net1vm_ip[1]}
litp create -p /ms/services/ms_vmservice1/vm_yum_repos/os -t vm-yum-repo -o name=os base_url="http://${net1vm_ip_ms}/6/os/x86_64"
litp create -p /ms/services/ms_vmservice1/vm_yum_repos/updates -t vm-yum-repo -o name=rhelPatches base_url="http://${net1vm_ip_ms}/6/updates/x86_64/Packages"
litp create -p /ms/services/ms_vmservice1/vm_packages/wireshark -t vm-package -o name=wireshark
litp create -p /ms/services/ms_vmservice1/vm_packages/firefox -t vm-package -o name=firefox
litp create -p /ms/services/ms_vmservice1/vm_ssh_keys/sshkey1 -t vm-ssh-key -o 'ssh_key=ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAgEAxMEYvlt5OvXmPNyMP/QM/mAcDk0KpOgUg7PZNXz6jRU5d99a4cndSHIyoLYyP/4EuCVNUWsjCMFsm/B06zOlCxs6XNAId+bSiABF1Vr5XzjUiFRRqsV1hM7FrFBvImYYgKCLag5xwRhajJAdu/4J+ZgRmHOsHfeRJJoVWnVzjvDOSMSiYf+Lo8dYywy94tyNll4RnXKu4D6bqwSn9YEsJX03gzijwPDTdnMVGj+/+8NxwWbc6BzV0GX5QqY/FnZ6/yuC0jxjizYEaH56PIbkRmK2wNSewjEZDhFCAm0+JWJ1bPrmJXErP3X1KBKFZSpDyHPyLQNB280PwX0jXu+KVNXAbQQXx0sNi2+Qmrx3KnhJlKyJdw2W1qf5OdsL6arDduZB/aWR0xxVPvHHPh18lrhgJMm8dHgfNDTqISabpWQtdJOUbCssvLEOjeZoVlehnENWbI4+zfDNq/gwr3PJfzFOcWimwvZK8FlV1NfuzOgzMbmS1deQUb7wJ6YivlrIEHhElbjoXTfEw+eAhhTroJJ4YVIM/v2MoHe/aGBxsXl01xv7TZAWPppPPGJ+4R7qKKr4+XpkPSGJn1nBKd71cD4L4cSKy0Pqac+fw4Tt9kQ+SIwQYe8gbdXnvQdqpvTv/e+r5IA3QsRuktwV/tTCx++9ghXSJhtUpF2Mqgr+9R6= key3@localhost.localdomain'
# vm-disk
litp create -t vm-disk -p /ms/services/ms_vmservice1/vm_disks/vm_disk1 -o host_volume_group=vg1 host_file_system=msvmFS mount_point=/ms_vm_disk

# vm-ram-mount
litp create -t vm-ram-mount -p /ms/services/ms_vmservice1/vm_ram_mounts/vm_ram_mnt -o type=ramfs mount_point="/mnt/ramfs" mount_options="size=512M,noexec,nodev,nosuid"

# Sysparams
litp create -t sysparam-node-config -p /ms/configs/sysctl_1
litp create -t sysparam -p /ms/configs/sysctl_1/params/sysctl1 -o key="kernel.threads-max" value="4598222"
#litp create -t sysparam -p /ms/configs/sysctl_1/params/sysctl23 -o key="vm.dirty_background_ratio" value="13"
litp create -t sysparam -p /ms/configs/sysctl_1/params/sysctl24 -o key="net.core.rmem_max" value="6489382"
#litp create -t sysparam -p /ms/configs/sysctl_1/params/sysctl25 -o key="vm.swappiness" value="8"
litp create -t sysparam -p /ms/configs/sysctl_1/params/sysctl26 -o key="net.core.wmem_max" value="840000"
litp create -t sysparam -p /ms/configs/sysctl_1/params/sysctl27 -o key="net.core.wmem_default" value="654982"
litp create -t sysparam -p /ms/configs/sysctl_1/params/sysctl28 -o key="debug.kprobes-optimization" value="0"
litp create -t sysparam -p /ms/configs/sysctl_1/params/sysctl29 -o key="net.core.rmem_default" value="6489382"
#litp create -t sysparam -p /ms/configs/sysctl_1/params/sysctl30 -o key="vm.nr_hugepages" value="55321"
#litp create -t sysparam -p /ms/configs/sysctl_1/params/sysctl31 -o key="vm.hugetlb_shm_group" value="300"
litp create -t sysparam -p /ms/configs/sysctl_1/params/sysctl32 -o key="net.ipv6.conf.default.autoconf" value="0"
litp create -t sysparam -p /ms/configs/sysctl_1/params/sysctl33 -o key="net.ipv6.conf.default.accept_ra" value="0"
litp create -t sysparam -p /ms/configs/sysctl_1/params/sysctl34 -o key="net.ipv6.conf.default.accept_ra_defrtr" value="0"
litp create -t sysparam -p /ms/configs/sysctl_1/params/sysctl35 -o key="net.ipv6.conf.default.accept_ra_rtr_pref" value="0"
litp create -t sysparam -p /ms/configs/sysctl_1/params/sysctl36 -o key="net.ipv6.conf.default.accept_ra_pinfo" value="0"
litp create -t sysparam -p /ms/configs/sysctl_1/params/sysctl37 -o key="net.ipv6.conf.default.accept_source_route" value="0"
litp create -t sysparam -p /ms/configs/sysctl_1/params/sysctl38 -o key="net.ipv6.conf.default.accept_redirects" value="0"
litp create -t sysparam -p /ms/configs/sysctl_1/params/sysctl39 -o key="net.ipv6.conf.all.autoconf" value="0"
litp create -t sysparam -p /ms/configs/sysctl_1/params/sysctl40 -o key="net.ipv6.conf.all.accept_ra" value="0"
litp create -t sysparam -p /ms/configs/sysctl_1/params/sysctl41 -o key="net.ipv6.conf.all.accept_ra_defrtr" value="0"
litp create -t sysparam -p /ms/configs/sysctl_1/params/sysctl42 -o key="net.ipv6.conf.all.accept_ra_rtr_pref" value="0"
litp create -t sysparam -p /ms/configs/sysctl_1/params/sysctl43 -o key="net.ipv6.conf.all.accept_ra_pinfo" value="0"
litp create -t sysparam -p /ms/configs/sysctl_1/params/sysctl44 -o key="net.ipv6.conf.all.accept_source_route" value="0"
litp create -t sysparam -p /ms/configs/sysctl_1/params/sysctl45 -o key="net.ipv6.conf.all.accept_redirects" value="0"

# Install packages from imported ENM ISO
litp load -p /software -f /tmp/enm_package_2.xml --merge
litp inherit -p /ms/items/model_repo -s /software/items/model_repo
litp inherit -p /ms/items/model_package -s /software/items/model_package
litp inherit -p /ms/items/ms_repo -s /software/items/ms_repo
litp inherit -p /ms/items/common_repo -s /software/items/common_repo
litp inherit -p /ms/items/db_repo -s /software/items/db_repo
litp inherit -p /ms/items/services_repo -s /software/items/services_repo

litp create_plan
