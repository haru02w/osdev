TARGET_ARCH := amd64
BUILD_DIR := ./build
OBJ_DIR := $(BUILD_DIR)/obj
SRC_DIR := ./src
INCLUDE_DIR := $(SRC_DIR)/include

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
	gcc -c -I $(INCLUDE_DIR) -ffreestanding -nostdlib -o $@ $(shell find $(SRC_DIR) -name '$(patsubst %,%.c,$(notdir $(basename $@))'))

$(ASM_OBJ_FILES): $(BUILD_DIR)/%.o : $(ASM_SRC_FILES)
	mkdir -p $(dir $@)
	gcc -c -I $(INCLUDE_DIR) -ffreestanding -nostdlib -o $@ $(shell find $(SRC_DIR) -name '$(patsubst %,%.S,$(notdir $(basename $@))'))

qemu: all
	mkdir -p vm/boot/grub
	cp $(BUILD_DIR)/$(FINAL_BIN) vm/boot/
	cp $(SRC_DIR)/boot/multiboot2/grub.cfg vm/boot/grub/
	grub-mkrescue /usr/lib/grub/i386-pc -o vm/haruOSw.iso vm
	
qemurun: qemu
	qemu-system-x86_64 -hda vm/haruOSw.iso
clean:
	rm -Rf ./build

# curl -L https://git.savannah.gnu.org/cgit/grub.git/plain/doc/multiboot2.h?h=multiboot2 > ./boot/multiboot2/amd64/multiboot2.h
