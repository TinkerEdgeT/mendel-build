# Preamble. Don't define any targets in this file! This is effectively just a
# common header where useful global vars go.

# Globally useful directories
TOOLCHAIN := $(ROOTDIR)/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-

# Used by debootstrap and rootfs both
DEBOOTSTRAP_TARBALL := $(ROOTDIR)/cache/debootstrap.tgz
DEBOOTSTRAP_TARBALL_SHA256 := $(ROOTDIR)/cache/debootstrap.tgz.sha256sum

DEBOOTSTRAP_EXTRA := \
	alsa-utils \
	apt-listchanges \
	apt-utils \
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
	doc-debian \
	file \
	firmware-atheros \
	gettext-base \
	gnupg \
	hdparm \
	ifupdown \
	init \
	iptables \
	iputils-ping \
	isc-dhcp-client \
	isc-dhcp-common \
	krb5-locales \
	less \
	libclass-isa-perl \
	liblockfile-bin \
	libpam-systemd \
	libswitch-perl \
	locales \
	logrotate \
	lsof \
	lxde \
	man-db \
	manpages \
	nano \
	ncurses-term \
	net-tools \
	netbase \
	netcat-traditional \
	network-manager \
	openbox-lxde-session \
	openssh-server \
	parted \
	pciutils \
	pulseaudio \
	python \
	python-minimal \
	python2.7 \
	python3-reportbug \
	reportbug \
	rsyslog \
	sudo \
	systemd \
	systemd-sysv \
	tasksel \
	telnet \
	traceroute \
	vim \
	wamerican \
	wget \
	whiptail \
	wireless-tools \
	wpasupplicant \
	xorg \
	xserver-xorg-input-all \
	xserver-xorg-video-all

DEBOOTSTRAP_ARGS := \
		--arch=arm64 \
		--keyring /usr/share/keyrings/debian-archive-keyring.gpg \
		--variant=buildd \
		--components=main,non-free \
		--exclude=debfoster \
		--include=$$(echo $(DEBOOTSTRAP_EXTRA) |tr ' ' ',') \

TARBALL_FETCH_ROOT_DIRECTORY := \
	/google/data/ro/teams/spacepark/enterprise/kokoro/prod/spacepark/enterprise
