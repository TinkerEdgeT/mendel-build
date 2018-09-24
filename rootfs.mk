ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

ROOTFS_DIR := $(PRODUCT_OUT)/obj/ROOTFS/rootfs
ROOTFS_RAW_IMG := $(PRODUCT_OUT)/obj/ROOTFS/rootfs.raw.img
ROOTFS_PATCHED_IMG := $(PRODUCT_OUT)/obj/ROOTFS/rootfs.patched.img

ROOTFS_FETCH_TARBALL ?= $(IS_GLINUX)
ROOTFS_REVISION ?= latest

PRE_INSTALL_PACKAGES := \
	aiy-board-audio \
	aiy-board-gadget \
	aiy-board-keyring \
	aiy-board-tools \
	aiy-board-tweaks \
	aiy-board-wlan \
	base-files \
	bluetooth \
	bluez \
	edgetpu-api \
	gstreamer1.0-alsa \
	gstreamer1.0-plugins-bad \
	gstreamer1.0-plugins-base \
	gstreamer1.0-plugins-base-apps \
	gstreamer1.0-plugins-good \
	gstreamer1.0-tools \
	imx-atf \
	imx-firmware \
	imx-gpu-viv \
	imx-gst1.0-plugin \
	imx-mkimage \
	imx-vpu-hantro \
	imx-vpuwrap \
	libbluetooth3 \
	libdrm2 \
	libdrm-vivante \
	libedgetpu \
	libgstreamer1.0-0 \
	libgstreamer-plugins-bad1.0-0 \
	libgstreamer-plugins-base1.0-0 \
	uboot-imx \
	wayland-protocols \
	weston-imx \

rootfs: $(PRODUCT_OUT)/rootfs.img
rootfs_raw: $(ROOTFS_RAW_IMG)

adjustments:
	sudo $(ROOTDIR)/build/fix_permissions.sh -p $(ROOTDIR)/build/permissions.txt -t $(ROOTFS_DIR)

ifeq ($(ROOTFS_FETCH_TARBALL),true)
$(ROOTFS_RAW_IMG): $(TARBALL_FETCH_ROOT_DIRECTORY)/$(ROOTFS_REVISION)/rootfs.raw.img
	mkdir -p $(dir $(ROOTFS_RAW_IMG))
	cp $< $<.sha256sum $(dir $(ROOTFS_RAW_IMG))
else
$(ROOTFS_RAW_IMG): $(ROOTDIR)/build/preamble.mk $(ROOTDIR)/build/rootfs.mk /usr/bin/qemu-aarch64-static
	mkdir -p $(ROOTFS_DIR)
	rm -f $(ROOTFS_RAW_IMG)
	fallocate -l $(ROOTFS_SIZE_MB)M $(ROOTFS_RAW_IMG)
	mkfs.ext4 -F -j $(ROOTFS_RAW_IMG)
	tune2fs -o discard $(ROOTFS_RAW_IMG)
	-sudo umount $(ROOTFS_DIR)/dev
	-sudo umount $(ROOTFS_DIR)
	sudo mount -o loop $(ROOTFS_RAW_IMG) $(ROOTFS_DIR)
	cp $(ROOTDIR)/build/multistrap.conf $(PRODUCT_OUT)
	sed -i -e 's/MAIN_PACKAGES/$(PACKAGES_EXTRA)/g' $(PRODUCT_OUT)/multistrap.conf
	sudo multistrap -f $(PRODUCT_OUT)/multistrap.conf -d $(ROOTFS_DIR)

	sudo mount -o bind /dev $(ROOTFS_DIR)/dev
	sudo cp /usr/bin/qemu-aarch64-static $(ROOTFS_DIR)/usr/bin
	sudo chroot $(ROOTFS_DIR) /var/lib/dpkg/info/dash.preinst install
	sudo DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true LC_ALL=C LANGUAGE=C LANG=C chroot $(ROOTFS_DIR) dpkg --configure -a
	sudo rm -f $(ROOTFS_DIR)/usr/bin/qemu-aarch64-static
	sudo umount $(ROOTFS_DIR)/dev
	sudo umount $(ROOTFS_DIR)
	sudo rmdir $(ROOTFS_DIR)
	sudo sync $(ROOTFS_RAW_IMG)
	sudo chown ${USER} $(ROOTFS_RAW_IMG)
	sha256sum $(ROOTFS_RAW_IMG) > $(ROOTFS_RAW_IMG).sha256sum
