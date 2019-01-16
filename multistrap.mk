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
include $(ROOTDIR)/build/rootfs-packages.mk

MULTISTRAP_WORK_DIR := $(PRODUCT_OUT)/multistrap/work

multistrap: $(PRODUCT_OUT)/multistrap/rootfs.img $(PRODUCT_OUT)/multistrap/boot.img

$(PRODUCT_OUT)/multistrap/rootfs.img: $(PRODUCT_OUT)/multistrap/boot.img $(HOST_OUT)/bin/img2simg
	fallocate -l $(ROOTFS_SIZE_MB)M $@.wip
	mkfs.ext4 -F -j $@.wip
	mkfs.ext2 -F $(PRODUCT_OUT)/multistrap/boot.img
	tune2fs -o discard $@.wip
	mkdir -p $(MULTISTRAP_WORK_DIR)

	sudo mount -o loop $@.wip $(MULTISTRAP_WORK_DIR)
	sudo mkdir -p $(MULTISTRAP_WORK_DIR)/boot $(MULTISTRAP_WORK_DIR)/dev
	sudo mount -o loop $(PRODUCT_OUT)/multistrap/boot.img $(MULTISTRAP_WORK_DIR)/boot

	cp $(ROOTDIR)/board/multistrap.conf $(PRODUCT_OUT)/multistrap
	sed -i -e 's/USERSPACE_ARCH/$(USERSPACE_ARCH)/g' $(PRODUCT_OUT)/multistrap/multistrap.conf
	sed -i -e 's/MAIN_PACKAGES/$(PACKAGES_EXTRA) $(BASE_PACKAGES) $(BSP_BASE_PACKAGES)/g' $(PRODUCT_OUT)/multistrap/multistrap.conf
	sudo multistrap -f $(PRODUCT_OUT)/multistrap/multistrap.conf -d $(MULTISTRAP_WORK_DIR)

	sudo mount -o bind /dev $(MULTISTRAP_WORK_DIR)/dev
	sudo cp /usr/bin/qemu-$(QEMU_ARCH)-static $(MULTISTRAP_WORK_DIR)/usr/bin
	sudo chroot $(MULTISTRAP_WORK_DIR) /var/lib/dpkg/info/dash.preinst install
	sudo DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true LC_ALL=C LANGUAGE=C LANG=C chroot $(MULTISTRAP_WORK_DIR) dpkg --configure -a
	sudo rm -f $(MULTISTRAP_WORK_DIR)/usr/bin/qemu-$(QEMU_ARCH)-static

	sudo umount -R $(MULTISTRAP_WORK_DIR)
	rm -rf $(MULTISTRAP_WORK_DIR)
	$(HOST_OUT)/bin/img2simg $@.wip $@

$(PRODUCT_OUT)/multistrap/boot.img: $(PRODUCT_OUT)/multistrap
	fallocate -l $(BOOT_SIZE_MB)M $@

$(PRODUCT_OUT)/multistrap:
	mkdir -p $(PRODUCT_OUT)/multistrap

.PHONY:: multistrap
