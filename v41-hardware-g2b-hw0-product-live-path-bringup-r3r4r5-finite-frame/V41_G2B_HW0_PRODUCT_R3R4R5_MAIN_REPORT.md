
# G2B-HW0-PRODUCT-R3R4R5 Floating-Point Boundary Correction and Finite-Frame Gate

## Result

- Engineering gate: `FAIL`
- Evidence publication: `SEALED_PENDING_COMMIT_PINNED_REMOTE_READBACK`
- Overall result: `FAIL`
- First blocker: `R3R4R5_FIRST_RECORD_ABI_VALIDATION_FAILED:DISCONTINUITY flag is set;MALFORMED_PRECEDING flag is set`

The fresh R3R4R5 run passed predecessor authority, immutable-boundary, exact
R3R4R4 baseline, authorized-delta, all 16 offline self-tests, independent
architecture, credential-helper, exclusivity, continuity, driver, node-map,
runtime identity, NVP, and fixed-input gates. The sole authorized synthetic
change was `1.400 s -> 1.401 s`; its evaluated span was `0.401 s`. Runtime
quiescence remained five consecutive observations spanning at least 400 ms.

Exactly one hardware session was executed. Reset advanced epoch `2 -> 3`.
Inherited `ERROR_STATUS=0x00000007` was normalized by one exact combined W1C
`0x00000007`, after which the status was zero. The reader was started and the
stream enabled once.

The first persisted 4096-byte record parsed structurally, but carried both
`DISCONTINUITY` and `MALFORMED_PRECEDING`. This violates the frozen capture
acceptance contract, so the run failed immediately and no retry was made. The
record file had already been flushed, fsynced, closed, reopened, and read back;
its disk-derived SHA-256 is
`E92D4DFC7E46F7F3A619A0CA9D184A6E019429533FC96959316BC295C970B5F4`. The payload file and
`FIRST_RECORD_DURABLE` event were correctly withheld because ABI validation
failed.

The failure path preserved `100` complete chunks
(`409600` bytes), plus
`3584` trailing bytes. Disk-based analysis
found `99` later malformed chunks and
`75` padding errors. The post-failure coherent
snapshot recorded `ERROR_STATUS=0x00000007` and
`LAST_ERROR_CAUSE=0x00000003` without clearing
either. Counter reconciliation and frame reconstruction therefore failed or
were not reached.

The safety-disable path completed, parent quiescence passed with five samples
over `400.659` ms, and cleanup passed. The exact
module was normally unloaded once; the endpoint automatically unbound, nodes
were removed, PCIe remained Gen2 x1, AER/kernel health remained clean, and
FPGA `DONE` remained 1.

No raw record, raw UYVY frame, or camera PNG is present in this public package.

## Nonclaims

R3R4R5 does not prove durable first-record hardware PASS, the 2500-record finite
capture, a complete real frame, 60-second capture, 288 MB/s throughput,
two-channel operation, four-input selection, synthetic generation, or V4L2.

## Corrective action

Investigate why the first new-epoch record retained `DISCONTINUITY` and
`MALFORMED_PRECEDING`, and why subsequent captured chunks lost record geometry,
under a new explicit governed authorization. Do not retry this R3R4R5 session.
