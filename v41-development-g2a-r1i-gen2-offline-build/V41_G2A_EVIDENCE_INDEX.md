# AHD v41 G2A Evidence Index

## Gate and publication identity

- Task: `AHD_V41_G2A_R1I_GEN2_OFFLINE_INTEGRATION`
- Date: `2026-08-28`
- Engineering gate: `PASS`
- Timing classification: `PASS_WITH_TIMING_RISK` (`WHS=+0.024 ns`)
- Qualified base commit: `20c3323d79d3896edc586d6db1df7deee60f9e41`
- Qualified base tree: `70d801fd7a879080da399bfa9ee95fd6eb008e16`
- Integration branch: `integration/v41-r1i-gen2-g2a`
- Integration commit: `224d194e5f82c85bcb29297561c5d5e76d28063b`
- Integration tree: `283f98c02e6f9c61716875415cf000682f8ab856`
- Source branch publication: `PASS`
- Published source ref: `origin/integration/v41-r1i-gen2-g2a`
- Published source commit: `224d194e5f82c85bcb29297561c5d5e76d28063b`
- Evidence repository: `lukaszsudul/AHD-diagnostic-evidence`
- Evidence directory: `v41-development-g2a-r1i-gen2-offline-build`
- Evidence publication: `PASS`
- Evidence payload commit: `bb8be9993726546cad2c120e300afd5499419951`
- Remote read-back: `PASS`
- Hardware accessed: `NO`
- C2H application data plane implemented: `NO`
- G2B started: `NO`

The published source tracking ref and local integration branch resolve to the same commit with ahead/behind `0/0`. The sanitized evidence payload was committed and pushed to `origin/main` without force, then verified from a fresh sparse clone at `bb8be9993726546cad2c120e300afd5499419951`. The evidence publication and remote read-back gates are `PASS`.

## Package layout and counts

| Package area | Indexed files | Disposition |
|---|---:|---|
| Required root contract artifacts | 17 | Includes this index and the final self-excluding SHA-256 manifest |
| Additional root comparison support | 1 | Frozen-donor effective XDMA configuration dump |
| Additional root publication receipt | 1 | Sanitization scope, exclusions, scans, sealed identities, and LFS policy |
| `build/reports` | 43 | Final clean R2 reports and receipts only |
| `build/logs` | 3 | Final clean R2 launch receipt, journal, and log |
| `build/artifacts` | 1 | Final bitstream; no LTX was produced |
| `offline_tests` | 50 | Curated final clean-commit contract and supplementary evidence |
| `reproducibility` | 4 | Minimal evidence-only scripts/bench and exact unit receipt |
| Final package total | 120 | Count after `V41_G2A_SHA256_MANIFEST.txt` is generated |

`V41_G2A_SHA256_MANIFEST.txt` contains 119 entries and hashes every other package file, including this index and sanitization receipt. A manifest cannot include its own digest, so it explicitly excludes itself.

## Required root contract artifacts

