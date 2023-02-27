ENTRY(_start)

SECTIONS
{
	. = 1M;
	.text :
	{
		*(.multiboot)
		*(.text)
	}
	.rodata :
	{
		*(.rodata)
	}
	.bss :
	{
		*(.bss)
	}

}
