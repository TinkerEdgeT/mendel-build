ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

# kernel-deb in kernel.mk is phony so redefine it here.
KERNEL_DEB := $(PRODUCT_OUT)/linux-image-4.9.51-aiy_1_arm64.deb

HANTRO_DIR := $(PRODUCT_OUT)/obj/IMX-VPU-HANTRO
HANTRO_DEBS := imx-vpu-hantro_1.6.0-0_arm64.deb
HANTRO_DEBS_DEV := imx-vpu-hantro-dev_1.6.0-0_arm64.deb
HANTRO_TARGETS := $(addprefix $(PRODUCT_OUT)/, $(HANTRO_DEBS)) $(addprefix $(PRODUCT_OUT)/dev/, $(HANTRO_DEBS_DEV))

WRAP_DIR := $(PRODUCT_OUT)/obj/IMX-VPUWRAP
WRAP_DEBS := imx-vpuwrap_4.3.4-0_arm64.deb
WRAP_DEBS_DEV := imx-vpuwrap-dev_4.3.4-0_arm64.deb
WRAP_TARGETS := $(addprefix $(PRODUCT_OUT)/, $(WRAP_DEBS)) $(addprefix $(PRODUCT_OUT)/dev/, $(WRAP_DEBS_DEV))

vpu-packages: imx-vpu-hantro imx-vpuwrap
imx-vpu-hantro: $(HANTRO_TARGETS)
imx-vpuwrap: $(WRAP_TARGETS)

$(HANTRO_TARGETS): $(KERNEL_DEB) $(ROOTDIR)/cache/arm64-builder.tar
	mkdir -p $(HANTRO_DIR)
	mkdir -p $(PRODUCT_OUT)/dev
	cp $(ROOTDIR)/imx-vpu-hantro/imx-vpu-hantro-1.6.0.bin $(HANTRO_DIR)
	cd $(HANTRO_DIR); ./imx-vpu-hantro-1.6.0.bin --auto-accept --force
	rsync -r $(ROOTDIR)/imx-vpu-hantro/debian/ $(HANTRO_DIR)/imx-vpu-hantro-1.6.0/debian/
	docker load -i $(ROOTDIR)/cache/arm64-builder.tar
	docker run --rm --privileged --tty \
	  -v $(PRODUCT_OUT):/out \
	  -v $(HANTRO_DIR):/imx-vpu-hantro arm64-builder \
	  /bin/bash -c 'dpkg -i /out/linux-headers-4.9.51-aiy_1_arm64.deb; \
	  cd /imx-vpu-hantro/imx-vpu-hantro-1.6.0; dpkg-buildpackage -uc -us -nc;'
	cp $(HANTRO_DIR)/$(HANTRO_DEBS) $(PRODUCT_OUT)
	cp $(HANTRO_DIR)/$(HANTRO_DEBS_DEV) $(PRODUCT_OUT)/dev

$(WRAP_TARGETS): $(HANTRO_TARGETS) $(KERNEL_DEB) $(ROOTDIR)/cache/arm64-builder.tar
	mkdir -p $(WRAP_DIR)
	mkdir -p $(PRODUCT_OUT)/dev
	cp $(ROOTDIR)/imx-vpuwrap/imx-vpuwrap-4.3.4.bin $(WRAP_DIR)
	cd $(WRAP_DIR); ./imx-vpuwrap-4.3.4.bin --auto-accept --force
	rsync -r $(ROOTDIR)/imx-vpuwrap/debian/ $(WRAP_DIR)/imx-vpuwrap-4.3.4/debian/
	docker load -i $(ROOTDIR)/cache/arm64-builder.tar
	docker run --rm --privileged --tty \
	  -v $(PRODUCT_OUT):/out \
	  -v $(WRAP_DIR):/imx-vpuwrap arm64-builder \
	  /bin/bash -c '\
	  dpkg -i /out/linux-headers-4.9.51-aiy_1_arm64.deb; \
	  dpkg -i /out/imx-vpu-hantro_1.6.0-0_arm64.deb; \
	  dpkg -i /out/dev/imx-vpu-hantro-dev_1.6.0-0_arm64.deb; \
	  cd /imx-vpuwrap/imx-vpuwrap-4.3.4; dpkg-buildpackage -uc -us -tc;'
	cp $(WRAP_DIR)/$(WRAP_DEBS) $(PRODUCT_OUT)
	cp $(WRAP_DIR)/$(WRAP_DEBS_DEV) $(PRODUCT_OUT)/dev
