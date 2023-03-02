# First of all:

This is a hobby operational system that can turn into
something more in future

# Booting

BIOS/UEFI -> Bootloader -> Assembly code -> C code 

Bootloader: 
* MULTIBOOT2 (GRUB2) - jumps to code in 32-bit protected mode
* LIMINE - jumps to code in 64-bit protected mode

IF Bootloader == MULTIBOOT2:
        Assembly code to switch to 64-bit mode, setup stack, pages, etc.
ELSE IF Bootloader == LIMINE
        Go directly into C code in 64-bit mode with all already setup

For while, I'm using GRUB MULTIBOOT2 boot method but it's planed to also implement
limine protocol
