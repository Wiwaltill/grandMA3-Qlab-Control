# grandMA3-Qlab-Control

Reusable grandMA3 Lua plugin for controlling QLab video cues via OSC from manually operated lighting sequences. Designed for grandMA3 2.5.1.1 and QLab 5 (version to confirm), without timecode or a dedicated video operator.

## Status
V1 development started: **0.1.0-dev.2 import preview**. Pure Lua command/state
core, native setup dialog, layout/installation data plan and mock tests exist.
XML/Lua import files are generated and deployed locally. Automatic pool creation
and OSC transmission are **not yet enabled**. No onPC/console or QLab runtime validation; no production release.

Build: `python3 tools/build.py`. Test with Lua 5.4 via Lupa:
`python3 tools/test.py` (requires `pip install lupa`). Generated files are in `dist/`.

- [Deutsche Entwicklungs- und Setup-Anleitung](docs/SETUP-DE.md)
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
