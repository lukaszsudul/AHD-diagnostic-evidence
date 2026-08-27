# AHD v41 R1 — R1i Causal-Isolation Candidates

Engineering gate: **PASS**  
Evidence publication: **PASS**  
Hardware accessed: **NO**  
Final execution point: **HARD STOP AFTER R1 OFFLINE BUILDS**

This directory publishes the sanitized offline implementation, test, build and provenance evidence for exactly two direct-sibling candidates derived from qualified R1i commit `20c3323d79d3896edc586d6db1df7deee60f9e41`.

| Candidate | Commit | Contract/tests/build | Timing | Bitstream SHA-256 |
|---|---|---|---|---|
| R1i-a / C1 | `8b8ec0fa9c22965e46d0421c25e63d83e7971597` | PASS / PASS / PASS | WNS +0.617 ns; WHS +0.036 ns | `847B2ECE6BAD25A5802677D0125EF0C6A12C87B949E0AD96954500F30434534D` |
| R1i-b / C2 | `e4d10bb8e85e3797d078144fd0965e9625ee727c` | PASS / PASS / PASS | WNS +0.617 ns; WHS +0.036 ns | `2092322C1C7A06A727691D8A666623FFE1C460CDD7B445DCD836293CAC5E5C1D` |

C1 selects the first filtered-HIGH ACK value from the completing qualified interval while preserving the C3 physical waveform and terminal decision tick. C2 lets the ordinary protocol-HIGH divider run from entry but requires filtered SCL HIGH at the endpoint before sampling or progression, otherwise reusing the qualified recovery path.

Both candidates change only `rtl/nvp/nvp6134c_i2c_bringup.vhd` synthesizably. All 231 other qualified tracked files are byte-identical, the branches are direct siblings, and cross-contamination is absent.

The two valid builds used separate fresh roots with no checkpoint reuse. An earlier Candidate B wrapper race created two delayed Vivado startup processes; both were terminated before project creation or any design operation and the root was quarantined. The contained incident is recorded in `builds/PRE_PROJECT_LAUNCH_INCIDENT_RECEIPT.txt` and did not contribute an artifact.

Start with:

- [R1 implementation report](R1_IMPLEMENTATION_REPORT.md)
- [candidate comparison](R1_CANDIDATE_COMPARISON.md)
- [offline test report](R1_OFFLINE_TEST_REPORT.md)
- [clean build report](R1_BUILD_REPORT.md)
- [source-diff audit](R1_SOURCE_DIFF_AUDIT.md)
- [runtime identity report](R1_RUNTIME_IDENTITY_REPORT.md)
- [evidence index](R1_EVIDENCE_INDEX.md)
- [machine-readable state](R1_STATE.json)

No SSH/DUT connection, JTAG, hardware-manager, programming, MMIO, PCIe, DMA, driver, reboot or power-cycle operation was performed. R2 was not started.
