TARGET_ARCH := amd64
BUILD_DIR := ./build
OBJ_DIR := $(BUILD_DIR)/obj
SRC_DIR := ./src
INCLUDE_DIR := -I$(SRC_DIR)/include/libk/ -I$(SRC_DIR)/include/libc/

# SRCS := $(shell find $(SRC_DIR/**) -name '*.c' -or -name '*.S')
# OBJS := $(patsubst %,$(BUILD_DIR)/%.o,$(notdir $(basename $(SRCS))))

C_SRC_FILES := $(shell find $(SRC_DIR) -name '*.c')
C_OBJ_FILES := $(patsubst %,$(BUILD_DIR)/%.o,$(notdir $(basename $(C_SRC_FILES))))

ASM_SRC_FILES := $(shell find $(SRC_DIR) -name '*.S')
ASM_OBJ_FILES := $(patsubst %,$(BUILD_DIR)/%.o,$(notdir $(basename $(ASM_SRC_FILES))))


#WARNING
FINAL_BIN := kernel.elf64

.SUFFIXES:

.PHONY: all
.PHONY: qemu
.PHONY: clean

all: $(C_OBJ_FILES) $(ASM_OBJ_FILES)
	ld -n -T $(SRC_DIR)/linker.ld -o $(BUILD_DIR)/$(FINAL_BIN) $^

$(C_OBJ_FILES): $(BUILD_DIR)/%.o : $(C_SRC_FILES)
	mkdir -p $(dir $@)
	gcc -g -c $(INCLUDE_DIR) -ffreestanding -nostdlib -o $@ $(shell find $(SRC_DIR) -name '$(patsubst %,%.c,$(notdir $(basename $@))'))

$(ASM_OBJ_FILES): $(BUILD_DIR)/%.o : $(ASM_SRC_FILES)
	mkdir -p $(dir $@)
	gcc -g -c -I $(INCLUDE_DIR) -ffreestanding -nostdlib -o $@ $(shell find $(SRC_DIR) -name '$(patsubst %,%.S,$(notdir $(basename $@))'))

qemu: all
	rm -f haruOSw.iso
	mkdir -p sysroot/boot/grub
	cp $(BUILD_DIR)/$(FINAL_BIN) sysroot/boot/
	cp $(SRC_DIR)/arch/amd64/multiboot2/grub.cfg sysroot/boot/grub/
	grub-mkrescue /usr/lib/grub/i386-pc -o haruOSw.iso sysroot/
	
qemurun: qemu
	qemu-system-x86_64 -hda haruOSw.iso
clean:
	rm -Rf ./build
qemudebug: qemu
	qemu-system-x86_64 -S -s -hda haruOSw.iso &
	gdb
# curl -L https://git.savannah.gnu.org/cgit/grub.git/plain/doc/multiboot2.h?h=multiboot2 > ./boot/multiboot2/amd64/multiboot2.h
