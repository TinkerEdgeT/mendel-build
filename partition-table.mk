ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

partition-table: $(PRODUCT_OUT)/partition-table.img

$(PRODUCT_OUT)/partition-table.img: $(ROOTDIR)/build/partition-table.bpt
	mkdir -p $(PRODUCT_OUT)
	$(ROOTDIR)/system/tools/bpt/bpttool make_table --input $(ROOTDIR)/build/partition-table.bpt --output_gpt $(PRODUCT_OUT)/partition-table.img

targets::
	@echo "partition-table - builds a partition table image for the eMMC"

clean::
	rm -f $(PRODUCT_OUT)/partition-table.img

.PHONY:: partition-table
