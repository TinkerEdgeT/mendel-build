ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

REQUIRED_PACKAGES := \
	apt-utils \
	bc \
	binutils-aarch64-linux-gnu \
	build-essential \
	binfmt-support \
	cdbs \
	coreutils \
	debhelper \
	debian-archive-keyring \
	debootstrap \
	device-tree-compiler \
	fakeroot \
	genext2fs \
	git \
	gnome-pkg-tools \
	kpartx \
	libcap-dev \
	libwayland-dev \
	mtools \
	parted \
	pbuilder \
	pkg-config \
	python-minimal \
	python2.7 \
	python3 \
	python3-setuptools \
	qemu-user-static \
	quilt \
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
