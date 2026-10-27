# Changelog

All notable changes to MoBetta, newest first. Dates are YYYY-MM-DD.

## 2026-10-27 - Engine package

### Added
- **`WS12WineCX26.3_Mobetta` Wineskin engine**, built by `scripts/package_engine.sh` from the stock `WS12WineCX26.3_DXMT` engine. Changes from stock: MoBetta's `ntdll.so`, `bin/x87sidecar`, the sidecar's MIT license (`share/doc/x87sidecar/LICENSE`), and the `version` file. Every other file is byte-for-byte stock. The build is reproducible (SHA-256 `cf244efd1625030a21d763968cef59e4f2911f8b90ac493dd09ae8c0bdadca51`)
- `scripts/build_x87sidecar.sh`: builds x87sidecar from a pinned upstream commit, checks the binary hash, and runs the sidecar's `--probe` compatibility check
- `scripts/baseline.sh`: SHA-256 baseline of the game folder (`take` / `verify`). It also reports added or removed files, to prove that a test run changed nothing in the game

### Changed
- The engine package leaves out macOS extended attributes (quarantine/provenance flags) that the stock archive carries

## 2026-10-27 - 4x frame rate: x87sidecar

### Added
- **i386 processes start under [x87sidecar](https://github.com/athei/x87sidecar)** (`patches/0003`). WoW 3.3.5a does its math in x87 floating point, and Rosetta 2 runs that in a slow software path. Profiling showed 65% of the game's main thread in that code. x87sidecar makes Rosetta translate x87 to native ARM floating point instead
- Result in game: **80 FPS average, 106 max** (was 20 average, 23-25 max). Tested over 30+ minute sessions with no game files changed
- The sidecar runs as a separate process next to the game. Nothing is injected into Wow.exe and no game files are patched
- If the sidecar is missing or unsupported on the installed macOS, the game still runs on stock Rosetta (slower). `ROSETTA_X87_PATH=` (empty) turns it off

## 2026-10-23 - DEP stays on under Rosetta

### Changed
- Data Execution Prevention stays permanently on for x86 processes under Rosetta (`patches/0002`), as it is on Windows for this game. With DEP off, every writable and executable memory page costs an extra round trip under Rosetta. No measurable FPS change for WoW 3.3.5a, so it is kept to match Windows behaviour. `WINE_FORCE_NX=0` turns it off

## 2026-10-23 - Character select crash fixed

### Fixed
- **`ERROR #132 ... ILLEGAL_INSTRUCTION` at character select** (`patches/0001`). Rosetta 2 rejects two kinds of legacy x86 instructions that the 3.3.5a client uses: `ARPL` and nine undocumented x87 opcode aliases. Wine's signal handler now emulates them exactly, giving the same result as on real x86 hardware
- Tested in game: login, realm select, character creation, intro cutscene, and playing in the world
- Covered by 4153 unit checks (every addressing form of `ARPL`, every x87 alias on every register)

## 2026-10-23 - Reproducible build

### Added
- `scripts/build_ntdll.sh`: cross-compiles Wine's x86_64 `ntdll.so` from CrossOver 26.3.0 source natively on Apple Silicon, with no Rosetta toolchain. It applies `patches/` in order, and builds are byte-for-byte reproducible
