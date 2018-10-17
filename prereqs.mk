# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

REQUIRED_PACKAGES := \
	apt-utils \
	bc \
	binutils-aarch64-linux-gnu \
	build-essential \
	binfmt-support \
	cdbs \
	coreutils \
	debhelper \
	debian-archive-keyring \
	device-tree-compiler \
	fakeroot \
	genext2fs \
	git \
	gnome-pkg-tools \
	kpartx \
	libcap-dev \
	libwayland-dev \
	mtools \
	multistrap \
	parted \
	pbuilder \
	pkg-config \
	python-minimal \
	python2.7 \
	python3 \
	python3-setuptools \
	qemu-user-static \
	quilt \
	rsync \
	xz-utils \
	zlib1g-dev

prereqs:
	sudo apt-get update
	sudo apt-get install --no-install-recommends -y $(REQUIRED_PACKAGES)

targets::
	@echo "prereqs    - installs packages required by this Makefile"

.PHONY:: prereqs
