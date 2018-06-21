ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

MODULES_DIRS := $(wildcard $(ROOTDIR)/modules/*)
MODULES := $(foreach module,$(MODULES_DIRS),$(notdir $(module)))

define make-module-target
$1: $(PRODUCT_OUT)/.$1
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
endef

$(foreach module,$(MODULES),$(eval $(call make-module-target,$(module))))

modules:: $(foreach module,$(MODULES),$(PRODUCT_OUT)/.$(module))
.PHONY:: modules