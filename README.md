# GFAmigaAtari800

Atari800 7.2.1, the emulator of the Atari 400, 800, 600XL, 800XL, 130XE,
XEGS and 5200, for GFOS (AmigaOS 3.2.3 with GFOpenUp) on a 68040 or 68060
with its FPU, on GFOpenGPU's SDL 2. Installed as a GFOpenUp part in
`SYS:Utilities/Atari800`.

Status: built for the PC from the same sources and settings and passing
upstream's Acid800 suite there (see Tests); the Amiga build is made by
the stove, not yet run in a lab.

## What you need

- GFOS: AmigaOS 3.2 with GFOpenUp and its GFOpenGPU part
  (`LIBS:GFOpenGPU/SDL2.module` draws, plays and reads the joysticks).
- A 68040 or 68060 with an FPU (not an LC040 or EC040).
- No ROM files: Altirra's free OS (400/800 and XL/XE) and BASIC are built
  in. Atari's own ROMs work too: put them in the drawer (`ATARIXL.ROM`,
  `ATARIBAS.ROM`, `ATARIOSB.ROM`, `5200.ROM` and so on) and Atari800
  finds them at its first start, or set them in its menu (F1).

## Using it

    cd SYS:Utilities/Atari800
    Atari800 Work:Atari/Disks/game.atr
    Atari800 -xl -basic          ; an XL with BASIC
    Atari800 -5200 Work:Atari/5200/cart.a52

F1 is the menu (disks, cartridges, machine, display, sound, settings),
F8 the monitor, F9 quits; `USAGE` in the drawer has every option. The
settings are kept in `PROGDIR:atari800.cfg` (the program's own drawer).
Disk images (ATR, XFD, DCM, PRO, ATX), cartridges (CAR, ROM, BIN),
executables (XEX, COM), BASIC programs, cassettes (CAS) and saved states
load from any AmigaDOS path.

## On AmigaOS

- Paths are AmigaDOS paths (`patches/0001`): `Volume:` ends a path part,
  and the settings and ROMs live in the program's drawer (`PROGDIR:`)
  however it was started.
- Not in this build (they need zlib's gz* file calls, which z.library,
  GFOpenZlib, doesn't have): gzip'd disk images and states (`.atz`,
  `.gz`), event recording and playback, PNG screenshots (PCX is there)
  and AVI video recording. WAV sound recording is there.
- No R: device or FujiNet (NetSIO): they need host sockets and threads.

## Building

    STOVE=~/AmiCradle/stoves/os32-gcc16-open6 OUT=out sh build-amiga.sh

or in Cradle, stove_build with the os32-gcc16-open6 stove, target `.`.
Atari800 is fetched at the commit `atari800.lock` pins. `OUT` gets
`Parts/Atari800` (the part) and `tests/` (the Acid800 disk and its
expected results, for a lab run).

## Tests

`make -C tests test` on a PC with SDL 2's development files: the Part
file, then `tests/host-a8.sh`, which builds Atari800 for the PC from the
same patched sources and `amiga/config.h`, runs upstream's Acid800 suite
(CPU, ANTIC, POKEY, PIA, GTIA and MMU tests, each against upstream's
expected results; 24 pass, 28 are upstream's known failures, none
regress) with SDL's dummy drivers, and checks `patches/0001`'s path rules
on upstream's own `Util_splitpath` and `Util_catpath`.

In a lab, after installing the part:

    cd SYS:Utilities/Atari800
    Atari800 -config NIL: -xl-rev altirra -nosound -nobasic -turbo -acid800 acid800.expected acid800.atr

prints the same table and returns 0 when nothing regressed.

## What was changed

- `patches/0001`: `Util_splitpath` and `Util_catpath` know `Volume:`
  paths; the program's directory is `PROGDIR:`.
- `amiga/config.h`: configure's answers for this set, with the C
  library's functions and headers from `scripts/a8-common.sh`'s probe
  (each one linked with the stove's compiler, as configure does).
- `amiga/amiga_start.c`: 256 KB of stack and the `$VER` string.

Designed, tested and delivered by The AmiCradle Team.
