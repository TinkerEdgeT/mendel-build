ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

$(KERNEL_OUT_DIR):
	mkdir -p $(KERNEL_OUT_DIR)

$(KERNEL_OUT_DIR)/.config: $(ROOTDIR)/board/defconfig | $(KERNEL_OUT_DIR)
	+make -C $(KERNEL_SRC_DIR) O=$(KERNEL_OUT_DIR) $(KERNEL_OPTIONS) mrproper defconfig
	cat $(ROOTDIR)/board/defconfig | tee -a $(KERNEL_OUT_DIR)/.config
	+make -C $(KERNEL_SRC_DIR) O=$(KERNEL_OUT_DIR) $(KERNEL_OPTIONS) olddefconfig

$(KERNEL_OUT_DIR)/arch/arm64/boot/Image: $(KERNEL_OUT_DIR)/.config
		+make -C $(KERNEL_SRC_DIR) O=$(KERNEL_OUT_DIR) $(KERNEL_OPTIONS) Image modules dtbs

kernel-deb: $(PRODUCT_OUT)/packages/linux-image-4.9.51-aiy_1_arm64.deb

kernel: $(KERNEL_OUT_DIR)/arch/arm64/boot/Image $(KERNEL_OUT_DIR)/arch/arm64/boot/dts/freescale/fsl-imx8mq-phanbell.dtb

$(PRODUCT_OUT)/packages/linux-image-4.9.51-aiy_1_arm64.deb: $(KERNEL_OUT_DIR)/.config | out-dirs
	+make -C $(KERNEL_SRC_DIR) O=$(KERNEL_OUT_DIR) $(KERNEL_OPTIONS) \
		KDEB_PKGVERSION=1 KBUILD_IMAGE=Image deb-pkg
	mv $(KERNEL_OUT_DIR)/../linux-image-4.9.51-aiy_1_arm64.deb $(PRODUCT_OUT)/packages
	mv $(KERNEL_OUT_DIR)/../linux-headers-4.9.51-aiy_1_arm64.deb $(PRODUCT_OUT)/packages

targets::
	@echo "kernel - builds the kernel and boot partition"

clean::
	+make -C $(KERNEL_SRC_DIR) mrproper

.NOTPARALLEL: kernel kernel-deb
# Mark the deb as phony so we ensure that we rely on the kbuild system for
# incremental builds.
.PHONY:: kernel \
         kernel-deb \
         $(KERNEL_OUT_DIR)/arch/arm64/boot/dts/freescale/fsl-imx8mq-phanbell.dtb \
         $(KERNEL_OUT_DIR)/arch/arm64/boot/Image \
