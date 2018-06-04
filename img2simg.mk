ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

LIBSPARSE_DIR := $(ROOTDIR)/tools/img2simg/libsparse
LIBSPARSE_OUT := $(HOST_OUT)/obj/LIBSPARSE

IMG2SIMG_SOURCES := img2simg.c
IMG2SIMG_SOURCES := $(foreach source, $(IMG2SIMG_SOURCES), $(LIBSPARSE_DIR)/$(source))

SIMG2IMG_SOURCES := simg2img.c
SIMG2IMG_SOURCES := $(foreach source, $(SIMG2IMG_SOURCES), $(LIBSPARSE_DIR)/$(source))

LIBSPARSE_SOURCES := backed_block.c output_file.c sparse.c sparse_crc32.c sparse_err.c sparse_read.c
LIBSPARSE_OBJS    := $(patsubst %.c,%.o,$(LIBSPARSE_SOURCES))

# Fixup the paths to fit our output locations
LIBSPARSE_SOURCES := $(foreach source, $(LIBSPARSE_SOURCES), $(LIBSPARSE_DIR)/$(source))
LIBSPARSE_OBJS    := $(foreach obj, $(LIBSPARSE_OBJS), $(LIBSPARSE_OUT)/$(obj))

img2simg: $(HOST_OUT)/bin/img2simg

simg2img: $(HOST_OUT)/bin/simg2img

$(HOST_OUT)/bin/img2simg: $(IMG2SIMG_SOURCES) $(LIBSPARSE_OBJS)
	mkdir -p $(dir $@)
	$(CXX) $^ -o $@ -I$(LIBSPARSE_DIR)/include -lz

$(HOST_OUT)/bin/simg2img: $(SIMG2IMG_SOURCES) $(LIBSPARSE_OBJS)
	mkdir -p $(dir $@)
	$(CXX) $^ -o $@ -I$(LIBSPARSE_DIR)/include -lz

$(LIBSPARSE_OUT)/%.o: $(LIBSPARSE_DIR)/%.c
	mkdir -p $(LIBSPARSE_OUT)
	$(CC) $< -c -o $@ -I$(LIBSPARSE_DIR)/include -I$(dir $(LIBSPARSE_DIR))/include

targets::
	@echo "img2simg - builds the sparse image conversion tool"
	@echo "simg2img - builds the unsparse image conversion tool"

clean::
	rm -f $(HOST_OUT)/bin/img2simg
	rm -f $(HOST_OUT)/bin/simg2img
	rm -rf $(LIBSPARSE_OUT)

.PHONY:: img2simg simg2img
