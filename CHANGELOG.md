# Changelog

All notable changes to MoBetta, newest first. Dates are YYYY-MM-DD.

## 2026-11-19 - x87 precision note

### Documentation
- **x87sidecar does x87 math in 64-bit doubles, not the x87's 80-bit format.** This is how x87sidecar is designed (its README: "The sidecar does x87 arithmetic in binary64"), and it is true of every MoBetta release since v1.0.0. At the 53-bit precision Windows programs run at, results match real hardware as long as values stay inside the double range. They differ when a program sets 24-bit or 64-bit precision, when a value goes beyond the double range in the middle of a calculation (`1e308 * 10 / 10` gives infinity, real x87 gives 1e308), and for `fsin`/`fcos` of very large arguments (`fsin` of 1e22 gives -4.24e79). Stock Rosetta gets all of these right. `tests/x87_precision_probe.c` prints 15 such cases; run it under Wine with and without x87sidecar (`ROSETTA_X87_PATH=`) to compare. WoW 3.3.5a has shown no problem from it. Earlier entries said results were "bit-identical to Rosetta's own": that holds for x87sidecar's test suite and our test programs, not for every x87 program, and those entries now say so. No engine change

## 2026-11-19 - Longer x87 sequences in Dalaran (v1.0.6)

### Changed
- **Ships the x87sidecar change from the entry below** (patch 0005): x87 sequences now continue across up to 12 ordinary instructions in a row and across byte and 16-bit loads from memory. At the Dalaran fountain on a MacBook M3, a solid 45-65 FPS with a low of 35 in crowded spots (v1.0.5: 50-60 holding at 50, in an earlier sitting; how many players are around changes it from one sitting to the next), and it feels smoother. Nothing else changed from v1.0.5. Engine SHA-256 `3cfda1b14924489d60a4eea70110155c376cc4fcc22898c34f5ede8e10ddd65a`

## 2026-11-19 - Longer gaps and byte loads inside x87 sequences (x87sidecar patch 0005)

### Changed
- **x87sidecar now keeps an x87 sequence going across longer stretches of ordinary instructions, and across loading a byte or 16-bit value from memory** (`patches/x87sidecar/0005`). Up to 12 ordinary instructions in a row (was 4), 24 per sequence (was 16), and `movzx`/`movsx` from 8- or 16-bit memory, which used to end the sequence. WoW's hottest x87 function in Dalaran (`0x97c001`) copies a 3-float vector from a global between its x87 instructions, 8-10 plain moves that every earlier version split the sequence at. In a recorded Dalaran profile this takes the x87 cost from 19.51 to 18.82 ARM instructions per x87 instruction (-3.5%), and the copy of the `0x7f9480` function runs 305 -> 273 ms under Wine. At the Dalaran fountain on a MacBook M3, a solid 45-65 FPS, with a low of 35 in crowded spots, and it feels smoother (how many players are around changes it from one sitting to the next). `X87_BRIDGE_MAX_GAP=4 X87_BRIDGE_MAX_TOTAL=16` gives the old limits. Results match x87sidecar's from before the change, and its test suite, which checks results against stock Rosetta, passes (1486 tests), including a new test of the byte and 16-bit loads and a 10-instruction gap. Released in v1.0.6

## 2026-11-19 - Faster Dalaran and a shader cache (v1.0.5)

### Changed
- **Ships the x87sidecar changes from the entries below** (patches 0002, 0003 and 0004): longer x87 sequences, joined in WoW's hottest x87 function, with values kept in 64-bit form between them. At the Dalaran fountain on a MacBook M3, 50-60 FPS holding at 50, against 40-50 on v1.0.4 (how many players are around changes it from one sitting to the next)

