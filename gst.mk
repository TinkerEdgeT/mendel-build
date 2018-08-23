ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

KERNEL_DEB := $(PRODUCT_OUT)/linux-image-4.9.51-aiy_1_arm64.deb

GST_DIR := $(PRODUCT_OUT)/obj/GST

GST_CORE_DEBS := libgstreamer1.0-0_1.12.2+imx-0_arm64.deb gstreamer1.0-tools_1.12.2+imx-0_arm64.deb
GST_CORE_DEBS_DEV := libgstreamer1.0-dev_1.12.2+imx-0_arm64.deb
GST_CORE_DEBS_AUX := gir1.2-gstreamer-1.0_1.12.2+imx-0_arm64.deb
GST_TARGETS := \
	$(addprefix $(PRODUCT_OUT)/, $(GST_CORE_DEBS)) \
	$(addprefix $(PRODUCT_OUT)/dev/, $(GST_CORE_DEBS_DEV)) \
	$(addprefix $(PRODUCT_OUT)/aux/, $(GST_CORE_DEBS_AUX)) \

GST_P_BASE_DEBS := gstreamer1.0-plugins-base_1.12.2+imx-0_arm64.deb \
	gstreamer1.0-alsa_1.12.2+imx-0_arm64.deb \
	libgstreamer-plugins-base1.0-0_1.12.2+imx-0_arm64.deb
GST_P_BASE_DEBS_DEV := libgstreamer-plugins-base1.0-dev_1.12.2+imx-0_arm64.deb
GST_P_BASE_DEBS_AUX := gstreamer1.0-plugins-base-apps_1.12.2+imx-0_arm64.deb gir1.2-gst-plugins-base-1.0_1.12.2+imx-0_arm64.deb
GST_P_BASE_TARGETS := \
	$(addprefix $(PRODUCT_OUT)/, $(GST_P_BASE_DEBS)) \
	$(addprefix $(PRODUCT_OUT)/dev/, $(GST_P_BASE_DEBS_DEV)) \
	$(addprefix $(PRODUCT_OUT)/aux/, $(GST_P_BASE_DEBS_AUX)) \

GST_P_GOOD_DEBS := gstreamer1.0-plugins-good_1.12.2+imx-0_arm64.deb
GST_P_GOOD_DEBS_AUX := gstreamer1.0-pulseaudio_1.12.2+imx-0_arm64.deb
GST_P_GOOD_TARGETS := $(addprefix $(PRODUCT_OUT)/, $(GST_P_GOOD_DEBS)) $(addprefix $(PRODUCT_OUT)/aux/, $(GST_P_GOOD_DEBS_AUX)) \

GST_P_BAD_DEBS := gstreamer1.0-plugins-bad_1.12.2+imx-0_arm64.deb libgstreamer-plugins-bad1.0-0_1.12.2+imx-0_arm64.deb
GST_P_BAD_DEBS_DEV := libgstreamer-plugins-bad1.0-dev_1.12.2+imx-0_arm64.deb
GST_P_BAD_DEBS_AUX := gir1.2-gst-plugins-bad-1.0_1.12.2+imx-0_arm64.deb
GST_P_BAD_TARGETS := \
	$(addprefix $(PRODUCT_OUT)/, $(GST_P_BAD_DEBS)) \
	$(addprefix $(PRODUCT_OUT)/dev/, $(GST_P_BAD_DEBS_DEV)) \
	$(addprefix $(PRODUCT_OUT)/aux/, $(GST_P_BAD_DEBS_AUX)) \

GST_P_IMX_DEBS := imx-gst1.0-plugin_4.3.4-0_arm64.deb
GST_P_IMX_TARGETS := $(addprefix $(PRODUCT_OUT)/, $(GST_P_IMX_DEBS))

GST_DEBS := $(addprefix $(PRODUCT_OUT)/, $(GST_CORE_DEBS) $(GST_P_BASE_DEBS) $(GST_P_GOOD_DEBS) $(GST_P_BAD_DEBS) $(GST_P_IMX_DEBS))

