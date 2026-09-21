# AHD v41 CH3 R2R10R3 — single APPLY with first-failure record

## Result

Engineering result: **FAIL_WITH_FIRST_FAILURE_CONTEXT**.

The exact R2R10R2 diagnostic image was activated once in volatile SRAM, followed by one planned warm reboot and admission of the qualified runtime. PREPARE completed successfully. The one authorized APPLY_A ended with loader terminal code 5 (`LOADER_ERR_READBACK`) after automatic recovery. The new sticky record remained coherent and localized the first mismatch.

## Activation and admission

- Source commit/tree: `e804b5a865637781f6a0f7e85a3607c284b72ffe` / `428ebb18e6f4057f333b78d0f889041ccf136363`.
- Private bitstream: 2,192,144 bytes, SHA-256 `8B910FF5243A95750F7B278AD4924689ED2A084BFE7EB9BAE023373C1DB86010`; the binary is not published.
- Programming attempts: 1; warm reboot attempts: 1.
- Runtime source identity, exact driver, endpoint-to-user-BAR mapping, autoinit, idle/quiescent conditions, `CAMP_VIRGIN`, and an empty reset record all passed.
- Autoinit NACK counter: 0.

## PREPARE and APPLY_A

- PREPARE write attempts: 1. First response was busy after 6.300326 ms. It completed after 100.124761 ms with `CAMP_PREPARED`, terminal 0, and an empty record.
- APPLY_A write attempts: 1. First response was busy after 10.728636 ms. It completed after 480.730894 ms with raw status `0xC3FFCB42`, `CAMP_RECOVERED`, and terminal 5.
- The first application read after each terminal status was the record header. The complete MMIO ledger contains no orphan, short, exceptional, or retried command access.

## Retained first failure

The coherent record reports:

- origin `APPLY_A`, variant A;
- accepted command at PC 310;
- confirmed and expected-matching Bank7 context;
- read of register `0xF0`;
- returned data `0xFF`;
- loader readback fault;
- no transport fault, no valid raw I2C cause, and no timeout.

The pinned source maps PC 310 to a constant readback check of register `0xF0` against `0x34`. This localizes the first loader mismatch. It does not prove why the codec returned `0xFF`, and it does not establish a physical root cause.

The historical REGADDR_NACK was **not reproduced as a REGADDR_NACK** in this attempt.

## Bounded branch and cleanup

The post-APPLY scan branch was not entered because APPLY_A failed. ONESHOT and snapshot ACK counts are zero. Fresh CH3 synchronization, CH3-to-VDO1 route readiness, and post-APPLY CH2 observation remain untested.

One normal unload of the exact owned module completed. The endpoint was unbound, XDMA nodes/FD/maps were absent, AIO was zero, and both task locks were released. The volatile image remains active; the last measured loader state before unload was `CAMP_RECOVERED` with the first-failure record valid.

## Boundaries

```text
ANALYZER_MODE=RECORD_ONLY
TRACE_STATUS=NOT_COLLECTED
PHYSICAL_NACK_ROOT_CAUSE=NOT_PROVEN
CH3_SYNC=NOT_TESTED
ROUTE_CONFIG_VERIFIED=NOT_RUN
PRODUCT_QUALIFICATION=NOT_CLAIMED
CAPTURE_ADMISSION=NOT_GRANTED
APPLY_B=HOST_RECOVER=C2H=H2C=DMA=CAPTURE=PNG=0
NEW_RTL=PROFILE_CHANGES=PN_CHANGES=MASTER_CHANGES=DRIVER_CHANGES=0
XSIM=SYNTH=OPT=PLACE=PHYS_OPT=ROUTE=BITGEN=NEW_SIGNOFF_REPORTS=0
```
