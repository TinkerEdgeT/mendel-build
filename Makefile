SRC_IMAGE := fsl-source.img
REQUIRED_PACKAGES := qemu-user-static debootstrap debian-archive-keyring parted	\
	kpartx rsync xz-utils

DEBOOTSTRAP_EXTRA := vim wpasupplicant network-manager lxde						\
	openbox-lxde-session systemd systemd-sysv libpam-systemd dialog				\
	openssh-server bluez locales dialog debian-archive-keyring parted sudo dbus	\
	pulseaudio avahi-daemon man-db less xorg xserver-xorg-video-all				\
	xserver-xorg-input-all tasksel wireless-tools

USER_NAME := enterprise
USER_PASS := open123

SDCARD_SIZE ?= 8
SDCARD_DEVICE ?=

all: rootfs

help: targets
targets:
	@echo "Tagets available for building in this Makefile:"
	@echo
	@echo "prereqs    - installs packages required by this Makefile"
	@echo "rootfs     - runs debootstrap to build the rootfs tree"
	@echo "             set DEBOOTSTRAP_EXTRA for additional packages"
	@echo "flash      - writes the sdcard.img to a card"
	@echo "             set SDCARD_DEVICE to the device in /dev"
	@echo "mount      - mounts the sdcard.img to mount/{boot,root}"
	@echo "unmount    - unmounts a previously mounted sdcard.img"

prereqs:
	sudo apt-get install $(REQUIRED_PACKAGES)

debootstrap:
	@echo
	@echo ==================== stage1 debootstrap ====================
	sudo qemu-debootstrap \
		--foreign \
		--arch=arm64 \
		--keyring /usr/share/keyrings/debian-archive-keyring.gpg \
		--variant=buildd \
		--exclude=debfoster \
		--include=$$(echo $(DEBOOTSTRAP_EXTRA) |tr ' ' ',') \
		stable rootfs

overlay: blobs.tar
	@echo
	@echo ==================== overlay ===============================
	sudo tar xpf blobs.tar
	sudo rsync -ar overlay/ rootfs/

adjustments:
	@echo
	@echo ==================== adjustments ===========================
	sudo cp /etc/resolv.conf rootfs/etc/
	sudo mount -o bind /proc rootfs/proc
	sudo mount -o bind /sys rootfs/sys
	sudo mount -o bind /dev rootfs/dev
	sudo mount -o bind /dev/pts rootfs/dev/pts
	sudo chroot rootfs locale-gen
	sudo chroot rootfs systemctl enable ssh
	sudo chroot rootfs systemctl enable bluetooth
	sudo chroot rootfs systemctl enable avahi-daemon
	sudo chroot rootfs systemctl enable NetworkManager
	sudo chroot rootfs apt-get update
	sudo chroot rootfs tasksel install standard
	sudo chroot rootfs apt-get clean
	sudo chroot rootfs apt-get dist-upgrade -y
	sudo chroot rootfs apt-get clean
	echo "enterprise	ALL=(ALL) ALL" |sudo tee -a rootfs/etc/sudoers
	sudo umount -R rootfs/{dev,sys,proc}

clean:
	-sudo umount source/ dest/
	-sudo kpartx -ds $(SRC_IMAGE)
	-sudo kpartx -ds sdcard.img
	-rmdir source/ dest/
	sudo rm -rf rootfs/ sdcard.img sdcard.img.xz blobs.tar

.PHONY: debootstrap overlay adjustments

### Non-phony targets below this line #################################

rootfs:
	mkdir rootfs
	make debootstrap
	make overlay
	make adjustments

blobs.tar:
	mkdir source
	sudo kpartx -as $(SRC_IMAGE)
	sudo mount /dev/mapper/loop0p2 source
	tar cpf blobs.tar source/lib/{modules/,firmware/}
	sudo umount source
	sudo kpartx -ds $(SRC_IMAGE)
	rmdir source

sdcard.img: rootfs tools/resize_image.sh
	cp $(SRC_IMAGE) sdcard.img
	tools/resize_image.sh -i sdcard.img -r rootfs/
	mkdir dest
	sudo kpartx -as sdcard.img
	sudo mkfs.ext3 -F -j -L root /dev/mapper/loop0p2
	sudo mount /dev/mapper/loop0p2 dest/
	sudo rsync -ar rootfs/ dest
	sudo umount dest
	rmdir dest

sdcard.img.xz: sdcard.img
	xz -k -T0 -0 sdcard.img
