#include "./multiboot2/multiboot2.h" //include constants for multiboot2 header (GRUB bootloader)
.set HEADER_LENGTH, header_end - header_start
.set CHECKSUM, -(MULTIBOOT2_HEADER_MAGIC + MULTIBOOT_ARCHITECTURE_I386 + HEADER_LENGTH)
.section .multiboot
header_start:
        .long MULTIBOOT2_HEADER_MAGIC
        .long MULTIBOOT_ARCHITECTURE_I386
        .long HEADER_LENGTH
        .long CHECKSUM

        /* multiboot tags go here - none defined */

        .short MULTIBOOT_HEADER_TAG_END
        .short 0    /* flags, none set */
        .long 8     /* size, including itself (short + short + long) */
header_end:

.set KERNEL_OFFSET, 0xFFFFFF8000000000
.set PAGE_SIZE, 4096 /* Size of each page */
.set PAGE_TABLE_ENTRIES, 512 /* number of entries each page have */
.set CR4_PAE, (1 << 5) /* number of entries each page have */

.code32
.section .text
.global _start
.type _start, @function

_start:
        //setup stack
        movl $(stack_top - KERNEL_OFFSET), %esp 

        call check_multiboot
	call check_cpuid
	call check_long_mode

	call setup_page_tables
	call enable_paging
	/* TODO: call setup_SSE */

        /* load the 64-bit GDT */
        lgdt (gdt64_pointer - KERNEL_OFFSET)

        /* Jump directly to external 64-bit C code */
        ljmp $gdt64_code_segment, $(_start64 - KERNEL_OFFSET)
        cli
        hlt

check_multiboot: /* check if a magic value is in eax */
        cmp $MULTIBOOT2_BOOTLOADER_MAGIC, %eax
        jne error 
        ret

.set CPUID_FLAG, 1<<21
/* Check if CPU has support for CPUID instruction */
check_cpuid:
	pushfl /* Save EFLAGS */
	pushfl /* Store EFLAGS */
        xorl $CPUID_FLAG, (%esp) /* Invert ID bit in stored EFLAGS inside stack */
	popfl /* Load stored EFLAGS (with ID bit inverted) */
	pushfl /* Store EFLAGS again (ID bit may or may not be inverted) */
        pop %eax /* eax = modified EFLAGS (ID bit may or may not be inverted) */
        xor (%esp),%eax /* invert bits changed with unchanged */
        popfl /* Restore original EFLAGS */
        and $CPUID_FLAG, %eax /* eax = zero if ID bit can't be changed, else non-zero */
        jz error
        ret


.set EXTENDED_FUNCTIONS, 0x80000000
.set DETECT_LONG_MODE, 0x80000001
check_long_mode:
        movl $EXTENDED_FUNCTIONS, %eax 
	cpuid /* check for extended functions */
	cmp $DETECT_LONG_MODE, %eax /* if less than $DETECT_LONG_MODE */
	jb error /* then it's not supported */

	movl $DETECT_LONG_MODE, %eax
	cpuid /* Run the detection of long mode */
	testl $(1 << 29), %edx /* if Long Mode bit is not set in %edx */
	jz error /* then it's not supported */
	ret

setup_page_tables:
       /* link Page Table 3 to Page Table 4 */
        movl $(pml3 - KERNEL_OFFSET), %eax
        orl $0b11, %eax /* enable flags PRESENT | WRITE */
        movl %eax, (pml4 - KERNEL_OFFSET)
	/* in pml4, skip 511 entries and place it */
        movl %eax, (pml4 - KERNEL_OFFSET) + ((PAGE_TABLE_ENTRIES - 1) * 8)

        /* link Page Table 2 to Page Table 3 */
        movl $(pml2 - KERNEL_OFFSET), %eax
        orl $0b11, %eax
        movl %eax, (pml3 - KERNEL_OFFSET)

        xorl %ecx, %ecx /* %ecx = 0; it's a counter */

1: /* local labels can only be numbers */
        movl $(PAGE_SIZE * PAGE_TABLE_ENTRIES), %eax /* two megabytes: $(1 << 21) || 512 * 4096 */
        mull %ecx /* multiplies %eax by %ecx - the counter */
        orl $0b10000011, %eax /* enable flags PRESENT | WRITE | HUGE */
        movl %eax, pml2 - KERNEL_OFFSET(,%ecx,8) /* write address to page table : same as (pml2 + %ecx * 8) in intel syntax */
        incl %ecx /* %ecx++ */
        cmpl $PAGE_TABLE_ENTRIES, %ecx  /* table is 512 entries sized */
        jne 1b /* do this while table isn't full; b - backwards, f - forwards*/
        ret

