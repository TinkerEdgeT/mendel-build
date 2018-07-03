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
	genext2fs \
	kernel-package \
	kpartx \
	mtools \
	parted \
	qemu-user-static \
	reprepro \
	rsync \
	xz-utils \
	zlib1g-dev

prereqs:
	sudo apt-get update
	sudo apt-get install --no-install-recommends -y $(REQUIRED_PACKAGES)

targets::
	@echo "prereqs    - installs packages required by this Makefile"

.PHONY:: prereqs
