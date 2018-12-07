# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

ROOTFS_DIR := $(PRODUCT_OUT)/obj/ROOTFS/rootfs
ROOTFS_IMG := $(PRODUCT_OUT)/rootfs_$(USERSPACE_ARCH).img
ROOTFS_RAW_IMG := $(PRODUCT_OUT)/obj/ROOTFS/rootfs_$(USERSPACE_ARCH).raw.img
ROOTFS_PATCHED_IMG := $(PRODUCT_OUT)/obj/ROOTFS/rootfs_$(USERSPACE_ARCH).patched.img
ROOTFS_RAW_LOCAL_CACHE_PATH := $(ROOTDIR)/cache/rootfs_$(USERSPACE).raw.img

BASE_PACKAGES := \
	aiy-board-gadget \
	aiy-board-keyring \
	aiy-board-tweaks \
	base-files \
	bluetooth \
	bluez \
	libbluetooth3 \
	mendel-distro-info-data

GUI_PACKAGES := \
	gstreamer1.0-alsa \
	gstreamer1.0-plugins-bad \
	gstreamer1.0-plugins-base \
	gstreamer1.0-plugins-base-apps \
	gstreamer1.0-plugins-good \
	gstreamer1.0-tools \
	libdrm2 \
	libgstreamer1.0-0 \
	libgstreamer-plugins-bad1.0-0 \
	libgstreamer-plugins-base1.0-0

include $(ROOTDIR)/board/rootfs.mk

ifeq ($(HEADLESS_BUILD),)
    $(info )
    $(info *** GUI build selected -- set HEADLESS_BUILD=true if this is not what you intend.)
	PRE_INSTALL_PACKAGES := $(BASE_PACKAGES) $(BSP_BASE_PACKAGES) $(GUI_PACKAGES) $(BSP_GUI_PACKAGES)
else
    $(info )
    $(info *** Headless build selected -- unset HEADLESS_BUILD if this is not what you intend.)
	PRE_INSTALL_PACKAGES := $(BASE_PACKAGES) $(BSP_BASE_PACKAGES)
endif

ifeq ($(FETCH_PACKAGES),true)
    $(info *** Using prebuilt packages, set FETCH_PACKAGES=false to build locally)
else
    $(info *** Building packages locally, set FETCH_PACKAGES=true to use prebuilts)
endif

$(ROOTFS_DIR):
	mkdir -p $(ROOTFS_DIR)

rootfs: $(ROOTFS_IMG)
	$(LOG) rootfs finished

rootfs_raw: $(ROOTFS_RAW_IMG)

adjustments:
	$(LOG) rootfs adjustments
	sudo $(ROOTDIR)/build/fix_permissions.sh -p $(ROOTDIR)/build/permissions.txt -t $(ROOTFS_DIR)

ifneq ($(ROOTFS_RAW_CACHE_DIRECTORY),)
$(ROOTFS_RAW_IMG): $(ROOTFS_RAW_CACHE_DIRECTORY)/rootfs_$(USERSPACE_ARCH).raw.img
	$(LOG) rootfs raw-fetch
	mkdir -p $(dir $(ROOTFS_RAW_IMG))
	cp $< $<.sha256sum $(dir $(ROOTFS_RAW_IMG))
	$(LOG) rootfs raw-fetch finished
else ifeq ($(shell test -f $(ROOTFS_RAW_LOCAL_CACHE_PATH) && echo found),found)
$(ROOTFS_RAW_IMG): $(ROOTFS_RAW_LOCAL_CACHE_PATH)
	$(LOG) rootfs raw-cache
	mkdir -p $(dir $(ROOTFS_RAW_IMG))
	cp $(ROOTFS_RAW_LOCAL_CACHE_PATH) $(ROOTFS_RAW_IMG)
	sha256sum $(ROOTFS_RAW_IMG) > $(ROOTFS_RAW_IMG).sha256sum
	$(LOG) rootfs raw-cache finished
else
$(ROOTFS_RAW_IMG): $(ROOTDIR)/build/preamble.mk $(ROOTDIR)/build/rootfs.mk /usr/bin/qemu-$(QEMU_ARCH)-static
	$(LOG) rootfs raw-build
	mkdir -p $(ROOTFS_DIR)
	rm -f $(ROOTFS_RAW_IMG)
	fallocate -l $(ROOTFS_SIZE_MB)M $(ROOTFS_RAW_IMG)
	mkfs.ext4 -F -j $(ROOTFS_RAW_IMG)
	tune2fs -o discard $(ROOTFS_RAW_IMG)
	-sudo umount $(ROOTFS_DIR)/dev
	-sudo umount $(ROOTFS_DIR)
	sudo mount -o loop $(ROOTFS_RAW_IMG) $(ROOTFS_DIR)
	cp $(ROOTDIR)/board/multistrap.conf $(PRODUCT_OUT)
	sed -i -e 's/MAIN_PACKAGES/$(PACKAGES_EXTRA)/g' $(PRODUCT_OUT)/multistrap.conf
	sed -i -e 's/USERSPACE_ARCH/$(USERSPACE_ARCH)/g' $(PRODUCT_OUT)/multistrap.conf
	$(LOG) rootfs raw-build multistrap
	sudo multistrap -f $(PRODUCT_OUT)/multistrap.conf -d $(ROOTFS_DIR)
	$(LOG) rootfs raw-build multistrap finished

	sudo mount -o bind /dev $(ROOTFS_DIR)/dev
	sudo cp /usr/bin/qemu-$(QEMU_ARCH)-static $(ROOTFS_DIR)/usr/bin
	sudo chroot $(ROOTFS_DIR) /var/lib/dpkg/info/dash.preinst install

	$(LOG) rootfs raw-build dpkg-configure
	sudo DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true LC_ALL=C LANGUAGE=C LANG=C chroot $(ROOTFS_DIR) dpkg --configure -a
	$(LOG) rootfs raw-build dpkg-configure finished

	sudo rm -f $(ROOTFS_DIR)/usr/bin/qemu-$(QEMU_ARCH)-static
	sudo umount $(ROOTFS_DIR)/dev
	sudo umount $(ROOTFS_DIR)
	sudo rmdir $(ROOTFS_DIR)
	sudo sync $(ROOTFS_RAW_IMG)
	sudo chown ${USER} $(ROOTFS_RAW_IMG)
	sha256sum $(ROOTFS_RAW_IMG) > $(ROOTFS_RAW_IMG).sha256sum
	$(LOG) rootfs raw-build finished
