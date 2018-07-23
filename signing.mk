ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

make-repo: $(PRODUCT_OUT)/repo/debian_repo/dists/stable/Release
$(PRODUCT_OUT)/repo/debian_repo/dists/stable/Release: $(ROOTDIR)/build/distributions | kernel-deb modules packages gpu-packages
	mkdir -p $(PRODUCT_OUT)/repo
	mkdir -p $(PRODUCT_OUT)/repo/debian_repo
	mkdir -p $(PRODUCT_OUT)/repo/deb_repo_config
	cp $(ROOTDIR)/build/distributions $(PRODUCT_OUT)/repo/deb_repo_config/
	reprepro --basedir $(PRODUCT_OUT)/repo \
	         --outdir $(PRODUCT_OUT)/repo/debian_repo \
	         --confdir $(PRODUCT_OUT)/repo/deb_repo_config \
	         includedeb stable $(PRODUCT_OUT)/*.deb
	find $(PRODUCT_OUT)/repo/debian_repo -type d | xargs chmod 777
	find $(PRODUCT_OUT)/repo/debian_repo -type f | xargs chmod 666

sign-repo: $(PRODUCT_OUT)/repo/debian_repo/dists/stable/Release.gpg
$(PRODUCT_OUT)/repo/debian_repo/dists/stable/Release.gpg:
ifneq (,$(wildcard /escalated_sign/escalated_sign.py))
	/escalated_sign/escalated_sign.py \
	  --tool=linux_gpg_sign \
	  --job-dir=/escalated_sign_jobs -- \
	  --loglevel=debug $(PRODUCT_OUT)/repo/debian_repo/dists/stable/Release
	mv $(PRODUCT_OUT)/repo/debian_repo/dists/stable/Release.asc \
	   $(PRODUCT_OUT)/repo/debian_repo/dists/stable/Release.gpg
else
	@echo "Not signing deb packages (if you are building locally -- this is okay)"
endif

.PHONY:: make-repo sign-repo