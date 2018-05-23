ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

include $(ROOTDIR)/build/preamble.mk

IMG2SIMG_SRCS_CXX := \
	system/core/base/stringprintf.cpp \
	system/core/libsparse/sparse_read.cpp

IMG2SIMG_SRCS_C := \
	system/core/libsparse/backed_block.c \
	system/core/libsparse/img2simg.c \
	system/core/libsparse/output_file.c \
	system/core/libsparse/sparse.c \
	system/core/libsparse/sparse_crc32.c \
	system/core/libsparse/sparse_err.c

IMG2SIMG_INCLUDES := \
	system/core/base/include \
	system/core/libsparse/include

IMG2SIMG_INCLUDES := $(addprefix -I,$(IMG2SIMG_INCLUDES))

img2simg: $(HOST_OUT)/bin/img2simg

$(HOST_OUT)/bin/img2simg:
	mkdir -p $(HOST_OUT)/bin
	mkdir -p $(HOST_OUT)/obj/IMG2SIMG
	$(foreach infile, $(IMG2SIMG_SRCS_CXX), g++ -include string.h $(IMG2SIMG_INCLUDES) -c $(infile) -o $(HOST_OUT)/obj/IMG2SIMG/$(notdir $(patsubst %.cpp,%.o,$(infile))); )
	$(foreach infile, $(IMG2SIMG_SRCS_C), gcc $(IMG2SIMG_INCLUDES) -c $(infile) -o $(HOST_OUT)/obj/IMG2SIMG/$(notdir $(patsubst %.c,%.o,$(infile))); )
	gcc -o $(HOST_OUT)/bin/img2simg $(HOST_OUT)/obj/IMG2SIMG/* -lz -lstdc++

clean::
	rm -rf $(HOST_OUT)/obj/IMG2SIMG
	rm -f $(HOST_OUT)/bin/img2simg

targets::
	@echo "img2simg - builds a copy of the img2simg utility"

.PHONY:: img2simg
