#!/bin/bash
#
# Sample LITP multi-blade deployment (SAN version)
#
# Usage:
#   ST_Deployment_15.sh <CLUSTER_SPEC_FILE>
#

if [ "$#" -lt 1 ]; then
    echo -e "Usage:\n  $0 <CLUSTER_SPEC_FILE>" >&2
    exit 1
fi

#results=$(grep "lvm_support.rb: execution expired" /var/log/messages)
#echo $results
#if [ "$results" ];then
#    exit 1
#fi

cluster_file="$1"
source "$cluster_file"

set -x

# Import an RPM in to the directory to create the repository data.
litp import /tmp/${rpm_1} /var/www/html/ENM_common

# Import an RPM in to the directory to create the repository data.
litp import /tmp/${rpm_2} /var/www/html/ENM_ms


# Import an RPM in to the directory to create the repository data.
litp import /tmp/${rpm_3} /var/www/html/ENM_models

# IMPORT DIFF NAMED SERVICE
litp import /tmp/test_service_name-2.0-1.noarch.rpm /var/www/html/3pp


# MS ONLY STUFF, PHIL.
litp update -p /ms -o hostname="${ms_host}"
# EXTERNAL PLUGIN - I BELIEVE
# litp create -p /ms/configs/dns_client -t dns-client -o search=athtem.eei.ericsson.se
# litp create -p /ms/configs/dns_client/nameservers/nameserver_A -t nameserver -o ipaddress=159.107.173.3 position=1
# litp create -p /ms/configs/dns_client/nameservers/nameserver_B -t nameserver -o ipaddress=159.107.173.12 position=2


# SYSCTRL PARAMS FOR MS
litp create -p /ms/configs/sysctl -t sysparam-node-config
litp create -p /ms/configs/sysctl/params/core_pattern -t sysparam -o key=kernel.core_pattern value="/ericsson/enm/dumps/core.%e.pid%p.usr%u.sig%s.tim%t1"
litp create -p /ms/configs/sysctl/params/def_autoconf -t sysparam -o key="net.ipv6.conf.default.autoconf" value="0"
litp create -p /ms/configs/sysctl/params/def_accept_ra -t sysparam -o key="net.ipv6.conf.default.accept_ra" value="0"
litp create -p /ms/configs/sysctl/params/def_accept_ra_defrtr -t sysparam -o key="net.ipv6.conf.default.accept_ra_defrtr" value="0"
litp create -p /ms/configs/sysctl/params/def_accept_ra_rtr_pref -t sysparam -o key="net.ipv6.conf.default.accept_ra_rtr_pref" value="0"
litp create -p /ms/configs/sysctl/params/def_accept_ra_pinfo -t sysparam -o key="net.ipv6.conf.default.accept_ra_pinfo" value="0"
litp create -p /ms/configs/sysctl/params/def_accept_source_route -t sysparam -o key="net.ipv6.conf.default.accept_source_route" value="0"
litp create -p /ms/configs/sysctl/params/def_accept_redirects -t sysparam -o key="net.ipv6.conf.default.accept_redirects" value="0"
litp create -p /ms/configs/sysctl/params/autoconf -t sysparam -o key="net.ipv6.conf.all.autoconf" value="0"
litp create -p /ms/configs/sysctl/params/accept_ra -t sysparam -o key="net.ipv6.conf.all.accept_ra" value="0"
litp create -p /ms/configs/sysctl/params/accept_ra_defrtr -t sysparam -o key="net.ipv6.conf.all.accept_ra_defrtr" value="0"
litp create -p /ms/configs/sysctl/params/accept_ra_rtr_pref -t sysparam -o key="net.ipv6.conf.all.accept_ra_rtr_pref" value="0"
litp create -p /ms/configs/sysctl/params/accept_ra_pinfo -t sysparam -o key="net.ipv6.conf.all.accept_ra_pinfo" value="0"
litp create -p /ms/configs/sysctl/params/accept_source_route -t sysparam -o key="net.ipv6.conf.all.accept_source_route" value="0"
litp create -p /ms/configs/sysctl/params/accept_redirects -t sysparam -o key="net.ipv6.conf.all.accept_redirects" value="0"


litp create -p /infrastructure/networking/networks/services_network -t network -o litp_management="true" name="services" subnet="${nodes_subnet}" # litp_management="false"
#litp create -p /infrastructure/networking/networks/storage_network -t network -o  litp_management="false" name="storage" subnet=""
#litp create -p /infrastructure/networking/networks/backup_network -t network -o litp_management="false" name="backup" subnet=""
#litp create -p /infrastructure/networking/networks/internal_network -t network -o litp_management="true" name="internal" subnet=""

# JDK
litp create -t package -p /software/items/jdk_7u95 -o name=jdk
litp inherit -p /ms/items/jdk_7u95 -s /software/items/jdk_7u95

