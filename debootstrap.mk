ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

DEBOOTSTRAP_EXTRA := \
	avahi-daemon \
	bluez \
	dbus \
	debian-archive-keyring \
	dialog \
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

validate-bootstrap-tarball:
	@if [[ ! -f $(DEBOOTSTRAP_TARBALL) ]]; then \
		echo ""; \
		echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"; \
		echo ""; \
		echo "Please run the make-bootstrap-tarball target first like this:"; \
		echo "  m make-bootstrap-tarball"; \
		echo ""; \
		echo "or this:"; \
		echo "  mm debootstrap make-bootstrap-tarball"; \
		echo ""; \
		echo "This will be automated in the future."; \
		echo ""; \
		echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"; \
		echo ""; \
		exit 1; \
	fi
	cd $(ROOTDIR)/cache && \
		sha256sum -c $(DEBOOTSTRAP_TARBALL_SHA256)

make-bootstrap-sha256sum: $(DEBOOTSTRAP_TARBALL)
	cd $(ROOTDIR)/cache && \
		sha256sum $(DEBOOTSTRAP_TARBALL) > $(DEBOOTSTRAP_TARBALL_SHA256)

make-bootstrap-tarball: $(ROOTDIR)/build/debootstrap.mk
	mkdir -p $(PRODUCT_OUT)/obj/DEBOOTSTRAP
	debootstrap \
		--foreign \
		--arch=arm64 \
		--keyring /usr/share/keyrings/debian-archive-keyring.gpg \
		--variant=buildd \
		--exclude=debfoster \
		--include=$$(echo $(DEBOOTSTRAP_EXTRA) |tr ' ' ',') \
		--make-tarball=$(DEBOOTSTRAP_TARBALL) \
		stretch $(PRODUCT_OUT)/obj/DEBOOTSTRAP
	+make -f $(ROOTDIR)/build/debootstrap.mk make-bootstrap-sha256sum

targets::
	@echo "validate-bootstrap-tarball - validates the bootstrap tarball matches the SHA-256 sums"
	@echo "make-bootstrap-tarball - makes the debootstrap tarball for faster rootfs building"
	@echo "make-bootstrap-sha256sum - calculates the SHA-256 sums of the debootstrap tarball"

clean::
	sudo rm -rf $(PRODUCT_OUT)/obj/DEBOOTSTRAP

.PHONY:: validate-bootstrap-tarball make-bootstrap-sha256sum make-bootstrap-tarball
