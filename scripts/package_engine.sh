#!/bin/bash
# MoBetta - Package the WS12WineCX26.3_Mobetta Wineskin engine
#
# Stock WS12WineCX26.3_DXMT with lib/wine/x86_64-unix/ntdll.so and opengl32.so replaced
# (build/out/ntdll.so, build/out/opengl32.so) and bin/x87sidecar added (build/out/x87sidecar), plus x87sidecar's MIT license in
# share/doc/x87sidecar/LICENSE (required when redistributing the binary).
# mtld3d (D3D9 on Metal, build/out/mtld3d/): lib/wine/i386-windows/d3d9.dll replaced (stock is
# wined3d's), i386-windows/mtld3d.dll and x86_64-unix/mtld3d.so added, its Zlib license in
# share/doc/mtld3d/LICENSE. d3d9.dll imports mtld3d.dll, which the loader finds only as a file
# on the prefix's path (syswow64/mtld3d.dll): wine.inf's [FakeDllsWow64] 11,,* has wineboot copy
# every builtin there, mtld3d.dll included, but only when it sets up or updates the prefix, and it
# updates when wine.inf's mtime differs from the prefix's .update-timestamp. wine.inf keeps stock
# content with d3d9.dll's mtime, so the first start on this engine updates an existing prefix
# (Session #14: without it, "Failed to find a suitable display device").
# Wine's LGPL text (share/doc/wine/COPYING.LIB, from the CrossOver source tree) and
# package/SOURCE.txt (share/doc/mobetta/SOURCE: what changed, where the source is) go in for the
# LGPL; the stock engine carries neither.
# Everything else is byte-for-byte stock.
# Same format as stock: ENGINE.tar.7z holding ENGINE.tar holding wswine.bundle/.
# The tar keeps stock's entry order and mtimes, so the output is reproducible.
#
# Requires: 7-Zip (brew install sevenzip), build_opengl32.sh (runs build_ntdll.sh),
# build_x87sidecar.sh and build_mtld3d.sh run first
# Usage: bash scripts/package_engine.sh [path/to/WS12WineCX26.3_DXMT.tar.7z]
# Output: build/engine/WS12WineCX26.3_Mobetta.tar.7z

set -e
cd "$(dirname "$0")/.."
ROOT="$PWD"

ENGINE="WS12WineCX26.3_Mobetta"
STOCK_ENGINE="WS12WineCX26.3_DXMT"
STOCK_ARCHIVE="${1:-$HOME/Library/Application Support/Wineskin/Engines/$STOCK_ENGINE.tar.7z}"
STOCK_SHA256="7b3f383a2209de5765eef45f1d6fc316682cfcfbb3518d7470e4b51f00e7cd08"
STOCK_NTDLL_SHA256="f4a653b12f142fe601253d764288260ce63e0620ca092dfb99ef8ffc41aad677"
NTDLL_SHA256="32d1fa05fb221a23946ff8e62162cbe5c0995145015ba8f412afc899fe726082"
STOCK_OPENGL32_SHA256="4571b05c840e7d0f49d87b11eeba2ce08391af713bcf689a19f6af25fac45c3a"
OPENGL32_SHA256="2eda5e35a3ffb3237c2423411573a7d3a6751ff4815f40b835f73878a1d876de"
SIDECAR_SHA256="881e9449565a9e2a823bfc517a30ef89d96a6388ae2f20a4dd5b7ab18058ea8e"
SIDECAR_LICENSE="$ROOT/build/x87sidecar/LICENSE"
SIDECAR_LICENSE_SHA256="b0c3f8090dbc91b3583d826944ac0570483a42407d7008c9746f943578e5d9cd"
MTLD3D_OUT="$ROOT/build/out/mtld3d"
STOCK_D3D9_SHA256="6bc5c859caeb3287dd1bd6c97ecf13c3232c29e7b4a878d76b5b842e5448bee3"
D3D9_SHA256="1193bd7f14bd632fa4ef907b59c652dc89e9aaab50bf1d5502dc6777b3abf9d4"
MTLD3D_DLL_SHA256="841a81e22abe1160ccbf5e9aab4259acec6feb2ed6ee3d36a976e4106d960de8"
MTLD3D_SO_SHA256="572c0a5ed993757416817014861a7a45b70bb95a885f381082117a099ce81457"
MTLD3D_LICENSE="$ROOT/build/mtld3d/LICENSE"
MTLD3D_LICENSE_SHA256="34218a98a2bc21b4624a0bd755d47d5fd0f4478090a3139cc1da887849dccb27"
WINE_LICENSE="$ROOT/build/src/sources/wine/COPYING.LIB"
WINE_LICENSE_SHA256="e237fa56668030e928551ddd60f05df5fe957f75eab874bbd017e085ed722e7c"
SOURCE_NOTE="$ROOT/package/SOURCE.txt"