### Added
- **mtld3d's shader cache is on, kept outside the game folder** (`patches/mtld3d/0004`, `d3d9.dll`). mtld3d saves the shaders and render pipelines the game has used, and builds them again while the game loads, so they are ready before the first frame. Upstream keeps that file next to `Wow.exe`, in the game folder, which is why MoBetta had it off. It now lives in the Wine prefix at `AppData\Local\mtld3d-cache\Wow\mtld3d_shaders.bin`, next to mtld3d's logs. Without the cache, arriving in Dalaran compiled 170 shaders while playing, in bursts of up to 83 shaders at once. On the next launch with the cache, 170 shaders and 355 pipelines were rebuilt in 0.25 s at startup, and only 33 new shaders were compiled in town. Arriving in Dalaran is noticeably smoother. The first visit to a place still compiles as before; each later visit uses the cache. `shaderCache.enable=false` in `MTLD3D_CONFIG` or `mtld3d.conf` turns it off. The game folder baseline check still matches every file. Engine SHA-256 `3a26e3455dd37b99315445333cc446cb03b9fa1b7d6d84aaefd4ddeb4f23008b`

## 2026-11-19 - x87 values kept in 64-bit form between sequences (x87sidecar patch 0004)

### Changed
- **x87sidecar no longer converts every x87 register back to Rosetta's 80-bit format at the end of each x87 sequence** (`patches/x87sidecar/0004`). A value the sequence held as a 64-bit double is now stored in a marked form: the double's bits plus a marker in an 80-bit pattern that real x87 math never produces. Writing it takes 5 ARM instructions instead of a chain of about 15-20, and the next sequence reads it straight back. Because the marker lives in the value itself, any copy Rosetta or Wine makes of the registers keeps it, so no change to Rosetta's own code was needed. Everything in x87sidecar that reads the raw registers decodes the marker, and before Rosetta's own x87 code runs, the sidecar converts all registers back to genuine 80-bit values. `X87_TAGGED_SLOTS=0` turns it off. Results match x87sidecar's from before the change, and its test suite, which checks results against stock Rosetta, passes (1468 tests)
- **Differences from real hardware, only visible to unusual code:** a crash handler or debugger that reads saved x87 registers sees the marked form; a hand-made "pseudo-NaN" 80-bit value loaded from memory becomes the standard x87 NaN. Real x87 math never produces those values, and WoW is not known to rely on either
- **Measured:** a copy of WoW's view-culling loop runs 14% faster (202 to 174 ms) and the copy of the hottest Dalaran function 7% faster (316 to 295 ms). In game at the Dalaran fountain on a MacBook M3: a solid 45-60 FPS depending on how many players are around (40-55 with spikes into the 60s with patch 0003, in an earlier sitting), no problems seen. Released in v1.0.5

## 2026-11-19 - x87 sequences joined in WoW's hottest x87 function (x87sidecar patch 0003)

### Changed
- **x87sidecar now also joins x87 sequences across `add`/`sub`-type instructions in blocks where Rosetta marks no CPU flag as needed** (`patches/x87sidecar/0003`). Before, such a block was skipped in case Rosetta had simply not filled in that information. Tests on Rosetta, in both 64-bit and 32-bit code, show it is exact when Rosetta can see the next block, and marks every flag as needed when it cannot (calls, returns, indirect jumps, very long blocks, page boundaries). So an empty mark means no flag is needed. As a safeguard it is only trusted after Rosetta has filled it in somewhere in the same process; `X87_BRIDGE_ZERO_FL=0` turns it off. This is what kept the hottest x87 function in Dalaran (at 0x7f9480) split into one- and two-instruction pieces. Results match x87sidecar's from before the change, and its test suite, which checks results against stock Rosetta, passes (1468 tests), including a new test that fails if a flag the next block needs is ever dropped
- **Measured:** the copy of that function runs about 34% faster than with patch 0002 (about 512 ms to 339 ms for its test loop), and the game's x87 code in a Dalaran profile gets another 7% shorter. In game at the Dalaran fountain on a MacBook M3: 40-55 FPS with spikes into the 60s (45-50 with 0002, in an earlier sitting), no problems seen. Released in v1.0.5

## 2026-11-19 - Longer x87 sequences (x87sidecar patch 0002)

