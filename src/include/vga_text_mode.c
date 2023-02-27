#include <stddef.h>
#include <vga_text_mode.h>

size_t vga_term_row;
size_t vga_term_column;
uint8_t vga_term_color;
uint16_t *vga_term_buffer;

static inline uint8_t vga_color(vga_color_t foreground, vga_color_t background,
				bool blink)
{
	return (background << 4) | foreground | (blink << 15);
}
static inline uint16_t vga_entry(uint8_t vga_color, uint8_t ascii_char)
{
	return (vga_color << 8) | ascii_char;
}

size_t strlen(const char *str)
{
	size_t i = 0;
	while (str[i])
		i++;
	return i;
}

void term_init()
{
	vga_term_row = 0;
	vga_term_column = 0;
	vga_term_buffer = VGA_BUFFER_START;
	vga_term_color = vga_color(VGA_COLOR_LIGHT_GREY, VGA_COLOR_BLACK,
				   /* blink = */ false);
	for (size_t row = 0; row < VGA_MAX_ROWS; row++)
		for (size_t column = 0; column < VGA_MAX_COLUMNS; column++)
			vga_term_buffer[row * VGA_MAX_COLUMNS + column] =
				vga_entry(vga_term_color, ' ');
}

void vga_kputc(uint8_t ascii_char)
{
	/* is printable?*/
	if (ascii_char >= ' ' && ascii_char <= '~') { //WARNING - make a library
		vga_term_buffer[vga_term_row * VGA_MAX_COLUMNS +
				vga_term_column] =
			vga_entry(vga_term_color, ascii_char);
		++vga_term_column;
		if ((vga_term_column %= VGA_MAX_COLUMNS) == 0)
			++vga_term_row;
		return;
	}

	switch (ascii_char) {
	case '\a':
	case '\b':
	case '\e':
	case '\f':
		vga_kputs(" Key not implemented yet! ");
		break;
	case '\n':
		//TODO
		// while (--vga_term_column >= 0) {
		// 	vga_term_buffer[vga_term_row * VGA_MAX_COLUMNS +
		// 			vga_term_column] =
		// 		vga_entry(vga_term_color, ascii_char);
		// }
		break;
	case '\r':
		//TODO
		break;
	case '\t':
		//TODO
		break;
	case '\v':
		//TODO
		break;
	}
}

void vga_kputs(const char *str)
{
	size_t i = 0;
	while (str[i]) {
		vga_kputc(str[i]);
		++i;
	}
}
