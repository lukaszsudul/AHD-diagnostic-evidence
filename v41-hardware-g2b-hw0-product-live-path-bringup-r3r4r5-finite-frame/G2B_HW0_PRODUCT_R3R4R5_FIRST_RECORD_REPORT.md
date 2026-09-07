
# R3R4R5 First Record Report

- Persistent first-record gate: `FAIL`
- First blocker: `R3R4R5_FIRST_RECORD_ABI_VALIDATION_FAILED:DISCONTINUITY flag is set;MALFORMED_PRECEDING flag is set`
- Persisted bytes: `4096`
- Record file flush/fsync/close/reopen boundary: `COMPLETED`
- Hash source: `REREAD_PERSISTED_FILE`
- Record SHA-256: `E92D4DFC7E46F7F3A619A0CA9D184A6E019429533FC96959316BC295C970B5F4`
- First record equals primary offset zero: `YES`
- Structural header parse: `PASS`
- Flags: `0x00000034` (`VALID`, `DISCONTINUITY`, `MALFORMED_PRECEDING`)
- Disqualifying continuity flags: `DISCONTINUITY; MALFORMED_PRECEDING`
- Payload geometry in record: `3840 bytes (PASS)`
- Padding: `192 zero bytes (PASS)`
- Dedicated payload file: `NOT_CREATED` because validation failed before payload persistence
- FIRST_RECORD_DURABLE event: `WITHHELD`
- Raw first record published: `NO`
