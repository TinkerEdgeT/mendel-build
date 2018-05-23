# Preamble. Don't define any targets in this file! This is effectively just a
# common header where useful global vars go.

# Globally useful directories
TOOLCHAIN := $(ROOTDIR)/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-

# Used by debootstrap and rootfs both
DEBOOTSTRAP_TARBALL := $(ROOTDIR)/cache/debootstrap.tgz
DEBOOTSTRAP_TARBALL_SHA256 := $(ROOTDIR)/cache/debootstrap.tgz.sha256sum
