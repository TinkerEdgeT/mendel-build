#!/bin/bash

set -e
set -x

# Run continuous.sh first
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash ${SCRIPT_DIR}/continuous.sh

pushd git/continuous-build
source build/setup.sh
popd

export TARBALL_FETCH_ROOT_DIRECTORY=${KOKORO_GFILE_DIR}
export PREBUILT_MODULES_ROOT=${KOKORO_GFILE_DIR}
export PREBUILT_DOCKER_ROOT=${KOKORO_GFILE_DIR}
export FETCH_PBUILDER_DIRECTORY=${KOKORO_GFILE_DIR}
export PACKAGES_FETCH_ROOT_DIRECTORY=${KOKORO_GFILE_DIR}
export PACKAGES_REVISION=.
export DEBOOTSTRAP_TARBALL_REVISION=.
export ROOTFS_REVISION=.
export FETCH_PACKAGES=false

m docker-make-repo

m sign-repo

# Copy signed repo to artifacts
cp -r ${PRODUCT_OUT}/repo/debian_repo ${KOKORO_ARTIFACTS_DIR}
