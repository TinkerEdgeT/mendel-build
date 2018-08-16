ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

WAYLAND_PROTO_DIR := $(PRODUCT_OUT)/obj/WAYLAND_PROTO
WESTON_DIR := $(PRODUCT_OUT)/obj/WESTON
LIBDRM_DIR := $(PRODUCT_OUT)/obj/LIBDRM
LIBDRM_DEBS := libdrm2_2.4.84+imx-0_arm64.deb libdrm-vivante_2.4.84+imx-0_arm64.deb
LIBDRM_DEBS_DEV := libdrm-dev_2.4.84+imx-0_arm64.deb
LIBDRM_TARGETS := $(addprefix $(PRODUCT_OUT)/, $(LIBDRM_DEBS)) $(addprefix $(PRODUCT_OUT)/dev/, $(LIBDRM_DEBS_DEV))

wayland-protocols: $(PRODUCT_OUT)/wayland-protocols-imx_1.13-0_all.deb
weston: $(PRODUCT_OUT)/weston-imx_3.0.0-0_arm64.deb
libdrm-imx: $(LIBDRM_TARGETS)
gpu-packages: weston wayland-protocols imx-gpu-viv libdrm-imx

$(PRODUCT_OUT)/weston-imx_3.0.0-0_arm64.deb: $(ROOTDIR)/cache/arm64-builder.tar $(PRODUCT_OUT)/wayland-protocols-imx_1.13-0_all.deb
	mkdir -p $(WESTON_DIR)/weston-imx-3.0.0
	cp -r $(ROOTDIR)/weston-imx/* $(WESTON_DIR)/weston-imx-3.0.0
	mkdir -p $(WESTON_DIR)/weston-imx-3.0.0/lib/systemd/system
	cp $(ROOTDIR)/build/weston.service $(WESTON_DIR)/weston-imx-3.0.0/lib/systemd/system
	tar -C $(WESTON_DIR) -cJf $(WESTON_DIR)/weston-imx_3.0.0.orig.tar.xz weston-imx-3.0.0
	cp -r $(ROOTDIR)/build/weston-imx-debian $(WESTON_DIR)/weston-imx-3.0.0/debian
	docker load -i $(ROOTDIR)/cache/arm64-builder.tar
	docker run --rm --privileged --tty \
	  -v $(PRODUCT_OUT):/out \
	  -v $(WESTON_DIR):/weston arm64-builder \
	  /bin/bash -c 'dpkg -i /out/wayland-protocols-imx_1.13-0_all.deb; \
		cd /weston/weston-imx-3.0.0; dpkg-buildpackage -uc -us -tc'
	mv $(WESTON_DIR)/weston-imx_3.0.0-0_arm64.deb $(PRODUCT_OUT)

$(PRODUCT_OUT)/wayland-protocols-imx_1.13-0_all.deb:
	mkdir -p $(WAYLAND_PROTO_DIR)/wayland-protocols-imx-1.13
	cp -r $(ROOTDIR)/wayland-protocols-imx/* $(WAYLAND_PROTO_DIR)/wayland-protocols-imx-1.13
	tar -C $(WAYLAND_PROTO_DIR) -cJf $(WAYLAND_PROTO_DIR)/wayland-protocols-imx_1.13.orig.tar.xz wayland-protocols-imx-1.13
	cp -r $(ROOTDIR)/build/wayland-protocols-imx-debian $(WAYLAND_PROTO_DIR)/wayland-protocols-imx-1.13/debian
	cd $(WAYLAND_PROTO_DIR)/wayland-protocols-imx-1.13; dpkg-buildpackage -uc -us -tc
	mv $(WAYLAND_PROTO_DIR)/wayland-protocols-imx_1.13-0_all.deb $(PRODUCT_OUT)

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

.PHONY:: wayland-protocols-imx weston-imx gpu-packages
