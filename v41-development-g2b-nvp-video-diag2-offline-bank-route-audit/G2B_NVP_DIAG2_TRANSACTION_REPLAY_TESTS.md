
# Transaction replay self-tests

| Test | Result |
|---|---|
| bank selection | PASS |
| direct write | PASS |
| masked write with known initial value | PASS |
| masked write with symbolic initial value | PASS |
| later override | PASS |
| per-channel expansion | PASS |
| deterministic replay | PASS |

The canonical trace contains 840 rows, seven named layers, zero use-before-bank-select events, zero invalid bank/address events, and zero unresolved source operations.
