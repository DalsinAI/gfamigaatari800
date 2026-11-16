#!/bin/sh
# PC test for scripts/write-part.sh: the Part file GFOpenUpTool reads.
# MIT, Copyright (c) 2026 AmiCradle Team.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir -p "$T/Utilities/Atari800"
for f in Atari800 ReadMe COPYING USAGE; do : > "$T/Utilities/Atari800/$f"; done
sh "$HERE/../scripts/write-part.sh" "$T" 7.2.1
fail=0
expect() { grep -qxF "$1" "$T/Part" || { echo "FAIL: no line: $1"; fail=1; }; }
expect 'part Atari800 7.2.1'
expect 'needs 68040'
expect 'needs part GFOpenGPU'
expect 'copy "Utilities/Atari800/Atari800" "SYS:Utilities/Atari800/Atari800"'
expect 'copy "Utilities/Atari800/USAGE" "SYS:Utilities/Atari800/USAGE"'
[ "$(head -1 "$T/Part")" = 'part Atari800 7.2.1' ] || { echo "FAIL: first line"; fail=1; }
[ "$(grep -c '^copy' "$T/Part")" = 4 ] || { echo "FAIL: copy count"; fail=1; }
sh "$HERE/../scripts/write-part.sh" "$T" 7.2.1
[ "$(grep -c '^copy' "$T/Part")" = 4 ] || { echo "FAIL: second run lists the Part file"; fail=1; }
[ $fail = 0 ] && echo "Part file: all checks passed"
exit $fail
