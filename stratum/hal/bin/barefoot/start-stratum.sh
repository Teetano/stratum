#!/usr/bin/env bash
# Copyright 2020-present Open Networking Foundation
# SPDX-License-Identifier: Apache-2.0

set -ex

KDRV_PATH=${KDRV_PATH:-/usr/lib/modules/bf_kdrv.ko}
PLATFORM=${PLATFORM:-x86-64-accton-wedge100bf-32x-r0}

if [ -f "/etc/onl/platform" ]; then
    PLATFORM="$(cat /etc/onl/platform)"
fi

# Setup port map
PORT_MAP="/usr/share/stratum/$PLATFORM.json"
if [ ! -f "$PORT_MAP" ]; then
    echo "Cannot find port map file $PORT_MAP"
    exit 255
fi
rm /usr/share/port_map.json || true
ln -s $PORT_MAP /usr/share/port_map.json

# Load Kernel module
rmmod bf_kdrv || true
insmod $KDRV_PATH intr_mode="msi"

mkdir -p /var/run/stratum /var/log/stratum

exec /usr/bin/stratum_bf \
    -grpc_max_recv_msg_size=256 \
    -bf_sde_install=/usr \
    -persistent_config_dir=/etc/stratum/ \
    -phal_config_file=/etc/stratum/stratum_configs/${PLATFORM}/phal_config.pb.txt \
    -chassis_config_file=/etc/stratum/stratum_configs/${PLATFORM}/chassis_config.pb.txt \
    -forwarding_pipeline_configs_file=/var/run/stratum/pipeline_cfg.pb.txt \
    -write_req_log_file=/var/log/stratum/p4_writes.pb.txt \
    -bf_switchd_cfg=/usr/share/stratum/tofino_skip_p4_no_bsp.conf \
    -logtosyslog=false \
    -bf_switchd_background=false \
    -colorlogtostderr \
    -logtosyslog=false \
    -stderrthreshold=0 \
    -v=0 \
    $@
