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

DOCKER_FETCH_TARBALL ?= $(IS_GLINUX)

docker-build: $(ROOTDIR)/cache/aiy-board-builder.tar
ifeq ($(DOCKER_FETCH_TARBALL),true)
$(ROOTDIR)/cache/aiy-board-builder.tar: $(PREBUILT_DOCKER_ROOT)/aiy-board-builder.tar
	mkdir -p $(ROOTDIR)/cache
	cp $< $(ROOTDIR)/cache
else
$(ROOTDIR)/cache/aiy-board-builder.tar: $(ROOTDIR)/build/Dockerfile $(ROOTDIR)/build/prereqs.mk
	mkdir -p $(ROOTDIR)/cache/docker-build
	cp -a $(ROOTDIR)/build $(ROOTDIR)/cache/docker-build
	cp -a $(ROOTDIR)/board $(ROOTDIR)/cache/docker-build
	cp -a $(ROOTDIR)/build/Dockerfile $(ROOTDIR)/cache/docker-build
	docker build -t aiy-board-builder $(ROOTDIR)/cache/docker-build
	docker image save -o $@ aiy-board-builder:latest
	docker rmi aiy-board-builder:latest
	rm -rf $(ROOTDIR)/cache/docker-build
endif

# Runs any make TARGET in x86 docker image ('m docker-TARGET')
docker-%: docker-build;
	docker load -i $(ROOTDIR)/cache/aiy-board-builder.tar
	docker run --rm --privileged --tty \
		-v /dev\:/dev \
		-v $(ROOTDIR)\:/rootdir \
		-v $(TARBALL_FETCH_ROOT_DIRECTORY)\:/tarballs \
		-v $(PREBUILT_DOCKER_ROOT)\:/docker \
		-v $(PREBUILT_MODULES_ROOT)\:/modules \
		-v $(FETCH_PBUILDER_DIRECTORY)\:/pbuilder \
		-w /rootdir \
		-e "ROOTFS_FETCH_TARBALL=$(ROOTFS_FETCH_TARBALL)" \
		-e "FETCH_PBUILDER_BASE=$(FETCH_PBUILDER_BASE)" \
		-e "TARBALL_FETCH_ROOT_DIRECTORY=/tarballs" \
		-e "PREBUILT_DOCKER_ROOT=/docker" \
		-e "ROOTFS_REVISION=$(ROOTFS_REVISION)" \
		-e "PREBUILT_MODULES_ROOT=/modules" \
		-e "FETCH_PBUILDER_DIRECTORY=/pbuilder" \
		-e "FETCH_PACKAGES=$(FETCH_PACKAGES)" \
		-e "HEADLESS_BUILD=$(HEADLESS_BUILD)" \
		-e "IS_EXTERNAL=$(IS_EXTERNAL)" \
		-e "http_proxy=$(http_proxy)" \
		-e "USERSPACE_ARCH=$(USERSPACE_ARCH)" \
		-e "QEMU_ARCH=$(QEMU_ARCH)" \
		aiy-board-builder \
		/bin/bash -c \
			'groupadd --gid $(shell id -g) $(shell id -g -n); \
			useradd -m -e "" -s /bin/bash --gid $(shell id -g) --uid $(shell id -u) $(shell id -u -n); \
			passwd -d $(shell id -u -n); \
			echo "$(shell id -u -n) ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers; \
			sudo cp /rootdir/build/99network-settings /etc/apt/apt.conf.d/; \
			sudo chmod 644 /etc/apt/apt.conf.d/99network-settings; \
			sudo -E -u $(shell id -u -n) /bin/bash -c "source build/setup.sh; m \
			-j$$(nproc) $*";'

# Test x86 docker ('m docker-test-docker')
test-docker:
	@echo "Docker architecture: $(shell uname -a)"
	@echo "Compiler version: $(shell gcc --version)"
	@echo -e '#include <stdio.h>\nint main() {printf("\\nHello Docker gcc test\\n\\n");\n return 0;\n}' > hello.c
	@make hello
	@./hello
	@rm -f hello.c hello

.DEFAULT_GOAL:=docker-all

.PHONY:: docker-build
