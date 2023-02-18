# osdev
Learning and writing a basic bootloader and operating system

For now, it's a Hello Word bootloader in 16-bit real-mode, but it's fine

## Dependencies:
```
- gcc
- nasm
- make
- qemu
- mtools
- dosfstools
```
---

Setup everything and run qemu
```
make all
```
Assemble bootloader
```
make bootloader
```
Make qemu image
```
make image
```
Execute qemu image
```
make run
```