# SETUP ALIAS' ON MS
litp create -p /ms/configs/alias_config -t alias-node-config
litp create -p /ms/configs/alias_config/aliases/httpd_alias -t alias -o alias_names="haproxy,ieatENM5183-1.athtem.eei.ericsson.se" address="10.151.9.137"
litp create -p /ms/configs/alias_config/aliases/ntp-server-2 -t alias -o alias_names="ntp-server2" address="10.140.2.9"
litp create -p /ms/configs/alias_config/aliases/ldap-1 -t alias -o alias_names="ldap-local" address="10.247.244.12"
litp create -p /ms/configs/alias_config/aliases/ldap-2 -t alias -o alias_names="ldap-remote" address="10.247.244.22"
litp create -p /ms/configs/alias_config/aliases/openidm -t alias -o alias_names="openidm-internal,openidm,idmhost-1,idmhost-2,idm-svc" address="10.247.246.12"
litp create -p /ms/configs/alias_config/aliases/idmdbhost -t alias -o alias_names="idmdbhost" address="10.247.244.7"
litp create -p /ms/configs/alias_config/aliases/sso-hostname -t alias -o alias_names="sso,sso-internal" address="10.247.246.56"
litp create -p /ms/configs/alias_config/aliases/hyperic-alias -t alias -o alias_names="monitoring-server" address="10.151.9.136"
litp create -p /ms/configs/alias_config/aliases/httpd-instance-1_alias -t alias -o alias_names="httpd-instance-1,iorfile1.ieatENM5183-1.athtem.eei.ericsson.se" address="10.247.246.10"
litp create -p /ms/configs/alias_config/aliases/httpd-instance-2_alias -t alias -o alias_names="httpd-instance-2,iorfile2.ieatENM5183-1.athtem.eei.ericsson.se" address="10.247.246.55"
litp create -p /ms/configs/alias_config/aliases/sso-instance-1_alias -t alias -o alias_names="sso-instance-1,sso-instance-1.ieatENM5183-1.athtem.eei.ericsson.se" address="10.247.246.89"
litp create -p /ms/configs/alias_config/aliases/sso-instance-2_alias -t alias -o alias_names="sso-instance-2,sso-instance-2.ieatENM5183-1.athtem.eei.ericsson.se" address="10.247.246.90"
litp create -p /ms/configs/alias_config/aliases/solr_alias -t alias -o alias_names="solr" address="10.247.246.47"
litp create -p /ms/configs/alias_config/aliases/emailservice_alias -t alias -o alias_names="emailservice" address="10.247.246.95"
litp create -p /ms/configs/alias_config/aliases/visinamingsb_alias -t alias -o alias_names="visinamingsb" address="10.247.246.58"
litp create -p /ms/configs/alias_config/aliases/visinamingsb-pub_alias -t alias -o alias_names="visinamingsb-pub" address="10.151.9.149"
litp create -p /ms/configs/alias_config/aliases/sentinelhost_alias -t alias -o alias_names="sentinelhost" address="10.140.2.9"
litp create -p /ms/configs/alias_config/aliases/db-1_alias -t alias -o alias_names="db-1" address="10.247.246.4"
litp create -p /ms/configs/alias_config/aliases/db-2_alias -t alias -o alias_names="db-2" address="10.247.246.5"
litp create -p /ms/configs/alias_config/aliases/svc-1_alias -t alias -o alias_names="svc-1" address="10.247.246.2"
litp create -p /ms/configs/alias_config/aliases/svc-2_alias -t alias -o alias_names="svc-2" address="10.247.246.3"
litp create -p /ms/configs/alias_config/aliases/svc-1-httpd_alias -t alias -o alias_names="svc-1-httpd,httpd-1-internal" address="10.247.246.10"
litp create -p /ms/configs/alias_config/aliases/svc-2-httpd_alias -t alias -o alias_names="svc-2-httpd,httpd-2-internal" address="10.247.246.55"
litp create -p /ms/configs/alias_config/aliases/svc-1-sso_alias -t alias -o alias_names="svc-1-sso,sso-1-internal" address="10.247.246.89"
litp create -p /ms/configs/alias_config/aliases/svc-2-sso_alias -t alias -o alias_names="svc-2-sso,sso-2-internal" address="10.247.246.90"
litp create -p /ms/configs/alias_config/aliases/svc-1-uiserv_alias -t alias -o alias_names="svc-1-uiserv,uiserv-1-internal" address="10.247.246.25"
litp create -p /ms/configs/alias_config/aliases/svc-2-uiserv_alias -t alias -o alias_names="svc-2-uiserv,uiserv-2-internal" address="10.247.246.26"
litp create -p /ms/configs/alias_config/aliases/svc-1-wpserv_alias -t alias -o alias_names="svc-1-wpserv,wpserv-1-internal" address="10.247.246.53"
litp create -p /ms/configs/alias_config/aliases/svc-2-wpserv_alias -t alias -o alias_names="svc-2-wpserv,wpserv-2-internal" address="10.247.246.54"
litp create -p /ms/configs/alias_config/aliases/svc-1-eventbasedclient_alias -t alias -o alias_names="svc-1-eventbasedclient,eventbasedclient-1-internal" address="10.247.246.17"
litp create -p /ms/configs/alias_config/aliases/svc-2-eventbasedclient_alias -t alias -o alias_names="svc-2-eventbasedclient,eventbasedclient-2-internal" address="10.247.246.18"
litp create -p /ms/configs/alias_config/aliases/svc-1-medrouter_alias -t alias -o alias_names="svc-1-medrouter,medrouter-1-internal,medrouter1-internal" address="10.247.246.13"
litp create -p /ms/configs/alias_config/aliases/svc-2-medrouter_alias -t alias -o alias_names="svc-2-medrouter,medrouter-2-internal,medrouter2-internal" address="10.247.246.14"
litp create -p /ms/configs/alias_config/aliases/svc-1-supervc_alias -t alias -o alias_names="svc-1-supervc,supervc-1-internal" address="10.247.246.15"
litp create -p /ms/configs/alias_config/aliases/svc-2-supervc_alias -t alias -o alias_names="svc-2-supervc,supervc-2-internal" address="10.247.246.16"
litp create -p /ms/configs/alias_config/aliases/svc-1-cmserv_alias -t alias -o alias_names="svc-1-cmserv,cmserv-1-internal,cmserv1-internal" address="10.247.246.21"
litp create -p /ms/configs/alias_config/aliases/svc-1-mscm_alias -t alias -o alias_names="svc-1-mscm,mscm-1-internal,mscm1-internal" address="10.247.246.29"
litp create -p /ms/configs/alias_config/aliases/svc-2-mscm_alias -t alias -o alias_names="svc-2-mscm,mscm-2-internal,mscm2-internal" address="10.247.246.30"
litp create -p /ms/configs/alias_config/aliases/svc-1-mscmce_alias -t alias -o alias_names="svc-1-mscmce,mscmce-1-internal" address="10.247.246.87"
litp create -p /ms/configs/alias_config/aliases/svc-2-mscmce_alias -t alias -o alias_names="svc-2-mscmce,mscmce-2-internal" address="10.247.246.88"
litp create -p /ms/configs/alias_config/aliases/svc-1-comecimpolicy_alias -t alias -o alias_names="svc-1-comecimpolicy,comecimpolicy-1-internal" address="10.247.246.63"
litp create -p /ms/configs/alias_config/aliases/svc-2-comecimpolicy_alias -t alias -o alias_names="svc-2-comecimpolicy,comecimpolicy-2-internal" address="10.247.246.64"
litp create -p /ms/configs/alias_config/aliases/svc-1-cmrules_alias -t alias -o alias_names="svc-1-cmrules,cmrules-1-internal" address="10.247.246.103"
litp create -p /ms/configs/alias_config/aliases/svc-2-cmrules_alias -t alias -o alias_names="svc-2-cmrules,cmrules-2-internal" address="10.247.246.104"
litp create -p /ms/configs/alias_config/aliases/svc-1-netex_alias -t alias -o alias_names="svc-1-netex,netex-1-internal" address="10.247.246.23"
litp create -p /ms/configs/alias_config/aliases/svc-2-netex_alias -t alias -o alias_names="svc-2-netex,netex-2-internal" address="10.247.246.24"
litp create -p /ms/configs/alias_config/aliases/svc-1-secserv_alias -t alias -o alias_names="svc-1-secserv,secserv-1-internal,secserv1-internal" address="10.247.246.27"
litp create -p /ms/configs/alias_config/aliases/svc-2-secserv_alias -t alias -o alias_names="svc-2-secserv,secserv-2-internal,secserv2-internal" address="10.247.246.28"
litp create -p /ms/configs/alias_config/aliases/svc-1-sps_alias -t alias -o alias_names="svc-1-sps,sps-1-internal" address="10.247.246.65"
litp create -p /ms/configs/alias_config/aliases/svc-2-sps_alias -t alias -o alias_names="svc-2-sps,sps-2-internal" address="10.247.246.66"
litp create -p /ms/configs/alias_config/aliases/svc-1-pmserv_alias -t alias -o alias_names="svc-1-pmserv,pmserv-1-internal" address="10.247.246.19"
litp create -p /ms/configs/alias_config/aliases/svc-2-pmserv_alias -t alias -o alias_names="svc-2-pmserv,pmserv-2-internal" address="10.247.246.20"
litp create -p /ms/configs/alias_config/aliases/svc-1-mspm_alias -t alias -o alias_names="svc-1-mspm,mspm-1-internal,mspm1-internal" address="10.247.246.31"
litp create -p /ms/configs/alias_config/aliases/svc-2-mspm_alias -t alias -o alias_names="svc-2-mspm,mspm-2-internal,mspm2-internal" address="10.247.246.32"
litp create -p /ms/configs/alias_config/aliases/svc-1-fmalarmprocessing_alias -t alias -o alias_names="svc-1-fmalarmprocessing,fmalarmprocessing-1-internal" address="10.247.246.73"
litp create -p /ms/configs/alias_config/aliases/svc-2-fmalarmprocessing_alias -t alias -o alias_names="svc-2-fmalarmprocessing,fmalarmprocessing-2-internal" address="10.247.246.74"
litp create -p /ms/configs/alias_config/aliases/svc-1-fmhistory_alias -t alias -o alias_names="svc-1-fmhistory,fmhistory-1-internal" address="10.247.246.75"
litp create -p /ms/configs/alias_config/aliases/svc-2-fmhistory_alias -t alias -o alias_names="svc-2-fmhistory,fmhistory-2-internal" address="10.247.246.76"
litp create -p /ms/configs/alias_config/aliases/svc-1-fmserv_alias -t alias -o alias_names="svc-1-fmserv,fmserv-1-internal" address="10.247.246.39"
litp create -p /ms/configs/alias_config/aliases/svc-2-fmserv_alias -t alias -o alias_names="svc-2-fmserv,fmserv-2-internal" address="10.247.246.40"
litp create -p /ms/configs/alias_config/aliases/svc-1-msfm_alias -t alias -o alias_names="svc-1-msfm,msfm-1-internal" address="10.247.246.37"
litp create -p /ms/configs/alias_config/aliases/svc-2-msfm_alias -t alias -o alias_names="svc-2-msfm,msfm-2-internal" address="10.247.246.38"
litp create -p /ms/configs/alias_config/aliases/svc-1-nbalarmirp_alias -t alias -o alias_names="svc-1-nbalarmirp,nbalarmirp-1-internal" address="10.247.246.41"
litp create -p /ms/configs/alias_config/aliases/svc-2-nbalarmirp_alias -t alias -o alias_names="svc-2-nbalarmirp,nbalarmirp-2-internal" address="10.247.246.42"
litp create -p /ms/configs/alias_config/aliases/svc-1-bnsiserv_alias -t alias -o alias_names="svc-1-bnsiserv,bnsiserv-1-internal" address="10.247.246.67"
litp create -p /ms/configs/alias_config/aliases/svc-2-bnsiserv_alias -t alias -o alias_names="svc-2-bnsiserv,bnsiserv-2-internal" address="10.247.246.68"
litp create -p /ms/configs/alias_config/aliases/svc-1-fmx_alias -t alias -o alias_names="svc-1-fmx,fmx-1-internal" address="10.247.246.85"
litp create -p /ms/configs/alias_config/aliases/svc-2-fmx_alias -t alias -o alias_names="svc-2-fmx,fmx-2-internal" address="10.247.246.86"
litp create -p /ms/configs/alias_config/aliases/svc-1-dlms_alias -t alias -o alias_names="svc-1-dlms,dlms-1-internal" address="10.247.246.105"
litp create -p /ms/configs/alias_config/aliases/svc-2-dlms_alias -t alias -o alias_names="svc-2-dlms,dlms-2-internal" address="10.247.246.106"
litp create -p /ms/configs/alias_config/aliases/svc-1-map-service_alias -t alias -o alias_names="svc-1-map-service,map-service-1-internal" address="10.247.246.77"
litp create -p /ms/configs/alias_config/aliases/svc-2-map-service_alias -t alias -o alias_names="svc-2-map-service,map-service-2-internal" address="10.247.246.78"
litp create -p /ms/configs/alias_config/aliases/svc-1-impexpserv_alias -t alias -o alias_names="svc-1-impexpserv,impexpserv-1-internal" address="10.247.246.43"
litp create -p /ms/configs/alias_config/aliases/svc-2-impexpserv_alias -t alias -o alias_names="svc-2-impexpserv,impexpserv-2-internal" address="10.247.246.44"
litp create -p /ms/configs/alias_config/aliases/svc-1-shmserv_alias -t alias -o alias_names="svc-1-shmserv,shmserv-1-internal" address="10.247.246.45"
litp create -p /ms/configs/alias_config/aliases/svc-2-shmserv_alias -t alias -o alias_names="svc-2-shmserv,shmserv-2-internal" address="10.247.246.46"
litp create -p /ms/configs/alias_config/aliases/svc-1-kpiserv_alias -t alias -o alias_names="svc-1-kpiserv,kpiserv-1-internal" address="10.247.246.51"
litp create -p /ms/configs/alias_config/aliases/svc-2-kpiserv_alias -t alias -o alias_names="svc-2-kpiserv,kpiserv-2-internal" address="10.247.246.52"
litp create -p /ms/configs/alias_config/aliases/svc-1-apserv_alias -t alias -o alias_names="svc-1-apserv,apserv-1-internal" address="10.247.246.59"
litp create -p /ms/configs/alias_config/aliases/svc-2-apserv_alias -t alias -o alias_names="svc-2-apserv,apserv-2-internal" address="10.247.246.60"
litp create -p /ms/configs/alias_config/aliases/svc-1-msap_alias -t alias -o alias_names="svc-1-msap,msap-1-internal" address="10.247.246.71"
litp create -p /ms/configs/alias_config/aliases/svc-2-msap_alias -t alias -o alias_names="svc-2-msap,msap-2-internal" address="10.247.246.72"
litp create -p /ms/configs/alias_config/aliases/svc-1-lcmserv_alias -t alias -o alias_names="svc-1-lcmserv,lcmserv-1-internal" address="10.247.246.61"
litp create -p /ms/configs/alias_config/aliases/svc-2-lcmserv_alias -t alias -o alias_names="svc-2-lcmserv,lcmserv-2-internal" address="10.247.246.62"
litp create -p /ms/configs/alias_config/aliases/svc-1-ipsmserv_alias -t alias -o alias_names="svc-1-ipsmserv,ipsmserv-1-internal" address="10.247.246.69"
litp create -p /ms/configs/alias_config/aliases/svc-2-ipsmserv_alias -t alias -o alias_names="svc-2-ipsmserv,ipsmserv-2-internal" address="10.247.246.70"
litp create -p /ms/configs/alias_config/aliases/svc-1-mscmip_alias -t alias -o alias_names="svc-1-mscmip,mscmip-1-internal" address="10.247.246.79"
litp create -p /ms/configs/alias_config/aliases/svc-2-mscmip_alias -t alias -o alias_names="svc-2-mscmip,mscmip-2-internal" address="10.247.246.80"
litp create -p /ms/configs/alias_config/aliases/svc-1-pkiraserv_alias -t alias -o alias_names="svc-1-pkiraserv,pkiraserv-1-internal" address="10.247.246.81"
litp create -p /ms/configs/alias_config/aliases/svc-2-pkiraserv_alias -t alias -o alias_names="svc-2-pkiraserv,pkiraserv-2-internal" address="10.247.246.82"
litp create -p /ms/configs/alias_config/aliases/svc-1-mssnmpfm_alias -t alias -o alias_names="svc-1-mssnmpfm,mssnmpfm-1-internal" address="10.247.246.93"
litp create -p /ms/configs/alias_config/aliases/svc-2-mssnmpfm_alias -t alias -o alias_names="svc-2-mssnmpfm,mssnmpfm-2-internal" address="10.247.246.94"
litp create -p /ms/configs/alias_config/aliases/svc-1-said_alias -t alias -o alias_names="svc-1-said,said-1-internal" address="10.247.246.91"
litp create -p /ms/configs/alias_config/aliases/svc-2-said_alias -t alias -o alias_names="svc-2-said,said-2-internal" address="10.247.246.92"
litp create -p /ms/configs/alias_config/aliases/svc-1-itservices_alias -t alias -o alias_names="svc-1-itservices,itservices-1-internal" address="10.247.246.96"
litp create -p /ms/configs/alias_config/aliases/svc-2-itservices_alias -t alias -o alias_names="svc-2-itservices,itservices-2-internal" address="10.247.246.97"
litp create -p /ms/configs/alias_config/aliases/svc-1-dchistory_alias -t alias -o alias_names="svc-1-dchistory,dchistory-1-internal" address="10.247.246.101"
litp create -p /ms/configs/alias_config/aliases/svc-2-dchistory_alias -t alias -o alias_names="svc-2-dchistory,dchistory-2-internal" address="10.247.246.102"
litp create -p /ms/configs/alias_config/aliases/db1-service_alias -t alias -o alias_names="db1-service" address="10.247.244.17"
litp create -p /ms/configs/alias_config/aliases/ms-1_alias -t alias -o alias_names="ms-1" address="${ms_ip}"
litp create -p /ms/configs/alias_config/aliases/elasticsearch_alias -t alias -o alias_names="elasticsearch" address="10.247.244.31"
litp create -p /ms/configs/alias_config/aliases/mysql_alias -t alias -o alias_names="mysql" address="10.247.244.7"
litp create -p /ms/configs/alias_config/aliases/postgresql01_alias -t alias -o alias_names="postgresql01" address="10.247.244.2"
litp create -p /ms/configs/alias_config/aliases/jms01_alias -t alias -o alias_names="jms01" address="10.247.244.26"

