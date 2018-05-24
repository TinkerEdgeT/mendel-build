# Preamble. Don't define any targets in this file! This is effectively just a
# common header where useful global vars go.

# Globally useful directories
TOOLCHAIN := $(ROOTDIR)/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-

# Used by debootstrap and rootfs both
DEBOOTSTRAP_TARBALL := $(ROOTDIR)/cache/debootstrap.tgz
DEBOOTSTRAP_TARBALL_SHA256 := $(ROOTDIR)/cache/debootstrap.tgz.sha256sum

DEBOOTSTRAP_EXTRA := \
	avahi-daemon \
	bluez \
	dbus \
	debian-archive-keyring \
	dialog \
	firmware-atheros \
	isc-dhcp-client \
	less \
	libpam-systemd \
	locales \
	lxde \
	man-db \
	net-tools \
	network-manager \
	openbox-lxde-session \
	openssh-server \
	parted \
	pulseaudio \
	sudo \
	systemd \
	systemd-sysv \
	tasksel \
	vim \
	wireless-tools \
	xorg \
	xserver-xorg-video-all \
	xserver-xorg-input-all \
	wpasupplicant

DEBOOTSTRAP_ARGS := \
		--arch=arm64 \
		--keyring /usr/share/keyrings/debian-archive-keyring.gpg \
		--variant=buildd \
		--components=main,non-free \
		--exclude=debfoster \
		--include=$$(echo $(DEBOOTSTRAP_EXTRA) |tr ' ' ',') \
