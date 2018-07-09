#!/bin/bash

set -e

pushd git
ln -srf build/Makefile .
source build/setup.sh
popd

export DEBOOTSTRAP_FETCH_TARBALL=false
export ROOTFS_FETCH_TARBALL=false
export PREBUILT_DOCKER_ROOT=$KOKORO_GFILE_DIR

m docker-bootstrap
m docker-rootfs

cp git/cache/debootstrap.tgz $KOKORO_ARTIFACTS_DIR
cp git/cache/debootstrap.tgz.sha256sum $KOKORO_ARTIFACTS_DIR
cp git/out/target/product/imx8m_phanbell/obj/ROOTFS/rootfs.raw.img $KOKORO_ARTIFACTS_DIR
cp git/out/target/product/imx8m_phanbell/obj/ROOTFS/rootfs.raw.img.sha256sum $KOKORO_ARTIFACTS_DIR
