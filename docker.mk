ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

DOCKER_FETCH_TARBALL ?= true

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

docker-build: $(ROOTDIR)/cache/aiy-board-builder.tar

define docker-run
docker-$1: docker-build;
	docker load -i $(ROOTDIR)/cache/aiy-board-builder.tar
	docker run --rm --privileged --tty \
	   -v /dev\:/dev \
	   -v $(ROOTDIR)\:/build \
	   -v $(TARBALL_FETCH_ROOT_DIRECTORY)\:/tarballs \
	   -v $(PREBUILT_DOCKER_ROOT)\:/docker \
	   -v $(PREBUILT_MODULES_ROOT)\:/modules \
	   -w /build \
		 -e "DEBOOTSTRAP_FETCH_TARBALL=$(DEBOOTSTRAP_FETCH_TARBALL)" \
		 -e "ROOTFS_FETCH_TARBALL=$(ROOTFS_FETCH_TARBALL)" \
		 -e "TARBALL_FETCH_ROOT_DIRECTORY=/tarballs" \
		 -e "PREBUILT_DOCKER_ROOT=/docker" \
		 -e "ROOTFS_REVISION=$(ROOTFS_REVISION)" \
		 -e "DEBOOTSTRAP_TARBALL_REVISION=$(DEBOOTSTRAP_TARBALL_REVISION)" \
		 -e "PREBUILT_MODULES_ROOT=/modules" \
	   aiy-board-builder \
	   /bin/bash -c \
	   'groupadd --gid $$(shell id -g) $$(shell id -g -n); \
	   useradd -m -e "" -s /bin/bash --gid $$(shell id -g) --uid $$(shell id -u) $$(shell id -u -n); \
	   passwd -d $$(shell id -u -n); \
	   echo "$$(shell id -u -n) ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers; \
	   adduser $$(shell id -u -n) docker; \
	   /etc/init.d/docker start; \
	   sudo -E -u $$(shell id -u -n) /bin/bash -c "source build/setup.sh; m \
		  -j$(shell nproc) $2";'
endef

$(call docker-run,bootstrap,make-bootstrap-tarball)
$(call docker-run,rootfs,rootfs_raw)
$(call docker-run,boot,boot)
$(call docker-run,all,boot-targets)
$(call docker-run,sdcard,sdcard)

.DEFAULT_GOAL:=docker-all

.PHONY:: docker-build
