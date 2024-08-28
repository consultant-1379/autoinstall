#!/bin/bash
#
# Sample LITP multi-blade deployment (SAN version)
#
# Deployment used for 10.44.86.90
#
# Usage:
#   ST_Deployment_12.sh <CLUSTER_SPEC_FILE>
##

litp update -p /litp/logging -o force_debug=true

if [ "$#" -lt 1 ]; then
    echo -e "Usage:\n  $0 <CLUSTER_SPEC_FILE>" >&2
    exit 1
fi

cluster_file="$1"
source "$cluster_file"

set -x

litpcrypt set key-for-root root "${nodes_ilo_password}"
litpcrypt set key-for-sfs support "${nas_password}"

# Plugin Install
for (( i=0; i<${#rpms[@]}; i++ )); do
    # import plugin into litp repo
    litp import "/tmp/${rpms[$i]}" litp
    # install plugin 
    expect /tmp/root_yum_install_pkg.exp "${ms_host}" "${rpms[$i]%%-*}"
done

# ENM ISO import commands
#expect /tmp/root_import_iso.exp "${ms_host}" "${enm_iso}"
#litp load -p /software -f /tmp/enm_package_2.xml --merge
#litp inherit -p /ms/items/model_repo -s /software/items/model_repo
#litp inherit -p /ms/items/model_package -s /software/items/model_package
#litp inherit -p /ms/items/ms_repo -s /software/items/ms_repo
#litp inherit -p /ms/items/common_repo -s /software/items/common_repo
#litp inherit -p /ms/items/db_repo -s /software/items/db_repo
#litp inherit -p /ms/items/services_repo -s /software/items/services_repo

litp update -p /litp/logging -o force_debug=true

litp create -p /software/profiles/os_prof1 -t os-profile -o name=os-profile1 path=/var/www/html/6/os/x86_64/
litp create -p /software/items/snap_validation -t tag-model-item -o snapshot_tag=validation deployment_tag=node
litp create -p /software/items/snap_sanitisation -t tag-model-item -o snapshot_tag=sanitisation deployment_tag=node
litp create -p /software/items/snap_san -t tag-model-item -o snapshot_tag=san deployment_tag=node
litp create -p /software/items/snap_pre_op -t tag-model-item -o snapshot_tag=pre_op deployment_tag=node
litp create -p /software/items/snap_post_op -t tag-model-item -o snapshot_tag=post_op deployment_tag=node
litp create -p /software/items/snap_prep_pup -t tag-model-item -o snapshot_tag=prep_puppet deployment_tag=node

litp create -p /deployments/d1 -t deployment
litp create -p /deployments/d1/clusters/c1 -t vcs-cluster -o cluster_type=sfha low_prio_net=mgmt default_nic_monitor=mii llt_nets=heartbeat1,heartbeat2 cluster_id="${vcs_cluster_id}" critical_service="SG_cups" app_agent_num_threads=1
#litp create -t clustered-service -p /deployments/d1/clusters/c1/services/PMmed -o active=1 standby=1 name=PMmed
litp create -p /ms/services/cobbler -o pxe_boot_timeout=360 -t cobbler-service
litp create -p /infrastructure/systems/sys1 -t blade -o system_name="${ms_sysname}"

# Create storage volume group 1
litp create -p /infrastructure/storage/storage_profiles/profile_1 -t storage-profile #-o storage_profile_name=sp1
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1 -t volume-group -o volume_group_name=vg_root
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/internal -t physical-device -o device_name=hd0
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/internal1 -t physical-device -o device_name=s1
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/internal2 -t physical-device -o device_name=s2
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/root -t file-system -o type=ext4 mount_point=/ size=8G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/swap -t file-system -o type=swap mount_point=swap size=2G
for (( i=0; i<2; i++ )); do
        litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/VG1_FS$i -t file-system -o type=ext4 mount_point=/mp_VG1_FS$i size=200M snap_size=$((100-($i * 10)))
done

# Setup MS disk and storage_profile with FS
litp create -t disk -p /infrastructure/systems/sys1/disks/d1 -o name="hd0_1" size=550G bootable="true" uuid=$ms_disk_uuid
litp create -t storage-profile -p /infrastructure/storage/storage_profiles/sp3
litp create -t volume-group -p /infrastructure/storage/storage_profiles/sp3/volume_groups/vg1 -o volume_group_name="vg_root"
litp create -t file-system -p /infrastructure/storage/storage_profiles/sp3/volume_groups/vg1/file_systems/fs1 -o type="ext4" mount_point="/mount_ms_fs1" size="100M" snap_size="5" snap_external="false"
litp create -t file-system -p /infrastructure/storage/storage_profiles/sp3/volume_groups/vg1/file_systems/fs2 -o type="ext4" mount_point="/mount_ms_fs2" size="100M" snap_size="0" backup_snap_size=0 snap_external="false"
litp create -t file-system -p /infrastructure/storage/storage_profiles/sp3/volume_groups/vg1/file_systems/fs3 -o type="ext4" size="100M" snap_size="10" snap_external="false"
# MS KS FS modelling
litp create -t file-system -p /infrastructure/storage/storage_profiles/sp3/volume_groups/vg1/file_systems/root -o type=ext4 mount_point=/ size=15G snap_size=100 backup_snap_size=100
litp create -t file-system -p /infrastructure/storage/storage_profiles/sp3/volume_groups/vg1/file_systems/home -o type=ext4 mount_point=/home size=6G snap_size=100 backup_snap_size=100
litp create -t file-system -p /infrastructure/storage/storage_profiles/sp3/volume_groups/vg1/file_systems/var_log -o type=ext4 mount_point=/var/log size=22G snap_size=0 backup_snap_size=100
litp create -t file-system -p /infrastructure/storage/storage_profiles/sp3/volume_groups/vg1/file_systems/var_www -o type=ext4 mount_point=/var/www size=72G snap_size=100 backup_snap_size=100
litp create -t file-system -p /infrastructure/storage/storage_profiles/sp3/volume_groups/vg1/file_systems/var -o type=ext4 mount_point=/var size=20G snap_size=100 backup_snap_size=100
litp create -t file-system -p /infrastructure/storage/storage_profiles/sp3/volume_groups/vg1/file_systems/software -o type=ext4 mount_point=/software size=50G snap_size=0 backup_snap_size=0

litp create -t physical-device -p /infrastructure/storage/storage_profiles/sp3/volume_groups/vg1/physical_devices/pd1 -o device_name="hd0_1"
litp inherit -p /ms/storage_profile -s /infrastructure/storage/storage_profiles/sp3





# Create storage volume group 2
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg2 -t volume-group -o volume_group_name=vg_secondDisk
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg2/physical_devices/internal -t physical-device -o device_name=hd1
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg2/physical_devices/internal1 -t physical-device -o device_name=s3
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg2/physical_devices/internal2 -t physical-device -o device_name=s4
for (( i=0; i<3; i++ )); do
        litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg2/file_systems/VG2FS$i -t file-system -o type=ext4 mount_point=/mp_VG2_FS$i size=500M snap_size=$((100-($i * 10))) backup_snap_size=$((100-($i * 10)))
done
# done (VG1 and VG2)

### NTP ###
litp create -t ntp-service -p /software/items/ntp1


# ALIASES FOR THE MANAGEMENT SERVER
litp create -p /ms/configs/alias_configuration -t alias-node-config
litp create -p /ms/configs/alias_configuration/aliases/test_alias_001 -t alias -o alias_names="test-alias-001" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_002 -t alias -o alias_names="test-alias-002" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_003 -t alias -o alias_names="test-alias-003" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_004 -t alias -o alias_names="test-alias-004" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_005 -t alias -o alias_names="test-alias-005" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_006 -t alias -o alias_names="test-alias-006" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_007 -t alias -o alias_names="test-alias-007" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_008 -t alias -o alias_names="test-alias-008" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_009 -t alias -o alias_names="test-alias-009" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_010 -t alias -o alias_names="test-alias-010" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_011 -t alias -o alias_names="test-alias-011" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_012 -t alias -o alias_names="test-alias-012" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_013 -t alias -o alias_names="test-alias-013" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_014 -t alias -o alias_names="test-alias-014" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_015 -t alias -o alias_names="test-alias-015" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_016 -t alias -o alias_names="test-alias-016" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_017 -t alias -o alias_names="test-alias-017" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_018 -t alias -o alias_names="test-alias-018" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_019 -t alias -o alias_names="test-alias-019" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_020 -t alias -o alias_names="test-alias-020" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_021 -t alias -o alias_names="test-alias-021" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_022 -t alias -o alias_names="test-alias-022" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_023 -t alias -o alias_names="test-alias-023" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_024 -t alias -o alias_names="test-alias-024" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_025 -t alias -o alias_names="test-alias-025" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_026 -t alias -o alias_names="test-alias-026" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_027 -t alias -o alias_names="test-alias-027" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_028 -t alias -o alias_names="test-alias-028" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_029 -t alias -o alias_names="test-alias-029" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_030 -t alias -o alias_names="test-alias-030" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_031 -t alias -o alias_names="test-alias-031" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_032 -t alias -o alias_names="test-alias-032" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_033 -t alias -o alias_names="test-alias-033" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_034 -t alias -o alias_names="test-alias-034" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_035 -t alias -o alias_names="test-alias-035" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_036 -t alias -o alias_names="test-alias-036" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_037 -t alias -o alias_names="test-alias-037" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_038 -t alias -o alias_names="test-alias-038" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_039 -t alias -o alias_names="test-alias-039" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_040 -t alias -o alias_names="test-alias-040" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_041 -t alias -o alias_names="test-alias-041" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_042 -t alias -o alias_names="test-alias-042" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_043 -t alias -o alias_names="test-alias-043" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_044 -t alias -o alias_names="test-alias-044" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_045 -t alias -o alias_names="test-alias-045" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_046 -t alias -o alias_names="test-alias-046" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_047 -t alias -o alias_names="test-alias-047" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_048 -t alias -o alias_names="test-alias-048" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_049 -t alias -o alias_names="test-alias-049" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_050 -t alias -o alias_names="test-alias-050" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_051 -t alias -o alias_names="test-alias-051" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_052 -t alias -o alias_names="test-alias-052" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_053 -t alias -o alias_names="test-alias-053" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_054 -t alias -o alias_names="test-alias-054" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_055 -t alias -o alias_names="test-alias-055" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_056 -t alias -o alias_names="test-alias-056" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_057 -t alias -o alias_names="test-alias-057" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_058 -t alias -o alias_names="test-alias-058" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_059 -t alias -o alias_names="test-alias-059" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_060 -t alias -o alias_names="test-alias-060" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_061 -t alias -o alias_names="test-alias-061" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_062 -t alias -o alias_names="test-alias-062" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_063 -t alias -o alias_names="test-alias-063" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_064 -t alias -o alias_names="test-alias-064" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_065 -t alias -o alias_names="test-alias-065" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_066 -t alias -o alias_names="test-alias-066" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_067 -t alias -o alias_names="test-alias-067" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_068 -t alias -o alias_names="test-alias-068" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_069 -t alias -o alias_names="test-alias-069" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_070 -t alias -o alias_names="test-alias-070" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_071 -t alias -o alias_names="test-alias-071" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_072 -t alias -o alias_names="test-alias-072" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_073 -t alias -o alias_names="test-alias-073" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_074 -t alias -o alias_names="test-alias-074" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_075 -t alias -o alias_names="test-alias-075" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_076 -t alias -o alias_names="test-alias-076" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_077 -t alias -o alias_names="test-alias-077" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_078 -t alias -o alias_names="test-alias-078" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_079 -t alias -o alias_names="test-alias-079" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_080 -t alias -o alias_names="test-alias-080" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_081 -t alias -o alias_names="test-alias-081" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_082 -t alias -o alias_names="test-alias-082" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_083 -t alias -o alias_names="test-alias-083" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_084 -t alias -o alias_names="test-alias-084" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_085 -t alias -o alias_names="test-alias-085" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_086 -t alias -o alias_names="test-alias-086" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_087 -t alias -o alias_names="test-alias-087" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_088 -t alias -o alias_names="test-alias-088" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_089 -t alias -o alias_names="test-alias-089" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_090 -t alias -o alias_names="test-alias-090" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_091 -t alias -o alias_names="test-alias-091" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_092 -t alias -o alias_names="test-alias-092" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_093 -t alias -o alias_names="test-alias-093" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_094 -t alias -o alias_names="test-alias-094" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_095 -t alias -o alias_names="test-alias-095" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_096 -t alias -o alias_names="test-alias-096" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_097 -t alias -o alias_names="test-alias-097" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_098 -t alias -o alias_names="test-alias-098" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_099 -t alias -o alias_names="test-alias-099" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_100 -t alias -o alias_names="test-alias-100" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_101 -t alias -o alias_names="test-alias-101" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_102 -t alias -o alias_names="test-alias-102" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_103 -t alias -o alias_names="test-alias-103" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_104 -t alias -o alias_names="test-alias-104" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_configuration/aliases/test_alias_105 -t alias -o alias_names="test-alias-105" address="${ntp_ip[1]}"

# PACKAGE LISTS
litp create -p /software/items/model_package_1 -t package-list -o name="additional_software_list_1"
litp create -p /software/items/model_package_1/packages/3PP_russian_hello -t package -o name="3PP-russian-hello-1.0.0-1"
litp create -p /software/items/model_package_1/packages/3PP_german_hello -t package -o name="3PP-german-hello-1.0.0-1"
litp create -p /software/items/model_package_1/packages/3PP_polish_hello -t package -o name="3PP-polish-hello-1.0.0-1"
litp create -p /software/items/model_package_1/packages/3PP_swedish_hello -t package -o name="3PP-swedish-hello-1.0.0-1"
litp create -p /software/items/model_package_1/packages/3PP_dutch_hello -t package -o name="3PP-dutch-hello-1.0.0-1"
litp create -p /software/items/model_package_1/packages/3PP_czech_hello -t package -o name="3PP-czech-hello-1.0.0-1"
litp create -p /software/items/model_package_1/packages/3PP_azerbaijani_in_ear -t package -o name="3PP-azerbaijani-in-ear-1.0.0-1"
litp create -p /software/items/model_package_1/packages/3PP_ejb_in_ear -t package -o name="3PP-ejb-in-ear-1.0.0-1"

litp create -p /software/items/model_package_2 -t package-list -o name="additional_software_list_2"
litp create -p /software/items/model_package_2/packages/3PP_esperanto_in_ear -t package -o name="3PP-esperanto-in-ear-1.0.0-1"
litp create -p /software/items/model_package_2/packages/3PP_finnish_hello -t package -o name="3PP-finnish-hello-1.0.0-1"
litp create -p /software/items/model_package_2/packages/3PP_french_hello -t package -o name="3PP-french-hello-1.0.0-1"
litp create -p /software/items/model_package_2/packages/3PP_hungarian_in_ear -t package -o name="3PP-hungarian-in-ear-1.0.0-1"
litp create -p /software/items/model_package_2/packages/3PP_italian_hello -t package -o name="3PP-italian-hello-1.0.0-1"
litp create -p /software/items/model_package_2/packages/3PP_klingon_hello -t package -o name="3PP-klingon-hello-1.0.0-1"
litp create -p /software/items/model_package_2/packages/3PP_spanish_hello -t package -o name="3PP-spanish-hello-1.0.0-1"

# PACKAGES
litp create -p /software/items/3PP_english_hello -t package -o name="3PP-english-hello-1.0.0-1"
litp create -p /software/items/3PP_irish_hello -t package -o name="3PP-irish-hello-1.0.0-1"

# JDK
litp create -t package -p /software/items/jdk_7u95 -o name=jdk
litp inherit -p /ms/items/jdk_7u95 -s /software/items/jdk_7u95


# INHERIT PACKAGE LISTS AND PACKAGES TO THE MS
litp inherit -p /ms/items/model_package_1 -s /software/items/model_package_1
litp inherit -p /ms/items/model_package_2 -s /software/items/model_package_2
litp inherit -p /ms/items/3PP_english_hello -s /software/items/3PP_english_hello
litp inherit -p /ms/items/3PP_irish_hello -s /software/items/3PP_irish_hello

### Cluster Level Aliases ####
# Alias
litp create -t alias-cluster-config -p /deployments/d1/clusters/c1/configs/alias_config
litp create -t alias -p /deployments/d1/clusters/c1/configs/alias_config/aliases/sfs_alias -o alias_names="sfsAlias","nasAlias" address="${sfs_management_ip}"

# Finished Creating Cluster Level Aliases

### MS Level Aliases ###
litp create -t alias-node-config -p /ms/configs/alias_config

for (( i=0; i<${#ntp_ip[@]}; i++ )); do
    litp create -t alias -p /ms/configs/alias_config/aliases/ntp_alias_$(($i+1)) -o alias_names=ntp-alias-$(($i+1)) address="${ntp_ip[i+1]}"
    litp create -t ntp-server -p /software/items/ntp1/servers/server$(($i+1)) -o server=ntp-alias-$(($i+1))
done

# done with NTP +3


# litp create -t nfs-service -p /infrastructure/storage/storage_providers/nfs_service -o service_name="sfs1" management_ip="${sfs_management_ip}" user_name="master" password="master" service_type="SFS"
# litp create -t nfs-service -p /infrastructure/storage/storage_providers/nfs_service -o service_name="sfs1" management_ip="${sfs_management_ip}" user_name='support' password_key='key-for-sfs' service_type="SFS"


for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp create -p /infrastructure/systems/sys$(($i+2)) -t blade -o system_name="${node_sysname[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk0 -t disk -o name=hd0 size=28G bootable=true uuid="${node_disk_uuid[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk1 -t disk -o name=hd1 size=28G bootable=false uuid="${node_disk1_uuid[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/bmc -t bmc -o ipaddress="${node_bmc_ip[$i]}" username=root password_key=key-for-root
done

litp create -t route   -p /infrastructure/networking/routes/route1 -o subnet="0.0.0.0/0" gateway="${nodes_gateway}"
litp create -t network -p /infrastructure/networking/networks/mgmt -o name=mgmt subnet="${nodes_subnet}" litp_management=true
litp create -t network -p /infrastructure/networking/networks/data -o name=data subnet="${nodes_subnet_ext}" 
litp create -t network -p /infrastructure/networking/networks/data1 -o name=data1
litp create -t network -p /infrastructure/networking/networks/heartbeat1 -o name=heartbeat1
litp create -t network -p /infrastructure/networking/networks/heartbeat2 -o name=heartbeat2
litp create -t network -p /infrastructure/networking/networks/traffic1 -o name=traffic1 # subnet="${traf1_subnet}"
litp create -t network -p /infrastructure/networking/networks/traffic2 -o name=traffic2
litp create -t network -p /infrastructure/networking/networks/xxx1 -o name=xxx1
litp create -t network -p /infrastructure/networking/networks/xxx2 -o name=xxx2
litp create -t network -p /infrastructure/networking/networks/bare_nic -o name=bare_nic
litp create -t network -p /infrastructure/networking/networks/vlan1_node2 -o name=vlan1_node2 subnet="${nodes_subnet_ext}"
litp create -t network -p /infrastructure/networking/networks/subnet_834 -o name=netwk834
litp create -t network -p /infrastructure/networking/networks/subnet_835 -o name=netwk835
litp create -t network -p /infrastructure/networking/networks/subnet_836 -o name=netwk836
litp create -t network -p /infrastructure/networking/networks/subnet_837 -o name=netwk837
litp create -t route6  -p /infrastructure/networking/routes/route1_ipv6  -o subnet=fdde:4e7e:d471:4::898:0:0/64 gateway=fdde:4d7e:d471:1::835:0:01
litp create -t route6  -p /infrastructure/networking/routes/route2_ipv6  -o                subnet=::/0                            gateway=fdde:4d7e:d471:1::835:0:1
litp create -t network -p /infrastructure/networking/networks/net1vm -o name=net1vm subnet="${net1vm_subnet}" 


# MS NICs, bonds and Vlans

litp create -t eth -p /ms/network_interfaces/if0 -o device_name=eth0 macaddress="${ms_eth0_mac}" master=bond0
litp create -t eth -p /ms/network_interfaces/if3 -o device_name=eth3 macaddress="${ms_eth3_mac}" master=bond0
litp create -t bond -p /ms/network_interfaces/b0 -o device_name='bond0' mode=1 ipaddress="${ms_ip}" ipv6address="${ms_ipv6_00}" network_name=mgmt arp_interval=5000 arp_ip_target=10.44.86.65,10.44.86.88,10.44.86.89
# litp create -t vlan -p /ms/network_interfaces/bond0_835 -o device_name='bond0.835' ipaddress="${ms_ip}" ipv6address="${ms_ipv6_00}" network_name=mgmt

# litp create -t eth -p /ms/network_interfaces/if0 -o device_name=eth0 macaddress="${ms_eth0_mac}" ipaddress="${ms_ip}" network_name=mgmt ipv6address="${ms_ipv6_00}"
litp create -t eth -p /ms/network_interfaces/if1 -o device_name=eth1 macaddress="${ms_eth1_mac}" ipaddress="${ms_ip_ext}" network_name=data ipv6address="${ms_ipv6_01}"
litp create -t eth  -p /ms/network_interfaces/if2 -o device_name=eth2 macaddress="${ms_eth2_mac}"
litp create -t vlan -p /ms/network_interfaces/vlan834 -o device_name=eth2.834                     network_name=netwk834 ipv6address="${ms_ipv6_02}"
# litp create -t vlan -p /ms/network_interfaces/vlan835 -o device_name=eth2.835                     network_name=netwk835 ipv6address="${ms_ipv6_03}"
litp create -t vlan -p /ms/network_interfaces/vlan836 -o device_name=eth2.836                     network_name=netwk836 ipv6address="${ms_ipv6_04}"
litp create -t vlan -p /ms/network_interfaces/vlan837 -o device_name=eth2.837                     network_name=netwk837 ipv6address="${ms_ipv6_05}"
# litp create -t vlan -p /ms/network_interfaces/vlan911 -o device_name=eth2.911 bridge=br0
litp create -t bridge -p /ms/network_interfaces/br0 -o device_name=br0 network_name=net1vm ipaddress="${net1vm_ip_ms}" multicast_snooping=0
litp create -t eth -p /ms/network_interfaces/if5 -o device_name=eth5 macaddress=2C:59:E5:3D:E3:DE bridge=br0


# 5 MS routes

litp inherit -p /ms/system -s /infrastructure/systems/sys1
litp inherit -p /ms/items/ntp -s /software/items/ntp1
litp inherit -p /ms/routes/route1 -s /infrastructure/networking/routes/route1
litp inherit -p /ms/routes/route2 -s /infrastructure/networking/routes/route1 	-o subnet="${route2_subnet}" gateway="${nodes_gateway}"
litp inherit -p /ms/routes/route3 -s /infrastructure/networking/routes/route1	-o subnet="${route3_subnet}" gateway="${nodes_gateway}"
litp inherit -p /ms/routes/route4 -s /infrastructure/networking/routes/route1 	-o subnet="${route4_subnet}" gateway="${nodes_gateway}"
litp inherit -p /ms/routes/route5 -s /infrastructure/networking/routes/route1 	-o subnet="${route_subnet_801}" gateway="${nodes_gateway_ext}"
litp inherit -p /ms/routes/route6 -s /infrastructure/networking/routes/route1_ipv6
litp inherit -p /ms/routes/route7 -s /infrastructure/networking/routes/route2_ipv6

litp update -p /ms -o hostname="${ms_host}"


# Adding routes and JDK

for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp create  -p /deployments/d1/clusters/c1/nodes/n$(($i+1)) -t node -o hostname="${node_hostname[$i]}"
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/jdk_7u95 -s /software/items/jdk_7u95
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/system             -s /infrastructure/systems/sys$(($i+2))
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/os                 -s /software/profiles/os_prof1
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/storage_profile    -s /infrastructure/storage/storage_profiles/profile_1
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/ntp1         -s /software/items/ntp1
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/route1      -s /infrastructure/networking/routes/route1
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/route2      -s /infrastructure/networking/routes/route1 -o subnet="${route2_subnet}"    gateway="${ms_gateway}"
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/route3      -s /infrastructure/networking/routes/route1 -o subnet="${route3_subnet}"    gateway="${ms_gateway}"
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/route4      -s /infrastructure/networking/routes/route1 -o subnet="${route4_subnet}"    gateway="${ms_gateway}"
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/route5      -s /infrastructure/networking/routes/route1 -o subnet="${route_subnet_801}" gateway="${ms_gateway}"
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/route1_ipv6 -s /infrastructure/networking/routes/route1_ipv6
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/route2_ipv6 -s /infrastructure/networking/routes/route2_ipv6
done




#  Create Nics

litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if0 	     -o device_name=eth0 macaddress="${node_eth0_mac[0]}" network_name=data ipaddress="${node_ip_ext[0]}" ipv6address="${ipv6_00[0]}"
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if1            -o device_name=eth1 macaddress="${node_eth1_mac[0]}" master=bond0
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if7 	     -o device_name=eth7 macaddress="${node_eth7_mac[0]}" master=bond0
litp create -t bond -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/b0 	     -o device_name='bond0' mode=1 ipv6address="${ipv6_01[0]}" ipaddress="${node_ip[0]}" network_name=mgmt arp_interval=2000 arp_ip_target=10.44.86.65,10.44.86.89 arp_validate=active arp_all_targets=any

#litp create -t bond -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/b1 	     -o device_name='bond1' mode=1 miimon=100 ipv6address="${ipv6_19[0]}" network_name=xxx1
#litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if2 	     -o device_name=eth2 macaddress="${node_eth2_mac[0]}" master=bond1
#litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if3            -o device_name=eth3 macaddress="${node_eth3_mac[0]}" master=bond1

litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if2 	     -o device_name=eth2 macaddress="${node_eth2_mac[0]}" network_name=xxx1 ipv6address="${ipv6_19[0]}"
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if3 	     -o device_name=eth3 macaddress="${node_eth3_mac[0]}" #network_name=xxx2 ipv6address="${ipv6_12[0]}"

#litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/vlan834       -o device_name=eth3.834  network_name=netwk834 ipv6address="${ipv6_11[0]}"
#litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/vlan835       -o device_name=eth3.835  network_name=netwk835 ipv6address="${ipv6_13[0]}"
litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/vlan836       -o device_name=eth3.836  network_name=netwk836 ipv6address="${ipv6_14[0]}" 
litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/vlan837       -o device_name=eth3.837  network_name=netwk837 ipv6address="${ipv6_15[0]}"

litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if4 	     -o device_name=eth4 macaddress="${node_eth4_mac[0]}" network_name=heartbeat1
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if5 	     -o device_name=eth5 macaddress="${node_eth5_mac[0]}" network_name=heartbeat2
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if6 	     -o device_name=eth6 macaddress="${node_eth6_mac[0]}" network_name=traffic1 ipv6address="${ipv6_16[0]}" # ipaddress="${traf1_ip[0]}" 

# TORF-169048
# Set pxe_boot_only=true for eth0 on n2
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if0 	-o device_name=eth0 macaddress="${node_eth0_mac[1]}" pxe_boot_only=true
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if6 	-o device_name=eth6 macaddress="${node_eth6_mac[1]}" master=bond0
litp create -t bond -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/b0 	-o device_name='bond0' mode=1 ipv6address="${ipv6_00[1]}" ipaddress="${node_ip[1]}" network_name=mgmt arp_interval=4000 arp_ip_target=10.44.86.65,10.44.86.88 arp_validate=active arp_all_targets=any
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if1 	-o device_name=eth1 macaddress="${node_eth1_mac[1]}" network_name=data ipaddress="${node_ip_ext[1]}" ipv6address="${ipv6_01[1]}"
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if2 	-o device_name=eth2 macaddress="${node_eth2_mac[1]}" network_name=heartbeat1
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if3 	-o device_name=eth3 macaddress="${node_eth3_mac[1]}" network_name=traffic1 ipv6address="${ipv6_15[1]}" # ipaddress="${traf1_ip[1]}"
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if4 	-o device_name=eth4 macaddress="${node_eth4_mac[1]}" network_name=heartbeat2 
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if5 	-o device_name=eth5 macaddress="${node_eth5_mac[1]}" network_name=traffic2 ipv6address=fdde:4d7e:d471:20::90:150/64
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/nh_traffic2_ipv6_if5 -o network_name=traffic2 ip=fdde:4d7e:d471:20::90:150
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if7 	-o device_name=eth7 macaddress="${node_eth7_mac[1]}"
litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/vlan834       -o device_name=eth7.834  network_name=netwk834 ipv6address="${ipv6_16[1]}"
# litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/vlan835       -o device_name=eth7.835  network_name=netwk835 ipv6address="${ipv6_11[1]}"
litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/vlan836       -o device_name=eth7.836  network_name=netwk836 ipv6address="${ipv6_12[1]}" 
litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/vlan837       -o device_name=eth7.837  network_name=netwk837 ipv6address="${ipv6_13[1]}"



# Bridge for nodes for private network
litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/vlan911 -o device_name=eth3.911 bridge=br1
litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/vlan911 -o device_name=eth7.911 bridge=br1
litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/br1 -o device_name=br1 network_name=net1vm ipaddress="${net1vm_ip[0]}" ipv6address="${Vm_vip_ipv6[1]}"
litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/br1 -o device_name=br1 network_name=net1vm ipaddress="${net1vm_ip[1]}" ipv6address="${Vm_vip_ipv6[2]}"

# Network hosts

litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/traffic1_ipv6_10 -o network_name=traffic1 ip="${ipv6_16[0]}"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/traffic1_ipv6_20 -o network_name=traffic1 ip="${ipv6_15[1]}"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/traffic1_ipv6_30 -o network_name=traffic1 ip="${ipv6_21[0]}"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/traffic1_bare_nic -o network_name=traffic2 ip=${ipv6_20[0]}
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/traf_vm1 -o network_name=net1vm ip="${net1vm_ip[0]}"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/traf_vm2 -o network_name=net1vm ip="${net1vm_ip[1]}"

# Firewall

# MS
litp create -p /ms/configs/fw_config -t firewall-node-config -o drop_all='true'
litp create -p /ms/configs/fw_config/rules/fw_hyperic_server_in -t firewall-rule -o action=accept chain=INPUT dport="57004,57005" name="112 hyperic tcp agent to server ports" proto=tcp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_hyperic_server_out -t firewall-rule -o action=accept chain=OUTPUT dport="57006" name="113 hyperic tcp server to agent port" proto=tcp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_sfsudp -t firewall-rule -o action=accept dport="111,2049,4011,4001" name="011 sfsudp" proto=udp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_sfstcp -t firewall-rule -o action=accept dport="111,2049,4011,4001" name="012 sfstcp" proto=tcp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_vmmonitord -t firewall-rule -o action=accept dport="12987" name="018 vmmonitord" proto=tcp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_dns -t firewall-rule -o action=accept dport="53" name="021 DNS udp" proto=udp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_brs -t firewall-rule -o action=accept dport="1556,2821,4032,13724,13782" name="022 backuprestore tcp" proto=tcp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_ntp -t firewall-rule -o action=accept dport="123" name="029 NTP udp" proto=tcp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_dhcp_tcp -t firewall-rule -o action=accept dport="546,547,647,847" name="030 DHCP tcp" proto=tcp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_dhcp_udp -t firewall-rule -o action=accept dport="546,547,647,847" name="031 DHCP udp" proto=udp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_cobbler -t firewall-rule -o action=accept dport="25150,25151" name="032 cobbler" proto=udp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_cobbler_tcp -t firewall-rule -o action=accept dport="25150,25151" name="033 cobbler" proto=tcp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_nexus -t firewall-rule -o action=accept dport="8080,8443" name="034 nexus tcp" proto=tcp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_lserv -t firewall-rule -o action=accept dport="5093" name="035 lserv" proto=udp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_rpcbind -t firewall-rule -o action=accept dport="676" name="036 rpcbind" proto=udp state=NEW
litp create -p /ms/configs/fw_config/rules/fw_loop_back -t firewall-rule -o action=accept iniface=lo name="01 loop back" proto=all
litp create -p /ms/configs/fw_config/rules/fw_icmp -t firewall-rule -o action=accept name="100 icmp" proto=icmp
litp create -p /ms/configs/fw_config/rules/fw_http_allow_int -t firewall-rule -o action=accept provider="iptables" dport="80" name="101 allow http internal" proto=tcp state=NEW source="10.247.244.0/22"
litp create -p /ms/configs/fw_config/rules/fw_http_allow_stor -t firewall-rule -o action=accept dport="80" name="102 allow http storage" proto=tcp state=NEW provider="iptables" source="10.140.2.0/24"
litp create -p /ms/configs/fw_config/rules/fw_http_allow_serv -t firewall-rule -o action=accept dport="80" name="103 allow http services" proto=tcp state=NEW provider="iptables" source="10.151.9.128/26"
litp create -p /ms/configs/fw_config/rules/fw_http_allow_bkp -t firewall-rule -o action=accept dport="80" name="104 allow http backup" proto=tcp state=NEW provider="iptables" source="10.151.24.0/23"
litp create -p /ms/configs/fw_config/rules/fw_http_block -t firewall-rule -o action=accept dport="80" name="105 drop http" proto=tcp state=NEW provider="iptables"

# CLUSTER
litp create -t firewall-cluster-config -p /deployments/d1/clusters/c1/configs/fw_config
litp create -t firewall-rule -p /deployments/d1/clusters/c1/configs/fw_config/rules/fw_icmp -o 'name=100 icmp' proto=icmp
litp create -t firewall-rule -p /deployments/d1/clusters/c1/configs/fw_config/rules/fw_nfstcp -o 'name=001 nfstcp' dport=111,2049,4001 proto=tcp
litp create -t firewall-rule -p /deployments/d1/clusters/c1/configs/fw_config/rules/fw_icmpv6 -o 'name=101 icmpv6' proto=ipv6-icmp provider=ip6tables
litp create -t firewall-rule -p /deployments/d1/clusters/c1/configs/fw_config/rules/fw_vmhc -o 'name=300 vmhc' proto=tcp dport=12987 provider=iptables
litp create -t firewall-rule -p /deployments/d1/clusters/c1/configs/fw_config/rules/fw_dnsudp -o 'name=201 dnsudp' dport=53 proto=udp
litp create -t firewall-rule -p /deployments/d1/clusters/c1/configs/fw_config/rules/fw_dnstcp -o 'name=200 dnstcp' dport=53 proto=tcp



# NODE
for (( i=0; i<${#node_sysname[@]}; i++ )); do

  litp create -t firewall-node-config -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config
  litp create -t firewall-rule -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config/rules/fw_nfsudp -o 'name=011 nfsudp' dport=111,2049,4001 proto=udp
  litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/snap_validation -s /software/items/snap_validation
  litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/snap_sanitisation -s /software/items/snap_sanitisation
  litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/snap_san -s /software/items/snap_san
  litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/snap_pre_op -s /software/items/snap_pre_op
  litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/snap_post_op -s /software/items/snap_post_op
  litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/snap_prep_pup -s /software/items/snap_prep_pup
done

# add 5 FS

litp create -t sfs-service -p /infrastructure/storage/storage_providers/sfs_service_sp1 -o name="sfs1" management_ipv4="${sfs_management_ip}" user_name='support' password_key='key-for-sfs'

# Add SFS filesystem of minimum size allowed for Path to be created on the sfs
#litp create -t sfs-filesystem -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl1/file_systems/mgmt_fs_test2 -o size=100M path='/vx/X' snap_size=20 cache_name='dot90cashe2'

#Add LVM FS with Name of max allowed length
litp create -t file-system -p /infrastructure/storage/storage_profiles/sp3/volume_groups/vg1/file_systems/test_fs_how_large_can_you_go_0123456 -o type=ext4 mount_point=/mount_ms_fs3_test_length_of_fs_name_3 size=100M snap_size=15 backup_snap_size=15

litp create -t file-system -p /infrastructure/storage/storage_profiles/sp3/volume_groups/vg1/file_systems/X -o type=ext4 mount_point=/mount_ms_fs4 size=100M snap_size=15 backup_snap_size=15
litp create -t sfs-virtual-server -p /infrastructure/storage/storage_providers/sfs_service_sp1/virtual_servers/vs1 -o name="virtserv1" ipv4address="${sfs_vip}"
#Create Multiple SFS Pools with multiple FS,exports and mounts
litp create -t sfs-pool             -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl1 -o name="SFS_Pool"
litp create -t sfs-pool             -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl2 -o name="ST_Pool"
litp create -t sfs-cache            -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl1/cache_objects/cache1 -o name='dot90cache1'
litp create -t sfs-filesystem       -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl1/file_systems/mgmt_fs1 -o path="${sfs_prefix}-fs1" size='10G' cache_name='dot90cache1' snap_size='20'
litp create -t sfs-filesystem       -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl1/file_systems/mgmt_fs2 -o path="${sfs_prefix}-fs2" size='1G' cache_name='dot90cache1' snap_size='15'
litp create -t sfs-filesystem       -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl2/file_systems/mgmt_fs3 -o path="${sfs_prefix}-fs3" size='1G' cache_name='dot90cache1' snap_size='20'
litp create -t sfs-export           -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl1/file_systems/mgmt_fs1/exports/ex1         -o ipv4allowed_clients="${ms_ip_nas},${node_ip_nas[0]},${node_ip_nas[1]}" options="rw,no_root_squash"
litp create -t sfs-export           -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl1/file_systems/mgmt_fs2/exports/ex2         -o ipv4allowed_clients="${ms_ip_nas},${node_ip_nas[0]},${node_ip_nas[1]}" options="rw,no_root_squash"
litp create -t sfs-export           -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl2/file_systems/mgmt_fs3/exports/ex1         -o ipv4allowed_clients="${ms_ip_nas},${node_ip_nas[0]},${node_ip_nas[1]}" options="rw,no_root_squash"

litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mount1 -o export_path="${sfs_prefix}-fs1" provider="virtserv1" mount_point="/sfsmount1" mount_options="soft,intr" network_name="${nas_network}"
litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mount2 -o export_path="${sfs_prefix}-fs2" provider="virtserv1" mount_point="/sfsmount2" mount_options="soft,intr" network_name="${nas_network}"

# till I add them to .231 litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mount3 -o export_path="${sfs_prefix}-fs3" provider="virtserv1" mount_point="/sfsmount3" mount_options="soft,intr" network_name="mgmt"
# till I add them to .231 litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mount4 -o export_path="${sfs_prefix}-fs4" provider="virtserv1" mount_point="/sfsmount4" mount_options="soft,intr" network_name="mgmt"
# till I add them to .231 litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mount5 -o export_path="${sfs_prefix}-fs5" provider="virtserv1" mount_point="/sfsmount5" mount_options="soft,intr" network_name="mgmt"

litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mountArad -o export_path="${sfs_prefix}-fs1" provider="virtserv1" mount_point="/ms_share_sfs" mount_options="soft,intr" network_name="${nas_network}"

for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/file_systems/fs1 -s /infrastructure/storage/nfs_mounts/mount1
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/file_systems/fs2 -s /infrastructure/storage/nfs_mounts/mount2
done

# Extra routes

# litp create -p /infrastructure/networking/routes/traffic1_gw -t route -o subnet=10.19.72.0/24 gateway=10.19.90.0
# litp inherit -p /deployments/d1/clusters/c1/nodes/n1/routes/traffic1_gw -s /infrastructure/networking/routes/traffic1_gw
# litp inherit -p /deployments/d1/clusters/c1/nodes/n2/routes/traffic1_gw -s /infrastructure/networking/routes/traffic1_gw

# Non SFS

#litp create -t nfs-service -p /infrastructure/storage/storage_providers/nas_service_sp1 -o name="nas1" ipv4address="${nfs_management_ip}"
#litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/nm1 -o export_path="${nfs_prefix}/dir_share_90_C" provider="nas1" mount_point="/cluster_ro" mount_options="soft,intr" network_name="mgmt"
#litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/nm2 -o export_path="${nfs_prefix}/dir_share_90_A" provider="nas1" mount_point="/cluster_rw" mount_options="soft,intr" network_name="mgmt"

#litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mountCaransebes -o export_path="${nfs_prefix}/dir_share_90_C" provider="nas1" mount_point="/ms_share_nfs" mount_options="soft,intr" network_name="mgmt"
#litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mountDrobeta -o export_path="${nfs_prefix}/dir_share_90_B" provider="nas1" mount_point="/ms_share_nfs1" mount_options="soft,intr" network_name="mgmt"

#
#for (( i=0; i<${#node_sysname[@]}; i++ )); do
#    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/file_systems/nm1 -s /infrastructure/storage/nfs_mounts/nm1
#    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/file_systems/nm2 -s /infrastructure/storage/nfs_mounts/nm2
#done

#MS
#litp inherit -p /ms/file_systems/fs1 -s /infrastructure/storage/nfs_mounts/mountArad
#litp inherit -p /ms/file_systems/fs3 -s /infrastructure/storage/nfs_mounts/mountCaransebes
#litp inherit -p /ms/file_systems/fs4 -s /infrastructure/storage/nfs_mounts/mountDrobeta

# Diff name service
litp create -p /software/items/diff_name_pkg -t package -o name="test_service_name-2.0-1"
litp create -p /software/services/diff_name_srvc -t service -o service_name="diff_service"
litp inherit -p /software/services/diff_name_srvc/packages/diff_name_pkg -s /software/items/diff_name_pkg
litp create -p /ms/services/diff_name_srvc -t service -o service_name="diff_service"
litp inherit -p /ms/services/diff_name_srvc/packages/diff_name_pkg -s /software/items/diff_name_pkg
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/services/diff_name_srvc -s /software/services/diff_name_srvc
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/services/diff_name_srvc -s /software/services/diff_name_srvc

#Sysparms  
litp create -t sysparam-node-config -p /ms/configs/sysctl
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_thresh_ipv4_3 -o key=net.ipv4.neigh.default.gc_thresh3 value=2048
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_thresh_ipv6_3 -o key=net.ipv6.neigh.default.gc_thresh3 value=2048
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl01 -o key="fs.mqueue.msgsize_max" value="8200"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl02 -o key="dev.raid.speed_limit_min" value="1100"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_enm1 -o key="net.core.rmem_default" -o value="5242880"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_enm2 -o key="net.core.rmem_max" value="5242880"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_enm3 -o key="net.core.wmem_default" value="655360"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_enm4 -o key="net.core.wmem_max" value="655360"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_enm5 -o key="vm.swappiness" value="10"
#litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_enm6 -o key=kernel.core_pattern value="/ericsson/enm/dumps/core.%e.pid%p.usr%u.sig%s.tim%t"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_enm7 -o key="vm.nr_hugepages" value="47104"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_enm8 -o key="vm.hugetlb_shm_group" value="205"
litp create -p /ms/configs/sysctl/params/core_pattern -t sysparam -o key=kernel.core_pattern value="/ericsson/enm/dumps/core.%e.pid%p.usr%u.sig%s.tim%t1"

for (( i=0; i<${#node_sysname[@]}; i++ )); do
 litp create -t sysparam-node-config -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl01 -o key="kernel.threads-max" value="4132410"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl02 -o key="vm.dirty_background_ratio" value="11"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl03 -o key="debug.kprobes-optimization" value="0"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl04 -o key="sunrpc.udp_slot_table_entries" value="15"
#      litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl05 -o key="vxvm.vxio.vol_failfast_on_write" value="2"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_enm1 -o key="net.core.rmem_default" value="5242880"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_enm2 -o key="net.core.rmem_max" value="5242880"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_enm3 -o key="net.core.wmem_default" value="655360"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_enm4 -o key="net.core.wmem_max" value="655360"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_enm5 -o key="vm.swappiness" value="10"
#     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_enm6 -o key="kernel.core_pattern" value="/ericsson/tor/dumps/core.%e.pid%p.usr%u.sig%s.tim%t"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_enm7 -o key="vm.nr_hugepages" value="47104"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_enm8 -o key="vm.hugetlb_shm_group" value="205"
     litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/def_autoconf -t sysparam -o key="net.ipv6.conf.default.autoconf" value="0"
     litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/def_accept_ra -t sysparam -o key="net.ipv6.conf.default.accept_ra" value="0"
     litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/def_accept_ra_defrtr -t sysparam -o key="net.ipv6.conf.default.accept_ra_defrtr" value="0"
     litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/def_accept_ra_rtr_pref -t sysparam -o key="net.ipv6.conf.default.accept_ra_rtr_pref" value="0"
     litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/def_accept_ra_pinfo -t sysparam -o key="net.ipv6.conf.default.accept_ra_pinfo" value="0"
     litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/def_accept_source_route -t sysparam -o key="net.ipv6.conf.default.accept_source_route" value="0"
     litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/def_accept_redirects -t sysparam -o key="net.ipv6.conf.default.accept_redirects" value="0"
     litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/autoconf -t sysparam -o key="net.ipv6.conf.all.autoconf" value="0"
     litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/accept_ra -t sysparam -o key="net.ipv6.conf.all.accept_ra" value="0"
     litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/accept_ra_defrtr -t sysparam -o key="net.ipv6.conf.all.accept_ra_defrtr" value="0"
     litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/accept_ra_rtr_pref -t sysparam -o key="net.ipv6.conf.all.accept_ra_rtr_pref" value="0"
     litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/accept_ra_pinfo -t sysparam -o key="net.ipv6.conf.all.accept_ra_pinfo" value="0"
     litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/accept_source_route -t sysparam -o key="net.ipv6.conf.all.accept_source_route" value="0"
     litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/accept_redirects -t sysparam -o key="net.ipv6.conf.all.accept_redirects" value="0"
done;



# Name servers 

litp create -t dns-client -p /deployments/d1/clusters/c1/nodes/n1/configs/dns_client -o search=ammeonvpn.com,masteroforion123456789.com,ex3.com,ex4444444444444444.com,a5.com,6666666666666666.com
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n1/configs/dns_client/nameservers/name_server_A -o ipaddress="${ipv6_nameserver_ip}" position=1
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n1/configs/dns_client/nameservers/name_server_B -o ipaddress="${ipv4_nameserver_ip}" position=2


litp create -t dns-client -p /deployments/d1/clusters/c1/nodes/n2/configs/dns_client -o search=ammeonvpn.com,masteroforion123456789.com,ex3.com,ex4444444444444444.com,a5.com,6666666666666666.com
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n2/configs/dns_client/nameservers/name_server_A -o ipaddress="${ipv6_nameserver_ip}" position=1
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n2/configs/dns_client/nameservers/name_server_B -o ipaddress="${ipv4_nameserver_ip}" position=2


#node 1 disks

litp create -p /infrastructure/systems/sys2/disks/disk2 -t disk -o name=hd2 size=5G bootable=false uuid="${hd2_uuid[0]}"
litp create -p /infrastructure/systems/sys2/disks/disk3 -t disk -o name=hd3 size=5G bootable=false uuid="${hd3_uuid[0]}"
litp create -p /infrastructure/systems/sys2/disks/disk4 -t disk -o name=s1 size=700M bootable=false uuid="${hd4_uuid[0]}"
litp create -p /infrastructure/systems/sys2/disks/disk5 -t disk -o name=s2 size=700M bootable=false uuid="${hd5_uuid[0]}"
litp create -p /infrastructure/systems/sys2/disks/disk6 -t disk -o name=s3 size=700M bootable=false uuid="${hd6_uuid[0]}"
litp create -p /infrastructure/systems/sys2/disks/disk7 -t disk -o name=s4 size=700M bootable=false uuid="${hd7_uuid[0]}"
litp create -p /infrastructure/systems/sys2/disks/disk8 -t disk -o name="hd8" size=293M bootable=false uuid="${hd8_uuid[0]}"

#node 2 disks

litp create -p /infrastructure/systems/sys3/disks/disk3 -t disk -o name=hd3 size=5G bootable=false uuid="${hd3_uuid[1]}"
litp create -p /infrastructure/systems/sys3/disks/disk2 -t disk -o name=hd2 size=5G bootable=false uuid="${hd2_uuid[1]}"
litp create -p /infrastructure/systems/sys3/disks/disk4 -t disk -o name=s1 size=700M bootable=false uuid="${hd4_uuid[1]}"
litp create -p /infrastructure/systems/sys3/disks/disk5 -t disk -o name=s2 size=700M bootable=false uuid="${hd5_uuid[1]}"
litp create -p /infrastructure/systems/sys3/disks/disk6 -t disk -o name=s3 size=700M bootable=false uuid="${hd6_uuid[1]}"
litp create -p /infrastructure/systems/sys3/disks/disk7 -t disk -o name=s4 size=700M bootable=false uuid="${hd7_uuid[1]}"
litp create -p /infrastructure/systems/sys3/disks/disk8 -t disk -o name="hd8" size=293M bootable=false uuid="${hd8_uuid[1]}" 




litp create -t storage-profile -p /infrastructure/storage/storage_profiles/profile_2 -o volume_driver=vxvm

litp inherit -p /deployments/d1/clusters/c1/storage_profile/sp2 -s /infrastructure/storage/storage_profiles/profile_2

litp create -t volume-group -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vg_vxvm_0 -o volume_group_name=vg_vxvm_0
# litp create -t file-system -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vg_vxvm_0/file_systems/VxVM_VG2_FS_0 -o type=vxfs size=2G snap_size=100 mount_point=/VxVM_mp_VG2_FS0
litp create -t file-system -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vg_vxvm_0/file_systems/VxVMVG2FS0 -o type=vxfs size=2G snap_size=5 mount_point=/VxVM_mp_VG2_FS0 backup_snap_size=5
litp create -t physical-device -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vg_vxvm_0/physical_devices/hd1_vxvm -o device_name=hd2
litp create -t physical-device -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vg_vxvm_0/physical_devices/hd2_vxvm -o device_name="hd8"


litp create -t volume-group -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vg_vxvm_1 -o volume_group_name=vg_vxvm_1
# litp create -t file-system -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vg_vxvm_1/file_systems/VxVM_VG2_FS_1 -o type=vxfs size=2G snap_size=100 mount_point=/VxVM_mp_VG2_FS1
litp create -t file-system -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vg_vxvm_1/file_systems/VxVMVG2FS1 -o type=vxfs size=2G snap_size=0 mount_point=/VxVM_mp_VG2_FS1 backup_snap_size=0
litp create -t physical-device -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vg_vxvm_1/physical_devices/hd1_vxvm -o device_name=hd3



# fencing 

litp create -t disk -p /deployments/d1/clusters/c1/fencing_disks/fd1 -o uuid=6006016011602d00a0840eb51170e411 size=90M name=fencing_disk_1
litp create -t disk -p /deployments/d1/clusters/c1/fencing_disks/fd2 -o uuid=6006016011602d0068e535c91170e411 size=90M name=fencing_disk_2
litp create -t disk -p /deployments/d1/clusters/c1/fencing_disks/fd3 -o uuid=6006016011602d00b2ef50a01170e411 size=90M name=fencing_disk_3


# Service Groups
# 2 F/O SGs - 1st SG #VIP=#AC 2nd SG  #VIP=2x#AC
# 1 PL  SGs -  

x=0
SG_pkg[x]="cups";    SG_rel[x]="79.el6"; SG_ver[x]="1.4.2";    SG_VIP_count[x]=3;      SG_active[x]=1; SG_standby[x]=1 status_interval[x]=30	status_timeout[x]=20	restart_limit[x]=2	startup_retry_limit[x]=1	node_list[x]="n2,n1" dependency_list[x]="SG_httpd" 	   x=$[$x+1]
SG_pkg[x]="luci";    SG_rel[x]="93.el6";     SG_ver[x]="0.26.0";   SG_VIP_count[x]=4;      SG_active[x]=1; SG_standby[x]=1 status_interval[x]=10	status_timeout[x]=10	restart_limit[x]=0	startup_retry_limit[x]=0	node_list[x]="n1,n2" initial_online_dependency_list[x]="SG_cups"  	   x=$[$x+1]
SG_pkg[x]="httpd";   SG_rel[x]="69.el6";   SG_ver[x]="2.2.15";   SG_VIP_count[x]=$[5*2]; SG_active[x]=2; SG_standby[x]=0 status_interval[x]=20	status_timeout[x]=60	restart_limit[x]=10	startup_retry_limit[x]=10 	node_list[x]="n1,n2"					   x=$[$x+1]
# SG_pkg[x]="ricci"; SG_rel[x]="63.el6";     SG_ver[x]="0.16.2";   SG_rel[x]="63.el6"; 	SG_ver[x]="0.16.2";     SG_VIP_count[x]=$[2*2]; SG_active[x]=2; SG_standby[x]=0 status_interval[x]=1000	status_timeout[x]=1000	restart_limit[x]=1000startup_retry_limit[x]=1000	x=$[$x+1]

vip_count=1
for (( x=0; x<${#SG_pkg[@]}; x++ )); do
litp create -t package               -p /software/items/"${SG_pkg[$x]}" -o name="${SG_pkg[$x]}" repository=OS version="${SG_ver[$x]}" release="${SG_rel[$x]}" 
litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}" -o active="${SG_active[$x]}" standby="${SG_standby[$x]}" name=vcs$(($x+1)) online_timeout=45 node_list="${node_list[$x]}" dependency_list="${dependency_list[$x]}"
litp create -t ha-service-config     -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}"/ha_configs/conf1 -o status_interval="${status_interval[$x]}" status_timeout="${status_timeout[$x]}" restart_limit="${restart_limit[$x]}" startup_retry_limit="${startup_retry_limit[$x]}"
litp create -t service           -p /software/services/"${SG_pkg[$x]}" -o service_name="${SG_pkg[$x]}"
litp inherit                     -p /software/services/"${SG_pkg[$x]}"/packages/pkg1 -s /software/items/"${SG_pkg[$x]}"
litp inherit                     -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}"/applications/"${SG_pkg[$x]}" -s /software/services/"${SG_pkg[$x]}"
       for (( i=0; i<${SG_VIP_count[x]}; i++ )); do
               litp create -t vip   -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}"/ipaddresses/t1_ip6${i} -o ipaddress="${traf1_vip_ipv6[$vip_count]}" network_name=traffic1
                vip_count=($vip_count+1)
        done
done


# Add Packages & REPO 
litp create -t yum-repository -p /software/items/yum_osHA_repo -o name="osHA" base_url="http://"${ms_host}"/6/os/x86_64/HighAvailability"
litp inherit -s /software/items/yum_osHA_repo -p /deployments/d1/clusters/c1/nodes/n1/items/yum_osHA_repo
litp inherit -s /software/items/yum_osHA_repo -p /deployments/d1/clusters/c1/nodes/n2/items/yum_osHA_repo

#litp create -t package -p /software/items/openjdk     -o name=java-1.7.0-openjdk
litp create -t package -p /software/items/cups-libs   -o name=cups-libs   version=1.4.2  release=79.el6 repository=OS 
litp create -t package -p /software/items/httpd-tools -o name=httpd-tools version=2.2.15 release=69.el6
#litp inherit -p /ms/items/java -s /software/items/openjdk
for (( i=0; i<${#node_sysname[@]}; i++ )); do
#    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/java        -s /software/items/openjdk
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/httpd-tools -s /software/items/httpd-tools
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/cups-libs   -s /software/items/cups-libs
done;

# Update packages  LITPCDS-7747 
litp update -p /software/items/cups-libs -o epoch=1
litp update -p /software/items/httpd -o epoch=0
litp update -p /software/items/luci -o epoch=0
litp update -p /software/items/cups -o epoch=1


litp inherit -p /deployments/d1/clusters/c1/services/SG_luci/filesystems/fs1 -s /deployments/d1/clusters/c1/storage_profile/sp2/volume_groups/vg_vxvm_0/file_systems/VxVMVG2FS0
litp inherit -p /deployments/d1/clusters/c1/services/SG_luci/filesystems/fs2 -s /deployments/d1/clusters/c1/storage_profile/sp2/volume_groups/vg_vxvm_1/file_systems/VxVMVG2FS1

# Log Rotate

litp create -t logrotate-rule-config -p /deployments/d1/clusters/c1/nodes/n2/configs/logrotate
litp create -t logrotate-rule -p /deployments/d1/clusters/c1/nodes/n2/configs/logrotate/rules/exampleservice -o name="exampleservice" path="/var/log/exampleservice/exampleservice.log" missingok=true ifempty=true rotate=4 copytruncate=true
litp create -t logrotate-rule -p /deployments/d1/clusters/c1/nodes/n2/configs/logrotate/rules/exampleservice_tasks -o name="exampleservice_tasks" path="/var/log/exampleservice/tasks/*.log" copytruncate=true rotate=0 missingok=true ifempty=true compress=false create=false


litp create -t logrotate-rule-config -p /ms/configs/logrotate
litp create -t logrotate-rule -p /ms/configs/logrotate/rules/exampleservice -o name="exampleservice" path="/var/log/exampleservice/exampleservice.log" missingok=true ifempty=true rotate=4 copytruncate=true
litp create -t logrotate-rule -p /ms/configs/logrotate/rules/exampleservice_tasks -o name="exampleservice_tasks" path="/var/log/exampleservice/tasks/*.log" copytruncate=true rotate=0 missingok=true ifempty=true compress=false create=false

#Add VM to paralel httpd service

/usr/bin/md5sum /var/www/html/images/vm_test_image.qcow2 | cut -d ' ' -f 1 > /var/www/html/images/vm_test_image.qcow2.md5

litp create -t vm-image -p /software/images/img_vm1 -o name=vm1_1 source_uri=http://ms1dot90/images/vm_test_image.qcow2
litp create -t vm-service -p /software/services/se_vm1 -o service_name=vm1 image_name=vm1_1 cpus=2 ram=2000M internal_status_check=on cleanup_command="/sbin/service vm1 force-stop"
litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/id_vm1 -o name=vm1 active=1 standby=1 node_list=n1,n2 initial_online_dependency_list=SG_httpd online_timeout=300 offline_timeout=88
litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/id_vm1/ha_configs/vm_hc -o status_interval=120 status_timeout=120 restart_limit=4 startup_retry_limit=2

litp inherit -p /deployments/d1/clusters/c1/services/id_vm1/applications/vm -s /software/services/se_vm1
litp create -t vm-network-interface -p /software/services/se_vm1/vm_network_interfaces/vm_nic1 -o device_name=eth0 host_device=br1 network_name=net1vm gateway=10.46.82.1 ipv6addresses=fdde:4d7e:d471:15:90::10/64 gateway6=fdde:4d7e:d471:15:90::1
litp update -p /deployments/d1/clusters/c1/services/id_vm1/applications/vm/vm_network_interfaces/vm_nic1 -o ipaddresses=10.46.82.10

litp create -t vm-alias -p /software/services/se_vm1/vm_aliases/vm_ms1 -o alias_names=ms1dot90,hohoho address="${net1vm_ip_ms}"
litp create -t vm-alias -p /software/services/se_vm1/vm_aliases/vm_mn1 -o alias_names=mn1,node1dot90,nodehohoho address="${net1vm_ip[0]}"
litp create -t vm-alias -p /software/services/se_vm1/vm_aliases/vm_mn2 -o alias_names=node2 address="${net1vm_ip[1]}"
litp create -t vm-yum-repo -p /software/services/se_vm1/vm_yum_repos/updates -o name=vm_UPDATES base_url=http://ms1dot90/6.10/updates/x86_64/Packages
litp create -t vm-yum-repo -p /software/services/se_vm1/vm_yum_repos/os -o name=vm_os base_url=http://"${net1vm_ip_ms}"/6.10/os/x86_64
litp create -t vm-yum-repo -p /software/services/se_vm1/vm_yum_repos/3pp -o name=vm_3pp base_url=http://hohoho/3pp
litp create -t vm-package -p /software/services/se_vm1/vm_packages/rhel_7_tree -o name=tree
litp create -t vm-package -p /software/services/se_vm1/vm_packages/rhel_7_unzip -o name=unzip
litp create -t package -p /software/items/libguestfs-tools-c -o name=libguestfs-tools-c
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/libguestfs-tools-c -s /software/items/libguestfs-tools-c
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/items/libguestfs-tools-c -s /software/items/libguestfs-tools-c
# Add vcs-trigger to SG
litp create -t vcs-trigger -p /deployments/d1/clusters/c1/services/id_vm1/triggers/trig1 -o trigger_type=nofailover


litp create -t vm-image -p /software/images/img_vm2 -o name=vm1_2 source_uri=http://ms1dot90/images/vm_test_image.qcow2
litp create -t vm-service -p /software/services/se_vm2 -o service_name=vm2 image_name=vm1_2 cpus=2 ram=2000M internal_status_check=on cleanup_command="/sbin/service vm2 force-stop"
litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/id_vm2 -o name=vm2 active=2 standby=0 node_list=n1,n2 dependency_list=SG_cups online_timeout=300 offline_timeout=299
litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/id_vm2/ha_configs/vm_hc -o status_interval=120 status_timeout=120 restart_limit=4 startup_retry_limit=2
litp inherit -p /deployments/d1/clusters/c1/services/id_vm2/applications/vm -s /software/services/se_vm2
litp create -t vm-network-interface -p /software/services/se_vm2/vm_network_interfaces/vm_nic1 -o device_name=eth0 host_device=br1 network_name=net1vm gateway=10.46.82.1 ipv6addresses=fdde:4d7e:d471:15:90::11/64,fdde:4d7e:d471:15:90::12/64 gateway6=fdde:4d7e:d471:15:90::1
litp update -p /deployments/d1/clusters/c1/services/id_vm2/applications/vm/vm_network_interfaces/vm_nic1 -o ipaddresses=10.46.82.11,10.46.82.12
litp update -p /deployments/d1/clusters/c1/services/id_vm2/applications/vm -o hostnames=vm-host1,vm-host2

litp create -t vm-alias -p /software/services/se_vm2/vm_aliases/vm_ms1 -o alias_names=ms1dot90,hohoho-bucalaca address="${net1vm_ip_ms}"
litp create -t vm-alias -p /software/services/se_vm1/vm_aliases/vm_ms1_ipv6 -o alias_names=ms1dot90 address=fdde:4d7e:d471:1::835:90:110
litp create -t vm-alias -p /software/services/se_vm2/vm_aliases/vm_mn1 -o alias_names=mn1,node1dot90,nodehohoho address="${net1vm_ip[0]}"
litp create -t vm-alias -p /software/services/se_vm2/vm_aliases/vm_ms1_ipv6 -o alias_names=ms1dot90 address=fdde:4d7e:d471:1::835:90:110
litp create -t vm-alias -p /software/services/se_vm2/vm_aliases/vm_mn2 -o alias_names=node2 address="${net1vm_ip[1]}"
litp create -t vm-yum-repo -p /software/services/se_vm2/vm_yum_repos/updates -o name=vm_UPDATES base_url=http://ms1dot90/6.10/updates/x86_64/Packages
litp create -t vm-yum-repo -p /software/services/se_vm2/vm_yum_repos/os -o name=vm_os base_url=http://"${net1vm_ip_ms}"/6.10/os/x86_64
litp create -t vm-yum-repo -p /software/services/se_vm2/vm_yum_repos/3pp -o name=vm_3pp base_url=http://hohoho-bucalaca/3pp
litp create -t vm-package -p /software/services/se_vm2/vm_packages/firefox -o name=firefox
litp create -t vm-package -p /software/services/se_vm2/vm_packages/cups -o name=cups



# SETUP VM ON THE MS
litp create -t vm-image -p /software/images/img_vm3 -o name=vm1_3 source_uri=http://ms1dot90/images/vm_test_image.qcow2
litp create -t vm-service -p /ms/services/se_vm3 -o service_name=vm3 image_name=vm1_3 cpus=2 ram=2000M internal_status_check=off

litp create -t vm-network-interface -p /ms/services/se_vm3/vm_network_interfaces/vm_nic1 -o device_name=eth0 host_device=br0 network_name=net1vm gateway=10.46.82.1 ipv6addresses=fdde:4d7e:d471:15:90::15/64 gateway6=fdde:4d7e:d471:15:90::1 ipaddresses=10.46.82.15

litp create -t vm-alias -p /ms/services/se_vm3/vm_aliases/vm_ms1 -o alias_names=ms1dot90,hohoho address="${net1vm_ip_ms}"
litp create -t vm-alias -p /ms/services/se_vm3/vm_aliases/vm_ms1_ipv6 -o alias_names=ms1dot90 address=fdde:4d7e:d471:1::835:90:110
litp create -t vm-alias -p /ms/services/se_vm3/vm_aliases/vm_mn1 -o alias_names=mn1,node1dot90,nodehohoho address="${net1vm_ip[0]}"
litp create -t vm-alias -p /ms/services/se_vm3/vm_aliases/vm_mn2 -o alias_names=node2 address="${net1vm_ip[1]}"
litp create -t vm-yum-repo -p /ms/services/se_vm3/vm_yum_repos/updates -o name=vm_UPDATES base_url=http://ms1dot90/6.10/updates/x86_64/Packages
litp create -t vm-yum-repo -p /ms/services/se_vm3/vm_yum_repos/os -o name=vm_os base_url=http://"${net1vm_ip_ms}"/6.10/os/x86_64
litp create -t vm-yum-repo -p /ms/services/se_vm3/vm_yum_repos/3pp -o name=vm_3pp base_url=http://hohoho/3pp

litp create -t vm-disk -p /ms/services/se_vm3/vm_disks/vm_disk_1 -o host_file_system="fs3" host_volume_group="vg1" mount_point="/12270"

# Sentinel
litp create  -t package -p /software/items/sentinel    -o name=EXTRlitpsentinellicensemanager_CXP9031488
litp inherit            -p /ms/items/sentinel                                     -s /software/items/sentinel
litp create  -t service -p /ms/services/sentinel       -o service_name=sentinel
litp create  -t service -p /software/services/sentinel -o service_name=sentinel
litp inherit            -p /software/services/sentinel/packages/sentinel          -s /software/items/sentinel

# RamFs and TmpFs addition
litp create -t vm-ram-mount -p /software/services/se_vm1/vm_ram_mounts/mount1 -o type=tmpfs mount_point="/mnt/data1" mount_options="size=512M,noexec,nodev,nosuid"
litp create -t vm-ram-mount -p /software/services/se_vm2/vm_ram_mounts/mount2 -o type=ramfs mount_point="/mnt/data2" mount_options="size=1024M,noexec,nodev,nosuid"
 
# FAILOVER SG - with 10 SG and a VM
litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/multiple_SG -o active=1 standby=1 name=FO_MULTISG online_timeout=80 node_list=n1,n2

# Add sample package to a yum repo with yum repo path on ms and inherit to ms and nodes
mkdir /var/www/html/new_repo
litp import /tmp/lsb_pkg/EXTR-lsbwrapper21-2.0.0.rpm /var/www/html/new_repo
litp create -t yum-repository -p /software/items/yum_repo_test -o name="yum_repo_test" ms_url_path=/new_repo
litp inherit -p /ms/items/yum_repo_test -s /software/items/yum_repo_test
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/yum_repo_test -s /software/items/yum_repo_test
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/items/yum_repo_test -s /software/items/yum_repo_test

# Add sample packages

litp import /tmp/lsb_pkg 3pp

litp create -t package -p /software/items/pkg_lsb1 -o name=EXTR-lsbwrapper1
litp create -t  service -p /software/services/service1 -o service_name=test-lsb-01
litp inherit -p /software/services/service1/packages/pkg1 -s /software/items/pkg_lsb1
litp inherit -p /deployments/d1/clusters/c1/services/multiple_SG/applications/service1 -s /software/services/service1
litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/multiple_SG/ha_configs/service1_conf -o status_interval=30 status_timeout=30 restart_limit=3 startup_retry_limit=4 service_id=service1
litp create -t vcs-trigger -p /deployments/d1/clusters/c1/services/multiple_SG/triggers/trig1 -o trigger_type=nofailover

# Create the software packages
for (( i=2; i<10; i++ )); do
    litp create -t package -p /software/items/pkg_lsb$i -o name=EXTR-lsbwrapper$i
    litp create -t  service -p /software/services/service$i -o service_name=test-lsb-0$i
    litp inherit -p /software/services/service$i/packages/pkg$i -s /software/items/pkg_lsb$i
    litp inherit -p /deployments/d1/clusters/c1/services/multiple_SG/applications/service$i -s /software/services/service$i
    litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/multiple_SG/ha_configs/service$(($i))_conf -o status_interval=15 status_timeout=15 restart_limit=4 startup_retry_limit=4 service_id=service$i dependency_list=service$(($i-1))
done;



litp create_plan
