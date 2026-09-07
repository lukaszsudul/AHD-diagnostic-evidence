# G2B-HW0-PRODUCT-R3R4R2 Capture-Tool Diff

- Result: `PASS`
- Authorized tool delta: `QUIET_WINDOW_EXPECTATION_PLUS_RUN_IDENTITY_ONLY`
- Runtime quiet-window implementation changed: `NO`
- Only semantic change: corrected case-5 expected completion vector

| Active file | Allowed delta | Result |
|---|---|---|
| `capture_r3r4.py` | `RUN_IDENTITY_ONLY` | `PASS` |
| `capture_r3r4_selftest.py` | `QUIET_WINDOW_EXPECTATION_PLUS_RUN_IDENTITY` | `PASS` |
| `frame_reconstruct_r3r4.py` | `RUN_IDENTITY_ONLY` | `PASS` |
| `abi_v1.py` | `BYTE_IDENTICAL` | `PASS` |
| `V41_C2H_TRANSPORT_ABI_V1.json` | `BYTE_IDENTICAL` | `PASS` |
| `Invoke-R3R4R2DutConnection.ps1` | `RUN_IDENTITY_ONLY` | `PASS` |
