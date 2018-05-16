# Globally useful directories
ROOTDIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))/..
TOOLCHAIN := $(ROOTDIR)/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-
PRODUCT_OUT := $(ROOTDIR)/out/target/product/imx8m_phanbell
HOST_OUT := $(ROOTDIR)/out/host/linux-x86

# U-boot directories
NXP_MKIMAGE_DIR := $(ROOTDIR)/device/nxp/imx8m/imx-mkimage
UBOOT_SRC_DIR := $(ROOTDIR)/hardware/bsp/bootloader/nxp/uboot-imx
UBOOT_OUT_DIR := $(PRODUCT_OUT)/obj/UBOOT_OBJ

# Kernel directories
KERNEL_SRC_DIR := $(ROOTDIR)/hardware/bsp/kernel/nxp/imx-v4.9
KERNEL_OUT_DIR := $(PRODUCT_OUT)/obj/KERNEL_OBJ

GPU_VERSION := imx-gpu-viv-6.2.4.p0.2-aarch64
GPU_DIR := $(ROOTDIR)/imx-gpu-viv/$(GPU_VERSION)

REQUIRED_PACKAGES := \
	qemu-user-static \
	debootstrap \
	debian-archive-keyring \
	parted \
	kpartx \
	rsync \
	xz-utils

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
	wpasupplicant \

IMG2SIMG_SRCS_CXX := \
	system/core/base/stringprintf.cpp \
	system/core/libsparse/sparse_read.cpp

IMG2SIMG_SRCS_C := \
	system/core/libsparse/backed_block.c \
	system/core/libsparse/img2simg.c \
	system/core/libsparse/output_file.c \
	system/core/libsparse/sparse.c \
	system/core/libsparse/sparse_crc32.c \
	system/core/libsparse/sparse_err.c

IMG2SIMG_INCLUDES := \
	system/core/base/include \
	system/core/libsparse/include
IMG2SIMG_INCLUDES := $(addprefix -I,$(IMG2SIMG_INCLUDES))

all: u-boot kernel partition-table boot

u-boot: $(PRODUCT_OUT)/u-boot.imx
kernel: $(PRODUCT_OUT)/kernel
partition-table: $(PRODUCT_OUT)/partition-table.img
boot: $(PRODUCT_OUT)/boot.img
rootfs: $(PRODUCT_OUT)/rootfs.img
img2simg: $(HOST_OUT)/bin/img2simg
sdcard: $(PRODUCT_OUT)/sdcard.img
sdcard-xz: $(PRODUCT_OUT)/sdcard.img.xz

help: targets
targets:
	@echo "Tagets available for building in this Makefile:"
	@echo
	@echo "prereqs    - installs packages required by this Makefile"
	@echo "u-boot     - builds the bootloader"
	@echo "boot       - builds the kernel and boot partition"
	@echo "partition-table - builds a partition table image for the eMMC"
	@echo "rootfs     - runs debootstrap to build the rootfs tree"
	@echo "             set DEBOOTSTRAP_EXTRA for additional packages"
	@echo "sdcard     - generate a flashable sdcard image"

prereqs:
	sudo apt-get install $(REQUIRED_PACKAGES)

clean:
	make -C $(KERNEL_SRC_DIR) mrproper
	make -C $(UBOOT_SRC_DIR) mrproper
	rm -rf $(ROOTDIR)/out

.PHONY: u-boot kernel partition-table.img boot.img debootstrap img2simg

### Non-phony targets below this line #################################

$(PRODUCT_OUT)/u-boot.imx:
	mkdir -p $(UBOOT_OUT_DIR)
	+make -C $(UBOOT_SRC_DIR) O=$(UBOOT_OUT_DIR) ARCH=arm CROSS_COMPILE=$(TOOLCHAIN) mx8mq_phanbell_defconfig
	+make -C $(UBOOT_SRC_DIR) O=$(UBOOT_OUT_DIR) ARCH=arm CROSS_COMPILE=$(TOOLCHAIN)
	cp $(UBOOT_OUT_DIR)/tools/mkimage $(UBOOT_OUT_DIR)/tools/mkimage_uboot
	+make -C $(NXP_MKIMAGE_DIR) TARGET_PRODUCT=iot_imx8m_phanbell SOC=iMX8M flash_hdmi_spl_uboot
	cp $(NXP_MKIMAGE_DIR)/iMX8M/flash.bin $(PRODUCT_OUT)/u-boot.imx
	+make -C $(NXP_MKIMAGE_DIR) TARGET_PRODUCT=iot_imx8m_phanbell clean

