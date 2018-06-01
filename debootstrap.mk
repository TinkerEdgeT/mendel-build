ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

DEBOOTSTRAP_TARBALL_REVISION ?= latest
DEBOOTSTRAP_FETCH_TARBALL ?= true

validate-bootstrap-tarball:
ifeq ($(DEBOOTSTRAP_FETCH_TARBALL),true)
		make -f $(ROOTDIR)/build/debootstrap.mk fetch-bootstrap-tarball
else
		make -f $(ROOTDIR)/build/debootstrap.mk make-bootstrap-tarball
endif
	cd $(ROOTDIR)/cache && \
		sha256sum -c $(DEBOOTSTRAP_TARBALL_SHA256)

fetch-bootstrap-tarball:
	mkdir -p $(ROOTDIR)/cache
	cp \
		$(TARBALL_FETCH_ROOT_DIRECTORY)/rootfs/$(DEBOOTSTRAP_TARBALL_REVISION)/debootstrap.tgz{,.sha256sum} \
		$(ROOTDIR)/cache

make-bootstrap-sha256sum: $(DEBOOTSTRAP_TARBALL)
	cd $(ROOTDIR)/cache && \
		sha256sum $(notdir $(DEBOOTSTRAP_TARBALL)) > $(DEBOOTSTRAP_TARBALL_SHA256)

make-bootstrap-tarball: $(ROOTDIR)/build/debootstrap.mk $(ROOTDIR)/build/preamble.mk
	mkdir -p $(PRODUCT_OUT)/obj/DEBOOTSTRAP
	mkdir -p $(ROOTDIR)/cache
	/usr/sbin/debootstrap \
		--foreign \
		$(DEBOOTSTRAP_ARGS) \
		--make-tarball=$(DEBOOTSTRAP_TARBALL) \
		stretch $(PRODUCT_OUT)/obj/DEBOOTSTRAP
	+make -f $(ROOTDIR)/build/debootstrap.mk make-bootstrap-sha256sum

targets::
	@echo "validate-bootstrap-tarball - validates the bootstrap tarball matches the SHA-256 sums"
	@echo "make-bootstrap-tarball - makes the debootstrap tarball for faster rootfs building"
	@echo "make-bootstrap-sha256sum - calculates the SHA-256 sums of the debootstrap tarball"

clean::
	sudo rm -rf $(PRODUCT_OUT)/obj/DEBOOTSTRAP

.PHONY:: fetch-bootstrap-tarball validate-bootstrap-tarball make-bootstrap-sha256sum make-bootstrap-tarball
