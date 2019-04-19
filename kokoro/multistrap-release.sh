#!/bin/bash

set -e
set -x

# Sourcing this only works in the directory above build...
pushd git
source build/setup.sh
popd

export PREBUILT_DOCKER_ROOT=${KOKORO_GFILE_DIR}
export FETCH_PBUILDER_DIRECTORY=${KOKORO_GFILE_DIR}
export ROOTFS_RAW_CACHE_DIRECTORY=${KOKORO_GFILE_DIR}

ARCHES="arm64"

for arch in ${ARCHES}
do
  export USERSPACE_ARCH=${arch}
  m docker-multistrap
  m docker-bootloader
  m docker-partition-table
  unset USERSPACE_ARCH
done

# Build the recovery partition, using the beta-uboot branch of uboot-imx
mv ${PRODUCT_OUT}/u-boot.imx ${PRODUCT_OUT}/u-boot.imx.clean
git -C ${ROOTDIR}/uboot-imx remote add https https://coral.googlesource.com/uboot-imx
REMOTE=https
git -C ${ROOTDIR}/uboot-imx fetch --unshallow
git -C ${ROOTDIR}/uboot-imx config remote.${REMOTE}.fetch "+refs/heads/*:refs/remotes/${REMOTE}/*"
git -C ${ROOTDIR}/uboot-imx fetch ${REMOTE}
git -C ${ROOTDIR}/uboot-imx checkout ${REMOTE}/beta-uboot
m docker-recovery
mv ${PRODUCT_OUT}/u-boot.imx.clean ${PRODUCT_OUT}/u-boot.imx


ARTIFACTS+="${ROOTDIR}/board/flash.sh "
ARTIFACTS+="${PRODUCT_OUT}/u-boot.imx "
ARTIFACTS+="${PRODUCT_OUT}/partition-table-8gb.img "
ARTIFACTS+="${PRODUCT_OUT}/partition-table-16gb.img "
ARTIFACTS+="${PRODUCT_OUT}/partition-table-64gb.img "
ARTIFACTS+="${PRODUCT_OUT}/recovery.img "

for arch in ${ARCHES}
do
  ARTIFACTS+="${PRODUCT_OUT}/multistrap/boot_${arch}.img "
  ARTIFACTS+="${PRODUCT_OUT}/multistrap/rootfs_${arch}.img "
done

# Check existence of artifacts, exit if one is missing
for artifact in ${ARTIFACTS}
do
  if [[ ! -f ${artifact} ]]; then
    echo "${artifact} not found!"
    exit 1
  fi
done

# Copy all artifacts to KOKORO_ARTIFACTS_DIR
for artifact in ${ARTIFACTS}
do
  cp ${artifact} ${KOKORO_ARTIFACTS_DIR}
  chmod -x ${KOKORO_ARTIFACTS_DIR}/$(basename ${artifact})
done
