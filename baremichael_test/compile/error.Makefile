# BareMichael SCC baremetal framework.
# Copyright (C) 2012.  All rights reserved.
#
# NOTE: only compilable with x86 cross compile tools
#

COMPILER_PATH   = /home/soowon/trunk/rckos/shared/tarballs/proj/MCEMU/modules/crosstool/0.42.1/gcc-3.4.5-glibc-2.3.6/i386-unknown-linux-gnu/bin
COMPILER_PREFIX = i386-unknown-linux-gnu-
COMPILER_ROOT   = ${COMPILER_PATH}/${COMPILER_PREFIX}

CC       = ${COMPILER_ROOT}gcc
CPP      = ${COMPILER_ROOT}cpp
LD       = ${COMPILER_ROOT}ld
AS       = ${COMPILER_ROOT}as
AR       = ${COMPILER_ROOT}ar
STRIP    = ${COMPILER_ROOT}strip
OBJCOPY  = ${COMPILER_ROOT}objcopy

BIN2OBJ_TOOL = /home/soowon/trunk/linuxkernel/bin2obj/bin2obj
BOOTCORES = 0 1 5 24 47

RCCE_SUPPORT    = 0
RCCE_GORY       = 0
RCCE_SMALLFLAGS = 0
RCCE_PATH       = ../../RCCE_V2.0

DEFINES = -DI386 -DDETAIL
INCLUDE = -I../include -I../test

CFLAGS = -O0 -m32 -Wall -Wstrict-prototypes -Wno-trigraphs \
		 -nostdinc -fno-builtin -fno-strict-aliasing -fno-common \
		 -fno-pic -ffunction-sections \
		 ${INCLUDE} ${DEFINES} -c
		 #-fomit-frame-pointer used to be included, but no longer.

# GETPROT_ADDR must be low enough to keep the compiled getprotected.S binary
# within a 16-bit address range.
GETPROT_ADDR = 0x00001000
IMG_ADDR = 0x18000000
RESET_VEC_ADDR = 0xfffff000

OBL_ADDR = 0x00001000
KERNEL_ADDR = 0x00090200 

#LDFLAGS = --oformat binary -Ttext $(IMG_ADDR) -melf_i386 -e _start
LDFLAGS = -Ttext $(IMG_ADDR) -melf_i386 -e _start
OCFLAGS = -I elf32-i386 -O binary

PWD = `pwd`
TOPDIR = ..
LIBDIR = ${TOPDIR}/lib

S_FILES = ../boot/startup.S \
		  ../system/halt.S \
		  ../system/intr.S \
		  ../system/enable_caching.S \
		  ../system/clockIRQ.S
C_FILES = ../test/main.c \
		  ../test/RCCE_pingpong.c \
		  ../system/platforminit.c \
		  ../system/interrupt.c \
		  ../system/dispatch.c \
		  ../system/xtrap.c \
		  ../system/scc.c \
		  ../system/apic.c \
		  ../system/clock.c

# First .o file must be startup.o, meaning S_FILES comes first, and first
# file in S_FILES must be startup.S
O_FILES = $(patsubst %.S,%.o,$(S_FILES)) $(patsubst %.c,%.o,$(C_FILES))

# These will be created
LOADMAP  = load.map
RESET_VEC_BIN = ../boot/reset_vector.bin
GETPROT_BIN = ../boot/getprotected.bin
IMAGE_BIN = image.bin
OBJ_FILE = battle.obj
MT_FILE  = battle.mt

OBL_BIN = OBL.bin
KERNEL_BIN = Kernel.bin

# Libraries to build
LIBS = libxc

LIB_ARC = ${LIBS:%=${LIBDIR}/%.a}

ifeq ($(RCCE_SUPPORT),1)
	INCLUDE += -I$(RCCE_PATH)/include
	O_FILES += ../system/rccesupport.o
	DEFINES += -DRCCE_SUPPORT
	ifeq ($(RCCE_GORY),0)
		ifeq ($(RCCE_SMALLFLAGS),0)
			LIB_RCCE = $(RCCE_PATH)/bin/SCC_BAREMETAL/libRCCE_bigflags_nongory_nopwrmgmt.a
		else
			LIB_RCCE = $(RCCE_PATH)/bin/SCC_BAREMETAL/libRCCE_smallflags_nongory_nopwrmgmt.a
		endif
	else
		ifeq ($(RCCE_SMALLFLAGS),0)
			LIB_RCCE = $(RCCE_PATH)/bin/SCC_BAREMETAL/libRCCE_bigflags_gory_nopwrmgmt.a
		else
			LIB_RCCE = $(RCCE_PATH)/bin/SCC_BAREMETAL/libRCCE_smallflags_gory_nopwrmgmt.a
		endif
	endif
endif


# don't delete .o files without my permission!
#.SECONDARY: $(O_FILES)

# Export variables for recursive make calls (such as the library)
export
################
# Make targets #
################
all:
	$(MAKE) clean
	$(MAKE) everything

everything: obj/


obj/: $(OBJ_FILE) $(MT_FILE)
	sccMerge -m 8 -n 12 -noimage $(MT_FILE)

#$(OBJ_FILE): $(RESET_VEC_BIN) $(GETPROT_BIN) $(IMAGE_BIN) $(LOADMAP)
#	$(BIN2OBJ_TOOL) -m $(LOADMAP) -o $@

(OBJ_FILE): $(RESET_VEC_BIN) $(GETPROT_BIN) $(KERNEL_BIN) $(LOADMAP)
	$(BIN2OBJ_TOOL) -m $(LOADMAP) -o $@

