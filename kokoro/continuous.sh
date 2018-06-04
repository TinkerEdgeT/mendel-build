#!/bin/bash

set -e

# Symlink the Makefile, like it would be if repo checked this out.
# Otherwise, sourcing setup.sh doesn't work as expected.
ln -sfr git/build/Makefile git/Makefile
source git/continuous-build/build/setup.sh
TARBALL_FETCH_ROOT_DIRECTORY=${KOKORO_GFILE_DIR} m

cp ${PRODUCT_OUT}/u-boot.imx ${KOKORO_ARTIFACTS_DIR}
cp ${PRODUCT_OUT}/boot.img ${KOKORO_ARTIFACTS_DIR}
cp ${PRODUCT_OUT}/partition-table.img ${KOKORO_ARTIFACTS_DIR}
cp ${PRODUCT_OUT}/rootfs.img ${KOKORO_ARTIFACTS_DIR}
