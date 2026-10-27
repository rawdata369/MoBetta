#!/bin/bash
# MoBetta - Build x86_64 opengl32.so (unix side) from CrossOver 26.3.0 source
#
# Uses the source tree, patches and configure that build_ntdll.sh sets up (it runs first).
# That configure has no Vulkan, so win32u.so cannot be built there; opengl32.so only
# links against it, so the link takes stock win32u.so from the stock engine instead.
# Output: build/out/opengl32.so (stripped), checked against the pinned SHA-256.
#
# Requires: what build_ntdll.sh needs, plus 7-Zip (brew install sevenzip)
# Usage: bash scripts/build_opengl32.sh [--clean] [path/to/WS12WineCX26.3_DXMT.tar.7z]

set -e
cd "$(dirname "$0")/.."
ROOT="$PWD"

CLEAN=
if [ "$1" = "--clean" ]; then
    CLEAN=--clean
    shift
fi

STOCK_ENGINE="WS12WineCX26.3_DXMT"
STOCK_ARCHIVE="${1:-$HOME/Library/Application Support/Wineskin/Engines/$STOCK_ENGINE.tar.7z}"
STOCK_SHA256="7b3f383a2209de5765eef45f1d6fc316682cfcfbb3518d7470e4b51f00e7cd08"
STOCK_WIN32U_SHA256="6d26be4d80e3d91983b2a6fa33402c29990a13a0f9675dba22353e53365ce805"
OPENGL32_SHA256="53a7b678890b206c5a9224d41beb74395354875298830b050863eb22541feef6"

WINE64_BUILD="$ROOT/build/wine64"
LINK_LIBS="$ROOT/build/stock-link"
WIN32U="lib/wine/x86_64-unix/win32u.so"

verify_sha256() {
    local actual
    actual=$(shasum -a 256 "$1" | awk '{print $1}')
    if [ "$actual" != "$2" ]; then
        echo "SHA-256 mismatch for $1"
        echo "  expected $2"
        echo "  actual   $actual"
        exit 1
    fi
}

command -v 7zz > /dev/null || { echo "7zz not found (brew install sevenzip)"; exit 1; }

# Source, patches, toolchain, configure and ntdll.so (opengl32.so links against it)
bash "$ROOT/scripts/build_ntdll.sh" $CLEAN

# Stock win32u.so to link against
if [ ! -f "$LINK_LIBS/win32u.so" ]; then
    verify_sha256 "$STOCK_ARCHIVE" "$STOCK_SHA256"
    rm -rf "$LINK_LIBS"
    mkdir -p "$LINK_LIBS"
    7zz x -so "$STOCK_ARCHIVE" | tar -xf - -C "$LINK_LIBS" "wswine.bundle/$WIN32U"
    mv "$LINK_LIBS/wswine.bundle/$WIN32U" "$LINK_LIBS/win32u.so"
    rm -rf "$LINK_LIBS/wswine.bundle"
fi
verify_sha256 "$LINK_LIBS/win32u.so" "$STOCK_WIN32U_SHA256"

export MACOSX_DEPLOYMENT_TARGET=12.0     # matches stock CX26.3 opengl32.so
export ZERO_AR_DATE=1                    # ld64: zero object mtimes so LC_UUID is reproducible

make -C "$WINE64_BUILD" -j8 dlls/opengl32/unix_thunks.o dlls/opengl32/unix_wgl.o \
    > "$WINE64_BUILD/make-opengl32.log" 2>&1

# The Makefile's link rule, with stock win32u.so in place of the one this tree cannot build
# (stock is built for a newer macOS; ld warns, as it would for stock's own link)
(cd "$WINE64_BUILD" && /usr/bin/clang -arch x86_64 -o "$ROOT/build/out/opengl32.so" -dynamiclib \
    -install_name @rpath/opengl32.so -Wl,-rpath,@loader_path/ \
    dlls/opengl32/unix_thunks.o dlls/opengl32/unix_wgl.o dlls/ntdll/ntdll.so "$LINK_LIBS/win32u.so" \
    2>&1 | grep -v "which was built for newer version" || true)
strip -S "$ROOT/build/out/opengl32.so"
verify_sha256 "$ROOT/build/out/opengl32.so" "$OPENGL32_SHA256"

echo "Built: $ROOT/build/out/opengl32.so"
shasum -a 256 "$ROOT/build/out/opengl32.so"