gst-core: $(GST_TARGETS)
gst-plugins-base: $(GST_P_BASE_TARGETS)
gst-plugins-good: $(GST_P_GOOD_TARGETS)
gst-plugins-bad: $(GST_P_BAD_TARGETS)
gst-plugins-imx: $(GST_P_IMX_TARGETS)
gst-packages: $(GST_DEBS)

define stat_files
$(shell stat $(1) > /dev/null 2>&1; echo $$?;)
endef

$(GST_TARGETS): $(ROOTDIR)/cache/arm64-builder.tar
ifeq ($(call stat_files,$(addprefix $(GST_DIR)/,$(GST_CORE_DEBS) $(GST_CORE_DEBS_DEV) $(GST_CORE_DEBS_AUX))),0)
	$(info $@ already built, not rebuilding)
else
	$(info building $@)
	mkdir -p $(PRODUCT_OUT)/dev
	mkdir -p $(PRODUCT_OUT)/aux
	mkdir -p $(GST_DIR)
	cd $(ROOTDIR)/imx-gstreamer; git submodule init; git submodule update;
	rsync -r $(ROOTDIR)/imx-gstreamer/ $(GST_DIR)/gstreamer1.0_1.12.2+imx/
	tar -C $(GST_DIR) -cJf $(GST_DIR)/gstreamer1.0_1.12.2+imx.orig.tar.xz gstreamer1.0_1.12.2+imx
	rsync -r $(ROOTDIR)/packages/imx-gstreamer/debian/ $(GST_DIR)/gstreamer1.0_1.12.2+imx/debian/
	docker load -i $(ROOTDIR)/cache/arm64-builder.tar
	docker run --rm --privileged --tty \
	  -v $(PRODUCT_OUT):/out \
	  -v $(GST_DIR):/gst arm64-builder \
	  /bin/bash -c 'cd /gst/gstreamer1.0_1.12.2+imx; \
	  DEB_COPYRIGHT_CHECK_LICENSECHECK=/nope dpkg-buildpackage -uc -us -tc;'
endif
	cp $(addprefix $(GST_DIR)/,$(GST_CORE_DEBS)) $(PRODUCT_OUT)
	cp $(addprefix $(GST_DIR)/,$(GST_CORE_DEBS_DEV)) $(PRODUCT_OUT)/dev
	cp $(addprefix $(GST_DIR)/,$(GST_CORE_DEBS_AUX)) $(PRODUCT_OUT)/aux

$(GST_P_BASE_TARGETS): $(GST_TARGETS) $(ROOTDIR)/cache/arm64-builder.tar
ifeq ($(call stat_files,$(addprefix $(GST_DIR)/,$(GST_P_BASE_DEBS) $(GST_P_BASE_DEBS_DEV) $(GST_P_BASE_DEBS_AUX))),0)
	$(info $@ already built, not rebuilding)
else
	$(info building $@)
	mkdir -p $(PRODUCT_OUT)/dev
	mkdir -p $(PRODUCT_OUT)/aux
	mkdir -p $(GST_DIR)
	cd $(ROOTDIR)/imx-gst-plugins-base; git submodule init; git submodule update;
	rsync -r $(ROOTDIR)/imx-gst-plugins-base/ $(GST_DIR)/gst-plugins-base1.0_1.12.2+imx/
	tar -C $(GST_DIR) -cJf $(GST_DIR)/gst-plugins-base1.0_1.12.2+imx.orig.tar.xz gst-plugins-base1.0_1.12.2+imx
	rsync -r $(ROOTDIR)/packages/imx-gst-plugins-base/debian/ $(GST_DIR)/gst-plugins-base1.0_1.12.2+imx/debian/
	docker load -i $(ROOTDIR)/cache/arm64-builder.tar
	docker run --rm --privileged --tty \
	  -v $(PRODUCT_OUT):/out \
	  -v $(GST_DIR):/gst arm64-builder \
	  /bin/bash -c '\
		dpkg -i /out/libgstreamer1.0-0_1.12.2+imx-0_arm64.deb; \
		dpkg -i /out/aux/gir1.2-gstreamer-1.0_1.12.2+imx-0_arm64.deb; \
		dpkg -i /out/dev/libgstreamer1.0-dev_1.12.2+imx-0_arm64.deb; \
		cd /gst/gst-plugins-base1.0_1.12.2+imx; \
		DEB_COPYRIGHT_CHECK_LICENSECHECK=/nope dpkg-buildpackage -uc -us -tc;'
