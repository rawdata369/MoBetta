#!/bin/bash
# MoBetta - SHA-256 baseline of the game folder (hard constraint 5: before/after each test)
#
# Read-only on the game folder. Skips folders the game writes to itself:
# WTF/, Cache/, Logs/, Errors/, Screenshots/.
# verify also fails on files added or removed since the baseline was taken.
#
# Usage: bash scripts/baseline.sh take|verify [game folder]
# Baseline: baseline.sha256 at the repo root (git-ignored); BASELINE=path overrides

set -e
cd "$(dirname "$0")/.."
ROOT="$PWD"

GAME="${2:-$HOME/Games/warmane/warmane.app/Contents/SharedSupport/prefix/drive_c/Program Files (x86)/World of Warcraft 3.3.5a}"
BASELINE="${BASELINE:-$ROOT/baseline.sha256}"

list_files() {
    (cd "$GAME" && find . -type f \
        ! -path "./WTF/*" ! -path "./Cache/*" ! -path "./Logs/*" \
        ! -path "./Errors/*" ! -path "./Screenshots/*" | LC_ALL=C sort)
}

[ -f "$GAME/Wow.exe" ] || { echo "No Wow.exe in $GAME"; exit 1; }

case "$1" in
take)
    if [ -f "$BASELINE" ]; then
        mv "$BASELINE" "$BASELINE.prev"
        echo "Old baseline moved to $BASELINE.prev"
    fi
    list_files | (cd "$GAME" && tr '\n' '\0' | xargs -0 shasum -a 256) > "$BASELINE"
    echo "Baseline: $(wc -l < "$BASELINE" | tr -d ' ') files -> $BASELINE"
    ;;
verify)
    [ -f "$BASELINE" ] || { echo "No baseline at $BASELINE (run: take)"; exit 1; }
    status=0
    names=$(diff <(cut -c67- "$BASELINE" | LC_ALL=C sort) <(list_files)) || true
    if [ -n "$names" ]; then
        echo "Files added (>) or removed (<) since the baseline:"
        echo "$names" | grep '^[<>]'
        status=1
    fi
    if ! failed=$(cd "$GAME" && shasum -a 256 -c --quiet "$BASELINE" 2>&1); then
        echo "Changed files:"
        echo "$failed"
        status=1
    fi
    if [ "$status" = 0 ]; then
        echo "Baseline OK: $(wc -l < "$BASELINE" | tr -d ' ')/$(wc -l < "$BASELINE" | tr -d ' ') files match"
    else
        echo "BASELINE FAILED"
    fi
    exit $status
    ;;
*)
    echo "Usage: bash scripts/baseline.sh take|verify [game folder]"
    exit 2
    ;;
esac
