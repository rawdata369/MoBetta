#!/bin/bash
# MoBetta - Unit tests for the Rosetta instruction emulation
#
# Extracts the code between the MOBETTA markers in the patched signal_x86_64.c,
# builds tests/test_emu.c around it as x86_64 and runs it under Rosetta.
#
# Usage: bash scripts/test_emu.sh   (after scripts/build_ntdll.sh has applied the patches)

set -e
cd "$(dirname "$0")/.."
ROOT="$PWD"

SIGNAL_C="$ROOT/build/src/sources/wine/dlls/ntdll/unix/signal_x86_64.c"
OUT="$ROOT/build/test"

mkdir -p "$OUT"
sed -n '/MOBETTA BEGIN emulation/,/MOBETTA END emulation/p' "$SIGNAL_C" > "$OUT/emu_extract.c"
if [ ! -s "$OUT/emu_extract.c" ]; then
    echo "No MOBETTA emulation block in $SIGNAL_C (patches not applied?)"
    exit 1
fi

/usr/bin/clang -arch x86_64 -O2 -Wall -Wno-unused-function -I"$OUT" \
    -o "$OUT/test_emu" "$ROOT/tests/test_emu.c"
"$OUT/test_emu"
