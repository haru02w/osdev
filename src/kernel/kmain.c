#include <vga_text_mode.h>

__attribute__((__noreturn__)) void kmain()
{
	asm("cli");
	asm("hlt");
	/* function never reachable, produces undefined behavior */
	__builtin_unreachable();
}
