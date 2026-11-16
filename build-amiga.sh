#!/bin/sh
# Builds Atari800, the Atari 8-bit computer and 5200 emulator, for GFOS
# (AmigaOS 3.2.3 with GFOpenUp) with a stove: a 68040 or 68060 with its
# FPU, on GFOpenGPU's SDL 2 (the stove's link stubs; SDL2.module at run
# time), hard float as that kit is.
#   STOVE=.../stoves/os32-gcc16-open6 OUT=out ./build-amiga.sh
# Atari800 is fetched at the commit atari800.lock gives; nothing
# third-party is kept here. The PC tests (tests/host-a8.sh: upstream's
# Acid800 suite on the same sources and config) run first when the PC has
# a compiler and SDL 2's development files; HOST_TESTS=0 skips them.
# OUT gets Parts/Atari800: a GFOpenUp part (its Part file and the drawer it
# puts in SYS:Utilities/Atari800; it needs the GFOpenGPU part), installed with
#   GFOpenUpTool INSTALL Parts/Atari800
# and tests/: the Acid800 disk and its expected results, for a lab run:
#   Atari800 -config NIL: -xl-rev altirra -nosound -nobasic -turbo
#            -acid800 acid800.expected acid800.atr
# MIT, Copyright (c) 2026 AmiCradle Team.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/atari800.lock"
. "$HERE/scripts/a8-common.sh"
STOVE=${STOVE:-"$HOME/AmiCradle/stoves/os32-gcc16-open6"}
# outside the checkout: Cradle cleans it (git clean -ffdx) before every job
WORK="${WORK:-$HOME/.cache/gfamigaatari800/build}"; OUT="${OUT:-$WORK/out}"; JOBS=${JOBS:-8}
# the PC tests run on the PC's own PATH: the stove has an sdl2-config too (GFOS's)
HOST_PATH=$PATH
TC="$STOVE/prefix"; PATH="$TC/bin:$PATH"; export PATH
mkdir -p "$WORK" "$OUT"; OUT=$(cd "$OUT" && pwd)
t0=$(date +%s)

# --- the PC tests first: the same sources and config, upstream's Acid800 ------
if [ "${HOST_TESTS:-1}" != 0 ] && (PATH=$HOST_PATH; command -v "${HOST_CC:-cc}") > /dev/null 2>&1; then
    rc=0; PATH=$HOST_PATH WORK="$WORK/host" sh "$HERE/tests/host-a8.sh" > "$WORK/host-tests.log" 2>&1 || rc=$?
    case $rc in
        0) grep -E "^acid800:|checks passed" "$WORK/host-tests.log" ;;
        2) echo "PC tests skipped: $(tail -1 "$WORK/host-tests.log")" ;;
        *) tail -30 "$WORK/host-tests.log"; exit 1 ;;
    esac
fi

# --- SDL 2 from the stove's SDK ------------------------------------------------
SDK="$TC/m68k-amigaos"
for f in include/SDL2/SDL.h lib/libSDL2.a; do
    [ -f "$SDK/$f" ] || { echo "the stove has no $f"; exit 2; }
done

# --- Atari800 at its pinned commit, patches/, the probe ------------------------
SRC="$WORK/atari800"
a8_source "$SRC"
CPU="-m68040 -m68881"
PROBE_CC="m68k-amigaos-gcc -noixemul $CPU" a8_probe "$WORK/probe.h"
echo "probe: $(grep -c '^#define HAVE_' "$WORK/probe.h") functions and headers found"

# --- compile -------------------------------------------------------------------
LATE=""
if m68k-amigaos-gcc -fno-late-combine-instructions -S -o /dev/null -x c /dev/null 2>/dev/null; then LATE="-fno-late-combine-instructions"; fi
# no loops turned into memset/memcpy calls (GCC 16), address 0 is memory
CF="-noixemul $CPU -O2 -fomit-frame-pointer -fno-tree-loop-distribute-patterns -fno-delete-null-pointer-checks $LATE \
 -std=gnu99 -Werror=implicit-function-declaration -I$WORK -I$HERE/amiga -I$SRC/src -I$SDK/include/SDL2 \
 -DA8_VERSION=\\\"$A8_VERSION\\\" -DA8_DATE=\\\"$(date -u +%d.%m.%Y)\\\""
O="$WORK/obj"
[ "$(cat "$O/.src" 2>/dev/null)" = "$(cat "$SRC/.patched")" ] || { rm -rf "$O"; mkdir -p "$O"; cat "$SRC/.patched" > "$O/.src"; }
M="$O/Makefile"
{
    echo "CF = $CF"
    A=""
    for f in $A8_SRCS; do
        o="$(echo "$f" | tr / _ | sed 's/\.c$/.o/')"; A="$A $o"
        printf '%s: %s\n\tm68k-amigaos-gcc $(CF) -MMD -c $< -o $@\n' "$o" "$SRC/src/$f"
    done
    A="$A amiga_start.o"
    printf 'amiga_start.o: %s\n\tm68k-amigaos-gcc $(CF) -c $< -o $@\n' "$HERE/amiga/amiga_start.c"
    echo "OBJS =$A"
    echo "all: \$(OBJS)"
    echo "-include *.d"
} > "$M"
(cd "$O" && nice -n 19 make -k -j"$JOBS" all > make.log 2>&1) || { grep -E 'error' "$O/make.log" | head -40; tail -20 "$O/make.log"; exit 1; }
echo "compile: $(( $(date +%s) - t0 )) s"

# --- link ------------------------------------------------------------------------
# shellcheck disable=SC2046
m68k-amigaos-gcc -noixemul $CPU -o "$O/Atari800.debug" \
    $(cd "$O" && for f in $(sed -n 's/^OBJS =//p' Makefile); do echo "$O/$f"; done) \
    -L"$SDK/lib" -lSDL2 -lm > "$O/link.log" 2>&1 || { head -60 "$O/link.log"; exit 1; }

# --- the GFOpenUp part: Parts/Atari800 --------------------------------------------
P="$OUT/Parts/Atari800"; D="$P/Utilities/Atari800"; rm -rf "$P"; mkdir -p "$D"
m68k-amigaos-strip -o "$D/Atari800" "$O/Atari800.debug"
cp "$HERE/README.md" "$D/ReadMe"
cp "$SRC/COPYING" "$D/COPYING"
cp "$SRC/DOC/USAGE" "$D/USAGE"
cp "$SRC/README.TXT" "$D/README.TXT"
sh "$HERE/scripts/write-part.sh" "$P" "$A8_VERSION"
# the Acid800 suite, for a lab run (not in the part)
rm -rf "$OUT/tests"; mkdir -p "$OUT/tests"
cp "$SRC/test/acid800.atr" "$SRC/test/acid800.expected" "$OUT/tests/"
ls -l "$D/Atari800"
echo "part: $(grep -c '^copy' "$P/Part") files, $(du -sk "$P" | cut -f1) KB"
echo "total: $(( $(date +%s) - t0 )) s"
