ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

# Kernel directories
KERNEL_SRC_DIR := $(ROOTDIR)/linux-imx
KERNEL_OUT_DIR := $(PRODUCT_OUT)/obj/KERNEL_OBJ

$(KERNEL_OUT_DIR)/.config: $(ROOTDIR)/build/defconfig
	mkdir -p $(KERNEL_OUT_DIR)
	cp -afs $(ROOTDIR)/linux-imx/* $(KERNEL_OUT_DIR)
	+make -C $(KERNEL_SRC_DIR) O=$(KERNEL_OUT_DIR) ARCH=arm64 CROSS_COMPILE=$(TOOLCHAIN) mrproper defconfig
	cat $(ROOTDIR)/build/defconfig | tee -a $(KERNEL_OUT_DIR)/.config

$(KERNEL_OUT_DIR)/arch/arm64/boot/Image: $(KERNEL_OUT_DIR)/.config
		+make -C $(KERNEL_SRC_DIR) O=$(KERNEL_OUT_DIR) ARCH=arm64 CROSS_COMPILE=$(TOOLCHAIN) Image modules dtbs

kernel: $(KERNEL_OUT_DIR)/arch/arm64/boot/Image $(KERNEL_OUT_DIR)/arch/arm64/boot/dts/freescale/fsl-imx8mq-phanbell.dtb

$(PRODUCT_OUT)/linux-image-4.9.51-aiy_1_arm64.deb: $(KERNEL_OUT_DIR)/.config
	cd $(KERNEL_OUT_DIR); MFLAGS="" MAKEFLAGS="" make-kpkg --rootcmd fakeroot --arch arm64 \
		--cross-compile $(TOOLCHAIN) --revision 1 --append-to-version=-aiy \
		-j $(shell nproc) --overlay-dir=$(ROOTDIR)/build/kernel-overlay \
		kernel_image kernel_headers
	mv $(KERNEL_OUT_DIR)/../*.deb $(PRODUCT_OUT)

targets::
	@echo "kernel - builds the kernel and boot partition"

clean::
	+make -C $(KERNEL_SRC_DIR) mrproper

# Mark the deb as phony so we enxure that we rely on the kbuild system for
# incremental builds.
.PHONY:: kernel \
         $(KERNEL_OUT_DIR)/arch/arm64/boot/dts/freescale/fsl-imx8mq-phanbell.dtb \
         $(KERNEL_OUT_DIR)/arch/arm64/boot/Image \
