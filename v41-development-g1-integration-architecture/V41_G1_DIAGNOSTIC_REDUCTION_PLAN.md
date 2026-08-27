# AHD v41 G1 Diagnostic Reduction Plan

## Decision

No diagnostic logic is removed in G1, G2A, or G2B. The qualified R1i image remains the causal and behavioral oracle while the independent R-track is open. Reduction is a later, separately reviewed productization change; it must be justified by diagnostic value, ABI commitments, and causal closure, not LUT pressure alone.

The minimum production observability is a compact, saturating error/status bank containing `INIT_DONE`, `INIT_ERROR`, total qualified NACK, retry exhausted, SCL timeout, bank-safety failure, FIFO overflow, DMA/drop/error counters, and per-channel state. Counters required to prove data loss or distinguish a source failure from a PCIe failure remain product logic.

## Classification rules

- `KEEP_IN_PRODUCT`: required for field safety, serviceability, data-integrity accounting, or the stable host contract.
- `KEEP_UNTIL_R_TRACK_COMPLETE`: may carry the evidence needed to establish or refute the exact R1i causal mechanism. It cannot be removed while R-track conclusions are incomplete.
- `REMOVE_AFTER_R_TRACK`: a candidate for removal only after the causal report closes, retained evidence is archived, an address-compatibility decision is approved, and a post-removal regression proves no functional fanout.
- `UNKNOWN`: evidence is insufficient to make a safe lifecycle decision. The owner must decide at a later gate.

## Feature disposition

| Diagnostic feature | Current evidence/role | Classification | Eventual action and proof obligation |
|---|---|---|---|
| `INIT_DONE`, `INIT_ERROR` | Product initialization state | KEEP_IN_PRODUCT | Keep stable and latched; define reset and sticky semantics in the product ABI. |
| Total qualified NACK | Field health and bus/device failure discriminator | KEEP_IN_PRODUCT | Keep a saturating counter and clear/snapshot policy. |
| Retry-exhausted and unrecovered transaction count | Terminal initialization/transaction failure | KEEP_IN_PRODUCT | Keep at least aggregate count plus a compact last/first terminal-error code. |
| SCL timeout count and maximum wait or timeout indication | Detects a wedged/slow bus and protects recovery | KEEP_IN_PRODUCT | Keep timeout count; maximum-wait detail may be reduced only after R-track review. |
| Bank-valid/bank-safety failure | Prevents unsafe register-bank assumptions | KEEP_IN_PRODUCT | Keep an error bit/counter whenever banked access remains in the product. |
| FIFO overflow, descriptor overflow | Direct proof of application data loss | KEEP_IN_PRODUCT | Keep per-channel attempts, stored, streamed, dropped, and overflow counts. |
| DMA protocol/error counters | Separates source/ring/AXIS/PCIe/host faults | KEEP_IN_PRODUCT | Keep sticky protocol error, reset epoch, and streamed-record counters. |
| Per-channel state and physical-input mapping | Required to interpret a two-active-of-four product | KEEP_IN_PRODUCT | Keep enable/state/input mapping and last-error cause. |
| Early versus qualified ACK samples | Central to the unresolved timing-causality question | KEEP_UNTIL_R_TRACK_COMPLETE | Preserve exact counter meanings and sample points until the causal report is accepted. |
| Raw/qualified/recovered/unrecovered comparison | Separates observation from retry recovery | KEEP_UNTIL_R_TRACK_COMPLETE | Preserve through causal closure; later retain only aggregate product counters if approved. |
| Success-on-retry 1/2/3 and extended retry detail | Quantifies recovery distribution and causal sensitivity | KEEP_UNTIL_R_TRACK_COMPLETE | Candidate for aggregation after R-track; retry behavior itself is never removed. |
| First early-false/recovered/unrecovered serials | First-event correlation for the R investigation | KEEP_UNTIL_R_TRACK_COMPLETE | Archive final evidence, then consider compact last-error replacement. |
| Post-initialization tri-phase I2C probe campaign | Active research measurement, not required for normal bring-up | REMOVE_AFTER_R_TRACK | Remove only after proving it has no functional fanout and is no longer required to validate the causal model. |
| 10,000-transaction probe-index histories | Deep campaign history, including BRAM-backed indexed records | REMOVE_AFTER_R_TRACK | Candidate for removal after evidence archival and an ABI/version plan; do not silently alias the old addresses. |
| 64 failed-transaction records and extended six-word histories | Deep failure reconstruction | REMOVE_AFTER_R_TRACK | Replace, if approved, with compact first/last terminal error plus aggregates. |
| AXI-clock lifecycle campaign instrumentation | Research evidence for clock/link/reset interaction | KEEP_UNTIL_R_TRACK_COMPLETE | Reclassify only after Gen2 clock/reset evidence and R-track closure. |
| Detailed maximum wait and per-phase measurement records | Useful for timing causality but larger than production minimum | KEEP_UNTIL_R_TRACK_COMPLETE | Later keep a timeout/health summary and remove deep detail if owner-approved. |
| ILA/VIO/debug helper sources | Source presence does not prove active implementation cost | UNKNOWN | Establish active synthesized instances and production debug need before any keep/remove decision. |
| Future second-channel debug depth | Not implemented or measured | UNKNOWN | Size from failure observability and resource/timing evidence at the two-channel gate. |

## Protected register consequences

The qualified legacy map through `0x35FF` and R1i telemetry page `0x3600–0x367F` remain exact throughout G2. Removing research logic later cannot silently change address responses, read latency, backpressure, or meanings. A later productization gate must choose and document one of these owner-approved strategies:

1. retain a compatibility responder with frozen counters/summary values;
2. retain the instrumentation in release builds;
3. introduce an explicitly versioned product ABI while preserving legacy-image identification; or
4. deprecate the page under an approved host-software migration.

Unused addresses remain deterministic; removal cannot expose stale BRAM contents or create a new alias.

## Reduction sequence after R-track closure

1. Seal the accepted causal report and the last full-diagnostic bitstream/source/evidence identities.
2. Produce an elaborated hierarchy and same-stage utilization delta for each proposed removal group.
3. Prove every proposed signal has diagnostic-only fanout. Any control, retry, timeout, bank, reset, or timing fanout reclassifies it as functional until proved otherwise.
4. Approve the MMIO compatibility/version decision before deleting storage or counters.
5. Remove one group at a time in a dedicated gate: probe campaign, deep histories, extended comparison counters, then debug helpers.
6. Run the complete protected R1i functional suite, exhaustive MMIO equivalence, CDC/reset checks, implementation/timing, and hardware initialization regression.
7. Compare product counters against the sealed full-diagnostic oracle under identical fault scenarios.

## Acceptance criteria for a production-minimum image

- NVP bring-up timing, ACK qualification, STOP/BUS_FREE, retry/backoff, timeout, and bank safety are bit-for-bit or behaviorally proven unchanged.
- All retained counters have documented width, saturation, epoch, snapshot, and clear semantics.
- Application data loss remains countable end to end for each logical channel.
- Host software can identify image/ABI version before interpreting optional research pages.
- Removed logic has a measured same-stage utilization and timing delta; estimates alone do not justify release.
- The R-track owner explicitly confirms the removed evidence is no longer needed.

## Gate conclusion

The reduction strategy is `PASS` as a plan. Execution is intentionally deferred. R1i diagnostic overhead is real but not yet safely removable, and no future resource shortfall authorizes bypassing causal or compatibility review.