.set MSR_EFER, 0xC0000080 /* extended feature register */
.set MSR_EFER_LME, 1<<8 /* extended feature register */
.set CR0_PG, 1<< 31 /*1<<31 - enable paging. 1 - protected mode (Already set by multiboot2 bootloaders) */
enable_paging:
        /* enable PAE */
        movl %cr4, %eax
        orl $CR4_PAE, %eax /* physical address extensions - needed for x86_64 */
        movl %eax, %cr4

        /* pass page table location to cpu */
        movl $(pml4 - KERNEL_OFFSET), %eax
        movl %eax, %cr3

        /* enable long mode */
        /* MSR - Model-Specific Register */
        movl $MSR_EFER, %ecx /* EFER - Extended Feature Enable Register */
        rdmsr

        orl $MSR_EFER_LME, %eax /* bit 8 - Long Mode Enable */
        /* Writes the contents of registers EDX:EAX into the 64-bit model specific register (MSR) specified in the ECX register */
        wrmsr

        /* Activate long mode */
        movl %cr0, %eax
        orl $CR0_PG, %eax /* paging enable */
        movl %eax, %cr0

        ret

error:
	cli 
	hlt 
        jmp error

.code64
_start64:
	// update selectors
	/* they don't matter in 64-bit mode but we still in 32bit here
	 * so set they as gdt64_data_segment or any other value */
	movw $0, %ax
	movw %ax, %ss
	movw %ax, %ds
	movw %ax, %es
        movw %ax, %fs
        movw %ax, %gs
        movabsq $higher_half, %rax /* 64bit register */

        jmp *%rax

higher_half:
	// move stack pointer to kernel space 
	movq $KERNEL_OFFSET, %rax
	add %rax, %rsp

	// remove identity mapping, as we are in higher_half
	movq $0, %rax
	movabsq %rax, (pml4)

	// update page tables (as we modified above)
	movq %cr3, %rax
	movq %rax, %cr3

	// Reload GDT
	movabs $gdt64_pointer, %rax
	lgdt (%rax)

	movabsq $reload_cs, %rax
	push $gdt64_code_segment
	push %rax
	retfq //return far 64bit address
reload_cs:
	.extern kmain
	movabsq $kmain, %rax
	jmp *%rax

	hlt
	jmp .


.section .bss
.balign PAGE_SIZE
pml4:
.zero PAGE_SIZE /* set 4096 bytes as zeros */
pml3:
.zero PAGE_SIZE /* set 4096 bytes as zeros */
pml2:
.zero PAGE_SIZE /* set 4096 bytes as zeros */

.set STACK_SIZE, 1<<14 /* 16384 bytes of stack */
stack_bottom:
.skip STACK_SIZE 
stack_top:

.section .rodata
.align 4 /* bytes */
gdt64:
        .quad 0 /* Null Descriptor */
gdt64_code_entry:
	.set gdt64_code_segment, gdt64_code_entry - gdt64
	/* 64-bit code descriptor - read upwards, endianess */
	.long 0 /* Base and Limit values *IGNORED* */
	.byte 0 /* Base value *IGNORED* */
	.byte 0b10011010 /* Present,code or data,executable,kernel lv,read perm */
	.byte 0b00100000 /* Long mode flag enable */
	.byte 0 /* Base value *IGNORED* in 64bit */
	// .quad 0x00209A0000000000
gdt64_data_entry:
	.set gdt64_data_segment, gdt64_data_entry - gdt64
	/* 64-bit data descriptor - read upwards, endianess */
	.long 0 /* Base and Limit values *IGNORED* */
	.byte 0 /* Base value *IGNORED* */
	.byte 0b10010010 /* Present,code or data,kernel lv,write perm */
	.byte 0 /* No flag enabled */
	.byte 0 /* Base value *IGNORED* in 64bit */
	// .quad 0x0000920000000000
gdt64_pointer:
        .word gdt64_pointer - gdt64 -1 /* 16-bit Size (Limit) of GDT. */
        .quad gdt64 /* 32-bit Base Address of GDT. (CPU will zero extend to 64-bit) */
