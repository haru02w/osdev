#include "../multiboot2.h"
.set HEADER_LENGTH, header_end - header_start
.set CHECKSUM, -(MULTIBOOT2_HEADER_MAGIC + MULTIBOOT_ARCHITECTURE_I386 + HEADER_LENGTH)
.section .multiboot
header_start:
        .long MULTIBOOT2_HEADER_MAGIC
        .long MULTIBOOT_ARCHITECTURE_I386
        .long HEADER_LENGTH
        .long CHECKSUM

        /* multiboot tags go here*/

        .short MULTIBOOT_HEADER_TAG_END
        .short 0    /* flags, none set */
        .long 8     /* size, including itself (short + short + long) */
header_end:

.set PAGE_SIZE, 4096 /* Size of each page */
.set PAGE_TABLE_ENTRIES, 512 /* number of entries each page have */
.set CR4_PAE, (1 << 5) /* number of entries each page have */
.code32

.section .text
.global _start
.type _start, @function

_start:
        movl stack_top, %esp 
        //setup stack
        call check_multiboot
	call check_cpuid
	call check_long_mode

	call setup_page_tables
	call enable_paging
	/* TODO: call setup_SSE */

        /* load the 64-bit GDT */
        lgdt (gdt64_pointer)

        /* Setup segment selectors */
        movw $0, %ax
        movw %ax, %ss
        movw %ax, %ds
        movw %ax, %es
        movw %ax, %fs
        movw %ax, %gs

        /* Jump to external 64-bit C code */
        /* CALL instruction changes increment stack and
         * we don't want to waste stack space 
         */
        ljmp $gdt64_code_segment, $kmain

check_multiboot:
        cmp MULTIBOOT2_BOOTLOADER_MAGIC, %eax
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


check_long_mode:
#WARNING - Make a constant
        movl $0x80000000, %eax
	cpuid
	cmp $0x80000001, %eax
	jb error

	movl $0x80000001, %eax
	cpuid
#WARNING - Make a constant
	testl $(1 << 29), %edx
	jz error 
	ret

setup_page_tables:
        movl $pml3, %eax
        orl $0b11, %eax /* PRESENT | WRITE */
        movl %eax, pml4

        movl $pml2, %eax
        orl $0b11, %eax
        movl %eax, pml3

        xorl %ecx, %ecx /* set %ecx == 0 */
1: /* local labels can only be numbers */
        movl $(PAGE_SIZE * PAGE_TABLE_ENTRIES), %eax /* two megabytes $(1 << 21) */
        mull %ecx /* %ecx is a counter, starts with 0 */
        orl $0b10000011, %eax /* PRESENT | WRITE | HUGE */
        movl %eax, pml2(,%ecx,8) /*same as (pml2 + %ecx * 8)*/
        incl %ecx /* %ecx++ */
        cmpl $PAGE_TABLE_ENTRIES,%ecx  /* table is 512 entries sized */
        jne 1b /* b - backwards, f - forwards; do it while table isn't full */
        ret

.set MSR_EFER, 0xc0000080 /* extended feature register */
.set MSR_EFER_LME, 1<<8 /* extended feature register */
.set CR0_PG, 1<< 31 /*1<<31 - enable paging. 1 - protected mode (Already set by multiboot2 bootloaders) */
enable_paging:
        /* enable PAE */
        movl %cr4, %eax
        orl $CR4_PAE, %eax /* physical address extensions - needed for x86_64 */
        movl %eax, %cr4

        /* pass page table location to cpu */
        movl $pml4, %eax
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
        CLI
        HLT
        JMP error


.section .bss
.balign PAGE_SIZE
pml4:
.zero PAGE_SIZE /*.zero num = number of bytes*/
pml3:
.zero PAGE_SIZE
pml2:
.zero PAGE_SIZE

.set STACK_SIZE, 1<<14 /* 16384 bytes of stack */
stack_bottom:
.zero STACK_SIZE 
stack_top:

.section .rodata
.align 4
gdt64:
        .quad 0 /* Null Descriptor */
gdt64_code_entry:
/* Intel/AMD gods decided, so I follow */
/* Read the manual for x86_64 to learn more */
.set gdt64_code_segment, gdt64_code_entry - gdt64
        .quad 0x00209A0000000000 /* 64-bit code descriptor (exec/read). */
gdt64_data_entry:
.set gdt64_data_segment, gdt64_data_entry - gdt64
        .quad 0x0000920000000000 /* 64-bit data descriptor (read/write). */

gdt64_pointer:
        .word gdt64_pointer - gdt64 -1 /* 16-bit Size (Limit) of GDT. */
        .quad gdt64 /* 32-bit Base Address of GDT. (CPU will zero extend to 64-bit) */
