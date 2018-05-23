ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

####
# Define your top-level build targets here.
####

template: $(PRODUCT_OUT)/template

####
# Other rules you need to define to do the build go here.
####

clean::
	rm -f $(PRODUCT_OUT)/template

targets::
	echo "template - replace this with better information"

.PHONY:: template
