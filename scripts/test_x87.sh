#!/bin/bash
# MoBetta - End-to-end tests for the x87sidecar handshake (patches/0003)
#
# Builds tests/x87_check.c as a 32-bit exe with x87 math only and runs it on a
# clone of the wrapper's engine with build/out/ntdll.so swapped in, in a
# throwaway prefix. The wrapper and the game prefix are not touched.
#   stock:    ROSETTA_X87_PATH="" (sidecar off), the baseline
#   env:      ROSETTA_X87_PATH=<sidecar>, must attach, match stock bit for bit, be faster
#   bundled:  sidecar copied to engine/bin/x87sidecar, ROSETTA_X87_PATH unset, must attach
#
# Usage: bash scripts/test_x87.sh [path/to/x87sidecar]
#        (after scripts/build_ntdll.sh; default sidecar build/x87sidecar/build/bin/x87sidecar)

set -e
cd "$(dirname "$0")/.."
ROOT="$PWD"

OUT="$ROOT/build/test"
ENGINE="$HOME/Games/warmane/warmane.app/Contents/SharedSupport/wine"
LLVM_MINGW="$ROOT/build/toolchain/llvm-mingw-20261006-ucrt-macos-universal"
SIDECAR="${1:-$ROOT/build/x87sidecar/build/bin/x87sidecar}"
NTDLL="$ROOT/build/out/ntdll.so"
MIN_SPEEDUP=3

[ -x "$SIDECAR" ] || { echo "No sidecar at $SIDECAR"; exit 1; }

mkdir -p "$OUT"
"$LLVM_MINGW/bin/i686-w64-mingw32-gcc" -O2 -Wall -mno-sse -mfpmath=387 \
    -o "$OUT/x87_check.exe" "$ROOT/tests/x87_check.c"
rm -rf "$OUT/engine" "$OUT/prefix"
cp -cR "$ENGINE" "$OUT/engine"   # APFS clone, instant
cp "$NTDLL" "$OUT/engine/lib/wine/x86_64-unix/ntdll.so"
echo "[wine: ntdll.so $(shasum -a 256 "$NTDLL" | cut -c1-8), sidecar $(shasum -a 256 "$SIDECAR" | cut -c1-8)]"

# run <name> <env...>: runs the exe, output in $OUT/x87_<name>.log
run() {
    local name=$1; shift
    env "$@" WINEPREFIX="$OUT/prefix" WINEDEBUG=fixme-all WINEDLLOVERRIDES="mscoree,mshtml=" \
        "$OUT/engine/bin/wine" "$OUT/x87_check.exe" > "$OUT/x87_$name.log" 2>&1 || true
}
field() { awk -v k="$1" '$1 == k { print $2 }' "$OUT/x87_$2.log" | tr -d '\r'; }

fail=0
check() {
    if [ "$2" = 1 ]; then echo "ok: $1"; else echo "FAIL: $1"; fail=1; fi
}
attached() { grep -q "attaching rosettax87 --cooperative" "$OUT/x87_$1.log" &&
             ! grep -q "RUNNING WITHOUT X87 ACCELERATION" "$OUT/x87_$1.log" && echo 1 || echo 0; }

run warmup ROSETTA_X87_PATH=     # prefix creation, so timings below are not skewed
run stock ROSETTA_X87_PATH=
run env ROSETTA_X87_PATH="$SIDECAR"
cp "$SIDECAR" "$OUT/engine/bin/x87sidecar"
run bundled -u ROSETTA_X87_PATH
run off ROSETTA_X87_PATH=        # bundled sidecar present, empty variable turns it off
WINEPREFIX="$OUT/prefix" "$OUT/engine/bin/wineserver" -k 2>/dev/null || true

for r in stock env bundled off; do
    echo "  $r: bits $(field bits $r) ms $(field ms $r)"
done

stock_bits=$(field bits stock); stock_ms=$(field ms stock); env_ms=$(field ms env)
check "stock run completes" "$([ -n "$stock_bits" ] && echo 1 || echo 0)"
check "stock run does not attach" "$(grep -q 'attaching rosettax87' "$OUT/x87_stock.log" && echo 0 || echo 1)"
check "ROSETTA_X87_PATH attaches cooperatively" "$(attached env)"
check "ROSETTA_X87_PATH result matches stock bit for bit" "$([ "$(field bits env)" = "$stock_bits" ] && echo 1 || echo 0)"
check "sidecar at least ${MIN_SPEEDUP}x faster (${stock_ms} ms -> ${env_ms} ms)" \
    "$([ -n "$env_ms" ] && [ $((env_ms * MIN_SPEEDUP)) -le "$stock_ms" ] && echo 1 || echo 0)"
check "bin/x87sidecar attaches without ROSETTA_X87_PATH" "$(attached bundled)"
check "bin/x87sidecar result matches stock bit for bit" "$([ "$(field bits bundled)" = "$stock_bits" ] && echo 1 || echo 0)"
check "empty ROSETTA_X87_PATH keeps bin/x87sidecar off" \
    "$(grep -q 'attaching rosettax87' "$OUT/x87_off.log" || [ "$(field bits off)" != "$stock_bits" ] && echo 0 || echo 1)"

[ $fail = 0 ] && echo "All x87sidecar tests passed" || { echo "x87sidecar tests FAILED (logs: $OUT/x87_*.log)"; exit 1; }