# DOUBLING UP NUMBER OF ALISES
litp create -p /ms/configs/alias_config/aliases/test_alias_001 -t alias -o alias_names="test-alias-001" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_002 -t alias -o alias_names="test-alias-002" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_003 -t alias -o alias_names="test-alias-003" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_004 -t alias -o alias_names="test-alias-004" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_005 -t alias -o alias_names="test-alias-005" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_006 -t alias -o alias_names="test-alias-006" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_007 -t alias -o alias_names="test-alias-007" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_008 -t alias -o alias_names="test-alias-008" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_009 -t alias -o alias_names="test-alias-009" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_010 -t alias -o alias_names="test-alias-010" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_011 -t alias -o alias_names="test-alias-011" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_012 -t alias -o alias_names="test-alias-012" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_013 -t alias -o alias_names="test-alias-013" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_014 -t alias -o alias_names="test-alias-014" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_015 -t alias -o alias_names="test-alias-015" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_016 -t alias -o alias_names="test-alias-016" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_017 -t alias -o alias_names="test-alias-017" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_018 -t alias -o alias_names="test-alias-018" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_019 -t alias -o alias_names="test-alias-019" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_020 -t alias -o alias_names="test-alias-020" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_021 -t alias -o alias_names="test-alias-021" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_022 -t alias -o alias_names="test-alias-022" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_023 -t alias -o alias_names="test-alias-023" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_024 -t alias -o alias_names="test-alias-024" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_025 -t alias -o alias_names="test-alias-025" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_026 -t alias -o alias_names="test-alias-026" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_027 -t alias -o alias_names="test-alias-027" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_028 -t alias -o alias_names="test-alias-028" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_029 -t alias -o alias_names="test-alias-029" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_030 -t alias -o alias_names="test-alias-030" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_031 -t alias -o alias_names="test-alias-031" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_032 -t alias -o alias_names="test-alias-032" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_033 -t alias -o alias_names="test-alias-033" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_034 -t alias -o alias_names="test-alias-034" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_035 -t alias -o alias_names="test-alias-035" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_036 -t alias -o alias_names="test-alias-036" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_037 -t alias -o alias_names="test-alias-037" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_038 -t alias -o alias_names="test-alias-038" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_039 -t alias -o alias_names="test-alias-039" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_040 -t alias -o alias_names="test-alias-040" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_041 -t alias -o alias_names="test-alias-041" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_042 -t alias -o alias_names="test-alias-042" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_043 -t alias -o alias_names="test-alias-043" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_044 -t alias -o alias_names="test-alias-044" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_045 -t alias -o alias_names="test-alias-045" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_046 -t alias -o alias_names="test-alias-046" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_047 -t alias -o alias_names="test-alias-047" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_048 -t alias -o alias_names="test-alias-048" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_049 -t alias -o alias_names="test-alias-049" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_050 -t alias -o alias_names="test-alias-050" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_051 -t alias -o alias_names="test-alias-051" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_052 -t alias -o alias_names="test-alias-052" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_053 -t alias -o alias_names="test-alias-053" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_054 -t alias -o alias_names="test-alias-054" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_055 -t alias -o alias_names="test-alias-055" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_056 -t alias -o alias_names="test-alias-056" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_057 -t alias -o alias_names="test-alias-057" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_058 -t alias -o alias_names="test-alias-058" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_059 -t alias -o alias_names="test-alias-059" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_060 -t alias -o alias_names="test-alias-060" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_061 -t alias -o alias_names="test-alias-061" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_062 -t alias -o alias_names="test-alias-062" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_063 -t alias -o alias_names="test-alias-063" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_064 -t alias -o alias_names="test-alias-064" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_065 -t alias -o alias_names="test-alias-065" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_066 -t alias -o alias_names="test-alias-066" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_067 -t alias -o alias_names="test-alias-067" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_068 -t alias -o alias_names="test-alias-068" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_069 -t alias -o alias_names="test-alias-069" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_070 -t alias -o alias_names="test-alias-070" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_071 -t alias -o alias_names="test-alias-071" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_072 -t alias -o alias_names="test-alias-072" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_073 -t alias -o alias_names="test-alias-073" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_074 -t alias -o alias_names="test-alias-074" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_075 -t alias -o alias_names="test-alias-075" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_076 -t alias -o alias_names="test-alias-076" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_077 -t alias -o alias_names="test-alias-077" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_078 -t alias -o alias_names="test-alias-078" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_079 -t alias -o alias_names="test-alias-079" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_080 -t alias -o alias_names="test-alias-080" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_081 -t alias -o alias_names="test-alias-081" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_082 -t alias -o alias_names="test-alias-082" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_083 -t alias -o alias_names="test-alias-083" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_084 -t alias -o alias_names="test-alias-084" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_085 -t alias -o alias_names="test-alias-085" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_086 -t alias -o alias_names="test-alias-086" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_087 -t alias -o alias_names="test-alias-087" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_088 -t alias -o alias_names="test-alias-088" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_089 -t alias -o alias_names="test-alias-089" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_090 -t alias -o alias_names="test-alias-090" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_091 -t alias -o alias_names="test-alias-091" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_092 -t alias -o alias_names="test-alias-092" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_093 -t alias -o alias_names="test-alias-093" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_094 -t alias -o alias_names="test-alias-094" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_095 -t alias -o alias_names="test-alias-095" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_096 -t alias -o alias_names="test-alias-096" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_097 -t alias -o alias_names="test-alias-097" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_098 -t alias -o alias_names="test-alias-098" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_099 -t alias -o alias_names="test-alias-099" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_100 -t alias -o alias_names="test-alias-100" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_101 -t alias -o alias_names="test-alias-101" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_102 -t alias -o alias_names="test-alias-102" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_103 -t alias -o alias_names="test-alias-103" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_104 -t alias -o alias_names="test-alias-104" address="${ntp_ip[1]}"
litp create -p /ms/configs/alias_config/aliases/test_alias_105 -t alias -o alias_names="test-alias-105" address="${ntp_ip[1]}"

litp create -t alias -p /ms/configs/alias_config/aliases/duplicate_alias_names_01 -o alias_names="primary-alias-names-01,secondary-name" address="127.0.0.1"
litp create -t alias -p /ms/configs/alias_config/aliases/duplicate_alias_names_02 -o alias_names="primary-alias-names-02,secondary-name,tertiary-name" address="127.0.0.1"
litp create -t alias -p /ms/configs/alias_config/aliases/duplicate_alias_names_03 -o alias_names="primary-alias-names-03,secondary-name,tertiary-name,quaternary-name" address="127.0.0.1"
litp create -t alias -p /ms/configs/alias_config/aliases/duplicate_alias_names_04 -o alias_names="primary-alias-names-04,secondary-name,tertiary-name,quaternary-name" address="127.0.0.1"



