#!/bin/bash

set -e
set -x

# Symlink the Makefile, like it would be if repo checked this out.
# Otherwise, sourcing setup.sh doesn't work as expected.
ln -sfr git/continuous-build/build/Makefile git/continuous-build/Makefile

# Sourcing this only works in the directory above build...
pushd git/continuous-build
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

ARTIFACTS+="${ROOTDIR}/board/flash.sh "
ARTIFACTS+="${PRODUCT_OUT}/u-boot.imx "
ARTIFACTS+="${PRODUCT_OUT}/partition-table-8gb.img "
ARTIFACTS+="${PRODUCT_OUT}/partition-table-16gb.img "
ARTIFACTS+="${PRODUCT_OUT}/partition-table-64gb.img "

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