# Because .S files must be compiled with gcc, not with as
%.o: %.S
	$(CC) ${CFLAGS} -o $@ $<

$(IMAGE_BIN): $(O_FILES) $(LIB_RCCE) $(LIB_ARC) ld.script
	#$(LD) $(LDFLAGS) -o $@ $^
	$(LD) $(LDFLAGS) -o $(@:%.bin=%.elf) $^
	$(OBJCOPY) $(OCFLAGS) $(@:%.bin=%.elf) $@
	chmod a-x $@

$(RESET_VEC_BIN): $(@:%.bin=%.S)
	#$(CC) $(CFLAGS) -DGETPROT_ADDR=$(GETPROT_ADDR) -o $(@:%.bin=%.o) $(@:%.bin=%.S)
	$(CC) $(CFLAGS) -DGETPROT_ADDR=$(OBL_ADDR) -o $(@:%.bin=%.o) $(@:%.bin=%.S)
	$(LD) --oformat binary -Ttext 0x0 -melf_i386 -o $@ $(@:%.bin=%.o)
	chmod a-x $@

$(GETPROT_BIN): $(@:%.bin=%.S) ../boot/initPaging.o ld.script
	$(CC) $(CFLAGS) -DIMG_ADDR=$(KERNEL_ADDR) -o $(@:%.bin=%.o) $(@:%.bin=%.S)
	$(LD) --oformat binary -Ttext $(GETPROT_ADDR) -melf_i386 -e _start -o $@ $(@:%.bin=%.o) $^
	chmod a-x $@

#$(GETPROT_BIN): $(@:%.bin=%.S) ../boot/initPaging.o ld.script
#	$(CC) $(CFLAGS) -DIMG_ADDR=$(IMG_ADDR) -o $(@:%.bin=%.o) $(@:%.bin=%.S)
#	$(LD) --oformat binary -Ttext $(GETPROT_ADDR) -melf_i386 -e _start -o $@ $(@:%.bin=%.o) $^
#	chmod a-x $@

${LIB_ARC}:
	$(MAKE) -C ${@:%.a=%} install

clean:
	$(MAKE) -C ${LIBDIR}/${LIBS} clean
	rm -f $(RESET_VEC_BIN) $(RESET_VEC_BIN:%.bin=%.o) $(GETPROT_BIN) $(GETPROT_BIN:%.bin=%.o) $(IMAGE_BIN) $(IMAGE_BIN:%.bin=%.elf) $(OBJ_FILE) $(MT_FILE) $(O_FILES) $(LOADMAP) ../boot/initPaging.o
	rm -rf obj/

###################
# Special targets #
###################
deploy: obj/
	sccBoot -g $<

run: obj/
	/opt/sccKit/1.4.0/bin/sccBoot -g $<; /opt/sccKit/1.4.0/bin/sccReset -r $(BOOTCORES)

$(LOADMAP):
	@echo "$(GETPROT_ADDR) $(GETPROT_BIN)" > $(LOADMAP)
	#@echo "$(IMG_ADDR) $(IMAGE_BIN)" >> $(LOADMAP)
	#@echo "$(RESET_VEC_ADDR) $(RESET_VEC_BIN)" >> $(LOADMAP)
	@echo "$(KERNEL_ADDR) $(KERNEL_BIN)" >> $(LOADMAP)
	@echo "$(RESET_VEC_ADDR) $(RESET_VEC_BIN)" >> $(LOADMAP)


$(MT_FILE):
	@echo "# pid mch-route mch-dest-id mch-offset-base testcase" > $(MT_FILE)
	@echo "0x00 0x00 6 0x00 $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x01 0x00 6 0x01 $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x02 0x00 6 0x02 $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x03 0x00 6 0x03 $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x04 0x00 6 0x04 $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x05 0x00 6 0x05 $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x06 0x05 4 0x00 $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x07 0x05 4 0x01 $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x08 0x05 4 0x02 $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x09 0x05 4 0x03 $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x0a 0x05 4 0x04 $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x0b 0x05 4 0x05 $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x0c 0x00 6 0x06 $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x0d 0x00 6 0x07 $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x0e 0x00 6 0x08 $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x0f 0x00 6 0x09 $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x10 0x00 6 0x0a $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x11 0x00 6 0x0b $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x12 0x05 4 0x06 $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x13 0x05 4 0x07 $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x14 0x05 4 0x08 $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x15 0x05 4 0x09 $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x16 0x05 4 0x0a $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x17 0x05 4 0x0b $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x18 0x20 6 0x00 $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x19 0x20 6 0x01 $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x1a 0x20 6 0x02 $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x1b 0x20 6 0x03 $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x1c 0x20 6 0x04 $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x1d 0x20 6 0x05 $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x1e 0x25 4 0x00 $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x1f 0x25 4 0x01 $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x20 0x25 4 0x02 $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x21 0x25 4 0x03 $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x22 0x25 4 0x04 $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x23 0x25 4 0x05 $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x24 0x20 6 0x06 $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x25 0x20 6 0x07 $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x26 0x20 6 0x08 $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x27 0x20 6 0x09 $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x28 0x20 6 0x0a $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x29 0x20 6 0x0b $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x2a 0x25 4 0x06 $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x2b 0x25 4 0x07 $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x2c 0x25 4 0x08 $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x2d 0x25 4 0x09 $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x2e 0x25 4 0x0a $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
	@echo "0x2f 0x25 4 0x0b $(PWD)/$(OBJ_FILE)" >> $(MT_FILE)
