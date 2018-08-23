ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

LIBDRM_DIR := $(PRODUCT_OUT)/obj/LIBDRM
LIBDRM_DEBS := libdrm2_2.4.84+imx-0_arm64.deb libdrm-vivante_2.4.84+imx-0_arm64.deb
LIBDRM_DEBS_DEV := libdrm-dev_2.4.84+imx-0_arm64.deb
LIBDRM_TARGETS := $(addprefix $(PRODUCT_OUT)/, $(LIBDRM_DEBS)) $(addprefix $(PRODUCT_OUT)/dev/, $(LIBDRM_DEBS_DEV))

libdrm-imx: $(LIBDRM_TARGETS)
gpu-packages: libdrm-imx

$(LIBDRM_TARGETS): $(ROOTDIR)/cache/arm64-builder.tar
	mkdir -p $(PRODUCT_OUT)/dev
	mkdir -p $(LIBDRM_DIR)/libdrm-2.4.84+imx
	rsync -r $(ROOTDIR)/libdrm-imx/ $(LIBDRM_DIR)/libdrm-2.4.84+imx
	tar -C $(LIBDRM_DIR) -cJf $(LIBDRM_DIR)/libdrm_2.4.84+imx.orig.tar.xz libdrm-2.4.84+imx
	rsync -r $(ROOTDIR)/packages/libdrm-imx/debian/ $(LIBDRM_DIR)/libdrm-2.4.84+imx/debian/
	docker load -i $(ROOTDIR)/cache/arm64-builder.tar
	docker run --rm --privileged --tty \
	  -v $(PRODUCT_OUT):/out \
	  -v $(LIBDRM_DIR):/libdrm arm64-builder \
	  /bin/bash -c 'cd /libdrm/libdrm-2.4.84+imx; \
	  dpkg-buildpackage -uc -us -tc;'
	cp $(LIBDRM_DIR)/libdrm2_2.4.84+imx-0_arm64.deb $(PRODUCT_OUT)
	cp $(LIBDRM_DIR)/libdrm-vivante_2.4.84+imx-0_arm64.deb $(PRODUCT_OUT)
	cp $(LIBDRM_DIR)/libdrm-dev_2.4.84+imx-0_arm64.deb $(PRODUCT_OUT)/dev

.PHONY:: gpu-packages
