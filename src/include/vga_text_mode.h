#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

#define VGA_BUFFER_START (uint16_t *)0xB8000
static const size_t VGA_MAX_COLUMNS = 80;
static const size_t VGA_MAX_ROWS = 25;

typedef enum {
	VGA_COLOR_BLACK = 0,
	VGA_COLOR_BLUE = 1,
	VGA_COLOR_GREEN = 2,
	VGA_COLOR_CYAN = 3,
	VGA_COLOR_RED = 4,
	VGA_COLOR_MAGENTA = 5,
	VGA_COLOR_BROWN = 6,
	VGA_COLOR_LIGHT_GREY = 7,
	VGA_COLOR_DARK_GREY = 8,
	VGA_COLOR_LIGHT_BLUE = 9,
	VGA_COLOR_LIGHT_GREEN = 10,
	VGA_COLOR_LIGHT_CYAN = 11,
	VGA_COLOR_LIGHT_RED = 12,
	VGA_COLOR_LIGHT_MAGENTA = 13,
	VGA_COLOR_LIGHT_BROWN = 14,
	VGA_COLOR_WHITE = 15,
} vga_color_t;

static inline uint8_t vga_color(vga_color_t foreground, vga_color_t background,
				bool blink);
static inline uint16_t vga_entry(uint8_t vga_color, uint8_t ascii_char);
size_t strlen(const char *str);
void term_init();
void vga_kputs(const char *str);
void vga_kputc(uint8_t ascii_char);
