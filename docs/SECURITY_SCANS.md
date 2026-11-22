# Malware scans

Scans of each release, the files MoBetta changes in the engine, and the source. Every file is listed by its SHA-256. You can check any hash yourself on [VirusTotal](https://www.virustotal.com) or with `shasum -a 256`.

- [Rescan 2026-11-22](#rescan-2026-11-22): every file flagged before, scanned again; vendor answers
- [v1.0.5 - v1.0.7](#v105---v107) (scanned 2026-11-20): only the files that changed since v1.0.4
- [v1.0.4](#v104) (scanned 2026-11-18): the full set, with controls

## Rescan 2026-11-22

Every file that was flagged before was uploaded to VirusTotal again on 2026-11-22 (06:01-06:05 UTC) for a fresh analysis. The v1.0.6 archive shows its 2026-11-21 analysis. K7 [confirmed by email on 2026-11-20](#vendor-answers) that its archive detection is fixed.

- **Cleared:** K7 on every release archive; Microsoft on `opengl32.so` and `winemac.so`.
- **Still flagged:** `ntdll.so` by Microsoft (now `Trojan:Script/Wacatac.B!ml`, still a machine-learning verdict); `user32.dll` by Cynet.
- **New:** the v1.0.4 and v1.0.7 release archives are flagged by **Avast, AVG** (`Other:Malware-gen [Trj]`; Avast and AVG share one engine) and **Avira** (`TR/Malware`), and v1.0.4 also by Cynet (`Malicious (score: 99)`; Cynet flagged v1.0.7 on an analysis earlier that day and returned "type unsupported" on the fresh one). These are generic labels on the 184 MB archive. The v1.0.5 and v1.0.6 archives, which contain all but four of the same files, are clean on all four engines, no file inside any archive is flagged by them, and ClamAV found nothing in any file. We believe these are false positives and are reporting them (see [Vendor answers](#vendor-answers)).

| File | SHA-256 | Result (2026-11-22) |
|---|---|---|
| [`WS12WineCX26.3_Mobetta.tar.7z`](https://www.virustotal.com/gui/file/c9d298230642a6b045526251e12a24e4eb8a8709e16db3d72a2ec3d165b0d409) (v1.0.7 release) | `c9d298230642a6b045526251e12a24e4eb8a8709e16db3d72a2ec3d165b0d409` | [3 / 43](screenshots/scans/vt-ws12winecx26-3-mobetta-v1-0-7-2026-11-22.png) (Avast, AVG, Avira). K7 clean |
| [`WS12WineCX26.3_Mobetta.tar.7z`](https://www.virustotal.com/gui/file/3cfda1b14924489d60a4eea70110155c376cc4fcc22898c34f5ede8e10ddd65a) (v1.0.6 release) | `3cfda1b14924489d60a4eea70110155c376cc4fcc22898c34f5ede8e10ddd65a` | [0 / 44](screenshots/scans/vt-ws12winecx26-3-mobetta-v1-0-6-2026-11-22.png) (analysis of 2026-11-21). K7 clean |
| [`WS12WineCX26.3_Mobetta.tar.7z`](https://www.virustotal.com/gui/file/3a26e3455dd37b99315445333cc446cb03b9fa1b7d6d84aaefd4ddeb4f23008b) (v1.0.5 release) | `3a26e3455dd37b99315445333cc446cb03b9fa1b7d6d84aaefd4ddeb4f23008b` | [0 / 41](screenshots/scans/vt-ws12winecx26-3-mobetta-v1-0-5-2026-11-22.png). K7 clean |
| [`WS12WineCX26.3_Mobetta.tar.7z`](https://www.virustotal.com/gui/file/2554e0a29294dc5821dd3091c86b67607f78f506ef04988249a389554a2d17b0) (v1.0.4 release) | `2554e0a29294dc5821dd3091c86b67607f78f506ef04988249a389554a2d17b0` | [4 / 43](screenshots/scans/vt-ws12winecx26-3-mobetta-v1-0-4-2026-11-22.png) (Avast, AVG, Avira, Cynet). K7 clean |
| [`lib/wine/x86_64-unix/ntdll.so`](https://www.virustotal.com/gui/file/91ecefb778c17bfb7d157093c7c4e4ffc6a0e2ba271b63223a84c5ad9995cedf) (v1.0.4-v1.0.7) | `91ecefb778c17bfb7d157093c7c4e4ffc6a0e2ba271b63223a84c5ad9995cedf` | [1 / 63](screenshots/scans/vt-ntdll-so-2026-11-22.png) (Microsoft) |
| [`lib/wine/x86_64-unix/opengl32.so`](https://www.virustotal.com/gui/file/4d0178eae748a61c61d89c3db67eda31aaf38d7417bcd7fcbf81af71ebf35428) (v1.0.4-v1.0.7) | `4d0178eae748a61c61d89c3db67eda31aaf38d7417bcd7fcbf81af71ebf35428` | [0 / 62](screenshots/scans/vt-opengl32-so-2026-11-22.png) |
| [`lib/wine/x86_64-unix/winemac.so`](https://www.virustotal.com/gui/file/5f3ec04fb74704a00101fa349857f73ea1593c4a05d57b3cd5fc687537f1f9bc) (v1.0.4-v1.0.7) | `5f3ec04fb74704a00101fa349857f73ea1593c4a05d57b3cd5fc687537f1f9bc` | [0 / 63](screenshots/scans/vt-winemac-so-2026-11-22.png) |
| [`lib/wine/i386-windows/user32.dll`](https://www.virustotal.com/gui/file/92ba32e4331788582cda984f654446400be7a8b663ff2ba88c4e84c9096084fa) (v1.0.4-v1.0.7) | `92ba32e4331788582cda984f654446400be7a8b663ff2ba88c4e84c9096084fa` | [1 / 71](screenshots/scans/vt-user32-dll-2026-11-22.png) (Cynet) |

### Vendor answers

| Vendor | Report | Answer |
|---|---|---|
| K7AntiVirus | email, 2026-11-18 (v1.0.4 archive) | 2026-11-20: "Reported FP is fixed." Confirmed on VirusTotal 2026-11-22: K7 clean on all four release archives |
| Microsoft | Defender file submission, 2026-11-18 (`ntdll.so`, `opengl32.so`, `winemac.so`) | No answer yet. `opengl32.so` and `winemac.so` are clean on VirusTotal; `ntdll.so` is still flagged |
| Cynet | email, 2026-11-18 (`user32.dll`) | No answer yet |
| Avast/AVG, Avira, Cynet | v1.0.4 and v1.0.7 archives | Reports being sent 2026-11-22 |

## v1.0.5 - v1.0.7

Scanned 2026-11-20. Each release archive was unpacked and hashed file by file against the one before it. Only four engine files changed after v1.0.4: `d3d9.dll` (v1.0.5, shader cache) and `bin/x87sidecar` (v1.0.5, v1.0.6, v1.0.7). The other 4,621 files have the same SHA-256 as in v1.0.4 and are covered by the [v1.0.4 scans](#v104).

- **ClamAV:** nothing found in the three release archives (fully unpacked), the 4,625 files of the unpacked v1.0.7 engine, or the source at each tag.
- **VirusTotal:** every changed engine file and every source zip: 0 detections. Each release archive: flagged by **K7AntiVirus** alone, with the same generic label as v1.0.4 (`Trojan ( 006e46631 )`), out of 39-44. No engine flags any file inside the archives. K7 has since fixed this detection (see [Rescan 2026-11-22](#rescan-2026-11-22)).

| File | SHA-256 | Result |
|---|---|---|
| [`WS12WineCX26.3_Mobetta.tar.7z`](https://www.virustotal.com/gui/file/c9d298230642a6b045526251e12a24e4eb8a8709e16db3d72a2ec3d165b0d409) (v1.0.7 release) | `c9d298230642a6b045526251e12a24e4eb8a8709e16db3d72a2ec3d165b0d409` | [1 / 44](screenshots/scans/vt-ws12winecx26-3-mobetta-v1-0-7.png) (K7AntiVirus). 15 engines timed out, 12 don't read 7z |
| [`WS12WineCX26.3_Mobetta.tar.7z`](https://www.virustotal.com/gui/file/3cfda1b14924489d60a4eea70110155c376cc4fcc22898c34f5ede8e10ddd65a) (v1.0.6 release) | `3cfda1b14924489d60a4eea70110155c376cc4fcc22898c34f5ede8e10ddd65a` | [1 / 44](screenshots/scans/vt-ws12winecx26-3-mobetta-v1-0-6.png) (K7AntiVirus). 15 engines timed out, 12 don't read 7z |
| [`WS12WineCX26.3_Mobetta.tar.7z`](https://www.virustotal.com/gui/file/3a26e3455dd37b99315445333cc446cb03b9fa1b7d6d84aaefd4ddeb4f23008b) (v1.0.5 release) | `3a26e3455dd37b99315445333cc446cb03b9fa1b7d6d84aaefd4ddeb4f23008b` | [1 / 39](screenshots/scans/vt-ws12winecx26-3-mobetta-v1-0-5.png) (K7AntiVirus). 20 engines timed out, 13 don't read 7z |
| [`bin/x87sidecar`](https://www.virustotal.com/gui/file/fef5b07ae2ee9e3d8e26baf756eb747dc7f21328b6befa752844a13367dfa25c) (v1.0.7, `patches/x87sidecar/0001-0006`) | `fef5b07ae2ee9e3d8e26baf756eb747dc7f21328b6befa752844a13367dfa25c` | [0 / 63](screenshots/scans/vt-x87sidecar-v1-0-7.png) |
| [`bin/x87sidecar`](https://www.virustotal.com/gui/file/47b8d85ee1f9c080ec4f96110fc74e5409d46e24185079dced7d212102e824f1) (v1.0.6, `patches/x87sidecar/0001-0005`) | `47b8d85ee1f9c080ec4f96110fc74e5409d46e24185079dced7d212102e824f1` | [0 / 62](screenshots/scans/vt-x87sidecar-v1-0-6.png) |
| [`bin/x87sidecar`](https://www.virustotal.com/gui/file/01e2aa9c9717c33f17882f51c9519c3ec749b778847268f04863e0a2e4d807f5) (v1.0.5, `patches/x87sidecar/0001-0004`) | `01e2aa9c9717c33f17882f51c9519c3ec749b778847268f04863e0a2e4d807f5` | [0 / 63](screenshots/scans/vt-x87sidecar-v1-0-5.png) |
| [`lib/wine/i386-windows/d3d9.dll`](https://www.virustotal.com/gui/file/0d5e411b5a6e8dc2df36c22fcdef54970ae052dfefbbbbfdc7695aa519762cde) (v1.0.5-v1.0.7, mtld3d + `patches/mtld3d/`) | `0d5e411b5a6e8dc2df36c22fcdef54970ae052dfefbbbbfdc7695aa519762cde` | [0 / 70](screenshots/scans/vt-d3d9-dll-v1-0-5.png) |
| [Source at tag v1.0.7](https://www.virustotal.com/gui/file/b0da59d074caf126011c5048bbfe52ecc68d9e74792aacd473533a10f78b6b7e) (`git archive --format=zip --prefix=MoBetta-v1.0.7/ v1.0.7`) | `b0da59d074caf126011c5048bbfe52ecc68d9e74792aacd473533a10f78b6b7e` | [0 / 65](screenshots/scans/vt-mobetta-v1-0-7-source-zip.png) |
| [Source at tag v1.0.6](https://www.virustotal.com/gui/file/15198034ce5aa628fed2bdb14fc6927c2573f4aace3b1c56e774b41b5c980a0c) | `15198034ce5aa628fed2bdb14fc6927c2573f4aace3b1c56e774b41b5c980a0c` | [0 / 65](screenshots/scans/vt-mobetta-v1-0-6-source-zip.png) |
| [Source at tag v1.0.5](https://www.virustotal.com/gui/file/f1e45dbacb93bad135920dc244bc80cbd2c57f160eb782824d30500d33b98f21) | `f1e45dbacb93bad135920dc244bc80cbd2c57f160eb782824d30500d33b98f21` | [0 / 63](screenshots/scans/vt-mobetta-v1-0-5-source-zip.png) |

ClamAV 1.5.4, signatures daily 28189, main 63, bytecode 339 (3,628,278 signatures), updated 2026-11-20.

| Target | Scanned | Infected |
|---|---|---|
| The three release archives (v1.0.5, v1.0.6, v1.0.7; unpacked by ClamAV, no time limit) | 551.8 MiB read, 4.85 GiB scanned | 0 |
| The v1.0.7 engine unpacked (`wswine.bundle`) | 4,625 files, 1.16 GiB | 0 |
| Source (`git archive` zips at tags v1.0.5, v1.0.6, v1.0.7) | 3 zips | 0 |

## v1.0.4

Scanned 2026-11-18.

### Summary

- **ClamAV:** nothing found in the release archive (fully unpacked), the 4,625 files of the unpacked engine, or the source.
- **VirusTotal:** the source and five of the eight changed engine files: 0 detections. Four engine files and the release archive: flagged by **one** engine each, out of 42-71. Each flag is a single vendor's heuristic or machine-learning verdict; no other engine agrees with any of them. We believe these are false positives; false-positive reports went to all three vendors on 2026-11-18, and this page will be updated with their answers (see [Flags](#flags)).
- **Controls:** the stock, unmodified files from Porting Kit's `WS12WineCX26.3_DXMT` engine, and our own build of `winemac.so` without MoBetta's patches, are 0 detections.

Everything MoBetta changes is in [`patches/`](../patches) as readable source, and [`scripts/build_engine.sh`](../scripts/build_engine.sh) rebuilds the engine to the same bytes (the release's SHA-256 is in [`SHA256SUMS`](../SHA256SUMS)).

### VirusTotal

Detections / engines that returned a verdict. Click a file for its live report, or a result for the screenshot taken on the scan date.

#### Release and source

| File | SHA-256 | Result |
|---|---|---|
| [`WS12WineCX26.3_Mobetta.tar.7z`](https://www.virustotal.com/gui/file/2554e0a29294dc5821dd3091c86b67607f78f506ef04988249a389554a2d17b0) (v1.0.4 release) | `2554e0a29294dc5821dd3091c86b67607f78f506ef04988249a389554a2d17b0` | [1 / 42](screenshots/scans/vt-ws12winecx26-3-mobetta.png) (K7AntiVirus). 15 engines timed out on the 184 MB archive, 13 don't read 7z |
| [Source at tag v1.0.4](https://www.virustotal.com/gui/file/cb0066de9a606de0a707273809cbe33cec0a848401bc11bf23f4de105589b208) (`git archive --format=zip --prefix=MoBetta-v1.0.4/ v1.0.4`) | `cb0066de9a606de0a707273809cbe33cec0a848401bc11bf23f4de105589b208` | [0 / 59](screenshots/scans/vt-mobetta-v1-0-4-source-zip.png) |

#### Engine files MoBetta changes or adds

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

#### Controls

| File | What it is | SHA-256 | Result |
|---|---|---|---|
| [`WS12WineCX26.3_DXMT.tar.7z`](https://www.virustotal.com/gui/file/7b3f383a2209de5765eef45f1d6fc316682cfcfbb3518d7470e4b51f00e7cd08) | Porting Kit's stock engine, the base of MoBetta | `7b3f383a2209de5765eef45f1d6fc316682cfcfbb3518d7470e4b51f00e7cd08` | [0 / 45](screenshots/scans/vt-stock-ws12winecx26-3-dxmt.png) |
| [`ntdll.so`](https://www.virustotal.com/gui/file/f4a653b12f142fe601253d764288260ce63e0620ca092dfb99ef8ffc41aad677) | stock, from that engine | `f4a653b12f142fe601253d764288260ce63e0620ca092dfb99ef8ffc41aad677` | [0 / 60](screenshots/scans/vt-stock-ntdll-so-cx26-3.png) |
| [`opengl32.so`](https://www.virustotal.com/gui/file/4571b05c840e7d0f49d87b11eeba2ce08391af713bcf689a19f6af25fac45c3a) | stock, from that engine | `4571b05c840e7d0f49d87b11eeba2ce08391af713bcf689a19f6af25fac45c3a` | [0 / 63](screenshots/scans/vt-stock-opengl32-so-cx26-3.png) |
| [`winemac.so`](https://www.virustotal.com/gui/file/2e9d3f8cbf9842a6286a5605c0f2077a32043550ab1b5040af62ff53f0f95c56) | stock, from that engine | `2e9d3f8cbf9842a6286a5605c0f2077a32043550ab1b5040af62ff53f0f95c56` | [0 / 63](screenshots/scans/vt-stock-winemac-so-v1-0-2.png) |
| [`winemac.so`](https://www.virustotal.com/gui/file/d9b0b757dde13ede7deded8b25c37fec28a1ff123356e60b6c68bba618fff76d) | our build, same toolchain, no MoBetta patches | `d9b0b757dde13ede7deded8b25c37fec28a1ff123356e60b6c68bba618fff76d` | [0 / 63](screenshots/scans/vt-control-winemac-so-unpatched.png) |

### Flags

| File | Engine | Label | What it is |
|---|---|---|---|
| `ntdll.so`, `opengl32.so`, `winemac.so` | Microsoft | `Trojan:Script/Wacatac.C!ml` | `!ml` marks a machine-learning verdict, not a signature match. "Wacatac" is Microsoft's catch-all name for such verdicts. The label says "Script", but these are native macOS libraries. The stock files and our unpatched `winemac.so` are clean, so the model reacts to the patched code; the patches are in `patches/` |
| `user32.dll` | Cynet | `Malicious (score: 100)` | Cynet's score is a heuristic/ML verdict. 70 other engines, including Microsoft, find nothing. Patch 0005 only shortens the display-mode list WoW sees |
| `WS12WineCX26.3_Mobetta.tar.7z` | K7AntiVirus | `Trojan ( 006e46631 )` | A generic label on the archive. No engine flags the same file inside it, and ClamAV found nothing in any of its files |

Reports sent 2026-11-18: Microsoft (Defender file submission), Cynet and K7 (by email to their false-positive contacts listed by VirusTotal). K7 and Microsoft's `opengl32.so` and `winemac.so` flags are gone; for the current state and the new archive flags see [Rescan 2026-11-22](#rescan-2026-11-22).

What the changed code does: emulate x86 instructions Rosetta 2 rejects (ntdll), keep no-exec memory on and start the x87 helper (ntdll), reuse a buffer mapping (opengl32), shorten the resolution list (user32), and fix mouse-look and fullscreen in the Mac display driver (winemac). Nothing is injected into the game and no game file is changed. See the [README](../README.md) and [CHANGELOG](../CHANGELOG.md).

### ClamAV

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
