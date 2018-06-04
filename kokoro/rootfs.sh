#!/bin/bash

set -e

pushd git
ln -srf build/Makefile .
source build/setup.sh
popd

# Debootstrap on 14.04 is very old and buggy. Update to the 16.04 version.
echo "deb http://archive.ubuntu.com/ubuntu xenial main restricted universe multiverse" | sudo tee -a /etc/apt/sources.list
sudo apt-get update
sudo apt-get install debootstrap/xenial

export DEBOOTSTRAP_FETCH_TARBALL=false
export ROOTFS_FETCH_TARBALL=false

m prereqs
mm debootstrap make-bootstrap-tarball
mm rootfs rootfs_raw

cp git/cache/debootstrap.tgz $KOKORO_ARTIFACTS_DIR
cp git/cache/debootstrap.tgz.sha256sum $KOKORO_ARTIFACTS_DIR
cp git/out/target/product/imx8m_phanbell/obj/ROOTFS/rootfs.raw.img $KOKORO_ARTIFACTS_DIR
cp git/out/target/product/imx8m_phanbell/obj/ROOTFS/rootfs.raw.img.sha256sum $KOKORO_ARTIFACTS_DIR