OUT="$ROOT/build/engine"
STAGE="$OUT/stage"
BUNDLE="$STAGE/wswine.bundle"
NTDLL="lib/wine/x86_64-unix/ntdll.so"
OPENGL32="lib/wine/x86_64-unix/opengl32.so"
D3D9="lib/wine/i386-windows/d3d9.dll"
MTLD3D_DLL="lib/wine/i386-windows/mtld3d.dll"
MTLD3D_SO="lib/wine/x86_64-unix/mtld3d.so"

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
verify_sha256 "$STOCK_ARCHIVE" "$STOCK_SHA256"
verify_sha256 "$ROOT/build/out/ntdll.so" "$NTDLL_SHA256"
verify_sha256 "$ROOT/build/out/opengl32.so" "$OPENGL32_SHA256"
verify_sha256 "$ROOT/build/out/x87sidecar" "$SIDECAR_SHA256"
verify_sha256 "$SIDECAR_LICENSE" "$SIDECAR_LICENSE_SHA256"
verify_sha256 "$MTLD3D_OUT/i386-windows/d3d9.dll" "$D3D9_SHA256"
verify_sha256 "$MTLD3D_OUT/i386-windows/mtld3d.dll" "$MTLD3D_DLL_SHA256"
verify_sha256 "$MTLD3D_OUT/x86_64-unix/mtld3d.so" "$MTLD3D_SO_SHA256"
verify_sha256 "$MTLD3D_LICENSE" "$MTLD3D_LICENSE_SHA256"
verify_sha256 "$WINE_LICENSE" "$WINE_LICENSE_SHA256"

# Stock engine, unpacked
rm -rf "$OUT"
mkdir -p "$STAGE"
7zz x -so "$STOCK_ARCHIVE" | tar -xpf - -C "$STAGE"
7zz x -so "$STOCK_ARCHIVE" | tar -tf - > "$OUT/entries.txt"
verify_sha256 "$BUNDLE/$NTDLL" "$STOCK_NTDLL_SHA256"
verify_sha256 "$BUNDLE/$OPENGL32" "$STOCK_OPENGL32_SHA256"
verify_sha256 "$BUNDLE/$D3D9" "$STOCK_D3D9_SHA256"

# Our files, with the mtimes of the stock entries they replace (bin/, share/ and the lib/wine
# directories keep their own); mtld3d's new files take d3d9.dll's
stamp() { date -r "$(stat -f %m "$1")" +%Y%m%d%H%M.%S; }
bin_stamp=$(stamp "$BUNDLE/bin")
ntdll_stamp=$(stamp "$BUNDLE/$NTDLL")
opengl32_stamp=$(stamp "$BUNDLE/$OPENGL32")
version_stamp=$(stamp "$BUNDLE/version")
share_stamp=$(stamp "$BUNDLE/share")
d3d9_stamp=$(stamp "$BUNDLE/$D3D9")
wineinf_stamp=$(stamp "$BUNDLE/share/wine/wine.inf")
i386_stamp=$(stamp "$BUNDLE/lib/wine/i386-windows")
unix_stamp=$(stamp "$BUNDLE/lib/wine/x86_64-unix")
cp "$ROOT/build/out/ntdll.so" "$BUNDLE/$NTDLL"
cp "$ROOT/build/out/opengl32.so" "$BUNDLE/$OPENGL32"
cp "$ROOT/build/out/x87sidecar" "$BUNDLE/bin/x87sidecar"
chmod 755 "$BUNDLE/$NTDLL" "$BUNDLE/$OPENGL32" "$BUNDLE/bin/x87sidecar"
printf '%s\n' "$ENGINE" > "$BUNDLE/version"
touch -m -t "$ntdll_stamp" "$BUNDLE/$NTDLL" "$BUNDLE/bin/x87sidecar"
touch -m -t "$opengl32_stamp" "$BUNDLE/$OPENGL32"
touch -m -t "$version_stamp" "$BUNDLE/version"
touch -m -t "$bin_stamp" "$BUNDLE/bin"
mkdir -p "$BUNDLE/share/doc/x87sidecar"
install -m 644 "$SIDECAR_LICENSE" "$BUNDLE/share/doc/x87sidecar/LICENSE"
touch -m -t "$ntdll_stamp" "$BUNDLE/share/doc/x87sidecar/LICENSE" "$BUNDLE/share/doc/x87sidecar" "$BUNDLE/share/doc"
cp "$MTLD3D_OUT/i386-windows/d3d9.dll" "$BUNDLE/$D3D9"
cp "$MTLD3D_OUT/i386-windows/mtld3d.dll" "$BUNDLE/$MTLD3D_DLL"
cp "$MTLD3D_OUT/x86_64-unix/mtld3d.so" "$BUNDLE/$MTLD3D_SO"
chmod 644 "$BUNDLE/$D3D9" "$BUNDLE/$MTLD3D_DLL"
chmod 755 "$BUNDLE/$MTLD3D_SO"
touch -m -t "$d3d9_stamp" "$BUNDLE/$D3D9" "$BUNDLE/$MTLD3D_DLL" "$BUNDLE/$MTLD3D_SO"
touch -m -t "$d3d9_stamp" "$BUNDLE/share/wine/wine.inf"
if [ "$(stamp "$BUNDLE/share/wine/wine.inf")" = "$wineinf_stamp" ]; then
    echo "wine.inf mtime equals stock's: existing prefixes would not get syswow64/mtld3d.dll"
    exit 1
