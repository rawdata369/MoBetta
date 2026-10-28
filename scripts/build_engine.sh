#!/bin/bash
# MoBetta - Build the WS12WineCX26.3_Mobetta engine from source, start to finish
#
# Runs the whole chain from a fresh clone, each step checked against its pinned SHA-256:
#   build_opengl32.sh (runs build_ntdll.sh): ntdll.so, opengl32.so
#   build_x87sidecar.sh: x87sidecar
#   build_mtld3d.sh: d3d9.dll, mtld3d.dll, mtld3d.so
#   package_engine.sh: WS12WineCX26.3_Mobetta.tar.7z
# and ends printing the engine SHA-256, which must equal the release's (DECISIONS.md #10).
# Downloads (CrossOver source, llvm-mingw, x87sidecar and mtld3d repos, xwin CRT/SDK,
# cargo crates) land in build/ and the cargo home; each is pinned by hash or commit.
#
# Requires: Xcode Command Line Tools (Apple clang 21.0.0, clang-2100.3.34.2: see
# build_x87sidecar.sh), ARM Homebrew bison, cmake, sevenzip, gh (logged in), rustup
# (stable >= 1.99 with llvm-tools, targets i686-pc-windows-msvc and x86_64-apple-darwin),
# cargo-installed xwin, and the stock WS12WineCX26.3_DXMT engine (Wineskin's engine list)
# Usage: bash scripts/build_engine.sh [--clean] [path/to/WS12WineCX26.3_DXMT.tar.7z]
# Output: build/engine/WS12WineCX26.3_Mobetta.tar.7z

set -e
cd "$(dirname "$0")/.."
ROOT="$PWD"

ENGINE_SHA256="71cb623920136b06f4515074b2dc238c702c0b76bf4cb1f68aa0511e48588441"

CLEAN=
if [ "$1" = "--clean" ]; then
    CLEAN=--clean
    shift
fi
STOCK_ARCHIVE="${1:-$HOME/Library/Application Support/Wineskin/Engines/WS12WineCX26.3_DXMT.tar.7z}"

# Prerequisites up front, so a missing tool fails here and not an hour in
missing=
for t in 7zz cmake gh git rustup rustc xwin brew; do
    command -v "$t" > /dev/null || missing="$missing $t"
done
[ -n "$missing" ] && { echo "Not found:$missing"; exit 1; }
brew --prefix bison > /dev/null 2>&1 || { echo "ARM Homebrew bison not found (brew install bison)"; exit 1; }
for t in i686-pc-windows-msvc x86_64-apple-darwin; do
    rustup +stable target list --installed | grep -qx "$t" || { echo "rustup target $t missing (rustup +stable target add $t)"; exit 1; }
done
[ -f "$STOCK_ARCHIVE" ] || { echo "Stock engine not found: $STOCK_ARCHIVE"; exit 1; }
clang_version=$(/usr/bin/clang --version | head -1)
case "$clang_version" in
    *"clang-2100.3.34.2"*) ;;
    *) echo "Warning: $clang_version is not the pinned clang-2100.3.34.2; x87sidecar's hash may differ" ;;
esac

step() { echo; echo "== $1"; }

step "ntdll.so, opengl32.so"
bash "$ROOT/scripts/build_opengl32.sh" $CLEAN "$STOCK_ARCHIVE"
step "x87sidecar"
bash "$ROOT/scripts/build_x87sidecar.sh" $CLEAN
step "mtld3d"
bash "$ROOT/scripts/build_mtld3d.sh" $CLEAN
step "Engine package"
bash "$ROOT/scripts/package_engine.sh" "$STOCK_ARCHIVE"

ENGINE_ARCHIVE="$ROOT/build/engine/WS12WineCX26.3_Mobetta.tar.7z"
actual=$(shasum -a 256 "$ENGINE_ARCHIVE" | awk '{print $1}')
echo
if [ "$actual" != "$ENGINE_SHA256" ]; then
    echo "Engine SHA-256 mismatch for $ENGINE_ARCHIVE"
    echo "  expected $ENGINE_SHA256"
    echo "  actual   $actual"
    exit 1
fi
echo "Engine matches the release:"
echo "$actual  $ENGINE_ARCHIVE"
