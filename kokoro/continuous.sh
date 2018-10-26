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

export IS_GLINUX=true
export TARBALL_FETCH_ROOT_DIRECTORY=${KOKORO_GFILE_DIR}
export PREBUILT_MODULES_ROOT=${KOKORO_GFILE_DIR}
export PREBUILT_DOCKER_ROOT=${KOKORO_GFILE_DIR}
export FETCH_PBUILDER_DIRECTORY=${KOKORO_GFILE_DIR}
export PACKAGES_FETCH_ROOT_DIRECTORY=${KOKORO_GFILE_DIR}
export PACKAGES_REVISION=.
export ROOTFS_REVISION=.
export FETCH_PACKAGES=false

# Install haveged on the host to provide extra entropy.
sudo apt-get install -y haveged
sudo /etc/init.d/haveged start

m docker-all
m docker-sdcard

pushd ${ROOTDIR}
python3 ${ROOTDIR}/build/create_release_manifest.py \
  -i ${ROOTDIR}/manifest/default.xml \
  -o ${PRODUCT_OUT}/manifest.xml
popd

if [[ -f ${PRODUCT_OUT}/u-boot.imx && \
      -f ${PRODUCT_OUT}/boot.img && \
      -f ${PRODUCT_OUT}/partition-table-8gb.img && \
      -f ${PRODUCT_OUT}/rootfs.img && \
      -f ${PRODUCT_OUT}/sdcard.img && \
      -f ${PRODUCT_OUT}/manifest.xml ]]; then
  cp ${ROOTDIR}/board/flash.sh ${KOKORO_ARTIFACTS_DIR}
  chmod -x ${KOKORO_ARTIFACTS_DIR}/flash.sh
  cp ${PRODUCT_OUT}/u-boot.imx ${KOKORO_ARTIFACTS_DIR}
  cp ${PRODUCT_OUT}/boot.img ${KOKORO_ARTIFACTS_DIR}
  cp ${PRODUCT_OUT}/partition-table-*.img ${KOKORO_ARTIFACTS_DIR}
  cp ${PRODUCT_OUT}/rootfs.img ${KOKORO_ARTIFACTS_DIR}
  cp ${PRODUCT_OUT}/sdcard.img ${KOKORO_ARTIFACTS_DIR}
  cp ${PRODUCT_OUT}/manifest.xml ${KOKORO_ARTIFACTS_DIR}
else
  exit 1
fi
