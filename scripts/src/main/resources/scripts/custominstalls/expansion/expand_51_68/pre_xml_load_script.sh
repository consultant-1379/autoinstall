#!/bin/bash
#
# To be run before expansion with root_c1_4n_with_VxVM_updateable_only.xml
# Required as SG_STvm is changed from Active Standby to Active Active

litp remove -p /deployments/d1/clusters/c1/services/SG_STvm4/triggers/trig1