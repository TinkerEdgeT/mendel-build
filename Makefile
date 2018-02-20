SDCARD_DEVICE ?=

fs/root:
	mkdir -p fs/root
	sudo qemu-debootstrap \
		--arch=arm64 \
		--keyring /usr/share/keyrings/debian-archive-keyring.gpg \
		--variant=buildd \
		--exclude=debfoster \
		stable root

sdcard.img:
	dd if=/dev/zero of=sdcard.img bs=1G count=8
	parted sdcard.img <<EOF \
		unit s \
		mklabel msdos \
        mkpart primary fat32 16384 81919 \
		mkpart primary ext4  81920 100%  \
	sudo kpartx -as sdcard.img
	sudo mkdosfs -n BOOT /dev/mapper/loop0p1
	sudo mkfs.ext4 -L root -j /dev/mapper/loop0p2
	sudo kpartx -ds sdcard.img

rsync: fs/root sdcard.img
	mkdir -p mount/boot mount/root
	sudo kpartx -as sdcard.img
	sudo mount /dev/mapper/loop0p1 mount/boot
	sudo mount /dev/mapper/loop0p2 mount/root
	sudo rsync -ar fs/boot/ mount/boot/ 
	sudo rsync -ar fs/root/ mount/root/
	sudo rsync -ar overlay/ mount/root/
	sudo umount mount/*
	sudo kpartx -ds sdcard.img
	rm -rf mount/

flash: sdcard.img
	@if [[ -z "$(SDCARD_DEVICE)" ]]; then \
		(echo "Error! Specify which SDCARD_DEVICE to write to like so: "; \
		 echo "  make SDCARD_DEVICE=/dev/mmcblk0 flash";) >/dev/stderr; \
		exit 1; \
	fi
	@echo "WARNING! This will erase all data on $(SDCARD_DEVICE)! Writing in 5 seconds!"
	@for i in $(seq 5 -1 1); do echo -n "$i "; sleep 1; done; echo
	sudo dd if=sdcard.img of=$(SDCARD_DEVICE) bs=1G

clean:
	sudo rm -rf fs/root sdcard.img

.PHONY: rsync flash clean
