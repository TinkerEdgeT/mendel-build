ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

u-boot: $(PRODUCT_OUT)/u-boot.imx

$(PRODUCT_OUT)/u-boot.imx: uboot-imx | out-dirs
	dpkg --fsys-tarfile $(PRODUCT_OUT)/packages/uboot-imx*.deb | \
	tar --strip-components 2 -C $(PRODUCT_OUT) -xf - ./boot/u-boot.imx

targets::
	@echo "u-boot - builds the bootloader"

.PHONY:: u-boot

