ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

sdcard: $(PRODUCT_OUT)/sdcard.img
sdcard-xz: $(PRODUCT_OUT)/sdcard.img.xz

$(PRODUCT_OUT)/sdcard.img: $(ROOTDIR)/build/rootfs.mk $(ROOTDIR)/build/boot.mk $(ROOTDIR)/build/u-boot.mk
	+make -f $(ROOTDIR)/Makefile boot-targets
	+make -f $(ROOTDIR)/Makefile rootfs
	fallocate -l 4G $(PRODUCT_OUT)/sdcard.img
	parted -s $(PRODUCT_OUT)/sdcard.img mklabel msdos
	parted -s $(PRODUCT_OUT)/sdcard.img unit MiB mkpart primary fat32 8 40
	parted -s $(PRODUCT_OUT)/sdcard.img unit MiB mkpart primary 40 4095
	dd if=$(PRODUCT_OUT)/u-boot.imx of=$(PRODUCT_OUT)/sdcard.img conv=notrunc seek=66 bs=512
	dd if=$(PRODUCT_OUT)/boot.img of=$(PRODUCT_OUT)/sdcard.img conv=notrunc seek=8 bs=1M
	dd if=$(PRODUCT_OUT)/obj/ROOTFS/rootfs.patched.img \
		of=$(PRODUCT_OUT)/sdcard.img conv=notrunc seek=40 bs=1M

$(PRODUCT_OUT)/sdcard.img.xz: $(PRODUCT_OUT)/sdcard.img
	xz -k -T0 -0 $(PRODUCT_OUT)/sdcard.img

targets::
	@echo "sdcard     - generate a flashable sdcard image"

clean::
	rm -f $(PRODUCT_OUT)/sdcard.img $(PRODUCT_OUT)/sdcard.img.xz

.PHONY:: sdcard sdcard-xz
