ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

REQUIRED_MODULES := apex

MODULES_DIRS := $(wildcard $(ROOTDIR)/modules/*)
MODULES := $(foreach module,$(MODULES_DIRS),$(notdir $(module)))
MODULES := $(sort $(MODULES) $(REQUIRED_MODULES))

PREBUILT_MODULES_ROOT ?= /google/data/ro/teams/spacepark/enterprise/debs

define make-module-target
$1: $(PRODUCT_OUT)/.$1
ifeq (,$$(wildcard $(ROOTDIR)/modules/$1/*))
$(PRODUCT_OUT)/.$1: $(PRODUCT_OUT)
	$$(warning "No source for $1")
	cp $(PREBUILT_MODULES_ROOT)/$1.deb $(PRODUCT_OUT)
else
$(PRODUCT_OUT)/.$1: $(shell find $(ROOTDIR)/modules/$1 -type f) $(KERNEL_OUT_DIR)/.config $(KERNEL_OUT_DIR)/arch/arm64/boot/Image
	mkdir -p $(PRODUCT_OUT)/obj/MODULE_OBJ/$1/debian
	cp -afs $(ROOTDIR)/modules/$1/* $(PRODUCT_OUT)/obj/MODULE_OBJ/$1
	cp -r $(ROOTDIR)/build/$1-debian/* $(PRODUCT_OUT)/obj/MODULE_OBJ/$1/debian/
	+cd $(PRODUCT_OUT)/obj/MODULE_OBJ/$1; \
		DEB_HOST_ARCH=arm64 \
		ROOT_CMD=fakeroot \
		$(KERNEL_OPTIONS) \
		KSRC=$(KERNEL_SRC_DIR) \
		KOUT=$(KERNEL_OUT_DIR) \
		debian/rules kdist_image
	touch $(PRODUCT_OUT)/.$1
endif
endef

$(foreach module,$(MODULES),$(eval $(call make-module-target,$(module))))

modules:: $(foreach module,$(MODULES),$(PRODUCT_OUT)/.$(module))
.NOTPARALLEL: modules
.PHONY:: modules
