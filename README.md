# MoBetta

Custom Wine engine for running World of Warcraft 3.3.5a (WotLK) on Apple Silicon Macs.

## The Problem

WoW 3.3.5a crashes at character select when running under Wine on Apple Silicon:

```
ERROR #132 (0x85100084) Fatal Exception
Exception: 0xC000001D (ILLEGAL_INSTRUCTION)
```

This affects all old WoW clients (1.12, 2.4.3, 3.3.5a) because Rosetta 2 doesn't implement certain legacy x86 instructions.

## The Solution

MoBetta is a Wineskin engine. Everything happens inside Wine:

- **The crash:** Wine's signal handler emulates the instructions Rosetta 2 rejects (`ARPL` and nine undocumented x87 opcodes), exactly as real x86 hardware runs them
- **The frame rate:** game processes start under [x87sidecar](https://github.com/athei/x87sidecar), which makes Rosetta translate the game's x87 floating point to native ARM code instead of a slow software path. **20 FPS -> 80 FPS average** (106 max)
- **Graphics buffers:** Wine's OpenGL keeps the low-memory view of a graphics buffer between maps instead of rebuilding it every time. Up to ~20% more FPS, 127 max
- **DEP** stays on under Rosetta, as on Windows
- **Direct3D 9 on Metal:** our build of [mtld3d](https://github.com/athei/mtld3d), without the hooks its release puts into the game's memory, with HDR off and its logs kept out of the game folder. ~140 FPS at the inn (was 60-80), ~170 in a light view

**Key constraint:** No game file modifications, nothing injected into the game process. This engine is designed for use with servers that run anti-cheat systems. A SHA-256 baseline of the game folder is checked before and after every test.

## Status

🚧 **In Development**

- [x] Phase 1: Confirm faulting instructions
- [x] Phase 2: Reproducible engine build
- [x] Phase 3: Instruction emulation (in game: past character select, playing in the world)
- [x] Phase 3b: Performance (20 -> 80 FPS average, 30+ minute sessions; buffer mapping up to ~20% more)
- [x] Engine package `WS12WineCX26.3_Mobetta`
- [x] mtld3d (Direct3D 9 on Metal) in the engine package (~140 FPS at the inn)
- [ ] One build script for the whole engine, reproducible from any directory
- [ ] Phase 4: Wider testing

See [CHANGELOG.md](CHANGELOG.md) for details.

## Target Environment

- **Machine:** Apple Silicon Mac (M1/M2/M3)
- **Wrapper:** Porting Kit / Wineskin
- **Base:** CrossOver 26.3 Wine (Wineskin engine `WS12WineCX26.3_DXMT`)
- **Game:** WoW 3.3.5a (build 12340)
- **Tested on:** MacBook M3, macOS 27

## Building

Requires Xcode Command Line Tools and Homebrew (`bison`, `cmake`, `sevenzip`, `gh`), plus the stock `WS12WineCX26.3_DXMT.tar.7z` in Wineskin's Engines folder.

```bash
bash scripts/build_opengl32.sh     # Wine ntdll.so and opengl32.so with patches/ applied
bash scripts/build_x87sidecar.sh   # x87sidecar at the pinned commit
bash scripts/build_mtld3d.sh       # mtld3d, Direct3D 9 on Metal (needs Rust and xwin)
bash scripts/package_engine.sh     # -> build/engine/WS12WineCX26.3_Mobetta.tar.7z
```

Every step checks SHA-256 hashes, and the output is reproducible.

## Installing

1. Copy `WS12WineCX26.3_Mobetta.tar.7z` to `~/Library/Application Support/Wineskin/Engines/`
2. Create a new wrapper with that engine in Wineskin Winery (or change the engine of an existing wrapper)
3. Run the game as usual. The first start on this engine updates the prefix once, as after any engine change

mtld3d writes its log to `drive_c/users/<user>/AppData/Local/mtld3d-logs/` in the prefix.

## Tests

```bash
bash scripts/test_emu.sh           # instruction emulation, 4153 checks
bash scripts/test_dep.sh --wine    # DEP patch
bash scripts/test_x87.sh           # x87sidecar start-up and speed
bash scripts/baseline.sh verify    # game folder unchanged
```

## References

- [Whisky Issue #537](https://github.com/Whisky-App/Whisky/issues/537) - WoW crashes on Apple Silicon
- [Wine Bug 56441](https://bugs.winehq.org/show_bug.cgi?id=56441) - FNDISI patch precedent
- [x87sidecar](https://github.com/athei/x87sidecar) - x87 acceleration for Rosetta 2 (MIT), shipped in the engine
- [athei/wine](https://github.com/athei/wine) - source of the DEP and x87sidecar ntdll patches we ported
- [mtld3d](https://github.com/athei/mtld3d) - Direct3D 9 on Metal (Zlib), shipped in the engine; we build it without the import-table hooks its release installs (`scripts/build_mtld3d.sh`, `patches/mtld3d/`)
- [Endfield_FineWine](https://github.com/stoicswe/Endfield_FineWine) - CrossOver patching example

## License

TBD. The engine includes x87sidecar under its MIT license (`share/doc/x87sidecar/LICENSE`), mtld3d under its Zlib license (`share/doc/mtld3d/LICENSE`) and Wine (LGPL 2.1).

## Disclaimer

This project is not affiliated with Blizzard Entertainment, any private server, or CodeWeavers. Use at your own risk.
