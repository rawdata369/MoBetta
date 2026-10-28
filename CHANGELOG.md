# Changelog

All notable changes to MoBetta, newest first. Dates are YYYY-MM-DD.

## 2026-10-28 - In-game FPS screenshots

### Added
- **Performance section in the README** with eight in-game screenshots and an FPS table, on the v1.0.0 engine on a MacBook M3 at medium-high settings: 191 FPS at the Ironforge gate, 155 in Stormwind, 138 in Orgrimmar, down to 97 in Booty Bay in the rain and 86 in Shattrath. Images are in `docs/screenshots/`, with chat and character names blurred
- **Why MoBetta** in the README: what it does differently from WoWSilicon (no game-folder patching, nothing added to the game process)
- **Porting Kit guide** (`docs/PORTING_KIT.md`): a new port with the MoBetta engine, step by step with screenshots, plus switching an existing port's engine through Wineskin, and turning off Vertical Sync in game

## 2026-10-28 - First release: install guide, checksums, licenses

### Added
- **Install guide** in the README: download, check with `SHA256SUMS`, put the engine in Wineskin's Engines folder, switch a Porting Kit or Wineskin wrapper to it through its `Wineskin.app` (Advanced > Tools > Change Engine Used)
- **`SHA256SUMS`** with the release engine's hash. `build_engine.sh` checks the same value
- **License:** MoBetta is LGPL 2.1 or later, the same as Wine (`LICENSE`)
- **The engine now carries Wine's license and a source note.** `share/doc/wine/COPYING.LIB` is Wine's LGPL text. `share/doc/mobetta/SOURCE` lists every file that differs from the stock engine and where its exact source is. The stock engine had neither. No code changed; engine SHA-256 `9bc8ec0626d050dcd0de110ced7ca331e62df0ab48211633cc0b5462807b5beb` (was `71cb6239...`)

### Fixed
- **`build_mtld3d.sh` explains a shared-Mac clash.** mtld3d has to build in `/private/tmp/mobetta-mtld3d` for its output to match the release. If another user on the Mac built there first, the script now says so and stops, instead of failing midway

## 2026-10-28 - One build script, same bytes anywhere

### Added
- **`scripts/build_engine.sh` builds the whole engine from a fresh clone.** It checks the tools it needs first, runs the four build steps, and fails unless the engine matches the pinned SHA-256: `71cb623920136b06f4515074b2dc238c702c0b76bf4cb1f68aa0511e48588441`. A clone in another directory, with every download fetched again, produced the same engine byte for byte

### Fixed
- **Wine's `ntdll.so` and `opengl32.so` now build the same in any directory.** Their Mach-O UUID was computed from debug info that recorded absolute build paths, so a build elsewhere differed in those 16 bytes. Source and object paths are now written relative to the repo. The code is unchanged; new hashes `32d1fa05...` (ntdll.so) and `2eda5e35...` (opengl32.so), engine `71cb6239...` (was `41d2a31e...`). Tested in game: loads, same frame rate
- **mtld3d failed to build in a fresh tree.** A Wine library it links against was built without our cross compiler on the path, so Homebrew's mingw gcc was picked up instead. `build_ntdll.sh` now builds it with the right compiler

## 2026-10-28 - Direct3D 9 on Metal in the engine package

### Added
- **The engine package now includes our mtld3d build**, so Direct3D 9 runs straight on Metal with nothing to set up in the wrapper. `lib/wine/i386-windows/d3d9.dll` is mtld3d's, with `mtld3d.dll` and `mtld3d.so` added and mtld3d's Zlib license in `share/doc/mtld3d/LICENSE`. **~170 FPS in a light view, ~140 at the inn** (the previous package: 106-116 and 60-80). `scripts/package_engine.sh` now needs `scripts/build_mtld3d.sh` run first; engine SHA-256 `41d2a31e36570ca1b5e0db65ccda3d92018894663182c2598c66602201751f6e`, the same on every run
- Works as a drop-in for an existing wrapper. On the first start, Wine updates the prefix once, as after any engine upgrade, and places `mtld3d.dll` where the game's `d3d9.dll` looks for it. Without that update the game stopped with "Failed to find a suitable display device". The package keeps Wine's `wine.inf` unchanged except for a newer file date, which is what triggers the update

