#!/bin/bash
# MoBetta - Build x86_64 ntdll.so from CrossOver 26.3.0 source
#
# Cross-compiles natively on Apple Silicon (no Rosetta toolchain, no x86_64 Homebrew).
# Applies patches/*.patch in order. Output: build/out/ntdll.so (stripped), checked against
# the pinned SHA-256 (change NTDLL_SHA256 here and in package_engine.sh with the patch set).
#
# Requires: Xcode Command Line Tools, ARM Homebrew bison (>= 3.0), gh CLI
# Usage: bash scripts/build_ntdll.sh [--clean]

set -e
cd "$(dirname "$0")/.."
ROOT="$PWD"

CX_VERSION="26.3.0"
CX_TARBALL="crossover-sources-$CX_VERSION.tar.gz"
CX_URL="https://media.codeweavers.com/pub/crossover/source/$CX_TARBALL"
CX_SHA256="ac99c8ca4b3848f3e81784135f023df266b61c2345726ea55a50b3e030dd6872"

LLVM_MINGW="llvm-mingw-20261006-ucrt-macos-universal"
LLVM_MINGW_SHA256="a7a19b11048e89372637d26279cdb7c430ed3cf8c1e224310421312bf986ebf6"
NTDLL_SHA256="32d1fa05fb221a23946ff8e62162cbe5c0995145015ba8f412afc899fe726082"

SRC="$ROOT/build/src"
TOOLCHAIN="$ROOT/build/toolchain"
TOOLS_BUILD="$ROOT/build/wine-tools"
WINE64_BUILD="$ROOT/build/wine64"

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

if [ "$1" = "--clean" ]; then
    rm -rf "$TOOLS_BUILD" "$WINE64_BUILD"
fi

# Source
mkdir -p "$SRC"
if [ ! -f "$SRC/$CX_TARBALL" ]; then
    curl -fL --retry 3 -o "$SRC/$CX_TARBALL" "$CX_URL"
fi
verify_sha256 "$SRC/$CX_TARBALL" "$CX_SHA256"
if [ ! -d "$SRC/sources/wine" ]; then
    tar -xzf "$SRC/$CX_TARBALL" -C "$SRC"
fi