$(PRODUCT_OUT)/kernel:
	mkdir -p $(KERNEL_OUT_DIR)
	+make -C $(KERNEL_SRC_DIR) O=$(KERNEL_OUT_DIR) ARCH=arm64 CROSS_COMPILE=$(TOOLCHAIN) defconfig
	cat $(ROOTDIR)/imx8-debian/defconfig | tee -a $(KERNEL_OUT_DIR)/.config
	+make -C $(KERNEL_SRC_DIR) O=$(KERNEL_OUT_DIR) ARCH=arm64 CROSS_COMPILE=$(TOOLCHAIN) Image modules dtbs
	cp $(KERNEL_OUT_DIR)/arch/arm64/boot/Image $(PRODUCT_OUT)/kernel

modules_install: $(PRODUCT_OUT)/kernel
	+sudo make -C $(KERNEL_SRC_DIR) O=$(KERNEL_OUT_DIR) ARCH=arm64 CROSS_COMPILE=$(TOOLCHAIN) INSTALL_MOD_PATH=$(PRODUCT_OUT)/rootfs modules_install

$(PRODUCT_OUT)/partition-table.img:
	mkdir -p $(PRODUCT_OUT)
	$(ROOTDIR)/system/tools/bpt/bpttool make_table --input $(ROOTDIR)/imx8-debian/partition-table.bpt --output_gpt $(PRODUCT_OUT)/partition-table.img

$(PRODUCT_OUT)/boot.img: $(PRODUCT_OUT)/u-boot.imx $(PRODUCT_OUT)/kernel
	mkdir -p $(PRODUCT_OUT)/boot
	$(UBOOT_OUT_DIR)/tools/mkimage -A arm -T script -O linux -d $(ROOTDIR)/imx8-debian/boot.txt $(PRODUCT_OUT)/boot.scr
	fallocate -l 32M $(PRODUCT_OUT)/boot.img
	mkfs.fat $(PRODUCT_OUT)/boot.img
	mcopy -i $(PRODUCT_OUT)/boot.img $(PRODUCT_OUT)/kernel ::Image
	mcopy -i $(PRODUCT_OUT)/boot.img $(PRODUCT_OUT)/boot.scr ::
	mcopy -i $(PRODUCT_OUT)/boot.img $(KERNEL_OUT_DIR)/arch/arm64/boot/dts/freescale/fsl-imx8mq-phanbell.dtb ::

