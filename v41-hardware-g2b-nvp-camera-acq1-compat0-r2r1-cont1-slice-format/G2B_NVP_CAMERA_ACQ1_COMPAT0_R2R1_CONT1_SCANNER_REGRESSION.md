# SCAN1 regression

Overall required regression: `FAIL`

- single ONESHOT hardware transactions: `82/82 entries`, `10/10 groups`, `105/105 transactions`
- snapshot publication: `PASS`
- entry bank / exit bank: `0x00 / 0x00`
- entry-bank restore: `PASS`
- A8 bookends: `0x0F / 0x0F`
- NACK: `0`
- timeout: `0`
- bank-verify failures: `0`
- single-scan host qualification: `FAIL`
- repeated regression: `0/32 NOT_REACHED`

First failure: `SCAN1_CONFIGURATION_PROJECTION_INCOMPLETE`. The frozen controller requires `01:88`, `01:89`, `01:8A`, and `01:8B` in its configuration projection, but the frozen 82-entry manifest does not scan those addresses. No retry was performed.
