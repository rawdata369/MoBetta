# Malware scans

Scans of the current release, every engine file MoBetta changes or adds, and the source. Every file is listed by its SHA-256. You can check any hash yourself on [VirusTotal](https://www.virustotal.com) or with `shasum -a 256`.

## v1.0.7 (current release)

Each file's most recent scan. Every file changed since v1.0.4 was scanned again on its release, and every file still flagged was uploaded again after the vendors' answers (latest 2026-11-23).

- **ClamAV:** nothing found in the release archive (fully unpacked), the 4,625 files of the unpacked engine, or the source.
- **VirusTotal:** the source and every engine file MoBetta changes or adds: 0 detections, except `user32.dll`, flagged by **Cynet** alone (1 / 69). The release archive is flagged by Cynet alone (1 / 44). Cynet's verdict is a bare score with no named threat. We believe it is a false positive and have reported it (see [Vendor answers](#vendor-answers)).
- **Earlier flags, now gone:** K7AntiVirus, Avast, AVG and Avira on the release archive, and Microsoft on `ntdll.so`, `opengl32.so` and `winemac.so`. K7 and Gen Digital (Avast, AVG, Avira) confirmed false positives.

Everything MoBetta changes is in [`patches/`](../patches) as readable source, and [`scripts/build_engine.sh`](../scripts/build_engine.sh) rebuilds the engine to the same bytes (the release's SHA-256 is in [`SHA256SUMS`](../SHA256SUMS)).

### VirusTotal

Detections / engines that returned a verdict, with the scan date. Click a file for its live report, or a result for the screenshot taken on the scan date.

| File | Built from | SHA-256 | Result |
|---|---|---|---|
| [`WS12WineCX26.3_Mobetta.tar.7z`](https://www.virustotal.com/gui/file/c9d298230642a6b045526251e12a24e4eb8a8709e16db3d72a2ec3d165b0d409) | the v1.0.7 release | `c9d298230642a6b045526251e12a24e4eb8a8709e16db3d72a2ec3d165b0d409` | [1 / 44](screenshots/scans/vt-ws12winecx26-3-mobetta-v1-0-7-2026-11-23.png) (Cynet), 2026-11-23 |
| [Source at tag v1.0.7](https://www.virustotal.com/gui/file/b0da59d074caf126011c5048bbfe52ecc68d9e74792aacd473533a10f78b6b7e) | `git archive --format=zip --prefix=MoBetta-v1.0.7/ v1.0.7` | `b0da59d074caf126011c5048bbfe52ecc68d9e74792aacd473533a10f78b6b7e` | [0 / 65](screenshots/scans/vt-mobetta-v1-0-7-source-zip.png), 2026-11-20 |
| [`lib/wine/x86_64-unix/ntdll.so`](https://www.virustotal.com/gui/file/91ecefb778c17bfb7d157093c7c4e4ffc6a0e2ba271b63223a84c5ad9995cedf) | Wine + `patches/0001-0003` | `91ecefb778c17bfb7d157093c7c4e4ffc6a0e2ba271b63223a84c5ad9995cedf` | [0 / 63](screenshots/scans/vt-ntdll-so-2026-11-23.png), 2026-11-23 |
| [`lib/wine/x86_64-unix/opengl32.so`](https://www.virustotal.com/gui/file/4d0178eae748a61c61d89c3db67eda31aaf38d7417bcd7fcbf81af71ebf35428) | Wine + `patches/0004` | `4d0178eae748a61c61d89c3db67eda31aaf38d7417bcd7fcbf81af71ebf35428` | [0 / 62](screenshots/scans/vt-opengl32-so-2026-11-22.png), 2026-11-22 |
| [`lib/wine/x86_64-unix/winemac.so`](https://www.virustotal.com/gui/file/5f3ec04fb74704a00101fa349857f73ea1593c4a05d57b3cd5fc687537f1f9bc) | Wine + `patches/0006-0008` | `5f3ec04fb74704a00101fa349857f73ea1593c4a05d57b3cd5fc687537f1f9bc` | [0 / 63](screenshots/scans/vt-winemac-so-2026-11-22.png), 2026-11-22 |
| [`lib/wine/i386-windows/user32.dll`](https://www.virustotal.com/gui/file/92ba32e4331788582cda984f654446400be7a8b663ff2ba88c4e84c9096084fa) | Wine + `patches/0005` | `92ba32e4331788582cda984f654446400be7a8b663ff2ba88c4e84c9096084fa` | [1 / 69](screenshots/scans/vt-user32-dll-2026-11-23.png) (Cynet), 2026-11-23 |
| [`bin/x87sidecar`](https://www.virustotal.com/gui/file/fef5b07ae2ee9e3d8e26baf756eb747dc7f21328b6befa752844a13367dfa25c) | x87sidecar + `patches/x87sidecar/0001-0006` | `fef5b07ae2ee9e3d8e26baf756eb747dc7f21328b6befa752844a13367dfa25c` | [0 / 63](screenshots/scans/vt-x87sidecar-v1-0-7.png), 2026-11-20 |
| [`lib/wine/i386-windows/d3d9.dll`](https://www.virustotal.com/gui/file/0d5e411b5a6e8dc2df36c22fcdef54970ae052dfefbbbbfdc7695aa519762cde) | mtld3d + `patches/mtld3d/` | `0d5e411b5a6e8dc2df36c22fcdef54970ae052dfefbbbbfdc7695aa519762cde` | [0 / 70](screenshots/scans/vt-d3d9-dll-v1-0-5.png), 2026-11-20 |
| [`lib/wine/i386-windows/mtld3d.dll`](https://www.virustotal.com/gui/file/841a81e22abe1160ccbf5e9aab4259acec6feb2ed6ee3d36a976e4106d960de8) | mtld3d + `patches/mtld3d/` | `841a81e22abe1160ccbf5e9aab4259acec6feb2ed6ee3d36a976e4106d960de8` | [0 / 71](screenshots/scans/vt-mtld3d-dll.png), 2026-11-18 |
| [`lib/wine/x86_64-unix/mtld3d.so`](https://www.virustotal.com/gui/file/d881c4529a2fafaa3464be2f79d2f9b70317518df3fcf99243bb4fb6b75e6746) | mtld3d + `patches/mtld3d/` | `d881c4529a2fafaa3464be2f79d2f9b70317518df3fcf99243bb4fb6b75e6746` | [0 / 62](screenshots/scans/vt-mtld3d-so.png), 2026-11-18 |

What the changed code does: emulate x86 instructions Rosetta 2 rejects (ntdll), keep no-exec memory on and start the x87 helper (ntdll), run x87 math in the helper (x87sidecar), reuse a buffer mapping (opengl32), shorten the resolution list (user32), fix mouse-look and fullscreen in the Mac display driver (winemac), and cache compiled shaders (mtld3d). Nothing is injected into the game and no game file is changed. See the [README](../README.md) and [CHANGELOG](../CHANGELOG.md).

### Vendor answers

| Vendor | Report | Answer |
|---|---|---|
| Cynet | email, 2026-11-18 (`user32.dll`) and 2026-11-22 (release archive) | No answer yet. Both still flagged on 2026-11-23 |
| Avast/AVG | email, 2026-11-22 (release archive) | 2026-11-22, Gen Digital Threat Ops: "The detection has been disabled." Confirmed on VirusTotal 2026-11-23 |
| Avira | analysis submission (release URL), 2026-11-22 | No answer. Clean on VirusTotal since 2026-11-23 (Avira is part of Gen Digital, which answered the Avast/AVG report) |
| K7AntiVirus | email, 2026-11-18 (release archive) | 2026-11-20: "Reported FP is fixed." Confirmed on VirusTotal 2026-11-22 |
| Microsoft | Defender file submission, 2026-11-18 (`ntdll.so`, `opengl32.so`, `winemac.so`) | No answer. All three clean on VirusTotal: `opengl32.so` and `winemac.so` since 2026-11-22, `ntdll.so` since 2026-11-23 |

### ClamAV

ClamAV 1.5.4, signatures daily 28189, main 63, bytecode 339 (3,628,278 signatures), updated 2026-11-20.

| Target | Scanned | Infected |
|---|---|---|
| `WS12WineCX26.3_Mobetta.tar.7z` (v1.0.7, unpacked by ClamAV, no time limit) | the full archive | 0 |
| The same engine unpacked (`wswine.bundle`) | 4,625 files, 1.16 GiB | 0 |
| Source (`git archive` zip at tag v1.0.7) | 1 zip | 0 |

To repeat it (Homebrew):

```bash
brew install clamav
cp /opt/homebrew/etc/clamav/freshclam.conf.sample /opt/homebrew/etc/clamav/freshclam.conf
sed -i '' 's/^Example/#Example/' /opt/homebrew/etc/clamav/freshclam.conf
freshclam
clamscan --max-filesize=2000M --max-scansize=4000M --max-scantime=0 WS12WineCX26.3_Mobetta.tar.7z
```
