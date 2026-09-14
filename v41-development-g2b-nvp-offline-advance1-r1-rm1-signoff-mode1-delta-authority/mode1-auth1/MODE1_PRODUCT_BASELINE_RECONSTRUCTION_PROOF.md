# MODE1 product-baseline reconstruction proof

Result: `FAIL_CLOSED`.

The current v41 source proves a controlled reset at wrapper startup and a deterministic product-equivalent autoinit. It does not prove a MODE1 host action that can invoke the exact same reset/autoinit flow without broader reset effects. More importantly, 27 minimum-set registers are not written by current v41, have no authoritative reset default, and have no safe-read authority in the accepted SCAN0 matrix. Product autoinit therefore cannot reconstruct their pre-MODE1 bytes.

The frozen recovery flow is represented in the graph but may not be selected for these registers. `NVP reset effect known or bounded`, `protected final state verifiable`, and `within existing v41 recovery authority` do not all pass.

Blocked registers:
- `0x00/0x22`
- `0x05/0x05`
- `0x05/0x0E`
- `0x05/0x75`
- `0x05/0xC0`
- `0x05/0xC1`
- `0x05/0xD4`
- `0x09/0x6C`
- `0x0A/0x60`
- `0x0A/0x61`
- `0x0A/0x62`
- `0x0A/0x63`
- `0x0A/0x64`
- `0x0A/0x65`
- `0x0A/0x66`
- `0x0A/0x67`
- `0x0A/0x68`
- `0x0A/0x69`
- `0x0A/0x6A`
- `0x0A/0x6B`
- `0x0A/0x6C`
- `0x0A/0x6D`
- `0x0A/0x6E`
- `0x0A/0x6F`
- `0x0A/0x70`
- `0x0A/0x71`
- `0x0A/0x72`

No `PRODUCT_BASELINE_RECONSTRUCTION` class is assigned merely to avoid exact rollback.
