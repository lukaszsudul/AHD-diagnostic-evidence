# Candidate 2 W3 source and implementation identity

**Status: SOURCE_FROZEN; ENGINEERING_FAIL_POST_OPT_LUT_GATE.** Candidate 2's `opt_design` completed, then its explicit post-opt gate stopped the build at `POST_OPT_LUT_GATE_FAILED:23774`. The measured 23,774 total Slice LUTs exceed the governed 20,384 limit by **3,390** and even the device's 20,800 physical LUT capacity by 2,974. This is the first failed candidate-2 engineering gate. Placement, routing and all later release gates were not run.

| Identity | Exact value |
|---|---|
| Governing parent commit / tree | `09cd7cbb426027acaefd0cf3989579b80a451f3a` / `c6be008ddc387c1f43eefa35d4fed0e2ccb968db` |
| Candidate 1 commit / tree | `57c92ec0d3dd97feb967371d765ed3bbe627b550` / `15b777a32b827f75c85fe379feaee294ade6028b` |
| Candidate 2 commit / tree | `98d4d214c1219b29a60dc1a33af13e91fe33d27c` / `1c43ee847bc468408f574125e3e37209cbb27d54` |
| Source branch | `diag/v41-g2b-w3-first-terminal-wait-delay-20260917T165535Z` |
| Candidate 2 changed path versus candidate 1 | `rtl/top/ahd_capture_top_xdma.sv` only |
| Candidate 2 top SHA-256 | `2112171A68A07FE0348C221383710F4E6ADB8000721BC7165DFC5638DA9151A6` |
| W3 contract/schema SHA-256 | `99868A4ECE2D859DA16224408F289EBEACE1F63315622109CBCEA9C4776A07B7` (17,783 bytes) |
| Frozen candidate 2 build manifest SHA-256 | `45C74B282C85D750ED828C53F12131E66F8CEE3CB98810E5C06F35FE42E49CF6` |
| Candidate 2 full-build Tcl SHA-256 | `8C141FFB9AF548B54968F81B731921FEABE99E147C5540BE923310CFB7DBD58D` |
| Target / top / tool | `xc7a35tcsg325-2` / `ahd_capture_top_xdma` / Vivado 2025.2 SW Build 6299465 |
| Build inputs | 26 SystemVerilog, 4 VHDL, 8 XDC, 1 XDMA XCI, 1 IP-configuration Tcl: 40 selected files |
| Source checkout at manifest freeze | Clean, per `W3_CANDIDATE2_SOURCE_BUILD_MANIFEST.json` |
| Source remote publication and commit-pinned readback | `PASS`, exact candidate-2 commit/tree and 342 paths, modes, sizes and SHA-256 values; `reports/SOURCE_REMOTE_READBACK.json`, SHA-256 `B33B2DB71E8A77000991929BCA25B8EE3BC7BB763C175E553E9670D823BEF0A8` |
| Post-opt Slice LUTs / governed limit / excess | `23,774` / `20,384` / `3,390` |
| Physical LUT capacity / excess | `20,800` / `2,974` |
| Post-opt logic LUT / memory LUT | `22,450` / `1,324` (includes 1,278 LUTRAM and 46 SRL) |
| Post-opt gate / engineering result | `POST_OPT_LUT_GATE_FAILED:23774` / `FAIL` |

The new implementation identity encoded in the build generics is candidate 2 commit `98d4d214c1219b29a60dc1a33af13e91fe33d27c`, split into five 32-bit words. The exact generic string, input paths, sizes and hashes are in `build/W3_CANDIDATE2_SOURCE_BUILD_MANIFEST.json`. The frozen W3 BAR contract is `contract/W3_CONTRACT.json`; its schema digest is not a substitute for a completed implementation identity read from hardware.

Candidate 1's `telemetry_bundle` connection reached synthesis as a one-bit implicit net. Candidate 2 moved only the 86-bit observation and scalar first-fault declarations above first use. `authority/candidate2_top_width_preflight/receipt.json` records an exact diff check, a negative control that rejects candidate 1, a positive control that accepts candidate 2, and isolated full-top source compilation. Candidate 1's failed synthesis receipt remains separate. No candidate-1 build result is inherited as candidate-2 resource or sign-off evidence.

The independent precommit scope report `reports/CHANGE_ALLOWLIST_AND_DIFF_REVIEW.md` enumerates the original four modified and 16 new W3-allowlisted paths; its immutable-input receipt `reports/IMMUTABLE_SOURCE_SHA256.json` matches 75 selected files to the governing parent bytes. The candidate-2 delta adds no new functional path or immutable-byte edit beyond the top declaration move.

## First failed gate and stopped descendants

| Stage or artifact | Actual result |
|---|---|
| Candidate-2 synthesis | Completed; not sufficient for W3 acceptance |
| Candidate-2 post-opt | `23,774` Slice LUTs including LUTRAM versus `20,384` allowed; **FAIL**, excess `3,390` |
| Placement / route / fresh timing, CDC, DRC, bus-skew | `NOT_RUN` after first failed gate |
| Signed new routed DCP absolute path / size / SHA-256 | `NONE` |
| Final W3 `.bit` absolute path / size / SHA-256 | `NONE` |
| Closed final bundle and private package identities | `NONE`; a provisional offline host copy is not a release bundle |
| W4 | `BLOCKED`; no W4 action or authorization |

The raw failure is in `build/candidate2_vivado.log` at lines 2,882–2,893 (360,974 bytes; SHA-256 `691FBD0D00BC720CE16BF2AD1F8E53A8BD2D8D88BB4025872064B3E2EE8C1EAE`). `build/candidate2/POST_OPT_UTILIZATION.rpt` (10,643 bytes; SHA-256 `7FE61C6DB36F3D53E81EF3AD24E1C115524C14DD8727BAE4CE6A90E8B774902F`) and `POST_OPT_HIERARCHY.rpt` (27,473 bytes; SHA-256 `DE70937D8FB00BD6DA2857F3AA978CAAD3EE7F7AAA578C64C0594C3A28E5AD26`) independently expose the measured total and breakdown. The parent post-opt total was 20,186, so candidate 2 uses 3,588 more LUTs than that parent. Closing the 3,390-LUT governed gap would require a substantial architectural reduction outside this narrow W3 implementation cone. No candidate 3 was attempted. Signed DCP, firmware, final bundle, package and hardware-qualification identities are **NONE**. The historical parent DCP and bitstream hashes remain comparison authorities only.
