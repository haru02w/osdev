#include <vga/text_mode.h>

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

void vga_set_color(vga_color_t foreground, vga_color_t background, bool blink)
{
	vga_term_color = vga_color(foreground, background, blink);
}

void vga_term_init()
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
	return;
}

void vga_clean_row(size_t vga_term_row)
{
	for (size_t i = 0; i < VGA_MAX_COLUMNS; i++)
		vga_term_buffer[vga_term_row * VGA_MAX_COLUMNS + i] =
			vga_entry(vga_term_color, ' ');
	return;
}
void vga_shift_term_up(size_t shift_rows)
{
	for (size_t row = shift_rows; row < VGA_MAX_ROWS; row++)
		for (size_t column = 0; column < VGA_MAX_COLUMNS; column++)
			vga_term_buffer[(row - shift_rows) * VGA_MAX_COLUMNS +
					column] =
				vga_term_buffer[row * VGA_MAX_COLUMNS + column];
}

void vga_kputc(uint8_t ascii_char)
{
	switch (ascii_char) {
	case ' ' ... '~':
		if ((vga_term_column %= VGA_MAX_COLUMNS) == 0)
			++vga_term_row;
		if (vga_term_row >= VGA_MAX_ROWS) {
			vga_shift_term_up(vga_term_row - (VGA_MAX_ROWS - 1));
			vga_term_row = VGA_MAX_ROWS - 1;
			vga_clean_row(vga_term_row);
		}
		vga_term_buffer[vga_term_row * VGA_MAX_COLUMNS +
				vga_term_column] =
			vga_entry(vga_term_color, ascii_char);
		++vga_term_column;
		break;
	case '\a':
	case '\b':
	case '\e':
	case '\f':
		//TODO
		break;
	case '\n':
		++vga_term_row;
	case '\r':
		vga_term_column = 0;
		break;
	case '\t':
		vga_term_column += 8;
		break;
	case '\v':
		//TODO
		break;
	}
	return;
}

void vga_kputs(const char *str)
{
	size_t i = 0;
	while (str[i]) {
		vga_kputc(str[i]);
		++i;
	}
	return;
}
