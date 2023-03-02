ENTRY(_start)

KERNEL_OFFSET = 0xFFFFFF8000000000;
SECTIONS
{
	. = 0x10000 + KERNEL_OFFSET;
	_kernel_start = . ;
	.text : AT(ADDR(.text ) - KERNEL_OFFSET)
	{
		*(.multiboot )
		*(.text)
	}
	.rodata : AT(ADDR(.rodata ) - KERNEL_OFFSET)
	{
		*(.rodata )
	}
	.data : AT(ADDR(.data ) - KERNEL_OFFSET)
	{
		*(.bss)
	}
	.bss : AT(ADDR(.bss ) - KERNEL_OFFSET)
	{
		*(.bss)
	}
	_kernel_end = . ;
}

