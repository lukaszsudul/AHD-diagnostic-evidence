# Fresh build report

## Governed result

- Vivado: `2025.2`, SW build `6299465`.
- Fresh nonincremental build attempt: `1`.
- `synth_design` invocations: `1`.
- Vivado command result for `synth_design`: completed successfully with `0` errors and `0` critical warnings.
- Governed fresh-synthesis gate: `FAIL`.
- `opt_design/place_design/phys_opt_design/route_design`: `0/0/0/0` invocations.
- Bitstream writes: `0`.
- Checkpoint reuse: `NO`.
- Hardware accessed: `NO`.
- Raw build error: `build-profile elaboration content mismatch`.
- First blocker: `ACQ1_COMPAT0_R2_BUILD_PROFILE_COUNTER_PREFIX_COLLISION`.

## Root cause

The post-synthesis profile counter intentionally accepts either a terminal
instance-name match or a reference-name match. Its reference-name clause uses
the prefix expression `string match "${ref_name}*"`. The query for
`g2b_nvp_camera_scan1` therefore counts both the wrapper reference
`g2b_nvp_camera_scan1_acq1_compat0_r2` and the one nested scanner reference
`g2b_nvp_camera_scan1`. The receipt is consequently `wrapper=1`,
`SCAN1_CORE_COUNT=2`, `ACQ1_EXECUTOR_COUNT=1`, `I2C_MASTER_COUNT=1`, while the
source generate chain is mutually exclusive and the wrapper contains one
scanner core. This proves a profile-evidence counter prefix collision; it does
not authorize overriding the failed gate.

The build exited before writing the synthesis checkpoint. No retry, harness
patch, implementation continuation, DCP, bitstream, or DUT action was performed.

- Build-result SHA-256: `1EFE5CEA1009D0BA1777D946D035D660822D6E8813787714501366F2D4B4185E`.
- Profile-receipt SHA-256: `BCAB82C627E3F1ABCD0864B7B399AEFB268A6B2704B2C5B969C9B2D31EA3B735`.
- Operation-count SHA-256: `7640F9753C4700425C0AFF3D51C2BF65CA180A0B62115BE4C6CC5996208997C5`.