### Fixed
- **mtld3d no longer writes into the game folder** (`patches/mtld3d/0003`). By default it put its log folder, `mtld3d-logs`, next to Wow.exe, and the same folder was used for crash reports. The default is now `mtld3d-logs` in the prefix's `AppData\Local`. Our test wrapper had avoided it with an `MTLD3D_CONFIG` registry setting, which an engine package cannot carry

## 2026-10-27 - mtld3d: built-in WoW defaults, reproducible build

### Changed
- **HDR off and the shader cache off are now built into our mtld3d** (`patches/mtld3d/0002`), in mtld3d's own World of Warcraft profile. No `MTLD3D_CONFIG` setting is needed any more, so a wrapper gets the fix from the engine alone. The shader cache stays off because mtld3d writes it next to Wow.exe, inside the game folder. `mtld3d.conf` or `MTLD3D_CONFIG` can still turn either back on. Same startup (first frame in 2 s) and frame rate as before
- **`scripts/build_mtld3d.sh` is byte-for-byte reproducible on any Mac.** Two clean builds, from different clones with different cargo homes, give the same four files. The build runs in a fixed directory (`/private/tmp/mobetta-mtld3d`), source paths are rewritten to fixed names, and the DLLs are linked without a PDB, whose link command line made every build's hash different. Anyone can build mtld3d from source and compare the result with ours

## 2026-10-27 - Direct3D 9 on Metal (in testing)

### Added
- **Our own build of [mtld3d](https://github.com/athei/mtld3d)**, which runs the game's Direct3D 9 straight on Metal instead of through Wine's OpenGL. `scripts/build_mtld3d.sh` builds it at a pinned upstream commit with `patches/mtld3d/0001` applied. The patch removes two hooks the upstream release installs at load time, which rewrite the game's import table in memory. Our build leaves Wow.exe's memory untouched, as everything else in MoBetta does
- The build marks mtld3d's `d3d9.dll` as a Wine builtin. Without the mark, Wine skips it and quietly loads the stock `d3d9.dll`
- Result in WoW 3.3.5a (Shadowglen, windowed, one run each): **106-116 -> ~170 FPS** in a light view (often 180), **60-80 -> ~140 FPS** in the heaviest view (the inn; max 151). In window mode the title bar is no longer transparent, and the cursor no longer flickers between the Mac and game cursors while turning the camera with the right mouse button
- Not in the engine package yet. Tested in a wrapper by hand; packaging comes next

### Fixed
- **45 s black or choppy title screen at startup, and a ~20 s freeze on maximize**, with mtld3d. They came from mtld3d's HDR output (an EDR layer on macOS). While macOS ramps the display's HDR brightness, Wine's desktop process keeps reloading the display list every ~250 ms, and the game waits on it until the ramp ends. Running mtld3d with `color.hdr.enable=false` (in `MTLD3D_CONFIG`) brings the first frame in 2 s after start and removes the freeze. WoW 3.3.5a has no HDR content, so colors look the same, and the frame rate is equal or slightly higher

## 2026-10-27 - Faster GL buffer mapping

### Changed
- **Up to ~20% higher frame rate** (`patches/0004`). In a 32-bit game, every time Wine's OpenGL hands the game a pointer into a graphics buffer that lives above 4 GB, it maps that memory again into the low 4 GB, and the game's writes then fault the pages in again. The driver almost always returns the same memory (99.7% of maps in a WoW 3.3.5a test run), so the low mapping is now kept and reused while it still points at the same memory. Wine checks that on every map and maps again when the driver has moved or replaced the buffer
- Result in WoW 3.3.5a (Shadowglen, windowed, vsync off, one run each): **85-105 -> 106-116 FPS** in a light view, **56-75 -> 60-80 FPS** in the heaviest view (the inn); max 127 FPS. Time the render thread spends mapping buffers: 6.8% -> 2.7%
- The engine now also replaces `lib/wine/x86_64-unix/opengl32.so`. `scripts/build_opengl32.sh` builds it reproducibly; engine package SHA-256 `7cecba75417e0f5ef9d0a440535cd4abfa6f70b64d76f1e008f803eaffa94cb8`

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
