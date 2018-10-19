#!/bin/bash

set -e

pushd git/continuous-build
ln -srf build/Makefile .
source build/setup.sh
popd

export IS_GLINUX=true
export ROOTFS_FETCH_TARBALL=false
export FETCH_PACKAGES=false
export PREBUILT_DOCKER_ROOT=$KOKORO_GFILE_DIR

# Install haveged on the host to provide extra entropy.
sudo apt-get install -y haveged
sudo /etc/init.d/haveged start

m docker-rootfs_raw

cp ${PRODUCT_OUT}/obj/ROOTFS/rootfs.raw.img $KOKORO_ARTIFACTS_DIR
cp ${PRODUCT_OUT}/obj/ROOTFS/rootfs.raw.img.sha256sum $KOKORO_ARTIFACTS_DIR