| Artifact | Purpose/status |
|---|---|
| `V41_G2A_IMPLEMENTATION_REPORT.md` | Main 21-section implementation and gate report |
| `G2A_PROVENANCE_PREFLIGHT.md` | Exact R1i base/tree, donor, G1, protected-ref, isolation, and planned-change preflight |
| `G2A_XDMA_CONFIG_DIFF.md` | Frozen-donor versus G2A effective/user configuration audit |
| `G2A_XDMA_EFFECTIVE_CONFIG.txt` | Final generated candidate dump of all `1,001` effective `CONFIG.*` properties |
| `G2A_PROVENANCE_HARDENING_DIFF.md` | Hunk-by-hunk secondary-donor provenance adoption record |
| `G2A_C2H_INACTIVE_BOUNDARY_RECEIPT.md` | Exact C2H constant tie-offs, H2C backpressure, and data-plane absence proof |
| `G2A_CLOCK_RECEIPT.md` | Requested/generated/routed clock identity and 62.5 MHz gate |
| `G2A_CDC_RESET_STATIC_REVIEW.md` | Static reset/CDC review plus exact Gen2 XDMA CDC disposition |
| `G2A_RESOURCE_DELTA.md` | Qualified-R1i versus final R2 resource/timing/congestion comparison |
| `G2A_OFFLINE_TEST_REPORT.md` | Final contract, provenance, focused R1i, MMIO, record, and bridge test results |
| `G2A_BUILD_REPORT.md` | Clean R2 flow, stage, timing, DRC, resource, process, and artifact report |
| `G2A_POST_BUILD_VERIFICATION.md` | Post-build source/config/clock/CDC/resource/bitstream verification |
| `G2A_SOURCE_DIFF.patch` | Exact qualified-base-to-integration source patch; no full proprietary source tree |
| `G2A_SOURCE_DIFF_AUDIT.md` | Four-file allowlist, protected-identity, conflict/leakage, and scope audit |
| `V41_G2A_STATE.json` | Machine-readable engineering and publication state |
| `V41_G2A_EVIDENCE_INDEX.md` | This package inventory and publication-boundary receipt |
| `V41_G2A_SHA256_MANIFEST.txt` | Final SHA-256 manifest for every other indexed package file; generated last |

Additional comparison support:

- `G2A_XDMA_FROZEN_DONOR_EFFECTIVE_CONFIG.txt` — frozen Gen1 donor effective-property dump used by `G2A_XDMA_CONFIG_DIFF.md`.

Additional publication support:

- `G2A_PUBLICATION_SANITIZATION_RECEIPT.md` — fail-closed public-payload allowlist, deterministic sanitization checks, artifact identity checks, and package-scoped LFS policy.

## Final clean R2 build reports — 43 files

All paths below are relative to the evidence directory.

1. `build/reports/BLACK_BOXES.txt`
2. `build/reports/BUS_SKEW.rpt`
3. `build/reports/CDC_VIOLATION_OBJECTS.txt`
4. `build/reports/CDC.rpt`
5. `build/reports/CHECK_TIMING.rpt`
6. `build/reports/CLOCK_INTERACTION.rpt`
7. `build/reports/CLOCK_UTILIZATION.rpt`
8. `build/reports/CLOCKS.rpt`
9. `build/reports/CONGESTION.rpt`
10. `build/reports/DRC.rpt`
11. `build/reports/EXCEPTION_COVERAGE.rpt`
12. `build/reports/G2A_BUILD_INPUT_SHA256.txt`
13. `build/reports/G2A_BUILD_PROVENANCE.txt`
14. `build/reports/G2A_BUILD_RESULT.txt`
15. `build/reports/G2A_CDC_EXACT_DISPOSITION.txt`
16. `build/reports/G2A_CLOCK_OBJECT_RECEIPT.txt`
17. `build/reports/G2A_COMPILE_ORDER.rpt`
18. `build/reports/G2A_DEBUG_PROBES_RECEIPT.txt`
19. `build/reports/G2A_EXPECTED_RUNTIME_PROVENANCE.txt`
20. `build/reports/G2A_OPERATION_COUNTS.txt`
21. `build/reports/G2A_PRE_BITSTREAM_HARD_GATE.txt`
22. `build/reports/G2A_ROUTED_XDC_CDC_OBJECT_COVERAGE.txt`
23. `build/reports/G2A_XDMA_IP_PROPERTIES.txt`
24. `build/reports/G2A_XDMA_IP_STATUS.rpt`
25. `build/reports/MAX_DELAY_CFG.rpt`
26. `build/reports/MAX_DELAY_DIAG_GRAY.rpt`
27. `build/reports/MAX_DELAY_STATUS.rpt`
28. `build/reports/METHODOLOGY.rpt`
29. `build/reports/POST_OPT_RESOURCE_GATE.txt`
30. `build/reports/POST_OPT_UTILIZATION_FLAT.rpt`
31. `build/reports/POST_OPT_UTILIZATION_HIER.rpt`
32. `build/reports/POST_SYNTH_TIMING_SUMMARY.rpt`
33. `build/reports/POST_SYNTH_UTILIZATION_FLAT.rpt`
34. `build/reports/POST_SYNTH_UTILIZATION_HIER.rpt`
35. `build/reports/RAM_UTILIZATION.rpt`
36. `build/reports/ROUTE_STATUS.rpt`
37. `build/reports/ROUTED_DESIGN_PROPERTIES.txt`
38. `build/reports/ROUTED_HOLD_TIMING.rpt`
39. `build/reports/ROUTED_RESOURCE_GATE.txt`
40. `build/reports/ROUTED_SETUP_TIMING.rpt`
41. `build/reports/ROUTED_UTILIZATION_FLAT.rpt`
42. `build/reports/ROUTED_UTILIZATION_HIER.rpt`
43. `build/reports/TIMING_SUMMARY.rpt`

