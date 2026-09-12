# AHD v41 G2B-NVP-CAMERA-ACQ1-COMPAT0-R2 main report

## Result

- Engineering gate: `BLOCKED`.
- Evidence publication: `PASS_ON_REQUIRED_COMMIT_PINNED_REMOTE_READBACK`.
- Overall result: `BLOCKED`.
- First blocker: `ACQ1_COMPAT0_R2_BUILD_PROFILE_COUNTER_PREFIX_COLLISION`.

## Completed gates

The pinned reference order and helper disposition passed. Diagnostic source was
committed and published as `dae2aff60141ecdbc0afac08fc0df9a3166f66c6` with tree `21e33d481ef637667756caa8015e7fa1b1dd8ebf`. PRODUCT
exclusion passed. Inherited SCAN1 tests passed `24/24`; executor/integration
tests passed `20/20`; the combined offline gate passed `44/44`.

## First blocked gate

One fresh Vivado 2025.2 run invoked `synth_design` exactly once. The command
completed with zero errors and zero critical warnings. The immediately following
profile-elaboration evidence gate failed with `build-profile elaboration content mismatch` before
`opt_design`.

The failure is a proven counter-prefix collision in the task-local evidence
harness. The query for reference name `g2b_nvp_camera_scan1` uses a trailing
wildcard and therefore counts both `g2b_nvp_camera_scan1` and its wrapper
`g2b_nvp_camera_scan1_acq1_compat0_r2`. This yields the receipt values
`wrapper=1`, `SCAN1 core count=2`, `executor=1`, and `I2C master=1`. The source
generate chain is mutually exclusive and the wrapper contains one scanner core,
but the failed governed gate was not overridden.

No retry or continuation was made. `opt_design`, placement, physical
optimization, route, CDC reconciliation, timing, DRC, methodology, resource
sign-off, bitstream generation, runtime bundle construction, DUT access,
programming, camera gate, I2C action, capture, and rollback were not reached.

## Preserved state and non-claims

Functional NVP writes are `0`; programming attempts and reboots are `0`; no
task-local hardware root, credential helper, or lock was created. PRODUCT,
SSOT, META, and NVP persistent state are unchanged. The publication contains no
reference source, vendor PDF, bitstream, DCP, XDMA driver, native binary, camera
image, or pixel payload.

## Required closure

A separate Owner-authorized continuation may correct the task-local profile
counter so that its reference-name test is exact rather than prefix-based, then
perform a new fresh build/sign-off. This task cannot reuse or reinterpret the
consumed failed build as PASS.

Generated UTC: `2026-09-12T11:14:37Z`.
