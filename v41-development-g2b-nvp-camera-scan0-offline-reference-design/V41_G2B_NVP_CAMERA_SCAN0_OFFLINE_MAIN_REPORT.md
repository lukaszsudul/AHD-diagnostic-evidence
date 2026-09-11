# AHD v41 G2B-NVP-CAMERA-SCAN0-OFFLINE main report

## Result

- Engineering gate: `PASS`.
- Offline deterministic gate: `24/24 PASS`.
- Overall classification: `PASS_SCAN1_READ_MANIFEST_READY_ACQ1_REFERENCE_COMPATIBILITY_TEST_REQUIRED`.
- Evidence publication is a separate external gate and is reported only after Git push plus commit-pinned remote byte read-back.

## Authority and scope

- Owner R1 SHA-256: `2CACBC2C66350ADEE0015704211DCB7B6DBB7F38FFD95CA579331559F5E350C5`.
- Reference repository/commit: `4e4o/nvp6134_ex` / `081ebbff9a2722d47acf16c680594be43cb179e2`; driver `17.03.20.01`; 14 files frozen by identity/hash only.
- Reference source manifest CSV SHA-256: `FBC9E25CCA9A35E429D67BF466560E97DA015803FD012E259D02F90FCC41D0FF`.
- Exact current source: `fc37d815b5d64ef90dfbd99c57ae4cc09567b56f` / tree `cdff3ea9d786141ff9bfd46f7099198324604663`; 9 scoped files inventoried read-only.
- Local NVP6134C authority: accepted Rev1.0 SHA-256 `301FF799A101B0DBDF6CD946EEAD0C1EDC67D07FFEAC7E65FA8C6AE82C316E46`.
- DUT/driver/PCIe/MMIO/NVP-I2C/JTAG/programming/reboot/power-cycle/Vivado/build/capture access: none.
- PRODUCT, diagnostic source, SSOT and META: unchanged.

## Principal findings

Current v41 is a one-shot static CH1/AHD1080p25/stage-2 profile with AUTO disabled and a 25-kHz master. DIAG1 samples A8/E0/E1/E2/E8+channel and may change only BGDCOL and VDO1 route before exact restore. It has no private-bank adaptive detector, campaign reset/debounce, slice sweep, callable mode action or reference-equivalent EQ action. Therefore a connected camera can remain at BGDCOL when the fixed acquisition assumptions never produce valid input lock; BGDCOL is an output fallback, not evidence that no camera signal exists.

The reference detector is stateful. It reads A8 and private F0/F2/F3/F4/F5, uses E2/E3/E8-E11-equivalent private metrics for ambiguity, performs temporary functional writes in initial discrimination, and requires three agreeing samples for a changed-format debounce. The host design uses a fresh campaign and a stricter three-complete-tuple rule. The no-video slice mapping is 0x50/0x40/0x60 by counter phase, but pre-increment makes 0x40 the first post-reset write; neighbor register 0x05 and the SD helper condition are inseparable from that semantic.

The candidate table has 82 entries. Bank0 B8-BE and C0-C6 are 14 known clear-trigger addresses and are prohibited; B0 is a held/latched NOVID read and is not itself in the documented clear-trigger ranges. All 82 candidate reads are frozen as observational reads; 40 private field meanings remain explicitly unconfirmed for NVP6134C. They stay raw and cannot alone authorize ACQ1.

SCAN1 is read-only ONESHOT, one frozen snapshot, host-owned history, 25 kHz, ten atomic groups, 82 entries, 105 transactions, 3681 SCL periods, 147.240 ms nominal wire time and a 25.560-ms longest group grant. It writes only 0xFF, verifies every bank, includes A8 bookends and restores/verifies ENTRY_BANK. The profile-only free range is 0x12000..0x123FF and the manifest SHA is `2773DFA86ABEC87EF1E5BFB6F093D83BD8FCB4382B51B1792F3B7E8E302A1B2B`. It adds no timer, double buffer, runtime timeout, recovery or CDC.

The AHD1080p25 reference path is deterministic: `211` semantic operations, two symbolic preserved fields, action SHA `64FFDBB1EF5E34D4DA2301B0256CFE2BA271E41ECDF26D64F85E42223C6344C1`. It is `PARTIAL`, not READY: reference-only functional writes require NVP6134C compatibility evidence. READY actions are `READ_DETECTION_SNAPSHOT, RESET_FORMAT_DETECTOR_STATE, VERIFY_AHD1080P25_LOCK, ROUTE_CHANNEL_TO_VDO1`; PARTIAL actions are `RESTORE_PRODUCT_BASELINE, ABORT_AND_RESTORE`; blocked functional actions are `ENTER_NOVIDEO_AHD1080P25, STEP_NOVIDEO_SLICE, APPLY_AHD1080P25_MODE, INIT_EQ_AHD1080P25`. Generic host I2C remains prohibited.

## First remaining causal blocker

`ACQ1_REFERENCE_ONLY_FUNCTIONAL_WRITES_LACK_NVP6134C_COMPATIBILITY_AND_COMPLETE_BASELINE_READBACK_AUTHORITY`.

This does not block SCAN1-R1 implementation. After SCAN1 simulation/build/hardware qualification under new authority, the Owner must authorize or reject exactly one controlled NVP6134C compatibility campaign for the blocked ACQ1 functional actions. CAM1 remains future-only and requires CH1/CH3, stable AHD1080p25 locks, 2500/2500 records, a complete non-BGDCOL/non-black spatial frame, and a second valid frame after one controlled scene change.
