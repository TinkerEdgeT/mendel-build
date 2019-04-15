#!/bin/bash

set -e
set -x

if [[ ${KOKORO_JOB_NAME} =~ release$ ]]; then
  readonly BUILD_TYPE=release
elif [[ ${KOKORO_JOB_NAME} =~ continuous$ ]]; then
  readonly BUILD_TYPE=continuous
elif [[ ${KOKORO_JOB_NAME} =~ headless$ ]]; then
  readonly BUILD_TYPE=headless
else
  echo "Invalid job name: ${KOKORO_JOB_NAME}" && exit 1
fi

# Symlink the Makefile, like it would be if repo checked this out.
# Otherwise, sourcing setup.sh doesn't work as expected.
ln -sfr git/build/Makefile git/continuous-build/Makefile

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

case "${BUILD_TYPE}" in
  headless)
    export HEADLESS_BUILD=true
    ;;
esac

ARCHES="arm64"

for arch in ${ARCHES}
do
  export USERSPACE_ARCH=${arch}
  m docker-all
  m docker-sdcard
  unset USERSPACE_ARCH
done

m docker-recovery

pushd ${ROOTDIR}
python3 ${ROOTDIR}/build/create_release_manifest.py \
  -i ${ROOTDIR}/manifest/default.xml \
  -o ${PRODUCT_OUT}/manifest.xml
popd

ARTIFACTS+="${ROOTDIR}/board/flash.sh "
ARTIFACTS+="${PRODUCT_OUT}/u-boot.imx "
ARTIFACTS+="${PRODUCT_OUT}/manifest.xml "
ARTIFACTS+="${PRODUCT_OUT}/recovery.img "
ARTIFACTS+="${PRODUCT_OUT}/partition-table-8gb.img "
ARTIFACTS+="${PRODUCT_OUT}/partition-table-16gb.img "
ARTIFACTS+="${PRODUCT_OUT}/partition-table-64gb.img "

for arch in ${ARCHES}
do
  ARTIFACTS+="${PRODUCT_OUT}/boot_${arch}.img "
  ARTIFACTS+="${PRODUCT_OUT}/rootfs_${arch}.img "
  ARTIFACTS+="${PRODUCT_OUT}/sdcard_${arch}.img "
done

# Check existence of artifacts, exit if one is missing
for artifact in ${ARTIFACTS}
do
  if [[ ! -f ${artifact} ]]; then
    echo "${artifact} not found!"
    exit 1
  fi
done

# Copy all artifacts to KOKORO_ARTIFACTS_DIR
for artifact in ${ARTIFACTS}
do
  cp ${artifact} ${KOKORO_ARTIFACTS_DIR}
  chmod -x ${KOKORO_ARTIFACTS_DIR}/$(basename ${artifact})
done
