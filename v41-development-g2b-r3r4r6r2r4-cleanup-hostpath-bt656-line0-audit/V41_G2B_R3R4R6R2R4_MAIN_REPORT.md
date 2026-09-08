
# AHD v41 — G2B-HW0-PRODUCT-R3R4R6R2R4

## Decision

- Engineering gate: **PASS**
- Overall result: **PASS_MINIMAL_DIAGNOSTIC_REQUIRED**
- Evidence publication result is established by the final commit-pinned remote
  read-back and reported by the governing Codex response.

## Outcome

The retained R3R4R6R2R3 state was closed safely. The preserved 10,240,000-byte
primary capture remains available and was accessed read-only. One cleanup-only
RESET_STREAM_STATE transitioned epoch 3 to 4 and established five-sample
physical quiescence over 400.413 ms. The abandoned counter changed by 0 rather
than the earlier expected 4; this is retained as a nonblocking operational-state
deviation because the ring was empty and the subsequent targeted cleanup passed.
PID 6055 exited after exactly one SIGTERM, the exact driver unloaded normally,
the nodes disappeared, and the exact retained locks were released. No reboot
was used.

The corrected host path places a direct MMIO disable before every log write,
flush, fsync, persistence, hash, snapshot, parse, report, or subprocess action.
The parent sends `DISABLE_ISSUED` only after that write; the native helper then
starts primary persistence. Progress metadata is memory-buffered during active
capture. Guard capacity is 128 record-granular IOCBs, with cancellation after
parent quiescence only. The deterministic gate is **12/12 PASS**. No new capture
was authorized, so the <=500-us hardware latency remains a next-run criterion.

Read-only forensics independently confirmed 2500 integral records and global
sequence 0..2499. The independent overflow event is record 441. Frame-boundary
records 575 and 1654 each follow line 1079 with next-frame line 1, each add
exactly 21 malformed observations and one drop, and each carry flags 0x34.

Unmodified-RTL XSim passes the existing full regression. A focused simulation
driven through line 1079 with the project's documented synthetic VBI marker
commits next-frame line 0 with SOF and then line 1 with zero malformed delta.
It also proves the conditional old-lock admission behavior: when lock is zero,
line 0 is parsed but not admitted, then its valid EAV relocks for line 1. The
hardware boundary's attempt gap and drop disprove that lock-only behavior as the
sole root. The exact +21 sequence cannot be reproduced because the repository
does not contain an authoritative cycle-accurate NVP6134C boundary marker trace.

Therefore:

`ROOT_CAUSE_NOT_PROVEN_RAW_MARKER_OBSERVABILITY_REQUIRED`

No speculative RTL/NVP/XDC correction, branch, worktree, commit, build, or
bitstream was created. The minimal next action is one bounded marker/state event
trace around a single line-1079-to-next-frame boundary, as specified in the
diagnostic plan.

## Preserved subqualifications and nonclaims

- finite committed-record transport: `PASS_INHERITED`
- rolling 1024 AIO window: `PASS_INHERITED`
- primary 2500-record integrity: `PASS_INHERITED`
- primary global transport sequence: `PASS_0_TO_2499_INHERITED`
- source admission: `DIAGNOSTIC_REQUIRED`
- complete real frame: `NOT_YET_PROVEN`
- 60-second capture / >=288 MB/s / two channels / four inputs / V4L2: not tested
- next full finite rerun authorized by this task: `NO`
