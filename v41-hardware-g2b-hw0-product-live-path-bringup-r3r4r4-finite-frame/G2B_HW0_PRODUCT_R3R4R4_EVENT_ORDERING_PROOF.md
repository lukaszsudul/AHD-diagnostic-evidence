# G2B-HW0-PRODUCT-R3R4R4 Event-Sequence Ordering Proof

| Field | Result |
|---|---|
| Formal result | `PASS` |
| Proof basis | `EVENT_SEQUENCE_PLUS_EXPLICIT_DEPENDENCY` |
| Monotonic timestamp used as causal proof | `NO` |
| Equal-timestamp case | `PASS` |
| Target-before-durable negative case | `PASS` |
| FIRST_RECORD_DURABLE sequence | `6` |
| PRIMARY_TARGET_REACHED sequence | `7` |
| Dependency at target acceptance | `FIRST_RECORD_DURABLE_SUCCESS` |
| Runtime capture semantics changed | `NO` |

Both accepted events deliberately used the same informational timestamp; sequence and the active dependency guard proved ordering.
