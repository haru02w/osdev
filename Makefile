ASM=nasm
BOOTLOADER_DIR=./src
KERNEL_DIR=./src/kernel
BUILD_DIR=./build

all: image bootloader kernel debug

bootloader: $(BUILD_DIR)/boot.bin mkdir

kernel: $(BUILD_DIR)/kernel.bin mkdir

image: $(BUILD_DIR)/floppy.img 

run: 
	qemu-system-i386 -fda $(BUILD_DIR)/floppy.img 

$(BUILD_DIR)/floppy.img: bootloader kernel
	dd if=/dev/zero of=$(BUILD_DIR)/floppy.img bs=512 count=2880 #1440k size of a floppy disk
	mkfs.fat -F 12 -n "HWOS" $(BUILD_DIR)/floppy.img 
	dd if=$(BUILD_DIR)/boot.bin of=$(BUILD_DIR)/floppy.img conv=notrunc #do not truncate the file
	mcopy -i $(BUILD_DIR)/floppy.img $(BUILD_DIR)/kernel.bin "::kernel.bin"

$(BUILD_DIR)/boot.bin: $(BOOTLOADER_DIR)/boot.asm
	$(ASM) $(BOOTLOADER_DIR)/boot.asm -f bin -o $(BUILD_DIR)/boot.bin

$(BUILD_DIR)/kernel.bin: $(KERNEL_DIR)/kernel.asm
	$(ASM) $(KERNEL_DIR)/kernel.asm -f bin -o $(BUILD_DIR)/kernel.bin

mkdir:
	mkdir -p $(BUILD_DIR)
clean:
	rm -Rf $(BUILD_DIR)/*
debug:
	qemu-system-i386 -fda $(BUILD_DIR)/floppy.img -S -s &
	gdb -ex 'target remote localhost:1234' \
    		-ex 'set architecture i8086' \
    		-ex 'break *0x7c00' \
    		-ex 'continue'

