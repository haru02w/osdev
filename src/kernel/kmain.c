#include <vga/text_mode.h>

__attribute__((__noreturn__)) void kmain()
{
	vga_term_init();
	vga_kputs("HaruOSw\n"
		  "\t1) Booting, DONE\n"
		  "\t2) Printing text on screen, DONE\n"
		  "\t3)Higher Half Mapping DONE\n");
	vga_kputs("In progress:\n"
		  "1) Split code into more libraries"
		  "2) Translate most parts to C code"
		  "3) Setup interrupts for keyboard input"
		  "4) Setup an memory manager "
		  "5) list goes on...");

	asm("cli");
	asm("hlt");
	/* function never reachable, produces undefined behavior */
	__builtin_unreachable();
}
