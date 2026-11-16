/* Atari800's config.h for GFOS (and for the PC tests, which build the same
 * set): what upstream's configure gives for
 *   --target=default --with-video=sdl2 --with-sound=sdl2 --without-opengl
 *   --without-readline --disable-netsio --disable-riodevice
 *   --disable-videorecording --disable-download
 * less zlib and libpng (no PNG screenshots: PCX; no event recording;
 * plain, not gzip'd, disk images and state files), with the functions and
 * headers the stove's C library has coming from probe.h, which
 * scripts/a8-common.sh writes by linking each one, as configure does.
 * MIT, Copyright (c) 2026 AmiCradle Team. */
#ifndef GFAMIGA_ATARI800_CONFIG_H
#define GFAMIGA_ATARI800_CONFIG_H

#include "probe.h"

#define PACKAGE "atari800"
#define PACKAGE_NAME "Atari800"
#define PACKAGE_TARNAME "atari800"
#define PACKAGE_BUGREPORT "pstehlik@sophics.cz"
#define PACKAGE_URL ""
#define PACKAGE_VERSION A8_VERSION
#define PACKAGE_STRING "Atari800 " A8_VERSION
#define VERSION A8_VERSION
#define STDC_HEADERS 1

/* the target: SDL 2 for the picture, the sound and the input */
#define SDL2 1
#define GUI_SDL 1
#define SUPPORTS_CHANGE_VIDEOMODE 1
#define SUPPORTS_ROTATE_VIDEOMODE 1
#define SUPPORTS_PLATFORM_CONFIGINIT 1
#define SUPPORTS_PLATFORM_CONFIGSAVE 1
#define SUPPORTS_PLATFORM_CONFIGURE 1
#define SUPPORTS_PLATFORM_PALETTEUPDATE 1
#define SUPPORTS_PLATFORM_SLEEP 1
#define SUPPORTS_PLATFORM_TIME 1
#define PLATFORM_MAP_PALETTE 1
#define USE_UI_BASIC_ONSCREEN_KEYBOARD 1

/* the emulation, as upstream's defaults */
#define EMUOS_ALTIRRA 1         /* Altirra's free OS and BASIC built in: no ROM files needed */
#define NEW_CYCLE_EXACT 1
#define CRASH_MENU 1
#define NTSC_FILTER 1
#define PAL_BLENDING 1
#define MONITOR_ANSI 1
#define MONITOR_ASSEMBLER 1
#define MONITOR_BREAK 1
#define MONITOR_HINTS 1
#define MONITOR_UTF8 1
/* no EVENT_RECORDING: it writes and reads its files through zlib's gz*
   calls, which z.library (GFOpenZlib) doesn't offer */
#define PBI_MIO 1
#define PBI_BB 1
#define PBI_XLD 1
#define PBI_PROTO80 1
#define AF80 1
#define BIT3 1
#define XEP80_EMULATION 1
#define VOICEBOX 1
#define IDE 1
#define POKEYREC 1
#define SCREENSHOTS 1           /* PCX: no libpng */
#define AUDIO_RECORDING 1       /* WAV: PCM, ADPCM, mu-law */

/* the sound */
#define SOUND 1
#define SOUND_CALLBACK 1
#define STEREO_SOUND 1
#define CONSOLE_SOUND 1
#define NONLINEAR_MIXING 1
#define INTERPOLATE_SOUND 1

/* the CPU: the 68040 is big-endian and reads words at any even or odd address */
#if defined(__BYTE_ORDER__) && __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
#define WORDS_BIGENDIAN 1
#endif
#define WORDS_UNALIGNED_OK 1

#ifdef __amigaos__
/* AmigaDOS paths (patches/0001): settings and ROMs in the program's drawer */
#define A8_AMIGA_PATHS 1
#define DEFAULT_CFG_NAME "atari800.cfg"
#endif

#endif