# WITHOUT A SECOND IP FOR THE MS THIS CANNOT BE DONE
# NFS MOUNT SECTION
#litp create -p /infrastructure/storage/nfs_mounts/nfsm-brsadm_home -t nfs-mount -o export_path="/vx/ENM183-brsadm_home" mount_options="soft" mount_point="/opt/ericsson/storage/user/nas/brsadm" network_name="storage" provider="vs_enm_2"
#litp create -p /infrastructure/storage/nfs_mounts/nfsm-storobs_home -t nfs-mount -o export_path="/vx/ENM183-storobs_home" mount_options="soft" mount_point="/opt/ericsson/storage/user/nas/storobs" network_name="storage" provider="vs_enm_1"
#litp create -p /infrastructure/storage/nfs_mounts/nfsm-data -t nfs-mount -o export_path="/vx/ENM183-data" mount_options="soft" mount_point="/ericsson/tor/data" network_name="storage" provider="vs_enm_1"
#litp create -p /infrastructure/storage/nfs_mounts/nfsm-ddc_data -t nfs-mount -o export_path="/vx/ENM183-ddc_data" mount_options="soft" mount_point="/var/ericsson/ddc_data" network_name="storage" provider="vs_enm_2"
#litp create -p /infrastructure/storage/nfs_mounts/nfsm-hcdumps -t nfs-mount -o export_path="/vx/ENM183-hcdumps" mount_options="soft" mount_point="/ericsson/enm/dumps" network_name="storage" provider="vs_enm_1"
#litp create -p /infrastructure/storage/nfs_mounts/nfsm-mdt -t nfs-mount -o export_path="/vx/ENM183-mdt" mount_options="soft" mount_point="/etc/opt/ericsson/ERICmodeldeployment" network_name="storage" provider="vs_enm_1"
#litp create -p /infrastructure/storage/nfs_mounts/nfsm-alex -t nfs-mount -o export_path="/vx/ENM183-alex" mount_options="soft" mount_point="/ericsson/enm/alex" network_name="storage" provider="vs_enm_1"


# YUM REPOSITORIES
litp create -p /software/items/common_repo -t yum-repository -o ms_url_path="/ENM_common/" name="common_repo"
litp create -p /software/items/ms_repo -t yum-repository -o ms_url_path="/ENM_ms/" name="ms_repo"
litp create -p /software/items/model_repo -t yum-repository -o ms_url_path="/ENM_models/" name="model_repo"

# NTP
litp create -p /software/items/ntp_service -t ntp-service
litp create -p /software/items/ntp_service/servers/ntp_server-1 -t ntp-server -o server="${ntp_ip[1]}"
litp create -p /software/items/ntp_service/servers/ntp_server-2 -t ntp-server -o server="${ntp_ip[2]}"

# PACKAGES - ORIGINAL EXTERNAL PACKAGES REPLACED WITH TEST LSB WRAPPER RPM'S
litp create -p /software/items/ddc_package -t package -o name="3PP-czech-hello-1.0.0-1"
litp create -p /software/items/enm_configuration -t package -o name="3PP-dutch-hello-1.0.0-1"
litp create -p /software/items/enm_utilities -t package -o name="3PP-english-hello-1.0.0-1"
litp create -p /software/items/enm_eniq_integration -t package -o name="3PP-french-hello-1.0.0-1" epoch=0
litp create -p /software/items/backup_restore_package -t package -o name="3PP-german-hello-1.0.0-1"
litp create -p /software/items/backup_restore_ombs_package -t package -o name="3PP-polish-hello-1.0.0-1"
litp create -p /software/items/pibscripts -t package -o name="3PP-swedish-hello-1.0.0-1"

# DIFF NAME SERVICE
litp create -p /software/items/diff_name_pkg -t package -o name="test_service_name-2.0-1"
litp create -p /ms/services/diff_name_srvc -t service -o service_name="diff_service"
litp inherit -p /ms/services/diff_name_srvc/packages/diff_name_pkg -s /software/items/diff_name_pkg


# PACKAGES - UNCHANGED
litp create -p /software/items/rsyslog8 -t package -o epoch=0 name="EXTRlitprsyslogelasticsearch_CXP9032173" replaces="rsyslog7"

