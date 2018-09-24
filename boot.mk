ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

boot: $(PRODUCT_OUT)/boot.img

$(PRODUCT_OUT)/boot.img:
	fallocate -l $(BOOT_SIZE_MB)M $@
	mkfs.ext2 -F $@

targets::
	@echo "boot - builds the kernel and boot partition"

clean::
	rm -f $(PRODUCT_OUT)/boot.img

.PHONY:: boot
