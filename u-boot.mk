ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

# U-boot directories
NXP_MKIMAGE_DIR := $(ROOTDIR)/tools/imx-mkimage
UBOOT_SRC_DIR := $(ROOTDIR)/uboot-imx
UBOOT_OUT_DIR := $(PRODUCT_OUT)/obj/UBOOT_OBJ

u-boot: $(PRODUCT_OUT)/u-boot.imx

mkimage: $(HOST_OUT)/bin/mkimage

$(PRODUCT_OUT)/u-boot.imx:
	mkdir -p $(UBOOT_OUT_DIR)
	+make -C $(UBOOT_SRC_DIR) O=$(UBOOT_OUT_DIR) ARCH=arm CROSS_COMPILE=$(TOOLCHAIN) mx8mq_phanbell_defconfig
	+make -C $(UBOOT_SRC_DIR) O=$(UBOOT_OUT_DIR) ARCH=arm CROSS_COMPILE=$(TOOLCHAIN)
	cp $(UBOOT_OUT_DIR)/tools/mkimage $(UBOOT_OUT_DIR)/tools/mkimage_uboot
	+make -C $(NXP_MKIMAGE_DIR) TARGET_PRODUCT=iot_imx8m_phanbell SOC=iMX8M flash_hdmi_spl_uboot
	cp $(NXP_MKIMAGE_DIR)/iMX8M/flash.bin $(PRODUCT_OUT)/u-boot.imx
	+make -C $(NXP_MKIMAGE_DIR) TARGET_PRODUCT=iot_imx8m_phanbell clean

$(HOST_OUT)/bin/mkimage: $(PRODUCT_OUT)/u-boot.imx
	mkdir -p $(HOST_OUT)/bin
	cp $(UBOOT_OUT_DIR)/tools/mkimage $(HOST_OUT)/bin

targets::
	@echo "u-boot - builds the bootloader"
	@echo "mkimage - builds the mkimage tool that creates boot images"

clean::
	+make -C $(UBOOT_SRC_DIR) mrproper
	rm -f $(HOST_OUT)/bin/mkimage $(PRODUCT_OUT)/u-boot.imx

.PHONY:: u-boot

