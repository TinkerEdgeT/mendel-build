ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

REQUIRED_PACKAGES := \
	bc \
	build-essential \
	binfmt-support \
	debian-archive-keyring \
	debootstrap \
	device-tree-compiler \
	fakeroot \
	kernel-package \
	kpartx \
	mtools \
	parted \
	qemu-user-static \
	rsync \
	xz-utils

prereqs:
	sudo apt-get install -y $(REQUIRED_PACKAGES)

targets::
	@echo "prereqs    - installs packages required by this Makefile"

.PHONY:: prereqs
