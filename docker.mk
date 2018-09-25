ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

ARM64_BUILDER_FETCH_TARBALL ?= $(IS_GLINUX)
DOCKER_FETCH_TARBALL ?= $(IS_GLINUX)

docker-build: $(ROOTDIR)/cache/aiy-board-builder.tar
ifeq ($(DOCKER_FETCH_TARBALL),true)
$(ROOTDIR)/cache/aiy-board-builder.tar: $(PREBUILT_DOCKER_ROOT)/aiy-board-builder.tar
	mkdir -p $(ROOTDIR)/cache
	cp $< $(ROOTDIR)/cache
else
$(ROOTDIR)/cache/aiy-board-builder.tar:
	mkdir -p $(ROOTDIR)/cache
	docker build -t aiy-board-builder $(ROOTDIR)/build
	docker image save -o $@ aiy-board-builder:latest
	docker rmi aiy-board-builder:latest
endif

docker-build-arm64: $(ROOTDIR)/cache/arm64-builder.tar
ifeq ($(ARM64_BUILDER_FETCH_TARBALL),true)
$(ROOTDIR)/cache/arm64-builder.tar: $(PREBUILT_DOCKER_ROOT)/arm64-builder.tar
	mkdir -p $(ROOTDIR)/cache
	cp $< $(ROOTDIR)/cache
else
$(ROOTDIR)/cache/arm64-builder.tar:
	mkdir -p $(ROOTDIR)/cache
	mkdir -p $(PRODUCT_OUT)/obj/ARM64_BUILDER
	cp $(ROOTDIR)/build/Dockerfile.arm64 $(PRODUCT_OUT)/obj/ARM64_BUILDER/Dockerfile
	cp $(shell which qemu-aarch64-static) $(PRODUCT_OUT)/obj/ARM64_BUILDER
	docker build -t arm64-builder $(PRODUCT_OUT)/obj/ARM64_BUILDER
	docker image save -o $@ arm64-builder:latest
	docker rmi arm64-builder:latest
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
		-v $(PACKAGES_FETCH_ROOT_DIRECTORY)\:/packages \
		-w /rootdir \
		-e "ROOTFS_FETCH_TARBALL=$(ROOTFS_FETCH_TARBALL)" \
		-e "ARM64_BUILDER_FETCH_TARBALL=$(ARM64_BUILDER_FETCH_TARBALL)" \
		-e "FETCH_PBUILDER_BASE=$(FETCH_PBUILDER_BASE)" \
		-e "TARBALL_FETCH_ROOT_DIRECTORY=/tarballs" \
		-e "PREBUILT_DOCKER_ROOT=/docker" \
		-e "ROOTFS_REVISION=$(ROOTFS_REVISION)" \
		-e "PREBUILT_MODULES_ROOT=/modules" \
		-e "FETCH_PBUILDER_DIRECTORY=/pbuilder" \
		-e "PACKAGES_FETCH_ROOT_DIRECTORY=/packages" \
		-e "FETCH_PACKAGES=$(FETCH_PACKAGES)" \
		-e "PACKAGES_REVISION=$(PACKAGES_REVISION)" \
		aiy-board-builder \
		/bin/bash -c \
			'groupadd --gid $(shell id -g) $(shell id -g -n); \
			useradd -m -e "" -s /bin/bash --gid $(shell id -g) --uid $(shell id -u) $(shell id -u -n); \
			passwd -d $(shell id -u -n); \
			echo "$(shell id -u -n) ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers; \
			adduser $(shell id -u -n) docker; \
			/etc/init.d/docker start; \
			sudo -E -u $(shell id -u -n) /bin/bash -c "source build/setup.sh; m \
			-j$(shell nproc) $*";'

# Macro for running make target in arm64 docker image
define docker-arm64-run
docker-arm64-$1: docker-build-arm64;
	docker load -i $(ROOTDIR)/cache/arm64-builder.tar; \
	docker run --rm --tty \
	    -v /dev\:/dev \
	    -v $(ROOTDIR)\:/build \
	    -v $(TARBALL_FETCH_ROOT_DIRECTORY)\:/tarballs \
	    -v $(PREBUILT_DOCKER_ROOT)\:/docker \
	    -v $(PREBUILT_MODULES_ROOT)\:/modules \
	    -w /build \
	      -e "ROOTFS_FETCH_TARBALL=$(ROOTFS_FETCH_TARBALL)" \
	      -e "ARM64_BUILDER_FETCH_TARBALL=$(ARM64_BUILDER_FETCH_TARBALL)" \
	      -e "TARBALL_FETCH_ROOT_DIRECTORY=/tarballs" \
	      -e "PREBUILT_DOCKER_ROOT=/docker" \
	      -e "ROOTFS_REVISION=$(ROOTFS_REVISION)" \
	      -e "PREBUILT_MODULES_ROOT=/modules" \
	   arm64-builder \
	   /bin/bash -c \
		'groupadd --gid $$(shell id -g) $$(shell id -g -n); \
	     useradd -m -e "" -s /bin/bash --gid $$(shell id -g) --uid $$(shell id -u) $$(shell id -u -n); \
	     passwd -d $$(shell id -u -n); \
	     echo "$$(shell id -u -n) ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers; \
	     source build/setup.sh; m -j$(shell nproc) $2'
endef

# Test x86 docker ('m docker-test-docker')
test-docker:
	@echo "Docker architecture: $(shell uname -a)"
	@echo "Compiler version: $(shell gcc --version)"
	@echo -e '#include <stdio.h>\nint main() {printf("\\nHello Docker gcc test\\n\\n");\n return 0;\n}' > hello.c
	@make hello
	@./hello
	@rm -f hello.c hello

# Test arm64 docker 'm docker-arm64-test-docker'
$(call docker-arm64-run,test-docker,test-docker)

.DEFAULT_GOAL:=docker-all

.PHONY:: docker-build
