ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

GPU_VERSION := imx-gpu-viv-6.2.4.p1.0-aarch64
GPU_DIR := $(ROOTDIR)/imx-gpu-viv/$(GPU_VERSION)
GPU_OUT_DIR := $(PRODUCT_OUT)/obj/GPU

WAYLAND_PROTO_DIR := $(PRODUCT_OUT)/obj/WAYLAND_PROTO
WESTON_DIR := $(PRODUCT_OUT)/obj/WESTON

imx-gpu-viv: $(PRODUCT_OUT)/imx-gpu-viv_6.2.4_arm64.deb
wayland-protocols: $(PRODUCT_OUT)/wayland-protocols-imx_1.13-0_all.deb
weston: $(PRODUCT_OUT)/weston-imx_3.0.0-0_arm64.deb
gpu-packages: weston wayland-protocols imx-gpu-viv

$(PRODUCT_OUT)/weston-imx_3.0.0-0_arm64.deb: $(ROOTDIR)/cache/arm64-builder.tar $(PRODUCT_OUT)/wayland-protocols-imx_1.13-0_all.deb
	mkdir -p $(WESTON_DIR)/weston-imx-3.0.0
	cp -r $(ROOTDIR)/weston-imx/* $(WESTON_DIR)/weston-imx-3.0.0
	mkdir -p $(WESTON_DIR)/weston-imx-3.0.0/etc/systemd/system
	cp $(ROOTDIR)/build/weston.service $(WESTON_DIR)/weston-imx-3.0.0/etc/systemd/system
	tar -C $(WESTON_DIR) -cJf $(WESTON_DIR)/weston-imx_3.0.0.orig.tar.xz weston-imx-3.0.0
	cp -r $(ROOTDIR)/build/weston-imx-debian $(WESTON_DIR)/weston-imx-3.0.0/debian
	docker load -i $(ROOTDIR)/cache/arm64-builder.tar
	docker run --rm --privileged --tty \
	  -v $(PRODUCT_OUT):/out \
	  -v $(WESTON_DIR):/weston arm64-builder \
	  /bin/bash -c 'dpkg -i /out/wayland-protocols-imx_1.13-0_all.deb; \
		cd /weston/weston-imx-3.0.0; dpkg-buildpackage -uc -us -tc'
	mv $(WESTON_DIR)/weston-imx_3.0.0-0_arm64.deb $(PRODUCT_OUT)

$(PRODUCT_OUT)/imx-gpu-viv_6.2.4_arm64.deb:
	mkdir -p $(GPU_OUT_DIR)
	mkdir -p $(GPU_OUT_DIR)/usr
	mkdir -p $(GPU_OUT_DIR)/usr/bin
	mkdir -p $(GPU_OUT_DIR)/usr/lib
	mkdir -p $(GPU_OUT_DIR)/usr/lib/dri
	mkdir -p $(GPU_OUT_DIR)/usr/lib/pkgconfig
	mkdir -p $(GPU_OUT_DIR)/usr/lib/vulkan
	mkdir -p $(GPU_OUT_DIR)/usr/include

	cp -P $(GPU_DIR)/gpu-core/usr/lib/*.so* $(GPU_OUT_DIR)/usr/lib/
	cp -r $(GPU_DIR)/gpu-core/usr/include/* $(GPU_OUT_DIR)/usr/include/
	cp -r $(GPU_DIR)/gpu-demos/opt $(GPU_OUT_DIR)
	cp -r $(GPU_DIR)/gpu-tools/gmem-info/usr/bin/* $(GPU_OUT_DIR)/usr/bin

	cp $(GPU_DIR)/gpu-core/usr/lib/pkgconfig/egl_wayland.pc $(GPU_OUT_DIR)/usr/lib/pkgconfig/egl.pc
	cp $(GPU_DIR)/gpu-core/usr/lib/pkgconfig/glesv1_cm.pc $(GPU_OUT_DIR)/usr/lib/pkgconfig
	cp $(GPU_DIR)/gpu-core/usr/lib/pkgconfig/glesv2.pc $(GPU_OUT_DIR)/usr/lib/pkgconfig
	cp $(GPU_DIR)/gpu-core/usr/lib/pkgconfig/vg.pc $(GPU_OUT_DIR)/usr/lib/pkgconfig
	cp $(GPU_DIR)/gpu-core/usr/lib/pkgconfig/wayland-egl.pc $(GPU_OUT_DIR)/usr/lib/pkgconfig
	cp $(GPU_DIR)/gpu-core/usr/lib/pkgconfig/gbm.pc $(GPU_OUT_DIR)/usr/lib/pkgconfig

	cp -r $(GPU_DIR)/gpu-core/usr/lib/dri $(GPU_OUT_DIR)/usr/lib

	mv $(GPU_OUT_DIR)/usr/lib/libGL.so.1.2 $(GPU_OUT_DIR)/usr/lib/libGL.so.1.2.0
	ln -sf libGL.so.1.2.0 $(GPU_OUT_DIR)/usr/lib/libGL.so.1.2
	ln -sf libGL.so.1.2 $(GPU_OUT_DIR)/usr/lib/libGL.so.1
	ln -sf libGL.so.1 $(GPU_OUT_DIR)/usr/lib/libGL.so

	mv $(GPU_OUT_DIR)/usr/lib/libEGL-wl.so $(GPU_OUT_DIR)/usr/lib/libEGL.so.1.0
	ln -sf libEGL.so.1.0 $(GPU_OUT_DIR)/usr/lib/libEGL.so.1
	ln -sf libEGL.so.1 $(GPU_OUT_DIR)/usr/lib/libEGL.so

	mv $(GPU_OUT_DIR)/usr/lib/libGAL-wl.so $(GPU_OUT_DIR)/usr/lib/libGAL.so
	mv $(GPU_OUT_DIR)/usr/lib/libVDK-wl.so $(GPU_OUT_DIR)/usr/lib/libVDK.so

	rm -rf $(GPU_OUT_DIR)/usr/lib/libGLESv2*
	cp $(GPU_DIR)/gpu-core/usr/lib/libGLESv2-wl.so $(GPU_OUT_DIR)/usr/lib/libGLESv2.so.2.0.0
	ln -sf libGLESv2.so.2.0.0 $(GPU_OUT_DIR)/usr/lib/libGLESv2.so.2.0
	ln -sf libGLESv2.so.2.0 $(GPU_OUT_DIR)/usr/lib/libGLESv2.so.2
	ln -sf libGLESv2.so.2 $(GPU_OUT_DIR)/usr/lib/libGLESv2.so

	mv $(GPU_OUT_DIR)/usr/lib/libvulkan-wl.so $(GPU_OUT_DIR)/usr/lib/vulkan/libvulkan_VSI.so

	rm -rf $(GPU_OUT_DIR)/usr/lib/*-wl.so
	rm -rf $(GPU_OUT_DIR)/usr/lib/*-fb.so
	rm -rf $(GPU_OUT_DIR)/usr/lib/*-x11.so

	rm -f $(GPU_OUT_DIR)/usr/lib/libOpenVG.so
	ln -sf libOpenVG.3d.so $(GPU_OUT_DIR)/usr/lib/libOpenVG.so

	cp -r $(ROOTDIR)/imx-gpu-viv/debian $(GPU_OUT_DIR)
	cd $(GPU_OUT_DIR); dpkg-buildpackage -aarm64 -b -rfakeroot -us -uc -tc

	mv $(GPU_OUT_DIR)/../imx-gpu-viv_6.2.4_arm64.deb $(PRODUCT_OUT)

$(PRODUCT_OUT)/wayland-protocols-imx_1.13-0_all.deb:
	mkdir -p $(WAYLAND_PROTO_DIR)/wayland-protocols-imx-1.13
	cp -r $(ROOTDIR)/wayland-protocols-imx/* $(WAYLAND_PROTO_DIR)/wayland-protocols-imx-1.13
	tar -C $(WAYLAND_PROTO_DIR) -cJf $(WAYLAND_PROTO_DIR)/wayland-protocols-imx_1.13.orig.tar.xz wayland-protocols-imx-1.13
	cp -r $(ROOTDIR)/build/wayland-protocols-imx-debian $(WAYLAND_PROTO_DIR)/wayland-protocols-imx-1.13/debian
	cd $(WAYLAND_PROTO_DIR)/wayland-protocols-imx-1.13; dpkg-buildpackage -uc -us -tc
	mv $(WAYLAND_PROTO_DIR)/wayland-protocols-imx_1.13-0_all.deb $(PRODUCT_OUT)


.PHONY:: imx-gpu-viv wayland-protocols-imx weston-imx gpu-packages
