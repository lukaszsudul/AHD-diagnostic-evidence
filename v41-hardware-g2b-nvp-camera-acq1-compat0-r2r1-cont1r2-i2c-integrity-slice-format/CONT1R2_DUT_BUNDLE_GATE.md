# CONT1R2 DUT Bundle Gate

- Local isolated gate: `PASS`
- DUT isolated gate: `PASS`
- Manifest SHA-256: `3189BF6849F675B60C21C1C1F21BB57AF4EB522FEACAAE099342AB08FC760D9A`
- Aggregate bundle identity: `55263E503D129CEF49854C4EFFF0B8148FE1637F7C57430EB93CA96BF4FAA6C4`
- Payload/deployed file counts: `55/58`
- Unresolved local imports: `0`
- Missing resources: `0`
- Module-origin violations: `0`
- Entrypoint smoke tests: `PASS`

Attempt 1 was preserved after the isolated entrypoint lacked an explicit bundle-root bootstrap. The task-local launcher/runtime gate was corrected, retested, and repacked without changing FPGA source, SCAN1 manifest, projection, MMIO, or ACQ semantics.
