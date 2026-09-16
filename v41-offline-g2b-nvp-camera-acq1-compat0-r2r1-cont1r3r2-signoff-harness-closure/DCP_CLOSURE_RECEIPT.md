# CONT1R3R2 existing-DCP closure receipt

Status: `CHECKPOINT_SIGNOFF_RECOVERED_FOR_SUBSEQUENT_BITSTREAM_GENERATION_TASK`, contingent on append-only evidence publication and commit-pinned remote byte read-back. This requalifies the *unchanged* final provisional checkpoint; it does not generate another routed design or an FPGA image.

## Exact authority

- Source branch `diag/v41-g2b-nvp-camera-cont1r3r1-bram-recovery-20260916T105442Z`, commit `09cd7cbb426027acaefd0cf3989579b80a451f3a`, tree `c6be008ddc387c1f43eefa35d4fed0e2ccb968db`, tracked worktree clean.
- Vivado 2025.2, build 6299465; part `xc7a35tcsg325-2`; top `ahd_capture_top_xdma`.
- Final provisional DCP: `C:\FPGA\G2B_NVP_CAMERA_ACQ1_COMPAT0_R2R1_CONT1R3R1_20260916T105442Z\signoff\CONT1R3R1_SIGNED_OFF_ROUTED.dcp`; 17,469,233 bytes; SHA-256 `C09145B1397E2A8DC972E435E755917C9104A5FDA2E5EF297FE4628EF9672CC2`. The private task-local copy has the same size and hash. The earlier routed DCP, SHA-256 `804CB25D89DF3729A65D2771B892738AC2D580E2921AF48CAE1C5C28D76BC208`, is an identity/reference artifact, not a substitute candidate.

## Resolved comparison gate

The historical comparator mixed a database-restored A timing view with an as-open B timing view. The first sign-off wrapper compared pre- versus post-`reset_timing`/`read_xdc` captures; the third finalizer compared restored A against the final DCP's freshly reopened B. Its `canonicalize_xdc` was text processing, while its surrounding restoration path mutated the in-memory timing database. The historical A/B raw XDC hashes differ, but their 97 ordered executable constraint commands are identical after expansion of only generated read-only `_xlnx_shared_iN` selector aliases; command-stream SHA-256 `12A2080ADB2957FB48F56433830CC64FB92B328BA0156B357ECA0DAB8F36DE50`.

The corrected task-local comparison uses the frozen [comparison contract](COMPARISON_CONTRACT.md) plus its narrow [addendum](COMPARISON_CONTRACT_ADDENDUM.md). Tests: XDC 10/10, report-body 4/4, artifact/tool rejection 3/3, real authority gate PASS. The final candidate and original routed reference were independently reopened as stored, without external XDC, `reset_timing`, implementation or checkpoint writes. Both have the same as-open B XDC, ordered commands, clocks, 119,180 per-net route-property records, netlist/LOC/BEL, and 38,667/38,667 fully routed nets. Complete per-net route exports match byte-for-byte at SHA-256 `02B912E829DFA2502D99F650E7533AD0A2EE543B20B0CA373DA99F8E0CB7FBFD`; their 3.56 GB raw files remain private. Physical `set_property` (49) and waiver (8) commands retain exact order and scope. No meaningful A/B constraint, property, target or route difference remains unresolved in the audited delta.

Five as-open report families (exceptions including ignored, clocks, clock networks, CDC) match in ordered bodies after excluding only generated `Date` and `Command` header fields. The initial timing-summary difference was a methodology-report cache section and was *not* stripped; a separate fresh session ran the identical methodology report on both as-open DCPs before timing reporting, retaining all 18 warnings, then timing-summary bodies matched. Raw report bytes remain unequal and are never claimed identical. Methodology body differences were limited to the input-DCP-derived floorplan identifier, with the same 18 warnings, zero errors and zero critical warnings. The global bus-skew report and promoted checks were inherited by exact design/route/constraint linkage, not rerun here.

## Sign-off coverage and disposition

| Gate | Result and provenance |
| --- | --- |
| Fully routed | PASS, 38,667/38,667 nets; zero unrouted/partial, fresh as-open identity plus inherited timing receipt. |
| Timing/coverage | PASS, WNS +0.047 ns, TNS 0, WHS +0.036 ns, THS 0, internal unconstrained endpoints 0; fresh candidate report confirms. |
| Resources | PASS, LUT 19,738/20,800 (94.894%, below governed 20,384 ceiling), FF 21,538/41,600, BRAM 28/50, DSP 0/90; inherited gate. |
| CDC | PASS under accepted profile-specific semantic manifest V1; 1,337 raw rows, including 427 critical and 874 warning rows, with zero unreconciled critical/warning rows. Raw severities are retained, not called zero. Fresh as-open CDC body matches. |
| DRC | PASS; 0 errors, 0 critical warnings, 24 ordinary warnings; inherited gate. |
| Methodology | PASS; 0 errors, 0 critical warnings, 18 ordinary warnings; inherited gate and fresh candidate confirmation. |
| Active bus-skew | 11/11 met, 0 violations; inherited source-DCP receipt linked by exact command, full route and design identity. Not rerun. |
| Promoted replacements | 17/17 PASS; inherited source-DCP result linked by exact design identity. Not rerun. |

No synthesis, optimization, placement or routing occurred in CONT1R3R2. No RTL, master, scanner manifest, host projection, project XDC, SSOT, META or PRODUCT file changed. No bitstream exists from this task; there was no DUT contact, programming, reboot, scanner campaign, NVP write or camera operation. The prior FAIL and `DO_NOT_PROGRAM_UNQUALIFIED_DCP.md` remain historical records. This receipt supersedes only that former mixed-view comparator gate for these exact bytes, after successful publication; it is not PRODUCT promotion, a camera result or permission to program an ungenerated bitstream.