endif
	cp $(addprefix $(GST_DIR)/,$(GST_P_BASE_DEBS)) $(PRODUCT_OUT)
	cp $(addprefix $(GST_DIR)/,$(GST_P_BASE_DEBS_DEV)) $(PRODUCT_OUT)/dev
	cp $(addprefix $(GST_DIR)/,$(GST_P_BASE_DEBS_AUX)) $(PRODUCT_OUT)/aux

$(GST_P_GOOD_TARGETS): $(GST_P_BASE_TARGETS) $(ROOTDIR)/cache/arm64-builder.tar
ifeq ($(call stat_files,$(addprefix $(GST_DIR)/,$(GST_P_GOOD_DEBS) $(GST_P_GOOD_DEBS_AUX))),0)
	$(info $@ already built, not rebuilding)
else
	$(info building $@)
	mkdir -p $(PRODUCT_OUT)/dev
	mkdir -p $(PRODUCT_OUT)/aux
	mkdir -p $(GST_DIR)
	cd $(ROOTDIR)/imx-gst-plugins-good; git submodule init; git submodule update;
	rsync -r $(ROOTDIR)/imx-gst-plugins-good/ $(GST_DIR)/gst-plugins-good1.0_1.12.2+imx/
	tar -C $(GST_DIR) -cJf $(GST_DIR)/gst-plugins-good1.0_1.12.2+imx.orig.tar.xz gst-plugins-good1.0_1.12.2+imx
	rsync -r $(ROOTDIR)/packages/imx-gst-plugins-good/debian/ $(GST_DIR)/gst-plugins-good1.0_1.12.2+imx/debian/
	docker load -i $(ROOTDIR)/cache/arm64-builder.tar
	docker run --rm --privileged --tty \
	  -v $(PRODUCT_OUT):/out \
	  -v $(GST_DIR):/gst arm64-builder \
	  /bin/bash -c '\
		dpkg -i /out/linux-headers-4.9.51-aiy_1_arm64.deb; \
		dpkg -i /out/libgstreamer1.0-0_1.12.2+imx-0_arm64.deb; \
		dpkg -i /out/aux/gir1.2-gstreamer-1.0_1.12.2+imx-0_arm64.deb; \
		dpkg -i /out/dev/libgstreamer1.0-dev_1.12.2+imx-0_arm64.deb; \
		dpkg -i /out/libgstreamer-plugins-base1.0-0_1.12.2+imx-0_arm64.deb; \
		dpkg -i /out/gstreamer1.0-plugins-base_1.12.2+imx-0_arm64.deb; \
		dpkg -i /out/aux/gir1.2-gst-plugins-base-1.0_1.12.2+imx-0_arm64.deb; \
		dpkg -i /out/dev/libgstreamer-plugins-base1.0-dev_1.12.2+imx-0_arm64.deb; \
		cd /gst/gst-plugins-good1.0_1.12.2+imx; \
		DEB_COPYRIGHT_CHECK_LICENSECHECK=/nope dpkg-buildpackage -uc -us -tc;'
endif
	cp $(addprefix $(GST_DIR)/,$(GST_P_GOOD_DEBS)) $(PRODUCT_OUT)
	cp $(addprefix $(GST_DIR)/,$(GST_P_GOOD_DEBS_AUX)) $(PRODUCT_OUT)/aux

