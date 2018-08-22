ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

ROOTFS_DIR := $(PRODUCT_OUT)/obj/ROOTFS/rootfs
ROOTFS_RAW_IMG := $(PRODUCT_OUT)/obj/ROOTFS/rootfs.raw.img
ROOTFS_PATCHED_IMG := $(PRODUCT_OUT)/obj/ROOTFS/rootfs.patched.img

ROOTFS_FETCH_TARBALL ?= true
ROOTFS_REVISION ?= latest

ROOTFS_PUSH_DEBS ?= false

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
rootfs_raw: $(ROOTFS_RAW_IMG)

firmware:
	sudo mkdir -p $(ROOTFS_DIR)/lib/firmware
	sudo rsync -rl $(ROOTDIR)/imx-firmware/ $(ROOTFS_DIR)/lib/firmware

adjustments:
	sudo rm -f $(ROOTFS_DIR)/etc/ssh/ssh_host_*
	sudo rm -f $(ROOTFS_DIR)/var/log/bootstrap.log
	echo "aiy" | sudo tee $(ROOTFS_DIR)/etc/hostname
	echo "127.0.0.1 aiy" | sudo tee -a $(ROOTFS_DIR)/etc/hosts
	echo "en_US.UTF-8 UTF-8" | sudo tee -a $(ROOTFS_DIR)/etc/locale.gen
	echo "spidev" | sudo tee -a $(ROOTFS_DIR)/etc/modules
	sudo chroot $(ROOTFS_DIR) locale-gen
	sudo chroot $(ROOTFS_DIR) mkdir -p /home/aiy
	sudo chroot $(ROOTFS_DIR) adduser aiy --home /home/aiy --shell /bin/bash --disabled-password --gecos ""
	for group in $(USER_GROUPS); do \
		sudo chroot $(ROOTFS_DIR) adduser aiy $$group; \
	done
	sudo chroot $(ROOTFS_DIR) chown aiy:aiy /home/aiy
	sudo chroot $(ROOTFS_DIR) bash -c "echo 'aiy:aiy' | chpasswd"
	echo "nameserver 8.8.8.8" | sudo tee $(ROOTFS_DIR)/etc/resolv.conf

	sudo chroot $(ROOTFS_DIR) systemctl enable ssh
	sudo chroot $(ROOTFS_DIR) systemctl enable bluetooth
	sudo chroot $(ROOTFS_DIR) systemctl enable avahi-daemon
	sudo chroot $(ROOTFS_DIR) systemctl enable NetworkManager
	echo "aiy	ALL=(ALL) ALL" |sudo tee -a $(ROOTFS_DIR)/etc/sudoers

	sudo $(ROOTDIR)/build/fix_permissions.sh -p $(ROOTDIR)/build/permissions.txt -t $(ROOTFS_DIR)

ifeq ($(ROOTFS_FETCH_TARBALL),true)
$(ROOTFS_RAW_IMG): $(TARBALL_FETCH_ROOT_DIRECTORY)/$(ROOTFS_REVISION)/rootfs.raw.img
	mkdir -p $(dir $(ROOTFS_RAW_IMG))
	cp $< $<.sha256sum $(dir $(ROOTFS_RAW_IMG))
else
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
endif

$(ROOTFS_PATCHED_IMG): $(ROOTFS_RAW_IMG) \
                       $(ROOTDIR)/board/fstab.emmc \
                       $(ROOTDIR)/build/boot.mk \
                       $(PRODUCT_OUT)/linux-image-4.9.51-aiy_1_arm64.deb \
                       $(PRODUCT_OUT)/wayland-protocols-imx_1.13-0_all.deb \
                       $(PRODUCT_OUT)/weston-imx_3.0.0-0_arm64.deb \
                       | $(PRODUCT_OUT)/boot.img \
                         modules \
                         packages \
                         gst-packages
	cp -r $(ROOTFS_RAW_IMG) $(ROOTFS_PATCHED_IMG)
	mkdir -p $(ROOTFS_DIR)
	-sudo umount $(ROOTFS_DIR)/boot
	-sudo umount $(ROOTFS_DIR)
	sudo mount -o loop $(ROOTFS_PATCHED_IMG) $(ROOTFS_DIR)
	sudo mount -o loop $(PRODUCT_OUT)/boot.img $(ROOTFS_DIR)/boot

	+make -f $(ROOTDIR)/build/rootfs.mk firmware
	+make -f $(ROOTDIR)/build/rootfs.mk adjustments

	sudo cp $(ROOTDIR)/board/fstab.emmc $(ROOTFS_DIR)/etc/fstab

	sudo mount -t tmpfs none $(ROOTFS_DIR)/tmp
	sudo cp $(PRODUCT_OUT)/*.deb $(ROOTFS_DIR)/tmp/
	sudo chroot $(ROOTFS_DIR) bash -c 'apt-get install --allow-downgrades --no-install-recommends -y /tmp/*.deb'
	sudo umount $(ROOTFS_DIR)/tmp

	sudo umount $(ROOTFS_DIR)/boot
	sudo umount $(ROOTFS_DIR)
	sudo rmdir $(ROOTFS_DIR)
	sudo sync $(ROOTFS_PATCHED_IMG)
	sudo chown ${USER} $(ROOTFS_PATCHED_IMG)

$(PRODUCT_OUT)/rootfs.img: $(HOST_OUT)/bin/img2simg $(ROOTFS_PATCHED_IMG)
	$(HOST_OUT)/bin/img2simg $(ROOTFS_PATCHED_IMG) $(PRODUCT_OUT)/rootfs.img

fetch_debs:
	$(info Fetching debs from cache...)
	mkdir -p $(PRODUCT_OUT)
	rsync -rv $(DEBCACHE_ROOT)/ $(PRODUCT_OUT)/
	find $(PRODUCT_OUT) -name *.deb | xargs touch -d "-1337 days ago"

ifeq ($(ROOTFS_PUSH_DEBS),true)
push_debs:
	$(info Pushing debs to cache...)
	rsync -rvm --exclude="aiy*.deb" --include="*.deb" --include="*/" --exclude="*"  $(PRODUCT_OUT)/ $(DEBCACHE_ROOT)/
else
push_debs:
	$(error Pushing debs to cache disabled)
endif

clean::
	if mount |grep -q $(ROOTFS_DIR); then sudo umount -R $(ROOTFS_DIR); fi
	if [[ -d $(ROOTFS_DIR) ]]; then rmdir $(ROOTFS_DIR); fi
	rm -f $(ROOTFS_PATCHED_IMG) $(ROOTFS_RAW_IMG) $(PRODUCT_OUT)/rootfs.img

targets::
	@echo "rootfs - runs debootstrap to build the rootfs tree"

.PHONY:: rootfs rootfs_raw gpu firmware adjustments fetch_debs push_debs