The terminal and pre-bitstream receipts establish `BUILD=PASS`, `SOURCE_TO_BIT_PROVENANCE=PASS`, fully routed status, WNS `+0.617 ns`, TNS `0`, WHS `+0.024 ns`, THS `0`, zero DRC errors/critical warnings, zero black boxes, the exact two dispositioned Gen2 XDMA CDC clock views with zero unknown critical findings, 62.5 MHz user/AXI clocks, resource/congestion PASS, and exactly one invocation of every build operation.

## Final clean R2 build logs — 3 files

1. `build/logs/G2A_CONTINGENCY_BUILD_LAUNCH_RECEIPT.txt`
2. `build/logs/vivado.jou`
3. `build/logs/vivado.log`

These are the final R2 launch/process receipt and Vivado journal/log. The receipt records exit code `0`, pre-launch process counts `0/0`, maximum Vivado/all-tool counts `3/3`, post-launch all-tool count `0`, no checkpoint reuse, and `HARDWARE_ACCESSED=NO`.

## Final bitstream and LTX disposition

The sole file in `build/artifacts` is:

- `build/artifacts/AHD_V41_G2A_R1I_GEN2_OFFLINE.bit`

Its SHA-256 is `4F74CC4AC8619B7509D46D74ED919FA81C5C9CC69D7BBDF6F34ED46D363E341E` and its size is `2,192,144` bytes. It is an offline-build artifact only: it was not programmed, loaded, enumerated, or hardware-qualified.

No LTX file is included because none was produced. `build/reports/G2A_DEBUG_PROBES_RECEIPT.txt` records `WRITE_DEBUG_PROBES_ATTEMPTED=YES`, `LTX_PRODUCED=NO`, `LTX_SHA256=NONE`, and `LTX_ERROR=NONE`. No placeholder LTX and no invented digest are published.

## Curated offline-test evidence — 50 files

The authoritative contract run identifier is `20260828T033504016Z_9dc3a634a236444785ceffe9dd32d27d`. Only this clean final-commit run and the final supplementary campaign are included.

### Contract and qualified-R1i campaign — 29 files

