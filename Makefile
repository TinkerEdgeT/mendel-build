ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

precheck:
	+make -f $(ROOTDIR)/build/Makefile validate-bootstrap-tarball
	+make -f $(ROOTDIR)/build/Makefile all

all: boot-targets partition-table rootfs

# We explicitly sequence these since they cannot be properly parallelized. The
# u-boot and kernel build systems, in particular, do not play well as they share
# some files.
boot-targets:
	+make -f $(ROOTDIR)/build/Makefile u-boot
	+make -f $(ROOTDIR)/build/Makefile kernel
	+make -f $(ROOTDIR)/build/Makefile boot

help: targets
targets::
	@echo "Tagets available for building in this Makefile:"
	@echo

include $(ROOTDIR)/build/boot.mk
include $(ROOTDIR)/build/debootstrap.mk
include $(ROOTDIR)/build/img2simg.mk
include $(ROOTDIR)/build/kernel.mk
include $(ROOTDIR)/build/partition-table.mk
include $(ROOTDIR)/build/prereqs.mk
include $(ROOTDIR)/build/rootfs.mk
include $(ROOTDIR)/build/sdcard.mk
include $(ROOTDIR)/build/u-boot.mk

clean::
	rm -rf $(ROOTDIR)/out

.PHONY:: all help targets clean boot-targets
