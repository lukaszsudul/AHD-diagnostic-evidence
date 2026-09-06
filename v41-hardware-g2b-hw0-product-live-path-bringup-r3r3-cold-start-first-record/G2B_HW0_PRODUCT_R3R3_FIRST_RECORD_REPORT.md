# First-record report

T3 gate: BLOCKED.

The task-owned reader handled partial reads and assembled exact 4096-byte boundaries. A first complete record event was delivered within the 10-second limit; the parent then wrote the single normal disable. The reader reports 53 complete records total: 1 primary and 52 bounded-drain records, with 0 incomplete trailing bytes.

The worker exited during bounded drain before its in-process quiescence proof. The parent stopped at R3R3_ROLLBACK_UNSAFE_ACTIVE_DMA before persisting the record buffer or invoking the frozen ABI validator. Consequently:

- first record bytes assembled: 4096
- first record SHA-256: NONE
- payload SHA-256: NONE
- raw first record/payload retained locally: NO — NOT_PERSISTED_AFTER_CAPTURE-TIME_BLOCKER
- little-endian header: NOT_REACHED
- payload geometry: NOT_REACHED
- zero padding: NOT_REACHED
- record epoch: N/A
- host-observed fixed 4096-byte boundary: PASS
- direct TKEEP/TLAST hardware observation: NOT_PERFORMED

No raw camera bytes exist in this public package. No deterministic pixel claim is made. A fresh read-only assessment later proved physical DMA quiescence, but it cannot reconstruct or validate the lost record bytes and does not authorize a retry.
