# W3a lean offline resume: final engineering result

Task `CONT1R3R4R6-W3-R1-LEAN-RESUME`; 2026-09-17. The interrupted W3 worktree had exactly two real candidate revisions at resume, no candidate-3 source or build, and no old worker writing its run root. Its original records and prepublication `PENDING` report were preserved. The already existing final remote read-back receipt for old evidence commit `d4d023f60579a9cf272e6242541f349be361c769` was bound again to the 54-file local staging and its self-excluding 53-row manifest: PASS. The original report was not rewritten.

The remaining third revision became reduced W3a commit `70266f0b90c6fc6a853495eba1d526b285fd7286`, tree `5f2bd8377985406b45433418b20be8993399bcb6`, branch `diag/v41-g2b-w3a-lean-resume-20260917T193348Z`. The private source branch push and independent commit-pinned 47-file byte read-back passed. The source is a clean isolated worktree. Frozen build manifest SHA-256: `2CA4660A9AE81099E230E573D6A40EC28BE411A9F867A00A87B04F1F7677D4F8` (40 selected inputs). The primary checkout, active XDC, SSOT and capture path were not edited.

## Scope and resource result

Candidate 2's post-opt excess was 3,390 LUT over 20,384. Same-stage hierarchy shows 3,321 LUT and 5,151 FF inside its wide W3 telemetry child; whole-design logic LUT grew by 3,588 while LUT-as-memory was unchanged at 1,324. Candidate 3 replaced that broad child with a retained primary bank-failure/cleanup record and guarded OFF/ON control, and retained the inherited SCAN1 BRAM, snapshot, 82 entries, 10 groups and capture transport. The 18,750-clock post-successful-bank-write pause is default OFF; this contract was statically reviewed, with no new dynamic timing measurement. Its W3a child measured 184 LUT/289 FF/no BRAM.

The sole candidate-3 Vivado run completed synthesis and `opt_design`, then stopped at `POST_OPT_LUT_GATE_FAILED:20456`: **72 LUT above** the governed limit. Post-opt logic/memory LUT: 19,132/1,324; FF: 21,833; RAMB36/RAMB18: 26/4. The reduction against full W3 candidate 2 is 3,318 LUT; the remaining increase over stable parent is 270 LUT. The hard gate correctly prevented place, route, timing/CDC/DRC/methodology/bus-skew sign-off, routed DCP reopen and bitstream. Final firmware path, size and SHA-256: **NONE**. No fourth revision is authorized.

## Verification and limitations

`XSIM_NEW_RUNS=0`; no new simulator or formal campaign was run. New RTL simulation is `NOT_RUN_OWNER_REQUESTED_SPEEDUP`. Host import/self-test validated the exact W3a contract without opening a device; the branch read-back proved bytes, not RTL behavior. Parent tests for unchanged source and candidate-2 pause measurements remain historical with their own source identities. The old full W3 T01–T32 matrix is superseded for this reduced scope, not a new pass. Behavioral assurance is `LIMITED_STATIC_REVIEW_AND_IDENTIFIED_HISTORY`.

Elaboration/synthesis found no new W3a port-width, implicit-net or truncation warning. Generated XDMA IP emitted the connection warnings; inherited scanner unused-register messages were present in candidate 2 as well. Synthesis reported zero errors and zero critical warnings. A wording discrepancy remains in the new JSON contract: status bit 1 is named `SCANNER_NOT_IDLE`, while the RTL asserts it during active scanner states 1–9 only. The host uses it as an active-scan guard and hardware rejects unsafe control writes; any next candidate should correct that label and validate it under a new source identity. This is separate from the first failed resource gate.

## Disposition

- **Engineering gate:** FAIL, first blocker `POST_OPT_LUT_GATE_FAILED:20456` against 20,384; 3/3 revisions used.
- **Evidence publication:** see separate remote read-back receipt; this field is not inferred from a successful push.
- **Hardware qualification:** NOT_RUN. `DUT_CONTACT=NONE`, `PROGRAMMING=0`, `NEW_HARDWARE_SCANS=0`, `CAMERA_FRAMES=0`.
- **Original full W3 scope:** `SUPERSEDED_BY_W3A_NOT_COMPLETED`.

Next action: obtain an explicit new candidate budget and make a targeted reduction of more than 72 post-opt LUT with the W3a status-label correction, then rerun the complete governed offline gates before any hardware use. No W4 activity is authorized by this result. A later W4 would use endpoint `10.132.1.111:22` only after fresh identity and BDF/device mapping, with one bitstream/configuration and OFF/ON as the single variable. The previously required 10,000-scan gate is not silently waived; any earlier frame demonstrator needs a separate explicit criterion. A real first frame still requires confirmed single-channel signal/format and configuration plus a complete real C2H transfer to Linux. MMIO data or a synthetic pattern is not a camera frame.
