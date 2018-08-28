ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

make-repo: $(PRODUCT_OUT)/repo/debian_repo/dists/stable/Release
$(PRODUCT_OUT)/repo/debian_repo/dists/stable/Release: $(ROOTDIR)/build/distributions | kernel-deb modules packages-tarball
	mkdir -p $(PRODUCT_OUT)/repo
	mkdir -p $(PRODUCT_OUT)/repo/debian_repo
	mkdir -p $(PRODUCT_OUT)/repo/deb_repo_config
	tar -xvf $(ROOTDIR)/cache/packages.tgz -C $(PRODUCT_OUT)/repo
	cp $(ROOTDIR)/build/distributions $(PRODUCT_OUT)/repo/deb_repo_config/
	reprepro --basedir $(PRODUCT_OUT)/repo \
	         --outdir $(PRODUCT_OUT)/repo/debian_repo \
	         --confdir $(PRODUCT_OUT)/repo/deb_repo_config \
	         includedeb animal $(PRODUCT_OUT)/repo/packages/*.deb
	# Sigh, reprepro doesn't accept multiple dsc's at once...
	find $(PRODUCT_OUT)/packages -maxdepth 1 -type f -name '*.dsc' | \
	xargs -n1 \
	reprepro --basedir $(PRODUCT_OUT)/repo \
					 --outdir $(PRODUCT_OUT)/repo/debian_repo \
					 --confdir $(PRODUCT_OUT)/repo/deb_repo_config \
					 includedsc animal
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
