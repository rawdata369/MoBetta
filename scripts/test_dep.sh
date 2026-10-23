#!/bin/bash
# MoBetta - Tests for the DEP patch (patches/0002)
#
# Unit: extracts get_execute_flags() from the patched unix/process.c and runs it
#       as x86_64 (Rosetta) and arm64 (native), with and without WINE_FORCE_NX.
# End to end (with --wine): builds tests/dep_check.c as a 32-bit exe without
#       NX_COMPAT and runs it on a clone of the wrapper's engine with
#       build/out/ntdll.so swapped in, in a throwaway prefix. The wrapper and the
#       game prefix are not touched. --stock runs the same on stock ntdll.so,
#       which must fail (shows the check can tell the difference).
#
# Usage: bash scripts/test_dep.sh [--wine [--stock]]   (after scripts/build_ntdll.sh)

set -e
cd "$(dirname "$0")/.."
ROOT="$PWD"

PROCESS_C="$ROOT/build/src/sources/wine/dlls/ntdll/unix/process.c"
OUT="$ROOT/build/test"
ENGINE="$HOME/Games/warmane/warmane.app/Contents/SharedSupport/wine"
LLVM_MINGW="$ROOT/build/toolchain/llvm-mingw-20261006-ucrt-macos-universal"

mkdir -p "$OUT"
sed -n '/^static ULONG get_execute_flags(void)/,/^}/p' "$PROCESS_C" > "$OUT/dep_extract.c"
if [ ! -s "$OUT/dep_extract.c" ]; then
    echo "No get_execute_flags() in $PROCESS_C (patches not applied?)"
    exit 1
fi

fail=0
for arch in x86_64 arm64; do
    /usr/bin/clang -arch $arch -O2 -Wall -I"$OUT" -o "$OUT/test_dep_$arch" "$ROOT/tests/test_dep.c"
    # Rosetta (x86_64) defaults to permanent, native arm64 does not
    [ $arch = x86_64 ] && default=1 || default=0
    echo "[$arch]"
    env -u WINE_FORCE_NX "$OUT/test_dep_$arch" $default || fail=1
    WINE_FORCE_NX=0 "$OUT/test_dep_$arch" 0 || fail=1
    WINE_FORCE_NX=1 "$OUT/test_dep_$arch" 1 || fail=1
done

if [ "$1" = "--wine" ]; then
    "$LLVM_MINGW/bin/i686-w64-mingw32-gcc" -O2 -Wall -Wl,--disable-nxcompat \
        -o "$OUT/dep_check.exe" "$ROOT/tests/dep_check.c"
    NTDLL="$ROOT/build/out/ntdll.so"
    [ "$2" = "--stock" ] && NTDLL="$ROOT/build/stock/ntdll.so.CX26.3"
    rm -rf "$OUT/engine" "$OUT/prefix"
    cp -cR "$ENGINE" "$OUT/engine"   # APFS clone, instant
    cp "$NTDLL" "$OUT/engine/lib/wine/x86_64-unix/ntdll.so"
    echo "[wine: $(basename "$NTDLL") $(shasum -a 256 "$NTDLL" | cut -c1-8)]"
    WINEPREFIX="$OUT/prefix" WINEDEBUG=-all WINEDLLOVERRIDES="mscoree,mshtml=" \
        "$OUT/engine/bin/wine" "$OUT/dep_check.exe" || fail=1
    WINEPREFIX="$OUT/prefix" "$OUT/engine/bin/wineserver" -k 2>/dev/null || true
fi

[ $fail = 0 ] && echo "All DEP tests passed" || { echo "DEP tests FAILED"; exit 1; }
