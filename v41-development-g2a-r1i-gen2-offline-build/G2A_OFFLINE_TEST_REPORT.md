# AHD v41 G2A Offline Test Report

## 1. Result

**Offline-test gate: PASS.**

The clean-committed G2A contract suite and the supplementary seven-case simulation matrix both passed against the final integration source identity:

- Commit: `224d194e5f82c85bcb29297561c5d5e76d28063b`
- Tree: `283f98c02e6f9c61716875415cf000682f8ab856`
- Branch: `integration/v41-r1i-gen2-g2a`

The source worktree was clean before and after both final test campaigns. No source or protected test was edited to obtain a pass. No hardware, DUT, network, Hardware Manager, programming, PCIe enumeration, MMIO, driver, DMA, throughput, full-build, or G2B action was performed by these tests.

This report classifies only the G2A offline-test gate. Synthesis, implementation, timing, DRC, bitstream, and hardware qualification are separate gates.

## 2. Authoritative clean-committed contract suite

Evidence directory:

`<PRIVATE_EVIDENCE_ROOT>\sealed_offline_checks_contingency_final`

Authoritative receipt:

`<PRIVATE_EVIDENCE_ROOT>\sealed_offline_checks_contingency_final\G2A_OFFLINE_CHECK_RECEIPT.txt`

Receipt SHA-256:

`961B79FFB1A4C6BD46CA64CD2A2E0EDBFA3AD767ECF7D0078A9B95D56EF42A32`

The receipt records `RESULT=PASS`, `MODE=CLEAN_COMMITTED`, `PYTHON_TESTS=PASS`, `FOCUSED_SIMULATION=PASS`, `PROVENANCE_TESTS=PASS`, and `HARDWARE_ACCESSED=NO`. Its source identity is the final commit/tree stated above.

### 2.1 Contract and source-protection checks

The suite passed all of the following applicable checks:

- Exact qualified base commit `20c3323d79d3896edc586d6db1df7deee60f9e41`, tree `70d801fd7a879080da399bfa9ee95fd6eb008e16`, and immutable qualified tag.
- Direct-parent and base-ancestry checks for the final integration commit.
- Primary and secondary XDMA donor identities and ancestry.
- Exact four-file source-change allowlist: the XDMA XCI, authoritative XDMA configuration Tcl, G2A build wrapper, and G2A offline-check runner only.
- Byte identity of protected R1i NVP/I2C RTL, composite top, MMIO/control sources, host bridge, PIO sources, the qualified build oracle, and protected R1i tests.
- R1i MMIO and telemetry source identity, no G2B `0x3800` pages, no functional RTL/XDC change, no record-to-C2H adapter, no ring, no formatter, no scheduler, and no conflict or R-track leakage.
- Exact Gen2 speed transition in both authoritative representations with x1, 100 MHz refclk request, 62.5 MHz AXI-stream clock request, 64-bit AXI4-Stream width, one C2H, one mandatory H2C, one MSI vector, MSI-X disabled, 128 KiB AXI-Lite/BAR architecture, active-low PERST, IDs, class code, and other frozen properties preserved.
- C2H application tie-off values `TDATA=64'b0`, `TKEEP=8'b0`, `TLAST=1'b0`, and `TVALID=1'b0`; H2C `TREADY=1'b0`.
- Provenance wrapper structure, exact 40-hex SHA round trip, positive provenance-only receipt, invalid-mode rejection, one-word round-trip-mismatch rejection, and exit before any project creation.
- Clean source before provenance execution and unchanged source after the complete offline suite.

### 2.2 Inherited Python and focused R1i simulation

All four discovered inherited Python suites exited zero:

- `test_nvp_r1e_tools`
- `test_nvp_r1f_tools`
- `test_nvp_r1f_tri_phase_probe_model`
- `test_nvp_r1i_tools`

The exact-base focused R1i simulation also exited zero with its required completion markers. It validates the qualified physical-wire behavior, including all-ACK wire/output equivalence, qualified high-SCL sampling, late-ACK handling, first-NACK abort, STOP/bus-free and bounded retry, timeout recovery, bank-cache safety, and reset cases.

The focused runner itself is byte-identical to qualified R1i (`tests/v41/run_r1i_focused_sim.ps1`, blob `47fc3c65b3b73976a41b2821a4606d7ad10a2695`, SHA-256 `D7950823C8145B4059FD1E9DF9BA4BFDCAEA38ED97E9AF213840CDA08264704B`). The protected R1i I2C and autoinit RTL are also byte-identical to the qualified base.

## 3. Supplementary simulation matrix

Evidence directory:

`<PRIVATE_EVIDENCE_ROOT>\supplementary_simulations_contingency_final`

Machine-readable receipt:

