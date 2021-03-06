#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -e

export INITIAL_COPYRIGHT_YEAR=2016
export G5_DEVICE_LIST="g5 h830 h850"
export V20_DEVICE_LIST="v20 h910 h918 us996 ls997 vs995"
export G6_DEVICE_LIST="g6"

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$MY_DIR" ]]; then MY_DIR="$PWD"; fi

CM_ROOT="$MY_DIR"/../../..

HELPER="$CM_ROOT"/vendor/cm/build/tools/extract_utils.sh
if [ ! -f "$HELPER" ]; then
    echo "Unable to find helper script at $HELPER"
    exit 1
fi
. "$HELPER"

# Initialize the helper for common platform
setup_vendor "$PLATFORM_COMMON" "$VENDOR" "$CM_ROOT" true

# Copyright headers and common guards
write_headers "$G5_DEVICE_LIST $V20_DEVICE_LIST"

# The standard blobs
write_makefiles "$MY_DIR"/proprietary-files.txt

# Qualcomm BSP blobs - we put a conditional around here
# in case the BSP is actually being built
printf '\n%s\n' "ifeq (\$(QCPATH),)" >> "$PRODUCTMK"
printf '\n%s\n' "ifeq (\$(QCPATH),)" >> "$ANDROIDMK"

write_makefiles "$MY_DIR"/proprietary-files-qc.txt

# Qualcomm performance blobs - conditional as well
# in order to support Cyanogen OS builds
cat << EOF >> "$PRODUCTMK"
endif

-include vendor/extra/devices.mk
ifneq (\$(call is-qc-perf-target),true)
EOF

cat << EOF >> "$ANDROIDMK"
endif

ifneq (\$(TARGET_HAVE_QC_PERF),true)
EOF

write_makefiles "$MY_DIR"/proprietary-files-qc-perf.txt

echo "endif" >> "$PRODUCTMK"
echo "endif" >> "$ANDROIDMK"

printf '\n%s\n' "\$(call inherit-product, vendor/qcom/binaries/msm8996/graphics/graphics-vendor.mk)" >> "$PRODUCTMK"

# We are done with platform
write_footers

# Reinitialize the helper for common device
setup_vendor "$DEVICE_COMMON" "$VENDOR" "$CM_ROOT" true

# Copyright headers and guards
if [ "$DEVICE_COMMON" == "g5-common" ]; then
    write_headers "$G5_DEVICE_LIST"
else
    if [ "$DEVICE_COMMON" == "g6-common" ]; then
        write_headers "$G6_DEVICE_LIST"
    else
        write_headers "$V20_DEVICE_LIST"
    fi
fi

write_makefiles "$MY_DIR"/../$DEVICE_COMMON/proprietary-files.txt

# We are done with common
write_footers

# Reinitialize the helper for device
setup_vendor "$DEVICE" "$VENDOR" "$CM_ROOT"

# Copyright headers and guards
write_headers

write_makefiles "$MY_DIR"/../$DEVICE/proprietary-files.txt

# Qualcomm BSP blobs - we put a conditional around here
# in case the BSP is actually being built
printf '\n%s\n' "ifeq (\$(QCPATH),)" >> "$PRODUCTMK"
printf '\n%s\n' "ifeq (\$(QCPATH),)" >> "$ANDROIDMK"

write_makefiles "$MY_DIR"/../$DEVICE/proprietary-files-qc.txt

printf '\n%s\n' "endif" >> "$PRODUCTMK"
printf '\n%s\n' "endif" >> "$ANDROIDMK"

# We are done with device
write_footers
