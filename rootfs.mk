ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

ARM64_BUILDER_FETCH_TARBALL ?= true
PREBUILT_DOCKER_ROOT ?= /google/data/ro/teams/spacepark/enterprise/kokoro/prod/spacepark/enterprise/docker

GPU_VERSION := imx-gpu-viv-6.2.4.p1.0-aarch64
GPU_DIR := $(ROOTDIR)/imx-gpu-viv/$(GPU_VERSION)
GPU_OUT_DIR := $(PRODUCT_OUT)/obj/GPU

WAYLAND_PROTO_DIR := $(PRODUCT_OUT)/obj/WAYLAND_PROTO
WESTON_DIR := $(PRODUCT_OUT)/obj/WESTON

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
rootfs_raw: $(ROOTFS_RAW_IMG)

$(PRODUCT_OUT)/wayland-protocols-imx_1.13-0_all.deb:
	mkdir -p $(WAYLAND_PROTO_DIR)/wayland-protocols-imx-1.13
	cp -r $(ROOTDIR)/wayland-protocols-imx/* $(WAYLAND_PROTO_DIR)/wayland-protocols-imx-1.13
	tar -C $(WAYLAND_PROTO_DIR) -cJf $(WAYLAND_PROTO_DIR)/wayland-protocols-imx_1.13.orig.tar.xz wayland-protocols-imx-1.13
	cp -r $(ROOTDIR)/build/wayland-protocols-imx-debian $(WAYLAND_PROTO_DIR)/wayland-protocols-imx-1.13/debian
	cd $(WAYLAND_PROTO_DIR)/wayland-protocols-imx-1.13; dpkg-buildpackage -uc -us -tc
	mv $(WAYLAND_PROTO_DIR)/wayland-protocols-imx_1.13-0_all.deb $(PRODUCT_OUT)

ifeq ($(ARM64_BUILDER_FETCH_TARBALL),true)
$(ROOTDIR)/cache/arm64-builder.tar: $(PREBUILT_DOCKER_ROOT)/arm64-builder.tar
	mkdir -p $(ROOTDIR)/cache
	cp $< $(ROOTDIR)/cache
else
$(ROOTDIR)/cache/arm64-builder.tar:
	mkdir -p $(ROOTDIR)/cache
	mkdir -p $(PRODUCT_OUT)/obj/ARM64_BUILDER
	cp $(ROOTDIR)/build/Dockerfile.arm64 $(PRODUCT_OUT)/obj/ARM64_BUILDER/Dockerfile
	cp $(shell which qemu-aarch64-static) $(PRODUCT_OUT)/obj/ARM64_BUILDER
	docker build -t arm64-builder $(PRODUCT_OUT)/obj/ARM64_BUILDER
	docker image save -o $@ arm64-builder:latest
	docker rmi arm64-builder:latest
endif

weston: $(PRODUCT_OUT)/weston-imx_3.0.0-0_arm64.deb
$(PRODUCT_OUT)/weston-imx_3.0.0-0_arm64.deb: $(ROOTDIR)/cache/arm64-builder.tar $(PRODUCT_OUT)/wayland-protocols-imx_1.13-0_all.deb
	mkdir -p $(WESTON_DIR)/weston-imx-3.0.0
	cp -r $(ROOTDIR)/weston-imx/* $(WESTON_DIR)/weston-imx-3.0.0
	mkdir -p $(WESTON_DIR)/weston-imx-3.0.0/etc/systemd/system
	cp $(ROOTDIR)/build/weston.service $(WESTON_DIR)/weston-imx-3.0.0/etc/systemd/system
	tar -C $(WESTON_DIR) -cJf $(WESTON_DIR)/weston-imx_3.0.0.orig.tar.xz weston-imx-3.0.0
	cp -r $(ROOTDIR)/build/weston-imx-debian $(WESTON_DIR)/weston-imx-3.0.0/debian
	docker load -i $(ROOTDIR)/cache/arm64-builder.tar
	docker run --rm --privileged --tty \
	  -v $(PRODUCT_OUT):/out \
	  -v $(WESTON_DIR):/weston arm64-builder \
	  /bin/bash -c 'dpkg -i /out/wayland-protocols-imx_1.13-0_all.deb; \
		cd /weston/weston-imx-3.0.0; dpkg-buildpackage -uc -us -tc'
	mv $(WESTON_DIR)/weston-imx_3.0.0-0_arm64.deb $(PRODUCT_OUT)

$(PRODUCT_OUT)/imx-gpu-viv_6.2.4_arm64.deb:
	mkdir -p $(GPU_OUT_DIR)
	mkdir -p $(GPU_OUT_DIR)/usr
	mkdir -p $(GPU_OUT_DIR)/usr/bin
	mkdir -p $(GPU_OUT_DIR)/usr/lib
	mkdir -p $(GPU_OUT_DIR)/usr/lib/dri
	mkdir -p $(GPU_OUT_DIR)/usr/lib/pkgconfig
	mkdir -p $(GPU_OUT_DIR)/usr/lib/vulkan
	mkdir -p $(GPU_OUT_DIR)/usr/include

	cp -P $(GPU_DIR)/gpu-core/usr/lib/*.so* $(GPU_OUT_DIR)/usr/lib/
	cp -r $(GPU_DIR)/gpu-core/usr/include/* $(GPU_OUT_DIR)/usr/include/
	cp -r $(GPU_DIR)/gpu-demos/opt $(GPU_OUT_DIR)
	cp -r $(GPU_DIR)/gpu-tools/gmem-info/usr/bin/* $(GPU_OUT_DIR)/usr/bin

	cp $(GPU_DIR)/gpu-core/usr/lib/pkgconfig/egl_wayland.pc $(GPU_OUT_DIR)/usr/lib/pkgconfig/egl.pc
	cp $(GPU_DIR)/gpu-core/usr/lib/pkgconfig/glesv1_cm.pc $(GPU_OUT_DIR)/usr/lib/pkgconfig
	cp $(GPU_DIR)/gpu-core/usr/lib/pkgconfig/glesv2.pc $(GPU_OUT_DIR)/usr/lib/pkgconfig
	cp $(GPU_DIR)/gpu-core/usr/lib/pkgconfig/vg.pc $(GPU_OUT_DIR)/usr/lib/pkgconfig
	cp $(GPU_DIR)/gpu-core/usr/lib/pkgconfig/wayland-egl.pc $(GPU_OUT_DIR)/usr/lib/pkgconfig
	cp $(GPU_DIR)/gpu-core/usr/lib/pkgconfig/gbm.pc $(GPU_OUT_DIR)/usr/lib/pkgconfig

	cp -r $(GPU_DIR)/gpu-core/usr/lib/dri $(GPU_OUT_DIR)/usr/lib

	mv $(GPU_OUT_DIR)/usr/lib/libGL.so.1.2 $(GPU_OUT_DIR)/usr/lib/libGL.so.1.2.0
	ln -sf libGL.so.1.2.0 $(GPU_OUT_DIR)/usr/lib/libGL.so.1.2
	ln -sf libGL.so.1.2 $(GPU_OUT_DIR)/usr/lib/libGL.so.1
	ln -sf libGL.so.1 $(GPU_OUT_DIR)/usr/lib/libGL.so

	mv $(GPU_OUT_DIR)/usr/lib/libEGL-wl.so $(GPU_OUT_DIR)/usr/lib/libEGL.so.1.0
	ln -sf libEGL.so.1.0 $(GPU_OUT_DIR)/usr/lib/libEGL.so.1
	ln -sf libEGL.so.1 $(GPU_OUT_DIR)/usr/lib/libEGL.so

	mv $(GPU_OUT_DIR)/usr/lib/libGAL-wl.so $(GPU_OUT_DIR)/usr/lib/libGAL.so
	mv $(GPU_OUT_DIR)/usr/lib/libVDK-wl.so $(GPU_OUT_DIR)/usr/lib/libVDK.so

	rm -rf $(GPU_OUT_DIR)/usr/lib/libGLESv2*
	cp $(GPU_DIR)/gpu-core/usr/lib/libGLESv2-wl.so $(GPU_OUT_DIR)/usr/lib/libGLESv2.so.2.0.0
	ln -sf libGLESv2.so.2.0.0 $(GPU_OUT_DIR)/usr/lib/libGLESv2.so.2.0
	ln -sf libGLESv2.so.2.0 $(GPU_OUT_DIR)/usr/lib/libGLESv2.so.2
	ln -sf libGLESv2.so.2 $(GPU_OUT_DIR)/usr/lib/libGLESv2.so

	mv $(GPU_OUT_DIR)/usr/lib/libvulkan-wl.so $(GPU_OUT_DIR)/usr/lib/vulkan/libvulkan_VSI.so

	rm -rf $(GPU_OUT_DIR)/usr/lib/*-wl.so
	rm -rf $(GPU_OUT_DIR)/usr/lib/*-fb.so
	rm -rf $(GPU_OUT_DIR)/usr/lib/*-x11.so

	rm -f $(GPU_OUT_DIR)/usr/lib/libOpenVG.so
	ln -sf libOpenVG.3d.so $(GPU_OUT_DIR)/usr/lib/libOpenVG.so

	cp -r $(ROOTDIR)/imx-gpu-viv/debian $(GPU_OUT_DIR)
	cd $(GPU_OUT_DIR); dpkg-buildpackage -aarm64 -b -rfakeroot -us -uc -tc

	mv $(GPU_OUT_DIR)/../imx-gpu-viv_6.2.4_arm64.deb $(PRODUCT_OUT)

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
                       $(ROOTDIR)/build/boot.mk \
                       $(PRODUCT_OUT)/linux-image-4.9.51-aiy_1_arm64.deb \
                       $(PRODUCT_OUT)/wayland-protocols-imx_1.13-0_all.deb \
                       $(PRODUCT_OUT)/weston-imx_3.0.0-0_arm64.deb \
                       $(PRODUCT_OUT)/imx-gpu-viv_6.2.4_arm64.deb \
                       | $(PRODUCT_OUT)/boot.img \
                         modules \
                         packages
	cp -r $(ROOTFS_RAW_IMG) $(ROOTFS_PATCHED_IMG)
	mkdir -p $(ROOTFS_DIR)
	-sudo umount $(ROOTFS_DIR)/boot
	-sudo umount $(ROOTFS_DIR)
	sudo mount -o loop $(ROOTFS_PATCHED_IMG) $(ROOTFS_DIR)
	sudo mount -o loop $(PRODUCT_OUT)/boot.img $(ROOTFS_DIR)/boot

	+make -f $(ROOTDIR)/build/rootfs.mk firmware
	+make -f $(ROOTDIR)/build/rootfs.mk adjustments

	sudo cp $(PRODUCT_OUT)/*.deb $(ROOTFS_DIR)/root/
	sudo cp $(ROOTDIR)/build/fstab.emmc $(ROOTFS_DIR)/etc/fstab
	sudo chroot $(ROOTFS_DIR) bash -c 'apt-get install --no-install-recommends -y /root/*.deb'
	sudo rm -rf $(ROOTFS_DIR)/root/*.deb

	sudo umount $(ROOTFS_DIR)/boot
	sudo umount $(ROOTFS_DIR)
	sudo rmdir $(ROOTFS_DIR)
	sudo sync $(ROOTFS_PATCHED_IMG)
	sudo chown ${USER} $(ROOTFS_PATCHED_IMG)

$(PRODUCT_OUT)/rootfs.img: $(HOST_OUT)/bin/img2simg $(ROOTFS_PATCHED_IMG)
	$(HOST_OUT)/bin/img2simg $(ROOTFS_PATCHED_IMG) $(PRODUCT_OUT)/rootfs.img

clean::
	if mount |grep -q $(ROOTFS_DIR); then sudo umount -R $(ROOTFS_DIR); fi
	if [[ -d $(ROOTFS_DIR) ]]; then rmdir $(ROOTFS_DIR); fi
	rm -f $(ROOTFS_PATCHED_IMG) $(ROOTFS_RAW_IMG) $(PRODUCT_OUT)/rootfs.img

targets::
	@echo "rootfs - runs debootstrap to build the rootfs tree"

.PHONY:: rootfs rootfs_raw gpu firmware adjustments
