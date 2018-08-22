# Preamble. Don't define any targets in this file! This is effectively just a
# common header where useful global vars go.

# Globally useful directories
TOOLCHAIN := $(ROOTDIR)/toolchains/aarch64-linux-android/bin/aarch64-linux-android-

# Kernel directories and options
KERNEL_SRC_DIR := $(ROOTDIR)/linux-imx
KERNEL_OUT_DIR := $(PRODUCT_OUT)/obj/KERNEL_OBJ
KERNEL_OPTIONS := ARCH=arm64 CROSS_COMPILE=$(TOOLCHAIN) LOCALVERSION=-aiy

# Used by debootstrap and rootfs both
DEBOOTSTRAP_TARBALL := $(ROOTDIR)/cache/debootstrap.tgz
DEBOOTSTRAP_TARBALL_SHA256 := $(ROOTDIR)/cache/debootstrap.tgz.sha256sum

FETCH_PBUILDER_DIRECTORY ?= /google/data/ro/teams/spacepark/enterprise/kokoro/prod/spacepark/enterprise/pbuilder
FETCH_PBUILDER_BASE ?= true

DEBOOTSTRAP_EXTRA := \
	alsa-utils \
	apt-listchanges \
	apt-utils \
	aptitude \
	avahi-daemon \
	bash-completion \
	bluez \
	cpio \
	cron \
	dbus \
	debconf-i18n \
	debian-archive-keyring \
	debian-faq \
	dialog \
	dmidecode \
	dnsmasq \
	doc-debian \
	ethtool \
	file \
	firmware-atheros \
	gettext-base \
	gnupg \
	hdparm \
	i2c-tools \
	ifupdown \
	init \
	iptables \
	iputils-ping \
	isc-dhcp-client \
	isc-dhcp-common \
	kbd \
	krb5-locales \
	less \
	libc++1 \
	libc++abi1 \
	libclass-isa-perl \
	libinput10 \
	liblockfile-bin \
	libpam-systemd \
	libswitch-perl \
	libwayland-cursor0 \
	libwayland-egl1-mesa \
	libxcb-composite0 \
	libxcb-shape0 \
	libxcursor1 \
	libxkbcommon0 \
	linux-base \
	lm-sensors \
	locales \
	logrotate \
	lrzsz \
	lsof \
	man-db \
	manpages \
	nano \
	ncurses-term \
	net-tools \
	netbase \
	netcat-traditional \
	network-manager \
	openssh-server \
	parted \
	pciutils \
	psmisc \
	pulseaudio \
	python \
	python-minimal \
	python2.7 \
	python3-reportbug \
	reportbug \
	rsync \
	rsyslog \
	sudo \
	systemd \
	systemd-sysv \
	tasksel \
	telnet \
	traceroute \
	v4l-utils \
	vim \
	wamerican \
	wget \
	whiptail \
	wireless-tools \
	wpasupplicant \
	xdg-user-dirs \
	xwayland

DEBOOTSTRAP_ARGS := \
		--arch=arm64 \
		--keyring /usr/share/keyrings/debian-archive-keyring.gpg \
		--variant=buildd \
		--components=main,non-free \
		--exclude=debfoster \
		--include=$$(echo $(DEBOOTSTRAP_EXTRA) |tr ' ' ',') \

TARBALL_FETCH_ROOT_DIRECTORY ?= \
	/google/data/ro/teams/spacepark/enterprise/kokoro/prod/spacepark/enterprise/rootfs

PREBUILT_DOCKER_ROOT ?= /google/data/ro/teams/spacepark/enterprise/kokoro/prod/spacepark/enterprise/docker

DEBCACHE_ROOT ?= /google/data/rw/teams/spacepark/enterprise/kokoro/prod/spacepark/enterprise/debcache
