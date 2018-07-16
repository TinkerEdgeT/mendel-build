#!/bin/bash

set -e

ROOTDIR=$(dirname $0)/..
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# If there's a boot.img in the same folder as flash.sh,
# find artifacts in the directory containing the script.
if [ -e ${SCRIPT_DIR}/boot.img ]; then
    PRODUCT_OUT=${SCRIPT_DIR}
else
    PRODUCT_OUT=${PRODUCT_OUT:=${ROOTDIR}/out/target/product/imx8m_phanbell}
fi


fastboot flash bootloader0 ${PRODUCT_OUT}/u-boot.imx
fastboot flash gpt ${PRODUCT_OUT}/partition-table.img
fastboot reboot-bootloader
fastboot erase misc
fastboot flash boot ${PRODUCT_OUT}/boot.img
fastboot flash rootfs ${PRODUCT_OUT}/rootfs.img
fastboot reboot
