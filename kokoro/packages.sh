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
export FETCH_PACKAGES=false

# Install haveged on the host to provide extra entropy.
sudo apt-get install -y haveged
sudo /etc/init.d/haveged start

m docker-upstream-delta

cp ${ROOTDIR}/cache/update.tgz ${KOKORO_ARTIFACTS_DIR}/packages.tgz