### Changed
- **x87sidecar now keeps an x87 sequence going across `push`, `pop` and storing a constant to memory** (`patches/x87sidecar/0002`). These ordinary instructions used to end the sequence, so the values went back to Rosetta's 80-bit registers in memory and were reloaded right after. It also allows up to 4 ordinary instructions in a row between x87 instructions (was 2), since that is how WoW's code is laid out. Results match x87sidecar's from before the change: the whole x87sidecar test suite, which checks results against stock Rosetta, passes (1450 tests), and a copy of the hottest function in Dalaran, instruction for instruction, gives the same result bits with and without it
- **Measured:** that copied function runs about 10% faster (about 595 ms to 530 ms for its test loop), and the game's x87 code in a Dalaran profile gets 5.7% shorter. In game at the Dalaran fountain on a MacBook M3: 45-50 FPS with the change, 40-50 without it, in the same sitting. That is a small gain at best, with no problems seen. Released in v1.0.5

## 2026-11-19 - Where Rosetta loses time in Dalaran

### Tested
- **A finer profile of the main thread.** A debug build of x87sidecar recorded which ARM instruction the game's main thread was running, 10,000 times a second for two minutes at the Dalaran fountain, without pausing the game. It also saved the translated code those samples landed in, so every sample maps back to the x86 instruction it came from. No engine change
- **Rosetta translates WoW's ordinary code well.** Common instructions (`mov`, `cmp`, `add`, conditional jumps, `push`) come out at about 1.3-2.4 ARM instructions each, close to the minimum for 32-bit code on a 64-bit CPU. A replacement translator for that code would gain little, so MoBetta will not build one
- **The x87 code costs much more than the earlier entry said.** About 71% of the main thread's time in `Wow.exe` is inside x87 sequences, not 27%. The earlier figure counted the wrong thing: Rosetta reports the x86 position only at the start and end of each sequence. The math itself is cheap. Most of the time goes to moving values between Rosetta's 80-bit x87 registers in memory and the CPU's 64-bit floating-point registers whenever a sequence starts or ends. WoW's sequences are short (about 7 instructions), because ordinary instructions in between (such as `push` or storing a constant) break them up
- **A faster conversion does not help.** Two faster versions of the 80-bit to 64-bit conversion produced identical results on 200 million test values but ran no faster on a copy of WoW's view-culling loop. The time is spent waiting on the round trip through memory, not in the conversion itself
- **What does help is joining the sequences.** x87sidecar can already join sequences across a few kinds of ordinary instructions. Teaching it `push`, `pop` and storing a constant would let the hottest function in Dalaran run as one sequence instead of 13 separate ones. The profile puts the most this could save at about a tenth of the main thread. Only an in-game before-and-after FPS test will show the real number. That is the next step

## 2026-11-18 - Dalaran x87 profile

### Tested
- **How much the x87 code costs in Dalaran.** A second Dalaran run on v1.0.4 (maximized window, 1970x1273, ~40 FPS at the fountain) recorded x87sidecar's own counts for every translated block. 86% of the x87 instructions already take the sidecar's fast path, at about 23 ARM instructions each. The costliest spots are short x87 runs broken up by ordinary instructions, which fall back to translating one instruction at a time: one function alone (`0x7f9480`) is 11% of all x87 cost at about 79 ARM instructions per x87 instruction. Joining those runs more widely would save at most 13-26% of the x87 cost, which is only about 3.5-7% of the main thread, or roughly 1.5-3 FPS at 40. That is less than the earlier entry suggested, so x87 alone will not close the gap
- **No hidden system-call cost.** The earlier profile put 10% of the main thread in the macOS kernel. A call-stack sample of the game puts it at 2-5%, with 94-98% in WoW's own code as translated by Rosetta 2; the rest was an artifact of the profiler. Wine has nothing to give back on that thread. The rest of the thread's time, about three quarters of it, is ordinary integer code that Rosetta translates; the next step is to measure how well it does that on the hottest functions. No engine change

## 2026-11-18 - Dalaran profiled; shader cache measured