1. `offline_tests/contract/G2A_OFFLINE_CHECK_RECEIPT.json`
2. `offline_tests/contract/G2A_OFFLINE_CHECK_RECEIPT.txt`
3. `offline_tests/contract/offline_runs/20260828T033504016Z_9dc3a634a236444785ceffe9dd32d27d/provenance_tests/invalid_mode/vivado.console.log`
4. `offline_tests/contract/offline_runs/20260828T033504016Z_9dc3a634a236444785ceffe9dd32d27d/provenance_tests/invalid_mode/vivado.log`
5. `offline_tests/contract/offline_runs/20260828T033504016Z_9dc3a634a236444785ceffe9dd32d27d/provenance_tests/positive/evidence/G2A_EXPECTED_RUNTIME_PROVENANCE.txt`
6. `offline_tests/contract/offline_runs/20260828T033504016Z_9dc3a634a236444785ceffe9dd32d27d/provenance_tests/positive/vivado.console.log`
7. `offline_tests/contract/offline_runs/20260828T033504016Z_9dc3a634a236444785ceffe9dd32d27d/provenance_tests/positive/vivado.log`
8. `offline_tests/contract/offline_runs/20260828T033504016Z_9dc3a634a236444785ceffe9dd32d27d/provenance_tests/round_trip_mismatch/vivado.console.log`
9. `offline_tests/contract/offline_runs/20260828T033504016Z_9dc3a634a236444785ceffe9dd32d27d/provenance_tests/round_trip_mismatch/vivado.log`
10. `offline_tests/contract/offline_runs/20260828T033504016Z_9dc3a634a236444785ceffe9dd32d27d/python_test_nvp_r1e_tools.log`
11. `offline_tests/contract/offline_runs/20260828T033504016Z_9dc3a634a236444785ceffe9dd32d27d/python_test_nvp_r1f_tools.log`
12. `offline_tests/contract/offline_runs/20260828T033504016Z_9dc3a634a236444785ceffe9dd32d27d/python_test_nvp_r1f_tri_phase_probe_model.log`
13. `offline_tests/contract/offline_runs/20260828T033504016Z_9dc3a634a236444785ceffe9dd32d27d/python_test_nvp_r1i_tools.log`
14. `offline_tests/contract/offline_runs/20260828T033504016Z_9dc3a634a236444785ceffe9dd32d27d/r1i_focused_sim.console.log`
15. `offline_tests/contract/offline_runs/20260828T033504016Z_9dc3a634a236444785ceffe9dd32d27d/r1i_focused_sim/wire_focused/candidate_compile.console.log`
16. `offline_tests/contract/offline_runs/20260828T033504016Z_9dc3a634a236444785ceffe9dd32d27d/r1i_focused_sim/wire_focused/candidate_elaborate.console.log`
17. `offline_tests/contract/offline_runs/20260828T033504016Z_9dc3a634a236444785ceffe9dd32d27d/r1i_focused_sim/wire_focused/candidate_run.console.log`
18. `offline_tests/contract/offline_runs/20260828T033504016Z_9dc3a634a236444785ceffe9dd32d27d/r1i_focused_sim/wire_focused/candidate_xsim.log`
19. `offline_tests/contract/offline_runs/20260828T033504016Z_9dc3a634a236444785ceffe9dd32d27d/r1i_focused_sim/wire_focused/r1h_reference_allack.trace`
20. `offline_tests/contract/offline_runs/20260828T033504016Z_9dc3a634a236444785ceffe9dd32d27d/r1i_focused_sim/wire_focused/r1i_candidate_allack.trace`
21. `offline_tests/contract/offline_runs/20260828T033504016Z_9dc3a634a236444785ceffe9dd32d27d/r1i_focused_sim/wire_focused/reference_compile.console.log`
22. `offline_tests/contract/offline_runs/20260828T033504016Z_9dc3a634a236444785ceffe9dd32d27d/r1i_focused_sim/wire_focused/reference_elaborate.console.log`
23. `offline_tests/contract/offline_runs/20260828T033504016Z_9dc3a634a236444785ceffe9dd32d27d/r1i_focused_sim/wire_focused/reference_run.console.log`
24. `offline_tests/contract/offline_runs/20260828T033504016Z_9dc3a634a236444785ceffe9dd32d27d/r1i_focused_sim/wire_focused/reference_xsim.log`
25. `offline_tests/contract/offline_runs/20260828T033504016Z_9dc3a634a236444785ceffe9dd32d27d/r1i_focused_sim/wire_focused/testbench_compile.console.log`
26. `offline_tests/contract/offline_runs/20260828T033504016Z_9dc3a634a236444785ceffe9dd32d27d/r1i_focused_sim/wire_focused/xelab.log`
27. `offline_tests/contract/offline_runs/20260828T033504016Z_9dc3a634a236444785ceffe9dd32d27d/r1i_focused_sim/wire_focused/xvhdl.log`
28. `offline_tests/contract/offline_runs/20260828T033504016Z_9dc3a634a236444785ceffe9dd32d27d/r1i_focused_sim/wire_focused/xvlog.log`
29. `offline_tests/contract/offline_runs/20260828T033504016Z_9dc3a634a236444785ceffe9dd32d27d/vivado_version.log`

