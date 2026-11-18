# Malware scans

Scans of the v1.0.4 release, the files MoBetta changes in the engine, and the source. Scanned 2026-11-18. Every file is listed by its SHA-256. You can check any hash yourself on [VirusTotal](https://www.virustotal.com) or with `shasum -a 256`.

## Summary

- **ClamAV:** nothing found in the release archive (fully unpacked), the 4,625 files of the unpacked engine, or the source.
- **VirusTotal:** the source and five of the eight changed engine files: 0 detections. Four engine files and the release archive: flagged by **one** engine each, out of 42-71. Each flag is a single vendor's heuristic or machine-learning verdict; no other engine agrees with any of them. We believe these are false positives; false-positive reports went to all three vendors on 2026-11-18, and this page will be updated with their answers (see [Flags](#flags)).
- **Controls:** the stock, unmodified files from Porting Kit's `WS12WineCX26.3_DXMT` engine, and our own build of `winemac.so` without MoBetta's patches, are 0 detections.

Everything MoBetta changes is in [`patches/`](../patches) as readable source, and [`scripts/build_engine.sh`](../scripts/build_engine.sh) rebuilds the engine to the same bytes (the release's SHA-256 is in [`SHA256SUMS`](../SHA256SUMS)).

## VirusTotal

Detections / engines that returned a verdict. Click a file for its live report, or a result for the screenshot taken on the scan date.

### Release and source

| File | SHA-256 | Result |
|---|---|---|
| [`WS12WineCX26.3_Mobetta.tar.7z`](https://www.virustotal.com/gui/file/2554e0a29294dc5821dd3091c86b67607f78f506ef04988249a389554a2d17b0) (v1.0.4 release) | `2554e0a29294dc5821dd3091c86b67607f78f506ef04988249a389554a2d17b0` | [1 / 42](screenshots/scans/vt-ws12winecx26-3-mobetta.png) (K7AntiVirus). 15 engines timed out on the 184 MB archive, 13 don't read 7z |
| [Source at tag v1.0.4](https://www.virustotal.com/gui/file/cb0066de9a606de0a707273809cbe33cec0a848401bc11bf23f4de105589b208) (`git archive --format=zip --prefix=MoBetta-v1.0.4/ v1.0.4`) | `cb0066de9a606de0a707273809cbe33cec0a848401bc11bf23f4de105589b208` | [0 / 59](screenshots/scans/vt-mobetta-v1-0-4-source-zip.png) |

### Engine files MoBetta changes or adds

| File | Built from | SHA-256 | Result |
|---|---|---|---|
| [`lib/wine/x86_64-unix/ntdll.so`](https://www.virustotal.com/gui/file/91ecefb778c17bfb7d157093c7c4e4ffc6a0e2ba271b63223a84c5ad9995cedf) | Wine + `patches/0001-0003` | `91ecefb778c17bfb7d157093c7c4e4ffc6a0e2ba271b63223a84c5ad9995cedf` | [1 / 63](screenshots/scans/vt-ntdll-so.png) (Microsoft) |
| [`lib/wine/x86_64-unix/opengl32.so`](https://www.virustotal.com/gui/file/4d0178eae748a61c61d89c3db67eda31aaf38d7417bcd7fcbf81af71ebf35428) | Wine + `patches/0004` | `4d0178eae748a61c61d89c3db67eda31aaf38d7417bcd7fcbf81af71ebf35428` | [1 / 63](screenshots/scans/vt-opengl32-so.png) (Microsoft) |
| [`lib/wine/x86_64-unix/winemac.so`](https://www.virustotal.com/gui/file/5f3ec04fb74704a00101fa349857f73ea1593c4a05d57b3cd5fc687537f1f9bc) | Wine + `patches/0006-0008` | `5f3ec04fb74704a00101fa349857f73ea1593c4a05d57b3cd5fc687537f1f9bc` | [1 / 56](screenshots/scans/vt-winemac-so.png) (Microsoft) |
| [`lib/wine/i386-windows/user32.dll`](https://www.virustotal.com/gui/file/92ba32e4331788582cda984f654446400be7a8b663ff2ba88c4e84c9096084fa) | Wine + `patches/0005` | `92ba32e4331788582cda984f654446400be7a8b663ff2ba88c4e84c9096084fa` | [1 / 71](screenshots/scans/vt-user32-dll.png) (Cynet) |
| [`bin/x87sidecar`](https://www.virustotal.com/gui/file/6a37a6937f6b562d376a7009460a1ba276236a72ec2d4278401eb708e796830b) | x87sidecar + `patches/x87sidecar/0001` | `6a37a6937f6b562d376a7009460a1ba276236a72ec2d4278401eb708e796830b` | [0 / 63](screenshots/scans/vt-x87sidecar.png) |
| [`lib/wine/i386-windows/d3d9.dll`](https://www.virustotal.com/gui/file/1193bd7f14bd632fa4ef907b59c652dc89e9aaab50bf1d5502dc6777b3abf9d4) | mtld3d + `patches/mtld3d/` | `1193bd7f14bd632fa4ef907b59c652dc89e9aaab50bf1d5502dc6777b3abf9d4` | [0 / 71](screenshots/scans/vt-d3d9-dll.png) |
| [`lib/wine/i386-windows/mtld3d.dll`](https://www.virustotal.com/gui/file/841a81e22abe1160ccbf5e9aab4259acec6feb2ed6ee3d36a976e4106d960de8) | mtld3d + `patches/mtld3d/` | `841a81e22abe1160ccbf5e9aab4259acec6feb2ed6ee3d36a976e4106d960de8` | [0 / 71](screenshots/scans/vt-mtld3d-dll.png) |
| [`lib/wine/x86_64-unix/mtld3d.so`](https://www.virustotal.com/gui/file/d881c4529a2fafaa3464be2f79d2f9b70317518df3fcf99243bb4fb6b75e6746) | mtld3d + `patches/mtld3d/` | `d881c4529a2fafaa3464be2f79d2f9b70317518df3fcf99243bb4fb6b75e6746` | [0 / 62](screenshots/scans/vt-mtld3d-so.png) |

### Controls

| File | What it is | SHA-256 | Result |
|---|---|---|---|
| [`WS12WineCX26.3_DXMT.tar.7z`](https://www.virustotal.com/gui/file/7b3f383a2209de5765eef45f1d6fc316682cfcfbb3518d7470e4b51f00e7cd08) | Porting Kit's stock engine, the base of MoBetta | `7b3f383a2209de5765eef45f1d6fc316682cfcfbb3518d7470e4b51f00e7cd08` | [0 / 45](screenshots/scans/vt-stock-ws12winecx26-3-dxmt.png) |
| [`ntdll.so`](https://www.virustotal.com/gui/file/f4a653b12f142fe601253d764288260ce63e0620ca092dfb99ef8ffc41aad677) | stock, from that engine | `f4a653b12f142fe601253d764288260ce63e0620ca092dfb99ef8ffc41aad677` | [0 / 60](screenshots/scans/vt-stock-ntdll-so-cx26-3.png) |
| [`opengl32.so`](https://www.virustotal.com/gui/file/4571b05c840e7d0f49d87b11eeba2ce08391af713bcf689a19f6af25fac45c3a) | stock, from that engine | `4571b05c840e7d0f49d87b11eeba2ce08391af713bcf689a19f6af25fac45c3a` | [0 / 63](screenshots/scans/vt-stock-opengl32-so-cx26-3.png) |
| [`winemac.so`](https://www.virustotal.com/gui/file/2e9d3f8cbf9842a6286a5605c0f2077a32043550ab1b5040af62ff53f0f95c56) | stock, from that engine | `2e9d3f8cbf9842a6286a5605c0f2077a32043550ab1b5040af62ff53f0f95c56` | [0 / 63](screenshots/scans/vt-stock-winemac-so-v1-0-2.png) |
| [`winemac.so`](https://www.virustotal.com/gui/file/d9b0b757dde13ede7deded8b25c37fec28a1ff123356e60b6c68bba618fff76d) | our build, same toolchain, no MoBetta patches | `d9b0b757dde13ede7deded8b25c37fec28a1ff123356e60b6c68bba618fff76d` | [0 / 63](screenshots/scans/vt-control-winemac-so-unpatched.png) |

## Flags

| File | Engine | Label | What it is |
|---|---|---|---|
| `ntdll.so`, `opengl32.so`, `winemac.so` | Microsoft | `Trojan:Script/Wacatac.C!ml` | `!ml` marks a machine-learning verdict, not a signature match. "Wacatac" is Microsoft's catch-all name for such verdicts. The label says "Script", but these are native macOS libraries. The stock files and our unpatched `winemac.so` are clean, so the model reacts to the patched code; the patches are in `patches/` |
| `user32.dll` | Cynet | `Malicious (score: 100)` | Cynet's score is a heuristic/ML verdict. 70 other engines, including Microsoft, find nothing. Patch 0005 only shortens the display-mode list WoW sees |
| `WS12WineCX26.3_Mobetta.tar.7z` | K7AntiVirus | `Trojan ( 006e46631 )` | A generic label on the archive. No engine flags the same file inside it, and ClamAV found nothing in any of its files |

Reports sent 2026-11-18: Microsoft (Defender file submission, analysis pending), Cynet and K7 (by email to their false-positive contacts listed by VirusTotal). Each file will be rescanned on VirusTotal after they answer.

What the changed code does: emulate x86 instructions Rosetta 2 rejects (ntdll), keep no-exec memory on and start the x87 helper (ntdll), reuse a buffer mapping (opengl32), shorten the resolution list (user32), and fix mouse-look and fullscreen in the Mac display driver (winemac). Nothing is injected into the game and no game file is changed. See the [README](../README.md) and [CHANGELOG](../CHANGELOG.md).

## ClamAV

ClamAV 1.5.4, signatures daily 28187, main 63, bytecode 339 (3,628,278 signatures), updated 2026-11-18.

| Target | Scanned | Infected |
|---|---|---|
| `WS12WineCX26.3_Mobetta.tar.7z` (v1.0.4, unpacked by ClamAV, no time limit) | 184 MiB read, 2.40 GiB scanned | 0 |
| The same engine unpacked (`wswine.bundle`) | 4,625 files, 1.16 GiB | 0 |
| Source (`git archive` of the repo, `patches/`, `scripts/`) | 21 files | 0 |

To repeat it (Homebrew):

```bash
brew install clamav
cp /opt/homebrew/etc/clamav/freshclam.conf.sample /opt/homebrew/etc/clamav/freshclam.conf
sed -i '' 's/^Example/#Example/' /opt/homebrew/etc/clamav/freshclam.conf
freshclam
clamscan --max-filesize=2000M --max-scansize=4000M --max-scantime=0 WS12WineCX26.3_Mobetta.tar.7z
```
