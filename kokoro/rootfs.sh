#!/bin/bash

set -e

pushd git/continuous-build
ln -srf build/Makefile .
source build/setup.sh
popd

export IS_EXTERNAL=false
export FETCH_PACKAGES=false
export PREBUILT_DOCKER_ROOT=${KOKORO_GFILE_DIR}

# Install haveged on the host to provide extra entropy.
sudo apt-get install -y haveged
sudo /etc/init.d/haveged start

ARCHES="armhf arm64"

for arch in ${ARCHES}
do
  USERSPACE_ARCH=${arch} m docker-rootfs_raw
done

for arch in ${ARCHES}
do
  ARTIFACTS+="${PRODUCT_OUT}/obj/ROOTFS/rootfs_${arch}.raw.img "
  ARTIFACTS+="${PRODUCT_OUT}/obj/ROOTFS/rootfs_${arch}.raw.img.sha256sum "
done

for artifact in ${ARTIFACTS}
do
  if [[ ! -f ${artifact} ]]; then
    echo "${artifact} not found!"
    exit 1
  fi
done

for artifact in ${ARTIFACTS}
do
  cp ${artifact} ${KOKORO_ARTIFACTS_DIR}
done

# For now, symlink rootfs_arm64 to rootfs.
# Remove when nothing depends on rootfs.img existing.
ln -sf rootfs_arm64.raw.img ${KOKORO_ARTIFACTS_DIR}/rootfs.raw.img
ln -sf rootfs_arm64.raw.img.sha256sum ${KOKORO_ARTIFACTS_DIR}/rootfs.raw.img.sha256sum
