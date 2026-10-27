#!/bin/bash
# MoBetta - Build x87sidecar (athei/x87sidecar, MIT) at the pinned commit
#
# patches/0003 starts i386 processes under it from wine/bin/x87sidecar.
# Output: build/out/x87sidecar (arm64, ad-hoc signed), checked against the pinned SHA-256.
# The binary depends on the compiler: a different Xcode/CLT can change the hash
# (pinned with Apple clang 21.0.0, clang-2100.3.34.2).
#
# Requires: Xcode Command Line Tools, cmake >= 3.27 (brew install cmake), git
# Usage: bash scripts/build_x87sidecar.sh [--clean]

set -e
cd "$(dirname "$0")/.."
ROOT="$PWD"

SIDECAR_URL="https://github.com/athei/x87sidecar.git"
SIDECAR_COMMIT="499e0f7e60d2961d379df459dd96bc79ecfe59fd"
SIDECAR_SHA256="881e9449565a9e2a823bfc517a30ef89d96a6388ae2f20a4dd5b7ab18058ea8e"

SRC="$ROOT/build/x87sidecar"
BUILD="$SRC/build"
OUT="$ROOT/build/out/x87sidecar"

if [ "$1" = "--clean" ]; then
    rm -rf "$BUILD"
fi

# Source at the pinned commit, no local edits
if [ ! -d "$SRC/.git" ]; then
    git clone "$SIDECAR_URL" "$SRC"
fi
if [ "$(git -C "$SRC" rev-parse HEAD)" != "$SIDECAR_COMMIT" ]; then
    git -C "$SRC" fetch origin
    git -C "$SRC" checkout -q --detach "$SIDECAR_COMMIT"
fi
if [ -n "$(git -C "$SRC" status --porcelain)" ]; then
    echo "Local changes in $SRC; refusing to build"
    git -C "$SRC" status --short
    exit 1
fi

cmake -S "$SRC" -B "$BUILD" -DCMAKE_BUILD_TYPE=Release > /dev/null
cmake --build "$BUILD" --target x87sidecar -j8 > "$BUILD/make.log" 2>&1 \
    || { tail -20 "$BUILD/make.log"; exit 1; }

mkdir -p "$ROOT/build/out"
cp "$BUILD/bin/x87sidecar" "$OUT"

actual=$(shasum -a 256 "$OUT" | awk '{print $1}')
if [ "$actual" != "$SIDECAR_SHA256" ]; then
    echo "SHA-256 mismatch for $OUT (compiler differs from the pinned build?)"
    echo "  expected $SIDECAR_SHA256"
    echo "  actual   $actual"
    exit 1
fi

# Hooks Rosetta internals: must say "supported" on this macOS
"$OUT" --probe

echo "Built: $OUT"
shasum -a 256 "$OUT"
