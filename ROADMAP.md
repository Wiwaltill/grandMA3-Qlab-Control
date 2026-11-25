# Roadmap
## V1
Current milestone: 0.1.0-dev.4 import preview. Parser/config/state, mock-tested
runtime boundaries, graphical setup and complete layout/pool data plan exist.
Steps 1, 3 and 4 remain incomplete: 2.5.1.1 smoke tests, native export fixtures,
pool mutation/ownership implementation and argument-free SendOSC encoding are
required before installation or transport can be enabled. The Plugin XML/Lua
entry point is now packaged; its onPC import round-trip is still pending. See docs/VALIDATION.md.

1. Validate MA 2.5.1.1 plugin entry point, argument dispatch, SendOSC encoding and QLab 5 OSC addresses/types with official docs and a minimal smoke test. Earlier chat offered two alternative syntaxes; neither has been hardware-tested.
2. Build tested command parser, configuration and state model; implement transport adapter.
3. Add setup dialog and collision-safe automatic pool installation.
4. Create native control layout, macros, appearance assets and state labels.
5. Test all commands, transitions, reinstall/uninstall and failure paths on MA onPC and QLab; publish German installation and show-programming guide.
6. Package versioned import ZIP; document untested limitations, changelog and release procedure.
## V2
Investigate bidirectional OSC and potential bridge; then implement actual playback/connection status, cue discovery and timing/progress only when verified.
## Open questions
Confirm actual QLab version, group modes and whether videos run full song or require intra-song triggers. Support both workflows. Confirm MA console/onPC networking, pool allocation and import format with user testing. No implementation or hardware verification yet.
