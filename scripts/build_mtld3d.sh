#!/bin/bash
# MoBetta - Build mtld3d (athei/mtld3d, D3D9 on Metal) at the pinned release
#
# Applies patches/mtld3d/*.patch in order (0001 drops the Wow.exe import hooks).
# Builds the two pieces a 32-bit game on our x86_64 Wine loads:
#   i386-windows/{d3d9,mtld3d}.dll (+ mtld3d.fake.dll, the prefix marker)
#   d3d9.dll gets winebuild's builtin mark here, as mtld3d's install target does:
#   the loader skips unmarked PEs in lib/wine and falls back to the prefix's
#   stock d3d9.dll (Session #11)
#   x86_64-unix/mtld3d.so
# Output: build/out/mtld3d/, with SHA-256 sums printed.
#
# Byte-reproducible on any Mac (Session #13): the patched tree is copied without
# .git to the fixed BUILD_DIR and built there. Cargo hashes the absolute path
# of a crate outside its workspace into the crate ID (windows/ and unix/ each
# use crates from the other), which shifts symbol names and code layout, so the
# path has to be the same everywhere. Without .git the release stamp is the
# manifest version, v0.15.1, whatever the clone's tags.
#
# No sudo: the MSVC CRT/SDK splat goes to build/xwin instead of mtld3d's
# /opt/xwin; RUSTFLAGS and CFLAGS_/CXXFLAGS_<target> replace the /opt paths in
# windows/.cargo/config.toml. WINE_SDK is a build-only tree (build/mtld3d-sdk):
# our winebuild + our tree's winecrt0 archives; its bin/wine refuses to run.
#
# Requires: rustup (stable >= 1.99 with llvm-tools, targets i686-pc-windows-msvc
# and x86_64-apple-darwin), cargo-installed xwin, build/wine64 configured by
# scripts/build_ntdll.sh
# Usage: bash scripts/build_mtld3d.sh [--clean]

set -e
cd "$(dirname "$0")/.."
ROOT="$PWD"

MTLD3D_URL="https://github.com/athei/mtld3d.git"
MTLD3D_COMMIT="9919759fa7c03362deac1b985db6d93de9e33ecf"   # v0.15.1
XWIN_CRT_VERSION="14.44.17.14"
XWIN_SDK_VERSION="10.0.26100"

SRC="$ROOT/build/mtld3d"
BUILD_DIR="/private/tmp/mobetta-mtld3d"
SDK="$ROOT/build/mtld3d-sdk"
XWIN="$ROOT/build/xwin"
WINE64_BUILD="$ROOT/build/wine64"
OUT="$ROOT/build/out/mtld3d"
PE_OUT="$BUILD_DIR/windows/target/i686-pc-windows-msvc/production"
UNIX_OUT="$BUILD_DIR/unix/target/x86_64-apple-darwin/production"

# PE linker and archiver from the toolchain's llvm-tools (mtld3d's setup-rust)
TOOLS="$(rustc +stable --print sysroot)/lib/rustlib/$(rustc +stable -vV | sed -n 's/^host: //p')/bin"
CARGO_DIR="${CARGO_HOME:-$HOME/.cargo}"
CARGO_BIN="$CARGO_DIR/bin"
ln -sf "$TOOLS/rust-lld" "$CARGO_BIN/lld-link"
ln -sf "$TOOLS/llvm-ar" "$CARGO_BIN/llvm-lib"

# Source at the pinned commit, then our patches
if [ ! -d "$SRC/.git" ]; then
    git clone "$MTLD3D_URL" "$SRC"
fi
if [ "$(git -C "$SRC" rev-parse HEAD)" != "$MTLD3D_COMMIT" ]; then
    git -C "$SRC" fetch origin
    git -C "$SRC" checkout -q --detach "$MTLD3D_COMMIT"
