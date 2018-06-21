ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

PACKAGES_DIRS := $(wildcard $(ROOTDIR)/packages/*)
PACKAGES := $(foreach package,$(PACKAGES_DIRS),$(notdir $(package)))

define make-package-target
$1: $(PRODUCT_OUT)/.$1
$(PRODUCT_OUT)/.$1: $(shell find $(ROOTDIR)/packages/$1 -type f)
	cd $(ROOTDIR)/packages/$1; dpkg-buildpackage -b -rfakeroot -us -uc -tc
	mv $(ROOTDIR)/packages/$1_* $(PRODUCT_OUT)/
	touch $(PRODUCT_OUT)/.$1
endef

$(foreach package,$(PACKAGES),$(eval $(call make-package-target,$(package))))

packages:: $(foreach package,$(PACKAGES),$(PRODUCT_OUT)/.$(package))
.PHONY:: packages