# MORE PACKAGES - TO BE REPLACED
litp create -p /software/items/model_package -t package-list -o name="models"
litp create -p /software/items/model_package/packages/cppcmcimodel -t package -o name="EXTR-lsbwrapper1-1.0.0"
litp create -p /software/items/model_package/packages/mediationcppconnectivityinfomodel -t package -o name="EXTR-lsbwrapper2-1.0.0"
litp create -p /software/items/model_package/packages/aicorewebmodel -t package -o name="EXTR-lsbwrapper3-1.0.0"
litp create -p /software/items/model_package/packages/securityfunctionmodel -t package -o name="EXTR-lsbwrapper4-1.0.0"
litp create -p /software/items/model_package/packages/securitymodel -t package -o name="EXTR-lsbwrapper5-1.0.0"
litp create -p /software/items/model_package/packages/mediationtopconnectivityinfomodel -t package -o name="EXTR-lsbwrapper6-1.0.0"
litp create -p /software/items/model_package/packages/rncnetworkresourcemodel15b -t package -o name="EXTR-lsbwrapper7-1.0.0"
litp create -p /software/items/model_package/packages/mediationrncnodemodelcommon -t package -o name="EXTR-lsbwrapper8-1.0.0"
litp create -p /software/items/model_package/packages/psmodels -t package -o name="EXTR-lsbwrapper9-1.0.0"
litp create -p /software/items/model_package/packages/pibmodel -t package -o name="EXTR-lsbwrapper10-1.0.0"
# 10
litp create -p /software/items/model_package/packages/webpushmodel -t package -o name="EXTR-lsbwrapper11-1.0.0"
litp create -p /software/items/model_package/packages/dpsconfmodels -t package -o name="EXTR-lsbwrapper12-1.0.0"
litp create -p /software/items/model_package/packages/clialiasmodel -t package -o name="EXTR-lsbwrapper13-1.0.0"
litp create -p /software/items/model_package/packages/batchmodel -t package -o name="EXTR-lsbwrapper14-1.0.0"
litp create -p /software/items/model_package/packages/upgradeindmodel -t package -o name="EXTR-lsbwrapper15-1.0.0"
litp create -p /software/items/model_package/packages/hcservicemodel -t package -o name="EXTR-lsbwrapper16-1.0.0"
litp create -p /software/items/model_package/packages/medsdkeventmodels -t package -o name="EXTR-lsbwrapper17-1.0.0"
litp create -p /software/items/model_package/packages/medcoreapichannelmodels -t package -o name="EXTR-lsbwrapper18-1.0.0"
litp create -p /software/items/model_package/packages/sshhandlerflowconfig -t package -o name="EXTR-lsbwrapper19-1.0.0"
litp create -p /software/items/model_package/packages/sshhandlermodel -t package -o name="EXTR-lsbwrapper20-1.0.0"
# 20
litp create -p /software/items/model_package/packages/sshhandlerflow -t package -o name="EXTR-lsbwrapper21-1.0.0"
litp create -p /software/items/model_package/packages/nodesecuritymodel -t package -o name="EXTR-lsbwrapper22-1.0.0"
litp create -p /software/items/model_package/packages/shmmodels -t package -o name="EXTR-lsbwrapper23-1.0.0"
litp create -p /software/items/model_package/packages/addnodebootstrapmodels -t package -o name="EXTR-lsbwrapper24-1.0.0"
litp create -p /software/items/model_package/packages/mocihandlermodel -t package -o name="EXTR-lsbwrapper25-1.0.0"
litp create -p /software/items/model_package/packages/writenodeflowmodel -t package -o name="EXTR-lsbwrapper26-1.0.0"
litp create -p /software/items/model_package/packages/erbsmediationconfigurationmodel -t package -o name="EXTR-lsbwrapper27-1.0.0"
litp create -p /software/items/model_package/packages/readnonpersistedattributesflow -t package -o name="EXTR-lsbwrapper28-1.0.0"
litp create -p /software/items/model_package/packages/mediationservicesmodel -t package -o name="EXTR-lsbwrapper29-1.0.0"
litp create -p /software/items/model_package/packages/networkelementdefmodel -t package -o name="EXTR-lsbwrapper30-1.0.0"
# 30
litp create -p /software/items/model_package/packages/geolocationmodel -t package -o name="EXTR-lsbwrapper31-1.0.0"
litp create -p /software/items/model_package/packages/syncnodeevent -t package -o name="EXTR-lsbwrapper32-1.0.0"
litp create -p /software/items/model_package/packages/syncnodeflowmodel -t package -o name="EXTR-lsbwrapper33-1.0.0"
litp create -p /software/items/model_package/packages/inbounddpshandlermodel -t package -o name="EXTR-lsbwrapper34-1.0.0"
litp create -p /software/items/model_package/packages/syncnodemocihandlermodel -t package -o name="EXTR-lsbwrapper35-1.0.0"
litp create -p /software/items/model_package/packages/subscriptionflow -t package -o name="EXTR-lsbwrapper36-1.0.0"
litp create -p /software/items/model_package/packages/subscriptioncreationhandlermodel -t package -o name="EXTR-lsbwrapper37-1.0.0"
litp create -p /software/items/model_package/packages/notificationhandlingflow -t package -o name="EXTR-lsbwrapper38-1.0.0"
litp create -p /software/items/model_package/packages/notificationreceiverhandlermodel -t package -o name="EXTR-lsbwrapper39-1.0.0"
litp create -p /software/items/model_package/packages/networkconnectorconfigmodels -t package -o name="EXTR-lsbwrapper40-1.0.0"
# 40
litp create -p /software/items/model_package/packages/subscriptionvalidationflow -t package -o name="EXTR-lsbwrapper41-1.0.0"
litp create -p /software/items/model_package/packages/subscriptionvalidationhandlermodel -t package -o name="EXTR-lsbwrapper42-1.0.0"
litp create -p /software/items/model_package/packages/networkelementcmdefmodel -t package -o name="EXTR-lsbwrapper43-1.0.0"
litp create -p /software/items/model_package/packages/osstopmodel -t package -o name="EXTR-lsbwrapper44-1.0.0"
litp create -p /software/items/model_package/packages/mediationerbsnodemodelcommon -t package -o name="EXTR-lsbwrapper45-1.0.0"
litp create -p /software/items/model_package/packages/mediationerbsnodemodel16b -t package -o name="EXTR-lsbwrapper46-1.0.0"
litp create -p /software/items/model_package/packages/mediationerbsnodemodel16a -t package -o name="EXTR-lsbwrapper47-1.0.0"
litp create -p /software/items/model_package/packages/mediationerbsnodemodel15b -t package -o name="EXTR-lsbwrapper48-1.0.0"
litp create -p /software/items/model_package/packages/mediationerbsnodemodel14b -t package -o name="EXTR-lsbwrapper49-1.0.0"
litp create -p /software/items/model_package/packages/mediationerbsnodemodel14a -t package -o name="EXTR-lsbwrapper50-1.0.0"
# 50
#litp create -p /software/items/model_package/packages/mediationerbsnodemodel13b -t package -o name="EXTR-lsbwrapper51-1.0.0"
#litp create -p /software/items/model_package/packages/mediationerbsnodemodel13a -t package -o name="EXTR-lsbwrapper52-1.0.0"
#litp create -p /software/items/model_package/packages/mediationmgwnodemodel15b -t package -o name="EXTR-lsbwrapper53-1.0.0"
#litp create -p /software/items/model_package/packages/mediationmgwnodemodelcommon -t package -o name="EXTR-lsbwrapper54-1.0.0"
#litp create -p /software/items/model_package/packages/sgsnmmenetworkresourcemodel14b -t package -o name="EXTR-lsbwrapper55-1.0.0"
#litp create -p /software/items/model_package/packages/mediationsgsnmmenodemodelcommon -t package -o name="EXTR-lsbwrapper56-1.0.0"
#litp create -p /software/items/model_package/packages/sgsnmmenetworkresourcemodel15a -t package -o name="EXTR-lsbwrapper57-1.0.0"
#litp create -p /software/items/model_package/packages/sgsnmmenetworkresourcemodel15b -t package -o name="EXTR-lsbwrapper58-1.0.0"
#litp create -p /software/items/model_package/packages/commodelsr5_0 -t package -o name="EXTR-lsbwrapper59-1.0.0"
#litp create -p /software/items/model_package/packages/msrbsv2networkresourcemodel15b -t package -o name="EXTR-lsbwrapper60-1.0.0"
# 60
#litp create -p /software/items/model_package/packages/msrbsv2nodemodelcommon -t package -o name="EXTR-lsbwrapper61-1.0.0"
#litp create -p /software/items/model_package/packages/commodelsr5_1 -t package -o name="EXTR-lsbwrapper62-1.0.0"
#litp create -p /software/items/model_package/packages/msrbsv2networkresourcemodel16a -t package -o name="EXTR-lsbwrapper63-1.0.0"
#litp create -p /software/items/model_package/packages/sgsnmmewritenodeflowmodels -t package -o name="EXTR-lsbwrapper64-1.0.0"
#litp create -p /software/items/model_package/packages/cbanetconfwritecontrollermodel -t package -o name="EXTR-lsbwrapper65-1.0.0"
#litp create -p /software/items/model_package/packages/radionodewritenodeflowmodels -t package -o name="EXTR-lsbwrapper66-1.0.0"
#litp create -p /software/items/model_package/packages/mediationcomconnectivityinfomodel -t package -o name="EXTR-lsbwrapper67-1.0.0"
#litp create -p /software/items/model_package/packages/sgsnmmemedconfiguration -t package -o name="EXTR-lsbwrapper68-1.0.0"
#litp create -p /software/items/model_package/packages/radionodemediationconfiguration -t package -o name="EXTR-lsbwrapper69-1.0.0"
#litp create -p /software/items/model_package/packages/comcmheartbeatsupervisionflow -t package -o name="EXTR-lsbwrapper70-1.0.0"
# 70
#litp create -p /software/items/model_package/packages/comecimcmheartbeatsuphandlermodel -t package -o name="EXTR-lsbwrapper71-1.0.0"
#litp create -p /software/items/model_package/packages/ecimcmheartbeatsupervisionflow -t package -o name="EXTR-lsbwrapper72-1.0.0"
#litp create -p /software/items/model_package/packages/ecimnotifheartbeathandlermodel -t package -o name="EXTR-lsbwrapper73-1.0.0"
#litp create -p /software/items/model_package/packages/cbanodeevents -t package -o name="EXTR-lsbwrapper74-1.0.0"
#litp create -p /software/items/model_package/packages/comecimcmdeltasyncflowmodel -t package -o name="EXTR-lsbwrapper75-1.0.0"
#litp create -p /software/items/model_package/packages/comecimcmdeltasynchandlermodel -t package -o name="EXTR-lsbwrapper76-1.0.0"
#litp create -p /software/items/model_package/packages/comecimcmpreparesubshandlermodel -t package -o name="EXTR-lsbwrapper77-1.0.0"
#litp create -p /software/items/model_package/packages/comecimcmsubscriptionhandlermodel -t package -o name="EXTR-lsbwrapper78-1.0.0"
#litp create -p /software/items/model_package/packages/comecimcreatesubscriptionflowmodel -t package -o name="EXTR-lsbwrapper79-1.0.0"
#litp create -p /software/items/model_package/packages/comecimdeletesubscriptionflowmodel -t package -o name="EXTR-lsbwrapper80-1.0.0"
# 80
#litp create -p /software/items/model_package/packages/comecimdeletesubshandlermodel -t package -o name="EXTR-lsbwrapper81-1.0.0"
#litp create -p /software/items/model_package/packages/comecimnotifsupervisionhandlermodel -t package -o name="EXTR-lsbwrapper82-1.0.0"
#litp create -p /software/items/model_package/packages/ecimnotificationhandlingflowmodel -t package -o name="EXTR-lsbwrapper83-1.0.0"
#litp create -p /software/items/model_package/packages/sgsncreatesubsflowmodel -t package -o name="EXTR-lsbwrapper84-1.0.0"
#litp create -p /software/items/model_package/packages/sgsndeletesubsflowmodel -t package -o name="EXTR-lsbwrapper85-1.0.0"
#litp create -p /software/items/model_package/packages/notificationcachedefinitionmodels -t package -o name="EXTR-lsbwrapper86-1.0.0"
#litp create -p /software/items/model_package/packages/cbacmsyncnodeflowmodels -t package -o name="EXTR-lsbwrapper87-1.0.0"
#litp create -p /software/items/model_package/packages/cbacmsyncnodehandlermodel -t package -o name="EXTR-lsbwrapper88-1.0.0"
#litp create -p /software/items/model_package/packages/comecimcmfiltergethandlermodel -t package -o name="EXTR-lsbwrapper89-1.0.0"
#litp create -p /software/items/model_package/packages/radionodecmreadnodeflow -t package -o name="EXTR-lsbwrapper90-1.0.0"
# 90
#litp create -p /software/items/model_package/packages/sgsnmmecmreadnodeflow -t package -o name="EXTR-lsbwrapper91-1.0.0"
#litp create -p /software/items/model_package/packages/netconfperiodictaskhandlermodel -t package -o name="EXTR-lsbwrapper92-1.0.0"
#litp create -p /software/items/model_package/packages/netconfsessionsubshandlermodel -t package -o name="EXTR-lsbwrapper93-1.0.0"
#litp create -p /software/items/model_package/packages/sgsnmmenetconfpreconnhandmodel -t package -o name="EXTR-lsbwrapper94-1.0.0"
#litp create -p /software/items/model_package/packages/cbanetconfconnecthandlermodel -t package -o name="EXTR-lsbwrapper95-1.0.0"
#litp create -p /software/items/model_package/packages/cbacmnetconfhandlermodel -t package -o name="EXTR-lsbwrapper96-1.0.0"
#litp create -p /software/items/model_package/packages/cbaconfigurationmodel -t package -o name="EXTR-lsbwrapper97-1.0.0"
#litp create -p /software/items/model_package/packages/cbanetconfdisconnecthandlermodel -t package -o name="EXTR-lsbwrapper98-1.0.0"
#litp create -p /software/items/model_package/packages/netconfsessionbuilderhandmodel -t package -o name="EXTR-lsbwrapper99-1.0.0"
#litp create -p /software/items/model_package/packages/netconfsessiondestroyerhandmodel -t package -o name="EXTR-lsbwrapper100-1.0.0"
# 100
#litp create -p /software/items/model_package/packages/netconfsessionreleaserhandmodel -t package -o name="EXTR-lsbwrapper101-1.0.0"
#litp create -p /software/items/model_package/packages/sshcredentialsmanagerhandlermodel -t package -o name="EXTR-lsbwrapper102-1.0.0"
#litp create -p /software/items/model_package/packages/sshtransportconnecthandlermodel -t package -o name="EXTR-lsbwrapper103-1.0.0"
#litp create -p /software/items/model_package/packages/netconfinboundconfighandlermodel -t package -o name="EXTR-lsbwrapper104-1.0.0"
#litp create -p /software/items/model_package/packages/sgsnmmesecuritymediationconfig -t package -o name="EXTR-lsbwrapper105-1.0.0"
#litp create -p /software/items/model_package/packages/sgsnmmesecuritysshcommandflow -t package -o name="EXTR-lsbwrapper106-1.0.0"
#litp create -p /software/items/model_package/packages/sshcommandhandlermodel -t package -o name="EXTR-lsbwrapper107-1.0.0"
#litp create -p /software/items/model_package/packages/sgsnmmecommandhandlermodel -t package -o name="EXTR-lsbwrapper108-1.0.0"
#litp create -p /software/items/model_package/packages/authenticationfailureevent -t package -o name="EXTR-lsbwrapper109-1.0.0"
#litp create -p /software/items/model_package/packages/authenticationfailureflow -t package -o name="EXTR-lsbwrapper110-1.0.0"
#110
#litp create -p /software/items/model_package/packages/authenticationfailurehandlermodel -t package -o name="EXTR-lsbwrapper111-1.0.0"
#litp create -p /software/items/model_package/packages/fmmediationeventmodel -t package -o name="EXTR-lsbwrapper112-1.0.0"
#litp create -p /software/items/model_package/packages/er6000cimodel -t package -o name="EXTR-lsbwrapper113-1.0.0"
#litp create -p /software/items/model_package/packages/er6000nodemodelcommon -t package -o name="EXTR-lsbwrapper114-1.0.0"
#litp create -p /software/items/model_package/packages/er6274nodemodelcommon -t package -o name="EXTR-lsbwrapper115-1.0.0"
#litp create -p /software/items/model_package/packages/er6672nodemodelcommon -t package -o name="EXTR-lsbwrapper116-1.0.0"
#litp create -p /software/items/model_package/packages/er6675nodemodelcommon -t package -o name="EXTR-lsbwrapper117-1.0.0"
#litp create -p /software/items/model_package/packages/upgradeindhttpfilehandlermodel -t package -o name="EXTR-lsbwrapper118-1.0.0"
#litp create -p /software/items/model_package/packages/upgradeindcppretrmimhandlersmodel -t package -o name="EXTR-lsbwrapper119-1.0.0"
#litp create -p /software/items/model_package/packages/upgradeindcppretrievemimflow -t package -o name="EXTR-lsbwrapper120-1.0.0"
# 120
#litp create -p /software/items/model_package/packages/ftphandlermodel -t package -o name="EXTR-lsbwrapper121-1.0.0"
#litp create -p /software/items/model_package/packages/upgradeindecimretrmhandlersmodel -t package -o name="EXTR-lsbwrapper122-1.0.0"
#litp create -p /software/items/model_package/packages/upgradeindecimretrievemimflow -t package -o name="EXTR-lsbwrapper123-1.0.0"
#litp create -p /software/items/model_package/packages/upgradeindcomecimretrmimhrsmodel -t package -o name="EXTR-lsbwrapper124-1.0.0"
#litp create -p /software/items/model_package/packages/erbshchandlerflows -t package -o name="EXTR-lsbwrapper125-1.0.0"
#litp create -p /software/items/model_package/packages/erbshandlermodels -t package -o name="EXTR-lsbwrapper126-1.0.0"
#litp create -p /software/items/model_package/packages/minilinkindoornodemodelcommon -t package -o name="EXTR-lsbwrapper127-1.0.0"
#litp create -p /software/items/model_package/packages/minilinkindoorcimodel -t package -o name="EXTR-lsbwrapper128-1.0.0"
#litp create -p /software/items/model_package/packages/minilinkindoorcmmediationconf -t package -o name="EXTR-lsbwrapper129-1.0.0"
#litp create -p /software/items/model_package/packages/minilinkoutdoornodemodelcom -t package -o name="EXTR-lsbwrapper130-1.0.0"
# 130
#litp create -p /software/items/model_package/packages/minilinkoutdoorcimodel -t package -o name="EXTR-lsbwrapper131-1.0.0"
#litp create -p /software/items/model_package/packages/minilinkoutdoorcmmedconfig -t package -o name="EXTR-lsbwrapper132-1.0.0"
#litp create -p /software/items/model_package/packages/softwaresynceventmodel -t package -o name="EXTR-lsbwrapper133-1.0.0"
#litp create -p /software/items/model_package/packages/cppsoftwaresyncflowmodel -t package -o name="EXTR-lsbwrapper134-1.0.0"
#litp create -p /software/items/model_package/packages/commonsoftwaresynchandlermodel -t package -o name="EXTR-lsbwrapper135-1.0.0"
#litp create -p /software/items/model_package/packages/cppsoftwaresynchandlermodel -t package -o name="EXTR-lsbwrapper136-1.0.0"
#litp create -p /software/items/model_package/packages/mediationsgsnmmenodemodel16a -t package -o name="EXTR-lsbwrapper137-1.0.0"
#litp create -p /software/items/model_package/packages/commodelsr60 -t package -o name="EXTR-lsbwrapper138-1.0.0"
#litp create -p /software/items/model_package/packages/radionodenodemodel16b -t package -o name="EXTR-lsbwrapper139-1.0.0"
#litp create -p /software/items/model_package/packages/tlscredentialsmanagerhandlermodel -t package -o name="EXTR-lsbwrapper140-1.0.0"
# 140
#litp create -p /software/items/model_package/packages/cmrouterpolicymodel -t package -o name="EXTR-lsbwrapper141-1.0.0"
#litp create -p /software/items/model_package/packages/er6000routerpolicymodel -t package -o name="EXTR-lsbwrapper142-1.0.0"
#litp create -p /software/items/model_package/packages/comecimcmrouterpolicymodel -t package -o name="EXTR-lsbwrapper143-1.0.0"
#litp create -p /software/items/model_package/packages/networkexplorermodels -t package -o name="EXTR-lsbwrapper144-1.0.0"
#litp create -p /software/items/model_package/packages/smrsservicemodel -t package -o name="EXTR-lsbwrapper145-1.0.0"
#litp create -p /software/items/model_package/packages/wfsmodel -t package -o name="EXTR-lsbwrapper146-1.0.0"
#litp create -p /software/items/model_package/packages/policyenginemodel -t package -o name="EXTR-lsbwrapper147-1.0.0"
#litp create -p /software/items/model_package/packages/fmprocessedeventmodel -t package -o name="EXTR-lsbwrapper148-1.0.0"
#litp create -p /software/items/model_package/packages/targethandlersmodels -t package -o name="EXTR-lsbwrapper149-1.0.0"
#litp create -p /software/items/model_package/packages/genericidentitymgmtmodel -t package -o name="EXTR-lsbwrapper150-1.0.0"
# 150
#litp create -p /software/items/model_package/packages/ssoutilitiesmodel -t package -o name="EXTR-lsbwrapper151-1.0.0"
#litp create -p /software/items/model_package/packages/pkimanagerconfigmodel -t package -o name="EXTR-lsbwrapper152-1.0.0"
#litp create -p /software/items/model_package/packages/pkicdpsmodel -t package -o name="EXTR-lsbwrapper153-1.0.0"
#litp create -p /software/items/model_package/packages/pkicoremodel -t package -o name="EXTR-lsbwrapper154-1.0.0"
#litp create -p /software/items/model_package/packages/pkiracmpmodel -t package -o name="EXTR-lsbwrapper155-1.0.0"
#litp create -p /software/items/model_package/packages/pmfunctionmodel -t package -o name="EXTR-lsbwrapper156-1.0.0"
#litp create -p /software/items/model_package/packages/pmiccorbahandlermodel -t package -o name="EXTR-lsbwrapper157-1.0.0"
#litp create -p /software/items/model_package/packages/pmicdpshandlermodel -t package -o name="EXTR-lsbwrapper158-1.0.0"
#litp create -p /software/items/model_package/packages/pmicfilecollectionhandlersmodels -t package -o name="EXTR-lsbwrapper159-1.0.0"
#litp create -p /software/items/model_package/packages/pmicinitiationflowmodel -t package -o name="EXTR-lsbwrapper160-1.0.0"
# 160
#litp create -p /software/items/model_package/packages/pmicfilecollection -t package -o name="EXTR-lsbwrapper161-1.0.0"
#litp create -p /software/items/model_package/packages/mediationconfigurationmodel -t package -o name="EXTR-lsbwrapper162-1.0.0"
#litp create -p /software/items/model_package/packages/pmicmodel -t package -o name="EXTR-lsbwrapper163-1.0.0"
#litp create -p /software/items/model_package/packages/sgsnmmepmpollingflow -t package -o name="EXTR-lsbwrapper164-1.0.0"
#litp create -p /software/items/model_package/packages/comecimpmpollingflow -t package -o name="EXTR-lsbwrapper165-1.0.0"
#litp create -p /software/items/model_package/packages/comecimpmpollinghandlermodel -t package -o name="EXTR-lsbwrapper166-1.0.0"
#litp create -p /software/items/model_package/packages/ecimpmoperationsflow -t package -o name="EXTR-lsbwrapper167-1.0.0"
#litp create -p /software/items/model_package/packages/ecimpmoperationshandlermodel -t package -o name="EXTR-lsbwrapper168-1.0.0"
#litp create -p /software/items/model_package/packages/comecimpmfilecollectionflow -t package -o name="EXTR-lsbwrapper169-1.0.0"
#litp create -p /software/items/model_package/packages/comecimpmfilecollectsetuphandmodel -t package -o name="EXTR-lsbwrapper170-1.0.0"
# 170
#litp create -p /software/items/model_package/packages/sgsnmmepmmediationconfigmodel -t package -o name="EXTR-lsbwrapper171-1.0.0"
#litp create -p /software/items/model_package/packages/comecimpmoperationsflow -t package -o name="EXTR-lsbwrapper172-1.0.0"
#litp create -p /software/items/model_package/packages/comecimpmoperhandlermodel -t package -o name="EXTR-lsbwrapper173-1.0.0"
#litp create -p /software/items/model_package/packages/radionodepmmediationconfigmodel -t package -o name="EXTR-lsbwrapper174-1.0.0"
#litp create -p /software/items/model_package/packages/comecimpmcompleteoperationsflow -t package -o name="EXTR-lsbwrapper175-1.0.0"
#litp create -p /software/items/model_package/packages/comecimpmevents -t package -o name="EXTR-lsbwrapper176-1.0.0"
#litp create -p /software/items/model_package/packages/ERICcomecimpmevents_CXP9032379 -t package -o name="EXTR-lsbwrapper177-1.0.0"
#litp create -p /software/items/model_package/packages/comecimpmasyncoperhandlermodel -t package -o name="EXTR-lsbwrapper178-1.0.0"
#litp create -p /software/items/model_package/packages/ecimpmeventsmoperationhandlrmodel -t package -o name="EXTR-lsbwrapper179-1.0.0"
#litp create -p /software/items/model_package/packages/pmicebminitiationhandlermodel -t package -o name="EXTR-lsbwrapper180-1.0.0"
# 180
#litp create -p /software/items/model_package/packages/dpsdataretrievalsetuphandlermodel -t package -o name="EXTR-lsbwrapper181-1.0.0"
#litp create -p /software/items/model_package/packages/erbscpppmiccollectionhandlersmodel -t package -o name="EXTR-lsbwrapper182-1.0.0"
#litp create -p /software/items/model_package/packages/pmiccelltraceinitsetuphndlrmodels -t package -o name="EXTR-lsbwrapper183-1.0.0"
#litp create -p /software/items/model_package/packages/pmicpredefstatsinitsetuphndlrmodels -t package -o name="EXTR-lsbwrapper184-1.0.0"
#litp create -p /software/items/model_package/packages/pmicstatsinitsetuphndlrsmodels -t package -o name="EXTR-lsbwrapper185-1.0.0"
#litp create -p /software/items/model_package/packages/sgsnmmepmhandlersmodel -t package -o name="EXTR-lsbwrapper186-1.0.0"
#litp create -p /software/items/model_package/packages/pmiccommonscannerhandlermodel -t package -o name="EXTR-lsbwrapper187-1.0.0"
#litp create -p /software/items/model_package/packages/alarmpersistencemodel -t package -o name="EXTR-lsbwrapper188-1.0.0"
#litp create -p /software/items/model_package/packages/fmfmxmodel -t package -o name="EXTR-lsbwrapper189-1.0.0"
#litp create -p /software/items/model_package/packages/fmcorbamediationconfig -t package -o name="EXTR-lsbwrapper190-1.0.0"
# 190
#litp create -p /software/items/model_package/packages/cppalarmsupervisionflowmodel -t package -o name="EXTR-lsbwrapper191-1.0.0"
#litp create -p /software/items/model_package/packages/cppalarmsupervisionhandlermodel -t package -o name="EXTR-lsbwrapper192-1.0.0"
#litp create -p /software/items/model_package/packages/corbainterfacemodel -t package -o name="EXTR-lsbwrapper193-1.0.0"
#litp create -p /software/items/model_package/packages/solrloadschedulemodel -t package -o name="EXTR-lsbwrapper194-1.0.0"
#litp create -p /software/items/model_package/packages/dlmsconfigurationmodel -t package -o name="EXTR-lsbwrapper195-1.0.0"
#litp create -p /software/items/model_package/packages/eniqtopologyservicemodel -t package -o name="EXTR-lsbwrapper196-1.0.0"
#litp create -p /software/items/model_package/packages/predefinedfiltermodel -t package -o name="EXTR-lsbwrapper197-1.0.0"
#litp create -p /software/items/model_package/packages/shmfunctionmodel -t package -o name="EXTR-lsbwrapper198-1.0.0"
#litp create -p /software/items/model_package/packages/shmjobmodel -t package -o name="EXTR-lsbwrapper199-1.0.0"
#litp create -p /software/items/model_package/packages/cppinventorymodel -t package -o name="EXTR-lsbwrapper200-1.0.0"
# 200
#litp create -p /software/items/model_package/packages/inventoryhandlermodel -t package -o name="EXTR-lsbwrapper201-1.0.0"
#litp create -p /software/items/model_package/packages/cppinventorymediationconfigmodel -t package -o name="EXTR-lsbwrapper202-1.0.0"
#litp create -p /software/items/model_package/packages/upgradepackagemodel -t package -o name="EXTR-lsbwrapper203-1.0.0"
#litp create -p /software/items/model_package/packages/shmmodelextension -t package -o name="EXTR-lsbwrapper204-1.0.0"
#litp create -p /software/items/model_package/packages/licensekeyinfomodel -t package -o name="EXTR-lsbwrapper205-1.0.0"
#litp create -p /software/items/model_package/packages/cppinventoryflowmodel -t package -o name="EXTR-lsbwrapper206-1.0.0"
#litp create -p /software/items/model_package/packages/kpicalculationflowmodel -t package -o name="EXTR-lsbwrapper207-1.0.0"
#litp create -p /software/items/model_package/packages/apdatacore -t package -o name="EXTR-lsbwrapper208-1.0.0"
#litp create -p /software/items/model_package/packages/apdatamacro -t package -o name="EXTR-lsbwrapper209-1.0.0"
#litp create -p /software/items/model_package/packages/apmodelecim -t package -o name="EXTR-lsbwrapper210-1.0.0"
# 210
#litp create -p /software/items/model_package/packages/nodediscoveryflowmodel -t package -o name="EXTR-lsbwrapper211-1.0.0"
#litp create -p /software/items/model_package/packages/nodediscoveryhandlersmodel -t package -o name="EXTR-lsbwrapper212-1.0.0"
#litp create -p /software/items/model_package/packages/apmediationmodel -t package -o name="EXTR-lsbwrapper213-1.0.0"
#litp create -p /software/items/model_package/packages/licensecontrolmonitoringmodel -t package -o name="EXTR-lsbwrapper214-1.0.0"
#litp create -p /software/items/model_package/packages/ipsmtemplatemanagermodel -t package -o name="EXTR-lsbwrapper215-1.0.0"
#litp create -p /software/items/model_package/packages/ipsmservicedefinitionmodel -t package -o name="EXTR-lsbwrapper216-1.0.0"
#litp create -p /software/items/model_package/packages/ipsmservicemanagermodel -t package -o name="EXTR-lsbwrapper217-1.0.0"
#litp create -p /software/items/model_package/packages/ipnediscoverymodel -t package -o name="EXTR-lsbwrapper218-1.0.0"
#litp create -p /software/items/model_package/packages/activityservicemodel -t package -o name="EXTR-lsbwrapper219-1.0.0"
#litp create -p /software/items/model_package/packages/er6000mediationconfiguration -t package -o name="EXTR-lsbwrapper220-1.0.0"
# 220
#litp create -p /software/items/model_package/packages/mediationiptransportchannelmodels -t package -o name="EXTR-lsbwrapper221-1.0.0"
#litp create -p /software/items/model_package/packages/er6000nodemodel16a -t package -o name="EXTR-lsbwrapper222-1.0.0"
#litp create -p /software/items/model_package/packages/er6672nodemodel16a -t package -o name="EXTR-lsbwrapper223-1.0.0"
#litp create -p /software/items/model_package/packages/netconfecimsyncnodehandlermodel -t package -o name="EXTR-lsbwrapper224-1.0.0"
#litp create -p /software/items/model_package/packages/er6000syncnodeflow -t package -o name="EXTR-lsbwrapper225-1.0.0"
#litp create -p /software/items/model_package/packages/er6000configurationmodel -t package -o name="EXTR-lsbwrapper226-1.0.0"
#litp create -p /software/items/model_package/packages/netconfecimoperationflow -t package -o name="EXTR-lsbwrapper227-1.0.0"
#litp create -p /software/items/model_package/packages/ipnesnmpscanflo -t package -o name="EXTR-lsbwrapper228-1.0.0"
#litp create -p /software/items/model_package/packages/ipnediscoveryhandlermodel -t package -o name="EXTR-lsbwrapper229-1.0.0"
#litp create -p /software/items/model_package/packages/netconfyangsyncnodehandlermodel -t package -o name="EXTR-lsbwrapper230-1.0.0"
# 230
#litp create -p /software/items/model_package/packages/netconfyangoperationhandlermodel -t package -o name="EXTR-lsbwrapper231-1.0.0"
#litp create -p /software/items/model_package/packages/netconfyangoperationflow -t package -o name="EXTR-lsbwrapper232-1.0.0"
#litp create -p /software/items/model_package/packages/iposcmnotificationhandlingflow -t package -o name="EXTR-lsbwrapper233-1.0.0"
#litp create -p /software/items/model_package/packages/iposcmheartbtsuphandlermodel -t package -o name="EXTR-lsbwrapper234-1.0.0"
#litp create -p /software/items/model_package/packages/iposcmheartbtsupflow -t package -o name="EXTR-lsbwrapper235-1.0.0"
#litp create -p /software/items/model_package/packages/iposcmsubflow -t package -o name="EXTR-lsbwrapper236-1.0.0"
#litp create -p /software/items/model_package/packages/iposcmsubhandlermodel -t package -o name="EXTR-lsbwrapper237-1.0.0"
#litp create -p /software/items/model_package/packages/pkirascepmodel -t package -o name="EXTR-lsbwrapper238-1.0.0"
#litp create -p /software/items/model_package/packages/pkiratdpsmodel -t package -o name="EXTR-lsbwrapper239-1.0.0"
#litp create -p /software/items/model_package/packages/snmpfmhandlermodel -t package -o name="EXTR-lsbwrapper240-1.0.0"
# 240
#litp create -p /software/items/model_package/packages/snmpfmflowmodel -t package -o name="EXTR-lsbwrapper241-1.0.0"
#litp create -p /software/items/model_package/packages/ecimnetconffmflowmodel -t package -o name="EXTR-lsbwrapper242-1.0.0"
#litp create -p /software/items/model_package/packages/sgsnmmenetconffmflowmodel -t package -o name="EXTR-lsbwrapper243-1.0.0"
#litp create -p /software/items/model_package/packages/snmpfmchannelmodels -t package -o name="EXTR-lsbwrapper244-1.0.0"
#litp create -p /software/items/model_package/packages/minilinkindoorfmmediationconf -t package -o name="EXTR-lsbwrapper245-1.0.0"
#litp create -p /software/items/model_package/packages/minilinkindoortargetdestflow -t package -o name="EXTR-lsbwrapper246-1.0.0"
#litp create -p /software/items/model_package/packages/er6000fmmediationconfiguration -t package -o name="EXTR-lsbwrapper247-1.0.0"
#litp create -p /software/items/model_package/packages/er6000snmpfmmodel -t package -o name="EXTR-lsbwrapper248-1.0.0"
#litp create -p /software/items/model_package/packages/er6000snmpfmhandlermodel -t package -o name="EXTR-lsbwrapper249-1.0.0"
#litp create -p /software/items/model_package/packages/msrbsv2fmmediationconfig -t package -o name="EXTR-lsbwrapper250-1.0.0"
# 250
#litp create -p /software/items/model_package/packages/wppsgsnmmefmmediationconfigmodel -t package -o name="EXTR-lsbwrapper251-1.0.0"
#litp create -p /software/items/model_package/packages/ecimnetconffmhandlermodel -t package -o name="EXTR-lsbwrapper252-1.0.0"
#litp create -p /software/items/model_package/packages/sgsnmmenetconffmhandlermodel -t package -o name="EXTR-lsbwrapper253-1.0.0"
#litp create -p /software/items/model_package/packages/autocellidmodel -t package -o name="EXTR-lsbwrapper254-1.0.0"
# 254