`<PRIVATE_EVIDENCE_ROOT>\supplementary_simulations_contingency_final\G2A_SUPPLEMENTARY_SIM_RECEIPT.txt`

Receipt SHA-256:

`D854696B90FDE99D1FDDDA0A0A95B3B14275576453C39AA44B27D486FEAF3105`

Result: **7/7 tests PASS; 18/18 tracked tool commands exited zero; zero failure tokens.**

| Test | Result | Required marker |
|---|---:|---|
| `tb_r1i_poc_mmio` | PASS | `R1I_POC_MMIO_PASS reads=258 writes=32 old_fallback=2 poc_page_bytes=128 formal_zero_bytes=128` |
| `tb_r1h_mmio_read_service` | PASS | `R1H_MMIO_READ_SERVICE_PASS accepted=10 consumed=6 reset_cancelled=4` |
| `tb_r1h_mmio_integration_exhaustive` | PASS | `R1H_MMIO_INTEGRATION_EXHAUSTIVE_PASS aligned_reads=1368 unaligned_reads=4104 forwarded_writes=1368 ordering_pairs=1 reset_cancellations=2` |
| `tb_g0p8c2_producer`, phase 1300 ps | PASS | `G0P8C2R1_PRODUCER PASS expected_dwords=1920 checked_dwords=1920 random_events=1000 random_abort_events=7 phase_ps=1300` |
| `tb_g0p8c2_producer_phase_b`, phase 2700 ps | PASS | `G0P8C2R1_PRODUCER PASS expected_dwords=1920 checked_dwords=1920 random_events=1000 random_abort_events=7 phase_ps=2700` |
| `tb_g0p8c3r1_slot_count` | PASS | `PASS_G0P8C3R1_SLOT_COUNT_REGRESSION` |
| Evidence-only `tb_g2a_axi_lite_host_bridge` | PASS | `PASS G2A_AXI_LITE_HOST_BRIDGE_PROTOCOL checks=41` |

The matrix compiled current source in isolated ASCII-only work directories. Record benches included Vivado `glbl` and elaborated with `xpm`, `unisims_ver`, and `glbl`. Commands, compile/elaboration/simulation logs, source/input hashes, and the hash manifest are preserved beside the receipt.

The receipt separately discloses an informational, non-matrix `vivado -version` banner query whose raw batch-wrapper exit was `1`; it produced the expected 2025.2/build-6299465 version text. The tracked version/compile/elaboration/simulation set is the reported 18/18 zero-exit set, so that informational query is not a test failure and is not used to conceal or override any simulator result.

## 4. Disclosed non-gating legacy exploratory failure

A prior exploratory audit attempted the historical bench `tests/nvp/tb_nvp_autoinit.vhd` and did not obtain a passing legacy run. This result is disclosed; it is **non-gating** for G2A and is not counted as a pass.

The bench was not introduced or modified by G2A. It is byte-identical to the qualified base (blob `5d6465f4fd8d8ddf81c0ea026a413c50ec4609f1`, SHA-256 `FD978BCF86A25B1E12CB5985FD29BA492E8A4F17306F2714896E4A6A295EF495`). Its historical expectations are stale relative to the frozen R1i contract. In particular, the bench text explicitly assumes in its isolated write-address-NACK case that an inherited write transaction continues through all three ACK sample states after a WADDR NACK. Qualified R1i instead requires and implements first-qualified-NACK abort, followed by STOP/bus-free and bounded retry. Therefore this legacy bench is not a valid oracle for the frozen R1i behavior it contradicts.

The exact-base focused R1i suite is authoritative because it is the protected qualified-R1i runner, compares the candidate all-ACK physical transaction stream and outputs against its reference, and explicitly tests the R1i first-NACK-abort, physical SCL qualification, retry/backoff, timeout, bank-safety, and reset semantics. That suite passed on the clean final commit. Protected RTL and both the focused and legacy test sources remained unchanged; no implementation behavior was altered to make either suite pass.

## 5. Gate conclusion

| Offline-test requirement | Result |
|---|---:|
| Final commit/tree and clean source proven | PASS |
| R1i protected identities and MMIO/telemetry identity | PASS |
| XDMA Gen2-only configuration delta and frozen invariants | PASS |
| C2H inactive and H2C backpressured | PASS |
| Provenance positive and negative tests | PASS |
| Inherited Python tests | PASS |
| Authoritative focused R1i simulation | PASS |
| Supplementary MMIO/record/bridge matrix | PASS |
| Source unchanged by tests | PASS |
| Hardware untouched and G2B not started | PASS |

**Final offline-test classification: PASS.** The stale legacy exploratory failure is retained as a disclosed non-gating observation and does not supersede the passing qualified-R1i oracle.
