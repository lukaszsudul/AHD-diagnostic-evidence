# W3 telemetry independent semantic review

Scope: read-only review of `source/rtl/g2b/g2b_nvp_camera_w3_telemetry.sv` at SHA-256 `E545FB629F3269168C626E7768A4EEA1D77EE7409439D84ED250D6DA71FEA587` and scanner integration at SHA-256 `46488440CC33FEB9A4CD7FC34F727D87D3F3302D91FC691B1749B67DA5BF0855`, against the frozen `contract/W3_CONTRACT.json` and user T11–T27. This is static review evidence, not a substitute for dynamic assertions.

Reviewed: exact MMIO header addresses and schema digest; control admission/reject priority and read latency; first and terminal event sources, failure cause namespaces and record field packing; scan/transaction identity and tick origins; per-scan slot validity, retained record validity and BRAM read masking; same-kind successful sample validity; saturating counter read-modify-write service; writer queues, scan admission and freeze ordering.

Issues found and corrected by the telemetry owner during review:

1. Registered command-accepted and done pulses needed a one-cycle timestamp correction to refer to their actual master edges.
2. Immediate subsequent scanner admission could let an older companion writer publish a slot in the new scan. Armed admissions now wait for writer drain; unarmed legacy admissions cancel an old companion write, leave partial physical words invalid, and set the overrun flag.
3. Payload revision needed an increment when the companion froze; explicit clear also needed to reset `terminal_seen`, and a clear-caused revision wrap needed a visible flag.
4. A later terminal group select could overwrite the first failed entry's original select/verify context. The first record now preserves that context; unrelated later cleanup is not linked to the earlier entry.
5. Same-operation/related identity needed both scan sequence and transaction sequence, with the wrap flag consulted.
6. A retained successful-control sample without a valid sample must expose zero data words rather than stale sample words.

At the reviewed SHA, no further actionable field packing, retention, BRAM validity, counter service, control admission, or writer-capacity mismatch was found by this static pass. The bounded dynamic gate remains the W3 test plan and final guarded Vivado simulation/build evidence; especially injected failure and near-admission overlap scenarios cannot be proved solely from source inspection.