# NETWORKING ROUTE
litp create -p /infrastructure/networking/routes/services_gateway_route -t route -o gateway="${nodes_gateway}" subnet="0.0.0.0/0"

# STORAGE PROFILE - MS
litp create -p /infrastructure/storage/storage_profiles/ms_storage_profile -t storage-profile -o volume_driver="lvm"
# VG1
litp create -p /infrastructure/storage/storage_profiles/ms_storage_profile/volume_groups/vg1 -t volume-group -o volume_group_name="vg_root"
litp create -p /infrastructure/storage/storage_profiles/ms_storage_profile/volume_groups/vg1/file_systems/fs_root -t file-system -o mount_point="/" size="15G" snap_external="false" snap_size=100 type="ext4"
litp create -p /infrastructure/storage/storage_profiles/ms_storage_profile/volume_groups/vg1/file_systems/fs_home -t file-system -o mount_point="/home" size="8G" snap_external="false" snap_size=100 type="ext4"
litp create -p /infrastructure/storage/storage_profiles/ms_storage_profile/volume_groups/vg1/file_systems/fs_var_log -t file-system -o mount_point="/var/log" size="20G" snap_external="false" snap_size=100 type="ext4"
litp create -p /infrastructure/storage/storage_profiles/ms_storage_profile/volume_groups/vg1/file_systems/fs_var -t file-system -o mount_point="/var" size="17G" snap_external="false" snap_size=100 type="ext4"
litp create -p /infrastructure/storage/storage_profiles/ms_storage_profile/volume_groups/vg1/file_systems/fs_swap -t file-system -o mount_point="swap" size="2G" snap_external="false" snap_size=100 type="swap"
litp create -p /infrastructure/storage/storage_profiles/ms_storage_profile/volume_groups/vg1/file_systems/fs_data -t file-system -o mount_point="/var/lib/mysql" size="20G" snap_external="false" snap_size=1 type="ext4"
litp create -p /infrastructure/storage/storage_profiles/ms_storage_profile/volume_groups/vg1/file_systems/fs_unmounted -t file-system -o size="100M" snap_external="false" snap_size=20 type="ext4"
litp create -p /infrastructure/storage/storage_profiles/ms_storage_profile/volume_groups/vg1/physical_devices/pd1 -t physical-device -o device_name="ms_hd0"

