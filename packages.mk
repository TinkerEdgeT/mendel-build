ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

# Packages which will run on any architecture.
ALLARCH_PACKAGE_NAMES := \
		 aiy-board-audio \
		 aiy-board-gadget \
		 aiy-board-keyring \
		 aiy-board-tools \
		 aiy-board-wlan

# Packages which require ARM64 binaries to be built.
ARM64_PACKAGE_NAMES := \
		imx-gpu-viv

EQUIVS_PACKAGE_NAMES := $(notdir $(shell find $(ROOTDIR)/packages/equivs -maxdepth 1 -type f))

ALL_PACKAGE_NAMES := $(ALLARCH_PACKAGE_NAMES) $(ARM64_PACKAGE_NAMES) $(EQUIVS_PACKAGE_NAMES)

BUILDPACKAGE_CMD := dpkg-buildpackage -b -rfakeroot -us -uc -tc

define make-package-target
	find $(ROOTDIR)/packages -maxdepth 1 -type f -name '$1*' -exec mv -f {} $(PRODUCT_OUT) \;
	touch $(PRODUCT_OUT)/.$1
endef

define make-allarch-package-target
$(PRODUCT_OUT)/.$1: $$(shell find $(ROOTDIR)/packages/$1 -type f)
	cd $(ROOTDIR)/packages/$1; $(BUILDPACKAGE_CMD)
$(call make-package-target,$1)
endef

define make-arm64-package-target
$(PRODUCT_OUT)/.$1: $$(shell find $(ROOTDIR)/packages/$1 -type f) $(ROOTDIR)/cache/arm64-builder.tar
	docker load -i $(ROOTDIR)/cache/arm64-builder.tar
	docker run --rm --tty \
	  -v $(ROOTDIR)/packages:/packages arm64-builder \
	  /bin/bash -c 'cd /packages/$1; $(BUILDPACKAGE_CMD);'
$(call make-package-target,$1)
endef

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

	cd $(PRODUCT_OUT)/obj/$1; pdebuild \
		--buildresult $(PRODUCT_OUT) -- \
		--basetgz $(ROOTDIR)/cache/base.tgz
	sudo touch $(PRODUCT_OUT)/.$1-pbuilder
.PHONY:: $1
endef

# Generate ARM64 targets
$(foreach package,$(ARM64_PACKAGE_NAMES),$(eval $(call make-arm64-package-target,$(package))))

# Generate ALL arch targets
$(foreach package,$(ALLARCH_PACKAGE_NAMES),$(eval $(call make-allarch-package-target,$(package))))

# Generate EQUIVS targets
$(foreach package,$(EQUIVS_PACKAGE_NAMES),$(eval $(call make-equivs-package-target,$(package))))

$(eval $(call make-pbuilder-package-target,imx-atf,imx-atf))
$(eval $(call make-pbuilder-package-target,imx-firmware,imx-firmware))
$(eval $(call make-pbuilder-package-target,imx-mkimage,tools/imx-mkimage))
$(eval $(call make-pbuilder-package-target,uboot-imx,uboot-imx,imx-atf imx-firmware imx-mkimage))

packages:: $(foreach package,$(ALL_PACKAGE_NAMES),$(PRODUCT_OUT)/.$(package)) $(PBUILDER_TARGETS)

.PHONY:: packages