endif

ROOTFS_PATCHED_DEPS := $(ROOTFS_RAW_IMG) \
                       $(ROOTDIR)/board/fstab.emmc \
                       $(ROOTDIR)/build/boot.mk

ifeq ($(FETCH_PACKAGES),false)
    ROOTFS_PATCHED_DEPS += $(ROOTDIR)/cache/packages.tgz
endif

$(ROOTFS_PATCHED_IMG): $(ROOTFS_PATCHED_DEPS) \
                       | $(PRODUCT_OUT)/boot_$(USERSPACE_ARCH).img \
                         /usr/bin/qemu-$(QEMU_ARCH)-static \
                         $(ROOTFS_DIR)
	$(LOG) rootfs patch
	cp $(ROOTFS_RAW_IMG) $(ROOTFS_PATCHED_IMG).wip
	mkdir -p $(ROOTFS_DIR)
	-sudo umount $(ROOTFS_DIR)/boot
	-sudo umount $(ROOTFS_DIR)
	sudo mount -o loop $(ROOTFS_PATCHED_IMG).wip $(ROOTFS_DIR)
	-sudo mkdir -p $(ROOTFS_DIR)/boot
	sudo mount -o loop $(PRODUCT_OUT)/boot_$(USERSPACE_ARCH).img $(ROOTFS_DIR)/boot
	-sudo mkdir -p $(ROOTFS_DIR)/dev
	sudo mount -o bind /dev $(ROOTFS_DIR)/dev
	sudo cp /usr/bin/qemu-$(QEMU_ARCH)-static $(ROOTFS_DIR)/usr/bin

	sudo cp $(ROOTDIR)/board/fstab.emmc $(ROOTFS_DIR)/etc/fstab

	$(LOG) rootfs patch keyring
	echo 'nameserver 8.8.8.8' | sudo tee $(ROOTFS_DIR)/etc/resolv.conf
ifeq ($(FETCH_PACKAGES),false)
	echo 'deb [trusted=yes] file:///opt/aiy/packages ./' | sudo tee $(ROOTFS_DIR)/etc/apt/sources.list.d/local.list
	sudo mkdir -p $(ROOTFS_DIR)/opt/aiy
	sudo tar -xvf $(ROOTDIR)/cache/packages.tgz -C $(ROOTFS_DIR)/opt/aiy/
endif
	sudo cp $(ROOTDIR)/build/99network-settings $(ROOTFS_DIR)/etc/apt/apt.conf.d/
	sudo chroot $(ROOTFS_DIR) bash -c 'apt-get update'
	sudo chroot $(ROOTFS_DIR) bash -c 'apt-get install -y --allow-unauthenticated aiy-board-keyring'
	sudo chroot $(ROOTFS_DIR) bash -c 'apt-get update'
	$(LOG) rootfs patch keyring finished

	$(LOG) rootfs patch bsp
	sudo chroot $(ROOTFS_DIR) bash -c 'apt-get install --allow-downgrades --no-install-recommends -y $(PRE_INSTALL_PACKAGES)'
	$(LOG) rootfs patch bsp finished

	+make -f $(ROOTDIR)/build/rootfs.mk adjustments

	sudo rm -f $(ROOTFS_DIR)/usr/bin/qemu-$(QEMU_ARCH)-static
	sudo umount $(ROOTFS_DIR)/dev
	sudo umount $(ROOTFS_DIR)/boot
	sudo umount $(ROOTFS_DIR)
	sudo rmdir $(ROOTFS_DIR)
	sudo sync $(ROOTFS_PATCHED_IMG).wip
	sudo chown ${USER} $(ROOTFS_PATCHED_IMG).wip
	mv $(ROOTFS_PATCHED_IMG).wip $(ROOTFS_PATCHED_IMG)
	$(LOG) rootfs patch finished

$(ROOTFS_IMG): $(HOST_OUT)/bin/img2simg $(ROOTFS_PATCHED_IMG)
	$(LOG) rootfs img2simg
	$(HOST_OUT)/bin/img2simg $(ROOTFS_PATCHED_IMG) $(ROOTFS_IMG)
	$(LOG) rootfs img2simg finished

clean::
	if mount |grep -q $(ROOTFS_DIR); then sudo umount -R $(ROOTFS_DIR); fi
	if [[ -d $(ROOTFS_DIR) ]]; then rmdir $(ROOTFS_DIR); fi
	rm -f $(ROOTFS_PATCHED_IMG) $(ROOTFS_RAW_IMG) $(ROOTFS_IMG)

targets::
	@echo "rootfs - runs multistrap to build the rootfs tree"

.PHONY:: rootfs rootfs_raw adjustments fetch_debs push_debs
