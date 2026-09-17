# AHD v41 G2B NVP camera W3 — first/terminal I2C telemetry and default-OFF bank pause

**Engineering gate: FAIL. Evidence publication: PENDING FINAL REMOTE READBACK. Overall: FAIL.** The W3 source and bounded offline digital tests are complete, and the private source branch passed commit-pinned remote byte readback. The new full FPGA build stopped at candidate 2's first failed post-opt gate: **23,774 Slice LUTs against the governed 20,384 ceiling, excess 3,390**. There is no qualified new routed DCP, bitstream, closed final host bundle or private release package. W4 is blocked and was not run.

This is an offline engineering report. It does not claim that a camera, board, PCIe function or I2C bus was accessed in W3, or that the historical Bank5 failure was physically repaired. Source release and public evidence publication are separate gates; public evidence publication must remain `PENDING` until its own final commit-pinned remote readback is recorded.

## Authority and identities

| Item | Exact result |
|---|---|
| Governance start/end and staleness | `PROJECT_STATE_REV_AT_START=9`, `PROJECT_STATE_REV_AT_END=9`, `SSOT_STALENESS=NONE`; six required documents read in order, 18/18 applicable manifest entries match at both checks; end manifest SHA-256 `5F5BEE9FB84BE98AE5D1A24B98CD487C42C8C70DC785C2326F0AC634815DCCCC`; local/origin/fresh remote evidence `main` resolves to the pinned entry commit. |
| Entry evidence commit / tree | `f3eafd4341752648f210afd0c8687c5cf4759294` / `fdb3ac413f7e4505d6249e8cd1252077420a2025` |
| W1/W2 accepted evidence commit | `f3eafd4341752648f210afd0c8687c5cf4759294` |
| Governed source parent commit / tree | `09cd7cbb426027acaefd0cf3989579b80a451f3a` / `c6be008ddc387c1f43eefa35d4fed0e2ccb968db` |
| Candidate 1 commit / tree | `57c92ec0d3dd97feb967371d765ed3bbe627b550` / `15b777a32b827f75c85fe379feaee294ade6028b` |
| Final candidate 2 commit / tree | `98d4d214c1219b29a60dc1a33af13e91fe33d27c` / `1c43ee847bc468408f574125e3e37209cbb27d54` |
| Diagnostic source branch | `diag/v41-g2b-w3-first-terminal-wait-delay-20260917T165535Z` |
| Source release readback | **PASS:** 342 paths, modes, sizes and SHA-256 values at the exact candidate-2 remote commit/tree; `receipts/SOURCE_REMOTE_READBACK.json`, SHA-256 `B33B2DB71E8A77000991929BCA25B8EE3BC7BB763C175E553E9670D823BEF0A8` |
| W3 contract/schema | `contract/W3_CONTRACT.json`, 17,783 bytes, SHA-256 `99868A4ECE2D859DA16224408F289EBEACE1F63315622109CBCEA9C4776A07B7` |
| Frozen candidate-2 input manifest | `receipts/W3_CANDIDATE2_SOURCE_BUILD_MANIFEST.json`, SHA-256 `45C74B282C85D750ED828C53F12131E66F8CEE3CB98810E5C06F35FE42E49CF6` |
| Build part / top / tool | `xc7a35tcsg325-2` / `ahd_capture_top_xdma` / Vivado 2025.2 SW Build 6299465; one worker |
| Implementation identity | Candidate-2 source commit encoded in five top generic words; no live readback of the identity occurred |

`reports/W3_AUTHORITY_PUBLIC.md` preserves the ordered rev-9 entry check and pinned evidence inventory. The independent fresh end check found rev 9 unchanged with all 18 manifest hashes matching, and classified SSOT staleness as `NONE`; this does not promote W3 into SSOT. The historical local archive was independently verified at 108,145 bytes, SHA-256 `96080348A26E00ECF8B4DBA58F6E691EBAD48F2D8B0C3DDC2EC474A316E6A0CB`. The control and 25 completed scans, generations 1–26, each recorded valid Bank0 `F4=0x00F49005` and `F5=0x00F50105`: historical device ID `0x90`, revision `0x01`, no retry. The incomplete scan is excluded; live identity remains **NOT_SURVEYED_IN_W3**. `reports/HISTORICAL_CHIP_ID_AND_AUDITOR_PREFLIGHT.md` also confines the historical Bank5 **27 matching / 18 differing / 6 unmatched** reference rows to scoped occurrence alignment; these are not correct/wrong/missing product-setting counts. The 18 differing rows do not directly intersect Bank5 `F2/F4/F5`.

