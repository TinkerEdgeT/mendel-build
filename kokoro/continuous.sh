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

export TARBALL_FETCH_ROOT_DIRECTORY=${KOKORO_GFILE_DIR}
export DEBOOTSTRAP_TARBALL_REVISION=.
export ROOTFS_REVISION=.

m prereqs

m
m sdcard

pushd ${ROOTDIR}
python3 ${ROOTDIR}/build/create_release_manifest.py \
  -i ${ROOTDIR}/manifest/default.xml \
  -o ${KOKORO_ARTIFACTS_DIR}/manifest.xml
popd

cp ${PRODUCT_OUT}/u-boot.imx ${KOKORO_ARTIFACTS_DIR}
cp ${PRODUCT_OUT}/boot.img ${KOKORO_ARTIFACTS_DIR}
cp ${PRODUCT_OUT}/partition-table.img ${KOKORO_ARTIFACTS_DIR}
cp ${PRODUCT_OUT}/rootfs.img ${KOKORO_ARTIFACTS_DIR}
cp ${PRODUCT_OUT}/sdcard.img ${KOKORO_ARTIFACTS_DIR}