### Supplementary MMIO/record/bridge campaign — 21 files

30. `offline_tests/supplementary/bridge/bridge_xvlog.log`
31. `offline_tests/supplementary/bridge/tb_g2a_axi_lite_host_bridge_xelab.log`
32. `offline_tests/supplementary/bridge/tb_g2a_axi_lite_host_bridge_xsim.log`
33. `offline_tests/supplementary/G2A_SUPPLEMENTARY_SIM_COMMANDS.txt`
34. `offline_tests/supplementary/G2A_SUPPLEMENTARY_SIM_RECEIPT.txt`
35. `offline_tests/supplementary/G2A_SUPPLEMENTARY_SIM_SHA256.txt`
36. `offline_tests/supplementary/mmio/mmio_xvlog.log`
37. `offline_tests/supplementary/mmio/tb_r1h_mmio_integration_exhaustive_xelab.log`
38. `offline_tests/supplementary/mmio/tb_r1h_mmio_integration_exhaustive_xsim.log`
39. `offline_tests/supplementary/mmio/tb_r1h_mmio_read_service_xelab.log`
40. `offline_tests/supplementary/mmio/tb_r1h_mmio_read_service_xsim.log`
41. `offline_tests/supplementary/mmio/tb_r1i_poc_mmio_xelab.log`
42. `offline_tests/supplementary/mmio/tb_r1i_poc_mmio_xsim.log`
43. `offline_tests/supplementary/record/record_xvlog.log`
44. `offline_tests/supplementary/record/tb_g0p8c2_producer_phase1300_xelab.log`
45. `offline_tests/supplementary/record/tb_g0p8c2_producer_phase1300_xsim.log`
46. `offline_tests/supplementary/record/tb_g0p8c2_producer_phase2700_xelab.log`
47. `offline_tests/supplementary/record/tb_g0p8c2_producer_phase2700_xsim.log`
48. `offline_tests/supplementary/record/tb_g0p8c3r1_slot_count_xelab.log`
49. `offline_tests/supplementary/record/tb_g0p8c3r1_slot_count_xsim.log`
50. `offline_tests/supplementary/tool_version.log`

The contract receipt records `RESULT=PASS`, `MODE=CLEAN_COMMITTED`, passing Python/focused/provenance tests, the final commit/tree, and `HARDWARE_ACCESSED=NO`. The supplementary receipt records 7/7 simulations and 18/18 tracked tool commands passing.

## Reproducibility support — 4 files

1. `reproducibility/cdc_disposition_unit_test.tcl` — exact-signature CDC disposition unit harness.
2. `reproducibility/cdc_disposition_unit_test_output/G2A_CDC_EXACT_DISPOSITION.txt` — passing expected-output receipt for that unit harness.
3. `reproducibility/dump_frozen_donor_effective_config.tcl` — frozen-donor effective-property dump helper.
4. `reproducibility/tb_g2a_axi_lite_host_bridge.sv` — evidence-only AXI-Lite bridge protocol bench used by the supplementary campaign.

These files are evidence-only reproduction aids. They are not additional product source changes, are not compiled into the shipped bitstream, and do not broaden G2A into G2B or hardware activity.

