# R1h MMIO transaction and latency test plan

## Identity and scope

Reference source: `e112a5addb7ac62700a9a71af81bf368fad0bada`, tree `3a59ebec130103055d24a3a32ecda00dedde5534`.

This is a test specification only. It did not execute a compiler, simulation, synthesis, implementation, or hardware action.

## Golden-model rule

Instantiate the exact R1g combinational decoder as the reference in simulation only. For every candidate request, sample the R1g value and all relevant valid/count metadata on the exact candidate request-handshake edge. Compare the candidate response transaction after ignoring its bounded implementation latency.

The comparison tuple is:

```text
(accepted request ordinal, address, expected 32-bit data, OKAY status)
```

The candidate must return exactly one tuple in the same order. No cycle-by-cycle equality is required for response latency.

## Required unit tests

1. Exhaust every aligned address from `0x20a0` through `0x35fc`; compare value and response order against the R1g decoder.
2. Test all unaligned low-bit patterns at every range boundary; require zero and `OKAY`.
3. Test every reserved/hole word in `0x20a0..0x35ff`; require zero and `OKAY`.
4. Write and read all 64 records, all six words per record, with independent nonconstant data in every 32-bit bank.
5. Verify record 64 is stored, failure 65 sets overflow without overwrite, and all unused records read zero without payload clear.
6. During a write to row `k`, read an already-valid different row `j`; require the exact old row value.
7. Request the not-yet-valid row on the append edge; require zero for that request and the full atomic 192-bit record on later requests.
8. For every phase, write and read index entries 0 through 511, including independent high/low patterns that detect swapped halves.
9. Check packed words `{index[2w+1],index[2w]}` for every `w=0..255` and each phase.
10. With an odd stored count, require the last lower half valid and the upper half exactly zero.
11. Verify entry 512 is the last stored index and entry 513 only sets overflow; no overwrite.
12. Simultaneously write a new index and read an already-stored different entry from the same phase memory.
13. Hold `rsp_ready=0` for randomized intervals in every response class; require `rsp_valid` and `rsp_rdata` stable.
14. Hold a second request valid while a first request is in each wait/response state; require no second handshake and no duplicated response.
15. Assert AXI reset during record wait, index-low wait, index-high wait, and response backpressure; require pending state/valid to clear and no stale response after release.
16. After payload writes, assert only NVP-POR metadata reset; require every logical payload read to return zero without physically clearing RAM.
17. Drop and restore `axi_aresetn` without NVP POR; after restart require payload visibility according to the persisted NVP metadata.
18. Test R1f/R1g-range writes at `0x20a0`, `0x2200`, `0x2400`, `0x2a00`, `0x2e00`, and `0x3200`; require unchanged forwarding to the application request channel and no diagnostic-service request.
19. Integrate through `v41_axi_lite_host_bridge`; delay the service response and AXI `RREADY` independently. Require one AXI response, stable data, and `RRESP=OKAY`.
20. Present application and local response stimuli in standalone negative tests; assertions must catch any illegal simultaneous response sources.
21. Run the complete decoded fixture set and compare exported JSON/CSV values byte-for-byte with R1g fixtures.
22. Run the formal-image complete-range model over every aligned diagnostic address; require deterministic zero.

## Latency and liveness gates

Measured from service request acceptance, with `rsp_ready=1`:

```text
SCALAR_RESPONSE_MAX_CYCLES=1
FAILED_RECORD_RESPONSE_MAX_CYCLES=2
PACKED_INDEX_RESPONSE_MAX_CYCLES=3
```

If the selected XPM output-register configuration adds one documented cycle, these limits may each increase by exactly one only when frozen before the equivalence run. The limit may not depend on address contents or observed data.

Backpressure may extend only the `RESP` state. Every non-reset accepted request must eventually reach `RESP` within the frozen class-specific bound.

## Coverage gates

```text
MMIO_TRANSACTION_LEVEL_EQUIVALENCE=PASS_ALL_ADDRESSES
MMIO_RESPONSE_ORDER_ERRORS=0
MMIO_DUPLICATE_RESPONSES=0
MMIO_LOST_RESPONSES=0
MMIO_BACKPRESSURE_STABILITY=PASS
MMIO_PENDING_REQUEST_ACCEPTS=0
MMIO_RESET_STALE_RESPONSES=0
DIAGNOSTIC_WRITE_FORWARDING=BYTE_IDENTICAL
FORMAL_R1H_RANGE_ZERO_FIXTURE=PASS
```

`SOURCE_MUTATIONS=0`

`FULL_BUILDS=0`

`HARDWARE_ACTIONS=0`
