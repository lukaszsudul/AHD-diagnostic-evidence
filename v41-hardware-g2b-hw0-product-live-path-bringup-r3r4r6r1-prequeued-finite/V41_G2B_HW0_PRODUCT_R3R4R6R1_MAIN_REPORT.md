
# AHD v41 G2B-HW0 PRODUCT R3R4R6R1 Main Report

## Result

- Engineering gate: **FAIL**
- First blocker: `PRIMARY_AIO_FINITE_BUFFER_NOT_FILLED:EXPECTED_10240000_ACTUAL_643072`
- Evidence publication: pending at package construction time
- Owner-confirmed frozen continuity: accepted without requalification

## Outcome

The unchanged R3R4R6 native helper compiled successfully on the authoritative
DUT and passed its no-device smoke test. The focused host-tool gate reached
`6/6 PASS`. Both native AIO requests were accepted before stream enable and
`PREQUEUE_READY` preceded enable by 137.364
microseconds.

The sole hardware session then disproved the required finite-path property.
The primary 10,240,000-byte request completed with only **643072 bytes
(157 whole records)**. The parent issued the authorized safety
disable 111.185 microseconds
after observing that completion and proved physical quiescence with five
accepted samples spanning 401.405
ms.

The coherent final snapshot recorded 163 streamed records and 83,456 streamed
beats, with deltas `dropped=1`, `overflow=1`, and `discontinuity=1`. Therefore
the prequeue hypothesis is **NOT_CONFIRMED** in this experiment. The guard AIO
request did not complete within the authorized 20-second post-quiescence wait
and remained blocked in the kernel with the C2H descriptor open. It was not
signal-interrupted or killed. Normal module unload was not attempted because
the task-owned AIO/descriptor remained active (`module refcount = 1`). Locks
remain held to protect that unsafe rollback state.

No primary buffer was persisted, so record-integrity, continuity, BT.656 flag,
and frame-reconstruction decisions are `NOT_REACHED`; no raw camera data was
published. Minimal kernel-health deltas contained no Oops, BUG, AER, IOMMU,
DMA-API, link-down, or XDMA fatal signature.

## Nonclaims

- Continuous 60-second performance: `NOT_RUN`
- Hardware throughput >=288 MB/s: `NOT_PROVEN`
- Two-channel, four-input, synthetic-generator, and V4L2 qualification: not performed
- No FPGA programming, reboot, Flash access, or power cycle occurred
