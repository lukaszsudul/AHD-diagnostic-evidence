# AHD v41 CH3 R2R10R2 — first-failure context offline release

## Result

`PASS_FIRST_FAILURE_CONTEXT_OFFLINE_BITSTREAM_READY`

A reset-only sticky first-failure context was added to the CH3 loader and released through one focused simulation campaign, one synthesis/implementation run, scoped post-route checks, and one bitstream generation call. The DUT was not contacted.

## Scope

- Base source: `b2f80cf4fda1775ab34804a246cb7be61e0ecd62`, tree `fd19d5e27923f69d16d2d8679db85d7813124c37`.
- Released source: `e804b5a865637781f6a0f7e85a3607c284b72ffe`, tree `428ebb18e6f4057f333b78d0f889041ccf136363`.
- Production RTL footprint: one loader file; profile memory, PN execution behavior, I2C master, wrapper, XDMA IP, DMA and all active XDC stayed unchanged.
- Record: three read-only 32-bit MMIO words, captured atomically on the first loader fault, immutable through recovery and MMIO reads, cleared only by the existing module reset.
- No hardware qualification, camera synchronization, capture admission, or product qualification is claimed.

## Focused verification

- XSim cases: 13 total: 11 extended first-failure cases, one pinned-base clean comparison, and one actual MMIO bridge/router/wrapper/SCAN1 regression.
- Host decoder unit tests: 8.
- Clean base and extended I2C command ledgers were byte-identical: 7,229 bytes, SHA-256 `5F231D7A66A24F59B74C71D9ECB0E88CD1D320BFEA9428C2138083EAFE02431B`.
- Covered bank-select failure, verifying read failure, later read/write failure, timeout, readback mismatch, local fault without fabricated I2C context, sticky retention through a later recovery fault, reset-only clearing, and rejected-command behavior.
- The I2C model was transactional; these tests are not physical ACK or analog-timing evidence.

## One implementation

- Full implementation runs: 1/1.
- Fully routed nets: 38,789/38,789; routing errors and unrouted/partial nets: 0.
- Routed resources: 19,725 LUT, 21,712 FF, 28.5 BRAM tiles.
- Delta from the accepted prior routed image: +30 LUT, +153 FF, +0 BRAM tile.
- LUT release limit: 20,384; remaining headroom: 659 LUT.

## Scoped finalization

- Timing: PASS. WNS +0.148 ns, TNS 0.000 ns, WHS +0.036 ns, THS 0.000 ns; setup, hold and pulse-width failing endpoints 0; no missing clock and no unconstrained internal endpoint.
- Final DRC: PASS against the exact accepted warning baseline; 0 errors, 0 critical warnings, 24 accepted warnings.
- Local realized CDC: PASS for the new record, MMIO responder and receiving AXI bridge. All observed sequential relations use `userclk1`; full-project CDC rerun was intentionally outside the scoped release.
- Aggregate bus-skew: PASS, 11/11 active constraints, minimum slack +1.121 ns, one report call.
- Mandatory write-bitstream DRC: ran once, 0 errors. Bitgen completed successfully in one call.

## Private artifact identities

The routed DCP and bitstream are not included.

- Routed DCP: 62,797,045 bytes, SHA-256 `E662906B1248C7E80127E00B5D540B731FF5BD7BC47768B9FF666F736156EB9F`.
- Bitstream: 2,192,144 bytes, SHA-256 `8B910FF5243A95750F7B278AD4924689ED2A084BFE7EB9BAE023373C1DB86010`.
- The DCP size and SHA-256 were unchanged after bitgen.

## Boundaries

```text
QUALIFICATION_SCOPE=LOADER_FIRST_FAILURE_CONTEXT_SCOPED_OFFLINE_RELEASE
HARDWARE_QUALIFICATION=NOT_RUN
NEXT_HARDWARE_RECOVERY_PREPARE_APPLY=SEPARATE_OWNER_AUTHORIZATION_REQUIRED
CAMERA_SYNCHRONIZATION=NOT_ESTABLISHED_BY_THIS_TASK
CAPTURE_ADMISSION=NOT_GRANTED
PRODUCT_QUALIFICATION=NOT_CLAIMED
HISTORICAL_APPLY_R2R10=FAIL_UNCHANGED
HISTORICAL_FAILED_CONTEXT=NOT_RETAINED_UNCHANGED
PHYSICAL_NACK_ROOT_CAUSE=NOT_PROVEN
DUT_CONTACT=SSH=JTAG=LIVE_MMIO=LIVE_I2C=0
DRIVER_OPERATIONS=HARDWARE_LOCK_MUTATIONS=0
HARDWARE_PREPARE=APPLY_A=APPLY_B=HOST_RECOVER=ONESHOT=0
PROGRAM=RESET=REBOOT=POWER_CYCLE=C2H=H2C=DMA=CAPTURE=0
PROFILE_CHANGES=PN_CHANGES=MASTER_BEHAVIOR_CHANGES=DMA_CHANGES=0
```

A future hardware session requires separate Owner authorization for recovery/activation of this exact image, PREPARE, one APPLY_A, immediate record readback before cleanup, and any bounded synchronization check. It does not inherit capture admission.