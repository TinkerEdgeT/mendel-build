ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

# Kernel directories
KERNEL_SRC_DIR := $(ROOTDIR)/hardware/bsp/kernel/nxp/imx-v4.9
KERNEL_OUT_DIR := $(PRODUCT_OUT)/obj/KERNEL_OBJ

# Explicit sequencing here since u-boot and the kernel seriously hate each other
# in parallel.
kernel:
	+make -f $(ROOTDIR)/build/kernel.mk $(KERNEL_OUT_DIR)/.config
	+make -f $(ROOTDIR)/build/kernel.mk $(PRODUCT_OUT)/kernel
	+make -f $(ROOTDIR)/build/kernel.mk $(PRODUCT_OUT)/fsl-imx8mq-phanbell.dtb

targets::
	@echo "kernel - builds the kernel and boot partition"

clean::
	+make -C $(KERNEL_SRC_DIR) mrproper

$(KERNEL_OUT_DIR)/.config: $(ROOTDIR)/build/defconfig
	mkdir -p $(KERNEL_OUT_DIR)
	+make -C $(KERNEL_SRC_DIR) O=$(KERNEL_OUT_DIR) ARCH=arm64 CROSS_COMPILE=$(TOOLCHAIN) defconfig
	cat $(ROOTDIR)/build/defconfig | tee -a $(KERNEL_OUT_DIR)/.config

$(PRODUCT_OUT)/kernel: $(KERNEL_OUT_DIR)/.config
	+make -C $(KERNEL_SRC_DIR) O=$(KERNEL_OUT_DIR) ARCH=arm64 CROSS_COMPILE=$(TOOLCHAIN) Image modules
	cp $(KERNEL_OUT_DIR)/arch/arm64/boot/Image $(PRODUCT_OUT)/kernel

$(PRODUCT_OUT)/fsl-imx8mq-phanbell.dtb: $(KERNEL_OUT_DIR)/.config
	+make -C $(KERNEL_SRC_DIR) O=$(KERNEL_OUT_DIR) ARCH=arm64 CROSS_COMPILE=$(TOOLCHAIN) dtbs
	cp $(KERNEL_OUT_DIR)/arch/arm64/boot/dts/freescale/fsl-imx8mq-phanbell.dtb $(PRODUCT_OUT)/fsl-imx8mq-phanbell.dtb

modules_install: $(PRODUCT_OUT)/kernel
	+sudo make -C $(KERNEL_SRC_DIR) O=$(KERNEL_OUT_DIR) ARCH=arm64 CROSS_COMPILE=$(TOOLCHAIN) INSTALL_MOD_PATH=$(PRODUCT_OUT)/obj/ROOTFS/rootfs modules_install

.PHONY:: kernel modules_install