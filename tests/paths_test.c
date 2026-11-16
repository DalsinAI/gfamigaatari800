/* PC test for patches/0001: Util_splitpath and Util_catpath (upstream's
 * util.c, built with A8_AMIGA_PATHS) on AmigaDOS paths, and the Unix
 * paths they took before. MIT, Copyright (c) 2026 AmiCradle Team. */
#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include "config.h"
#include "util.h"

/* what util.c calls from the rest of the emulator */
void Log_print(const char *format, ...) { (void)format; }
void Atari800_ErrExit(void) { }
double PLATFORM_Time(void) { return 0; }
void PLATFORM_Sleep(double s) { (void)s; }

static int fails;

static void split(const char *in, const char *dir, const char *file)
{
	char d[FILENAME_MAX], f[FILENAME_MAX];
	Util_splitpath(in, d, f);
	if (strcmp(d, dir) || strcmp(f, file)) {
		printf("FAIL split %s: \"%s\" \"%s\" (want \"%s\" \"%s\")\n", in, d, f, dir, file);
		fails++;
	}
}

static void cat(const char *a, const char *b, const char *want)
{
	char r[FILENAME_MAX];
	Util_catpath(r, a, b);
	if (strcmp(r, want)) {
		printf("FAIL cat %s + %s: \"%s\" (want \"%s\")\n", a, b, r, want);
		fails++;
	}
}

int main(void)
{
	split("PROGDIR:atari800.cfg", "PROGDIR:", "atari800.cfg");
	split("Work:Atari/Disks/game.atr", "Work:Atari/Disks", "game.atr");
	split("DH1:game.atr", "DH1:", "game.atr");
	split("Work:Atari/", "Work:", "Atari/");
	split("/home/a/x.atr", "/home/a", "x.atr");
	split("x.atr", "", "x.atr");
	cat("PROGDIR:", "atari800.cfg", "PROGDIR:atari800.cfg");
	cat("Work:Atari", "game.atr", "Work:Atari/game.atr");
	cat("Work:Atari/", "game.atr", "Work:Atari/game.atr");
	cat("", "atari800.cfg", "atari800.cfg");
	cat("/home/a", "x", "/home/a/x");
	if (!fails) printf("paths: all checks passed\n");
	return fails != 0;
}
