#!/bin/bash

ROOTDIR=$(dirname $0)/..
PRODUCT_OUT=${PRODUCT_OUT:=${ROOTDIR}/out/target/product/imx8m_phanbell}

set -e

fastboot flash bootloader0 ${PRODUCT_OUT}/u-boot.imx
fastboot flash gpt ${PRODUCT_OUT}/partition-table.img
fastboot reboot-bootloader
fastboot erase misc
fastboot flash boot ${PRODUCT_OUT}/boot.img
fastboot flash rootfs ${PRODUCT_OUT}/rootfs.img
fastboot reboot