$(GST_P_BAD_TARGETS): libdrm-imx $(GST_P_BASE_TARGETS) $(KERNEL_DEB) wayland-protocols-imx $(ROOTDIR)/cache/arm64-builder.tar
ifeq ($(call stat_files,$(addprefix $(GST_DIR)/,$(GST_P_BAD_DEBS) $(GST_P_BAD_DEBS_DEV) $(GST_P_BAD_DEBS_AUX))),0)
	$(info $@ already built, not rebuilding)
else
	$(info building $@)
	mkdir -p $(PRODUCT_OUT)/dev
	mkdir -p $(PRODUCT_OUT)/aux
	mkdir -p $(GST_DIR)
	cd $(ROOTDIR)/imx-gst-plugins-bad; git submodule init; git submodule update;
	rsync -r $(ROOTDIR)/imx-gst-plugins-bad/ $(GST_DIR)/gst-plugins-bad1.0_1.12.2+imx/
	tar -C $(GST_DIR) -cJf $(GST_DIR)/gst-plugins-bad1.0_1.12.2+imx.orig.tar.xz gst-plugins-bad1.0_1.12.2+imx
	rsync -r $(ROOTDIR)/packages/imx-gst-plugins-bad/debian/ $(GST_DIR)/gst-plugins-bad1.0_1.12.2+imx/debian/
	docker load -i $(ROOTDIR)/cache/arm64-builder.tar
	docker run --rm --privileged --tty \
	  -v $(PRODUCT_OUT):/out \
	  -v $(GST_DIR):/gst arm64-builder \
	  /bin/bash -c '\
		dpkg -i /out/wayland-protocols-imx_1.13-0_all.deb; \
		dpkg -i /out/libdrm2_2.4.84+imx-0_arm64.deb /out/libdrm-vivante_2.4.84+imx-0_arm64.deb; \
		dpkg -i /out/libdrm-dev_2.4.84+imx-0_arm64.deb; \
		dpkg -i /out/linux-headers-4.9.51-aiy_1_arm64.deb; \
		dpkg -i /out/libgstreamer1.0-0_1.12.2+imx-0_arm64.deb; \
		dpkg -i /out/aux/gir1.2-gstreamer-1.0_1.12.2+imx-0_arm64.deb; \
		dpkg -i /out/dev/libgstreamer1.0-dev_1.12.2+imx-0_arm64.deb; \
		dpkg -i /out/libgstreamer-plugins-base1.0-0_1.12.2+imx-0_arm64.deb; \
		dpkg -i /out/gstreamer1.0-plugins-base_1.12.2+imx-0_arm64.deb; \
		dpkg -i /out/aux/gir1.2-gst-plugins-base-1.0_1.12.2+imx-0_arm64.deb; \
		dpkg -i /out/dev/libgstreamer-plugins-base1.0-dev_1.12.2+imx-0_arm64.deb; \
		cp /usr/src/linux-headers-4.9.51-aiy/include/uapi/linux/mxcfb.h /usr/include/linux; \
		cp /usr/src/linux-headers-4.9.51-aiy/include/uapi/linux/ion.h /usr/include/linux; \
		cp /usr/src/linux-headers-4.9.51-aiy/include/uapi/linux/ipu.h /usr/include/linux; \
		cp /usr/src/linux-headers-4.9.51-aiy/include/uapi/linux/mxc_v4l2.h /usr/include/linux; \
		cd /gst/gst-plugins-bad1.0_1.12.2+imx; \
		DEB_COPYRIGHT_CHECK_LICENSECHECK=/nope dpkg-buildpackage -uc -us -tc;'
endif
	cp $(addprefix $(GST_DIR)/,$(GST_P_BAD_DEBS)) $(PRODUCT_OUT)
	cp $(addprefix $(GST_DIR)/,$(GST_P_BAD_DEBS_DEV)) $(PRODUCT_OUT)/dev
	cp $(addprefix $(GST_DIR)/,$(GST_P_BAD_DEBS_AUX)) $(PRODUCT_OUT)/aux

