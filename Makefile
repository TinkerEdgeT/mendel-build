SHELL := $(shell which /bin/bash)

ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

precheck:
	+make -f $(ROOTDIR)/build/Makefile validate-bootstrap-tarball
	+make -f $(ROOTDIR)/build/Makefile all

$(PRODUCT_OUT):
	mkdir -p $(PRODUCT_OUT)

all: boot-targets

# We explicitly sequence these since they cannot be properly parallelized. The
# u-boot and kernel build systems, in particular, do not play well together for
# various odd reasons (duplicate targets such as depcheck, etc.)
boot-targets:
	+make -f $(ROOTDIR)/build/Makefile u-boot
	+make -f $(ROOTDIR)/build/Makefile kernel
	+make -f $(ROOTDIR)/build/Makefile boot
	+make -f $(ROOTDIR)/build/Makefile partition-table
	+make -f $(ROOTDIR)/build/Makefile rootfs

help: targets
targets::
	@echo "Tagets available for building in this Makefile:"
	@echo

include $(ROOTDIR)/build/boot.mk
include $(ROOTDIR)/build/debootstrap.mk
include $(ROOTDIR)/build/gpu.mk
include $(ROOTDIR)/build/img2simg.mk
include $(ROOTDIR)/build/kernel.mk
include $(ROOTDIR)/build/kernel-modules.mk
include $(ROOTDIR)/build/partition-table.mk
include $(ROOTDIR)/build/prereqs.mk
include $(ROOTDIR)/build/rootfs.mk
include $(ROOTDIR)/build/sdcard.mk
include $(ROOTDIR)/build/signing.mk
include $(ROOTDIR)/build/u-boot.mk

include $(ROOTDIR)/build/docker.mk
include $(ROOTDIR)/build/packages.mk

clean::
	rm -rf $(ROOTDIR)/out

.PHONY:: all help targets clean boot-targets
