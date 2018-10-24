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

m docker-packages-tarball

cp ${ROOTDIR}/cache/packages.tgz ${KOKORO_ARTIFACTS_DIR}
