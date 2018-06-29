ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

sdcard: $(PRODUCT_OUT)/sdcard.img
sdcard-xz: $(PRODUCT_OUT)/sdcard.img.xz

sdcard-allocate: | $(PRODUCT_OUT)
	fallocate -l 4G $(PRODUCT_OUT)/sdcard.img

$(PRODUCT_OUT)/sdcard.img: sdcard-allocate \
                           $(ROOTDIR)/build/rootfs.mk \
                           $(ROOTDIR)/build/boot.mk \
                           $(ROOTDIR)/build/u-boot.mk \
                           | $(PRODUCT_OUT)/u-boot.imx \
                           $(PRODUCT_OUT)/boot.img \
                           $(PRODUCT_OUT)/obj/ROOTFS/rootfs.patched.img
	parted -s $(PRODUCT_OUT)/sdcard.img mklabel msdos
	parted -s $(PRODUCT_OUT)/sdcard.img unit MiB mkpart primary ext2 8 136
	parted -s $(PRODUCT_OUT)/sdcard.img unit MiB mkpart primary ext4 136 4095
	dd if=$(PRODUCT_OUT)/u-boot.imx of=$(PRODUCT_OUT)/sdcard.img conv=notrunc seek=66 bs=512
	dd if=$(PRODUCT_OUT)/boot.img of=$(PRODUCT_OUT)/sdcard.img conv=notrunc seek=8 bs=1M
	dd if=$(PRODUCT_OUT)/obj/ROOTFS/rootfs.patched.img \
		of=$(PRODUCT_OUT)/sdcard.img conv=notrunc seek=136 bs=1M


	mkdir -p $(ROOTFS_DIR)
	-sudo umount $(ROOTFS_DIR)/boot
	-sudo umount $(ROOTFS_DIR)
	$(eval LOOP=$(shell sudo losetup --show -f $(PRODUCT_OUT)/sdcard.img))
	-sudo partx -d $(LOOP)
	sudo partx -a $(LOOP)

	sudo mount $(LOOP)p2 $(ROOTFS_DIR)
	sudo mount $(LOOP)p1 $(ROOTFS_DIR)/boot

	sudo cp $(ROOTDIR)/build/fstab.sdcard $(ROOTFS_DIR)/etc/fstab

	sudo umount $(ROOTFS_DIR)/boot
	sudo umount $(ROOTFS_DIR)
	sudo partx -d $(LOOP)
	sudo losetup -d $(LOOP)
	rmdir $(ROOTFS_DIR)

$(PRODUCT_OUT)/sdcard.img.xz: $(PRODUCT_OUT)/sdcard.img
	xz -k -T0 -0 $(PRODUCT_OUT)/sdcard.img

targets::
	@echo "sdcard     - generate a flashable sdcard image"

clean::
	rm -f $(PRODUCT_OUT)/sdcard.img $(PRODUCT_OUT)/sdcard.img.xz

.PHONY:: sdcard sdcard-xz