# MoBetta patches: when the set changes, restore pristine copies of every file
# the old and new sets touch, then apply the new set in order
PATCH_STAMP="$SRC/.mobetta-patches"
PATCHES_SHA256=$(cat "$ROOT"/patches/*.patch | shasum -a 256 | awk '{print $1}')
if [ "$(head -1 "$PATCH_STAMP" 2>/dev/null)" != "$PATCHES_SHA256" ]; then
    patched_files=$(grep -h '^+++ b/' "$ROOT"/patches/*.patch | cut -c7- | sort -u)
    for f in $( (tail -n +2 "$PATCH_STAMP" 2>/dev/null; echo "$patched_files") | sort -u); do
        # Files a patch creates are not in the tarball: remove them instead
        if tar -tzf "$SRC/$CX_TARBALL" "sources/wine/$f" > /dev/null 2>&1; then
            tar -xzf "$SRC/$CX_TARBALL" -C "$SRC" "sources/wine/$f"
            touch "$SRC/sources/wine/$f"
        else
            rm -f "$SRC/sources/wine/$f"
        fi
    done
    for p in "$ROOT"/patches/*.patch; do
        patch -p1 -s -d "$SRC/sources/wine" < "$p"
    done
    { echo "$PATCHES_SHA256"; echo "$patched_files"; } > "$PATCH_STAMP"
fi

# PE cross compiler (Apple's Command Line Tools are arm64-only, so no Rosetta toolchain)
mkdir -p "$TOOLCHAIN"
if [ ! -d "$TOOLCHAIN/$LLVM_MINGW" ]; then
    gh release download 20261006 -R mstorsjo/llvm-mingw -p "$LLVM_MINGW.tar.xz" -D "$TOOLCHAIN" --skip-existing
    verify_sha256 "$TOOLCHAIN/$LLVM_MINGW.tar.xz" "$LLVM_MINGW_SHA256"
    tar -xJf "$TOOLCHAIN/$LLVM_MINGW.tar.xz" -C "$TOOLCHAIN"
fi

export PATH="$TOOLCHAIN/$LLVM_MINGW/bin:$(brew --prefix bison)/bin:$PATH"
export PKG_CONFIG_LIBDIR=/nonexistent    # keep ARM Homebrew libs out of the x86_64 build
export MACOSX_DEPLOYMENT_TARGET=12.0     # matches stock CX26.3 ntdll.so
export ZERO_AR_DATE=1                    # ld64: zero object mtimes so LC_UUID is reproducible

# Native (arm64) build tools: winebuild, widl, wrc, ...
if [ ! -x "$TOOLS_BUILD/tools/winebuild/winebuild" ]; then
    mkdir -p "$TOOLS_BUILD"
    (cd "$TOOLS_BUILD" && "$SRC/sources/wine/configure" --without-x --without-freetype > configure.log 2>&1)
    make -C "$TOOLS_BUILD" -j8 __tooldeps__ > "$TOOLS_BUILD/make.log" 2>&1
fi

# x86_64 Mach-O + i386/x86_64 PE (new WoW64)
# Same bytes from any directory (Session #15): ld64 hashes the debug stabs into LC_UUID
# before strip -S removes them, and the stabs name the source dirs (N_SO) and objects
# (N_OSO) by absolute path. The prefix map and -oso_prefix make both relative to ROOT.
# configure reruns when these flags change (stamp below).
WINE64_CFLAGS="-g -O2 -ffile-prefix-map=$ROOT/=/mobetta/"
WINE64_LDFLAGS="-Wl,-oso_prefix,$ROOT/"
CONFIGURE_STAMP="$WINE64_BUILD/.mobetta-configure"
if [ ! -f "$WINE64_BUILD/Makefile" ] || [ "$(cat "$CONFIGURE_STAMP" 2>/dev/null)" != "$WINE64_CFLAGS $WINE64_LDFLAGS" ]; then
    rm -rf "$WINE64_BUILD"
    mkdir -p "$WINE64_BUILD"
    (cd "$WINE64_BUILD" && "$SRC/sources/wine/configure" \
        --build=aarch64-apple-darwin --host=x86_64-apple-darwin \
        CC="/usr/bin/clang -arch x86_64" \
        CFLAGS="$WINE64_CFLAGS" LDFLAGS="$WINE64_LDFLAGS" \
        --enable-archs=i386,x86_64 \
        --with-wine-tools="$TOOLS_BUILD" \
        --without-x --without-freetype > configure.log 2>&1)
    echo "$WINE64_CFLAGS $WINE64_LDFLAGS" > "$CONFIGURE_STAMP"
fi
# winecrt0 archives for build_mtld3d.sh's WINE_SDK: built here, where llvm-mingw is on PATH
# (outside it, make finds Homebrew's mingw gcc, which rejects clang's flags)
make -C "$WINE64_BUILD" -j8 dlls/ntdll/ntdll.so \
    dlls/winecrt0/i386-windows/libwinecrt0.a dlls/winecrt0/x86_64-windows/libwinecrt0.a \
    > "$WINE64_BUILD/make-ntdll.log" 2>&1

# Strip debug stabs like stock does; they embed object mtimes and paths
mkdir -p "$ROOT/build/out"
cp "$WINE64_BUILD/dlls/ntdll/ntdll.so" "$ROOT/build/out/ntdll.so"
strip -S "$ROOT/build/out/ntdll.so"
verify_sha256 "$ROOT/build/out/ntdll.so" "$NTDLL_SHA256"

echo "Built: $ROOT/build/out/ntdll.so"
shasum -a 256 "$ROOT/build/out/ntdll.so"
