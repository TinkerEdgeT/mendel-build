ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

REQUIRED_PACKAGES := \
	qemu-user-static \
	debootstrap \
	debian-archive-keyring \
	parted \
	kpartx \
	rsync \
	xz-utils

prereqs:
	sudo apt-get install $(REQUIRED_PACKAGES)

targets::
	@echo "prereqs    - installs packages required by this Makefile"

.PHONY:: prereqs
