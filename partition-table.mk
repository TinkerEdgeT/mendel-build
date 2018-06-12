ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

partition-table: $(PRODUCT_OUT)/partition-table.img $(PRODUCT_OUT)/partition-table.json

$(PRODUCT_OUT)/partition-table.json: $(ROOTDIR)/build/partition-table.json
	mkdir -p $(PRODUCT_OUT)
	$(ROOTDIR)/tools/bpt/bpttool make_table \
		--input $(ROOTDIR)/build/partition-table.json \
		--output_json $(PRODUCT_OUT)/partition-table.json

$(PRODUCT_OUT)/partition-table.img: $(ROOTDIR)/build/partition-table.json
	mkdir -p $(PRODUCT_OUT)
	$(ROOTDIR)/tools/bpt/bpttool make_table \
		--input $(ROOTDIR)/build/partition-table.json \
		--output_gpt $(PRODUCT_OUT)/partition-table.img

targets::
	@echo "partition-table - builds a partition table image for the eMMC"

clean::
	rm -f $(PRODUCT_OUT)/partition-table.img

.PHONY:: partition-table
