ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

GPU_VERSION := imx-gpu-viv-6.2.4.p0.2-aarch64
GPU_DIR := $(ROOTDIR)/imx-gpu-viv/$(GPU_VERSION)

ROOTFS_DIR := $(PRODUCT_OUT)/obj/ROOTFS/rootfs
ROOTFS_RAW_IMG := $(PRODUCT_OUT)/obj/ROOTFS/rootfs.raw.img
ROOTFS_PATCHED_IMG := $(PRODUCT_OUT)/obj/ROOTFS/rootfs.patched.img

ROOTFS_FETCH_TARBALL ?= true
ROOTFS_REVISION ?= latest

USER_GROUPS := \
	adm \
	audio \
	bluetooth \
	disk \
	games \
	input \
	plugdev \
	staff \
	sudo \
	users \
	video

rootfs: $(PRODUCT_OUT)/rootfs.img

ifeq ($(ROOTFS_FETCH_TARBALL),true)
rootfs_raw: fetch-rootfs
else
rootfs_raw: build-rootfs
endif

gpu:
	sudo rsync -rl $(GPU_DIR)/gpu-core/ $(ROOTFS_DIR)
	sudo rsync -rl $(GPU_DIR)/gpu-demos/ $(ROOTFS_DIR)
	sudo rsync -rl $(GPU_DIR)/gpu-tools/gmem-info/ $(ROOTFS_DIR)
	echo "vivante" | sudo tee -a $(ROOTFS_DIR)/etc/modules

firmware:
	sudo mkdir -p $(ROOTFS_DIR)/lib/firmware
	sudo rsync -rl $(ROOTDIR)/imx-firmware/ $(ROOTFS_DIR)/lib/firmware

adjustments:
	sudo rm -f $(ROOTFS_DIR)/etc/ssh/ssh_host_*
	sudo rm -f $(ROOTFS_DIR)/var/log/bootstrap.log
	echo "enterprise" | sudo tee $(ROOTFS_DIR)/etc/hostname
	echo "127.0.0.1 enterprise" | sudo tee -a $(ROOTFS_DIR)/etc/hosts
	echo "en_US.UTF-8 UTF-8" | sudo tee -a $(ROOTFS_DIR)/etc/locale.gen
	echo "spidev" | sudo tee -a $(ROOTFS_DIR)/etc/modules
	sudo chroot $(ROOTFS_DIR) locale-gen
	sudo chroot $(ROOTFS_DIR) mkdir -p /home/enterprise
	sudo chroot $(ROOTFS_DIR) adduser enterprise --home /home/enterprise --shell /bin/bash --disabled-password --gecos ""
	for group in $(USER_GROUPS); do \
		sudo chroot $(ROOTFS_DIR) adduser enterprise $$group; \
	done
	sudo chroot $(ROOTFS_DIR) chown enterprise:enterprise /home/enterprise
	sudo chroot $(ROOTFS_DIR) bash -c "echo 'enterprise:enterprise' | chpasswd"
	echo "nameserver 8.8.8.8" | sudo tee $(ROOTFS_DIR)/etc/resolv.conf

	sudo chroot $(ROOTFS_DIR) systemctl enable ssh
	sudo chroot $(ROOTFS_DIR) systemctl enable bluetooth
	sudo chroot $(ROOTFS_DIR) systemctl enable avahi-daemon
	sudo chroot $(ROOTFS_DIR) systemctl enable NetworkManager
	echo "enterprise	ALL=(ALL) ALL" |sudo tee -a $(ROOTFS_DIR)/etc/sudoers

	sudo $(ROOTDIR)/build/fix_permissions.sh -p $(ROOTDIR)/build/permissions.txt -t $(ROOTFS_DIR)

build-rootfs: $(ROOTFS_RAW_IMG)

$(ROOTFS_RAW_IMG): $(ROOTDIR)/build/debootstrap.mk $(ROOTDIR)/build/preamble.mk $(ROOTDIR)/build/rootfs.mk $(DEBOOTSTRAP_TARBALL)
	+make -f $(ROOTDIR)/build/debootstrap.mk validate-bootstrap-tarball
	mkdir -p $(ROOTFS_DIR)
	rm -f $(ROOTFS_RAW_IMG)
	fallocate -l 2G $(ROOTFS_RAW_IMG)
	mkfs.ext4 -F -j $(ROOTFS_RAW_IMG)
	tune2fs -o discard $(ROOTFS_RAW_IMG)
	-sudo umount $(ROOTFS_DIR)
	sudo mount -o loop $(ROOTFS_RAW_IMG) $(ROOTFS_DIR)
	sudo qemu-debootstrap \
		$(DEBOOTSTRAP_ARGS) \
		--unpack-tarball=$(DEBOOTSTRAP_TARBALL) \
		stretch $(ROOTFS_DIR)
	sudo umount $(ROOTFS_DIR)
	sudo rmdir $(ROOTFS_DIR)
	sudo sync $(ROOTFS_RAW_IMG)
	sudo chown ${USER} $(ROOTFS_RAW_IMG)
	sha256sum $(ROOTFS_RAW_IMG) > $(ROOTFS_RAW_IMG).sha256sum

ifeq ($(ROOTFS_FETCH_TARBALL),true)
$(ROOTFS_PATCHED_IMG): fetch-rootfs
else
$(ROOTFS_PATCHED_IMG): $(ROOTFS_RAW_IMG)
endif
	cp -r $(ROOTFS_RAW_IMG) $(ROOTFS_PATCHED_IMG)
	mkdir -p $(ROOTFS_DIR)
	-sudo umount $(ROOTFS_DIR)
	sudo mount -o loop $(ROOTFS_PATCHED_IMG) $(ROOTFS_DIR)

	+make -f $(ROOTDIR)/build/rootfs.mk gpu
	+make -f $(ROOTDIR)/build/rootfs.mk firmware
	+make -f $(ROOTDIR)/build/kernel.mk modules_install
	+make -f $(ROOTDIR)/build/rootfs.mk adjustments

	sudo umount $(ROOTFS_DIR)
	sudo rmdir $(ROOTFS_DIR)
	sudo sync $(ROOTFS_PATCHED_IMG)
	sudo chown ${USER} $(ROOTFS_PATCHED_IMG)

$(PRODUCT_OUT)/rootfs.img: $(HOST_OUT)/bin/img2simg $(ROOTFS_PATCHED_IMG)
	$(HOST_OUT)/bin/img2simg $(ROOTFS_PATCHED_IMG) $(PRODUCT_OUT)/rootfs.img

fetch-rootfs: $(TARBALL_FETCH_ROOT_DIRECTORY)/$(ROOTFS_REVISION)/rootfs.raw.img
	mkdir -p $(dir $(ROOTFS_RAW_IMG))
	cp $< $<.sha256sum $(dir $(ROOTFS_RAW_IMG))

clean::
	if mount |grep -q $(ROOTFS_DIR); then sudo umount -R $(ROOTFS_DIR); fi
	if [[ -d $(ROOTFS_DIR) ]]; then rmdir $(ROOTFS_DIR); fi
	rm -f $(ROOTFS_PATCHED_IMG) $(ROOTFS_RAW_IMG) $(PRODUCT_OUT)/rootfs.img

targets::
	@echo "rootfs - runs debootstrap to build the rootfs tree"

.PHONY:: rootfs rootfs_raw gpu firmware adjustments