fi
git -C "$SRC" checkout -q -- .
for p in "$ROOT"/patches/mtld3d/*.patch; do
    git -C "$SRC" apply "$p"
done

if [ "$1" = "--clean" ]; then
    rm -rf "$BUILD_DIR"
fi
mkdir -p "$BUILD_DIR"
rsync -a --delete --exclude /.git --exclude target/ --exclude /mobetta-build.log "$SRC/" "$BUILD_DIR/"

# Build-only WINE_SDK
# (build_ntdll.sh builds the winecrt0 archives, with llvm-mingw on PATH)
for a in i386 x86_64; do
    [ -f "$WINE64_BUILD/dlls/winecrt0/$a-windows/libwinecrt0.a" ] \
        || { echo "No $a winecrt0 archive: run scripts/build_ntdll.sh first"; exit 1; }
done
mkdir -p "$SDK/bin" "$SDK/lib/wine/i386-windows" "$SDK/lib/wine/x86_64-windows" \
    "$SDK/lib/wine/x86_64-unix"
ln -sf "$ROOT/build/wine-tools/tools/winebuild/winebuild" "$SDK/bin/winebuild"
for t in wine wineserver; do
    printf '#!/bin/sh\necho "mtld3d-sdk is build-only: no %s here" >&2\nexit 1\n' "$t" > "$SDK/bin/$t"
    chmod +x "$SDK/bin/$t"
done
for a in i386 x86_64; do
    ln -sf "$WINE64_BUILD/dlls/winecrt0/$a-windows/libwinecrt0.a" "$SDK/lib/wine/$a-windows/libwinecrt0.a"
done

# MSVC CRT + Windows SDK, pinned versions (same as mtld3d's Makefile)
if [ ! -d "$XWIN/crt/lib/x86" ] || [ ! -d "$XWIN/sdk/lib/um/x86" ]; then
    xwin --accept-license --arch x86,x86_64 --crt-version "$XWIN_CRT_VERSION" \
        --sdk-version "$XWIN_SDK_VERSION" --cache-dir "$ROOT/build/xwin-cache" \
        splat --output "$XWIN"
fi

LOG="$SRC/mobetta-build.log"
INC="-idirafter $XWIN/crt/include -idirafter $XWIN/sdk/include/ucrt -idirafter $XWIN/sdk/include/um -idirafter $XWIN/sdk/include/shared"
# Panic locations and C __FILE__ strings name /mtld3d and /cargo instead of
# BUILD_DIR and the cargo registry (which is per user). /DEBUG:NONE drops the
# PDB, which records the link command line (absolute paths, rustc's random
# deps/rustcXXXXXX directory) and which /Brepro would hash into the DLL's
# timestamp. No PDB ever shipped. /build-id keeps the CodeView record the log's
# image ID is read from, its GUID now hashed from the DLL alone
REMAP="--remap-path-prefix=$CARGO_DIR=/cargo --remap-path-prefix=$BUILD_DIR=/mtld3d"
CMAP="-ffile-prefix-map=$CARGO_DIR=/cargo -ffile-prefix-map=$BUILD_DIR=/mtld3d"
env RUSTFLAGS="-C target-cpu=pentium4 -C target-feature=-crt-static -C link-arg=/Brepro -C link-arg=/DEBUG:NONE -C link-arg=/build-id $REMAP -Lnative=$XWIN/crt/lib/x86 -Lnative=$XWIN/sdk/lib/um/x86 -Lnative=$XWIN/sdk/lib/ucrt/x86" \
    "CFLAGS_i686-pc-windows-msvc=-march=pentium4 -fno-omit-frame-pointer $CMAP $INC" \
    "CXXFLAGS_i686-pc-windows-msvc=-march=pentium4 -fno-omit-frame-pointer $CMAP $INC" \
    make -C "$BUILD_DIR" PROD=1 WINE_SDK="$SDK" windows-i686 > "$LOG" 2>&1 \
    || { tail -20 "$LOG"; exit 1; }
# RUSTFLAGS replaces unix/.cargo/config.toml's rustflags, so they are repeated here
env RUSTFLAGS="-C target-cpu=x86-64-v2 -C target-feature=+bmi1,+bmi2,+lzcnt $REMAP" \
    "CFLAGS_x86_64-apple-darwin=-march=x86-64-v2 -mbmi -mbmi2 -mlzcnt $CMAP" \
    "CXXFLAGS_x86_64-apple-darwin=-march=x86-64-v2 -mbmi -mbmi2 -mlzcnt $CMAP" \
    make -C "$BUILD_DIR" PROD=1 WINE_SDK="$SDK" unix-x64 >> "$LOG" 2>&1 \
    || { tail -20 "$LOG"; exit 1; }

# The hooks must be gone from d3d9.dll
if strings -a "$PE_OUT/d3d9.dll" | grep -q "exit_code_hook\|display-mode list filter\|import patch"; then
    echo "d3d9.dll still carries the import hooks"
    exit 1
fi

mkdir -p "$OUT/i386-windows" "$OUT/x86_64-unix"
cp "$PE_OUT/d3d9.dll" "$PE_OUT/mtld3d.dll" "$PE_OUT/mtld3d.fake.dll" "$OUT/i386-windows/"
cp "$UNIX_OUT/mtld3d.so" "$OUT/x86_64-unix/"
"$SDK/bin/winebuild" --builtin "$OUT/i386-windows/d3d9.dll"
for dll in d3d9 mtld3d; do
    if [ "$(dd if="$OUT/i386-windows/$dll.dll" bs=1 skip=64 count=16 2>/dev/null)" != "Wine builtin DLL" ]; then
        echo "$dll.dll has no builtin mark"
        exit 1
    fi
done

echo "Built: $OUT"
(cd "$OUT" && shasum -a 256 i386-windows/* x86_64-unix/*)
