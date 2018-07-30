ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

boot: $(PRODUCT_OUT)/boot.img

$(PRODUCT_OUT)/boot.img: $(PRODUCT_OUT)/u-boot.imx \
                         $(PRODUCT_OUT)/obj/KERNEL_OBJ/arch/arm64/boot/dts/freescale/fsl-imx8mq-phanbell.dtb \
                         $(PRODUCT_OUT)/obj/KERNEL_OBJ/arch/arm64/boot/Image \
                         $(PRODUCT_OUT)/obj/BOOT_OBJ/boot.scr
	mkdir -p $(PRODUCT_OUT)/boot
	cp $(PRODUCT_OUT)/obj/BOOT_OBJ/boot.scr \
	   $(PRODUCT_OUT)/obj/KERNEL_OBJ/arch/arm64/boot/dts/freescale/fsl-imx8mq-phanbell.dtb \
	   $(PRODUCT_OUT)/obj/KERNEL_OBJ/arch/arm64/boot/Image \
		 $(PRODUCT_OUT)/boot/
	genext2fs -d $(PRODUCT_OUT)/boot/ -B 4096 -b 32768 $(PRODUCT_OUT)/boot.img

$(PRODUCT_OUT)/obj/BOOT_OBJ/boot.scr: $(HOST_OUT)/bin/mkimage
	mkdir -p $(PRODUCT_OUT)/obj/BOOT_OBJ
	$(HOST_OUT)/bin/mkimage -A arm -T script -O linux -d $(ROOTDIR)/board/boot.txt $(PRODUCT_OUT)/obj/BOOT_OBJ/boot.scr

targets::
	@echo "boot - builds the kernel and boot partition"

clean::
	rm -f $(PRODUCT_OUT)/boot.img
	rm -rf $(PRODUCT_OUT)/obj/BOOT_OBJ

.PHONY:: boot
