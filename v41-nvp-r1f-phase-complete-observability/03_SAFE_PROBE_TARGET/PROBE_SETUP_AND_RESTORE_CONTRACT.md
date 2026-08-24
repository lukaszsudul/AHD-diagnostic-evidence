# R1f Data-Probe Setup and Restoration Contract

## Frozen target

```text
R1F_PROBE_BANK=0x00
R1F_PROBE_REGISTER=0x85
R1F_PROBE_DATA=0x00
TARGET_REGISTER_NAME=SPL_MD_CH1
DATA_PROBE_SIDE_EFFECT_CLASS=IDEMPOTENT_SAME_VALUE_WRITE_WITH_PRE_POST_READBACK
```

This contract is mandatory.  It is not a recovery algorithm: every failed
gate aborts the probe, releases SCL/SDA, preserves the failure evidence, and
classifies the probe result as invalid.  It must not improvise another target.

## Setup sequence

1. Wait for the original autoinit terminal `init_done` event and require
   `init_busy=0`.
2. Require the original master to release both SCL and SDA and require stable
   synchronized bus-idle high.
3. Read Bank Select register `0xFF`; save the returned byte as
   `probe_entry_bank`; require a successful transaction and a valid byte.
4. If `probe_entry_bank != 0x00`, write `{0xFF,0x00}`.
5. Read `0xFF` and require exact value `0x00`.  Do not access the target unless
   this verified bank gate passes.
6. Read target register `0x85`; require transaction success and exact value
   `0x00`.  Store it as `safe_target_pre_value`.
7. Only after steps 1-6 pass may the round-robin phase probe begin.

Any failed setup step sets:

```text
PROBE_ABORTED=1
PROBE_DONE=0
PROBE_RESULT=INVALID_ACTIVE_PROBE_SETUP_OR_RESTORE
PROBE_RATE_INFERENCE=NOT_PERMITTED
```

## Per-data-probe transaction

The data-phase probe may issue only:

```text
START
0x60
ACK prerequisite
0x85
ACK prerequisite
0x00
target DATA ACK sample
STOP
bus free
```

It may not attempt the data byte when either prerequisite phase NACKs.  No
other register or data value is authorized.  Target-phase opportunity is
counted only when the `0x00` byte physically reaches its ACK sample.

## Post-probe validation and restoration

After all three target phases reach exactly 10,000 opportunities:

1. Require bus idle and both masters releasing SCL/SDA.
2. Read `0xFF`; if it is not `0x00`, abort before interpreting the probe.
3. Read `0x85`; require exact value `0x00` and require equality with
   `safe_target_pre_value`.
4. Write `{0xFF,probe_entry_bank}`.
5. Read `0xFF`; require exact equality with `probe_entry_bank`.
6. Release SCL and SDA; require stable bus idle.
7. Only now may `PROBE_DONE=1` be asserted.

Restoration is required even if a probe transaction or post-read fails, when
the bus remains operable.  A restoration attempt must never be converted into
a retry of a failed probe transaction, and no partial probe sample is valid.

## Required recorded evidence

```text
probe_entry_bank
probe_entry_bank_valid
safe_bank_select_write_result
safe_bank_verify_value
safe_bank_verify_pass
safe_target_pre_read_result
safe_target_pre_value
safe_target_pre_value_pass
safe_target_post_read_result
safe_target_post_value
safe_target_pre_post_equal
entry_bank_restore_write_result
entry_bank_restore_readback_value
entry_bank_restore_verified
final_scl_released
final_sda_released
final_bus_idle
```

## Valid completion gate

```text
PROBE_DONE=1
PROBE_ABORTED=0
SAFE_TARGET_PRE_VALUE=0x00
SAFE_TARGET_POST_VALUE=0x00
SAFE_TARGET_PRE_POST_EQUAL=YES
ORIGINAL_BANK_RESTORED=YES
ORIGINAL_BANK_RESTORE_VERIFIED=YES
FINAL_BUS_IDLE=YES
```

## Evidence basis

- NVP6134C Rev 1.0 datasheet p.12, Table 2.1: Bank-0 `SPL_MD`
  (`0x85~0x89[3:0]`) is a video-format register setting; AHD 1080p25 uses
  `0x0`.
- Datasheet p.36: generic NVP6134C I2C write/read protocol.
- Exact R1e `nvp6134c_autoinit.vhd:183-189`: AHD 1080p25, `auto_enable=0`,
  stage 2.
- Exact R1e `nvp6134c_diagnostics_pkg.vhd:329,408`: two intentional
  `x"008500"` writes in the same frozen stage-2 init sequence.
- Exact R1e `rtl/top/ahd_capture_top_xdma.sv:16` keeps
  `ENABLE_MAREK_INIT_TABLE=1`; `scripts/v41/r1e_build.tcl:76-83` does not
  override that parameter, so both writes are active in the frozen R1e image.
- Exact R1e `nvp6134c_i2c_bringup.vhd`: verified bank selection and
  entry-bank preservation/restoration provide the accepted transaction model.
