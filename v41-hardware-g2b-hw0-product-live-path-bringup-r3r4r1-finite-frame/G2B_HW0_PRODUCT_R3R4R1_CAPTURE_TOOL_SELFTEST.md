# R3R4R1 capture-tool offline self-test

- Result: `FAIL / BLOCKED`
- Completed PASS cases: `4/11`
- Failed case: `PARENT_QUIESCENCE_HANDSHAKE_PASS`
- First blocker: `R3R4R1_CAPTURE_TOOL_HARD_GATE_FAILED`
- Governed rerun: `NO`
- Capture tool or self-test modified after failure: `NO`
- Hardware access: `NO`
- DUT connections: `0`

| Case | Result |
|---|---|
| `FIRST_RECORD_PERSISTENCE_PASS` | `PASS` |
| `PARTIAL_READ_ASSEMBLY_PASS` | `PASS` |
| `PRIMARY_2500_BOUNDARY_PASS` | `PASS` |
| `DRAIN_CAPTURE_PASS` | `PASS` |
| `PARENT_QUIESCENCE_HANDSHAKE_PASS` | `FAIL` |
| `FAILURE_PRESERVES_RAW_DATA_PASS` | `NOT_REACHED` |
| `EXCEPTION_DETAIL_PASS` | `NOT_REACHED` |
| `COMPLETE_FRAME_RECONSTRUCTION_PASS` | `NOT_REACHED` |
| `EXACT_CAPTURE_HASH_PASS` | `NOT_REACHED` |
| `NO_BLANK_BLOCKER_PASS` | `NOT_REACHED` |
| `NO_RAW_RECORD_IPC_PASS` | `NOT_REACHED` |

## Corrected partial-read criterion

The invalid chunk-call-count assertion is absent and was not replaced by any
chunk-call versus record-count comparison.

| Semantic check | Result |
|---|---|
| `chunk_smaller_than_4096` | `PASS` |
| `chunk_larger_than_4096` | `PASS` |
| `cumulative_boundary_unaligned` | `PASS` |
| `chunk_spans_multiple_records` | `PASS` |
| `more_than_one_chunk` | `PASS` |
| `complete_records_2507` | `PASS` |
| `reconstructed_stream_byte_identical` | `PASS` |
| `primary_records_2500` | `PASS` |
| `primary_bytes_10240000` | `PASS` |
| `drain_records_7` | `PASS` |
| `drain_bytes_28672` | `PASS` |
| `trailing_bytes_zero` | `PASS` |
| `primary_hash_independently_matches` | `PASS` |
| `drain_hash_independently_matches` | `PASS` |

## New exact failure

The actual completion vector was
`[false,false,false,false,false,true,true]`; the test expected
`[false,false,false,false,false,false,true]`. The mismatch occurs at t=2.8
seconds, already 1.4 seconds after the last data event. This is an offline test
expectation defect, not a hardware result.
