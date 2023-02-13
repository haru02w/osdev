# verify if nasm, gcc, make, qemu are installed
#
#
ASM=nasm
BOOTLOADER_DIR=./src/bootloader
BUILD_DIR=./build

all: image bootloader run

bootloader: $(BUILD_DIR)/bmain.bin

image: $(BUILD_DIR)/floppy.img 

run: 
	qemu-system-i386 -fda $(BUILD_DIR)/floppy.img

$(BUILD_DIR)/floppy.img: $(BUILD_DIR)/bmain.bin
	cp $(BUILD_DIR)/bmain.bin $(BUILD_DIR)/floppy.img
	truncate -s 1440k $(BUILD_DIR)/floppy.img

$(BUILD_DIR)/bmain.bin: $(BOOTLOADER_DIR)/bmain.asm
	$(ASM) $(BOOTLOADER_DIR)/bmain.asm -f bin -o $(BUILD_DIR)/bmain.bin

