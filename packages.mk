ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

ifeq ($(FETCH_PBUILDER_BASE),true)
$(ROOTDIR)/cache/base.tgz: $(FETCH_PBUILDER_DIRECTORY)/base.tgz | out-dirs
	cp $< $(ROOTDIR)/cache
else
$(ROOTDIR)/cache/base.tgz: /usr/bin/qemu-aarch64-static
	mkdir -p $(ROOTDIR)/cache
	sudo pbuilder create \
		--basetgz $@ \
		--mirror http://http.us.debian.org/debian \
		--distribution stretch \
		--architecture amd64 \
		--extrapackages crossbuild-essential-arm64 debhelper
	mkdir -p $(ROOTDIR)/cache/base-tmp
	cd $(ROOTDIR)/cache/base-tmp; \
	sudo tar xf $@; \
	sudo cp /usr/bin/qemu-aarch64-static usr/bin; \
	sudo tar cf base.tar .; \
	gzip base.tar; mv -f base.tar.gz $@
	sudo rm -rf $(ROOTDIR)/cache/base-tmp
endif

# $1 package name
define get-deb-version-orig
$(shell head -n1 $(ROOTDIR)/packages/$1/debian/changelog | awk '{split ($$2,a,"-"); print a[1]}' | tr -d '()')
endef

define get-deb-version-full
$(shell head -n1 $(ROOTDIR)/packages/$1/debian/changelog | awk '{print $$2}' | tr -d '()')
endef

# $1: package name
# $2: source location (relative to ROOTDIR)
# $3: space separated list of package dependencies (may be empty)
# $4: space separated list of external dependencies (may be empty)
# $5: dpkg-buildpackage --build value (may be empty, defaults to full)
define make-pbuilder-package-target
$1: $(PRODUCT_OUT)/.$1-pbuilder
PBUILDER_TARGETS += $(PRODUCT_OUT)/.$1-pbuilder

