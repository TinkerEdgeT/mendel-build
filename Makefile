REQUIRED_PACKAGES := \
	qemu-user-static debootstrap debian-archive-keyring parted kpartx rsync

DEBOOTSTRAP_EXTRA := vim

SDCARD_DEVICE ?=

all: rsync

help: targets
targets:
	@echo "Tagets available for building in this Makefile:"
	@echo
	@echo "prereqs    - installs packages required by this Makefile"
	@echo "fs/root    - runs debootstrap to build the rootfs tree"
	@echo "             set DEBOOTSTRAP_EXTRA for additional packages"
	@echo "sdcard.img - makes a blank sdcard.img"
	@echo "rsync      - installs the filesystem tree"
	@echo "flash      - writes the sdcard.img to a card"
	@echo "             set SDCARD_DEVICE to the device in /dev"
	@echo "mount      - mounts the sdcard.img to mount/{boot,root}"
	@echo "unmount    - unmounts a previously mounted sdcard.img"
	@echo "clean      - removes generated files"
	@echo "mrclean    - removes generated files and the debootstrap root"

ensure-unmounted:
	@if [[ -d mount ]]; then \
		echo "sdcard.img mounted -- unmount first!" >/dev/stderr; \
		exit 1; \
	fi

ensure-mounted:
	@if [[ ! -d mount ]]; then \
		echo "sdcard.img not mounted -- mount first!" >/dev/stderr; \
		exit 1; \
	fi

mount: sdcard.img
	sudo mkdir -p mount/boot mount/root
	sudo kpartx -as sdcard.img
	sudo mount /dev/mapper/loop0p1 mount/boot
	sudo mount /dev/mapper/loop0p2 mount/root

umount: unmount
unmount: ensure-mounted
	-[[ -d mount ]] && sudo umount mount/boot mount/root
	-sudo kpartx -ds sdcard.img
	sudo rm -rf mount/

prereqs:
	sudo apt-get install $(REQUIRED_PACKAGES)

fs/root:
	mkdir -p fs/root
	sudo qemu-debootstrap \
		--arch=arm64 \
		--keyring /usr/share/keyrings/debian-archive-keyring.gpg \
		--variant=buildd \
		--exclude=debfoster \
		--include=$(DEBOOTSTRAP_EXTRA) \
		stable fs/root

sdcard.img: ensure-unmounted
	dd if=/dev/zero of=sdcard.img bs=1G count=8
	parted sdcard.img < partmap.txt
	sudo kpartx -as sdcard.img
	sudo mkdosfs -n BOOT /dev/mapper/loop0p1
	sudo mkfs.ext4 -L root -j /dev/mapper/loop0p2
	sudo kpartx -ds sdcard.img

rsync: fs/root sdcard.img 
	mkdir -p mount/boot mount/root
	sudo kpartx -as sdcard.img
	sudo mount /dev/mapper/loop0p1 mount/boot
	sudo mount /dev/mapper/loop0p2 mount/root
	sudo rsync -r fs/boot/ mount/boot/
	sudo rsync -ar fs/root/ mount/root/
	sudo rsync -ar overlay/ mount/root/
	sudo umount mount/*
	sudo kpartx -ds sdcard.img
	rm -rf mount/

flash: ensure-unmounted sdcard.img
	@if [[ -z "$(SDCARD_DEVICE)" ]]; then \
		(
			echo "Error! Specify which SDCARD_DEVICE to write to like so: "; \
			echo "  make SDCARD_DEVICE=/dev/mmcblk0 flash";
		) >/dev/stderr; \
		exit 1; \
	fi
	@echo "WARNING! This will erase all data on $(SDCARD_DEVICE)! Writing in 5 seconds!"
	@for i in $(seq 5 -1 1); do echo -n "$i "; sleep 1; done; echo
	sudo dd if=sdcard.img of=$(SDCARD_DEVICE) bs=1G

clean: ensure-unmounted
	sudo rm -rf sdcard.img

mrclean: clean
	sudo rm -rf fs/root

.PHONY: prereqs rsync flash clean mrclean help targets mount unmount umount all