$(HOST_OUT)/bin/img2simg:
	mkdir -p $(HOST_OUT)/bin
	mkdir -p $(HOST_OUT)/obj/IMG2SIMG
	$(foreach infile, $(IMG2SIMG_SRCS_CXX), g++ -include string.h $(IMG2SIMG_INCLUDES) -c $(infile) -o $(HOST_OUT)/obj/IMG2SIMG/$(notdir $(patsubst %.cpp,%.o,$(infile))); )
	$(foreach infile, $(IMG2SIMG_SRCS_C), gcc $(IMG2SIMG_INCLUDES) -c $(infile) -o $(HOST_OUT)/obj/IMG2SIMG/$(notdir $(patsubst %.c,%.o,$(infile))); )
	gcc -o $(HOST_OUT)/bin/img2simg $(HOST_OUT)/obj/IMG2SIMG/* -lz -lstdc++

gpu:
	sudo rsync -rl $(GPU_DIR)/gpu-core/ $(PRODUCT_OUT)/rootfs
	sudo rsync -rl $(GPU_DIR)/gpu-demos/ $(PRODUCT_OUT)/rootfs
	sudo rsync -rl $(GPU_DIR)/gpu-tools/gmem-info/ $(PRODUCT_OUT)/rootfs
	echo "vivante" | sudo tee -a $(PRODUCT_OUT)/rootfs/etc/modules

firmware:
	sudo mkdir $(PRODUCT_OUT)/rootfs/lib/firmware
	sudo rsync -rl $(ROOTDIR)/imx-firmware/ $(PRODUCT_OUT)/rootfs/lib/firmware

adjustments:
	sudo rm -f $(PRODUCT_OUT)/rootfs/etc/ssh/ssh_host_*
	sudo rm -f $(PRODUCT_OUT)/rootfs/var/log/bootstrap.log
	echo "enterprise" | sudo tee $(PRODUCT_OUT)/rootfs/etc/hostname
	echo "127.0.0.1 enterprise" | sudo tee -a $(PRODUCT_OUT)/rootfs/etc/hosts
	sudo chroot $(PRODUCT_OUT)/rootfs mkdir -p /home/enterprise
	sudo chroot $(PRODUCT_OUT)/rootfs adduser enterprise --home /home/enterprise --shell /bin/bash --disabled-password --gecos ""
	sudo chroot $(PRODUCT_OUT)/rootfs chown enterprise:enterprise /home/enterprise
	sudo chroot $(PRODUCT_OUT)/rootfs bash -c "echo 'enterprise:open123' | chpasswd"
	echo "nameserver 8.8.8.8" | sudo tee $(PRODUCT_OUT)/rootfs/etc/resolv.conf
	sudo mount -o bind /proc $(PRODUCT_OUT)/rootfs/proc
	sudo mount -o bind /sys $(PRODUCT_OUT)/rootfs/sys
	sudo mount -o bind /dev $(PRODUCT_OUT)/rootfs/dev
	sudo mount -o bind /dev/pts $(PRODUCT_OUT)/rootfs/dev/pts

	echo "en_US.UTF-8 UTF-8" | sudo tee -a $(PRODUCT_OUT)/rootfs/etc/locale.gen
	sudo chroot $(PRODUCT_OUT)/rootfs locale-gen
	sudo chroot $(PRODUCT_OUT)/rootfs systemctl enable ssh
	sudo chroot $(PRODUCT_OUT)/rootfs systemctl enable bluetooth
	sudo chroot $(PRODUCT_OUT)/rootfs systemctl enable avahi-daemon
	sudo chroot $(PRODUCT_OUT)/rootfs systemctl enable NetworkManager

	sudo chroot $(PRODUCT_OUT)/rootfs apt-get update
	sudo chroot $(PRODUCT_OUT)/rootfs tasksel install standard
	sudo chroot $(PRODUCT_OUT)/rootfs apt-get clean
	sudo chroot $(PRODUCT_OUT)/rootfs apt-get dist-upgrade -y
	sudo chroot $(PRODUCT_OUT)/rootfs apt-get clean
	echo "enterprise	ALL=(ALL) ALL" |sudo tee -a $(PRODUCT_OUT)/rootfs/etc/sudoers

	sudo $(ROOTDIR)/imx8-debian/tools/fix_permissions.sh -p $(ROOTDIR)/imx8-debian/permissions.txt -t $(PRODUCT_OUT)/rootfs
	sudo umount -R $(PRODUCT_OUT)/rootfs/{dev,proc,sys}

$(PRODUCT_OUT)/rootfs.img: $(HOST_OUT)/bin/img2simg
	mkdir -p $(PRODUCT_OUT)/rootfs
	fallocate -l 2G $(PRODUCT_OUT)/rootfs.img
	mkfs.ext4 $(PRODUCT_OUT)/rootfs.img
	sudo mount -o loop $(PRODUCT_OUT)/rootfs.img $(PRODUCT_OUT)/rootfs
	sudo qemu-debootstrap \
		--foreign \
		--arch=arm64 \
		--keyring /usr/share/keyrings/debian-archive-keyring.gpg \
		--variant=buildd \
		--exclude=debfoster \
		--include=$$(echo $(DEBOOTSTRAP_EXTRA) |tr ' ' ',') \
		stretch $(PRODUCT_OUT)/rootfs

	+make gpu
	+make firmware
	+make modules_install
	+make adjustments

	sudo umount $(PRODUCT_OUT)/rootfs
	sudo rmdir $(PRODUCT_OUT)/rootfs
	sudo sync $(PRODUCT_OUT)/rootfs.img
	sudo chown ${USER} $(PRODUCT_OUT)/rootfs.img
	$(HOST_OUT)/bin/img2simg $(PRODUCT_OUT)/rootfs.img $(PRODUCT_OUT)/rootfs.simg

$(PRODUCT_OUT)/sdcard.img: $(PRODUCT_OUT)/rootfs.img $(PRODUCT_OUT)/boot.img $(PRODUCT_OUT)/u-boot.imx
	fallocate -l 4G $(PRODUCT_OUT)/sdcard.img
	parted -s $(PRODUCT_OUT)/sdcard.img mklabel msdos
	parted -s $(PRODUCT_OUT)/sdcard.img unit MiB mkpart primary fat32 8 40
	parted -s $(PRODUCT_OUT)/sdcard.img unit MiB mkpart primary 40 4095
	dd if=$(PRODUCT_OUT)/u-boot.imx of=$(PRODUCT_OUT)/sdcard.img conv=notrunc seek=66 bs=512
	dd if=$(PRODUCT_OUT)/boot.img of=$(PRODUCT_OUT)/sdcard.img conv=notrunc seek=8 bs=1M
	dd if=$(PRODUCT_OUT)/rootfs.img of=$(PRODUCT_OUT)/sdcard.img conv=notrunc seek=40 bs=1M

$(PRODUCT_OUT)/sdcard.img.xz: $(PRODUCT_OUT)/sdcard.img
	xz -k -T0 -0 $(PRODUCT_OUT)/sdcard.img
