# G2B-HW0-PRODUCT-R3R4R3 Ordering Proof

| Field | Result |
|---|---|
| Formal result | `FAIL` |
| Failed case | `FIRST_RECORD_PERSISTENCE_PASS` |
| Expected | `DURABLE_MONOTONIC_NS_LT_TARGET_MONOTONIC_NS` |
| Actual relation | `TIMESTAMPS_EQUAL` |
| Numeric event timestamps | `NOT_PERSISTED` |
| Clock implementation | `GetTickCount64()` |
| Clock resolution | `15.625_ms` |
| Program-order dependency | `PROVEN` |
| Suite rerun | `NO` |

The strict distinct-tick assertion is not a valid proof requirement on this clock. No correction was made in this governed run.
