# AHD 1080p25 action authority

- Selected reference path: `nvp6134_set_chnmode(CH,PAL,NVP6134_VI_1080P_2530)` -> common values -> common FHD -> AHD1080p2530 -> software mode state -> ACP -> EQ init -> Bank9 re-arm (35 ms) -> Bank0 channel enable.
- Extracted semantic operations: `211` (`205` I2C operations, three fixed delays totaling `245` ms, and three software-state assignments).
- Manifest digest: `64FFDBB1EF5E34D4DA2301B0256CFE2BA271E41ECDF26D64F85E42223C6344C1`.
- CH1 deterministic replay: `1C83F7F1DD20328A301D992CC21A12DEEF76AB85CDDF82F82F17D05DE717D18F`.
- CH3 deterministic replay: `CBED701E4E510BF84C13C850B6F60898059FF22BD4D45063ABC0F15DFBA6EEC4`.
- Explicit NVP6134C guide-note-proven operation instances: `41`.
- Reference-driver-only or software-state operation instances: `170`.
- Symbolic preserved fields: `2` — Bank1 `0xED` and Bank9 `0x44`; both clear only the target channel bit and preserve every other old bit symbolically.

Readiness is `PARTIAL`, not hardware-ready. The sequence is deterministic and complete for the selected reference call path, but most functional register values are not proven compatible with NVP6134C. No unknown masked bit is set to zero. ACQ1 must first capture and persist the complete touched-register baseline, verify safe readback authority, and obtain bounded compatibility evidence. SCAN1 contains none of these writes.
