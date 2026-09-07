
# R3R4R5 Counter Reconciliation

- Result: `FAIL`
- Host complete records: `100`
- Host trailing bytes: `3584`
- records attempted delta: `148`
- records committed delta: `101`
- records streamed delta: `101`
- beats streamed delta: `51712`
- Expected beats for host complete records: `51200`
- records dropped delta: `47`
- overflow-count delta: `47`
- discontinuity delta: `7`
- records abandoned delta: `0`
- last global / channel: `100 / 147`

The captured session terminated at the first-record validation failure; the
2500-record equality contract was not reached. No reconciliation PASS is claimed.
