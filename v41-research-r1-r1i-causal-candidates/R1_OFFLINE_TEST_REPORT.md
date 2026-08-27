# AHD v41 R1 Offline Test Report

## Result

**PASS.** Both committed candidates passed their candidate-specific contract tests, the inherited R1i lifecycle and safety coverage, all three frozen MMIO simulations, and all 40 host-side decoder/statistics fixtures before either candidate entered a full Vivado build.

Every Xilinx offline-test process used Vivado Simulator 2025.2 build 6299465 with `XILINX_LOCAL_USER_DATA=NO`, the canonical Tcl app repository, and a short ASCII-only candidate-local TEMP/TMP directory. Test input hashes were recorded before and after execution.

## Candidate A — C1 selected first-HIGH ACK sample

The full inherited lifecycle suite was retained. Its one stimulus that encoded qualified R1i's removed late-sample behavior was hash-guarded and adapted only for mode-1 ACK timing: end-of-LOW NACK, first filtered-HIGH ACK, and terminal live NACK. All inherited assertions, transaction counts, recovery checks, and postconditions remained active across the complete 825-opportunity run.

Results:

- Reference and candidate all-ACK lifecycles passed with 275 transactions and 825 ACK-phase bytes.
- The complete C1-aware inherited mode passed all 825 formerly false-early opportunities.
- Reference and candidate all-ACK trace SHA-256 values are identical: `7C5D7F767B2E9CAEB1B587D3F258C295AD0F454141B2A8C84240B966133A4B49`.
- Held ACK and held NACK passed for WADDR, REGADDR, DATA and RADDR; each terminal decision remained exactly 26 controller cycles from ACK-state entry.
- Delayed filtered HIGH passed with a 34-cycle decision interval.
- A broken HIGH interval invalidated the first selection, resampled the completing interval, and passed with a 44-cycle decision interval.
- The terminal decision used the held selected value, not live or raw SDA.
- Missing qualification followed the inherited recovery path.
- First-NACK abort, no later phase after NACK, legal STOP, BUS_FREE, retry/backoff, terminal exhaustion, bank invalidation, read behavior and passive early telemetry passed through inherited coverage.

The immutable qualified-R1i mode-1 late-sample assertion was also run and produced the expected semantic mismatch against C1. It is not presented as a product defect or silently counted as a pass. R0 explicitly defines C1 to remove that later ACK sample point, so retaining that single assertion as an acceptance criterion would contradict the frozen candidate contract. The hash-guarded C1 adaptation is therefore the superseding form of that inherited test: it changes only the obsolete ACK stimulus/expectation while preserving the complete 825-opportunity lifecycle, all inherited safety assertions and every postcondition. On that contract-correct basis, Candidate A's focused-test gate is PASS.

## Candidate B — C2 endpoint qualification

Results:

- Ten static source-contract checks passed, including the exact 14-state ordinary-HIGH set, divider independence, endpoint guard, reuse of the existing x07 recovery path, and absence of any selected-sample latch or new timeout constant.
- Endpoint-HIGH passed: the divider ran from state entry, live filtered SDA was sampled at the terminal endpoint, and progression occurred normally (`dwell=21`).
- Endpoint-LOW passed: SDA was not sampled, no ACK opportunity was counted, no later phase was entered, and the exact existing recovery dispatch was recorded (`dwell=21`).
- The full inherited qualified-R1i simulator suite passed without a candidate-aware semantic substitution.
- STOP_B, STOP_C and BUS_FREE retained their physical filtered-SCL qualification.
- First-NACK abort, phase suppression after NACK, retry ladder, terminal exhaustion, bank invalidation, reads, telemetry and recovery all passed.

## MMIO and telemetry regression

Both candidates produced all three frozen pass markers:

- `R1I_POC_MMIO_PASS reads=258 writes=32 old_fallback=2 poc_page_bytes=128 formal_zero_bytes=128`
- `R1H_MMIO_READ_SERVICE_PASS accepted=10 consumed=6 reset_cancelled=4`
- `R1H_MMIO_INTEGRATION_EXHAUSTIVE_PASS aligned_reads=1368 unaligned_reads=4104 forwarded_writes=1368 ordering_pairs=1 reset_cancellations=2`

The MMIO address map, access types, legacy fallback, telemetry packing, formal-zero page, read service ordering, reset cancellation and forwarded-write behavior are unchanged. All seven MMIO source/test hashes matched before and after each suite.

## Host fixtures

Each candidate passed the same 40 Python tests:

- 16 R1f decoder/statistics tests;
- 8 tri-phase probe-model tests;
- 16 R1i decoder, ABI, provenance and safety-policy tests.

`PYTHONDONTWRITEBYTECODE=1` was used, and the seven script/test/fixture hashes were stable pre-run and post-run.

## Evidence

Sanitized final receipts and logs are under `offline_tests/candidate_a` and `offline_tests/candidate_b`. Simulator databases, WDB files, compiled work directories, backups, and superseded development harness attempts are excluded.
