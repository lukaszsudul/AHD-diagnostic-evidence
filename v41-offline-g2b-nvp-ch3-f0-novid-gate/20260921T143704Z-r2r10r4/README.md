# AHD v41 CH3 R2R10R4 — offline review of the F0/NOVID gate

## Scope

This append-only package summarizes an offline review of retained R2R10R3 evidence and pinned sources. No DUT, driver, MMIO, I2C, FPGA tools, simulation, build, programming, reset, DMA, or capture operation was performed.

Owner attested that two cameras are connected and that the target camera is on physical CH3. This is continuity context, not a fresh A8/F0 measurement.

## Findings

- The documented chain is physical CH3 → NVP channel index 2 → Bank7 F0/F2/F3 → Bank0/A8 bit 2 (NOVID_03) → loader ch3_novid.
- Historical two-camera evidence showed reactions on logical CH2 and CH3. It remains historical evidence; the current second connector was not inferred.
- Retained PREPARE evidence proves that the hardware F0 read at PC38 returned 0x34; PREPARE completed cleanly and its first-failure record was empty.
- The first APPLY failure was PC310, Bank7/F0: returned 0xFF, expected 0x34, readback fault, with no transport/raw-cause/timeout flag.
- Because PC307 completed before the first failure and the terminal retained NOVID bit 0 through recovery, NOVID_03=0 at PC307 is source-reconstructed. The full A8 byte was not retained. PC307 and PC310 were sequential samples about 4.784 ms apart, not a simultaneous or continuous-lock observation.
- F2/F3, CH2 post-check, route write/readback, restore, and normal END were not reached. route=0 is therefore not evidence of a route or DMA fault.
- The public datasheet identifies per-channel F0 as a format classifier but does not provide the TVI 0x34 code or a first-read stabilization guarantee. The pinned reference maps 0x34 to TVI1080p25 and uses a 200 ms detection wait plus three-sample debounce behavior.

## Decision

Keep F0=0x34 as the final TVI1080p25 criterion. A single immediate PC310 comparison is not source-justified as a guaranteed first-sample readiness test.

The one recommended next action is a separately authorized minimal loader revision with a bounded detector-readiness window after static PC306 checks and before CH2 protection and route configuration:

- wait 200 ms, then sample A8_PRE → F0/F2/F3 → A8_POST with bank selection and verification;
- require three consecutive complete samples with F0 0x34 and NOVID_03 zero at both boundaries;
- use at most five complete samples, 1.2 s absolute deadline, and 55 I2C transactions;
- classify dynamic not-ready separately from NACK/readback failure;
- retain immediate hard-stop behavior for transport, bank, static readback, CH2 protection, sequence, and MMIO errors.

The 200 ms and three-sample choices have pinned-code precedent. Five samples and the 1.2 s bound are explicit experimental design assumptions, not manufacturer guarantees.

## Boundaries

HISTORICAL_APPLY_R2R10=FAIL_REGADDR_NACK_UNCHANGED
HISTORICAL_APPLY_R2R10R3=FAIL_PC310_F0_READBACK_UNCHANGED
HISTORICAL_REGADDR_NACK_ROOT_CAUSE=NOT_PROVEN
CURRENT_NVP_STATE=NOT_MEASURED
CH3_CURRENT_SYNCHRONIZATION=NOT_ESTABLISHED_BY_THIS_OFFLINE_TASK
NEXT_IMPLEMENTATION_OR_HARDWARE=SEPARATE_OWNER_AUTHORIZATION_REQUIRED
CAPTURE_ADMISSION=NOT_GRANTED