ifneq (,$(wildcard $(ROOTDIR)/packages/$1))
$(PRODUCT_OUT)/.$1-pbuilder: \
	$(foreach package,$3,$(PRODUCT_OUT)/.$(package)-pbuilder) \
	$$(shell find $(ROOTDIR)/packages/$1 -type f) \
	$$(shell find $(ROOTDIR)/$2 -type f | sed -e 's/ /\\ /g') \
	| out-dirs $(ROOTDIR)/cache/base.tgz \
	$4

	$(ROOTDIR)/build/update_packages.sh
	cd $(ROOTDIR)/$2; git submodule init; git submodule update;
	rm -rf $(PRODUCT_OUT)/obj/$1
	mkdir -p $(PRODUCT_OUT)/obj/$1
	rsync -rl --exclude .git/ $(ROOTDIR)/$2/* $(PRODUCT_OUT)/obj/$1
	cp -r $(ROOTDIR)/packages/$1/debian $(PRODUCT_OUT)/obj/$1
	tar -C $(PRODUCT_OUT)/obj --exclude=debian/ -czf \
		$(PRODUCT_OUT)/obj/$1_$$(call get-deb-version-orig,$1).orig.tar.gz \
		$1
	tar -C $(PRODUCT_OUT)/obj/$1 -czf \
		$(PRODUCT_OUT)/obj/$1_$$(call get-deb-version-full,$1).debian.tar.gz \
		debian

	cd $(PRODUCT_OUT)/obj/$1; pdebuild \
		--buildresult $(PRODUCT_OUT)/packages -- \
		--debbuildopts "--build=$(if $5,$5,full)" \
		--basetgz $(ROOTDIR)/cache/base.tgz \
		--configfile $(ROOTDIR)/build/pbuilderrc \
		--hookdir $(ROOTDIR)/build/pbuilder-hooks \
		--host-arch arm64 --logfile $(PRODUCT_OUT)/$1.log
else
$(PRODUCT_OUT)/.$1-pbuilder: \
	| out-dirs \
	$(PACKAGES_FETCH_ROOT_DIRECTORY)/$(PACKAGES_REVISION)/packages.tgz
	tar -C $(PRODUCT_OUT) --wildcards -xf \
		$(PACKAGES_FETCH_ROOT_DIRECTORY)/$(PACKAGES_REVISION)/packages.tgz \
		packages/$1*.deb
	$(ROOTDIR)/build/update_packages.sh
endif
	touch $(PRODUCT_OUT)/.$1-pbuilder
.PHONY:: $1
endef

$(eval $(call make-pbuilder-package-target,imx-atf,imx-atf))
$(eval $(call make-pbuilder-package-target,imx-firmware,imx-firmware))
$(eval $(call make-pbuilder-package-target,imx-mkimage,tools/imx-mkimage))
$(eval $(call make-pbuilder-package-target,uboot-imx,uboot-imx,imx-atf imx-firmware imx-mkimage))

$(eval $(call make-pbuilder-package-target,wayland-protocols-imx,wayland-protocols-imx))
$(eval $(call make-pbuilder-package-target,weston-imx,weston-imx,wayland-protocols-imx))

$(eval $(call make-pbuilder-package-target,imx-gpu-viv,imx-gpu-viv,,kernel-deb,binary))
$(eval $(call make-pbuilder-package-target,libdrm-imx,libdrm-imx))
$(eval $(call make-pbuilder-package-target,imx-vpu-hantro,imx-vpu-hantro,,kernel-deb,binary))
$(eval $(call make-pbuilder-package-target,imx-vpuwrap,imx-vpuwrap,imx-vpu-hantro,,binary))
$(eval $(call make-pbuilder-package-target,imx-gstreamer,imx-gstreamer))
$(eval $(call make-pbuilder-package-target,imx-gst-plugins-base,imx-gst-plugins-base,imx-gstreamer))
$(eval $(call make-pbuilder-package-target,imx-gst-plugins-good,imx-gst-plugins-good,imx-gst-plugins-base))
$(eval $(call make-pbuilder-package-target,imx-gst-plugins-bad,imx-gst-plugins-bad,\
	libdrm-imx imx-gst-plugins-base,kernel-deb))
$(eval $(call make-pbuilder-package-target,imx-gst1.0-plugin,imx-gst1.0-plugin,\
	imx-vpuwrap imx-gst-plugins-bad))

$(eval $(call make-pbuilder-package-target,aiy-board-audio,packages/aiy-board-audio))
$(eval $(call make-pbuilder-package-target,aiy-board-gadget,packages/aiy-board-gadget))
$(eval $(call make-pbuilder-package-target,aiy-board-keyring,packages/aiy-board-keyring))
$(eval $(call make-pbuilder-package-target,aiy-board-tools,packages/aiy-board-tools))
$(eval $(call make-pbuilder-package-target,aiy-board-tweaks,packages/aiy-board-tweaks))
$(eval $(call make-pbuilder-package-target,aiy-board-wlan,packages/aiy-board-wlan))

$(eval $(call make-pbuilder-package-target,bluez-imx,bluez-imx))

$(eval $(call make-pbuilder-package-target,base-files,packages/base-files))

$(eval $(call make-pbuilder-package-target,libedgetpu,libedgetpu))
$(eval $(call make-pbuilder-package-target,edgetpu-api,packages/edgetpu-api,libedgetpu))

ALL_PACKAGE_TARGETS := $(PBUILDER_TARGETS)
packages-tarball: $(ROOTDIR)/cache/packages.tgz
$(info )
ifeq ($(FETCH_PACKAGES),true)
$(info Using prebuilt packages, set FETCH_PACKAGES=false to build locally)
$(ROOTDIR)/cache/packages.tgz: $(PACKAGES_FETCH_ROOT_DIRECTORY)/$(ROOTFS_REVISION)/packages.tgz | out-dirs
	cp $< $(ROOTDIR)/cache
else
$(info Building packages locally, set FETCH_PACKAGES=true to use prebuilts)
$(ROOTDIR)/cache/packages.tgz: $(ALL_PACKAGE_TARGETS) | out-dirs
	$(ROOTDIR)/build/update_packages.sh
	tar -C $(PRODUCT_OUT) -czf $@ packages
endif
$(info )

packages:: $(ALL_PACKAGE_TARGETS)

.PHONY:: packages
