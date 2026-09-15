# AHD v41 CONT1R2 Main Report

## Outcome

Engineering Path B completed successfully: `PASS_RETRIED_NACK_REPRODUCED_CHARACTERIZED_NO_FUNCTIONAL_WRITES`.

The 10,000-scan zero-error gate itself classified `FAIL_RETRIED_NACK` after the first recovered NACK at qualification scan 7. That scientific result did not authorize functional writes. The controller recorded 10 recovered NACK events within the Owner-authorized global limit, encountered no hard-stop event, performed zero functional NVP writes, and completed normal cleanup.

## Frozen authority

- Source commit/tree: `dae2aff60141ecdbc0afac08fc0df9a3166f66c6` / `21e33d481ef637667756caa8015e7fa1b1dd8ebf`
- Bitstream SHA-256: `CFA58A46572094209997F6B1A3A5A033BF4E8C8A71EC261A5BBF1833B8BCF91B`
- CONT1R1 evidence commit: `01b443170bbddb7de1589d534977395ebebfa154`
- FPGA source/build/manifest/projection/MMIO changes: `NONE`
- Runtime continuity: `REUSED_EXACT_VOLATILE_RUNTIME`; programming attempts `0`, warm reboots `0`

## Gates

- Prior event replay: `PASS`; raw SHA-256 `671D570715F53E6E1EEB74ADCB7BF08D18C24223FFB191CDE9B8436D89509C6D`
- Host integrity controller: `18/18 PASS`
- Local and DUT closed-bundle gates: `PASS/PASS`
- Driver/PCIe: `PASS`, `0000:01:00.0`, `Gen2 x1`
- SCAN1/ACQ identities: `PASS/PASS`
- MMIO sanity: `16/16` and `16/16`
- Control scan: `PASS`, `105/105`, NACK/retry `0/0`
- Qualification: `7/10000`; first recovered event at scan 7
- All recorded scans: `65`; clean 105-transaction scans `56`; projections `65`
- Recovered NACK/retry events: `10/10`
- Timeout/bank-verify/incomplete/mutation/hard-stop: `0/0/0/0/0`
- Functional/unauthorized writes: `0/0`
- Cleanup: `PASS`

## Characterization

The event targets were dispersed across seven `(bank, register)` pairs rather than confined to the inherited Bank7/0xF4 event. Every retry completed with `VALUE_VALID`, `RETRIED`, `BANK_VERIFIED`, and no final error code. The frozen encoding does not retain the exact first-attempt NACK protocol phase after a successful retry; therefore that phase is `NOT_ENCODED`, not inferred.

The bounded fast campaign comprised 7 qualification scans and 57 additional same-cadence scans. Ten recovered events reached the global limit, making the spaced arm safely not applicable. This evidence supports an intermittent cadence-associated first-attempt NACK phenomenon, but does not localize it to a single register, bank, channel, scanner RTL defect, NVP defect, or physical root cause.

## Fail-closed disposition

The physical camera gate, two-register baseline, idempotent rewrite, slice search, format identification, and rollback were not reached. Mode, EQ, capture, generic host I2C, programming, reboot, Flash, and power-cycle remained absent.

## Transparent integration record

The first isolated bundle attempt exposed a missing bundle-root import bootstrap and stopped before hardware access. A later unprivileged runtime invocation stopped on device permission before MMIO; the accepted governed sudo path then passed. The first cleanup diagnostic used a whole-boot kernel regex and caught historical SATA messages outside the task window; the final task-scoped diagnostic passed without hardware mutation. Each stopped attempt is preserved locally and did not execute an NVP operation.

## Cleanup and publication

The scanner, executor, and I2C bus ended idle; stream was disabled; pending AIO was zero; all 65 scans restored the entry bank; the driver unloaded normally; XDMA nodes disappeared; the DUT lock and then controller lock were released. Private raw snapshots, credentials, driver, bitstream, DCP, vendor material, and camera data are excluded from this public set.
