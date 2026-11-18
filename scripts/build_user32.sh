#!/bin/bash
# MoBetta - Build i386 user32.dll (PE side) from CrossOver 26.3.0 source
#
# Uses the source tree, patches (0005 changes dlls/user32/sysparams.c) and configure that
# build_ntdll.sh sets up (it runs first). Only the 32-bit user32.dll is replaced: WoW 3.3.5a
# is a 32-bit program, and EnumDisplaySettings lives on the PE side.
# Output: build/out/user32.dll (debug info stripped), checked against the pinned SHA-256.
#
# Byte-reproducible: user32's objects are rebuilt every run with -ffile-prefix-map (the
# configure's i386_CFLAGS has none, so __FILE__ strings would name this checkout), and
# SOURCE_DATE_EPOCH sets the PE timestamp lld writes to the stock user32.dll's own.
#
# Requires: what build_ntdll.sh needs
# Usage: bash scripts/build_user32.sh [--clean]
set -e
cd "$(dirname "$0")/.."
ROOT="$PWD"
CLEAN=
[ "$1" = "--clean" ] && CLEAN=--clean

USER32_SHA256="92ba32e4331788582cda984f654446400be7a8b663ff2ba88c4e84c9096084fa"
STOCK_TIMESTAMP=1785313578               # PE TimeDateStamp of stock CX26.3 i386 user32.dll
LLVM_MINGW="llvm-mingw-20261006-ucrt-macos-universal"
WINE64_BUILD="$ROOT/build/wine64"
OBJ="$WINE64_BUILD/dlls/user32"

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

# Source, patches, toolchain and configure
bash "$ROOT/scripts/build_ntdll.sh" $CLEAN

export PATH="$ROOT/build/toolchain/$LLVM_MINGW/bin:$(brew --prefix bison)/bin:$PATH"
export SOURCE_DATE_EPOCH="$STOCK_TIMESTAMP"

# wrc reads locale.nls from the tools tree's nls/ to compile user32's resources
mkdir -p "$ROOT/build/wine-tools/nls"
cp "$ROOT"/build/src/sources/wine/nls/*.nls "$ROOT/build/wine-tools/nls/"

rm -f "$OBJ"/i386-windows/*.o "$OBJ/i386-windows/user32.dll" "$OBJ/user32.res"
make -C "$WINE64_BUILD" -j8 i386_CFLAGS="-g -O2 -ffile-prefix-map=$ROOT/=/mobetta/" \
    dlls/user32/i386-windows/user32.dll > "$WINE64_BUILD/make-user32.log" 2>&1 \
    || { tail -20 "$WINE64_BUILD/make-user32.log"; exit 1; }
llvm-strip --strip-debug -o "$ROOT/build/out/user32.dll" "$OBJ/i386-windows/user32.dll"
if strings -a "$ROOT/build/out/user32.dll" | grep -q "$ROOT"; then
    echo "user32.dll names the build directory ($ROOT)"
    exit 1
fi
verify_sha256 "$ROOT/build/out/user32.dll" "$USER32_SHA256"
echo "Built: $ROOT/build/out/user32.dll"
shasum -a 256 "$ROOT/build/out/user32.dll"