fi
touch -m -t "$i386_stamp" "$BUNDLE/lib/wine/i386-windows"
touch -m -t "$unix_stamp" "$BUNDLE/lib/wine/x86_64-unix"
mkdir -p "$BUNDLE/share/doc/mtld3d"
install -m 644 "$MTLD3D_LICENSE" "$BUNDLE/share/doc/mtld3d/LICENSE"
touch -m -t "$d3d9_stamp" "$BUNDLE/share/doc/mtld3d/LICENSE" "$BUNDLE/share/doc/mtld3d"
mkdir -p "$BUNDLE/share/doc/wine" "$BUNDLE/share/doc/mobetta"
install -m 644 "$WINE_LICENSE" "$BUNDLE/share/doc/wine/COPYING.LIB"
install -m 644 "$SOURCE_NOTE" "$BUNDLE/share/doc/mobetta/SOURCE"
touch -m -t "$ntdll_stamp" "$BUNDLE/share/doc/wine/COPYING.LIB" "$BUNDLE/share/doc/wine" \
    "$BUNDLE/share/doc/mobetta/SOURCE" "$BUNDLE/share/doc/mobetta"
touch -m -t "$ntdll_stamp" "$BUNDLE/share/doc"
touch -m -t "$share_stamp" "$BUNDLE/share"
cat >> "$OUT/entries.txt" <<EOF2
wswine.bundle/bin/x87sidecar
wswine.bundle/share/doc/
wswine.bundle/share/doc/x87sidecar/
wswine.bundle/share/doc/x87sidecar/LICENSE
wswine.bundle/share/doc/mtld3d/
wswine.bundle/share/doc/mtld3d/LICENSE
wswine.bundle/share/doc/wine/
wswine.bundle/share/doc/wine/COPYING.LIB
wswine.bundle/share/doc/mobetta/
wswine.bundle/share/doc/mobetta/SOURCE
wswine.bundle/$MTLD3D_DLL
wswine.bundle/$MTLD3D_SO
EOF2

# Repack: stock entry order, no recursion, neutral owner. No xattrs: stock carries the
# packager's com.apple.provenance/quarantine, and fresh copies get new values per run
(cd "$STAGE" && COPYFILE_DISABLE=1 tar -cf "$OUT/$ENGINE.tar" -n --no-mac-metadata --no-xattrs --no-acls --no-fflags \
    --uid 0 --gid 0 --uname root --gname wheel -T "$OUT/entries.txt")
touch -m -t "$ntdll_stamp" "$OUT/$ENGINE.tar"
(cd "$OUT" && 7zz a -t7z -m0=lzma2 -mx=9 -mmt=4 -bd "$ENGINE.tar.7z" "$ENGINE.tar" > /dev/null)

# Check: every stock file's content is unchanged except ntdll.so, opengl32.so, d3d9.dll and
# version; x87sidecar, mtld3d.dll, mtld3d.so, the licenses and SOURCE are new
sums() { (cd "$1" && find . -type f -print0 | sort -z | xargs -0 shasum -a 256); }
mkdir -p "$OUT/check/stock" "$OUT/check/ours"
7zz x -so "$STOCK_ARCHIVE" | tar -xf - -C "$OUT/check/stock"
7zz x -so "$OUT/$ENGINE.tar.7z" | tar -xf - -C "$OUT/check/ours"
changed=$(diff <(sums "$OUT/check/stock") <(sums "$OUT/check/ours") | grep '^>' | awk '{print $3}' | LC_ALL=C sort | tr '\n' ' ')
expected="./wswine.bundle/bin/x87sidecar ./wswine.bundle/$D3D9 ./wswine.bundle/$MTLD3D_DLL ./wswine.bundle/$MTLD3D_SO ./wswine.bundle/$NTDLL ./wswine.bundle/$OPENGL32 ./wswine.bundle/share/doc/mobetta/SOURCE ./wswine.bundle/share/doc/mtld3d/LICENSE ./wswine.bundle/share/doc/wine/COPYING.LIB ./wswine.bundle/share/doc/x87sidecar/LICENSE ./wswine.bundle/version "
if [ "$changed" != "$expected" ]; then
    echo "Unexpected changes vs stock: $changed"
    exit 1
fi
echo "Changed vs stock: $changed"

rm -rf "$OUT/check"

rm -rf "$STAGE" "$OUT/$ENGINE.tar"
echo "Built: $OUT/$ENGINE.tar.7z"
shasum -a 256 "$OUT/$ENGINE.tar.7z"
