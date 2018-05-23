ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

GPU_VERSION := imx-gpu-viv-6.2.4.p0.2-aarch64
GPU_DIR := $(ROOTDIR)/imx-gpu-viv/$(GPU_VERSION)

ROOTFS_DIR := $(PRODUCT_OUT)/obj/ROOTFS/rootfs
ROOTFS_RAW_IMG := $(PRODUCT_OUT)/obj/ROOTFS/rootfs.raw.img

rootfs: $(PRODUCT_OUT)/rootfs.img

gpu:
	sudo rsync -rl $(GPU_DIR)/gpu-core/ $(ROOTFS_DIR)
	sudo rsync -rl $(GPU_DIR)/gpu-demos/ $(ROOTFS_DIR)
	sudo rsync -rl $(GPU_DIR)/gpu-tools/gmem-info/ $(ROOTFS_DIR)
	echo "vivante" | sudo tee -a $(ROOTFS_DIR)/etc/modules

firmware:
	sudo mkdir $(ROOTFS_DIR)/lib/firmware
	sudo rsync -rl $(ROOTDIR)/imx-firmware/ $(ROOTFS_DIR)/lib/firmware

adjustments:
	sudo rm -f $(ROOTFS_DIR)/etc/ssh/ssh_host_*
	sudo rm -f $(ROOTFS_DIR)/var/log/bootstrap.log
	echo "enterprise" | sudo tee $(ROOTFS_DIR)/etc/hostname
	echo "127.0.0.1 enterprise" | sudo tee -a $(ROOTFS_DIR)/etc/hosts
	sudo chroot $(ROOTFS_DIR) mkdir -p /home/enterprise
	sudo chroot $(ROOTFS_DIR) adduser enterprise --home /home/enterprise --shell /bin/bash --disabled-password --gecos ""
	sudo chroot $(ROOTFS_DIR) chown enterprise:enterprise /home/enterprise
	sudo chroot $(ROOTFS_DIR) bash -c "echo 'enterprise:enterprise' | chpasswd"
	echo "nameserver 8.8.8.8" | sudo tee $(ROOTFS_DIR)/etc/resolv.conf
	sudo mount -o bind /proc $(ROOTFS_DIR)/proc
	sudo mount -o bind /sys $(ROOTFS_DIR)/sys
	sudo mount -o bind /dev $(ROOTFS_DIR)/dev
	sudo mount -o bind /dev/pts $(ROOTFS_DIR)/dev/pts

	echo "en_US.UTF-8 UTF-8" | sudo tee -a $(ROOTFS_DIR)/etc/locale.gen
	sudo chroot $(ROOTFS_DIR) locale-gen
	sudo chroot $(ROOTFS_DIR) systemctl enable ssh
	sudo chroot $(ROOTFS_DIR) systemctl enable bluetooth
	sudo chroot $(ROOTFS_DIR) systemctl enable avahi-daemon
	sudo chroot $(ROOTFS_DIR) systemctl enable NetworkManager
	echo "enterprise	ALL=(ALL) ALL" |sudo tee -a $(ROOTFS_DIR)/etc/sudoers

	sudo $(ROOTDIR)/build/fix_permissions.sh -p $(ROOTDIR)/build/permissions.txt -t $(ROOTFS_DIR)
	sudo umount -R $(ROOTFS_DIR)/{dev,proc,sys}

$(ROOTFS_RAW_IMG):
	+make -f $(ROOTDIR)/build/debootstrap.mk validate-bootstrap-tarball

	mkdir -p $(ROOTFS_DIR)
	fallocate -l 12G $(ROOTFS_RAW_IMG)
	mkfs.ext4 -j $(ROOTFS_RAW_IMG)
	tune2fs -o discard $(ROOTFS_RAW_IMG)
	sudo mount -o loop $(ROOTFS_RAW_IMG) $(ROOTFS_DIR)
	sudo qemu-debootstrap \
		--arch=arm64 \
		--keyring /usr/share/keyrings/debian-archive-keyring.gpg \
		--unpack-tarball=$(DEBOOTSTRAP_TARBALL) \
		stretch $(ROOTFS_DIR)

	+make -f $(ROOTDIR)/build/rootfs.mk gpu
	+make -f $(ROOTDIR)/build/rootfs.mk firmware
	+make -f $(ROOTDIR)/build/kernel.mk modules_install
	+make -f $(ROOTDIR)/build/rootfs.mk adjustments

	sudo umount -R $(ROOTFS_DIR)
	sudo rmdir $(ROOTFS_DIR)
	sudo sync $(ROOTFS_RAW_IMG)
	sudo chown ${USER} $(ROOTFS_RAW_IMG)

$(PRODUCT_OUT)/rootfs.img: $(HOST_OUT)/bin/img2simg $(ROOTFS_RAW_IMG)
	$(HOST_OUT)/bin/img2simg $(ROOTFS_RAW_IMG) $(PRODUCT_OUT)/rootfs.img

clean::
	if mount |grep -q $(ROOTFS_DIR); then sudo umount -R $(ROOTFS_DIR); fi
	if [[ -d $(ROOTFS_DIR) ]]; then rmdir $(ROOTFS_DIR); fi
	rm -f $(ROOTFS_RAW_IMG) $(PRODUCT_OUT)/rootfs.img

targets::
	@echo "rootfs - runs debootstrap to build the rootfs tree"

.PHONY:: rootfs gpu firmware adjustments