### Tested
- **Where the frames go in Dalaran.** On v1.0.4, windowed at 1563x1010 on a MacBook M3, Dalaran runs at 30-40 FPS and Booty Bay at 70-80. A 15-second profile at the Dalaran fountain shows the game limited by its one main thread running WoW's own x86 code under Rosetta 2: about 87% of that thread's time is in `Wow.exe`, and 27% of it sits on x87 floating-point instructions. Wine and mtld3d barely show up on that thread, and the GPU is only 11-15% busy. So a PC running the game natively on x86 has the edge here, and the remaining room on a Mac is mostly in x87sidecar's translation of that x87 code. Next: profile which of those x87 blocks still miss x87sidecar's fast path. No engine change
- **mtld3d shader cache.** The cache stays off because mtld3d writes it next to `Wow.exe`, in the game folder. In quiet zones the game compiles 21-91 shaders per session in 40-143 ms in total, mostly in the background, so a cache would not help there. Arriving in Booty Bay and Dalaran compiled 215 shaders in 1.9 s, some in batches of 100-300 ms that hold up a frame. A cache would remove those hitches on later visits but would not raise average FPS. It needs a patch to move the file out of the game folder, planned for a release that also brings an FPS gain

## 2026-11-18 - HDR retest; false-positive reports sent

### Tested
- **HDR on no longer stalls the game.** Before v1.0.4, turning on HDR in mtld3d gave a black title screen for up to 45 s and a ~20 s freeze on maximize, which is why MoBetta ships with HDR off. The cause was the same one behind the fullscreen stutter fixed in v1.0.4 (`patches/0007`): Wine reloaded its display list every time macOS adjusted the display's brightness headroom. Retested on v1.0.4 with HDR on and auto-brightness on: the title screen came up right away, maximize, minimize and fullscreen worked normally, and Wine's desktop process stayed near idle (0.4% CPU on average) while the headroom rose to 5.4x. No engine change

### Unchanged
- **HDR stays off by default.** WoW 3.3.5a has no HDR content, so colours look the same either way, and the standard 8-bit output uses half the graphics bandwidth. Anyone who wants it on can set `color.hdr.enable=true` in `MTLD3D_CONFIG` or `mtld3d.conf`, without the old stall

### Security
- **False-positive reports sent** to Microsoft, Cynet and K7 for the one-engine VirusTotal flags in [`docs/SECURITY_SCANS.md`](docs/SECURITY_SCANS.md). Each flag is a machine-learning or generic verdict. Three different patched files are flagged by Microsoft alone, and they share no technique, so the model most likely reacts to a modified low-level system library rather than to any particular change. Results will be posted on that page when the vendors answer

## 2026-11-18 - Malware scan results

### Added
- **`docs/SECURITY_SCANS.md`**: ClamAV and VirusTotal results for the v1.0.4 release, the eight engine files MoBetta changes or adds, and the source, with each file's SHA-256, a link to its live VirusTotal report and a screenshot (`docs/screenshots/scans/`). ClamAV finds nothing. On VirusTotal four engine files and the release archive are flagged by one engine each (machine-learning or generic verdicts); the stock Porting Kit files and an unpatched build are clean. Reports to the vendors are pending

## 2026-11-18 - Fullscreen fix (v1.0.4)

### Fixed
- **Fullscreen no longer stutters** (`patches/0007`, `winemac.so`). With auto-brightness on, a Mac's built-in XDR display keeps adjusting its brightness headroom, most of all with a fullscreen window up, and macOS reports each step as a display change. Wine rebuilt its whole display list every time, keeping one of its processes at a full CPU core and stalling the game's threads. The stutter started some seconds after going fullscreen and stayed after going back to windowed. Wine now ignores these reports when nothing it uses from the displays changed; plugging in a display or changing the resolution still goes through
- **Camera turning stays smooth after fullscreen** (`patches/0008`, `winemac.so`). In fullscreen WoW confines the cursor to its display and keeps that after going back to windowed, which switched the v1.0.3 mouse-look fix off for the rest of the session. Mouse-look now stays on while the confinement holds the whole game window. Engine SHA-256 `2554e0a29294dc5821dd3091c86b67607f78f506ef04988249a389554a2d17b0`

