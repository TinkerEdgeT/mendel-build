#!/bin/bash

set -e

pushd git
ln -srf build/Makefile .
source build/setup.sh
popd

m prereqs
mm debootstrap make-bootstrap-tarball
mm rootfs rootfs_raw || true
sudo umount git/out/target/product/imx8m_phanbell/obj/ROOTFS/rootfs || true

cp git/cache/debootstrap.tgz $KOKORO_ARTIFACTS_DIR
cp git/cache/debootstrap.tgz.sha256sum $KOKORO_ARTIFACTS_DIR
cp git/out/target/product/imx8m_phanbell/obj/ROOTFS/rootfs.raw.img $KOKORO_ARTIFACTS_DIR
# cp git/out/target/product/imx8m_phanbell/obj/ROOTFS/rootfs.raw.img.sha256sum $KOKORO_ARTIFACTS_DIR
