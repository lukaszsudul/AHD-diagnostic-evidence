# Compile-time profile isolation

| Profile | Scanner | Legacy heavy DIAG1 scanner | Executor | I2C release when absent |
|---|---|---|---|---|
| PRODUCT | not elaborated | not elaborated | not elaborated | constant high |
| SCAN1 | elaborated | disabled | not elaborated | executor release constant high |
| future ACQ1 | optional qualified scanner | disabled | elaborated | absent clients release high |

Use independent compile-time constants, with static/elaboration assertions forbidding simultaneous DIAG1 and SCAN1 decode and forbidding executor elaboration in PRODUCT or SCAN1. PRODUCT output logic, active constraints, ABI ranges, capture path and I2C behavior remain byte/source unchanged. No runtime bit may reveal a generic I2C write service.