## Scoped source and behavior

The candidate-1 source changed four tracked files and added 16 files, all in the W3 allowlist. Candidate 2 made one narrow top-level correction: it moved the unchanged 86-bit master observation and scalar first-fault net declarations before their first use. `receipts/W3_CANDIDATE2_TOP_PREFLIGHT.json` has a negative control that rejects the candidate-1 late declaration and a positive candidate-2 top compile. Seventy-five selected immutable source/IP/XDC/driver/manifest/projection/autoinit inputs matched the parent bytes. The primary checkout and prior artifacts were preserved. No SSOT, META, PRODUCT, driver, table, scanner read-manifest, ACQ functional, IP or XDC change is claimed. Exact paths and hashes are in `reports/CHANGE_ALLOWLIST_AND_DIFF_REVIEW.md`, `reports/IMMUTABLE_SOURCE_SHA256.json` and `reports/CANDIDATE2_SOURCE_AND_IDENTITY.md`.

The W3 extension adds a default-OFF, one-hot controlled scanner-owned pause; first-detected and terminal I2C error records; per-attempt SCL wait and ACK-phase validity; same-kind successful control samples; bounded 1,024-by-32-bit BRAM payload, validity masks and saturating counters. A block ID and effective mode are frozen at admission. Rejected writes, incomplete scans, first versus terminal identity, first raw versus completion/timeout cause, and reset/clear retention are explicit. The inherited 82-entry/10-group scanner and ACQ functional paths remain outside the changed behavior except for the authorized additive page, telemetry taps and successful bank-write pause.

## Offline verification actually passed

`reports/W3_TEST_COVERAGE_AUDIT.md` assesses **T02–T31 as 30 bounded directed digital PASS cases** with named guarded receipts. T01's source/contract identity subset now has the candidate-2 commit and 342-file remote readback, but full release identity cannot pass after the resource stop. T32's provisional 49-file host copy passed 27 module-origin/import checks and wrong-BDF/foreign-descriptor negative tests; it is not a final source-frozen release bundle or hardware qualification. No digital PASS is promoted to whole-design or physical acceptance.

The clean pin-level OFF run completed 105 accepted commands and 82 valid entries. Its command sequence and complete resolved SCL/SDA START/STOP edge trace matched the pinned W1 parent. All **104** adjacent gaps and the W1 CSV's 21 selected boundaries were checked. ON retained the same commands and pin waveform per operation. It added exactly **18,750 cycles = 300 µs** after each of the ten successful group-select bank writes, including three same-bank reselections, and the successful terminal restore: **11 affected writes, 206,250 added cycles = 3.300 ms** in the clean full scan. The other 93 gaps were unchanged. A clean bank-write STOP-to-verify START gap is **3,755 cycles = 60.080 µs OFF**, **22,505 cycles = 360.080 µs ON**; verify-read-to-first-entry-read remains 3,755 cycles in both modes. Clean successful restore-to-verify has the same OFF/ON bank-write gap. `receipts/W3_DELAY_FINAL.json` and `reports/W3_PIN_LEVEL_AND_MASTER_VERIFICATION.md` contain source/log hashes and the exact comparison.

Five paired OFF/ON Bank5 pin-level fault cases passed: WADDR, REGADDR, RADDR, DATA NACK and SCL timeout. A failed select received **no** added pause and no select retry; a later successful cleanup restore received its authorized pause. The DATA-NACK case stopped after 37 valid entries and 51 accepted commands, with raw cause 4 and mapped cause 10; the verify RADDR case had 52 commands and mapped cause 3. The real-master compound REGADDR-NACK then STOP bus-idle timeout separately retained raw first cause 2, completion raw cause 6/timeout and mapped cause 5 in committed first/terminal MMIO records. Same-kind group-verify success then failure retained all seven control/context words and validity. The master remained cycle-exact to the pinned parent for nine representative commands and 3,374 compared cycles. Receipts are `receipts/W3_DELAY_NEGATIVE_FINAL.json`, `receipts/W3_T18_T23.json` and `receipts/W3_MASTER_TELEMETRY.json`.

