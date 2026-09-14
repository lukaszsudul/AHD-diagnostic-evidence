# G2B NVP DIAG2-RM1 final offline gate receipt

## Passed offline gates

- Focused simulation: `18/18 PASS`
- Route-controller integration: `PASS`
- Parser-tap integration: `PASS`
- Source drift during focused gate: `NO`
- Focused receipt SHA-256: `D39EB3AA71D90AA0F08DB8BE1747C756F34ADAB33C402E347B8076E490020C77`
- Inherited/affected R3 regression: `25/25 PASS`
- Protected R3 inputs: `BYTE_IDENTICAL`
- Affected receipt SHA-256: `3FC7C8F9F19A71BE4E3D29D2E302A8C2453BB1EDB2FBAD7D56A59F6AB68A364A`
- Final static harness gate: `PASS`
- Static receipt SHA-256: `BAD0D802034A34EC5281D62884B10040D9E849FAEC9C9E8E1543333BCE4F6EEE`
- Source commit/read-back: `PASS`
- Hardware accessed: `NO`

The static harness gate includes three deterministic post-parse receipt-swap
negative tests, case-alias omnibus rejection, exact 14-entry pre-Vivado
authority with the fixed R3 donor, exact path/SHA binding, XDC positive and
negative structural mocks, PowerShell/Tcl syntax checks, and byte-current hash
verification.

## Build disposition

- Full build: `FAIL`
- First failure: `RM1_PRE_SYNTH_TCL_PUBLICATION_RECEIPT_PATTERN_INVALID_COMMAND_NAME_BACKSLASH_T`
- CDC sign-off: `NOT_REACHED`
- WNS/WHS/LUT: `N/A`
- Signed-off DCP: `NONE`
- Bitstream: `NONE`
- RM1 classification: `RM1_BUILD_BLOCKED`
- RM1 HW1 prompt: `NONE`

Offline behavioral PASS is not implementation sign-off and does not authorize
hardware execution.
