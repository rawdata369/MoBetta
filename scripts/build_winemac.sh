#!/bin/bash
# MoBetta - Build x86_64 winemac.so (the Mac display driver, unix side) from CrossOver 26.3.0 source
#
# Uses the source tree, patches (0006 changes dlls/winemac.drv) and configure that
# build_ntdll.sh sets up (it runs first). That configure has no Vulkan, so win32u.so cannot
# be built there; winemac.so only links against it, so the link takes stock win32u.so from
# the stock engine (as build_opengl32.sh does). winemac.drv's own Vulkan code (MoltenVK
# surfaces) has no configure switch in Wine 11 and is always built.
# Output: build/out/winemac.so (stripped), checked against the pinned SHA-256.
#
# Requires: what build_ntdll.sh needs, plus 7-Zip (brew install sevenzip)
# Usage: bash scripts/build_winemac.sh [--clean] [path/to/WS12WineCX26.3_DXMT.tar.7z]

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
WINEMAC_SHA256="3a7b5f4e46c1a5f0633461a76b1611d20d5e32a76a18ead3c1ced556ca19c07c"

WINE64_BUILD="$ROOT/build/wine64"
LINK_LIBS="$ROOT/build/stock-link"
WIN32U="lib/wine/x86_64-unix/win32u.so"
OBJS="clipboard cocoa_app cocoa_clipboard cocoa_cursorclipping cocoa_display cocoa_event
      cocoa_icon_utils cocoa_main cocoa_opengl cocoa_status_item cocoa_window d3dmetal
      d3dmetal_objc display event gdi image keyboard macdrv_main mouse opengl surface systray
      vulkan window"

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

# Source, patches, toolchain, configure and ntdll.so (winemac.so links against it)
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

export MACOSX_DEPLOYMENT_TARGET=12.0     # matches stock CX26.3
export ZERO_AR_DATE=1                    # ld64: zero object mtimes so LC_UUID is reproducible

objs=
for o in $OBJS; do objs="$objs dlls/winemac.drv/$o.o"; done
# Rebuilt every run: an object compiled outside this script lacks the deployment target
(cd "$WINE64_BUILD" && rm -f $objs)
make -C "$WINE64_BUILD" -j8 $objs > "$WINE64_BUILD/make-winemac.log" 2>&1 \
    || { tail -20 "$WINE64_BUILD/make-winemac.log"; exit 1; }

# The Makefile's link rule, with stock win32u.so in place of the one this tree cannot build;
# -oso_prefix as in build_ntdll.sh, so LC_UUID does not depend on the directory
(cd "$WINE64_BUILD" && /usr/bin/clang -arch x86_64 -o "$ROOT/build/out/winemac.so" -dynamiclib \
    -install_name @rpath/winemac.so -Wl,-rpath,@loader_path/ -Wl,-oso_prefix,"$ROOT/" \
    $objs dlls/ntdll/ntdll.so "$LINK_LIBS/win32u.so" \
    -framework AppKit -framework Carbon -framework CoreVideo -framework Foundation \
    -framework IOKit -framework Metal -framework OpenGL -framework QuartzCore -framework Security \
    2>&1 | grep -v "which was built for newer version" || true)
strip -S "$ROOT/build/out/winemac.so"
if strings -a "$ROOT/build/out/winemac.so" | grep -q "$ROOT"; then
    echo "winemac.so names the build directory ($ROOT)"
    exit 1
fi
if [ -n "$WINEMAC_SHA256" ]; then
    verify_sha256 "$ROOT/build/out/winemac.so" "$WINEMAC_SHA256"
else
    echo "winemac.so not pinned yet"
fi

echo "Built: $ROOT/build/out/winemac.so"
shasum -a 256 "$ROOT/build/out/winemac.so"
