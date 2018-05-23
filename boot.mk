ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

boot: $(PRODUCT_OUT)/boot.img

$(PRODUCT_OUT)/boot.img: $(PRODUCT_OUT)/u-boot.imx $(PRODUCT_OUT)/kernel $(PRODUCT_OUT)/obj/BOOT_OBJ/boot.scr
	fallocate -l 32M $(PRODUCT_OUT)/boot.img
	mkfs.fat $(PRODUCT_OUT)/boot.img
	mcopy -i $(PRODUCT_OUT)/boot.img $(PRODUCT_OUT)/kernel ::Image
	mcopy -i $(PRODUCT_OUT)/boot.img $(PRODUCT_OUT)/obj/BOOT_OBJ/boot.scr ::
	mcopy -i $(PRODUCT_OUT)/boot.img $(PRODUCT_OUT)/fsl-imx8mq-phanbell.dtb ::

$(PRODUCT_OUT)/obj/BOOT_OBJ/boot.scr: $(HOST_OUT)/bin/mkimage
	mkdir -p $(PRODUCT_OUT)/obj/BOOT_OBJ
	$(HOST_OUT)/bin/mkimage -A arm -T script -O linux -d $(ROOTDIR)/build/boot.txt $(PRODUCT_OUT)/obj/BOOT_OBJ/boot.scr

targets::
	@echo "boot - builds the kernel and boot partition"

clean::
	rm -f $(PRODUCT_OUT)/boot.img
	rm -rf $(PRODUCT_OUT)/obj/BOOT_OBJ

.PHONY:: boot
