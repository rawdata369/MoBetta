#!/bin/bash
# MoBetta - Build x86_64 ntdll.so from CrossOver 26.3.0 source
#
# Cross-compiles natively on Apple Silicon (no Rosetta toolchain, no x86_64 Homebrew).
# Applies patches/*.patch in order. Output: build/out/ntdll.so (stripped)
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
        tar -xzf "$SRC/$CX_TARBALL" -C "$SRC" "sources/wine/$f"
        touch "$SRC/sources/wine/$f"
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
if [ ! -f "$WINE64_BUILD/Makefile" ]; then
    mkdir -p "$WINE64_BUILD"
    (cd "$WINE64_BUILD" && "$SRC/sources/wine/configure" \
        --build=aarch64-apple-darwin --host=x86_64-apple-darwin \
        CC="/usr/bin/clang -arch x86_64" \
        --enable-archs=i386,x86_64 \
        --with-wine-tools="$TOOLS_BUILD" \
        --without-x --without-freetype > configure.log 2>&1)
fi
make -C "$WINE64_BUILD" -j8 dlls/ntdll/ntdll.so > "$WINE64_BUILD/make-ntdll.log" 2>&1

# Strip debug stabs like stock does; they embed object mtimes, which breaks reproducibility
mkdir -p "$ROOT/build/out"
cp "$WINE64_BUILD/dlls/ntdll/ntdll.so" "$ROOT/build/out/ntdll.so"
strip -S "$ROOT/build/out/ntdll.so"

echo "Built: $ROOT/build/out/ntdll.so"
shasum -a 256 "$ROOT/build/out/ntdll.so"
