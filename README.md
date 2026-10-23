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

MoBetta patches Wine's signal handler to emulate the rejected instructions, allowing the game to run without modifying game files or injecting DLLs.

**Key constraint:** No game file modifications. This engine is designed for use with servers that run anti-cheat systems.

## Status

🚧 **In Development**

- [x] Phase 1: Confirm faulting instructions
- [x] Phase 2: Reproducible engine build
- [x] Phase 3: Implement instruction emulation (unit-tested; in-game test pending)
- [ ] Phase 4: Testing

## Target Environment

- **Machine:** Apple Silicon Mac (M1/M2/M3)
- **Wrapper:** Porting Kit / Wineskin
- **Base:** CrossOver 26.3 Wine
- **Game:** WoW 3.3.5a (build 12340)

## Building

Documentation coming after Phase 2.

## References

- [Whisky Issue #537](https://github.com/Whisky-App/Whisky/issues/537) - WoW crashes on Apple Silicon
- [Wine Bug 56441](https://bugs.winehq.org/show_bug.cgi?id=56441) - FNDISI patch precedent
- [x87sidecar](https://github.com/athei/x87sidecar) - Related project
- [Endfield_FineWine](https://github.com/stoicswe/Endfield_FineWine) - CrossOver patching example

## License

TBD

## Disclaimer

This project is not affiliated with Blizzard Entertainment, any private server, or CodeWeavers. Use at your own risk.
