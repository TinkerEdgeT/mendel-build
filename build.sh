#!/bin/bash

if [ $VERSION_NUMBER ]; then
	VERSION_NUMBER="$VERSION_NUMBER"-"$(date  +%Y%m%d)"
	RELEASE_NAME=Tinker_Edge_T-Mendel-Eagle-V"$VERSION_NUMBER"
fi
echo "VERSION_NUMBER: $VERSION_NUMBER"

CMD=`realpath $0`
COMMON_DIR=`dirname $CMD`
TOP_DIR=$(realpath $COMMON_DIR/..)

source build/setup.sh
m
m docker-sdcard
m docker-recovery

if [ "$VERSION_NUMBER" ]; then
	IMAGE_PATH=$TOP_DIR/out/target/product/imx8m_phanbell
	STUB_PATH=IMAGE/"$RELEASE_NAME"
	export STUB_PATH=$TOP_DIR/$STUB_PATH
	mkdir -p $STUB_PATH/$RELEASE_NAME
	cp -rp $TOP_DIR/board/flash/. $STUB_PATH/$RELEASE_NAME
	cp $TOP_DIR/board/flash_uboot_and_force_fastboot_mode.cmd $STUB_PATH/.
        cd $IMAGE_PATH
	cp boot_arm64.img partition-table-16gb.img partition-table-64gb.img partition-table-8gb.img home.img recovery.img rootfs_arm64.img u-boot.imx sdcard_arm64.img  $STUB_PATH/$RELEASE_NAME
	cd -
	cd $STUB_PATH
	zip -r $RELEASE_NAME.zip $RELEASE_NAME
	sha256sum $RELEASE_NAME.zip > $RELEASE_NAME.zip.sha256sum
	rm -rf $RELEASE_NAME
	cd -
fi