Guarded scanner/MMIO, inherited SCAN1/ACQ/BRAM and CONT1R3 replay tests passed; the scanner/MMIO bench asserts 22 required markers, including writer drain, all 164 entry first/retry slots, all 20 group select/verify slots, first/terminal retention and ownership. The host W3 unit suite passed 9/9 tests, including corrupt-record rejection and coherent read fail-closed behavior. These are offline digital/model tests; they do not establish analog SCL behavior, current NVP ID, camera format, electrical margin or a recovered frame.

## Two build candidates and first failed gate

Candidate 1 reached synthesis with `telemetry_bundle` connected through a one-bit implicit top net instead of the master's 86-bit port (`Synth 8-11241`, `Synth 8-689`). That build was stopped at its own first connectivity failure, before post-opt. Candidate 2 moved only those declarations before use, passed the targeted top compile, and ran a fresh whole-design synthesis and `opt_design`. Its explicit post-opt gate then stopped the build:

| Resource / stage | Candidate 2 actual | Authority or limit | Result |
|---|---:|---:|---|
| Post-synthesis Slice LUTs | 25,372 | 20,800 physical device LUTs | Diagnostic over capacity; post-opt remains governing |
| Post-opt Slice LUTs, total including LUTRAM | **23,774** | **20,384 governed ceiling** | **FAIL, excess 3,390** |
| Post-opt logic / memory LUTs | 22,450 / 1,324 | Total above applies | Measured, no double-counted hierarchy |
| Post-opt FF / RAMB36 / RAMB18 / DSP | 26,807 / 27 / 4 / 0 | Device limits in raw report | Measured; LUT is first failed gate |
| Parent post-opt / routed LUTs | 20,186 / 19,738 | Historical comparison only | Candidate 2 post-opt is +3,588 versus parent post-opt |
| Candidate-2 placement / route / fresh timing/CDC/DRC/bus-skew | NOT_RUN | Required later gates | Stopped at post-opt |

The raw error is `POST_OPT_LUT_GATE_FAILED:23774` in `build/candidate2_vivado.log:2888`. That log is 360,974 bytes, SHA-256 `691FBD0D00BC720CE16BF2AD1F8E53A8BD2D8D88BB4025872064B3E2EE8C1EAE`. `receipts/POST_OPT_UTILIZATION.rpt` is 10,643 bytes, SHA-256 `7FE61C6DB36F3D53E81EF3AD24E1C115524C14DD8727BAE4CE6A90E8B774902F`; `reports/RESOURCE_DELTA.csv` records the parent delta and `NOT_REACHED` routed result. A reduction of at least 3,390 post-opt LUTs would require substantial architecture work outside this bounded W3 correction cone. No candidate 3 was attempted. Neither a lower synthesis-only estimate nor the parent's routed count can pass this gate.

## Release disposition and hard stop

| Output or action | Actual W3 result |
|---|---|
| Qualified new routed DCP / independent reopen | `NONE` / `NOT_RUN` |
| Final W3 `.bit` / bitgen invocation | `NONE` / `0` |
| Firmware manifest, closed final bundle, private package | `NONE`; provisional offline host copy does not replace these |
| W4 handoff status | `BLOCKED`, recorded in `reports/W4_HANDOFF.md`; W4 not authorized or run |
| Hardware qualification, DUT/SSH/JTAG/MMIO | `NOT_RUN`, `NONE` |
| Programming / reboot / new physical scans / frames | `0 / 0 / 0 / 0` |
| Product/SSOT/META/driver update | `NONE` |
| Public evidence publication | `PENDING FINAL REMOTE READBACK`; no PASS claim in this report |

The source release is independently **PASS** at the private branch and exact 342-file remote readback. That does not change the engineering **FAIL**, and it does not establish a public evidence publication result. The unresolved engineering blocker is the **3,390-LUT post-opt excess**; a separately governed architectural resource redesign and fresh build/sign-off would be required before any real W4 handoff. No 10,000-scan waiver, camera/MODE1/EQ/DMA campaign, physical NACK-cause conclusion or first-frame claim follows from W3.
