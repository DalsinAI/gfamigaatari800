#!/bin/sh
# Atari800 built for the PC the way build-amiga.sh builds it for GFOS (the
# same patches, amiga/config.h with the PC's probe.h, the same sources),
# then upstream's own "make check" on it with SDL's dummy drivers:
#   the Acid800 suite (test/acid800.atr: CPU, ANTIC, POKEY, PIA, GTIA and
#   MMU tests, each result against test/acid800.expected); not the
#   playback of test/playback.rec, which needs event recording (zlib's gz*
#   calls, which z.library doesn't have),
# and the AmigaDOS path rules of patches/0001 (tests/paths_test.c).
#   sh tests/host-a8.sh     (needs a C compiler and SDL 2's development files)
# MIT, Copyright (c) 2026 AmiCradle Team.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$HERE/atari800.lock"
. "$HERE/scripts/a8-common.sh"
WORK=${WORK:-"$HERE/build-host"}; CC=${HOST_CC:-cc}
command -v sdl2-config > /dev/null || { echo "no sdl2-config: the PC tests need SDL 2's development files"; exit 2; }
mkdir -p "$WORK"
SRC="$WORK/atari800"
a8_source "$SRC"
PROBE_CC="$CC" a8_probe "$WORK/probe.h"
CF="-O2 -std=gnu99 -w -Werror=implicit-function-declaration -I$WORK -I$HERE/amiga -I$SRC/src $(sdl2-config --cflags) -DA8_VERSION=\"$A8_VERSION\""
O="$WORK/obj"; rm -rf "$O"; mkdir -p "$O"
objs=""
for f in $A8_SRCS; do
    o="$O/$(echo "$f" | tr / _).o"
    # shellcheck disable=SC2086
    $CC $CF -c "$SRC/src/$f" -o "$o" &
    objs="$objs $o"
done
wait
# shellcheck disable=SC2086
$CC -o "$WORK/atari800-host" $objs $(sdl2-config --libs) -lm
echo "built: $("$WORK/atari800-host" -v 2>&1 | head -1)"

fail=0
cd "$SRC"
if SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy "$WORK/atari800-host" -config /dev/null -xl-rev altirra \
     -nosound -nobasic -turbo -acid800 test/acid800.expected test/acid800.atr > "$WORK/acid800.log" 2>&1; then
    grep '^acid800:' "$WORK/acid800.log"
else
    echo "FAIL Acid800:"; grep -E '^(FAIL|MISSING|acid800:)' "$WORK/acid800.log"; fail=1
fi
# patches/0001's AmigaDOS paths, with Util_splitpath and Util_catpath from util.c
# shellcheck disable=SC2086
$CC -std=gnu99 -w -DA8_AMIGA_PATHS -I$WORK -I$HERE/amiga -I$SRC/src -DA8_VERSION=\"$A8_VERSION\" \
    -o "$WORK/paths_test" "$HERE/tests/paths_test.c" "$SRC/src/util.c" -lm || fail=1
"$WORK/paths_test" || fail=1
exit $fail
