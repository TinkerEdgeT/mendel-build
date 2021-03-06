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

SHELL := $(shell which /bin/bash)

ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

precheck:
	+make -f $(ROOTDIR)/build/Makefile validate-bootstrap-tarball
	+make -f $(ROOTDIR)/build/Makefile all

out-dirs:
	@mkdir -p $(PRODUCT_OUT)/packages/core
	@mkdir -p $(PRODUCT_OUT)/packages/bsp
	@mkdir -p $(PRODUCT_OUT)/obj
	@mkdir -p $(ROOTDIR)/cache

all: rootfs bootloader partition-table

lintian: packages
	lintian $(PRODUCT_OUT)/packages/core/*.deb $(PRODUCT_OUT)/packages/bsp/*.deb

help: targets
targets::
	@echo "Targets available for building in this Makefile:"
	@echo

include $(ROOTDIR)/board/boot.mk
include $(ROOTDIR)/board/partition-table.mk

include $(ROOTDIR)/build/img2simg.mk
include $(ROOTDIR)/build/prereqs.mk
include $(ROOTDIR)/build/rootfs.mk
include $(ROOTDIR)/build/docker.mk
include $(ROOTDIR)/build/packages.mk
include $(ROOTDIR)/build/multistrap.mk

include $(ROOTDIR)/board/bootloader.mk
-include $(ROOTDIR)/board/sdcard.mk
-include $(ROOTDIR)/board/recovery.mk

clean::
	rm -rf $(ROOTDIR)/out

.PHONY:: all help targets clean boot-targets
