# What build-amiga.sh (the stove) and tests/host-a8.sh (the PC) share: the
# sources upstream's src/Makefile.am builds for amiga/config.h's set,
# fetching Atari800 with patches/, and the probe that writes probe.h.
# Sourced; needs HERE (the repo) and atari800.lock's settings.
# MIT, Copyright (c) 2026 AmiCradle Team.

# src/Makefile.am's atari800_SOURCES for SDL 2 video and sound, sound,
# audio recording, screenshots (PCX), the PBI boards, IDE, NTSC filter,
# PAL blending, Altirra's OS, XEP80, Voice Box, Pokey recording
A8_SRCS="acidtest.c af80.c afile.c antic.c artifact.c atari.c atari_ntsc/atari_ntsc.c
 binload.c bit3.c cartridge.c cartridge_info.c cassette.c cfg.c
 codecs/audio.c codecs/audio_adpcm.c codecs/audio_mulaw.c codecs/audio_pcm.c
 codecs/container.c codecs/container_wav.c codecs/image.c codecs/image_pcx.c
 colours.c colours_external.c colours_ntsc.c colours_pal.c compfile.c cpu.c crc32.c
 cycle_map.c devices.c esc.c file_export.c filter_ntsc.c gtia.c ide.c img_tape.c
 input.c log.c memory.c monitor.c mzpokeysnd.c pal_blending.c pbi.c pbi_bb.c
 pbi_mio.c pbi_proto80.c pbi_scsi.c pbi_xld.c pia.c pokey.c pokeyrec.c pokeysnd.c
 remez.c roms/altirra_5200_charset.c roms/altirra_5200_os.c roms/altirra_basic.c
 roms/altirraos_800.c roms/altirraos_xl.c rtime.c screen.c sdl/init.c sdl/input.c
 sdl/main.c sdl/palette.c sdl/sound.c sdl/video.c sdl/video_sw.c sio.c sound.c
 statesav.c sysrom.c ui.c ui_basic.c util.c videomode.c voicebox.c votrax.c
 votraxsnd.c xep80.c xep80_fonts.c"

# a repository at one commit, fetched once: fetch_at DIR URL COMMIT
fetch_at() {
    if [ "$(git -C "$1" rev-parse HEAD 2>/dev/null)" != "$3" ]; then
        rm -rf "${1:?}"; mkdir -p "$1"
        git -C "$1" init -q
        git -C "$1" fetch -q --depth 1 "$2" "$3"
        git -C "$1" checkout -q FETCH_HEAD
        [ "$(git -C "$1" rev-parse HEAD)" = "$3" ] || { echo "$1: commit mismatch"; exit 1; }
    fi
}

# Atari800 at A8_COMMIT with patches/ applied, into $1 (redone when either changes)
a8_source() {
    PSUM=$(cat "$HERE"/patches/*.patch | sha256sum | cut -c1-16)
    if [ "$(cat "$1/.patched" 2>/dev/null)" != "$A8_COMMIT-$PSUM" ]; then
        rm -rf "$1"
        fetch_at "$1" "$A8_GIT" "$A8_COMMIT"
        for p in "$HERE"/patches/*.patch; do
            patch -s -d "$1" -p1 < "$p" || { echo "patch failed: $p"; exit 1; }
        done
        echo "$A8_COMMIT-$PSUM" > "$1/.patched"
    fi
}

# probe.h into $1: HAVE_<FUNCTION> for each function a link finds and
# HAVE_<HEADER>_H for each header that compiles, as configure's checks
# ($PROBE_CC: the compile and link command)
a8_probe() {
    t=$(mktemp -d)
    {
        echo "/* probe.h: written by scripts/a8-common.sh a8_probe */"
        for f in atexit chmod clock fdopen fflush floor fseeko fstat getcwd gettimeofday \
                 localtime memmove memset mkdir mkstemp mktemp modf nanosleep opendir \
                 rename rewind rmdir signal snprintf stat strcasecmp strchr strdup \
                 strerror strncpy strrchr strstr strtol system time tmpfile tmpnam \
                 unlink usleep vprintf vsnprintf; do
            printf 'char %s(void);\nint main(void) { return (int)%s(); }\n' "$f" "$f" > "$t/p.c"
            # shellcheck disable=SC2086
            if $PROBE_CC -o "$t/p" "$t/p.c" -lm > /dev/null 2>&1; then
                echo "#define HAVE_$(echo "$f" | tr '[:lower:]' '[:upper:]') 1"
            fi
        done
        for h in dirent.h errno.h fcntl.h inttypes.h signal.h stdint.h stdio.h stdlib.h \
                 strings.h string.h sys/stat.h sys/time.h sys/types.h time.h unistd.h wchar.h; do
            printf '#include <%s>\nint main(void) { return 0; }\n' "$h" > "$t/p.c"
            # shellcheck disable=SC2086
            if $PROBE_CC -o "$t/p" "$t/p.c" > /dev/null 2>&1; then
                echo "#define HAVE_$(echo "$h" | tr '[:lower:]/.' '[:upper:]__') 1"
            fi
        done
        printf '#include <stdint.h>\nint main(void) { uintptr_t u = 0; return (int)u; }\n' > "$t/p.c"
        # shellcheck disable=SC2086
        if $PROBE_CC -o "$t/p" "$t/p.c" > /dev/null 2>&1; then echo "#define HAVE_UINTPTR_T 1"; fi
    } > "$1"
    rm -rf "$t"
}