# VG2 - REMOVED AS DiSKS MERGED
#litp create -p /infrastructure/storage/storage_profiles/ms_storage_profile/volume_groups/vg2 -t volume-group -o volume_group_name="vg_addt_1"
#litp create -p /infrastructure/storage/storage_profiles/ms_storage_profile/volume_groups/vg2/file_systems/fs_software -t file-system -o mount_point="/additional_1" size="20G" snap_external="false" snap_size=1 type="ext4"
#litp create -p /infrastructure/storage/storage_profiles/ms_storage_profile/volume_groups/vg2/file_systems/fs_unmounted -t file-system -o size="100M" snap_external="false" snap_size=20 type="ext4"
#litp create -p /infrastructure/storage/storage_profiles/ms_storage_profile/volume_groups/vg2/physical_devices/pd1 -t physical-device -o device_name="ms_hd1"

# VG3
#litp create -p /infrastructure/storage/storage_profiles/ms_storage_profile/volume_groups/vg3 -t volume-group -o volume_group_name="vg_addt_2"
#litp create -p /infrastructure/storage/storage_profiles/ms_storage_profile/volume_groups/vg3/file_systems/fs_software -t file-system -o mount_point="/additional_2" size="20G" snap_external="false" snap_size=1 type="ext4"
#litp create -p /infrastructure/storage/storage_profiles/ms_storage_profile/volume_groups/vg3/file_systems/fs_unmounted -t file-system -o size="100M" snap_external="false" snap_size=0 type="ext4"
#litp create -p /infrastructure/storage/storage_profiles/ms_storage_profile/volume_groups/vg3/physical_devices/pd1 -t physical-device -o device_name="ms_hd2"

