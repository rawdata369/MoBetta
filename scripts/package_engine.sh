#!/bin/bash
# MoBetta - Package the WS12WineCX26.3_Mobetta Wineskin engine
#
# Stock WS12WineCX26.3_DXMT with lib/wine/x86_64-unix/ntdll.so and opengl32.so replaced
# (build/out/ntdll.so, build/out/opengl32.so) and bin/x87sidecar added (build/out/x87sidecar), plus x87sidecar's MIT license in
# share/doc/x87sidecar/LICENSE (required when redistributing the binary).
# Everything else is byte-for-byte stock.
# Same format as stock: ENGINE.tar.7z holding ENGINE.tar holding wswine.bundle/.
# The tar keeps stock's entry order and mtimes, so the output is reproducible.
#
# Requires: 7-Zip (brew install sevenzip), build_opengl32.sh (runs build_ntdll.sh) and
# build_x87sidecar.sh run first
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
NTDLL_SHA256="62b15cba602b0011976dacb30b8903379021b306a930c2d7df3e2cbf6e50763a"
STOCK_OPENGL32_SHA256="4571b05c840e7d0f49d87b11eeba2ce08391af713bcf689a19f6af25fac45c3a"
OPENGL32_SHA256="53a7b678890b206c5a9224d41beb74395354875298830b050863eb22541feef6"
SIDECAR_SHA256="881e9449565a9e2a823bfc517a30ef89d96a6388ae2f20a4dd5b7ab18058ea8e"
SIDECAR_LICENSE="$ROOT/build/x87sidecar/LICENSE"
SIDECAR_LICENSE_SHA256="b0c3f8090dbc91b3583d826944ac0570483a42407d7008c9746f943578e5d9cd"

OUT="$ROOT/build/engine"
STAGE="$OUT/stage"
BUNDLE="$STAGE/wswine.bundle"
NTDLL="lib/wine/x86_64-unix/ntdll.so"
OPENGL32="lib/wine/x86_64-unix/opengl32.so"

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

# Stock engine, unpacked
rm -rf "$OUT"
mkdir -p "$STAGE"
7zz x -so "$STOCK_ARCHIVE" | tar -xpf - -C "$STAGE"
7zz x -so "$STOCK_ARCHIVE" | tar -tf - > "$OUT/entries.txt"
verify_sha256 "$BUNDLE/$NTDLL" "$STOCK_NTDLL_SHA256"
verify_sha256 "$BUNDLE/$OPENGL32" "$STOCK_OPENGL32_SHA256"

# Our files, with the mtimes of the stock entries they replace (bin/ and share/ keep their own)
stamp() { date -r "$(stat -f %m "$1")" +%Y%m%d%H%M.%S; }
bin_stamp=$(stamp "$BUNDLE/bin")
ntdll_stamp=$(stamp "$BUNDLE/$NTDLL")
opengl32_stamp=$(stamp "$BUNDLE/$OPENGL32")
version_stamp=$(stamp "$BUNDLE/version")
share_stamp=$(stamp "$BUNDLE/share")
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
touch -m -t "$share_stamp" "$BUNDLE/share"
cat >> "$OUT/entries.txt" <<EOF2
wswine.bundle/bin/x87sidecar
wswine.bundle/share/doc/
wswine.bundle/share/doc/x87sidecar/
wswine.bundle/share/doc/x87sidecar/LICENSE
EOF2

# Repack: stock entry order, no recursion, neutral owner. No xattrs: stock carries the
# packager's com.apple.provenance/quarantine, and fresh copies get new values per run
(cd "$STAGE" && COPYFILE_DISABLE=1 tar -cf "$OUT/$ENGINE.tar" -n --no-mac-metadata --no-xattrs --no-acls --no-fflags \
    --uid 0 --gid 0 --uname root --gname wheel -T "$OUT/entries.txt")
touch -m -t "$ntdll_stamp" "$OUT/$ENGINE.tar"
(cd "$OUT" && 7zz a -t7z -m0=lzma2 -mx=9 -mmt=4 -bd "$ENGINE.tar.7z" "$ENGINE.tar" > /dev/null)

# Check: every stock file's content is unchanged except ntdll.so, opengl32.so and version;
# x87sidecar + LICENSE are new
sums() { (cd "$1" && find . -type f -print0 | sort -z | xargs -0 shasum -a 256); }
mkdir -p "$OUT/check/stock" "$OUT/check/ours"
7zz x -so "$STOCK_ARCHIVE" | tar -xf - -C "$OUT/check/stock"
7zz x -so "$OUT/$ENGINE.tar.7z" | tar -xf - -C "$OUT/check/ours"
changed=$(diff <(sums "$OUT/check/stock") <(sums "$OUT/check/ours") | grep '^>' | awk '{print $3}' | LC_ALL=C sort | tr '\n' ' ')
expected="./wswine.bundle/bin/x87sidecar ./wswine.bundle/$NTDLL ./wswine.bundle/$OPENGL32 ./wswine.bundle/share/doc/x87sidecar/LICENSE ./wswine.bundle/version "
if [ "$changed" != "$expected" ]; then
    echo "Unexpected changes vs stock: $changed"
    exit 1
fi
echo "Changed vs stock: $changed"

rm -rf "$OUT/check"

rm -rf "$STAGE" "$OUT/$ENGINE.tar"
echo "Built: $OUT/$ENGINE.tar.7z"
shasum -a 256 "$OUT/$ENGINE.tar.7z"