$(GST_P_IMX_TARGETS): libdrm-imx imx-vpu-hantro imx-vpuwrap $(GST_P_BASE_TARGETS) $(GST_P_BAD_TARGETS) $(KERNEL_DEB) $(ROOTDIR)/cache/arm64-builder.tar
ifeq ($(call stat_files,$(addprefix $(GST_DIR)/,$(GST_P_IMX_DEBS))),0)
	$(info $@ already built, not rebuilding)
else
	$(info building $@)
	mkdir -p $(PRODUCT_OUT)/dev
	mkdir -p $(PRODUCT_OUT)/aux
	mkdir -p $(GST_DIR)
	rsync -r $(ROOTDIR)/imx-gst1.0-plugin/ $(GST_DIR)/imx-gst1.0-plugin_4.3.4/
	tar -C $(GST_DIR) -cJf $(GST_DIR)/imx-gst1.0-plugin_4.3.4.orig.tar.xz imx-gst1.0-plugin_4.3.4
	rsync -r $(ROOTDIR)/packages/imx-gst1.0-plugin/debian/ $(GST_DIR)/imx-gst1.0-plugin_4.3.4/debian/
	docker load -i $(ROOTDIR)/cache/arm64-builder.tar
	docker run --rm --privileged --tty \
	  -v $(PRODUCT_OUT):/out \
	  -v $(GST_DIR):/gst arm64-builder \
	  /bin/bash -c '\
		dpkg -i /out/libdrm2_2.4.84+imx-0_arm64.deb /out/libdrm-vivante_2.4.84+imx-0_arm64.deb; \
		dpkg -i /out/libdrm-dev_2.4.84+imx-0_arm64.deb; \
		dpkg -i /out/imx-vpu-hantro_1.6.0-0_arm64.deb out/imx-vpu-hantro-dev_1.6.0-0_arm64.deb; \
		dpkg -i /out/imx-vpuwrap_4.3.4-0_arm64.deb out/imx-vpuwrap-dev_4.3.4-0_arm64.deb; \
		dpkg -i /out/linux-headers-4.9.51-aiy_1_arm64.deb; \
		dpkg -i /out/libgstreamer1.0-0_1.12.2+imx-0_arm64.deb; \
		dpkg -i /out/aux/gir1.2-gstreamer-1.0_1.12.2+imx-0_arm64.deb; \
		dpkg -i /out/dev/libgstreamer1.0-dev_1.12.2+imx-0_arm64.deb; \
		dpkg -i /out/libgstreamer-plugins-base1.0-0_1.12.2+imx-0_arm64.deb; \
		dpkg -i /out/gstreamer1.0-plugins-base_1.12.2+imx-0_arm64.deb; \
		dpkg -i /out/aux/gir1.2-gst-plugins-base-1.0_1.12.2+imx-0_arm64.deb; \
		dpkg -i /out/dev/libgstreamer-plugins-base1.0-dev_1.12.2+imx-0_arm64.deb; \
		dpkg -i /out/libgstreamer-plugins-bad1.0-0_1.12.2+imx-0_arm64.deb; \
		dpkg -i /out/gstreamer1.0-plugins-bad_1.12.2+imx-0_arm64.deb; \
		dpkg -i /out/aux/gir1.2-gst-plugins-bad-1.0_1.12.2+imx-0_arm64.deb; \
		dpkg -i /out/dev/libgstreamer-plugins-bad1.0-dev_1.12.2+imx-0_arm64.deb; \
		cp /usr/src/linux-headers-4.9.51-aiy/include/uapi/linux/mxcfb.h /usr/include/linux; \
		cp /usr/src/linux-headers-4.9.51-aiy/include/uapi/linux/ion.h /usr/include/linux; \
		cp /usr/src/linux-headers-4.9.51-aiy/include/uapi/linux/ipu.h /usr/include/linux; \
		cp /usr/src/linux-headers-4.9.51-aiy/include/uapi/linux/mxc_v4l2.h /usr/include/linux; \
		cd /gst/imx-gst1.0-plugin_4.3.4; \
		dpkg-buildpackage -uc -us;'
endif
	cp $(addprefix $(GST_DIR)/,$(GST_P_IMX_DEBS)) $(PRODUCT_OUT)
