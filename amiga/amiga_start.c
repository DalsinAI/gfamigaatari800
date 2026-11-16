/* Atari800 on GFOS: the stack (the Shell's 4 KB is too small for the
 * emulator's menus and monitor) and the $VER string.
 * MIT, Copyright (c) 2026 AmiCradle Team. */
unsigned long __stack = 256 * 1024;
static const char version[] __attribute__((used)) =
	"$VER: Atari800 " A8_VERSION " (" A8_DATE ") GFOS";
