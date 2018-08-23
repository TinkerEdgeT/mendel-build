ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

EQUIVS_PACKAGE_NAMES := $(notdir $(shell find $(ROOTDIR)/packages/equivs -maxdepth 1 -type f))

ALL_PACKAGE_NAMES := $(EQUIVS_PACKAGE_NAMES)

BUILDPACKAGE_CMD := dpkg-buildpackage -b -rfakeroot -us -uc -tc

define make-equivs-package-target
$(PRODUCT_OUT)/.$1: $(ROOTDIR)/packages/equivs/$1
	cd $(PRODUCT_OUT); equivs-build $$<
	touch $$@
endef

ifeq ($(FETCH_PBUILDER_BASE),true)
$(ROOTDIR)/cache/base.tgz: $(FETCH_PBUILDER_DIRECTORY)/base.tgz
	mkdir -p $(ROOTDIR)/cache
	cp $< $(ROOTDIR)/cache
else
$(ROOTDIR)/cache/base.tgz:
	mkdir -p $(ROOTDIR)/cache
	sudo pbuilder create \
		--basetgz $@ \
		--mirror http://http.us.debian.org/debian \
		--distribution stretch \
		--architecture arm64 \
		--extrapackages debhelper
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
# $3: space separated list of dependencies (may be empty)
define make-pbuilder-package-target
$1: $(PRODUCT_OUT)/.$1-pbuilder
PBUILDER_TARGETS += $1
$(PRODUCT_OUT)/.$1-pbuilder: \
	$(foreach package,$3,$(PRODUCT_OUT)/.$(package)-pbuilder) \
	$(shell find $(ROOTDIR)/packages/$1 -type f) \
	| $(ROOTDIR)/cache/base.tgz

	mkdir -p $(PRODUCT_OUT)/obj/$1
	rsync -rl --exclude .git/ $(ROOTDIR)/$2/* $(PRODUCT_OUT)/obj/$1
	cp -r $(ROOTDIR)/packages/$1/debian $(PRODUCT_OUT)/obj/$1
	tar -C $(PRODUCT_OUT)/obj --exclude=debian/ -cJf \
		$(PRODUCT_OUT)/obj/$1_$(call get-deb-version-orig,$1).orig.tar.xz \
		$1
	tar -C $(PRODUCT_OUT)/obj/$1 -cJf \
		$(PRODUCT_OUT)/obj/$1_$(call get-deb-version-full,$1).debian.tar.xz \
		debian

	cd $(PRODUCT_OUT)/obj/$1; pdebuild \
		--buildresult $(PRODUCT_OUT) -- \
		--basetgz $(ROOTDIR)/cache/base.tgz \
		--configfile $(ROOTDIR)/build/pbuilderrc \
		--hookdir $(ROOTDIR)/build/pbuilder-hooks
	sudo touch $(PRODUCT_OUT)/.$1-pbuilder
.PHONY:: $1
endef

# Generate EQUIVS targets
$(foreach package,$(EQUIVS_PACKAGE_NAMES),$(eval $(call make-equivs-package-target,$(package))))

$(eval $(call make-pbuilder-package-target,imx-atf,imx-atf))
$(eval $(call make-pbuilder-package-target,imx-firmware,imx-firmware))
$(eval $(call make-pbuilder-package-target,imx-mkimage,tools/imx-mkimage))
$(eval $(call make-pbuilder-package-target,uboot-imx,uboot-imx,imx-atf imx-firmware imx-mkimage))

$(eval $(call make-pbuilder-package-target,wayland-protocols-imx,wayland-protocols-imx))
$(eval $(call make-pbuilder-package-target,weston-imx,weston-imx,wayland-protocols-imx))

$(eval $(call make-pbuilder-package-target,imx-gpu-viv,packages/imx-gpu-viv))

$(eval $(call make-pbuilder-package-target,aiy-board-audio,packages/aiy-board-audio))
$(eval $(call make-pbuilder-package-target,aiy-board-gadget,packages/aiy-board-gadget))
$(eval $(call make-pbuilder-package-target,aiy-board-keyring,packages/aiy-board-keyring))
$(eval $(call make-pbuilder-package-target,aiy-board-tools,packages/aiy-board-tools))
$(eval $(call make-pbuilder-package-target,aiy-board-wlan,packages/aiy-board-wlan))

packages:: $(foreach package,$(ALL_PACKAGE_NAMES),$(PRODUCT_OUT)/.$(package)) $(PBUILDER_TARGETS)

.PHONY:: packages