endif

$(ROOTFS_PATCHED_IMG): $(ROOTFS_RAW_IMG) \
                       $(ROOTDIR)/board/fstab.emmc \
                       $(ROOTDIR)/build/boot.mk \
                       $(ROOTDIR)/cache/packages.tgz \
                       | $(PRODUCT_OUT)/boot.img
	cp $(ROOTFS_RAW_IMG) $(ROOTFS_PATCHED_IMG).wip
	mkdir -p $(ROOTFS_DIR)
	-sudo umount $(ROOTFS_DIR)/boot
	-sudo umount $(ROOTFS_DIR)
	sudo mount -o loop $(ROOTFS_PATCHED_IMG).wip $(ROOTFS_DIR)
	sudo mount -o loop $(PRODUCT_OUT)/boot.img $(ROOTFS_DIR)/boot
	sudo mount -o bind /dev $(ROOTFS_DIR)/dev

	sudo cp $(ROOTDIR)/board/fstab.emmc $(ROOTFS_DIR)/etc/fstab

	echo 'nameserver 8.8.8.8' | sudo tee $(ROOTFS_DIR)/etc/resolv.conf
	echo 'deb [trusted=yes] file:///opt/aiy/packages ./' | sudo tee $(ROOTFS_DIR)/etc/apt/sources.list.d/local.list
	sudo mkdir -p $(ROOTFS_DIR)/opt/aiy
	sudo tar -xvf $(ROOTDIR)/cache/packages.tgz -C $(ROOTFS_DIR)/opt/aiy/
	sudo chroot $(ROOTFS_DIR) bash -c 'apt-get update'
	sudo chroot $(ROOTFS_DIR) bash -c 'apt-get install aiy-board-keyring'
	sudo chroot $(ROOTFS_DIR) bash -c 'apt-get update'
	sudo chroot $(ROOTFS_DIR) bash -c 'apt-get install --allow-downgrades --no-install-recommends -y $(PRE_INSTALL_PACKAGES)'

	sudo mount -t tmpfs none $(ROOTFS_DIR)/tmp
	sudo cp $(PRODUCT_OUT)/packages/linux-headers-*-aiy_*_arm64.deb \
		$(PRODUCT_OUT)/packages/linux-image-*-aiy_*_arm64.deb $(ROOTFS_DIR)/tmp
	sudo chroot $(ROOTFS_DIR) bash -c 'apt-get install --allow-downgrades --no-install-recommends -y /tmp/*.deb'
	sudo umount $(ROOTFS_DIR)/tmp

	+make -f $(ROOTDIR)/build/rootfs.mk adjustments

	sudo umount $(ROOTFS_DIR)/dev
	sudo umount $(ROOTFS_DIR)/boot
	sudo umount $(ROOTFS_DIR)
	sudo rmdir $(ROOTFS_DIR)
	sudo sync $(ROOTFS_PATCHED_IMG).wip
	sudo chown ${USER} $(ROOTFS_PATCHED_IMG).wip
	mv $(ROOTFS_PATCHED_IMG).wip $(ROOTFS_PATCHED_IMG)

$(PRODUCT_OUT)/rootfs.img: $(HOST_OUT)/bin/img2simg $(ROOTFS_PATCHED_IMG)
	$(HOST_OUT)/bin/img2simg $(ROOTFS_PATCHED_IMG) $(PRODUCT_OUT)/rootfs.img

clean::
	if mount |grep -q $(ROOTFS_DIR); then sudo umount -R $(ROOTFS_DIR); fi
	if [[ -d $(ROOTFS_DIR) ]]; then rmdir $(ROOTFS_DIR); fi
	rm -f $(ROOTFS_PATCHED_IMG) $(ROOTFS_RAW_IMG) $(PRODUCT_OUT)/rootfs.img

targets::
	@echo "rootfs - runs multistrap to build the rootfs tree"

.PHONY:: rootfs rootfs_raw adjustments fetch_debs push_debs