## 2026-11-18 - Mouse-look fix (v1.0.3)

### Fixed
- **Mouse-look keeps the cursor inside the game window** (`patches/0006`, Wine's Mac display driver `winemac.so`). While you hold a mouse button to turn the camera, WoW hides the cursor and moves it back to the window's centre every frame. On a second display, that point could fall outside the window, so the hidden cursor sat over other apps and the frame rate dropped while dragging. The stock driver also showed an arrow where WoW asks for no cursor. Now the Mac cursor stays inside the window during mouse-look and the camera turns from relative mouse movement. Tested on a MacBook's built-in display and an external one. Engine SHA-256 `768d4a1ad254d9bae9155d33c4dc6b4f2add51adfdaa93a94956589698a32dda`

### Known issue
- **Fullscreen stutters.** The stock driver stutters in fullscreen too, worse than this one. Play windowed until this is fixed

## 2026-11-18 - Faster x87 math (v1.0.2)

### Changed
- **Up to ~15% more FPS where WoW does heavy x87 math** (`patches/x87sidecar/0001`). At ultra, WoW's main thread spends about 75% of its time in old x87 floating-point code, which Rosetta 2 hands to x87sidecar. Its hottest loop (box vs view frustum, `0x9839e0`) had integer shifts between x87 instructions, which broke x87sidecar's fast path into single slow steps. x87sidecar now carries an x87 run across `shl`/`shr`/`sar` by a constant when the flags are not used afterwards: that loop goes from 586 to 124 ARM instructions and runs 4.9x faster in a standalone test (`tests/x87_bridge_shift.c`), with the same result bits as without the change. In game on a MacBook M3 at ultra, back to back on the same spot: 100-115 -> 120-130 FPS at an inn, 110-120 -> 120-130 outside. Engine SHA-256 `034eea94f365a98d7b984e2c58bfca0fef811e3352ca83d1192ec3cb70a924d8`

### Fixed
- **Updating instructions** in the README and the Porting Kit guide: after replacing the engine file, select `WS12WineCX26.3_Mobetta` again in Change Engine Used, even though it already shows as the current engine

## 2026-11-18 - Short resolution list, rebuilt with the current Apple compiler

### Fixed
- **WoW's resolution list no longer runs off the screen** (`patches/0005`). macOS reports every scaled and native mode of a Mac display: 300 sizes on a 14" MacBook Pro, up to its native 3456x2234. Wine handed all of them to the game, and the Video settings dropdown overflowed. Wine's `user32.dll` now lists only sizes that fit on the desktop, match its shape, are at least 800 wide and that Wine can switch to in fullscreen, about one per 10% step: 6 sizes on that MacBook. Switching modes works as before; only the list is shorter. The engine now also replaces `lib/wine/i386-windows/user32.dll` (`scripts/build_user32.sh`)

### Changed
- **Pinned to Apple clang 2100.4.1.1** (macOS 27.2 Command Line Tools). The new compiler builds `ntdll.so`, `opengl32.so`, `x87sidecar` and `mtld3d.so` from the same sources to different bytes, so the reproducible build is pinned to it. Same frame rate as before. Engine SHA-256 `d683f50966e7dd4ef10b95a1db3774b695692d6993e9465307877afac269f4b5`

## 2026-10-28 - In-game FPS screenshots

### Added
- **Performance section in the README** with eight in-game screenshots and an FPS table, on the v1.0.0 engine on a MacBook M3 at medium-high settings: 191 FPS at the Ironforge gate, 155 in Stormwind, 138 in Orgrimmar, down to 97 in Booty Bay in the rain and 86 in Shattrath. Images are in `docs/screenshots/`, with chat and character names blurred
- **Other games** in the README's Requirements: nothing in the engine is WoW-specific, but only 3.3.5a has been tested
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
