# RM1-R1 fresh build failure report

## Governed result

- Fresh, nonincremental one-shot build: `FAIL`.
- Fresh synthesis: `PASS` (`synth_design completed successfully`).
- First explicit failed gate: `RM1_POST_SYNTH_PROFILE_ELABORATION_COUNT_GATE_FAILED`.
- Full implementation, routing, timing, CDC, bus-skew, promoted checks, DRC, methodology, routed DCP and bitstream: `NOT_REACHED`.
- Retry or post-synthesis correction: `NOT PERFORMED`.
- Classification: `RM1_BUILD_BLOCKED`.

## Exact first-failed-gate evidence

The build stopped immediately after synthesis in `rm1_profile_gate POST_SYNTH`:

```text
RM1_WRAPPER_BOUNDARY_COUNT=3173
RM1_ROUTE_BOUNDARY_COUNT=299
RM1_MONITOR_BOUNDARY_COUNT=2839
RM1_ROUTE_STATE_COUNT=6
RM1_MONITOR_STATE_COUNT=7
RM1_SNAPSHOT_BRAM_PRIMITIVE_COUNT=0
FIXED_I2C_MASTER_COUNT=334
R3_CORE_COUNT=0
RTRACK_TRI_PROBE_COUNT=0
RTRACK_HISTORY_COUNT=0
SCAN1_ACQ1_MODE1_BGDCOL_HISTORY_COUNT=0
GENERIC_HOST_NVP_I2C_COUNT=0_BY_SOURCE_CONTRACT
PROFILE_ELABORATION_GATE=FAIL
```

The exact-count probe did not identify one wrapper, one route controller and one monitor after synthesis; it counted thousands of flattened descendant/boundary cells. Snapshot BRAM primitive count was also zero. These measurements fail the required exact profile-isolation proof and cannot be normalized into a PASS.

Vivado also emitted critical warnings that procedural commands in `g2b_nvp_diag2_rm1_cdc.xdc` were unsupported in the XDC context. The explicit build hard stop was the post-synthesis profile elaboration gate; this report does not claim that the XDC warnings caused the count mismatch.

## Frozen identities

- Source commit: `a7436eb81f69f09ee84301bcf214fcaa2b680ee8`.
- Source tree: `cce4a561a30d58d4accc2a45e4eb8d72e5a7ec26`.
- Source remained clean after the failed build: `YES`.
- Corrected task-local harness SHA-256: `145A410AF61EBC06A0AB18FC2470DCCD78ED647821A46B43857A2E61CF828CE4`.
- Pre-Vivado input seal SHA-256: `95235124C3EBED4A1F2F1DB43ADC1C7F443BEDA9A37A3A56C5BE96B616FE6A4F`.
- Focused receipt SHA-256: `D39EB3AA71D90AA0F08DB8BE1747C756F34ADAB33C402E347B8076E490020C77` (`18/18 PASS`).
- Affected R3 receipt SHA-256: `3FC7C8F9F19A71BE4E3D29D2E302A8C2453BB1EDB2FBAD7D56A59F6AB68A364A` (`25/25 PASS`).
- Source read-back receipt SHA-256: `0B16973F5CAFCD97E68AF47B8F44A6AB8BF6CABF3DE2C05C8FA63863EB7D2902`.
- Console log SHA-256: `4EABAD66070F0F17D41CB94AB35B7ED5AE477F3D5F7B4E116C4576926DF292F2` (344859 bytes).
- Post-synthesis profile report SHA-256: `B229EC41D91BEBCFE30F146770C24968F2AECA7E6F7666533D9F1104ADD2E8C7`.
- Build result SHA-256: `ADAD5CFFBC46C36FD2766B11811007A3E39924D5933F719DFD01463D086223ED`.
- One-shot result SHA-256: `CDD21836A7B050A13E255172F87AAB435F84EBDF3B6279B4AD390A6B5510AF83`.

No DUT or hardware access occurred. No DCP, bitstream or RM1 HW1 prompt was created.
