#!/bin/sh
# Writes the Part file GFOpenUpTool INSTALL reads (gfopenup src/openuptool.c):
# one "copy" line per file under the part drawer, each to SYS:<its path>.
# It needs the GFOpenGPU part, whose SDL2.module draws, plays and reads the
# keys and joysticks.
#   write-part.sh <part drawer> <version>
# MIT, Copyright (c) 2026 AmiCradle Team.
set -eu
P=$1; V=$2
{
    echo "part Atari800 $V"
    echo "; Atari800: the Atari 400/800, XL/XE and 5200 emulator, with Altirra's free OS and BASIC built in"
    echo "needs 68040"
    echo "needs part GFOpenGPU"
    (cd "$P" && find Utilities -type f ! -name Part | LC_ALL=C sort) | while read -r f; do
        echo "copy \"$f\" \"SYS:$f\""
    done
} > "$P/Part"
