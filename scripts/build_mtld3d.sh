#!/bin/bash
# MoBetta - Build mtld3d (athei/mtld3d, D3D9 on Metal) at the pinned release
#
# Applies patches/mtld3d/*.patch in order (0001 drops the Wow.exe import hooks).
# Builds the two pieces a 32-bit game on our x86_64 Wine loads:
#   i386-windows/{d3d9,mtld3d}.dll (+ mtld3d.fake.dll, the prefix marker)
#   x86_64-unix/mtld3d.so
# Output: build/out/mtld3d/, with SHA-256 sums printed (not pinned yet).
# mtld3d.so and mtld3d.fake.dll rebuild identical. The two DLLs' code does too,
# but /Brepro derives their timestamp and PDB GUID from the PDB, which records
# rustc's random deps/rustcXXXXXX link directory, so those fields vary per build.
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
SDK="$ROOT/build/mtld3d-sdk"
XWIN="$ROOT/build/xwin"
WINE64_BUILD="$ROOT/build/wine64"
OUT="$ROOT/build/out/mtld3d"
PE_OUT="$SRC/windows/target/i686-pc-windows-msvc/production"
UNIX_OUT="$SRC/unix/target/x86_64-apple-darwin/production"

# PE linker and archiver from the toolchain's llvm-tools (mtld3d's setup-rust)
TOOLS="$(rustc +stable --print sysroot)/lib/rustlib/$(rustc +stable -vV | sed -n 's/^host: //p')/bin"
CARGO_BIN="${CARGO_HOME:-$HOME/.cargo}/bin"
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
    rm -rf "$SRC/windows/target" "$SRC/unix/target"
fi

# Build-only WINE_SDK
make -C "$WINE64_BUILD" -s dlls/winecrt0/i386-windows/libwinecrt0.a \
    dlls/winecrt0/x86_64-windows/libwinecrt0.a > /dev/null
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
env RUSTFLAGS="-C target-cpu=pentium4 -C target-feature=-crt-static -C link-arg=/Brepro -Lnative=$XWIN/crt/lib/x86 -Lnative=$XWIN/sdk/lib/um/x86 -Lnative=$XWIN/sdk/lib/ucrt/x86" \
    "CFLAGS_i686-pc-windows-msvc=-march=pentium4 -fno-omit-frame-pointer $INC" \
    "CXXFLAGS_i686-pc-windows-msvc=-march=pentium4 -fno-omit-frame-pointer $INC" \
    make -C "$SRC" PROD=1 WINE_SDK="$SDK" windows-i686 > "$LOG" 2>&1 \
    || { tail -20 "$LOG"; exit 1; }
make -C "$SRC" PROD=1 WINE_SDK="$SDK" unix-x64 >> "$LOG" 2>&1 \
    || { tail -20 "$LOG"; exit 1; }

# The hooks must be gone from d3d9.dll
if strings -a "$PE_OUT/d3d9.dll" | grep -q "exit_code_hook\|display-mode list filter\|import patch"; then
    echo "d3d9.dll still carries the import hooks"
    exit 1
fi

mkdir -p "$OUT/i386-windows" "$OUT/x86_64-unix"
cp "$PE_OUT/d3d9.dll" "$PE_OUT/mtld3d.dll" "$PE_OUT/mtld3d.fake.dll" "$OUT/i386-windows/"
cp "$UNIX_OUT/mtld3d.so" "$OUT/x86_64-unix/"

echo "Built: $OUT"
(cd "$OUT" && shasum -a 256 i386-windows/* x86_64-unix/*)
