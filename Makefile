REQUIRED_PACKAGES := \
	qemu-user-static debootstrap debian-archive-keyring parted kpartx rsync \
	xz-utils

DEBOOTSTRAP_EXTRA := vim

SDCARD_SIZE ?= 8
SDCARD_DEVICE ?=

all: rootfs

sdcard.img:
	@echo "Usage: make"
	@echo
	@echo "Place a copy of the freescale sdcard image in this directory as 'sdcard.img'"
	@echo "this makefile will convert the sdcard.img rootfs into a debian root and"
	@echo "preserve the kernel modules on the disk."

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

ensure-unmounted:
	@if [[ -d rootfs ]]; then \
		echo "sdcard.img mounted -- unmount first!" >/dev/stderr; \
		exit 1; \
	fi

ensure-mounted:
	@if [[ ! -d rootfs ]]; then \
		echo "sdcard.img not mounted -- mount first!" >/dev/stderr; \
		exit 1; \
	fi

mount: sdcard.img
	mkdir rootfs
	sudo kpartx -as sdcard.img
	sudo mount /dev/mapper/loop0p2 rootfs

umount: unmount
unmount: ensure-mounted
	-[[ -d rootfs ]] && sudo umount rootfs
	-sudo kpartx -ds sdcard.img
	rmdir rootfs

prereqs:
	sudo apt-get install $(REQUIRED_PACKAGES)

rootfs: sdcard.img
	mkdir -p rootfs
	sudo kpartx -as sdcard.img
	sudo mount /dev/mapper/loop0p2 rootfs
	sudo tar cpf modules.tar rootfs/lib/modules/
	sudo umount rootfs
	sudo mkfs.ext4 -F -L root -j /dev/mapper/loop0p2
	sudo mount /dev/mapper/loop0p2 rootfs
	sudo qemu-debootstrap \
		--arch=arm64 \
		--keyring /usr/share/keyrings/debian-archive-keyring.gpg \
		--variant=buildd \
		--exclude=debfoster \
		--include=$(DEBOOTSTRAP_EXTRA) \
		stable rootfs
	sudo tar xpf modules.tar
	sudo rsync -ar overlay/ rootfs
	sudo umount rootfs
	sudo kpartx -ds sdcard.img
	rmdir rootfs
	rm -f modules.tar

flash: ensure-unmounted sdcard.img
	@if [[ -z "$(SDCARD_DEVICE)" ]]; then \
		{
			echo "Error! Specify which SDCARD_DEVICE to write to like so: "; \
			echo "  make SDCARD_DEVICE=/dev/mmcblk0 flash";
		} >/dev/stderr; \
		exit 1; \
	fi
	@echo "WARNING! This will erase all data on $(SDCARD_DEVICE)! Writing in 5 seconds!"
	@for i in $(seq 5 -1 1); do echo -n "$i "; sleep 1; done; echo
	sudo dd if=sdcard.img of=$(SDCARD_DEVICE) status=progress

.PHONY: prereqs rootfs flash clean mrclean help targets mount unmount umount all ensure-unmounted ensure-mounted
