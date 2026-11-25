# grandMA3-Qlab-Control

Reusable grandMA3 Lua plugin for controlling QLab video cues via OSC from manually operated lighting sequences. Designed for grandMA3 2.5.1.1 and QLab 5 (version to confirm), without timecode or a dedicated video operator.

## Status
**0.2.0-beta.8 — integration test build.** Native setup, automatic layout/
macro/appearance installation, ownership preflight, repeat install/update and
confirmed cleanup are implemented. Explicit TEST sends a real SendOSC command;
START/STOP/PAUSE/RESUME and manual GO/PANIC also use the configured MA output.
No onPC/console or QLab runtime validation has been performed. The zero-argument SendOSC form with empty type/value fields is an integration-test
candidate; the earlier address-only form was rejected by the user's onPC.
Restart starts a separately mapped QLab helper cue; its song-specific restart logic
must be programmed and tested in QLab.

Build: `python3 tools/build.py`. Test with Lua 5.4 via Lupa:
`python3 tools/test.py` (requires `pip install lupa`). Generated files are in `dist/`.

- [Deutsche Entwicklungs- und Setup-Anleitung](docs/SETUP-DE.md)
- [OSC-Verbindung Schritt für Schritt einrichten](docs/OSC-ANLEITUNG-DE.md)
- [Kompatibilität und offizielle Quellen](docs/COMPATIBILITY.md)
- [Manuelle Tests und Release-Gates](docs/VALIDATION.md)
- [Changelog](CHANGELOG.md)

## Documentation
- [Development instructions for Codex](AGENTS.md)
- [Functional specification and UI design](SPECIFICATION.md)
- [V1/V2 roadmap](ROADMAP.md)

V1: native MA layout, automatic macros and appearances, setup dialog, explicit cue control and manual transport. V2: investigate real playback feedback and progress.

## License
See [LICENSE](LICENSE).
