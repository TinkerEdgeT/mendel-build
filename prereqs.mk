ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

REQUIRED_PACKAGES := \
	bc \
	binutils-aarch64-linux-gnu \
	build-essential \
	binfmt-support \
	coreutils \
	debhelper \
	debian-archive-keyring \
	debootstrap \
	device-tree-compiler \
	equivs \
	fakeroot \
	genext2fs \
	kpartx \
	libcap-dev \
	libwayland-dev \
	mtools \
	parted \
	pkg-config \
	python-minimal \
	python2.7 \
	python3 \
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