## Explicit publication exclusions

The public payload intentionally excludes:

- the full proprietary source repository and all unchanged qualified R1i source files; the exact four-file source delta is represented only by `G2A_SOURCE_DIFF.patch` and its audit;
- R2 design checkpoints `G2A_SYNTH.dcp`, `G2A_POST_OPT.dcp`, and `G2A_ROUTED.dcp`; their independently verified SHA-256 identities remain sealed in the textual build receipts;
- the generated Vivado project, generated IP/HDL/XDC products, `.Xil`, IP cache, implementation database, and all other tool-generated source/output products not named above;
- build, donor-dump, launch, temporary, and cache workspaces outside this curated directory;
- the superseded first clean build, its pre-bitstream failure outputs, and all superseded CDC harness/unit, runner-self-test, precommit, donor-generation, sealed-check, supplementary-simulation, and retry/transient directories;
- duplicate raw copies of the four reproducibility files and all local launcher/helper transients not listed in the package catalogue;
- any secret, credential, hardware-manager, JTAG, DUT, PCIe-enumeration, MMIO, driver, DMA, or throughput artifact; none is required or authorized for G2A;
- an LTX placeholder: `write_debug_probes` was attempted, but no LTX was produced and the receipt records `LTX_SHA256=NONE` and `LTX_ERROR=NONE`.

Only the final clean R2 build reports/logs/bitstream, final clean-commit offline evidence, minimal reproduction aids, and the sanitized textual contract artifacts are indexed for publication. No DCP, generated source tree, transient working directory, or superseded run is part of the public evidence payload.

## Publication and read-back procedure

1. Use the isolated evidence clone/worktree and fetch `origin/main`.
2. Verify the evidence worktree is clean before adding this single curated directory and record the fetched `origin/main` identity.
3. Confirm the package contains exactly the catalogued payload, contains no excluded path, and contains no secret or proprietary full-source material.
4. Add a package-specific Git LFS rule for the bitstream if required by the repository's established binary-artifact policy; verify the staged representation before commit.
5. Generate `V41_G2A_SHA256_MANIFEST.txt` last over every other package file, using repository-normalized relative paths and explicitly excluding the manifest itself.
6. Commit with message `Publish AHD v41 G2A R1i Gen2 offline build evidence`.
7. Fetch again and push fast-forward to `origin/main` without force.
8. Perform independent remote read-back: verify all required names and category counts, JSON validity, bitstream/LFS availability, source patch integrity, and every manifest digest.
9. After those checks pass, record the evidence remote commit and final publication/read-back disposition.

Completed publication receipt: `origin/main` advanced by fast-forward from `0e9a809be891db01ad11373b2cfbdf28679180c4` to payload commit `bb8be9993726546cad2c120e300afd5499419951`. A separate fresh sparse clone reported both `HEAD` and `ls-remote origin/main` at that commit, materialized both LFS objects, and was clean after checkout. The remote payload contained exactly 120 files: 19 root files, 43 build reports, 3 build logs, 1 bitstream, 50 offline-test files, and 4 reproducibility files. All 119 manifest entries matched; the bitstream was 2,192,144 bytes with SHA-256 `4F74CC4AC8619B7509D46D74ED919FA81C5C9CC69D7BBDF6F34ED46D363E341E`, the LFS timing report was 76,996,212 bytes with SHA-256 `1B016342532147122C05AF21F8D604382A4F0EE85EB8F9AE609E776DBE870E30`, the source patch hash matched `BD2796E63CDBBA0AE974691F5F0A6511CBE9B23DE9CA369C9AA24A4837E449A2`, and `V41_G2A_STATE.json` parsed successfully. Result: `REMOTE_READ_BACK=PASS`.

Publication does not authorize FPGA programming, DUT access, C2H implementation, G2B, or any hardware qualification. The final execution point remains `HARD STOP AFTER G2A OFFLINE BUILD`.