# SYSTEM CONFIGURATION
litp create -p /infrastructure/systems/management_server -t system -o system_name="${ms_sysname}"
litp create -p /infrastructure/systems/management_server/disks/disk0 -t disk -o bootable="true" disk_part="false" name="ms_hd0" size="400G" uuid="${ms_disk_0_uuid}"
#litp create -p /infrastructure/systems/management_server/disks/disk1 -t disk -o bootable="false" disk_part="false" name="ms_hd1" size="140G" uuid="${ms_disk_1_uuid}"
#litp create -p /infrastructure/systems/management_server/disks/disk2 -t disk -o bootable="false" disk_part="false" name="ms_hd2" size="140G" uuid="${ms_disk_2_uuid}"


# FIREWALL CONFIGURATION
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

# INHERITANCE STARTS HERE

# NFS FILE SYSTEMS
#litp inherit -p /ms/file_systems/nfsm-brsadm_home -s /infrastructure/storage/nfs_mounts/nfsm-brsadm_home
#litp inherit -p /ms/file_systems/nfsm-storobs_home -s /infrastructure/storage/nfs_mounts/nfsm-storobs_home
#litp inherit -p /ms/file_systems/nfsm-data -s /infrastructure/storage/nfs_mounts/nfsm-data
#litp inherit -p /ms/file_systems/nfsm-ddc_data -s /infrastructure/storage/nfs_mounts/nfsm-ddc_data
#litp inherit -p /ms/file_systems/nfsm-hcdumps -s /infrastructure/storage/nfs_mounts/nfsm-hcdumps
#litp inherit -p /ms/file_systems/nfsm-mdt -s /infrastructure/storage/nfs_mounts/nfsm-mdt
#litp inherit -p /ms/file_systems/nfsm-alex -s /infrastructure/storage/nfs_mounts/nfsm-alex

# YUM REPOSITORIES
litp inherit -p /ms/items/common_repo -s /software/items/common_repo
litp inherit -p /ms/items/ms_repo -s /software/items/ms_repo
litp inherit -p /ms/items/model_repo -s /software/items/model_repo
litp inherit -p /ms/items/ntp_service -s /software/items/ntp_service
litp inherit -p /ms/items/ddc_package -s /software/items/ddc_package
litp inherit -p /ms/items/syslog8 -s /software/items/rsyslog8
litp inherit -p /ms/items/enm_configuration -s /software/items/enm_configuration
litp inherit -p /ms/items/enm_utilities -s /software/items/enm_utilities
litp inherit -p /ms/items/enm_eniq_integration -s /software/items/enm_eniq_integration
litp inherit -p /ms/items/backup_restore_package -s /software/items/backup_restore_package
litp inherit -p /ms/items/backup_restore_ombs_package -s /software/items/backup_restore_ombs_package
litp inherit -p /ms/items/pibscripts -s /software/items/pibscripts
litp inherit -p /ms/items/model_package -s /software/items/model_package

# NETWORK CONFIGURATION
litp create -p /ms/network_interfaces/eth0 -t eth -o bridge="br0" device_name="eth0" macaddress="${ms_eth0_mac}"
#litp create -p /ms/network_interfaces/eth1 -t eth -o bridge="br1" device_name="eth1" macaddress="${ms_eth1_mac}"
# ONLY 2 NICS ON 210 MS
#litp create -p /ms/network_interfaces/eth2 -t eth -o bridge="br2" device_name="eth2" macaddress="${ms_eth2_mac}"
#litp create -p /ms/network_interfaces/eth3 -t eth -o bridge="br3" device_name="eth3" macaddress="${ms_eth3_mac}"

litp create -p /ms/network_interfaces/br0 -t bridge -o ipaddress="${ms_ip}" network_name="services" device_name="br0"
#litp create -p /ms/network_interfaces/br1 -t bridge -o ipaddress="${ms_ip_2}" network_name="storage" device_name="br1"
#litp create -p /ms/network_interfaces/br2 -t bridge -o ipaddress="${ms_ip_3}" network_name="backup" device_name="br2"
#litp create -p /ms/network_interfaces/br3 -t bridge -o ipaddress="${ms_ip_4}" network_name="internal" device_name="br3"

litp inherit -p /ms/routes/services_gateway_route -s /infrastructure/networking/routes/services_gateway_route 


# SERVICES
litp create -p /ms/services/sentinel -t service -o cleanup_command="/sbin/service sentinel stop" service_name="sentinel"
litp create -p /ms/services/cobbler -t cobbler-service -o authentication="authn_configfile" ksm_ksname="litp.ks" ksm_path="/var/lib/cobbler/kickstarts" ksm_selinux_mode="enforcing" manage_dhcp="true" manage_dns="false" puppet_auto_setup="true"  remove_old_puppet_certs_automatically="true" rsync_disabled="false" sign_puppet_certs_automatically="true"


litp inherit -p /ms/storage_profile -s /infrastructure/storage/storage_profiles/ms_storage_profile
litp inherit -p /ms/system -s /infrastructure/systems/management_server

# SETUP VM ON THE MS
/usr/bin/md5sum /var/www/html/images/vm_test_image.qcow2 | cut -d ' ' -f 1 > /var/www/html/images/vm_test_image.qcow2.md5

litp create -t vm-image -p /software/images/img_vm1 -o name=vm1_1 source_uri=http://Archer/images/vm_test_image.qcow2
litp create -t vm-service -p /ms/services/se_vm1 -o service_name=vm1 image_name=vm1_1 cpus=2 ram=2000M internal_status_check=off

litp create -t vm-network-interface -p /ms/services/se_vm1/vm_network_interfaces/vm_nic1 -o device_name=eth0 host_device=br0 network_name=services gateway="${ms_gateway}" ipaddresses="${node_ip[0]}"

litp create -t vm-alias -p /ms/services/se_vm1/vm_aliases/vm_ms1 -o alias_names=Archer address="10.44.86.210"
litp create -t vm-yum-repo -p /ms/services/se_vm1/vm_yum_repos/updates -o name=vm_UPDATES base_url=http://Archer/6.6/updates/x86_64/Packages
litp create -t vm-yum-repo -p /ms/services/se_vm1/vm_yum_repos/os -o name=vm_os base_url=http://10.44.86.210/6.6/os/x86_64
litp create -t vm-yum-repo -p /ms/services/se_vm1/vm_yum_repos/3pp -o name=vm_3pp base_url=http://Archer/3pp

#litp create -t vm-disk -p /ms/services/se_vm1/vm_disks/vm_disk_1 -o host_file_system="fs_unmounted" host_volume_group="vg1" mount_point="/12270_vg1"
#litp create -t vm-disk -p /ms/services/se_vm1/vm_disks/vm_disk_2 -o host_file_system="fs_unmounted" host_volume_group="vg2" mount_point="/12270_vg2"
#litp create -t vm-disk -p /ms/services/se_vm1/vm_disks/vm_disk_3 -o host_file_system="fs_unmounted" host_volume_group="vg3" mount_point="/12270_vg3"

# 107476
litp create -t vm-ram-mount -p /ms/services/se_vm1/vm_ram_mounts/fs_test_mount -o type=tmpfs mount_point="/mnt/tmp_test_mount" mount_options="size=256M,noexec,nodev,nosuid"


litp create_plan

